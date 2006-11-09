subroutine da_transform_xtoy_airep ( xa, iv, xp, y )

   IMPLICIT NONE

   TYPE (x_type),  INTENT(IN)   :: xa       ! gridded analysis increment.
   TYPE (ob_type), INTENT(IN)   :: iv       ! Innovation vector (O-B).
   TYPE (xpose_type), INTENT(IN):: xp       ! Domain decomposition vars.
   TYPE (y_type), INTENT(INOUT) :: y        ! y = h (xa) (linear)

   INTEGER                      :: n        ! Loop counter.
   INTEGER                      :: i, j, k  ! Index dimension.
   REAL                         :: dx, dxm  ! 
   REAL                         :: dy, dym  !

   IF ( iv%num_airep > 0 ) THEN
      do n=iv%ob_numb(iv%current_ob_time-1)%airep + 1, iv%ob_numb(iv%current_ob_time)%airep
         k = iv % airep(n) % info % levels
         if ( k < 1 ) cycle

         ! xyh         y%airep(n)%u(:) = 0.0
         ! xyh         y%airep(n)%v(:) = 0.0
         ! xyh         y%airep(n)%t(:) = 0.0

         ! [1.1] Get horizontal interpolation weights:

         i = iv%airep(n)%loc%i
         dy = iv%airep(n)%loc%dy
         dym = iv%airep(n)%loc%dym
         j = iv%airep(n)%loc%j
         dx = iv%airep(n)%loc%dx
         dxm = iv%airep(n)%loc%dxm

         ![1.2] Interpolate horizontally:
#ifndef DEREF_KLUDGE
         call da_interp_lin_3d(xa % u, xp, i, j, dx, dy, dxm, dym, &
                           y%airep(n)%u, k, iv%airep(n)%zk, k)

         call da_interp_lin_3d(xa % v, xp, i, j, dx, dy, dxm, dym, &
                           y%airep(n)%v, k, iv%airep(n)%zk, k)

         call da_interp_lin_3d(xa % t, xp, i, j, dx, dy, dxm, dym, &
                           y%airep(n)%t, k, iv%airep(n)%zk, k)

#else
         call da_interp_lin_3d(xa % u(xp%ims,xp%jms,xp%kms), xp, i, j, dx, dy, dxm, dym, &
                           y%airep(n)%u(1), k, iv%airep(n)%zk(1), k)

         call da_interp_lin_3d(xa % v(xp%ims,xp%jms,xp%kms), xp, i, j, dx, dy, dxm, dym, &
                           y%airep(n)%v(1), k, iv%airep(n)%zk(1), k)

         call da_interp_lin_3d(xa % t(xp%ims,xp%jms,xp%kms), xp, i, j, dx, dy, dxm, dym, &
                           y%airep(n)%t(1), k, iv%airep(n)%zk(1), k)

#endif
      end do
   ENDIF

end subroutine da_transform_xtoy_airep
