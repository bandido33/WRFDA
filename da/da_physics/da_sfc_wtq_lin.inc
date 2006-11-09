subroutine da_sfc_wtq_lin(psfc, tg, ps, ts, qs, us, vs, regime,           &
                       psfc_prime,tg_prime,ps_prime,ts_prime,qs_prime, &
                       us_prime,vs_prime, hs,roughness,xland,          &
                       u10_prime,v10_prime,t2_prime,q2_prime) 

   !---------------------------------------------------------------------------
   ! Calculate the  10m wind, 2m temperature and moisture based on the
   ! similarity theory/
   !
   ! Reference:
   ! ---------
   !
   !  Input Variables(basic state):
   ! 
   !   psfc, tg               : surface pressure and ground temperature
   !   ps, ts, qs, us, vs, hs : model variable at lowlest half sigma level
   !   regime                 : PBL regime
   !
   !  Input Variables(pertubation):
   ! 
   !   psfc_prime, tg_prime   : Surface pressure and ground temperature
   !   ps_prime, ts_prime,    : Model variables at the lowest half sigma
   !   qs_prime, us_prime,    : level 
   !   vs_prime               : 
   !
   !  Constants:
   !
   !   hs                     : height at the lowest half sigma level
   !   roughness              : roughness
   !   xland                  : land-water-mask (=2 water, =1 land)
   !
   !  Output Variables(pertubation):
   !
   !   u10_prime, v10_prime   : 10-m high observed wind components
   !   t2_prime , q2_prime    : 2-m high observed temperature and mixing ratio
   !
   !---------------------------------------------------------------------------
   !  
   !                      psim  : mechanical psi at lowlest sigma level
   !                      psim2 : mechanical psi at 2m 
   !                      psimz : mechanical psi at 10m 
   !
   !---------------------------------------------------------------------------

   IMPLICIT NONE

   REAL   , INTENT (in)          :: regime
   REAL   , INTENT (in)          :: ps , ts , qs , us, vs, psfc, tg
   REAL   , INTENT (in)          :: ps_prime, ts_prime, qs_prime  , &
                                    us_prime, vs_prime, psfc_prime, tg_prime
   REAL   , INTENT (in)          :: hs, roughness, xland

   REAL   , INTENT (out)         :: u10_prime, v10_prime, t2_prime, q2_prime

   ! Maximum number of iterations in computing psim, psih

   INTEGER, PARAMETER :: k_iteration = 10 
   !      INTEGER, PARAMETER :: k_iteration = 1

   ! h10 is the height of 10m where the wind observed
   ! h2  is the height of 2m where the temperature and 
   !        moisture observed.

   REAL, PARAMETER :: h10 = 10., h2 = 2.
   !
   ! Default roughness over the land

   REAL, PARAMETER :: zint0 = 0.01 
   !
   ! Von Karman constant

   REAL, PARAMETER :: k_kar = 0.4
   !
   ! Working variables

   REAL :: Vc2, Va2, V2 
   REAL :: rib, rcp, xx, yy, cc, Pi
   REAL :: psiw, psiz, mol, ust, hol, holz, hol2
   REAL :: psim, psimz, psim2, psih, psihz, psih2
   REAL :: psit, psit2, psiq, psiq2
   REAL :: gzsoz0, gz10oz0, gz2oz0
   REAL :: eg, qg, tvg, tvs
   REAL :: ths, thg, thvs, thvg
   REAL :: zq0, z0

   REAL :: Vc2_prime, Va2_prime, V2_prime
   REAL :: rib_prime, xx_prime, yy_prime
   REAL :: psiw_prime, psiz_prime, mol_prime, ust_prime, &
           hol_prime, holz_prime, hol2_prime
   REAL :: psim_prime, psimz_prime, psim2_prime, &
           psih_prime, psihz_prime, psih2_prime
   REAL :: psit_prime, psit2_prime, &
           psiq_prime, psiq2_prime
   REAL :: qg_prime, tvg_prime, tvs_prime
   REAL :: ths_prime, thg_prime, thvs_prime, thvg_prime

   REAL, PARAMETER :: ka = 2.4E-5

   INTEGER :: iregime

   rcp = gas_constant/cp

   ! 1 Compute the roughness length based upon season and land use 
   ! =====================================

   ! 1.1 Define the rouhness length
   !     -----------------

   z0 = roughness

   if (z0 < 0.0001) z0 = 0.0001

   ! 1.2 Define the rouhgness length for moisture
   !     -----------------

   if (xland .ge. 1.5) then
      zq0 = z0
    else
      zq0 =  zint0
   endif

   ! 1.3 Define the some constant variable for psi
   !     -----------------

   gzsoz0 = log(hs/z0)

   gz10oz0 = log(h10/z0)

   gz2oz0 = log(h2/z0)


   ! 2. Calculate the virtual temperature
   ! =====================================

   ! 2.1 Compute Virtual temperature on the lowest half sigma level
   !     ---------------------------------------------------------

   tvs_prime  = ts_prime * (1. + 0.608 * qs) + 0.608 * ts * qs_prime
   tvs  = ts * (1. + 0.608 * qs)

   ! 2.2 Compute the ground saturated mixing ratio and the ground virtual 
   !     temperature
   !     ----------------------------------------------------------------

   call da_tp_to_qs( tg, psfc, eg, qg )
   call da_tp_to_qs_lin1( tg, psfc, eg, tg_prime, psfc_prime, qg_prime )

   qg_prime = qg_prime * qg

   tvg_prime  = tg_prime * (1. + 0.608 * qg) + 0.608 * tg * qg_prime
   tvg  = tg * (1. + 0.608 * qg)

   ! 3.  Compute the potential temperature and virtual potential temperature
   ! =======================================================================

   ! 3.1 Potential temperature on the lowest half sigma level
   !     ----------------------------------------------------

   Pi = (100000. / ps) ** rcp
   ths_prime  = (ts_prime - ps_prime * rcp * ts/ps ) * Pi 
   ths  = ts * Pi

   ! 3.2 Virtual potential temperature on the lowest half sigma level
   !     ------------------------------------------------------------

   thvs_prime  = (tvs_prime - ps_prime * rcp * tvs/ps) * Pi 
   thvs = tvs * Pi

   ! 3.3 Potential temperature at the ground
   !     -----------------------------------

   Pi = (100000. / psfc) ** rcp
   thg_prime  = (tg_prime - psfc_prime * rcp * tg/psfc) * Pi 
   thg  = tg * Pi

   ! 3.4 Virtual potential temperature at ground
   !     ---------------------------------------

   thvg_prime  = (tvg_prime - psfc_prime * rcp * tvg/psfc) * Pi
   thvg = tvg * Pi

   ! 4.  BULK RICHARDSON NUMBER AND MONI-OBUKOV LENGTH
   ! =================================================

   ! 4.1 Velocity
   !     --------
   
   ! Wind speed:

   Va2_prime =  2.*us*us_prime + 2.*vs*vs_prime
   Va2 =   us*us + vs*vs
    
   ! Convective velocity:

   if (thvg >= thvs) then
      Vc2_prime = 4. * (thvg_prime - thvs_prime)
      Vc2 = 4. * (thvg - thvs)
   else
      Vc2_prime = 0.
      Vc2 = 0.
   endif
   
   V2_prime  = Va2_prime+ Vc2_prime
   V2  = Va2 + Vc2

   ! 4.2 Bulk richardson number
   !     ----------------------

   Pi = gravity * hs / (ths*V2)
   rib_prime = ( thvs_prime - thvg_prime   &
              - (thvs-thvg)/V2  * V2_prime &
              - (thvs-thvg)/ths * ths_prime ) * Pi 
   rib = (thvs - thvg) * Pi

   ! 5.  CALCULATE PSI BASED UPON REGIME
   ! =======================================

   iregime = int(regime)

   SELECT CASE ( iregime  ) 

   ! 5.1 Stable conditions (REGIME 1)
   !     ---------------------------

   CASE ( 1 );

      psim_prime  = 0.
      psimz_prime = 0.
      psim2_prime = 0.
      psim  = -10.*gzsoz0
      psimz = -10.*gz10oz0
      psim2 = -10.*gz2oz0
      psim  = max(psim,-10.)
      psimz = max(psimz,-10.)
      psim2 = max(psim2,-10.)

      psih_prime  = psim_prime
      psihz_prime = psimz_prime
      psih2_prime = psim2_prime
      psih  = psim
      psihz = psimz
      psih2 = psim2

   ! 5.2 Mechanically driven turbulence (REGIME 2)
   !     ------------------------------------------

   CASE ( 2 );

      Pi =  - 1.0 / ((1.1 - 5.*rib)*(1.1 - 5.*rib))
      psim_prime  = 5.5 * gzsoz0  * rib_prime * Pi 
      psimz_prime = 5.5 * gz10oz0 * rib_prime * Pi
      psim2_prime = 5.5 * gz2oz0  * rib_prime * Pi

      Pi =  ( -5. * rib ) / (1.1 - 5.*rib)
      psim  = gzsoz0  * Pi
      psimz = gz10oz0 * Pi
      psim2 = gz2oz0  * Pi

      if ( psim >= -10. ) then
         psim = psim
         psim_prime = psim_prime
      else
         psim = -10.
         psim_prime = 0.
      endif
      if ( psimz >= -10. ) then
         psimz = psimz
         psimz_prime = psimz_prime
      else
         psimz = -10.
         psimz_prime = 0.
      endif
      if ( psim2 >= -10. ) then
         psim2 = psim2
         psim2_prime = psim2_prime
      else
         psim2 = -10.
         psim2_prime = 0.
      endif

      psih_prime  = psim_prime
      psihz_prime = psimz_prime
      psih2_prime = psim2_prime
      psih = psim
      psihz = psimz
      psih2 = psim2

   ! 5.3 Unstable Forced convection (REGIME 3)
   !     -------------------------------------

   CASE ( 3 );

      psim_prime = 0.
      psimz_prime = 0.
      psim2_prime = 0.

      psim = 0.
      psimz = 0.
      psim2 = 0.

      psih_prime = psim_prime
      psihz_prime = psimz_prime
      psih2_prime = psim2_prime
      psih = psim
      psihz = psimz
      psih2 = psim2


      ! 5.4 Free convection (REGIME 4)
      !     --------------------------

   CASE ( 4 );

      ! Calculate psi m and pshi h using iteration method

      psim_prime = 0.
      psih_prime = 0.
      psim = 0.
      psih = 0.
      cc = 2. * atan(1.0)

      ! do k = 1 , k_iteration

      ! 5.4.1  Calculate   ust, m/L (mol), h/L (hol)
      !        --------------------------

      ! Friction speed

      ust = k_kar * sqrt(v2) /( gzsoz0 - psim)
      ust_prime = (0.5/V2 * v2_prime + psim_prime /(gzsoz0 - psim)) * ust

      ! Heat fux factor

      mol = k_kar * (ths - thg )/( gzsoz0 - psih)
      mol_prime = ( (ths_prime - thg_prime ) /(ths - thg) + &
                     psih_prime /( gzsoz0 - psih) ) * mol

      ! Ratio of PBL height to Monin-Obukhov length

      if ( ust .LT. 0.01 ) then
         hol_prime = rib_prime * gzsoz0
         hol = rib * gzsoz0
      else
         hol = k_kar * gravity * hs * mol / ( ths * ust * ust )
         hol_prime = ( mol_prime / mol - ths_prime / ths &
                        - 2.* ust_prime / ust ) * hol
      endif

      ! 5.4.2  Calculate n, nz, R, Rz
      !        --------------------------

      if ( hol >= 0. ) then
         hol_prime = 0.
         hol = 0.
      else
         hol_prime = hol_prime
         hol = hol
      endif
      if ( hol >= -10. ) then
         hol_prime = hol_prime
         hol = hol
      else
         hol_prime = 0.
         hol = -10.
      endif

      holz_prime = (h10 / hs) * hol_prime
      holz = (h10 / hs) * hol
      if ( holz >= 0. ) then
         holz_prime = 0.
         holz = 0.
      else
         holz_prime = holz_prime
         holz = holz
      endif
      if ( holz >= -10. ) then
         holz_prime = holz_prime
         holz = holz
      else
         holz_prime = 0.
         holz = -10.
      endif

      hol2_prime = (h2 / hs) * hol_prime
      hol2 = (h2 / hs) * hol
      if ( hol2 >= 0. ) then
         hol2_prime = 0.
         hol2 = 0.
      else
         hol2_prime = hol2_prime
         hol2 = hol2
      endif
      if ( hol2 >= -10. ) then
         hol2_prime = hol2_prime
         hol2 = hol2
      else
         hol2_prime = 0.
         hol2 = -10.
      endif

      ! 5.4.3 Calculate Psim & psih
      !        --------------------------

      ! Using the continuous function:
      xx_prime = -4.* hol_prime /((1. - 16. * hol) ** 0.75)
      xx = (1. - 16. * hol) ** 0.25
      yy_prime = 2.* xx * xx_prime /(1.+xx*xx)
      yy = log((1.+xx*xx)/2.)
      psim_prime = 2 * xx_prime *(1.0/(1.+xx)-1.0/(1+xx*xx)) + yy_prime 
      psim = 2. * log((1.+xx)/2.) + yy - 2. * atan(xx) + cc
      psih_prime = 2. * yy_prime
      psih = 2. * yy

      ! Using the continuous function:
      xx_prime = -4.* holz_prime /((1. - 16. * holz) ** 0.75)
      xx = (1. - 16. * holz) ** 0.25
      yy_prime = 2.* xx * xx_prime /(1.+xx*xx)
      yy = log((1.+xx*xx)/2.)
      psimz_prime = 2.* xx_prime *(1.0/(1.+xx)-1.0/(1+xx*xx)) + yy_prime
      psimz = 2. * log((1.+xx)/2.) + yy - 2. * atan(xx) + cc
      psihz_prime = 2. * yy_prime
      psihz = 2. * yy

      ! Using the continuous function:
      xx_prime = -4.* hol2_prime /((1. - 16. * hol2) ** 0.75)
      xx = (1. - 16. * hol2) ** 0.25
      yy_prime = 2.* xx * xx_prime /(1.+xx*xx)
      yy = log((1.+xx*xx)/2.)
      psim2_prime = 2.* xx_prime *(1.0/(1.+xx)-1.0/(1+xx*xx)) + yy_prime
      psim2 = 2. * log((1.+xx)/2.) + yy - 2. * atan(xx) + cc
      psih2_prime = 2. * yy_prime
      psih2 = 2. * yy

      ! enddo 

      ! 5.4.4 Define the limit value for psim & psih
      !        --------------------------

      if ( psim <= 0.9*gzsoz0 ) then
         psim_prime = psim_prime
         psim = psim
      else
         psim = 0.9*gzsoz0
         psim_prime = 0.
      endif
      if ( psimz <= 0.9*gz10oz0 ) then
         psimz_prime = psimz_prime
         psimz = psimz
      else
         psimz_prime = 0.
         psimz = 0.9*gz10oz0
      endif
      if ( psim2 <= 0.9*gz2oz0 ) then
         psim2_prime = psim2_prime
         psim2 = psim2
      else
         psim2_prime = 0.
         psim2 = 0.9*gz2oz0
      endif
      if ( psih <= 0.9*gzsoz0 ) then
         psih_prime = psih_prime
         psih = psih
      else
         psih_prime = 0.
         psih = 0.9*gzsoz0
      endif
      if ( psihz <= 0.9*gz10oz0 ) then
         psihz_prime = psihz_prime
         psihz = psihz
      else
         psihz_prime = 0.
         psihz = 0.9*gz10oz0
      endif
      if ( psih2 <= 0.9*gz2oz0 ) then
         psih2_prime = psih2_prime
         psih2 = psih2
      else
         psih2_prime = 0.
         psih2 = 0.9*gz2oz0
       endif

    CASE DEFAULT;
       WRITE(UNIT=errmsg(1),FMT='(A,I2,A)') &
          "Regime=",iregime," is invalid."
       call da_error(__FILE__,__LINE__,errmsg(1:1))

   END SELECT

   ! 6.  CALCULATE PSI FOR WIND, TEMPERATURE AND MOISTURE
   ! =======================================

   psiw_prime = - psim_prime
   psiw = gzsoz0 - psim
   psiz_prime = - psimz_prime
   psiz = gz10oz0 - psimz
   psit_prime = - psih_prime
   psit = gzsoz0 - psih
   psit2_prime = - psih2_prime
   psit2 = gz2oz0 - psih2

   ust = k_kar * sqrt(v2) /( gzsoz0 - psim)
   ust_prime = (0.5/V2 * v2_prime + psim_prime /(gzsoz0 - psim)) * ust

   psiq2_prime = k_kar*hs/(ka*(k_kar*ust*hs/ka + hs / zq0 ))*ust_prime
   psiq_prime  = psiq2_prime - psih_prime
   psiq2_prime = psiq2_prime - psih2_prime

   psiq  = log(k_kar*ust*hs/ka + hs / zq0 ) - psih
   psiq2 = log(k_kar*ust*h2/ka + h2 / zq0 ) - psih2

   ! 7.  CALCULATE THE PERTURBATIONS for 10M WIND, 2M TEMPERATURE AND MOISTURE
   ! =======================================

   Pi = psiz / psiw
   u10_prime= (us_prime + us/psiz * psiz_prime - us/psiw * psiw_prime) * Pi
   v10_prime= (vs_prime + vs/psiz * psiz_prime - vs/psiw * psiw_prime) * Pi

   t2_prime = ( (1.0-psit2/psit) * thg_prime + ( ths_prime + &
                           (ths - thg)/psit2 * psit2_prime - &
                           (ths - thg)/psit  * psit_prime ) * psit2/psit &
             + rcp*( thg + ( ths - thg )*psit2/psit)/psfc * psfc_prime ) &
             * (psfc/100000.)**rcp

   q2_prime = (1.0-psiq2/psiq) * qg_prime + psiq2/psiq * qs_prime + &
              (qs -qg)*(psiq2/psiq) * (psiq2_prime/psiq2 - psiq_prime/psiq)

end subroutine da_sfc_wtq_lin

