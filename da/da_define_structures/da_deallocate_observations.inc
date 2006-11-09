SUBROUTINE da_deallocate_observations ( ob )

   !---------------------------------------------------------------------------
   ! PURPOSE: Deallocate components of observation structure.
   !---------------------------------------------------------------------------

   IMPLICIT NONE

   TYPE (ob_type), intent(inout)        :: ob     ! Observation structure.
   integer   :: n

   IF (trace_use) CALL da_trace_entry("da_deallocate_observations")

   !---------------------------------------------------------------------------
   ! [1.0] Deallocate:
   !---------------------------------------------------------------------------

   IF ( ob % num_sound > 0 ) then
      do n = 1, ob % num_sound
         deallocate (ob % sound ( n ) % h )
         deallocate (ob % sound ( n ) % p )
         deallocate (ob % sound ( n ) % zk)
         deallocate (ob % sound ( n ) % u )
         deallocate (ob % sound ( n ) % v )
         deallocate (ob % sound ( n ) % t )
         deallocate (ob % sound ( n ) % q )
      enddo

      DEALLOCATE (ob % sound)

      DEALLOCATE (ob % sonde_sfc)
   endif

   if (ob % num_synop > 0) DEALLOCATE (ob % synop)

   IF ( ob % num_airep > 0 ) then
      do n = 1, ob % num_airep
         deallocate (ob % airep ( n ) % h )
         deallocate (ob % airep ( n ) % p )
         deallocate (ob % airep ( n ) % zk)
         deallocate (ob % airep ( n ) % u )
         deallocate (ob % airep ( n ) % v )
         deallocate (ob % airep ( n ) % t )
      enddo

      DEALLOCATE (ob % airep)
   endif

   if (ob % num_satem > 0) then
      do n = 1, ob % num_satem
         deallocate (ob % satem(n) % p)
         deallocate (ob % satem(n) % thickness)
         deallocate (ob % satem(n) % org_thickness)
      end do
      deallocate (ob % satem)
   end if

   if (ob % num_geoamv > 0) then
      do n = 1, ob % num_geoamv
         deallocate (ob % geoamv(n) % p)
         deallocate (ob % geoamv(n) % zk)
         deallocate (ob % geoamv(n) % u)
         deallocate (ob % geoamv(n) % v)
      end do
      deallocate (ob % geoamv)
   end if


   if (ob % num_polaramv > 0) then
      do n = 1, ob % num_polaramv
         deallocate (ob % polaramv(n) % u)
         deallocate (ob % polaramv(n) % v)
      end do
      deallocate (ob % polaramv)
   end if

   if (ob % num_metar > 0) DEALLOCATE (ob % metar)
   if (ob % num_ships > 0) DEALLOCATE (ob % ships)

   IF ( ob % num_pilot > 0 ) then
      do n = 1, ob % num_pilot
         deallocate (ob % pilot ( n ) % p )
         deallocate (ob % pilot ( n ) % zk)
         deallocate (ob % pilot ( n ) % u )
         deallocate (ob % pilot ( n ) % v )
      enddo

      DEALLOCATE (ob % pilot)
   endif

   IF ( ob % num_bogus > 0 ) then
      do n = 1, ob % num_bogus
         deallocate (ob % bogus ( n ) % h )
         deallocate (ob % bogus ( n ) % p )
         deallocate (ob % bogus ( n ) % zk)
         deallocate (ob % bogus ( n ) % u )
         deallocate (ob % bogus ( n ) % v )
         deallocate (ob % bogus ( n ) % t )
         deallocate (ob % bogus ( n ) % q )
      enddo

      DEALLOCATE (ob % bogus)
   endif

   IF ( ob % num_Radar > 0 ) then
      do n = 1, ob % num_Radar
         deallocate (ob % Radar ( n ) % height   )
         deallocate (ob % Radar ( n ) % height_qc)
         deallocate (ob % Radar ( n ) % zk       )
         deallocate (ob % Radar ( n ) % rv       )
         deallocate (ob % Radar ( n ) % rf       )
      enddo

      DEALLOCATE (ob % Radar)
   endif

   if (ob % num_gpspw > 0) DEALLOCATE (ob % gpspw)

   if ( ob % num_gpsref > 0 ) then
      do n = 1, ob % num_gpsref
         deallocate (ob % gpsref(n) %  h )
         deallocate (ob % gpsref(n) %  zk)
         deallocate (ob % gpsref(n) % ref)
         deallocate (ob % gpsref(n) %   p)
         deallocate (ob % gpsref(n) %   t)
         deallocate (ob % gpsref(n) %   q)
      enddo
      DEALLOCATE (ob % gpsref)
   endif

   if (ob % num_ssmi_tb > 0) DEALLOCATE (ob % ssmi_tb)
   if (ob % num_ssmi_retrieval > 0) DEALLOCATE (ob % ssmi_retrieval)

   if (ob % num_ssmt1 > 0) then
      do n = 1, ob % num_ssmt1
         deallocate (ob % ssmt1(n) % h )
         deallocate (ob % ssmt1(n) % p )
         deallocate (ob % ssmt1(n) % zk)
         deallocate (ob % ssmt1(n) % t )
      enddo
   
      DEALLOCATE (ob % ssmt1)
   endif
   
   if (ob % num_ssmt2 > 0) then
      do n = 1, ob % num_ssmt2
         deallocate (ob % ssmt2(n) % h )
         deallocate (ob % ssmt2(n) % p )
         deallocate (ob % ssmt2(n) % zk)
         deallocate (ob % ssmt2(n) % rh)
      enddo
   
      DEALLOCATE (ob % ssmt2)
   endif

   if (ob % num_qscat > 0) DEALLOCATE (ob % qscat)

   if (ob%num_profiler > 0) then
      do n = 1, ob % num_profiler
         DEALLOCATE (ob%profiler(n)%p)
         DEALLOCATE (ob%profiler(n)%zk)
         DEALLOCATE (ob%profiler(n)%u)
         DEALLOCATE (ob%profiler(n)%v)
      end do

      DEALLOCATE(ob%profiler)
   endif

   if (ob%num_buoy     > 0) DEALLOCATE(ob%buoy)

   IF (ob % num_airsr > 0) then
      do n = 1, ob % num_airsr
         deallocate (ob % airsr ( n ) % h )
         deallocate (ob % airsr ( n ) % p )
         deallocate (ob % airsr ( n ) % zk)
         deallocate (ob % airsr ( n ) % t )
         deallocate (ob % airsr ( n ) % q )
      enddo

      DEALLOCATE (ob % airsr)
   endif

   IF (trace_use) CALL da_trace_exit("da_deallocate_observations")

END SUBROUTINE da_deallocate_observations
