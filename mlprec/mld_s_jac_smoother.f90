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
!
! File: mld_s_jac_smoother_mod.f90
!
! Module: mld_s_jac_smoother_mod
!
!  This module defines:
!    the mld_s_jac_smoother_type data structure containing the
!    smoother for a Jacobi/block Jacobi smoother.
!  The smoother stores in ND the block off-diagonal matrix.
!  One special case is treated separately, when the solver is DIAG or L1-DIAG
!  then the ND is the entire off-diagonal part of the matrix (including the
!  main diagonal block), so that it becomes possible to implement
!  a pure Jacobi or L1-Jacobi global solver.
!
module mld_s_jac_smoother

  use mld_s_base_smoother_mod

  type, extends(mld_s_base_smoother_type) :: mld_s_jac_smoother_type
    ! The local solver component is inherited from the
    ! parent type.
    !    class(mld_s_base_solver_type), allocatable :: sv
    !
    type(psb_sspmat_type), pointer  :: pa => null()
    type(psb_sspmat_type) :: nd
    integer(psb_lpk_)       :: nd_nnz_tot
    logical                 :: checkres
    logical                 :: printres
    integer(psb_ipk_)       :: checkiter
    integer(psb_ipk_)       :: printiter
    real(psb_dpk_)          :: tol
  contains
    procedure, pass(sm) :: dump    => mld_s_jac_smoother_dmp
    procedure, pass(sm) :: build   => mld_s_jac_smoother_bld
    procedure, pass(sm) :: cnv     => mld_s_jac_smoother_cnv
    procedure, pass(sm) :: clone   => mld_s_jac_smoother_clone
    procedure, pass(sm) :: apply_v => mld_s_jac_smoother_apply_vect
    procedure, pass(sm) :: apply_a => mld_s_jac_smoother_apply
    procedure, pass(sm) :: free    => s_jac_smoother_free
    procedure, pass(sm) :: cseti   => mld_s_jac_smoother_cseti
    procedure, pass(sm) :: csetc   => mld_s_jac_smoother_csetc
    procedure, pass(sm) :: csetr   => mld_s_jac_smoother_csetr
    procedure, pass(sm) :: descr   => mld_s_jac_smoother_descr
    procedure, pass(sm) :: sizeof  => s_jac_smoother_sizeof
    procedure, pass(sm) :: default => s_jac_smoother_default
    procedure, pass(sm) :: get_nzeros => s_jac_smoother_get_nzeros
    procedure, pass(sm) :: get_wrksz => s_jac_smoother_get_wrksize
    procedure, nopass   :: get_fmt    => s_jac_smoother_get_fmt
    procedure, nopass   :: get_id     => s_jac_smoother_get_id
  end type mld_s_jac_smoother_type


  private :: s_jac_smoother_free, &
       & s_jac_smoother_sizeof,  s_jac_smoother_get_nzeros, &
       & s_jac_smoother_get_fmt, s_jac_smoother_get_id, &
       & s_jac_smoother_get_wrksize


  interface
    subroutine mld_s_jac_smoother_apply_vect(alpha,sm,x,beta,y,desc_data,trans,&
         & sweeps,work,wv,info,init,initu)
      import :: psb_desc_type, mld_s_jac_smoother_type, psb_s_vect_type, psb_spk_, &
           & psb_sspmat_type, psb_s_base_sparse_mat, psb_s_base_vect_type,&
           & psb_ipk_

      type(psb_desc_type), intent(in)                 :: desc_data
      class(mld_s_jac_smoother_type), intent(inout) :: sm
      type(psb_s_vect_type),intent(inout)           :: x
      type(psb_s_vect_type),intent(inout)           :: y
      real(psb_spk_),intent(in)                      :: alpha,beta
      character(len=1),intent(in)                     :: trans
      integer(psb_ipk_), intent(in)                   :: sweeps
      real(psb_spk_),target, intent(inout)           :: work(:)
      type(psb_s_vect_type),intent(inout)           :: wv(:)
      integer(psb_ipk_), intent(out)                  :: info
      character, intent(in), optional                :: init
      type(psb_s_vect_type),intent(inout), optional   :: initu
    end subroutine mld_s_jac_smoother_apply_vect
  end interface

  interface
    subroutine mld_s_jac_smoother_apply(alpha,sm,x,beta,y,desc_data,trans,&
         & sweeps,work,info,init,initu)
      import :: psb_desc_type, mld_s_jac_smoother_type, psb_s_vect_type, psb_spk_, &
           & psb_sspmat_type, psb_s_base_sparse_mat, psb_s_base_vect_type, &
           & psb_ipk_
      type(psb_desc_type), intent(in)      :: desc_data
      class(mld_s_jac_smoother_type), intent(inout) :: sm
      real(psb_spk_),intent(inout)         :: x(:)
      real(psb_spk_),intent(inout)         :: y(:)
      real(psb_spk_),intent(in)            :: alpha,beta
      character(len=1),intent(in)           :: trans
      integer(psb_ipk_), intent(in)         :: sweeps
      real(psb_spk_),target, intent(inout) :: work(:)
      integer(psb_ipk_), intent(out)        :: info
      character, intent(in), optional       :: init
      real(psb_spk_),intent(inout), optional :: initu(:)
    end subroutine mld_s_jac_smoother_apply
  end interface

  interface
    subroutine mld_s_jac_smoother_bld(a,desc_a,sm,info,amold,vmold,imold)
      import :: psb_desc_type, mld_s_jac_smoother_type, psb_s_vect_type, psb_spk_, &
           & psb_sspmat_type, psb_s_base_sparse_mat, psb_s_base_vect_type,&
           & psb_ipk_, psb_i_base_vect_type
      type(psb_sspmat_type), intent(in), target           :: a
      Type(psb_desc_type), Intent(inout)                  :: desc_a
      class(mld_s_jac_smoother_type), intent(inout)       :: sm
      integer(psb_ipk_), intent(out)                      :: info
      class(psb_s_base_sparse_mat), intent(in), optional :: amold
      class(psb_s_base_vect_type), intent(in), optional  :: vmold
      class(psb_i_base_vect_type), intent(in), optional  :: imold
    end subroutine mld_s_jac_smoother_bld
  end interface

  interface
    subroutine mld_s_jac_smoother_cnv(sm,info,amold,vmold,imold)
      import :: mld_s_jac_smoother_type, psb_spk_, &
           & psb_s_base_sparse_mat, psb_s_base_vect_type,&
           & psb_ipk_, psb_i_base_vect_type
      class(mld_s_jac_smoother_type), intent(inout)       :: sm
      integer(psb_ipk_), intent(out)                      :: info
      class(psb_s_base_sparse_mat), intent(in), optional :: amold
      class(psb_s_base_vect_type), intent(in), optional  :: vmold
      class(psb_i_base_vect_type), intent(in), optional  :: imold
    end subroutine mld_s_jac_smoother_cnv
  end interface

  interface
    subroutine mld_s_jac_smoother_dmp(sm,ictxt,level,info,prefix,head,smoother,solver)
      import :: psb_sspmat_type, psb_s_vect_type, psb_s_base_vect_type, &
           & psb_spk_, mld_s_jac_smoother_type, psb_epk_, psb_desc_type, &
           & psb_ipk_
      implicit none
      class(mld_s_jac_smoother_type), intent(in) :: sm
      integer(psb_ipk_), intent(in)               :: ictxt
      integer(psb_ipk_), intent(in)               :: level
      integer(psb_ipk_), intent(out)              :: info
      character(len=*), intent(in), optional :: prefix, head
      logical, optional, intent(in)    :: smoother, solver
    end subroutine mld_s_jac_smoother_dmp
  end interface

  interface
    subroutine mld_s_jac_smoother_clone(sm,smout,info)
      import :: mld_s_jac_smoother_type, psb_spk_, &
           & mld_s_base_smoother_type, psb_ipk_
      class(mld_s_jac_smoother_type), intent(inout)               :: sm
      class(mld_s_base_smoother_type), allocatable, intent(inout) :: smout
      integer(psb_ipk_), intent(out)                :: info
    end subroutine mld_s_jac_smoother_clone
  end interface

  interface
    subroutine mld_s_jac_smoother_descr(sm,info,iout,coarse)
      import :: mld_s_jac_smoother_type, psb_ipk_
      class(mld_s_jac_smoother_type), intent(in) :: sm
      integer(psb_ipk_), intent(out)               :: info
      integer(psb_ipk_), intent(in), optional      :: iout
      logical, intent(in), optional              :: coarse
    end subroutine mld_s_jac_smoother_descr
  end interface

  interface
    subroutine mld_s_jac_smoother_cseti(sm,what,val,info,idx)
      import :: psb_sspmat_type, psb_s_vect_type, psb_s_base_vect_type, &
           & psb_spk_, mld_s_jac_smoother_type, psb_epk_, psb_desc_type, psb_ipk_
      implicit none
      class(mld_s_jac_smoother_type), intent(inout) :: sm
      character(len=*), intent(in)                   :: what
      integer(psb_ipk_), intent(in)                  :: val
      integer(psb_ipk_), intent(out)                 :: info
      integer(psb_ipk_), intent(in), optional        :: idx
    end subroutine mld_s_jac_smoother_cseti
  end interface

  interface
    subroutine mld_s_jac_smoother_csetc(sm,what,val,info,idx)
      import :: psb_sspmat_type, psb_s_vect_type, psb_s_base_vect_type, &
           & psb_spk_, mld_s_jac_smoother_type, psb_epk_, psb_desc_type, psb_ipk_
      implicit none
      class(mld_s_jac_smoother_type), intent(inout) :: sm
      character(len=*), intent(in)                   :: what
      character(len=*), intent(in)                   :: val
      integer(psb_ipk_), intent(out)                 :: info
      integer(psb_ipk_), intent(in), optional        :: idx
    end subroutine mld_s_jac_smoother_csetc
  end interface

  interface
    subroutine mld_s_jac_smoother_csetr(sm,what,val,info,idx)
      import :: psb_sspmat_type, psb_s_vect_type, psb_s_base_vect_type, &
           & psb_spk_, mld_s_jac_smoother_type, psb_epk_, psb_desc_type, psb_ipk_
      implicit none
      class(mld_s_jac_smoother_type), intent(inout) :: sm
      character(len=*), intent(in)                   :: what
      real(psb_spk_), intent(in)                   :: val
      integer(psb_ipk_), intent(out)                 :: info
      integer(psb_ipk_), intent(in), optional        :: idx
    end subroutine mld_s_jac_smoother_csetr
  end interface

