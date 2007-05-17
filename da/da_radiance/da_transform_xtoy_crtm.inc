subroutine da_transform_xtoy_crtm ( xa, iv, xp, y )

   !---------------------------------------------------------------------------
   !  PURPOSE: transform from analysis increment to 
   !                          pertubation radiance.
   !
   !  METHOD:  delta_y = H delta_x
   !           1. input reference state of CRTM_TL
   !           2. interpolate analysis increment to obs location
   !           3. Call CRTM_TL
   !
   !  HISTORY: 11/16/2006 - Creation            Zhiquan Liu
   !
   !---------------------------------------------------------------------------

   IMPLICIT NONE

   TYPE (x_type), INTENT(IN)      :: xa       ! delta_x
   TYPE (xpose_type), INTENT(IN)  :: xp       ! Domain decomposition vars.
   TYPE (y_type),  INTENT(INOUT)  :: y        ! H' delta_x
   TYPE (ob_type), INTENT(IN)     :: iv       ! O-B structure.

   INTEGER                        :: k  ! Index dimension.

   INTEGER            :: inst, num_rad, nchanl, n
   real, allocatable :: temperature(:,:)
   real, allocatable :: absorber(:,:)
   real, allocatable :: psfc(:)

#if defined(CRTM)
   ! CRTM local varaibles and types
   INTEGER :: wmo_sensor_id, Error_Status, Allocate_Status
   TYPE( CRTM_RTSolution_type ), ALLOCATABLE :: RTSolution(:),RTSolution_TL(:)
   TYPE( CRTM_Atmosphere_type )   :: Atmosphere, Atmosphere_TL
   TYPE( CRTM_Surface_type )      :: Surface, Surface_TL
   TYPE( CRTM_GeometryInfo_type ) :: GeometryInfo
   !TYPE( CRTM_Options_type )      :: Options
#endif
!---------------------------------------------------------

#if !defined(CRTM)
    call da_error(__FILE__,__LINE__, &
       (/"Must compile with $CRTM option for radiances"/))
#else

   IF ( iv%num_inst < 1 ) return

   if (trace_use) call da_trace_entry("da_transform_xtoy_crtm")

!----------------------------------------------------------------------------
! CRTM allocation
!
! Atmosphere structure
    Atmosphere%n_Layers=(xp%kte-xp%kts)+1   ! number of vertical levels
    Atmosphere%n_Absorbers=2
    Atmosphere%n_Clouds=0
    Atmosphere%n_Aerosols=0
    if (crtm_cloud) Atmosphere%n_Clouds=6                       

    Error_Status = CRTM_Allocate_Atmosphere( Atmosphere%n_Layers, &
                                             Atmosphere%n_Absorbers, &
                                             Atmosphere%n_Clouds, &
                                             Atmosphere%n_Aerosols, &
                                             Atmosphere)
    if ( Error_Status /= 0 ) THEN
       call da_error(__FILE__,__LINE__, &
         (/"Error in allocatting CRTM Atmosphere Structure"/))
    endif

    Atmosphere%Absorber_ID(1)=H2O_ID
    Atmosphere%Absorber_ID(2)=O3_ID

    if (crtm_cloud) then
       Atmosphere%Cloud(1)%Type=WATER_CLOUD
       Atmosphere%Cloud(2)%Type=ICE_CLOUD
       Atmosphere%Cloud(3)%Type=RAIN_CLOUD
       Atmosphere%Cloud(4)%Type=SNOW_CLOUD
       Atmosphere%Cloud(5)%Type=GRAUPEL_CLOUD
       Atmosphere%Cloud(6)%Type=HAIL_CLOUD
    end if

