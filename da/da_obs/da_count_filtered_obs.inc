subroutine da_count_filtered_obs(&
                    ts0, tlp, ptop, ps0, map, ds, ide, jde,&   
                    phic, xlonc, truelat1, truelat2)
!-----------------------------------------------------------------------------!
!  Purpose: Scans intermediate Filtered Obs file, 
!           counts various obs type and writes on filtered_obs_unit              
!-----------------------------------------------------------------------------!
! Original code:      10/18/2005            Syed RH Rizvi
! Update History:     
!      06/01/2006  - Updated for MPI run            Syed RH Rizvi
!      06/01/2006  - Updated for AIRS retrievals    Syed RH Rizvi
!      10/21/2006  - Update for MPI                 Syed RH Rizvi
!                    Now writing only header 
!                     
!-----------------------------------------------------------------------------!
   implicit none
   REAL,              intent(in) :: ts0, tlp, ptop, ps0, ds
   REAL,              intent(in) :: phic, xlonc, truelat1, truelat2
   INTEGER,           intent(in) :: map, ide, jde
!
   INTEGER                      :: i, k, iost, fm
   TYPE (multi_level_type)      :: platform
   REAL                         :: height_error
   INTEGER                      :: num_synop, &
                                   num_metar, &
                                   num_ships, &
                                   num_buoy, &
                                   num_sound, &
                                   num_airep, &
                                   num_pilot, &
                                   num_geoamv, &
                                   num_polaramv, &
                                   num_gpspw, &
                                   num_gpsref, &
                                   num_profiler, &          
                                   num_qscat, &
                                   num_ssmt1, &
                                   num_ssmt2, &
                                   num_satem, &
                                   num_bogus, &
                                   num_airsr, &
                                   num_others
!
   INTEGER                        :: iunit, files, total_obs     
   INTEGER                        :: maxnes, numc, idd, nesti, nestj
   character*20                   :: filename
!----------------------------------------------------------------------------!
   if (trace_use) CALL da_trace_entry("da_count_filtered_obs")
!----------------------------------------------------------------------------!
   num_sound = 0
   num_synop = 0
   num_pilot = 0
   num_geoamv = 0
   num_polaramv = 0
   num_satem = 0
   num_airep = 0
   num_metar = 0
   num_ships = 0
   num_gpspw = 0
   num_gpsref = 0
   num_ssmt1 = 0
   num_ssmt2 = 0
   num_qscat = 0
   num_profiler = 0
   num_buoy = 0
   num_bogus = 0
   num_airsr = 0
   num_others = 0
!----------------------------------------------------------------------------!
   call da_get_unit(iunit)
