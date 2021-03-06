module da_setup_structures

   !---------------------------------------------------------------------------
   ! Purpose: Sets up various structures.
   !---------------------------------------------------------------------------

   use module_domain, only : xb_type, ep_type, domain

   use da_define_structures, only : xbx_type,be_subtype, be_type, y_type, &
      iv_type,da_allocate_background_errors,da_allocate_observations
   use da_control, only : trace_use,vert_evalue,stdout,rootproc, &
      analysis_date,coarse_ix,coarse_ds,map_projection,coarse_jy, c2,dsm,phic, &
      pole, cone_factor, start_x,base_pres,ptop,psi1,start_y, base_lapse,base_temp,truelat2_3dv, &
      truelat1_3dv,xlonc,t0,num_fft_factors,pi,print_detail_spectral, global, &
      use_radar_rf, num_ob_indexes,kts, kte, &
      max_fgat_time, num_fgat_time, dt_cloud_model, &
      use_ssmiretrievalobs,use_radarobs,use_ssmitbobs,use_qscatobs, num_procs, &
      num_pseudo, missing, ob_format, ob_format_bufr,ob_format_ascii, &
      use_airepobs, test_dm_exact, use_amsuaobs, use_amsubobs, &
      use_airsobs, use_bogusobs, sfc_assi_options, use_eos_amsuaobs, &
      use_filtered_rad, use_eos_radobs, use_gpsrefobs, use_hirs2obs, &
      use_hsbobs,use_hirs3obs, use_gpspwobs, use_metarobs, use_msuobs, &
      use_kma1dvar,use_pilotobs, use_polaramvobs, use_rad, crtm_cloud, use_soundobs,use_mtgirsobs, &
      use_ssmt1obs,use_ssmt2obs, use_shipsobs, use_satemobs, use_synopobs, &
      use_radar_rv,use_profilerobs, use_obsgts, use_geoamvobs, use_buoyobs, &
      alphacv_method,its,ite,jts,jte,cv_size_domain_jb, &
      cv_size_domain_je, cv_size_domain,ids,ide,jds,jde,kde,ensdim_alpha, &
      lat_stats_option,alpha_std_dev,alpha_corr_scale,len_scaling1, &
      len_scaling2,len_scaling3,len_scaling4,len_scaling5,max_vert_var1, &
      max_vert_var2,max_vert_var3,max_vert_var4,print_detail_be, &
      test_statistics, var_scaling1,var_scaling2,var_scaling3,var_scaling4, &
      var_scaling5,vert_corr,max_vert_var5,power_truncation,alpha_truncation, &
      print_detail_regression,gas_constant, use_airsretobs, &
      filename_len, use_ssmisobs, gravity, t_triple, use_hirs4obs, use_mhsobs, &
      ims,ime,jms,jme,kms,kme,kds, vert_corr_2, alphacv_method_xa, vert_evalue_global, &
      vert_evalue_local, obs_names, num_ob_indexes, &
      sound, mtgirs, synop, profiler, gpsref, gpspw, polaramv, geoamv, ships, metar, &
      satem, radar, ssmi_rv, ssmi_tb, ssmt1, ssmt2, airsr, pilot, airep, &
      bogus, buoy, qscat, radiance, pseudo, trace_use_dull, kts,kte, &
      use_simulated_rad, use_pseudo_rad, pseudo_rad_platid, pseudo_rad_satid, &
      pseudo_rad_senid, rtminit_nsensor, rtminit_platform, rtminit_satid, &
      rtminit_sensor, thinning, qc_rad,& 
      num_pseudo,pseudo_x, pseudo_y, pseudo_z, pseudo_var,pseudo_val, pseudo_err,&
      fg_format, fg_format_kma_global

   use da_obs, only : da_fill_obs_structures, da_store_obs_grid_info
   use da_obs_io, only : da_scan_obs_bufr,da_read_obs_bufr,da_read_obs_radar, &
      da_scan_obs_radar,da_scan_obs_ascii,da_read_obs_ascii
   use da_par_util, only : da_patch_to_global
#if defined(RTTOV) || defined(CRTM)
   use da_radiance, only : da_setup_radiance_structures
#endif
   use da_reporting, only : da_error,message, da_warning, da_message
   use da_recursive_filter, only : da_calculate_rf_factors
   use da_spectral, only : da_initialize_h,da_calc_power_spectrum
   use da_ssmi, only : da_read_obs_ssmi,da_scan_obs_ssmi
   use da_tools_serial, only : da_get_unit, da_free_unit, da_array_print, da_find_fft_factors, &
      da_find_fft_trig_funcs
   use da_tracing, only : da_trace_entry, da_trace_exit
   use da_vtox_transforms, only : da_check_eof_decomposition

   implicit none

contains

#include "da_get_vertical_truncation.inc"
#include "da_interpolate_regcoeff.inc"
#include "da_rescale_background_errors.inc"
#include "da_setup_background_errors.inc"
#include "da_setup_be_global.inc"
#include "da_setup_be_regional.inc"
#include "da_setup_cv.inc"
#include "da_chgvres.inc"
#include "da_setup_flow_predictors.inc"
#include "da_setup_obs_structures.inc"
#include "da_setup_obs_structures_ascii.inc"
#include "da_setup_obs_structures_bufr.inc"
#include "da_setup_obs_interp_wts.inc"
#include "da_setup_runconstants.inc"
#include "da_cloud_model.inc"
#include "da_lcl.inc"
#include "da_cumulus.inc"
#include "da_qfrmrh.inc"
#include "da_write_increments.inc"
#include "da_write_kma_increments.inc"
#include "da_get_bins_info.inc"
#include "da_truncate_spectra.inc"

end module da_setup_structures
