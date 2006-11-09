
subroutine da_calculate_grady_rad( iv, re, jo_grad_y ) 
!------------------------------------------------------------------------------
!  PURPOSE: Calculate Gradient_y for radiance data.
!
!  METHOD:  grad_y = -R^-1 (d - H delta_x ).
!
!  HISTORY: 08/2005 - Creation            Zhiquan Liu
!
!------------------------------------------------------------------------------
   IMPLICIT NONE

   TYPE (ob_type), INTENT(IN)    :: iv          ! Innovation vector.
   TYPE (y_type) , INTENT(IN)    :: re          ! Residual vector.
   TYPE (y_type) , INTENT(INOUT) :: jo_grad_y   ! Grad_y(Jo)

   INTEGER                       :: n, k, i

   IF ( iv%num_inst < 1 ) RETURN

   if (trace_use) call da_trace_entry("da_calculate_grady_rad")

   DO i =1, iv%num_inst
      IF ( iv%instid(i)%num_rad < 1 ) cycle
      DO n=1, iv%instid(i)%num_rad
         do k=1, iv%instid(i)%nchan
            jo_grad_y%instid(i)%rad(n)%tb(k) = -re%instid(i)%rad(n)%tb(k) / &
                                      ( iv%instid(i)%rad(n)%tb(k)%error * &
                                        iv%instid(i)%rad(n)%tb(k)%error )
         end do
      END DO
   END DO

   if (trace_use) call da_trace_exit("da_calculate_grady_rad")

end subroutine da_calculate_grady_rad
