SUBROUTINE NSSL_ref2tten(mype,istat_radar,nlon,nlat,nsig,ref_mos_3d,cld_cover_3d,& 
                         p_bk,t_bk,sat_ctp)
!
!$$$  subprogram documentation block
!                .      .    .                                       .
! subprogram:  NSSL_ref2tten      convert radar observation to temperature tedency
!
!   PRGMMR: Ming Hu          ORG: GSD/AMB        DATE: 2008-11-27
!
! ABSTRACT: 
!  This subroutine coverts radar observation (dBZ) to temperature tedency for DFI 
!
! PROGRAM HISTORY LOG:
!    2009-01-02  Hu  Add NCO document block
!
!
!   input argument list:
!     mype         - processor ID
!     istat_radar  - radar data status: 0=no radar data; 1=use radar reflectivity
!     nlon         - no. of lons on subdomain (buffer points on ends)
!     nlat         - no. of lats on subdomain (buffer points on ends)
!     nsig         - no. of levels
!     ref_mos_3d   - 3D radar reflectivity  (dBZ)
!     cld_cover_3d - 3D cloud cover     (0-1)
!     p_bk         - 3D background pressure  (hPa)
!     t_bk         - 3D background temperature (K)
!     sat_ctp      - 2D NESDIS cloud top pressure (hPa)
!
!   output argument list:
!
! USAGE:
!   INPUT FILES: 
!
!   OUTPUT FILES:
!
! REMARKS:
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90 
!   MACHINE:  Linux cluster (WJET)
!
!$$$
!
!_____________________________________________________________________
!
  use kinds, only: r_kind,i_kind,r_single
  use guess_grids, only: ges_tten
  implicit none

  INTEGER,INTENT(IN)  ::  mype
  INTEGER,INTENT(IN) ::  nlon,nlat,nsig
  INTEGER(i_kind),INTENT(IN) :: istat_radar

!  real :: zh(nlon,nlat)                         ! terrain
  real(r_kind),INTENT(IN) :: ref_mos_3d(nlon,nlat,nsig)            ! reflectivity in grid
  real(r_single),INTENT(IN) :: cld_cover_3d(nlon,nlat,nsig)
  real(r_single),INTENT(IN) :: p_bk(nlon,nlat,nsig)
  real(r_single),INTENT(IN) :: t_bk(nlon,nlat,nsig)
  real(r_single),INTENT(IN),OPTIONAL  :: sat_ctp(nlon,nlat)

  real, allocatable :: tten_radar(:,:,:)         ! 
  real, allocatable :: dummy(:,:)         ! 

  integer krad_bot                    ! RUC bottom level for TTEN_RAD
                                          !  and for filling from above
  parameter (krad_bot = 6)
!
!  convection suppression
!
  real, allocatable :: radyn(:,:) 
  real ::   radmax, dpint
  integer :: nrad
  real ::   radmaxall, dpintmax

! adopted from: METCON of RUC  (/ihome/rucdev/code/13km/hybfront_code)
! CONTAINS ATMOSPHERIC/METEOROLOGICAL/PHYSICAL CONSTANTS
!**  R_P               R  J/(MOL*K)    UNIVERSAL GAS CONSTANT
!**                                      R* = 8.31451
!**  MD_P              R  KG/MOL       MEAN MOLECULAR WEIGHT OF DRY AIR
!**                                      MD = 0.0289645
!jmb--Old value                          MD = 0.0289644
!**  RD_P              R  J/(KG*K)     SPECIFIC GAS CONSTANT FOR DRY AIR
!**                                      RD = R*>/<MD = 287.0586
!**  CPD_P             R  J/(KG*K)     SPECIFIC HEAT OF DRY AIR AT
!**                                      CONSTANT PRESSURE = 3.5*RD
!**                                      1004.6855
!**  LV_P              R  J/KG         LATENT HEAT OF VAPORIZATION
!**                                      AT 0 DEGREES C
!jmb                                     LV = 2.501E6 (SEVERAL SOURCES)
!jmb
!jmb LF0_P                J/KG         LATENT HEAT OF FUSION
!jmb                                     AT 0 DEGREES C
!jmb                                     LF0= .3335E6 [WEXLER (1977)]
!jmb
!**  CPOVR_P           R  ND           CPD/RD = 3.5

  REAL(r_kind)::     R_P
  PARAMETER ( R_P     =  8.31451     )

  REAL(r_kind)::        MD_P
  REAL(r_kind)::        RD_P
  REAL(r_kind)::        CPD_P
  REAL(r_kind)::        CPOVR_P
  REAL(r_kind)::        LV_P
  REAL(r_kind)::        LF0_P
  PARAMETER ( MD_P     =  0.0289645          )
  PARAMETER ( RD_P     =  R_P/MD_P           )
  PARAMETER ( CPD_P    =  3.5* RD_P          )
  PARAMETER ( CPOVR_P  =  CPD_P/RD_P         )
  PARAMETER ( LV_P      = 2.501E6           )
  PARAMETER ( LF0_P     = .3335E6           )