contains


  subroutine s_jac_smoother_free(sm,info)


    Implicit None

    ! Arguments
    class(mld_s_jac_smoother_type), intent(inout) :: sm
    integer(psb_ipk_), intent(out)                  :: info
    integer(psb_ipk_) :: err_act
    character(len=20)  :: name='s_jac_smoother_free'

    call psb_erractionsave(err_act)
    info = psb_success_



    if (allocated(sm%sv)) then
      call sm%sv%free(info)
      if (info == psb_success_) deallocate(sm%sv,stat=info)
      if (info /= psb_success_) then
        info = psb_err_alloc_dealloc_
        call psb_errpush(info,name)
        goto 9999
      end if
    end if
    call sm%nd%free()
    sm%pa => null()

    call psb_erractionrestore(err_act)
    return

9999 call psb_error_handler(err_act)
    return
  end subroutine s_jac_smoother_free

  function s_jac_smoother_sizeof(sm) result(val)

    implicit none
    ! Arguments
    class(mld_s_jac_smoother_type), intent(in) :: sm
    integer(psb_epk_) :: val
    integer(psb_ipk_)        :: i

    val = psb_sizeof_lp
    if (allocated(sm%sv)) val = val + sm%sv%sizeof()
    val = val + sm%nd%sizeof()

    return
  end function s_jac_smoother_sizeof

  subroutine s_jac_smoother_default(sm)

    Implicit None

    ! Arguments
    class(mld_s_jac_smoother_type), intent(inout) :: sm

    !
    ! Default: BJAC with no residual check
    !
    sm%checkres = .false.
    sm%printres = .false.
    sm%checkiter = -1
    sm%printiter = -1
    sm%tol = 0

    if (allocated(sm%sv)) then
      call sm%sv%default()
    end if

    return
  end subroutine s_jac_smoother_default

  function s_jac_smoother_get_nzeros(sm) result(val)

    implicit none
    ! Arguments
    class(mld_s_jac_smoother_type), intent(in) :: sm
    integer(psb_epk_) :: val
    integer(psb_ipk_)        :: i

    val = 0
    if (allocated(sm%sv)) val = val + sm%sv%get_nzeros()
    val = val + sm%nd%get_nzeros()

    return
  end function s_jac_smoother_get_nzeros

  function s_jac_smoother_get_wrksize(sm) result(val)
    implicit none
    class(mld_s_jac_smoother_type), intent(inout) :: sm
    integer(psb_ipk_)  :: val

    val = 2
    if (allocated(sm%sv)) val = val + sm%sv%get_wrksz()

  end function s_jac_smoother_get_wrksize

  function s_jac_smoother_get_fmt() result(val)
    implicit none
    character(len=32)  :: val

    val = "Jacobi smoother"
  end function s_jac_smoother_get_fmt

  function s_jac_smoother_get_id() result(val)
    implicit none
    integer(psb_ipk_)  :: val

    val = mld_jac_
  end function s_jac_smoother_get_id

end module mld_s_jac_smoother
