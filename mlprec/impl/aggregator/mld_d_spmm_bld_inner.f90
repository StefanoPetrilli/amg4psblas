!   
!   
!                             MLD2P4  Extensions
!    
!    (C) Copyright 2019
!  
!                        Salvatore Filippone  Cranfield University
!        Pasqua D'Ambra         IAC-CNR, Naples, IT
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
! File: mld_daggrmat_nosmth_bld.F90
!
!
subroutine mld_d_spmm_bld_inner(a_csr,desc_a,ilaggr,nlaggr,parms,ac,&
     & op_prol,op_restr,info)
  use psb_base_mod
  use mld_d_inner_mod
  use mld_d_base_aggregator_mod, mld_protect_name => mld_d_spmm_bld_inner
  implicit none

  ! Arguments
  type(psb_ld_csr_sparse_mat), intent(inout) :: a_csr
  type(psb_desc_type), intent(in)            :: desc_a
  integer(psb_lpk_), intent(inout)           :: ilaggr(:), nlaggr(:)
  type(mld_dml_parms), intent(inout)         :: parms 
  type(psb_ldspmat_type), intent(inout)      :: op_prol, op_restr
  type(psb_ldspmat_type), intent(out)        :: ac
  integer(psb_ipk_), intent(out)             :: info

  ! Local variables
  integer(psb_ipk_)  :: err_act
  integer(psb_ipk_)  :: ictxt,np,me, icomm, ndx, minfo
  character(len=40)  :: name
  integer(psb_ipk_)  :: ierr(5)
  type(psb_ld_coo_sparse_mat) :: ac_coo, tmpcoo, coo_prol
  type(psb_ld_csr_sparse_mat) :: acsr2, acsr3, acsr4, csr_prol, ac_csr, csr_restr
  type(psb_ldspmat_type) :: am3, am4, tmp_prol
  type(psb_desc_type), target  :: tmp_desc
  integer(psb_ipk_) :: debug_level, debug_unit, naggr
  integer(psb_lpk_) :: nrow, nglob, ncol, ntaggr, nzl, ip, &
       &  nzt, naggrm1, naggrp1, i, k
  integer(psb_lpk_) ::  nrsave, ncsave, nzsave, nza, nrpsave, ncpsave, nzpsave
  logical, parameter :: do_timings=.true., oldstyle=.false., debug=.false.  
  integer(psb_ipk_), save :: idx_spspmm=-1

  name='mld_spmm_bld_inner'
  if(psb_get_errstatus().ne.0) return 
  info=psb_success_
  call psb_erractionsave(err_act)


  ictxt = desc_a%get_context()
  icomm = desc_a%get_mpic()
  call psb_info(ictxt, me, np)
  debug_unit  = psb_get_debug_unit()
  debug_level = psb_get_debug_level()
  nglob = desc_a%get_global_rows()
  nrow  = desc_a%get_local_rows()
  ncol  = desc_a%get_local_cols()

  if ((do_timings).and.(idx_spspmm==-1)) &
       & idx_spspmm = psb_get_timer_idx("SPMM_BLD: par_spspmm")

  naggr   = nlaggr(me+1)
  ntaggr  = sum(nlaggr)
  naggrm1 = sum(nlaggr(1:me))
  naggrp1 = sum(nlaggr(1:me+1)) 
  !write(0,*)me,' ',name,' input sizes',nlaggr(:),':',naggr
  nrpsave = op_prol%get_nrows()
  ncpsave = op_prol%get_ncols()
  nzpsave = op_prol%get_nzeros()    
  !write(0,*)me,' ',name,' input op_prol ',nrpsave,ncpsave,nzpsave

  !
  ! Here OP_PROL should be with GLOBAL indices on the cols
  ! and LOCAL indices on the rows. 
  !
  if (debug) write(0,*)  me,' ',trim(name),' Size check on entry New: ',&
       & op_prol%get_fmt(),op_prol%get_nrows(),op_prol%get_ncols(),op_prol%get_nzeros(),&
       & nrow,ntaggr,naggr

  call op_prol%cp_to(coo_prol)

  if (debug) write(0,*)  me,' ',trim(name),' coo_prol: ',&
       & coo_prol%ia(1:min(10,nzpsave)),' :',coo_prol%ja(1:min(10,nzpsave))
  call psb_cdall(ictxt,tmp_desc,info,nl=naggr)
  call tmp_desc%indxmap%g2lip_ins(coo_prol%ja(1:nzpsave),info) 
  call coo_prol%set_ncols(tmp_desc%get_local_cols())
  call coo_prol%mv_to_fmt(csr_prol,info)

  if (debug) write(0,*) me,trim(name),' Product AxPROL ',&
       & a_csr%get_nrows(),a_csr%get_ncols(), csr_prol%get_nrows(), &
       & desc_a%get_local_rows(),desc_a%get_local_cols(),&
       & tmp_desc%get_local_rows(),desc_a%get_local_cols()
  if (debug) flush(0)

  if (do_timings) call psb_tic(idx_spspmm)
  call psb_par_spspmm(a_csr,desc_a,csr_prol,acsr3,tmp_desc,info)
  if (do_timings) call psb_toc(idx_spspmm)  

  if (debug) write(0,*) me,trim(name),' Done AxPROL ',&
       & acsr3%get_nrows(),acsr3%get_ncols(), acsr3%get_nzeros(),&
       & tmp_desc%get_local_rows(),tmp_desc%get_local_cols()

  !
  ! Ok first product done.
  !
  ! Remember that RESTR must be built from PROL after halo extension,
  ! which is done above in psb_par_spspmm
  if (debug) write(0,*)me,' ',name,' No inp_restr, transposing prol ',&
       & csr_prol%get_nrows(),csr_prol%get_ncols(),csr_prol%get_nzeros()
  call csr_prol%cp_to_fmt(tmpcoo,info)
