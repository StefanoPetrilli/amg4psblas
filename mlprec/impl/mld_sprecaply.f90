!  
!   
!                             MLD2P4  version 2.1
!    MultiLevel Domain Decomposition Parallel Preconditioners Package
!               based on PSBLAS (Parallel Sparse BLAS version 3.4)
!    
!    (C) Copyright 2008, 2010, 2012, 2015, 2017 
!  
!        Salvatore Filippone    Cranfield University
!        Ambra Abdullahi Hassan University of Rome Tor Vergata
!        Alfredo Buttari        CNRS-IRIT, Toulouse
!        Pasqua D'Ambra         ICAR-CNR, Naples
!        Daniela di Serafino    University of Campania "L. Vanvitelli", Caserta
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
! File: mld_sprecaply.f90
!
! Subroutine: mld_sprecaply
! Version:    real
!
!  This routine applies the preconditioner built by mld_sprecbld, i.e. it computes
!
!                             Y = op(M^(-1)) * X,
!  where
!  - M is the preconditioner,
!  - op(M^(-1)) is M^(-1) or its transpose, according to the value of trans,
!  - X and Y are vectors.
!  This operation is performed at each iteration of a preconditioned Krylov solver.
!
!
! Arguments:
!    prec       -  type(mld_sprec_type), input.
!                  The preconditioner data structure containing the local part
!                  of the preconditioner to be applied.
!    x          -  real(psb_spk_), dimension(:), input.
!                  The local part of the vector X in Y=op(M^(-1))*X.
!    y          -  real(psb_spk_), dimension(:), output.
!                  The local part of the vector Y in Y=op(M^(-1))*X.
!    desc_data  -  type(psb_desc_type), input.
!                  The communication descriptor associated to the matrix to be
!                  preconditioned.
!    info       -  integer, output.
!                  Error code.
!    trans      -  character(len=1), optional.
!                  If trans='N','n' then op(M^(-1)) = M^(-1);
!                  if trans='T','t' then op(M^(-1)) = M^(-T) (transpose of M^(-1)).
!    work       -  real(psb_spk_), dimension (:), optional, target.
!                  Workspace. Its size must be at
!                  least 4*desc_data%get_local_cols().
!    
subroutine mld_sprecaply(prec,x,y,desc_data,info,trans,work)

  use psb_base_mod
  use mld_s_inner_mod!, mld_protect_name => mld_sprecaply
  
  implicit none
  
  ! Arguments
  type(psb_desc_type),intent(in)    :: desc_data
  type(mld_sprec_type), intent(inout)  :: prec
  real(psb_spk_),intent(inout)   :: x(:)
  real(psb_spk_),intent(inout)   :: y(:)
  integer(psb_ipk_), intent(out)    :: info
  character(len=1), optional        :: trans
  real(psb_spk_),intent(inout), optional, target  :: work(:)

  ! Local variables
  character     :: trans_ 
  real(psb_spk_), pointer :: work_(:)
  integer(psb_ipk_)  :: ictxt,np,me
  integer(psb_ipk_)  :: err_act,iwsz
  character(len=20)  :: name

  name='mld_sprecaply'
  info = psb_success_
  call psb_erractionsave(err_act)

  ictxt = desc_data%get_context()
  call psb_info(ictxt, me, np)

  if (present(trans)) then 
    trans_=psb_toupper(trans)
  else
    trans_='N'
  end if

  if (present(work)) then 
    work_ => work
  else
    iwsz = max(1,4*desc_data%get_local_cols())
    allocate(work_(iwsz),stat=info)
    if (info /= psb_success_) then 
      call psb_errpush(psb_err_alloc_request_,name, &
           & i_err=(/iwsz,izero,izero,izero,izero/),&
           & a_err='real(psb_spk_)')
      goto 9999      
    end if

  end if

  if (.not.(allocated(prec%precv))) then 
    !! Error 1: should call mld_sprecbld
    info=3112
    call psb_errpush(info,name)
    goto 9999
  end if

  if (size(prec%precv) >1) then
    !
    ! Number of levels > 1: apply the multilevel preconditioner
    ! 
    call mld_mlprec_aply(sone,prec,x,szero,y,desc_data,trans_,work_,info)
    if(info /= psb_success_) then
      call psb_errpush(psb_err_from_subroutine_,name,a_err='mld_smlprec_aply')
      goto 9999
    end if

  else  if (size(prec%precv) == 1) then
    !
    ! Number of levels = 1: apply the base preconditioner
    !
    call prec%precv(1)%sm%apply(sone,x,szero,y,desc_data,trans_,&
         & prec%precv(1)%parms%sweeps, work_,info)
  else 
    info = psb_err_from_subroutine_ai_
    call psb_errpush(info,name,a_err='Invalid size of precv',&
         & i_Err=(/ione*size(prec%precv),izero,izero,izero,izero/))
    goto 9999
  endif

  ! If the original distribution has an overlap we should fix that. 
  call psb_halo(y,desc_data,info,data=psb_comm_mov_)


  if (present(work)) then 
  else
    deallocate(work_)
  end if

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