!
  INTEGER(i_kind):: i,j, k, iskip
  REAL(r_kind):: tten, addsnow
  REAL(r_kind):: spval_p

!
  spval_p =99999.0_r_kind
  if(istat_radar .ne. 1 ) then
   ges_tten=-spval_p
   ges_tten(:,:,nsig,1)=-10.0_r_kind
   return
  endif

  allocate(tten_radar(nlon,nlat,nsig))   
  allocate(dummy(nlon,2))   
  tten_radar=0
!
!-------Calculate tten_radar for LH nudging------
!   NOTE: tten_radar should be temperature tendency for each 
!         integration step instead of each second
!    So (60*cpd_p), where 60 is 60 steps for 40 min foreward integration with 40 second time step.
!
  DO k=2,nsig-1
  DO j=2,nlat-1
  DO i=2,nlon-1
    if (ref_mos_3d(i,j,k).lt.5.0.and.ref_mos_3d(i,j,k).gt.-100) then     ! no echo
         tten_radar(i,j,k) = 0.
    else if (ref_mos_3d(i,j,k).ge.5.0) then  ! echo
      iskip=0
      if (PRESENT(sat_ctp) ) then
      if (sat_ctp(i,j).gt.1010. .and. sat_ctp(i,j).lt.1100.) then
        iskip=iskip+1
!           write (6,*)' Radar ref > 5 dbZ, GOES indicates clear'
!           write (6,*)' i,j,k / refl / lat-lon',i,j,k,ref_mos_3d(i,j,k)
!        Therefore, if GOES indicates clear, tten_radar
!            will retain the zero value
      endif
      endif
      if (t_bk(i,j,k).gt.277.15 .and. ref_mos_3d(i,j,k).lt.28.) then
        iskip=iskip+1
!           write (6,*)' t is over 277 ',i,j,k,ref_mos_3d(i,j,k)
!        ALSO, if T > 4C and refl < 28dBZ, again
!            tten_radar = 0.
      endif
      if(iskip == 0 ) then
!        tten_radar set as non-zero ONLY IF
!          - not contradicted by GOES clear, and
!          - ruc_refl > 28 dbZ for temp > 4K, and
!          - for temp < 4K, any ruc_refl dbZ is OK.
!          - cloudy and under GEOS cloud top
          if (k.ge.krad_bot) then
             if (abs(cld_cover_3d(i,j,k)).le.0.5 .and. (sat_ctp(i,j).gt.p_bk(i,j,k))) then
                 addsnow=0.0
             else
                 addsnow = 10**(ref_mos_3d(i,j,k)/17.8)/264083.*1.5
             endif
             tten = ((1000.0/p_bk(i,j,k))**(1./cpovr_p))    &
                   *(((LV_P+LF0_P)*addsnow)/(60.0*CPD_P))
             tten_radar(i,j,k)= min(0.4,max(-0.01,tten))
          end if
      end if
    end if  ! ref_mos_3d

  ENDDO
  ENDDO
  ENDDO

  DO k=1,nsig
    call smooth(tten_radar(1,1,k),dummy,nlon,nlat,0.5)
    call smooth(tten_radar(1,1,k),dummy,nlon,nlat,0.5)
  ENDDO