!!$      write(0,*)me,' ',name,' new into transposition ',tmpcoo%get_nrows(),&
!!$           & tmpcoo%get_ncols(),tmpcoo%get_nzeros()
  call tmpcoo%transp()
  nzl = tmpcoo%get_nzeros()
  call tmp_desc%l2gip(tmpcoo%ia(1:nzl),info)
  i=0
  !
  ! Now we have to fix this.  The only rows of the restrictor that are correct 
  ! are those corresponding to "local" aggregates, i.e. indices in ilaggr(:)
  !
  do k=1, nzl
    if ((naggrm1 < tmpcoo%ia(k)) .and.(tmpcoo%ia(k) <= naggrp1)) then
      i = i+1
      tmpcoo%val(i) = tmpcoo%val(k)
      tmpcoo%ia(i)  = tmpcoo%ia(k)
      tmpcoo%ja(i)  = tmpcoo%ja(k)
    end if
  end do
  call tmpcoo%set_nzeros(i)
  call tmpcoo%fix(info)
  call op_restr%cp_from(tmpcoo)
!!$      write(0,*)me,' ',name,' after transposition ',tmpcoo%get_nrows(),tmpcoo%get_ncols(),tmpcoo%get_nzeros()

  if (info /= psb_success_) then 
    call psb_errpush(psb_err_from_subroutine_,name,a_err='spcnv op_restr')
    goto 9999
  end if
  if (debug_level >= psb_debug_outer_) &
       & write(debug_unit,*) me,' ',trim(name),&
       & 'starting sphalo/ rwxtd'
  nzl    = tmpcoo%get_nzeros()    
  call psb_glob_to_loc(tmpcoo%ia(1:nzl),tmp_desc,info,iact='I',owned=.true.)
  call tmpcoo%clean_negidx(info)
  nzl  = tmpcoo%get_nzeros()
  call tmpcoo%set_nrows(tmp_desc%get_local_rows())
  call tmpcoo%set_ncols(desc_a%get_local_cols())
!!$    write(0,*)me,' ',name,' after G2L on rows ',tmpcoo%get_nrows(),tmpcoo%get_ncols(),tmpcoo%get_nzeros()      
  call csr_restr%mv_from_coo(tmpcoo,info)


  if (debug) write(0,*) me,trim(name),' Product RESTRxAP ',&
       & csr_restr%get_nrows(),csr_restr%get_ncols(), &
       & tmp_desc%get_local_rows(),desc_a%get_local_cols(),&
       & acsr3%get_nrows(),acsr3%get_ncols()
  if (do_timings) call psb_tic(idx_spspmm)      
  call psb_par_spspmm(csr_restr,desc_a,acsr3,ac_csr,tmp_desc,info)
  if (do_timings) call psb_toc(idx_spspmm)      
  call ac_csr%mv_to_coo(ac_coo,info)
  nza    = ac_coo%get_nzeros()
  if (debug) write(0,*) me,trim(name),' Fixing ac ',&
       & ac_coo%get_nrows(),ac_coo%get_ncols(), nza

  call ac_coo%fix(info)
  call tmp_desc%indxmap%l2gip(ac_coo%ia(1:nza),info)
  call tmp_desc%indxmap%l2gip(ac_coo%ja(1:nza),info)
  call ac_coo%set_nrows(ntaggr)
  call ac_coo%set_ncols(ntaggr)
  if (debug) write(0,*)  me,' ',trim(name),' Before mv_from',psb_get_errstatus()
  if (info == 0) call ac%mv_from(ac_coo)
  if (debug) write(0,*)  me,' ',trim(name),' After  mv_from',psb_get_errstatus()
  if (debug) write(0,*)  me,' ',trim(name),' ',ac%get_fmt(),ac%get_nrows(),ac%get_ncols(),ac%get_nzeros(),naggr,ntaggr
  ! write(0,*)  me,' ',trim(name),' Final AC newstyle ',ac%get_fmt(),ac%get_nrows(),ac%get_ncols(),ac%get_nzeros()
  if (debug) then
    write(0,*) me,' ',trim(name),' Checkpoint at exit'
    call psb_barrier(ictxt)
    write(0,*) me,' ',trim(name),' Checkpoint through'
  end if

  if (info /= psb_success_) then
    call psb_errpush(psb_err_internal_error_,name,a_err='Build ac = op_restr x am3')
    goto 9999
  end if


  if (debug_level >= psb_debug_outer_) &
       & write(debug_unit,*) me,' ',trim(name),&
       & 'Done smooth_aggregate '

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return
  
end subroutine mld_d_spmm_bld_inner