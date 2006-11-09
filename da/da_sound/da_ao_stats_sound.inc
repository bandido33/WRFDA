subroutine da_ao_stats_sound( stats_unit, oi, re )

  !-------------------------------------------------------------
  !  Updates:       
  !     Bug fix for num_sound_tot   Syed RH Rizvi   07/28/2006    
  !-------------------------------------------------------------
  IMPLICIT NONE

  INTEGER,        INTENT (in)      :: stats_unit    ! Output unit for stats.
  TYPE (ob_type), INTENT (in)      :: oi            ! OI
  TYPE ( y_type), INTENT (in)      :: re            ! A - O

  TYPE (stats_sound_type)          :: Sound
  INTEGER                          :: nu, nv, nt, nq
  INTEGER                          :: n, k

  nu = 0
  nv = 0
  nt = 0
  nq = 0

  Sound%maximum%u = maxmin_type( missing_r, 0, 0)
  Sound%maximum%v = maxmin_type( missing_r, 0, 0)
  Sound%maximum%t = maxmin_type( missing_r, 0, 0)
  Sound%maximum%q = maxmin_type( missing_r, 0, 0)
  Sound%minimum%u = maxmin_type(-missing_r, 0, 0)
  Sound%minimum%v = maxmin_type(-missing_r, 0, 0)
  Sound%minimum%t = maxmin_type(-missing_r, 0, 0)
  Sound%minimum%q = maxmin_type(-missing_r, 0, 0)
  Sound%average = residual_sound1_type(0.0, 0.0, 0.0, 0.0)
  Sound%rms_err = Sound%average

  IF ( oi%num_Sound > 0 ) THEN
    DO n=1, oi%num_Sound
      if( oi%sound(n)%loc%proc_domain ) then
        do k=1, oi%sound(n)%info%levels

          call da_stats_calculate( n, k, oi%Sound(n)%u(k)%qc, & 
                              re%sound(n)%u(k), nu, &
                              sound%minimum%u, Sound%maximum%u, &
                              sound%average%u, Sound%rms_err%u )
          call da_stats_calculate( n, k, oi%Sound(n)%v(k)%qc, & 
                              re%sound(n)%v(k), nv, &
                              sound%minimum%v, Sound%maximum%v, &
                              sound%average%v, Sound%rms_err%v )
          call da_stats_calculate( n, k, oi%Sound(n)%t(k)%qc, & 
                              re%sound(n)%t(k), nt, &
                              sound%minimum%t, Sound%maximum%t, &
                              sound%average%t, Sound%rms_err%t )
          call da_stats_calculate( n, k, oi%Sound(n)%q(k)%qc, & 
                              re%Sound(n)%q(k), nq, &
                              Sound%minimum%q, Sound%maximum%q, &
                              Sound%average%q, Sound%rms_err%q )
        end do
      endif    ! end if( oi%sound(n)%loc%proc_domain )
    END DO
  END IF

  ! Do inter-processor communication to gather statistics.
  call da_proc_sum_int( nu )
  call da_proc_sum_int( nv )
  call da_proc_sum_int( nt )
  call da_proc_sum_int( nq )

   num_sound_tot = nu + nv + nt + nq

  call da_proc_stats_combine(Sound%average%u, Sound%rms_err%u, &
                          Sound%minimum%u%value, Sound%maximum%u%value, &
                          Sound%minimum%u%n, Sound%maximum%u%n, &
                          Sound%minimum%u%l, Sound%maximum%u%l )
  call da_proc_stats_combine(Sound%average%v, Sound%rms_err%v, &
                          Sound%minimum%v%value, Sound%maximum%v%value, &
                          Sound%minimum%v%n, Sound%maximum%v%n, &
                          Sound%minimum%v%l, Sound%maximum%v%l )
  call da_proc_stats_combine(Sound%average%t, Sound%rms_err%t, &
                          Sound%minimum%t%value, Sound%maximum%t%value, &
                          Sound%minimum%t%n, Sound%maximum%t%n, &
                          Sound%minimum%t%l, Sound%maximum%t%l )
  call da_proc_stats_combine(Sound%average%q, Sound%rms_err%q, &
                          Sound%minimum%q%value, Sound%maximum%q%value, &
                          Sound%minimum%q%n, Sound%maximum%q%n, &
                          Sound%minimum%q%l, Sound%maximum%q%l )

  IF ( rootproc ) THEN
    IF ( nu /= 0 .or. nv /= 0 .or. nt /= 0 .or. nq /= 0 ) THEN
      write(unit=stats_unit, fmt='(/a/)') ' Diagnostics of AO for Sound'
      call da_print_stats_sound(stats_unit, nu, nv, nt, nq, Sound)
    END IF
  END IF

end subroutine da_ao_stats_sound