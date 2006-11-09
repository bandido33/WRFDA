subroutine da_check_balance( phi, phi_u )

   !---------------------------------------------------------------------------
   ! PURPOSE: Compare balanced mass (phi_b - function of wind) and actual phi.
   !
   ! METHOD:  Calculate correlation between balanced and actual phi.
   !---------------------------------------------------------------------------

   IMPLICIT NONE
      
   REAL, INTENT(IN)             :: phi(:,:,:)      ! Total phi.
   REAL, INTENT(IN)             :: phi_u(:,:,:)    ! Unbalanced phi.

   INTEGER                      :: iy              ! Size of 1st dimension.
   INTEGER                      :: jx              ! Size of 2nd dimension.
   INTEGER                      :: kz              ! Size of 3rd dimension.
   INTEGER                      :: i, k            ! Loop counters
   REAL                         :: corr_coef       ! Correlation coefficient.
   REAL                         :: accurac         ! Accuracy.
   REAL, ALLOCATABLE            :: phi_b1(:)       ! 1D balanced phi.
   REAL, ALLOCATABLE            :: phi_b2(:,:)     ! 2D balanced phi.
   REAL, ALLOCATABLE            :: corr_coeff(:,:) ! Correlation coefficient.
   REAL, ALLOCATABLE            :: accuracy(:,:)   ! Accuracy.

   if (trace_use) call da_trace_entry("da_check_balance")
          
   IF ( balance_type == balance_geo ) THEN
      write(UNIT=stdout, fmt='(a)') ' da_check_balance: Balance is geostrophic.'
   ELSE IF ( balance_type == balance_cyc ) THEN
      write(UNIT=stdout, fmt='(a)') &
         ' da_check_balance: Balance is cyclostrophic.'
   ELSE IF ( balance_type == balance_geocyc ) THEN
      write(UNIT=stdout, fmt='(a)') &
         ' da_check_balance: Balance is geo/cyclostrophic.'
   END IF
      
   write(UNIT=stdout, fmt='(a)') ' da_check_balance: Correlation/accuracy: '
      
   !-------------------------------------------------------------------------
   ! [1.0]: Initialise:
   !-------------------------------------------------------------------------  

   iy = SIZE(phi_u, DIM=1)
   jx = SIZE(phi_u, DIM=2)
   kz = SIZE(phi_u, DIM=3)
      
   ALLOCATE(phi_b1(1:jx))
   ALLOCATE(phi_b2(1:iy,1:jx))

   ALLOCATE(corr_coeff(1:kz,1:iy))
   corr_coeff(1:kz,1:iy) = 0.0

   ALLOCATE(accuracy(1:kz,1:iy))
   accuracy(1:kz,1:iy) = 0.0
      
   !-------------------------------------------------------------------------
   ! [2.0]: Calculate correlations/accuracy:
   !-------------------------------------------------------------------------  

   do k = 1, kz
      do i = 1, iy

         phi_b1(2:jx-1) = phi(i,2:jx-1,k) - phi_u(i,2:jx-1,k)
            
         call da_correlation_coeff1d( phi_b1(2:jx-1), phi(i,2:jx-1,k), &
                                      corr_coeff(k,i), accuracy(k,i) )
     
         ! write(58,*) corr_coeff(k,i), accuracy(k,i)
      end do
         
      phi_b2(2:iy-1,2:jx-1) = phi(2:iy-1,2:jx-1,k) - phi_u(2:iy-1,2:jx-1,k)
      call da_correlation_coeff2d( phi_b2(2:iy-1,2:jx-1), &
                                   phi(2:iy-1,2:jx-1,k), &
                                   corr_coef, accurac )

      write(UNIT=stdout, fmt='(i6,1pe9.2,1pe9.2)') &
            k, corr_coef, accurac

   end do

   !-------------------------------------------------------------------------
   ! [3.0]: Tidy up:
   !-------------------------------------------------------------------------  

   DEALLOCATE(phi_b1)
   DEALLOCATE(phi_b2)
   DEALLOCATE(corr_coeff)
   DEALLOCATE(accuracy)

   if (trace_use) call da_trace_exit("da_check_balance")

end subroutine da_check_balance