!  KEY element -- Set tten_radar to no-coverage AFTER smoothing
!      where ref_mos_3d had been previously set to no-coverage (-99.0 dbZ)

  DO k=1,nsig
  DO j=1,nlat
  DO i=1,nlon
     ges_tten(j,i,k,1)=tten_radar(i,j,k)
     if(ref_mos_3d(i,j,k) .le. -200.0 ) ges_tten(j,i,k,1)=-spval_p   ! no obs
  ENDDO
  ENDDO
  ENDDO

! -- Whack (smooth) the tten_radar array some more.
!     for convection suppression in the radyn array.
  DO k=1,nsig
      call smooth(tten_radar(1,1,k),dummy,nlon,nlat,0.5)
      call smooth(tten_radar(1,1,k),dummy,nlon,nlat,0.5)
      call smooth(tten_radar(1,1,k),dummy,nlon,nlat,0.5)
  ENDDO

  deallocate(dummy)   

!  RADYN array = convection suppression array
!  Definition of RADYN values
!     -10 -> no information 
!       0 -> no convection
!       1 -> there might be convection nearby
!  NOTE:  0,1 values are only possible if
!     deep radar coverage is available (i.e., > 300 hPa deep)

!  RADYN is read into RUC model as array PCPPREV,
!   where it is used to set the cap_depth (cap_max)
!   in the Grell-Devenyi convective scheme
!   to a near-zero value, effectively suppressing convection
!   during DFI and first 30 min of the forward integration.

  allocate(radyn(nlon,nlat))
  radyn = -10.

  radmaxall=-999
  dpintmax=-999
  DO j=1,nlat
  DO i=1,nlon

     nrad = 0
     radmax = 0.
     dpint = 0.
     DO k=2,nsig-1
       if ((ref_mos_3d(i,j,k)) .le. -200.0) tten_radar(i,j,k) = -spval_p
       if (tten_radar(i,j,k).gt.-20.) then
         nrad=nrad+1
         dpint = dpint + 0.5*(p_bk(i,j,k-1)-p_bk(i,j,k+1))
         radmax = max(radmax,tten_radar(i,j,k))
       end if
     ENDDO
     if (dpint.ge.300. ) then 
       radyn(i,j) = 0.
       if (radmax.gt.0.00002) radyn(i,j) = 1.
     endif
     if(dpintmax < dpint ) dpintmax=dpint
     if(radmaxall< radmax) radmaxall=radmax
  ENDDO
  ENDDO

  DO j=1,nlat
  DO i=1,nlon
     ges_tten(j,i,nsig,1)=radyn(i,j)
  ENDDO
  ENDDO

  deallocate(tten_radar)   
  deallocate(radyn)   

END SUBROUTINE NSSL_ref2tten
SUBROUTINE NSSL_ref2tten_nosat(mype,istat_radar,nlon,nlat,nsig,ref_mos_3d,cld_cover_3d,& 
                         p_bk,t_bk)
!
!$$$  subprogram documentation block
!                .      .    .                                       .
! subprogram:  NSSL_ref2tten      convert radar observation to temperature tedency
!
!   PRGMMR: Ming Hu          ORG: GSD/AMB        DATE: 2008-11-27
!
! ABSTRACT: 
!  This subroutine coverts radar observation (dBZ) to temperature tedency for DFI 
!
! PROGRAM HISTORY LOG:
!    2009-01-02  Hu  Add NCO document block
!
!
!   input argument list:
!     mype         - processor ID
!     istat_radar  - radar data status: 0=no radar data; 1=use radar reflectivity
!     nlon         - no. of lons on subdomain (buffer points on ends)
!     nlat         - no. of lats on subdomain (buffer points on ends)
!     nsig         - no. of levels
!     ref_mos_3d   - 3D radar reflectivity  (dBZ)
!     cld_cover_3d - 3D cloud cover     (0-1)
!     p_bk         - 3D background pressure  (hPa)
!     t_bk         - 3D background temperature (K)
!
!   output argument list:
!
! USAGE:
!   INPUT FILES: 
!
!   OUTPUT FILES:
!
! REMARKS:
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90 
!   MACHINE:  Linux cluster (WJET)
!
!$$$
!
!_____________________________________________________________________
!
  use kinds, only: r_kind,i_kind,r_single
  use guess_grids, only: ges_tten
  implicit none

  INTEGER,INTENT(IN)  ::  mype
  INTEGER,INTENT(IN) ::  nlon,nlat,nsig
  INTEGER(i_kind),INTENT(IN) :: istat_radar

