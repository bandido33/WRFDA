subroutine da_set_boundary_3d(var, &
                              ids, ide, jds, jde, kds, kde, &
                              ims, ime, jms, jme, kms, kme, &
                              its, ite, jts, jte, kts, kte)
   !------------------------------------------------------------------------
   !  Purpose: 
   !
   !  Merge East-West boundary values for input 3d-array (var)
   !------------------------------------------------------------------------

   implicit none
   integer, intent(in) :: ids, ide, jds, jde, kds, kde, &
                          ims, ime, jms, jme, kms, kme, &
                          its, ite, jts, jte, kts, kte
   real, dimension(ims:ime, jms:jme, kms:kme) :: var

   integer :: n, j, k

   ! JRB use variables to stop compiler whinge
   IF (kds == 1 .OR. jds == 1 .OR. jde == 1 .OR. kde == 1) THEN
   END IF

   if((its /= ids) .or. (ite /= ide)) return

   do k=kts, kte
      do j=jts, jte
         do n=1,bdyzone
            var(ids-n,j,k) = var(ide+1-n,j,k)
            var(ide+n,j,k) = var(ids-1+n,j,k)
         enddo
      enddo
   enddo

end subroutine da_set_boundary_3d
