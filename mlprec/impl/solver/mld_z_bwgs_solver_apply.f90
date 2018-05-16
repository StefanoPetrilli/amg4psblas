!  
!   
!                             MLD2P4  version 2.2
!    MultiLevel Domain Decomposition Parallel Preconditioners Package
!               based on PSBLAS (Parallel Sparse BLAS version 3.5)
!    
!    (C) Copyright 2008-2018 
!  
!        Salvatore Filippone  
!        Pasqua D'Ambra   
!        Daniela di Serafino   
!   
!    Redistribution and use in source and binary forms, with or without
!    modification, are permitted provided that the following conditions
!    are met:
!      1. Redistributions of source code must retain the above copyright
!         notice, this list of conditions and the following disclaimer.
!      2. Redistributions in binary form must reproduce the above copyright
!         notice, this list of conditions, and the following disclaimer in the
!         documentation and/or other materials provided with the distribution.
!      3. The name of the MLD2P4 group or the names of its contributors may
!         not be used to endorse or promote products derived from this
!         software without specific written permission.
!   
!    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
!    ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
!    TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
!    PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE MLD2P4 GROUP OR ITS CONTRIBUTORS
!    BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
!    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
!    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
!    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
!    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
!    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
!    POSSIBILITY OF SUCH DAMAGE.
!   
!  
subroutine mld_z_bwgs_solver_apply(alpha,sv,x,beta,y,desc_data,&
     &trans,work,info,init,initu)
  
  use psb_base_mod
  use mld_z_gs_solver, mld_protect_name => mld_z_bwgs_solver_apply
  implicit none 
  type(psb_desc_type), intent(in)       :: desc_data
  class(mld_z_bwgs_solver_type), intent(inout) :: sv
  complex(psb_dpk_),intent(inout)         :: x(:)
  complex(psb_dpk_),intent(inout)         :: y(:)
  complex(psb_dpk_),intent(in)            :: alpha,beta
  character(len=1),intent(in)           :: trans
  complex(psb_dpk_),target, intent(inout) :: work(:)
  integer(psb_ipk_), intent(out)        :: info
  character, intent(in), optional       :: init
  complex(psb_dpk_),intent(inout), optional :: initu(:)

  integer(psb_ipk_)  :: n_row,n_col, itx
  complex(psb_dpk_), pointer :: ww(:), aux(:), tx(:),ty(:)
  complex(psb_dpk_), allocatable :: temp(:),wv(:),xit(:)
  integer(psb_ipk_)  :: ictxt,np,me,i, err_act
  character          :: trans_, init_
  character(len=20)  :: name='z_bwgs_solver_apply'

  call psb_erractionsave(err_act)
  ictxt = desc_data%get_ctxt()
  call psb_info(ictxt,me,np)
  info = psb_success_

  trans_ = psb_toupper(trans)
  select case(trans_)
  case('N')
!!$  case('T')
!!$  case('C')
  case default
    call psb_errpush(psb_err_iarg_invalid_i_,name)
    goto 9999
  end select
  
  if (present(init)) then
    init_ = psb_toupper(init)
  else
    init_='Z'
  end if


  n_row = desc_data%get_local_rows()
  n_col = desc_data%get_local_cols()

  if (n_col <= size(work)) then 
    ww => work(1:n_col)
    if ((4*n_col+n_col) <= size(work)) then 
      aux => work(n_col+1:)
    else
      allocate(aux(4*n_col),stat=info)
      if (info /= psb_success_) then 
        info=psb_err_alloc_request_
        call psb_errpush(info,name,& 
             & i_err=(/4*n_col,izero,izero,izero,izero/),&
             & a_err='complex(psb_dpk_)')
        goto 9999      
      end if
    endif
  else
    allocate(ww(n_col),aux(4*n_col),stat=info)
    if (info /= psb_success_) then 
      info=psb_err_alloc_request_
      call psb_errpush(info,name,& 
           & i_err=(/5*n_col,izero,izero,izero,izero/),&
           & a_err='complex(psb_dpk_)')
      goto 9999      
    end if
  endif

  if (info /= psb_success_) then 
    info=psb_err_alloc_request_
    call psb_errpush(info,name,&
         & i_err=(/5*n_col,izero,izero,izero,izero/),&
         & a_err='complex(psb_dpk_)')
    goto 9999      
  end if

  call psb_geasb(wv,desc_data,info) 
  call psb_geasb(xit,desc_data,info) 
  select case (init_)
  case('Z') 
    xit(:) = zzero
  case('Y')
    call psb_geaxpby(zone,y,zzero,xit,desc_data,info)
  case('U')
    if (.not.present(initu)) then
      call psb_errpush(psb_err_internal_error_,name,&
           & a_err='missing initu to smoother_apply')
      goto 9999
    end if
    call psb_geaxpby(zone,initu,zzero,xit,desc_data,info)
  case default
    call psb_errpush(psb_err_internal_error_,name,&
         & a_err='wrong  init to smoother_apply')
    goto 9999
  end select
  
  select case(trans_)
  case('N')
    if (sv%eps <=dzero) then
      !
      ! Fixed number of iterations
      !
      !
      do itx=1,sv%sweeps
        call psb_geaxpby(zone,x,zzero,wv,desc_data,info)
        ! Update with L. The off-diagonal block is taken care
        ! from the Jacobi smoother, hence this is purely local. 
        call psb_spmm(-zone,sv%l,xit,zone,wv,desc_data,info,doswap=.false.)
        call psb_spsm(zone,sv%u,wv,zzero,xit,desc_data,info)
      end do
      
      call psb_geaxpby(alpha,xit,beta,y,desc_data,info)

    else
      !
      ! Iterations to convergence, not implemented right now. 
      !
      info = psb_err_internal_error_
      call psb_errpush(info,name,a_err='EPS>0 not implemented in GS subsolve')
      goto 9999
    
    end if
!!$  case('T')
!!$    call psb_spsm(zone,sv%u,x,zzero,wv,desc_data,info,&
!!$         & trans=trans_,scale='L',diag=sv%dv,choice=psb_none_,work=aux)
!!$    if (info == psb_success_) call psb_spsm(alpha,sv%l,wv,beta,y,desc_data,info,&
!!$         & trans=trans_,scale='U',choice=psb_none_,work=aux)
!!$
!!$  case('C')
!!$
!!$    call psb_spsm(zone,sv%u,x,zzero,wv,desc_data,info,&
!!$         & trans=trans_,scale='U',choice=psb_none_,work=aux)
!!$
!!$    call wv1%mlt(zone,sv%dv,wv,zzero,info,conjgx=trans_)
!!$
!!$    if (info == psb_success_) call psb_spsm(alpha,sv%l,wv1,beta,y,desc_data,info,&
!!$         & trans=trans_,scale='U',choice=psb_none_,work=aux)

  case default
      info = psb_err_internal_error_
      call psb_errpush(info,name,& 
         & a_err='Invalid TRANS in GS subsolve')
    goto 9999
  end select


  if (info /= psb_success_) then

    call psb_errpush(psb_err_internal_error_,name,& 
         & a_err='Error in subsolve')
    goto 9999
  endif

  if (n_col <= size(work)) then 
    if ((4*n_col+n_col) <= size(work)) then 
    else
      deallocate(aux)
    endif
  else
    deallocate(ww,aux)
  endif

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

end subroutine mld_z_bwgs_solver_apply