!  real :: zh(nlon,nlat)                         ! terrain
  real(r_kind),INTENT(IN) :: ref_mos_3d(nlon,nlat,nsig)            ! reflectivity in grid
  real(r_single),INTENT(IN) :: cld_cover_3d(nlon,nlat,nsig)
  real(r_single),INTENT(IN) :: p_bk(nlon,nlat,nsig)
  real(r_single),INTENT(IN) :: t_bk(nlon,nlat,nsig)

  real, allocatable :: tten_radar(:,:,:)         ! 
  real, allocatable :: dummy(:,:)         ! 

  integer krad_bot                    ! RUC bottom level for TTEN_RAD
                                          !  and for filling from above
  parameter (krad_bot = 6)
!
!  convection suppression
!
  real, allocatable :: radyn(:,:) 
  real ::   radmax, dpint
  integer :: nrad
  real ::   radmaxall, dpintmax

! adopted from: METCON of RUC  (/ihome/rucdev/code/13km/hybfront_code)
! CONTAINS ATMOSPHERIC/METEOROLOGICAL/PHYSICAL CONSTANTS
!**  R_P               R  J/(MOL*K)    UNIVERSAL GAS CONSTANT
!**                                      R* = 8.31451
!**  MD_P              R  KG/MOL       MEAN MOLECULAR WEIGHT OF DRY AIR
!**                                      MD = 0.0289645
!jmb--Old value                          MD = 0.0289644
!**  RD_P              R  J/(KG*K)     SPECIFIC GAS CONSTANT FOR DRY AIR
!**                                      RD = R*>/<MD = 287.0586
!**  CPD_P             R  J/(KG*K)     SPECIFIC HEAT OF DRY AIR AT
!**                                      CONSTANT PRESSURE = 3.5*RD
!**                                      1004.6855
!**  LV_P              R  J/KG         LATENT HEAT OF VAPORIZATION
!**                                      AT 0 DEGREES C
!jmb                                     LV = 2.501E6 (SEVERAL SOURCES)
!jmb
!jmb LF0_P                J/KG         LATENT HEAT OF FUSION
!jmb                                     AT 0 DEGREES C
!jmb                                     LF0= .3335E6 [WEXLER (1977)]
!jmb
!**  CPOVR_P           R  ND           CPD/RD = 3.5

  REAL(r_kind)::     R_P
  PARAMETER ( R_P     =  8.31451     )

  REAL(r_kind)::        MD_P
  REAL(r_kind)::        RD_P
  REAL(r_kind)::        CPD_P
  REAL(r_kind)::        CPOVR_P
  REAL(r_kind)::        LV_P
  REAL(r_kind)::        LF0_P
  PARAMETER ( MD_P     =  0.0289645          )
  PARAMETER ( RD_P     =  R_P/MD_P           )
  PARAMETER ( CPD_P    =  3.5* RD_P          )
  PARAMETER ( CPOVR_P  =  CPD_P/RD_P         )
  PARAMETER ( LV_P      = 2.501E6           )
  PARAMETER ( LF0_P     = .3335E6           )
!
  INTEGER(i_kind):: i,j, k, iskip
  REAL(r_kind):: tten, addsnow
  REAL(r_kind):: spval_p

!
  spval_p =99999.0_r_kind
  if(istat_radar .ne. 1 ) then
   ges_tten=-spval_p
   ges_tten(:,:,nsig,1)=-10.0_r_kind
   return
  endif

  allocate(tten_radar(nlon,nlat,nsig))   
  allocate(dummy(nlon,2))   
  tten_radar=0
!
!-------Calculate tten_radar for LH nudging------
!   NOTE: tten_radar should be temperature tendency for each 
!         integration step instead of each second
!    So (60*cpd_p), where 60 is 60 steps for 40 min foreward integration with 40 second time step.
!
  DO k=2,nsig-1
  DO j=2,nlat-1
  DO i=2,nlon-1
    if (ref_mos_3d(i,j,k).lt.5.0.and.ref_mos_3d(i,j,k).gt.-100) then     ! no echo
         tten_radar(i,j,k) = 0.
    else if (ref_mos_3d(i,j,k).ge.5.0) then  ! echo
      iskip=0
      if (t_bk(i,j,k).gt.277.15 .and. ref_mos_3d(i,j,k).lt.28.) then
        iskip=iskip+1