end subroutine mld_sprecaply


!
! Subroutine: mld_sprecaply1
! Version:    real
!
!  Applies the preconditioner built by mld_sprecbld, i.e. computes
!
!                             X = op(M^(-1)) * X,
!  where
!  - M is the preconditioner,
!  - op(M^(-1)) is M^(-1) or its transpose, according to the value of trans,
!  - X is a vectors.
!  This operation is performed at each iteration of a preconditioned Krylov solver.
!
!  This routine differs from mld_sprecaply because the preconditioned vector X
!  overwrites the original one.
!
!
! Arguments:
!    prec       -  type(mld_sprec_type), input.
!                  The preconditioner data structure containing the local part
!                  of the preconditioner to be applied.
!    x          -  real(psb_spk_), dimension(:), input/output.
!                  The local part of vector X in X := op(M^(-1)) * X.
!    desc_data  -  type(psb_desc_type), input.
!                  The communication descriptor associated to the matrix to be
!                  preconditioned.
!    info       -  integer, output.
!                  Error code.
!    trans      -  character(len=1), optional.
!                  If trans='N','n' then op(M^(-1)) = M^(-1);
!                  if trans='T','t' then op(M^(-1)) = M^(-T) (transpose of M^(-1)).
!  
subroutine mld_sprecaply1(prec,x,desc_data,info,trans)

  use psb_base_mod
  use mld_s_inner_mod!, mld_protect_name => mld_sprecaply1

  implicit none

  ! Arguments
  type(psb_desc_type),intent(in)    :: desc_data
  type(mld_sprec_type), intent(inout)  :: prec
  real(psb_spk_),intent(inout)   :: x(:)
  integer(psb_ipk_), intent(out)    :: info
  character(len=1), optional        :: trans

  ! Local variables
  integer(psb_ipk_)      :: ictxt,np,me
  integer(psb_ipk_)      :: err_act
  real(psb_spk_), pointer :: WW(:), w1(:)
  character(len=20)   :: name

  name='mld_sprecaply1'
  info = psb_success_
  call psb_erractionsave(err_act)
  

  ictxt = desc_data%get_context()
  call psb_info(ictxt, me, np)

  allocate(ww(size(x)),w1(size(x)),stat=info)
  if (info /= psb_success_) then 
    info=psb_err_alloc_request_
    call psb_errpush(info,name, &
         & i_err=(/itwo*size(x),izero,izero,izero,izero/),&
         & a_err='real(psb_spk_)')
    goto 9999      
  end if

  call prec%apply(x,ww,desc_data,info,trans=trans,work=w1)
  if (info /= psb_success_) then
    call psb_errpush(psb_err_from_subroutine_,name,a_err='mld_precaply')
    goto 9999
  end if

  x(:) = ww(:)
  deallocate(ww,W1,stat=info)
  if (info /= psb_success_) then
    info = psb_err_alloc_dealloc_
    call psb_errpush(info,name)
    goto 9999
  end if
  
  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)
  return

end subroutine mld_sprecaply1