!-------------------------------------------------------------------------------

   do inst = 1, iv%num_inst                 ! loop for sensor
      if ( iv%instid(inst)%num_rad < 1 ) cycle
      num_rad   = iv%instid(inst)%num_rad

  ! CRTM channel information structure
      Error_Status = CRTM_Set_ChannelInfo(Sensor_Descriptor(inst),ChannelInfo)
      if ( Error_Status /= 0) then
         call da_error(__FILE__,__LINE__, &
          (/"Error in calling CRTM_Set_ChannelInfo"/))
      endif
      nchanl    = ChannelInfo%n_channels
                                        
  ! Allocate forward model solution RTSolution array to number of channels
      ALLOCATE( RTSolution( ChannelInfo%n_Channels ), &
                RTSolution_TL( ChannelInfo%n_Channels ), &
               STAT = Allocate_Status )
      IF ( Allocate_Status /= 0 ) THEN
         call da_error(__FILE__,__LINE__, &
          (/"Error in allocatting RTSolution"/))
      END IF

  ! CRTM Surface Structure
      if (trim(crtm_sensor_name(rtminit_sensor(inst))) =='amsua') then
         wmo_sensor_id=WMO_AMSUA
      elseif (trim(crtm_sensor_name(rtminit_sensor(inst))) =='amsub') then
         wmo_sensor_id=WMO_AMSUB
      elseif (trim(crtm_sensor_name(rtminit_sensor(inst))) =='amsre') then
         wmo_sensor_id=WMO_AMSRE
      elseif (trim(crtm_sensor_name(rtminit_sensor(inst))) =='ssmi') then
         wmo_sensor_id=WMO_SSMI
      else
         wmo_sensor_id=INVALID_WMO_SENSOR_ID
      endif

      Error_Status = CRTM_Allocate_Surface( nchanl,     &  ! Input
                                   Surface)  ! Output
      if ( Error_Status /= 0 ) THEN
        call da_error(__FILE__,__LINE__, &
          (/"Error in allocatting CRTM Surface Structure"/))
      endif

  ! CRTM Options structure
      !Options%n_channels = nchanl
      !Error_Status = CRTM_Allocate_Options( nchanl,     &  ! Input
      !                             Options)  ! Output
      !if ( Error_Status /= 0 ) THEN
      !  call da_error(__FILE__,__LINE__, &
      !    (/"Error in allocatting CRTM Options Structure"/))
      !endif

      allocate (temperature(atmosphere%n_layers, num_rad))
      allocate (absorber(atmosphere%n_layers, num_rad))
      allocate (psfc(num_rad))

      do k=xp%kts,xp%kte ! from bottem to top
         call da_interp_lin_2d_new( xa%t(:,:,k), xp%ims, xp%ime, xp%jms, xp%jme, &
            iv%instid(inst)%loc_i, iv%instid(inst)%loc_j, &
            iv%instid(inst)%loc_dx, iv%instid(inst)%loc_dy, &
            iv%instid(inst)%loc_dxm, iv%instid(inst)%loc_dym, &
            temperature(xp%kte-k+1,:), num_rad)

         call da_interp_lin_2d_new( xa%q(:,:,k), xp%ims, xp%ime, xp%jms, xp%jme, &
            iv%instid(inst)%loc_i, iv%instid(inst)%loc_j, &
            iv%instid(inst)%loc_dx, iv%instid(inst)%loc_dy, &
            iv%instid(inst)%loc_dxm, iv%instid(inst)%loc_dym, &
            absorber(xp%kte-k+1,:), num_rad)

         where (iv%instid(inst)%pm(xp%kte-k+1,:) < 75.0) &
            absorber(xp%kte-k+1,:) = 0.0
      end do

      call da_interp_lin_2d_new( xa%psfc, xp%ims, xp%ime, xp%jms, xp%jme, &
         iv%instid(inst)%loc_i, iv%instid(inst)%loc_j, &
         iv%instid(inst)%loc_dx, iv%instid(inst)%loc_dy, &
         iv%instid(inst)%loc_dxm, iv%instid(inst)%loc_dym, &
         psfc(:), num_rad )

      do n= 1, num_rad           ! loop for pixel
            
      ! [1.1] Get horizontal interpolation weights:

      ! [1.3] Extract base state Atmosphere variables 
            atmosphere%level_pressure(0) = iv%instid(inst)%pf(0,n)
           do k=1,atmosphere%n_layers
            atmosphere%pressure(k) = iv%instid(inst)%pm(k,n)
            atmosphere%level_pressure(k) = iv%instid(inst)%pf(k,n)
            atmosphere%temperature(k) = iv%instid(inst)%tm(k,n)
            atmosphere%absorber(k,1) = iv%instid(inst)%qm(k,n)
           if (crtm_cloud) then
            atmosphere%cloud(1)%water_content(k)=iv%instid(inst)%qcw(k,n)
            atmosphere%cloud(2)%water_content(k)=iv%instid(inst)%qci(k,n)
            atmosphere%cloud(3)%water_content(k)=iv%instid(inst)%qrn(k,n)
            atmosphere%cloud(4)%water_content(k)=iv%instid(inst)%qsn(k,n)
            atmosphere%cloud(5)%water_content(k)=iv%instid(inst)%qgr(k,n)
            atmosphere%cloud(6)%water_content(k)=0.
            atmosphere%cloud(1)%effective_radius(k)=10.
            atmosphere%cloud(2)%effective_radius(k)=200.
            atmosphere%cloud(3)%effective_radius(k)=200.
            atmosphere%cloud(4)%effective_radius(k)=200.
            atmosphere%cloud(5)%effective_radius(k)=200.
            atmosphere%cloud(6)%effective_radius(k)=200.
           end if
           enddo

      ! [1.4] User-supplied emissivity
           !Options%emissivity_switch = 1
           !Options%emissivity(1:Options%n_channels) = &
           !    iv%instid(inst)%emiss(1:Options%n_channels,n)

      ! [1.4] CRTM Surface parameter data
     Surface%Land_Coverage=iv%instid(inst)%land_coverage(n) 
     Surface%Water_Coverage=iv%instid(inst)%water_coverage(n) 
     Surface%Snow_Coverage=iv%instid(inst)%snow_coverage(n)
     Surface%Ice_Coverage=iv%instid(inst)%ice_coverage(n)

     if (Surface%Land_Coverage > 0.) then
       Surface%Land_Type=GRASS_SOIL           ! land type (User guide appendix 3)
       Surface%Land_Temperature=iv%instid(inst)%ts(n)      ! K
       Surface%Soil_Moisture_Content=iv%instid(inst)%smois(n)  !0.05    ! volumetric water content (g/cm**3)
       !Surface%Canopy_Water_Content=0.05      ! gravimetric water content
       Surface%Vegetation_Fraction=iv%instid(inst)%vegtyp(n)
       Surface%Soil_Temperature=iv%instid(inst)%tslb(n)
     endif
     if (Surface%Water_Coverage > 0.) then
       !Surface%Water_Type=SEA_WATER          ! (Currently NOT used)
       Surface%Water_Temperature=iv%instid(inst)%ts(n)     ! K
       Surface%Wind_Speed=sqrt((iv%instid(inst)%u10(n))**2+ &
                               (iv%instid(inst)%v10(n))**2)  ! m/sec
       !surface%Wind_Direction=0.0            ! NOT used
       Surface%Salinity=33.                   ! ppmv
     endif
     if (Surface%Snow_Coverage > 0.) then
       Surface%Snow_Type=NEW_SNOW             ! User guide appendix 3
       Surface%Snow_Temperature=iv%instid(inst)%ts(n)      ! K
       Surface%Snow_Depth=iv%instid(inst)%snowh(n)         ! mm
       !Surface%Snow_Density=0.2               ! g/cm**3
       !Surface%Snow_Grain_Size=2.0            ! mm
     endif
     if (Surface%Ice_Coverage > 0.) then
       !Surface%Ice_Type=FRESH_ICE             ! NO Table offered, single example is FRESH_ICE
       Surface%Ice_Temperature=iv%instid(inst)%ts(n)       ! K
       Surface%Ice_Thickness=10.              ! mm
       !Surface%Ice_Density=0.9                ! g/cm**3
       !Surface%Ice_Roughness=0.               ! NO Table offered, single example is ZERO
     endif
     Surface%SensorData%n_channels = nchanl
     Surface%SensorData%Sensor_ID  = wmo_sensor_id
     Surface%SensorData%Tb(1:nchanl) = iv%instid(inst)%tb_inv(1:nchanl,n) + &
                                           iv%instid(inst)%tb_xb(1:nchanl,n)

      ! -- Copy the TL atmosphere structure
      Error_Status = CRTM_Assign_Atmosphere( Atmosphere, Atmosphere_TL )

      IF ( Error_Status /= 0 ) THEN
        call da_error(__FILE__,__LINE__, &
          (/"Error copying Atmosphere_TL structure"/))
      END IF

      ! -- Copy the TL surface structure
      Error_Status = CRTM_Assign_Surface( Surface, Surface_TL )

      IF ( Error_Status /= 0 ) THEN
        call da_error(__FILE__,__LINE__, &
          (/"Error copying Surface_TL structure"/))
      END IF

    ! -- Zero the TL outputs
    ! Important: adjoint variables must be initialized
    CALL CRTM_Zero_Atmosphere( Atmosphere_TL )
    CALL CRTM_Zero_Surface( Surface_TL )
       
    Atmosphere_TL%Temperature(xp%kts:xp%kte)             = temperature(xp%kts:xp%kte,n)
    Atmosphere_TL%Absorber(xp%kts:xp%kte,1)              = absorber(xp%kts:xp%kte,n)
    Atmosphere_TL%Level_Pressure(Atmosphere_TL%n_Layers) = psfc(n)

              Atmosphere_TL%Level_Pressure(Atmosphere%n_Layers)= &
                         0.01*Atmosphere_TL%Level_Pressure(Atmosphere%n_Layers)
              Atmosphere_TL%Absorber(:,1) = 1000.*Atmosphere_TL%Absorber(:,1) ! in g/kg

      ! [1.5] CRTM GeometryInfo Structure
        GeometryInfo%Sensor_Zenith_Angle=iv%instid(inst)%satzen(n)
        GeometryInfo%Source_Zenith_Angle=iv%instid(inst)%solzen(n)
   !     GeometryInfo%Satellite_Height=830.
   !     GeometryInfo%Sensor_Scan_Angle=
   !     GeometryInfo%Sensor_Zenith_Angle=
   !     GeometryInfo%Sensor_Scan_Angle=
   !     GeometryInfo%Source_Zenith_Angle=

      ! [1.6] Call CRTM_TL model

         call da_crtm_tl (nchanl, Atmosphere,   &
                            Surface,      &
                            Atmosphere_TL,&
                            Surface_TL,   &
                            GeometryInfo, &
                            ChannelInfo,  &
                            RTSolution,   &
                            RTSolution_TL)
      
         !Error_Status = CRTM_Tangent_Linear(Atmosphere,   &
         !                   Surface,      &
         !                   Atmosphere_TL,&
         !                   Surface_TL,   &
         !                   GeometryInfo, &
         !                   ChannelInfo,  &
         !                   RTSolution,   &
         !                   RTSolution_TL)  !,&
         !                   !Options = Options)
         !if ( Error_Status /= 0 ) THEN
         !     call da_error(__FILE__,__LINE__, &
         !        (/"Error in calling CRTM_Tangent_Linear"/))
         !endif

      !-------------------------------------------------------------------
      ! [1.7] assign Hdx :
      !-------------------------------------------------------------------
         y%instid(inst)%tb(:,n) = RTSolution_TL(:)%brightness_temperature
         !if (n <= 10 ) write(6,'(15f8.3)') RTSolution_TL(:)%brightness_temperature

         Error_Status = CRTM_Destroy_Atmosphere( Atmosphere_TL )
         if ( Error_Status /= 0 ) THEN
            call da_error(__FILE__,__LINE__, &
               (/"Error in deallocatting CRTM Atmosphere_TL Structure"/))
         endif

         Error_Status = CRTM_Destroy_Surface(Surface_TL)
         if ( Error_Status /= 0 ) THEN
            call da_error(__FILE__,__LINE__, &
               (/"Error in deallocatting CRTM Surface_TL Structure"/))
         endif

      end do  ! end loop for pixels 

      deallocate (temperature)
      deallocate (absorber)
      deallocate (psfc)     
                                                                                                                    
      !-------------------------------------------------------------------
      ! [2.0] Deallocating CRTM structures
      !-------------------------------------------------------------------
         deallocate( rtsolution, rtsolution_tl, STAT = Allocate_Status )
         IF ( Allocate_Status /= 0 ) THEN
            call da_error(__FILE__,__LINE__, &
              (/"Error in deallocatting RTSolution"/))
         END IF
             
         Error_Status = CRTM_Destroy_Surface(Surface)
         if ( Error_Status /= 0 ) THEN
            call da_error(__FILE__,__LINE__, &
               (/"Error in deallocatting CRTM Surface Structure"/))
         endif

   end do     ! end loop for sensor

      !-------------------------------------------------------------------
      ! [3.0] Deallocating CRTM Atmosphere structures
      !-------------------------------------------------------------------
    Error_Status = CRTM_Destroy_Atmosphere( Atmosphere )
    if ( Error_Status /= 0 ) THEN
       call da_error(__FILE__,__LINE__, &
         (/"Error in deallocatting CRTM Atmosphere Structure"/))
    endif

   if (trace_use) call da_trace_exit("da_transform_xtoy_crtm")
#endif

end subroutine da_transform_xtoy_crtm