!  Loop over all data files
!--------------------------
file_number: DO files = 0, num_procs-1
   write(UNIT=filename, FMT='(a,i3.3)') 'filtered_obs.',files  
   open(unit=iunit, file= trim(filename), form='formatted',iostat=iost)
   if(iost /= 0) &
   call da_error(__FILE__,__LINE__, (/"Cannot open "//trim(filename)/))

!  LOOP OVER RECORDS
!  -----------------
   reports: DO
!     READ STATION GENERAL INFO
!     =============================
      READ (iunit, FMT = fmt_info, IOSTAT = iost) &
                   platform%info%platform,    &
                   platform%info%date_char,   &
                   platform%info%name,        &
                   platform%info%levels,      &
                   platform%info%lat,         &
                   platform%info%lon,         &
                   platform%info%elv,         &
                   platform%info%id
      IF (iost /= 0) THEN
          WRITE (0,'(/A,I9)') ' END OF OBS UNIT: ',iunit
          WRITE (0,'(/A,I9)') ' IOSTAT:          ',iost
         EXIT reports
      ENDIF

!  Read surface Info
!  -------------------
      READ (iunit, FMT = fmt_srfc) platform%loc%slp, platform%loc%pw

! == levels < 1 and not GPSPW, go back to reports

      IF ((platform%info%levels < 1) .AND.            &
          (index(platform%info%platform, 'GPSPW') <= 0)) then
           cycle reports
      ENDIF
      read(platform%info%platform(4:6), '(I3)') fm
!     READ EACH LEVELS
!     ----------------

loop_level: DO i = 1, platform%info%levels

      platform%each (i) = each_level_type(missing_r, missing, -1.0, & ! height
                       field_type(missing_r, missing, missing_r), & ! u
                       field_type(missing_r, missing, missing_r), & ! v
                       field_type(missing_r, missing, missing_r), & ! p
                       field_type(missing_r, missing, missing_r), & ! t
                       field_type(missing_r, missing, missing_r), & ! q
                       field_type(missing_r, missing, missing_r), & ! rh
                       field_type(missing_r, missing, missing_r), & ! td
                       field_type(missing_r, missing, missing_r))  ! speed 

       READ (UNIT = iunit, FMT = TRIM (fmt_each)) &
              platform%each (i)%p,            &
              platform%each (i)%speed,        &
              platform%each (i)%v,            &
              platform%each (i)%height,       &
              platform%each (i)%height_qc,    &
              height_error,                   &
              platform%each (i)%t,            &
              platform%each (i)%td,           &
              platform%each (i)%rh


      ENDDO loop_level

      if( platform%info%levels < 1) then
         if ( fm /= 111 ) then
            cycle reports
         endif
      endif
      SELECT CASE(fm)

!        if(index(platform%info%source, 'SYNOP') > 0) then

         CASE (12) ;

            if(.not.use_SynopObs) cycle reports
            num_synop = num_synop + 1

!        else if(index(platform%info%source, 'SHIP') > 0 .or. &
!                index(platform%info%source, 'BOUY') > 0) then

         CASE (13, 17) ;                  ! ships          

            if(.not.use_ShipsObs) cycle reports
            num_ships  = num_ships  + 1

!        else if(index(platform%info%source, 'METAR') > 0) then

         CASE (15:16) ;

            if(.not.use_MetarObs) cycle reports
            num_metar = num_metar + 1

!        else if(index(platform%info%source, 'PILOT') > 0) then

         CASE (32:34) ;

            if(.not.use_PilotObs) cycle reports
            num_pilot = num_pilot + 1

!        else if(index(platform%info%source, 'FM-35 TEMP') > 0) then

         CASE (35:38) ;
            if(.not.use_SoundObs) cycle reports
            num_sound = num_sound + 1

!        else if(index(platform%info%source, 'SATEM') > 0) then

         CASE (86) ;

            if(.not.use_SatemObs) cycle reports

!-----------Reject cloudy Satem obs.
 
            if(platform%loc%pw%inv > 10.) then
               cycle reports
            endif

            num_satem = num_satem + 1


!--------Geostationary or Polar orbitting Satellite AMVs:

         CASE (88)    ;

      if(index(platform%info%name, 'MODIS') > 0 .or. &
         index(platform%info%name, 'modis') > 0 )  then
         if(.not.use_PolarAMVObs) cycle reports
         num_polaramv = num_polaramv + 1
      else
         if(.not.use_GeoAMVObs) cycle reports 
         num_geoamv = num_geoamv + 1
      end if

!        else if(index(platform%info%source, 'AIREP') > 0) then

         CASE (42,96:97) ;

            if(.not.use_AirepObs) cycle reports
            num_airep = num_airep + 1

!        else if(index(platform%info%source, 'GPSPW') > 0) then

         CASE (111) ;
         
            if(.not.use_GpspwObs) cycle reports
            num_gpspw = num_gpspw + 1

!        else if(index(platform%info%source, 'GPSRF') > 0) then

         CASE (116) ;
         
            if(.not.use_GpsrefObs) cycle reports
            num_gpsref = num_gpsref + 1

!        SSM/T1 temperatures:
         CASE (121) ;

            if(.not.use_ssmt1obs) cycle reports
            num_ssmt1 = num_ssmt1 + 1

!        SSM/T2 relative humidities:
         CASE (122) ;

            if(.not.use_ssmt2obs) cycle reports
            num_ssmt2 = num_ssmt2 + 1

!        Scatterometer:

         CASE (281)    ;

            if(.not.use_qscatobs) cycle reports
            num_qscat  = num_qscat  + 1

         CASE (132) ;

            if(.not.use_ProfilerObs) cycle reports
            num_profiler = num_profiler + 1

         CASE (135) ;

            if(.not.use_BogusObs) cycle reports
            num_bogus = num_bogus + 1

         CASE (18,19) ;             ! bouy

            if(.not.use_BuoyObs) cycle reports
            num_buoy  = num_buoy  + 1

         CASE (133) ;      !  AIRS retrievals
            if(.not.use_AIRSRETObs) cycle reports
            num_airsr = num_airsr + 1

         CASE DEFAULT;
             num_others = num_others + 1
            write(unit=*, fmt='(/a/)') &
                 'WARNING   WARNING   WARNING   WARNING   WARNING :'

            write(unit=*, fmt='(a)') 'unsaved obs found:'

            write(unit=*, fmt='(2a)') &
                 'platform%info%platform=', platform%info%platform
 
            write(unit=*, fmt='(a, i3)') &
                 'platform%info%levels=', platform%info%levels

      END SELECT
   ENDDO reports                  !  Loop over reports              
   close ( iunit )
   ENDDO file_number              !  Loop over all data files
   call da_free_unit (iunit)
!-------------------------------------------------------------------------------
!  Write Counts in the Header 
!-------------------------------------------------------------------------------
      total_obs = num_synop + num_metar + num_ships + &
             num_buoy + num_sound + num_airep + num_pilot + &
             num_geoamv + num_polaramv + num_gpspw + num_gpsref + &
             num_profiler + num_qscat + num_ssmt1 + num_ssmt2 +  &
             num_satem  + num_bogus +  num_airsr + num_others
!
      WRITE  (UNIT = filtered_obs_unit, FMT = '(A,I7,A,F8.0,A)')    &
      "TOTAL =",total_obs, ", MISS. =",missing_r,","  

! Write other counts       
! -------------------
      WRITE  (UNIT = filtered_obs_unit, FMT = '(6(A,I7,A))' )    &
      "SYNOP =",num_synop,", ", &
      "METAR =",num_metar,", ", &
      "SHIP  =",num_ships,", ", &
      "BUOY  =",num_buoy,", ", &
      "TEMP  =",num_sound,", ", &
      "AIREP =",num_airep,", ", &
      "PILOT =",num_pilot,", ", &
      "GeoAMV =",num_geoamv,", ", &
      "PolarAMV =",num_polaramv,", ", &
      "GPSPW =",num_gpspw,", ", &
      "GPSPRF =",num_gpsref,", ", &
      "PROFL =",num_profiler,", ", &
      "QSCAT =",num_qscat,", ", &
      "SSMT1 =",num_ssmt1,", ", &
      "SSMT2 =",num_ssmt2,", ", &
      "SATEM =",num_satem, ", ", &
      "BOGUS =",num_bogus,", ", &
      "AIRSRET =",num_airsr,", ", &
      "OTHER =",num_others,", "

! Write Reference state Info
! ---------------------------

        WRITE (UNIT = filtered_obs_unit, FMT = '(A,F7.2,A,F7.2,4(A,F7.2),A)') &
        "PHIC  =", phic,", XLONC =", xlonc,", TRUE1 =", truelat1,&
      ", TRUE2 =",truelat2                                                      
        WRITE (UNIT = filtered_obs_unit, FMT = '(2(A,F7.2),A,F7.0,A,F7.0,A)') &
        "TS0   =",  ts0, ", TLP   =", tlp, &
      ", PTOP  =",  ptop,", PS0   =",  ps0,"," 

! Write Domain Info 
! ------------------
!  Hard wire Following variabless
      maxnes = 1 ; numc = 1 ;  idd = 1
      nesti = 1 ; nestj = 1
        WRITE (UNIT = filtered_obs_unit, FMT = '(5(A,I7),A)' ) &
        "IXC   =", ide   ,", JXC   =", jde   ,", IPROJ =", map,&
        ", IDD   =", idd,", MAXNES=",maxnes,","
        WRITE (UNIT = filtered_obs_unit, FMT = '(A,10(:,I7,A))')  &
!       "NESTIX=",(nestix (i),", ", i = 1, maxnes)
       "NESTIX=",(ide    ,", ", i = 1, maxnes)
        WRITE (UNIT = filtered_obs_unit, FMT = '(A,10(:,I7,A))')  &
       "NESTJX=",(jde       ,", ", i = 1, maxnes)
        WRITE (UNIT = filtered_obs_unit, FMT = '(A,10(:,I7,A))')  &
       "NUMC  =",(numc ,", ", i = 1, maxnes)
        WRITE (UNIT = filtered_obs_unit, FMT = '(A,10(:,F7.2,A))')&
       "DIS   =",(ds/1000.,", ",i = 1, maxnes)
        WRITE (UNIT = filtered_obs_unit, FMT = '(A,10(:,I7,A))')  &
       "NESTI =",(nesti     ,", ", i = 1, maxnes)
        WRITE (UNIT = filtered_obs_unit, FMT = '(A,10(:,I7,A))')  &
       "NESTJ =",(nestj     ,", ", i = 1, maxnes)

! Write Variable names and Unit
! -------------------------------

       WRITE (UNIT = filtered_obs_unit, FMT = '(A)' ) &
      "INFO  = PLATFORM, DATE, NAME, LEVELS, LATITUDE, LONGITUDE, ELEVATION, ID."
       WRITE (UNIT = filtered_obs_unit, FMT = '(A)' ) &
      "SRFC  = SLP, PW (DATA,QC,ERROR)."
       WRITE (UNIT = filtered_obs_unit, FMT = '(A)' ) &
      "EACH  = PRES, SPEED, DIR, HEIGHT, TEMP, DEW PT, HUMID (DATA,QC,ERROR)*LEVELS."

! Write Format Info
! ------------------

      WRITE (UNIT = filtered_obs_unit, FMT = '(2A)' ) 'INFO_FMT = ', TRIM (fmt_info)
      WRITE (UNIT = filtered_obs_unit, FMT = '(2A)' ) 'SRFC_FMT = ', TRIM (fmt_srfc)
      WRITE (UNIT = filtered_obs_unit, FMT = '(2A)' ) 'EACH_FMT = ', TRIM (fmt_each)

! Write End of header record
! ---------------------------

      WRITE (UNIT = filtered_obs_unit, FMT = '(A)') &
"#------------------------------------------------------------------------------#"

   if (trace_use) CALL da_trace_exit("da_count_filtered_obs")
end subroutine da_count_filtered_obs 