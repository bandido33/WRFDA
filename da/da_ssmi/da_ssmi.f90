module da_ssmi


   use module_dm, only : wrf_dm_sum_integer
   use module_domain, only : xpose_type, xb_type, domain
   use module_ssmi, only : cal_sigma_v,tb,effht,epsalt,spemiss,tbatmos,&
      roughem,effang,tbatmos,filter

   use da_control, only : obs_qc_pointer,max_ob_levels,missing_r, &
      v_interp_p, v_interp_h, check_max_iv_print, t_roughem, t_kelvin, &
      missing, max_error_uv, max_error_t, rootproc, pi, &
      max_error_p,max_error_q, check_max_iv_unit,check_max_iv,  &
      max_stheight_diff,missing_data,max_error_bq,max_error_slp, &
      max_error_bt, max_error_buv, max_error_thickness, mkz, &
      num_ssmt2_tot,num_ssmt1_tot,max_error_rh,max_error_tb, max_error_pw, &
      trace_use,test_wrfvar,stdout, use_ssmiretrievalobs, use_ssmitbobs, &
      num_ssmi_tb_tot,num_ssmi_rv_tot,num_ssmi_tot, global, print_detail_obs, &
      its,ite,jts,jte,kts,kte,ims,ime,jms,jme,kms,kme,ids,ide,jds,jde
   use da_define_structures, only : maxmin_type, ob_type, y_type, jo_type, &
      bad_data_type, x_type, number_type, bad_data_type, &
      maxmin_type,residual_ssmi_retrieval_type, &
      residual_ssmi_tb_type, model_loc_type, info_type, field_type, &
      count_obs_number_type, ssmi_retrieval_type, ssmi_tb_type, ssmt1_type, &
      ssmt2_type
   use da_interpolation, only : da_interp_lin_2d, da_interp_lin_2d_adj, &
      da_interp_lin_3d,da_interp_lin_3d_adj,da_to_zk
   use da_par_util, only : da_proc_stats_combine
   use da_par_util1, only : da_proc_sum_int
   use da_reporting, only : da_warning, message, da_error
   use da_statistics, only : da_stats_calculate
   use da_tools, only : da_max_error_qc, da_residual, da_ll_to_xy
   use da_tools1, only : da_get_unit, da_free_unit
   use da_tracing, only : da_trace_entry, da_trace_exit

   ! The "stats_ssmi_rv_type" is ONLY used locally in da_ssmi_rv:

   type maxmin_ssmi_rv_stats_type
      type (maxmin_type)         :: tpw      ! Toatl precipitable water cm
      type (maxmin_type)         :: Speed    ! Wind speed (m/s)
   end type maxmin_ssmi_rv_stats_type

   type stats_ssmi_retrieval_type
      type (maxmin_ssmi_rv_stats_type)      :: maximum, minimum
      type (residual_ssmi_retrieval_type)   :: average, rms_err
   end type stats_ssmi_retrieval_type

   ! The "stats_ssmi_tb_type" is ONLY used locally in da_ssmi_tb:

   type maxmin_ssmi_tb_stats_type
      type (maxmin_type)         :: tb19v    ! brightness temperature (K)
      type (maxmin_type)         :: tb19h    ! brightness temperature (K)
      type (maxmin_type)         :: tb22v    ! brightness temperature (K)
      type (maxmin_type)         :: tb37v    ! brightness temperature (K)
      type (maxmin_type)         :: tb37h    ! brightness temperature (K)
      type (maxmin_type)         :: tb85v    ! brightness temperature (K)
      type (maxmin_type)         :: tb85h    ! brightness temperature (K)
   end type maxmin_ssmi_tb_stats_type

   type stats_ssmi_tb_type
      type (maxmin_ssmi_tb_stats_type)  :: maximum, minimum
      type (residual_ssmi_tb_type)      :: average, rms_err
   end type stats_ssmi_tb_type


contains

