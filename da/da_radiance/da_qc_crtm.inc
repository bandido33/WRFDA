subroutine da_qc_crtm (ob, iv)

   !---------------------------------------------------------------------------
   ! Purpose: perform quality control for radiance data.
   !
   ! METHOD:  seperated QC for each sensor
   !---------------------------------------------------------------------------

   implicit none

   type (y_type),  intent(in)      :: ob         ! Observation structure.
   type (iv_type), intent(inout)   :: iv         ! O-B structure.

   integer :: i, nchan
   logical   :: amsua, amsub, hirs, msu,airs,hsb, ssmis, mhs

   if (trace_use) call da_trace_entry("da_qc_crtm")
#ifdef CRTM

   do i = 1, iv%num_inst
      nchan    = iv%instid(i)%nchan

      amsua = trim(rttov_inst_name(rtminit_sensor(i))) == 'amsua'
      amsub = trim(rttov_inst_name(rtminit_sensor(i))) == 'amsub'
      hirs  = trim(rttov_inst_name(rtminit_sensor(i))) == 'hirs'
      msu   = trim(rttov_inst_name(rtminit_sensor(i))) == 'msu'
      airs  = trim(rttov_inst_name(rtminit_sensor(i))) == 'airs'
      hsb   = trim(rttov_inst_name(rtminit_sensor(i))) == 'hsb'
      ssmis = trim(rttov_inst_name(rtminit_sensor(i))) == 'ssmis'
      mhs   = trim(rttov_inst_name(rtminit_sensor(i))) == 'mhs'

      if (hirs) then
         call da_qc_hirs(i,nchan,ob,iv)
      else if (airs) then
         call da_qc_airs(i,nchan,ob,iv)
      else if ( hsb ) then
         ! call da_qc_hsb(i,nchan,ob,iv)
         call da_warning(__FILE__,__LINE__,(/'QC Not implemented for HSB'/))
      else if (amsua) then
         call da_qc_amsua(i,nchan,ob,iv)
      else if ( amsub ) then
         call da_qc_amsub(i,nchan,ob,iv)
      else if (msu) then
         ! call da_qc_msu(i,nchan, ob,iv)
         call da_warning(__FILE__,__LINE__,(/'QC Not implemented for MSU'/))
      else if (ssmis) then
         call da_qc_ssmis(i,nchan,ob,iv)
      else if (mhs) then
         call da_qc_mhs(i,nchan,ob,iv)
      else
         write(unit=message(1),fmt='(A,A)') &
            "Unrecognized instrument",trim(rttov_inst_name(rtminit_sensor(i)))
         call da_error(__FILE__,__LINE__,message(1:1))
      end if

   end do
#endif

   if (trace_use) call da_trace_exit("da_qc_crtm")

end subroutine da_qc_crtm