subroutine mld_sprecaply2_vect(prec,x,y,desc_data,info,trans,work)

  use psb_base_mod
  use mld_s_inner_mod!, mld_protect_name => mld_sprecaply2_vect
  
  implicit none
  
  ! Arguments
  type(psb_desc_type),intent(in)      :: desc_data
  type(mld_sprec_type), intent(inout) :: prec
  type(psb_s_vect_type),intent(inout) :: x
  type(psb_s_vect_type),intent(inout) :: y
  integer(psb_ipk_), intent(out)      :: info
  character(len=1), optional          :: trans
  real(psb_spk_),intent(inout), optional, target  :: work(:)

  ! Local variables
  character     :: trans_ 
  real(psb_spk_), pointer :: work_(:)
  integer(psb_ipk_)  :: ictxt,np,me
  integer(psb_ipk_)  :: err_act,iwsz
  character(len=20)  :: name

  name='mld_sprecaply'
  info = psb_success_
  call psb_erractionsave(err_act)

  ictxt = desc_data%get_context()
  call psb_info(ictxt, me, np)

  if (present(trans)) then 
    trans_=psb_toupper(trans)
  else
    trans_='N'
  end if

  if (present(work)) then 
    work_ => work
  else
    iwsz = max(1,4*desc_data%get_local_cols())
    allocate(work_(iwsz),stat=info)
    if (info /= psb_success_) then 
      call psb_errpush(psb_err_alloc_request_,name, &
           & i_err=(/iwsz,izero,izero,izero,izero/),&
           & a_err='real(psb_spk_)')
      goto 9999      
    end if

  end if

  if (.not.(allocated(prec%precv))) then 
    !! Error 1: should call mld_sprecbld
    info=3112
    call psb_errpush(info,name)
    goto 9999
  end if
  if (size(prec%precv) >1) then
    !
    ! Number of levels > 1: apply the multilevel preconditioner
    ! 
    call mld_mlprec_aply(sone,prec,x,szero,y,desc_data,trans_,work_,info)

    if(info /= psb_success_) then
      call psb_errpush(psb_err_from_subroutine_,name,a_err='mld_smlprec_aply')
      goto 9999
    end if

  else  if (size(prec%precv) == 1) then
    !
    ! Number of levels = 1: apply the base preconditioner
    !
    call prec%precv(1)%sm%apply(sone,x,szero,y,desc_data,trans_,&
         & prec%precv(1)%parms%sweeps, work_,info)

  else 

    info = psb_err_from_subroutine_ai_
    call psb_errpush(info,name,a_err='Invalid size of precv',&
         & i_Err=(/ione*size(prec%precv),izero,izero,izero,izero/))
    goto 9999
  endif

  ! If the original distribution has an overlap we should fix that. 
  call psb_halo(y,desc_data,info,data=psb_comm_mov_)


  if (present(work)) then 
  else
    deallocate(work_)
  end if

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

end subroutine mld_sprecaply2_vect


subroutine mld_sprecaply1_vect(prec,x,desc_data,info,trans,work)

  use psb_base_mod
  use mld_s_inner_mod!, mld_protect_name => mld_sprecaply1_vect
  
  implicit none
  
  ! Arguments
  type(psb_desc_type),intent(in)      :: desc_data
  type(mld_sprec_type), intent(inout) :: prec
  type(psb_s_vect_type),intent(inout) :: x
  integer(psb_ipk_), intent(out)      :: info
  character(len=1), optional          :: trans
  real(psb_spk_),intent(inout), optional, target  :: work(:)

  ! Local variables
  character     :: trans_ 
  type(psb_s_vect_type) :: ww
  real(psb_spk_), pointer :: work_(:)
  integer(psb_ipk_)  :: ictxt,np,me
  integer(psb_ipk_)  :: err_act,iwsz
  character(len=20)  :: name

  name='mld_sprecaply'
  info = psb_success_
  call psb_erractionsave(err_act)

  ictxt = desc_data%get_context()
  call psb_info(ictxt, me, np)

  if (present(trans)) then 
    trans_=psb_toupper(trans)
  else
    trans_='N'
  end if

  if (present(work)) then 
    work_ => work
  else
    iwsz = max(1,4*desc_data%get_local_cols())
    allocate(work_(iwsz),stat=info)
    if (info /= psb_success_) then 
      call psb_errpush(psb_err_alloc_request_,name, &
           & i_err=(/iwsz,izero,izero,izero,izero/),&
           & a_err='real(psb_spk_)')
      goto 9999      
    end if

  end if

  if (.not.(allocated(prec%precv))) then 
    !! Error 1: should call mld_sprecbld
    info=3112
    call psb_errpush(info,name)
    goto 9999
  end if
  call psb_geasb(ww,desc_data,info,mold=x%v,scratch=.true.)
  if (size(prec%precv) >1) then
    !
    ! Number of levels > 1: apply the multilevel preconditioner
    ! 
    call mld_mlprec_aply(sone,prec,x,szero,ww,desc_data,trans_,work_,info)

    if(info /= psb_success_) then
      call psb_errpush(psb_err_from_subroutine_,name,a_err='mld_smlprec_aply')
      goto 9999
    end if

  else  if (size(prec%precv) == 1) then
    !
    ! Number of levels = 1: apply the base preconditioner
    !
    call prec%precv(1)%sm%apply(sone,x,szero,ww,desc_data,trans_,&
         & prec%precv(1)%parms%sweeps, work_,info)

  else 

    info = psb_err_from_subroutine_ai_
    call psb_errpush(info,name,a_err='Invalid size of precv',&
         & i_Err=(/ione*size(prec%precv),izero,izero,izero,izero/))
    goto 9999
  endif

  if (info == 0) call psb_geaxpby(sone,ww,szero,x,desc_data,info)
  if (info == 0) call psb_gefree(ww,desc_data,info)

  ! If the original distribution has an overlap we should fix that. 
  call psb_halo(x,desc_data,info,data=psb_comm_mov_)


  if (present(work)) then 
  else
    deallocate(work_)
  end if

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

end subroutine mld_sprecaply1_vect