#include "da_ao_stats_ssmi.inc"
#include "da_ao_stats_ssmi_rv.inc"
#include "da_ao_stats_ssmi_tb.inc"
#include "da_read_ssmi.inc"
#include "da_scan_ssmi.inc"
#include "da_jo_and_grady_ssmi.inc"
#include "da_jo_and_grady_ssmi_rv.inc"
#include "da_jo_and_grady_ssmi_tb.inc"
#include "da_residual_ssmi.inc"
#include "da_residual_ssmi_rv.inc"
#include "da_residual_ssmi_tb.inc"
#include "da_oi_stats_ssmi.inc"
#include "da_oi_stats_ssmi_rv.inc"
#include "da_oi_stats_ssmi_tb.inc"
#include "da_transform_xtospeed.inc"
#include "da_transform_xtospeed_lin.inc"
#include "da_transform_xtospeed_adj.inc"
#include "da_transform_xtoseasfcwind.inc"
#include "da_transform_xtoseasfcwind_lin.inc"
#include "da_transform_xtoseasfcwind_adj.inc"
#include "da_transform_xtotb.inc"
#include "da_transform_xtotb_lin.inc"
#include "da_transform_xtotb_adj.inc"
#include "da_transform_xtoy_ssmi.inc"
#include "da_transform_xtoy_ssmi_adj.inc"
#include "da_transform_xtoy_ssmi_rv.inc"
#include "da_transform_xtoy_ssmi_rv_adj.inc"
#include "da_transform_xtoy_ssmi_tb.inc"
#include "da_transform_xtoy_ssmi_tb_adj.inc"
#include "da_transform_xtozrhoq.inc"
#include "da_transform_xtozrhoq_lin.inc"
#include "da_transform_xtozrhoq_adj.inc"
#include "da_jo_and_grady_ssmt1.inc"
#include "da_jo_and_grady_ssmt2.inc"
#include "da_residual_ssmt1.inc"
#include "da_residual_ssmt2.inc"
#include "da_check_max_iv_ssmi_rv.inc"
#include "da_check_max_iv_ssmi_tb.inc"
#include "da_check_max_iv_ssmt1.inc"
#include "da_check_max_iv_ssmt2.inc"
#include "da_get_innov_vector_ssmi.inc"
#include "da_get_innov_vector_ssmi_rv.inc"
#include "da_get_innov_vector_ssmi_tb.inc"
#include "da_get_innov_vector_ssmt1.inc"
#include "da_get_innov_vector_ssmt2.inc"
#include "da_ao_stats_ssmt1.inc"
#include "da_ao_stats_ssmt2.inc"
#include "da_oi_stats_ssmt1.inc"
#include "da_oi_stats_ssmt2.inc"
#include "da_print_stats_ssmt1.inc"
#include "da_print_stats_ssmt2.inc"
#include "da_transform_xtoy_ssmt1.inc"
#include "da_transform_xtoy_ssmt1_adj.inc"
#include "da_transform_xtoy_ssmt2.inc"
#include "da_transform_xtoy_ssmt2_adj.inc"
#include "da_calculate_grady_ssmi.inc"
#include "da_calculate_grady_ssmt1.inc"
#include "da_calculate_grady_ssmt2.inc"

#include "da_tb_adj.inc"
#include "da_sigma_v_adj.inc"
#include "da_effang_adj.inc"
#include "da_effht_adj.inc"
#include "da_epsalt_adj.inc"
#include "da_roughem_adj.inc"
#include "da_spemiss_adj.inc"
#include "da_tbatmos_adj.inc"

#include "da_tb_tl.inc"
#include "da_tbatmos_tl.inc"
#include "da_effht_tl.inc"
#include "da_roughem_tl.inc"
#include "da_spemiss_tl.inc"
#include "da_effang_tl.inc"
#include "da_epsalt_tl.inc"
#include "da_sigma_v_tl.inc"
   
end module da_ssmi

