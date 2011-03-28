/* This file was generated by a script using the mld_base_prec_type.F90 file as a basis. */
#ifdef __cplusplus
extern "C" { 
#endif
#define MLD_VERSION_STRING_ ( "2.0.0" )
#define MLD_VERSION_MAJOR_ ( 2 )
#define MLD_VERSION_MINOR_ ( 0 )
#define MLD_PATCHLEVEL_ ( 0 )
#define MLD_SMOOTHER_TYPE_ (  1          )
#define MLD_SUB_SOLVE_ (  2 )
#define MLD_SUB_RESTR_ (  3 )
#define MLD_SUB_PROL_ (  4 )
#define MLD_SUB_REN_ (  5 )
#define MLD_SUB_OVR_ (  6 )
#define MLD_SUB_FILLIN_ (  8 )
#define MLD_SLU_PTR_ ( 10 )
#define MLD_UMF_SYMPTR_ ( 12 )
#define MLD_UMF_NUMPTR_ ( 14 )
#define MLD_SLUD_PTR_ ( 16 )
#define MLD_PREC_STATUS_ ( 18  )
#define MLD_ML_TYPE_ ( 20 )
#define MLD_SMOOTHER_SWEEPS_PRE_ ( 21 )
#define MLD_SMOOTHER_SWEEPS_POST_ ( 22 )
#define MLD_SMOOTHER_POS_ ( 23 )
#define MLD_AGGR_KIND_ ( 24 )
#define MLD_AGGR_ALG_ ( 25 )
#define MLD_AGGR_OMEGA_ALG_ ( 26 )
#define MLD_AGGR_EIG_ ( 27 )
#define MLD_AGGR_FILTER_ ( 28 )
#define MLD_COARSE_MAT_ ( 29 )
#define MLD_COARSE_SOLVE_ ( 30  )
#define MLD_COARSE_SWEEPS_ ( 31 )
#define MLD_COARSE_FILLIN_ ( 32 )
#define MLD_COARSE_SUBSOLVE_ ( 33 )
#define MLD_SMOOTHER_SWEEPS_ ( 34 )
#define MLD_IFPSZ_ ( 36 )
#define MLD_MIN_PREC_ ( 0 )
#define MLD_NOPREC_ ( 0 )
#define MLD_JAC_ ( 1 )
#define MLD_BJAC_ ( 2 )
#define MLD_AS_ ( 3 )
#define MLD_MAX_PREC_ ( 3 )
#define MLD_SLV_DELTA_ ( MLD_MAX_PREC_+1 )
#define MLD_F_NONE_ ( MLD_SLV_DELTA_+0 )
#define MLD_DIAG_SCALE_ ( MLD_SLV_DELTA_+1 )
#define MLD_ILU_N_ ( MLD_SLV_DELTA_+2 )
#define MLD_MILU_N_ ( MLD_SLV_DELTA_+3 )
#define MLD_ILU_T_ ( MLD_SLV_DELTA_+4 )
#define MLD_SLU_ ( MLD_SLV_DELTA_+5 )
#define MLD_UMF_ ( MLD_SLV_DELTA_+6 )
#define MLD_SLUDIST_ ( MLD_SLV_DELTA_+7 )
#define MLD_MAX_SUB_SOLVE_ ( MLD_SLV_DELTA_+7 )
#define MLD_MIN_SUB_SOLVE_ ( MLD_DIAG_SCALE_ )
#define MLD_RENUM_NONE_ (0 )
#define MLD_RENUM_GLB_ (1 )
#define MLD_RENUM_GPS_ (2 )
#define MLD_MAX_RENUM_ (1 )
#define MLD_NO_ML_ ( 0 )
#define MLD_ADD_ML_ ( 1 )
#define MLD_MULT_ML_ ( 2 )
#define MLD_NEW_ML_PREC_ ( 3 )
#define MLD_MAX_ML_TYPE_ ( MLD_MULT_ML_ )
#define MLD_PRE_SMOOTH_ (1 )
#define MLD_POST_SMOOTH_ (2 )
#define MLD_TWOSIDE_SMOOTH_ (3 )
#define MLD_MAX_SMOOTH_ (MLD_TWOSIDE_SMOOTH_ )
#define MLD_NO_SMOOTH_ ( 0 )
#define MLD_SMOOTH_PROL_ ( 1 )
#define MLD_MIN_ENERGY_ ( 2 )
#define MLD_BIZ_PROL_ ( 3 )
#define MLD_MAX_AGGR_KIND_ (MLD_MIN_ENERGY_ )
#define MLD_NO_FILTER_MAT_ (0 )
#define MLD_FILTER_MAT_ (1 )
#define MLD_MAX_FILTER_MAT_ (MLD_NO_FILTER_MAT_ )
#define MLD_DEC_AGGR_ (0 )
#define MLD_SYM_DEC_AGGR_ (1 )
#define MLD_GLB_AGGR_ (2 )
#define MLD_NEW_DEC_AGGR_ (3 )
#define MLD_NEW_GLB_AGGR_ (4 )
#define MLD_MAX_AGGR_ALG_ (MLD_DEC_AGGR_ )
#define MLD_EIG_EST_ (0 )
#define MLD_USER_CHOICE_ (999 )
#define MLD_MAX_NORM_ (0 )
#define MLD_DISTR_MAT_ (0 )
#define MLD_REPL_MAT_ (1 )
#define MLD_MAX_COARSE_MAT_ (MLD_REPL_MAT_   )
#define MLD_PREC_BUILT_ (98765 )
#define MLD_SUB_ILUTHRS_ ( 1 )
#define MLD_AGGR_OMEGA_VAL_ ( 2 )
#define MLD_AGGR_THRESH_ ( 3 )
#define MLD_COARSE_ILUTHRS_ ( 4 )
#define MLD_RFPSZ_ ( 8 )
#define MLD_L_PR_ (1 )
#define MLD_U_PR_ (2 )
#define MLD_BP_ILU_AVSZ_ (2 )
#define MLD_AP_ND_ (3 )
#define MLD_AC_ (4 )
#define MLD_SM_PR_T_ (5 )
#define MLD_SM_PR_ (6 )
#define MLD_SMTH_AVSZ_ (6 )
#define MLD_MAX_AVSZ_ (MLD_SMTH_AVSZ_  )
#ifdef __cplusplus
}
#endif