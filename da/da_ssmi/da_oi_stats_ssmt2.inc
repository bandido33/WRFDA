subroutine da_oi_stats_ssmt2 ( stats_unit, iv )

   IMPLICIT NONE

   INTEGER,        INTENT (in)      :: stats_unit    ! Output unit for stats.
   TYPE (ob_type), INTENT (in)      :: iv            ! O-B

   TYPE (maxmin_type)               :: minimum
   TYPE (maxmin_type)               :: maximum
   INTEGER                          :: nrh
   INTEGER                          :: n, k
   real                             :: average, rms_err

   LOGICAL, EXTERNAL :: wrf_dm_on_monitor

   nrh = 0
   
   maximum = maxmin_type(-1.0E+20, 0, 0)
   minimum = maxmin_type( 1.0E+20, 0, 0)
   average = 0.0
   rms_err = 0.0

   IF ( iv%num_ssmt2 > 0 ) THEN

      DO n=1, iv%num_ssmt2

         if ( iv%ssmt2(n)%loc%proc_domain ) then

            do k=1, iv%ssmt2(n)%info%levels
    
               CALL da_stats_calculate( n, k, iv%ssmt2(n)%rh(k)%qc, &
                                     iv%ssmt2(n)%rh(k)%inv, nrh, &
                                     minimum, maximum, &
                                     average, rms_err)
            end do
         end if    ! end if( iv%ssmt2(n)%loc%proc_domain )
      END DO
      
   END IF

! Do inter-processor communication to gather statistics.
   call da_proc_sum_int( nrh )
   
   call da_proc_stats_combine(average, rms_err, &
                           minimum%value, maximum%value, &
                           minimum%n, maximum%n, &
                           minimum%l, maximum%l )
   
   IF ( wrf_dm_on_monitor() ) THEN
   
     IF ( nrh /= 0 ) THEN
   
      write(unit=stats_unit, fmt='(/a/)') ' Diagnostics of O-B for SSMT2'
   
      CALL da_print_stats_ssmt2( stats_unit, nrh, minimum, maximum, &
                                 average, rms_err )
   
     END IF
   
   END IF

end subroutine da_oi_stats_ssmt2