!           write (6,*)' t is over 277 ',i,j,k,ref_mos_3d(i,j,k)
!        ALSO, if T > 4C and refl < 28dBZ, again
!            tten_radar = 0.
      endif
      if(iskip == 0 ) then
!        tten_radar set as non-zero ONLY IF
!          - not contradicted by GOES clear, and
!          - ruc_refl > 28 dbZ for temp > 4K, and
!          - for temp < 4K, any ruc_refl dbZ is OK.
!          - cloudy and under GEOS cloud top
          if (k.ge.krad_bot) then
             if (abs(cld_cover_3d(i,j,k)).le.0.5) then
                 addsnow=0.0
             else
                 addsnow = 10**(ref_mos_3d(i,j,k)/17.8)/264083.*1.5
             endif
             tten = ((1000.0/p_bk(i,j,k))**(1./cpovr_p))    &
                   *(((LV_P+LF0_P)*addsnow)/(60.0*CPD_P))
             tten_radar(i,j,k)= min(0.4,max(-0.01,tten))
          end if
      end if
    end if  ! ref_mos_3d

  ENDDO
  ENDDO
  ENDDO

  DO k=1,nsig
    call smooth(tten_radar(1,1,k),dummy,nlon,nlat,0.5)
    call smooth(tten_radar(1,1,k),dummy,nlon,nlat,0.5)
  ENDDO

!  KEY element -- Set tten_radar to no-coverage AFTER smoothing
!      where ref_mos_3d had been previously set to no-coverage (-99.0 dbZ)

  DO k=1,nsig
  DO j=1,nlat
  DO i=1,nlon
     ges_tten(j,i,k,1)=tten_radar(i,j,k)
     if(ref_mos_3d(i,j,k) .le. -200.0 ) ges_tten(j,i,k,1)=-spval_p   ! no obs
  ENDDO
  ENDDO
  ENDDO

! -- Whack (smooth) the tten_radar array some more.
!     for convection suppression in the radyn array.
  DO k=1,nsig
      call smooth(tten_radar(1,1,k),dummy,nlon,nlat,0.5)
      call smooth(tten_radar(1,1,k),dummy,nlon,nlat,0.5)
      call smooth(tten_radar(1,1,k),dummy,nlon,nlat,0.5)
  ENDDO

  deallocate(dummy)   

!  RADYN array = convection suppression array
!  Definition of RADYN values
!     -10 -> no information 
!       0 -> no convection
!       1 -> there might be convection nearby
!  NOTE:  0,1 values are only possible if
!     deep radar coverage is available (i.e., > 300 hPa deep)

!  RADYN is read into RUC model as array PCPPREV,
!   where it is used to set the cap_depth (cap_max)
!   in the Grell-Devenyi convective scheme
!   to a near-zero value, effectively suppressing convection
!   during DFI and first 30 min of the forward integration.

  allocate(radyn(nlon,nlat))
  radyn = -10.

  radmaxall=-999
  dpintmax=-999
  DO j=1,nlat
  DO i=1,nlon

     nrad = 0
     radmax = 0.
     dpint = 0.
     DO k=2,nsig-1
       if ((ref_mos_3d(i,j,k)) .le. -200.0) tten_radar(i,j,k) = -spval_p
       if (tten_radar(i,j,k).gt.-20.) then
         nrad=nrad+1
         dpint = dpint + 0.5*(p_bk(i,j,k-1)-p_bk(i,j,k+1))
         radmax = max(radmax,tten_radar(i,j,k))
       end if
     ENDDO
     if (dpint.ge.300. ) then 
       radyn(i,j) = 0.
       if (radmax.gt.0.00002) radyn(i,j) = 1.
     endif
     if(dpintmax < dpint ) dpintmax=dpint
     if(radmaxall< radmax) radmaxall=radmax
  ENDDO
  ENDDO

  DO j=1,nlat
  DO i=1,nlon
     ges_tten(j,i,nsig,1)=radyn(i,j)
  ENDDO
  ENDDO

  deallocate(tten_radar)   
  deallocate(radyn)   

END SUBROUTINE NSSL_ref2tten_nosat
