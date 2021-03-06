!WRF:MODEL_LAYER:CHEMISTRY
!
      SUBROUTINE photolysis_driver (id,ktau,dtstep, config_flags,haveaer,&
               gmt,julday,t_phy,moist,aerwrf,p8w,t8w,p_phy,              &
               chem,rho_phy,dz8w,xlat,xlong,z_at_w,gd_cloud,gd_cloud2,   &
               ph_macr,ph_o31d,ph_o33p,ph_no2,ph_no3o2,ph_no3o,ph_hno2,  &
               ph_hno3,ph_hno4,ph_h2o2,ph_ch2or,ph_ch2om,ph_ch3cho,      &
               ph_ch3coch3,ph_ch3coc2h5,ph_hcocho,ph_ch3cocho,           &
               ph_hcochest,ph_ch3o2h,ph_ch3coo2h,ph_ch3ono2,ph_hcochob,  &
               ph_n2o5,ph_o2,                                            &
               tauaer1,tauaer2,tauaer3,tauaer4,                          &
               gaer1,gaer2,gaer3,gaer4,                                  &
               waer1,waer2,waer3,waer4,                                  &
               pm2_5_dry,pm2_5_water,uvrad,                              &
               ids,ide, jds,jde, kds,kde,                                &
               ims,ime, jms,jme, kms,kme,                                &
               its,ite, jts,jte, kts,kte                                 )

!------------------------------------------------------------------------
   USE module_configure
   USE module_state_description
   USE module_model_constants
   USE module_phot_mad
   USE module_phot_fastj
   INTEGER,      INTENT(IN   ) :: id,julday,                           &
                                  ids,ide, jds,jde, kds,kde,           &
                                  ims,ime, jms,jme, kms,kme,           &
                                  its,ite, jts,jte, kts,kte
   INTEGER,      INTENT(IN   ) ::                                      &
                                  ktau
      REAL,      INTENT(IN   ) ::                                      &
                             dtstep,gmt
!
! advected moisture variables
!
   REAL, DIMENSION( ims:ime, kms:kme, jms:jme, num_moist ),            &
         INTENT(IN ) ::                                   moist
!
!  aerosol interaction
!
   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ),                       & 
         INTENT(INOUT ) ::                                             &
               pm2_5_dry,pm2_5_water, aerwrf
!
! arrays that hold the photolysis rates
!

   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ),                       &  
         INTENT(INOUT ) ::                                             &
           ph_macr,ph_o31d,ph_o33p,ph_no2,ph_no3o2,ph_no3o,ph_hno2,    &  
           ph_hno3,ph_hno4,ph_h2o2,ph_ch2or,ph_ch2om,ph_ch3cho,        &  
           ph_ch3coch3,ph_ch3coc2h5,ph_hcocho,ph_ch3cocho,             &  
           ph_hcochest,ph_ch3o2h,ph_ch3coo2h,ph_ch3ono2,ph_hcochob,    &
           ph_n2o5,ph_o2
   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ),                       &  
         INTENT(INOUT ) ::                                             &
           gd_cloud,gd_cloud2
!
! arrays that hold the aerosol optical properties
!
   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ),                       &  
         INTENT(INOUT ) ::                                             &
           tauaer1,tauaer2,tauaer3,tauaer4,                            &
           gaer1,gaer2,gaer3,gaer4,                                    &
           waer1,waer2,waer3,waer4
!
! array that holds all advected chemical species
!
   REAL, DIMENSION( ims:ime, kms:kme, jms:jme, num_chem ),             &
         INTENT(INOUT ) ::                                   chem
!
! on input from meteorological part of model
!
   REAL,  DIMENSION( ims:ime , kms:kme , jms:jme )         ,           &
          INTENT(IN   ) ::                                             &
                                                      t_phy,           &
                                                      p_phy,           &
                                                      dz8w,            &
                                              t8w,p8w,z_at_w ,         &
                                                    rho_phy
   REAL,  DIMENSION( ims:ime , jms:jme )                   ,           &
          INTENT(INOUT   ) ::  uvrad
   REAL,  DIMENSION( ims:ime , jms:jme )                   ,           &
          INTENT(IN   ) ::                                             &
                                                     xlat,             &
                                                     xlong
   TYPE(grid_config_rec_type),  INTENT(IN   )    :: config_flags

   LOGICAL, INTENT(IN) :: haveaer
!         
!                                                    
! LOCAL  VAR


!-----------------------------------------------------------------

   IF (config_flags%phot_opt .eq. 0) return
!
! select photolysis option
!
   chem_phot_select: SELECT CASE(config_flags%phot_opt)

     CASE (PHOTMAD)
       CALL wrf_debug(15,'calling madronich1_driver')
       call madronich1_driver(id,ktau,dtstep,config_flags,haveaer,     & 
               gmt,julday,t_phy,moist,aerwrf,p8w,t8w,p_phy,            &
               chem,rho_phy,dz8w,xlat,xlong,z_at_w,gd_cloud,gd_cloud2, &
               ph_macr,ph_o31d,ph_o33p,ph_no2,ph_no3o2,ph_no3o,ph_hno2,&
               ph_hno3,ph_hno4,ph_h2o2,ph_ch2or,ph_ch2om,ph_ch3cho,    &
               ph_ch3coch3,ph_ch3coc2h5,ph_hcocho,ph_ch3cocho,         &
               ph_hcochest,ph_ch3o2h,ph_ch3coo2h,ph_ch3ono2,ph_hcochob,&
               pm2_5_dry,pm2_5_water,uvrad,                            &
               ids,ide, jds,jde, kds,kde,                              &
               ims,ime, jms,jme, kms,kme,                              &
               its,ite, jts,jte, kts,kte                               )
     CASE (PHOTFASTJ)
       call wrf_debug(15,'calling fastj_driver')
       call fastj_driver(id,ktau,dtstep,config_flags,                  & 
               gmt,julday,t_phy,moist,p8w,p_phy,                       &
               chem,rho_phy,dz8w,xlat,xlong,z_at_w,                    &
               ph_o2,ph_o31d,ph_o33p,ph_no2,ph_no3o2,ph_no3o,ph_hno2,  &
               ph_hno3,ph_hno4,ph_h2o2,ph_ch2or,ph_ch2om,ph_ch3cho,    &
               ph_ch3coch3,ph_ch3coc2h5,ph_hcocho,ph_ch3cocho,         &
               ph_hcochest,ph_ch3o2h,ph_ch3coo2h,ph_ch3ono2,ph_hcochob,&
               ph_n2o5,                                                &
               tauaer1,tauaer2,tauaer3,tauaer4,                        &
               gaer1,gaer2,gaer3,gaer4,                                &
               waer1,waer2,waer3,waer4,                                &
               ids,ide, jds,jde, kds,kde,                              &
               ims,ime, jms,jme, kms,kme,                              &
               its,ite, jts,jte, kts,kte                               )
     CASE DEFAULT

   END SELECT chem_phot_select

END SUBROUTINE photolysis_driver
