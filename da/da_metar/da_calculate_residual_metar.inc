subroutine da_calculate_residual_metar( oi, y, re,                        &
                                        np_missing, np_bad_data,          &
                                        np_obs_used, np_available )

   IMPLICIT NONE

   TYPE (ob_type), INTENT(IN)        :: oi     ! Innovation vector (O-B).
   TYPE (y_type) , INTENT(IN)        :: y      ! y = H (xa)
   TYPE (y_type) , INTENT(INOUT)     :: re     ! Residual structure.

   INTEGER       , INTENT(INOUT)     :: np_available, np_obs_used,          &
                                        np_missing  , np_bad_data

   TYPE (bad_data_type)              :: n_obs_bad
   INTEGER                           :: n

   IF (trace_use) call da_trace_entry("da_calculate_residual_metar")

   IF ( oi%num_metar > 0 ) THEN
      n_obs_bad % u % num = number(0, 0, 0)
      n_obs_bad % v % num = number(0, 0, 0)
      n_obs_bad % t % num = number(0, 0, 0)
      n_obs_bad % p % num = number(0, 0, 0)
      n_obs_bad % q % num = number(0, 0, 0)

      DO n=1, oi%num_metar
         np_available = np_available + 5

         re%metar(n)%u = da_residual( n, 0, y%metar(n)%u, &
                                     oi%metar(n)%u, n_obs_bad % u )
         re%metar(n)%v = da_residual( n, 0, y%metar(n)%v, &
                                  oi%metar(n)%v, n_obs_bad % v )
         re%metar(n)%t = da_residual( n, 0, y%metar(n)%t, &
                                  oi%metar(n)%t, n_obs_bad % t )
         re%metar(n)%p = da_residual( n, 0, y%metar(n)%p, &
                                  oi%metar(n)%p, n_obs_bad % p )
         re%metar(n)%q = da_residual( n, 0, y%metar(n)%q, &
                                  oi%metar(n)%q, n_obs_bad % q )
      END DO

      np_missing = np_missing + n_obs_bad % u % num % miss + &
                  n_obs_bad % v % num % miss + n_obs_bad % t % num % miss + &
                  n_obs_bad % p % num % miss + n_obs_bad % q % num % miss
      np_bad_data = np_bad_data + n_obs_bad % u % num % bad + &
                   n_obs_bad % v % num % bad + n_obs_bad % t % num % bad + &
                   n_obs_bad % p % num % bad + n_obs_bad % q % num % bad
      np_obs_used = np_obs_used + n_obs_bad % u % num % use + &
                   n_obs_bad % v % num % use + n_obs_bad % t % num % use + &
                   n_obs_bad % p % num % use + n_obs_bad % q % num % use

   ENDIF

   IF (trace_use) call da_trace_exit("da_calculate_residual_metar")

end subroutine da_calculate_residual_metar
