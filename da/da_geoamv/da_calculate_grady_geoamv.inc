subroutine da_calculate_grady_geoamv( iv, re, jo_grad_y )

   !-------------------------------------------------------------------------
   ! Purpose: Calculates Gradient of Geo. CMVs Obs.
   !               
   !-------------------------------------------------------------------------

   IMPLICIT NONE


   TYPE (ob_type), INTENT(IN)     :: iv          ! Innovation vector.
   TYPE (y_type),  INTENT(INOUT)  :: re          ! Residual vector.
   TYPE (y_type),  INTENT(INOUT)  :: jo_grad_y   ! Grad_y(Jo)

   INTEGER                      :: n , k

   IF ( iv%num_geoamv > 0 ) THEN
      DO n=1, iv%num_geoamv
         do k=1, iv%geoamv(n)%info%levels
            if(iv%geoamv(n)%u(k)%qc < obs_qc_pointer) re%geoamv(n)%u(k) = 0.0
            if(iv%geoamv(n)%v(k)%qc < obs_qc_pointer) re%geoamv(n)%v(k) = 0.0

            jo_grad_y%geoamv(n)%u(k) = -re%geoamv(n)%u(k) / &
                                      ( iv%geoamv(n)%u(k)%error * &
                                        iv%geoamv(n)%u(k)%error )
            jo_grad_y%geoamv(n)%v(k) = -re%geoamv(n)%v(k) / &
                                      ( iv%geoamv(n)%v(k)%error * &
                                        iv%geoamv(n)%v(k)%error )
         end do
      END DO
   END IF

end subroutine da_calculate_grady_geoamv