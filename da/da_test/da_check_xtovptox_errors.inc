subroutine da_check_xtovptox_errors( xa, xa2_u, xa2_v, xa2_w, xa2_t, &
                                     xa2_p, xa2_q, xa2_rho, &
                                     xa2_qt, xa2_qcw, xa2_qrn, &
                                     ids,ide, jds,jde, kds,kde, &
                                     ims,ime, jms,jme, kms,kme, &
                                     its,ite, jts,jte, kts,kte )

   !---------------------------------------------------------------------------
   ! PURPOSE: Test invertibility of v = U^{-1} x followed by x = Uv.
   !
   !  METHOD:  Perform statistics on differences in initial and final x.
   !---------------------------------------------------------------------------

   IMPLICIT NONE
      
   TYPE (x_type), INTENT(IN)      :: xa          ! Test input

   integer, intent(in)            :: ids,ide, jds,jde, kds,kde ! domain dims.
   integer, intent(in)            :: ims,ime, jms,jme, kms,kme ! memory dims.
   integer, intent(in)            :: its,ite, jts,jte, kts,kte ! tile   dims.

   real, dimension(ims:ime, jms:jme, kms:kme), &
                 INTENT(IN)      :: xa2_u, xa2_v, xa2_t, &
                                    xa2_p, xa2_q, xa2_rho, &
                                    xa2_qt, xa2_qcw, xa2_qrn
   real, dimension(ims:ime, jms:jme, kms:kme), &
                 INTENT(IN)      :: xa2_w    !xiao


   REAL                           :: rms_fild    ! RMS of field.
   REAL                           :: rms_diff    ! RMS of differnce.

   real, dimension(ims:ime, jms:jme, kms:kme) :: diff ! Difference

   ! JRB Stop compiler whinging
   IF (ids==0 .OR. ide==0 .OR. jds==0 .OR. jde==0 .OR. kde==0 .OR. &
       kds==0) THEN
   END IF

   if (trace_use) call da_trace_entry("da_check_xtovpx_errors")

   !----------------------------------------------------------------------
   ! [1.0]: Check u differences:
   !----------------------------------------------------------------------

   diff(its:ite, jts:jte, kts:kte) = xa2_u(its:ite, jts:jte, kts:kte) &
                                   - xa% u(its:ite, jts:jte, kts:kte)
   
   rms_fild = SQRT( SUM( xa % u(its:ite, jts:jte, kts:kte) &
                       * xa % u(its:ite, jts:jte, kts:kte) ) )
   rms_diff = SQRT( SUM( diff(its:ite, jts:jte, kts:kte) &
                       * diff(its:ite, jts:jte, kts:kte) ) )
     
   IF ( rms_fild == 0.0 ) THEN
      write(UNIT=stdout, fmt='(a)') ' u is zero ' 
   ELSE
      write(UNIT=stdout, fmt='(a,1pe10.4)') ' u RMS error = ', rms_diff
      write(UNIT=stdout, fmt='(a,1pe10.4)') ' u RMS field = ', rms_fild
      write(UNIT=stdout, fmt='(a,1pe10.4)') ' u RMS error/RMS field = ', &
         rms_diff/rms_fild
   END IF        
     
   !----------------------------------------------------------------------
   ! [2.0]: Check v differences:
   !----------------------------------------------------------------------

   diff(its:ite, jts:jte, kts:kte) = xa2_v(its:ite, jts:jte, kts:kte) &
                                   - xa% v(its:ite, jts:jte, kts:kte)
   
   rms_fild = SQRT( SUM( xa % v(its:ite, jts:jte, kts:kte) &
                       * xa % v(its:ite, jts:jte, kts:kte) ) )
   rms_diff = SQRT( SUM( diff(its:ite, jts:jte, kts:kte) &
                       * diff(its:ite, jts:jte, kts:kte) ) )
     
   IF ( rms_fild == 0.0 ) THEN
      write(UNIT=stdout, fmt='(a)') ' v is zero ' 
   ELSE
      write(UNIT=stdout, fmt='(a,1pe10.4)') ' v RMS error = ', rms_diff
      write(UNIT=stdout, fmt='(a,1pe10.4)') ' v RMS field = ', rms_fild
      write(UNIT=stdout, fmt='(a,1pe10.4)') ' v RMS error/RMS field = ', &
      rms_diff/rms_fild
   END IF    
      
   !----------------------------------------------------------------------
   ! [3.0]: Check t differences:
   !----------------------------------------------------------------------

   diff(its:ite, jts:jte, kts:kte) = xa2_t(its:ite, jts:jte, kts:kte) &
                                   - xa% t(its:ite, jts:jte, kts:kte)

   rms_fild = SQRT( SUM( xa % t(its:ite, jts:jte, kts:kte) &
                       * xa % t(its:ite, jts:jte, kts:kte) ) )
   rms_diff = SQRT( SUM( diff(its:ite, jts:jte, kts:kte) &
                       * diff(its:ite, jts:jte, kts:kte) ) )

   IF ( rms_fild == 0.0 ) THEN
      write(UNIT=stdout, fmt='(a)') ' t is zero ' 
   ELSE
      write(UNIT=stdout, fmt='(a,1pe10.4)') ' t RMS error = ', rms_diff
      write(UNIT=stdout, fmt='(a,1pe10.4)') ' t RMS field = ', rms_fild
      write(UNIT=stdout, fmt='(a,1pe10.4)') ' t RMS error/RMS field = ', &
         rms_diff/rms_fild
   END IF         
        
   !----------------------------------------------------------------------
   ! [4.0]: Check p differences:
   !----------------------------------------------------------------------

   diff(its:ite, jts:jte, kts:kte) = xa2_p(its:ite, jts:jte, kts:kte) &
                                   - xa% p(its:ite, jts:jte, kts:kte)

   rms_fild = SQRT( SUM( xa % p(its:ite, jts:jte, kts:kte) &
                       * xa % p(its:ite, jts:jte, kts:kte) ) )
   rms_diff = SQRT( SUM( diff(its:ite, jts:jte, kts:kte) &
                       * diff(its:ite, jts:jte, kts:kte) ) )

   IF ( rms_fild == 0.0 ) THEN
      write(UNIT=stdout, fmt='(a)') ' p is zero ' 
   ELSE
      write(UNIT=stdout, fmt='(a,1pe10.4)') ' p RMS error = ', rms_diff
      write(UNIT=stdout, fmt='(a,1pe10.4)') ' p RMS field = ', rms_fild
      write(UNIT=stdout, fmt='(a,1pe10.4)') ' p RMS error/RMS field = ', &
         rms_diff/rms_fild
   END IF           

   !----------------------------------------------------------------------
   ! [5.0]: Check q differences:
   !----------------------------------------------------------------------

   diff(its:ite, jts:jte, kts:kte) = xa2_q(its:ite, jts:jte, kts:kte) &
                                   - xa% q(its:ite, jts:jte, kts:kte)

   rms_fild = SQRT( SUM( xa % q(its:ite, jts:jte, kts:kte) &
                       * xa % q(its:ite, jts:jte, kts:kte) ) )
   rms_diff = SQRT( SUM( diff(its:ite, jts:jte, kts:kte) &
                       * diff(its:ite, jts:jte, kts:kte) ) )

   IF ( rms_fild == 0.0 ) THEN
      write(UNIT=stdout, fmt='(a)') ' q is zero ' 
   ELSE
      write(UNIT=stdout, fmt='(a,1pe10.4)') ' q RMS error = ', rms_diff
      write(UNIT=stdout, fmt='(a,1pe10.4)') ' q RMS field = ', rms_fild
      write(UNIT=stdout, fmt='(a,1pe10.4)') ' q RMS error/RMS field = ', &
         rms_diff/rms_fild
   END IF        

   !----------------------------------------------------------------------
   ! [6.0]: Check rho differences:
   !----------------------------------------------------------------------

   diff(its:ite, jts:jte, kts:kte) = xa2_rho(its:ite, jts:jte, kts:kte) &
                                   - xa% rho(its:ite, jts:jte, kts:kte)

   rms_fild = SQRT( SUM( xa % rho(its:ite, jts:jte, kts:kte) &
                       * xa % rho(its:ite, jts:jte, kts:kte) ) )
   rms_diff = SQRT( SUM( diff(its:ite, jts:jte, kts:kte) &
                       * diff(its:ite, jts:jte, kts:kte) ) )

   IF ( rms_fild == 0.0 ) THEN
      write(UNIT=stdout, fmt='(a)') ' rho is zero ' 
   ELSE
      write(UNIT=stdout, fmt='(a,1pe10.4)') ' rho RMS error = ', rms_diff
      write(UNIT=stdout, fmt='(a,1pe10.4)') ' rho RMS field = ', rms_fild
      write(UNIT=stdout, fmt='(a,1pe10.4)') ' rho RMS error/RMS field = ', &
         rms_diff/rms_fild
   END IF        

   !----------------------------------------------------------------------
   ! [7.0]: Check w differences:
   !----------------------------------------------------------------------

   diff(its:ite, jts:jte, kts:kte+1) = xa2_w(its:ite, jts:jte, kts:kte+1) &
                                     - xa% w(its:ite, jts:jte, kts:kte+1)

   rms_fild = SQRT( SUM( xa % w(its:ite, jts:jte, kts:kte+1) &
                       * xa % w(its:ite, jts:jte, kts:kte+1) ) )
   rms_diff = SQRT( SUM( diff(its:ite, jts:jte, kts:kte+1) &
                       * diff(its:ite, jts:jte, kts:kte+1) ) )

   IF ( rms_fild == 0.0 ) THEN
      write(UNIT=stdout, fmt='(a)') ' w is zero '
   ELSE
      write(UNIT=stdout, fmt='(a,1pe10.4)') ' w RMS error = ', rms_diff
      write(UNIT=stdout, fmt='(a,1pe10.4)') ' w RMS field = ', rms_fild
      write(UNIT=stdout, fmt='(a,1pe10.4)') ' w RMS error/RMS field = ', &
         rms_diff/rms_fild
   END IF

   if ( cv_options_hum == 3 ) then
      !-------------------------------------------------------------------
      ! [8.0]: Check qt differences:
      !-------------------------------------------------------------------

      diff(its:ite, jts:jte, kts:kte) = xa2_qt(its:ite, jts:jte, kts:kte) &
                                      - xa% qt(its:ite, jts:jte, kts:kte)

      rms_fild = SQRT( SUM( xa % qt(its:ite, jts:jte, kts:kte) &
                          * xa % qt(its:ite, jts:jte, kts:kte) ) )
      rms_diff = SQRT( SUM( diff(its:ite, jts:jte, kts:kte) &
                          * diff(its:ite, jts:jte, kts:kte) ) )

      IF ( rms_fild == 0.0 ) THEN
         write(UNIT=stdout, fmt='(a)') ' qt is zero '
      ELSE
         write(UNIT=stdout, fmt='(a,1pe10.4)') ' qt RMS error = ', rms_diff
         write(UNIT=stdout, fmt='(a,1pe10.4)') ' qt RMS field = ', rms_fild
         write(UNIT=stdout, fmt='(a,1pe10.4)') ' qt RMS error/RMS field = ', &
         rms_diff/rms_fild
      END IF

      !----------------------------------------------------------------------
      ! [9.0]: Check qcw differences:
      !----------------------------------------------------------------------

      diff(its:ite, jts:jte, kts:kte) = xa2_qcw(its:ite, jts:jte, kts:kte) &
                                      - xa% qcw(its:ite, jts:jte, kts:kte)

      rms_fild = SQRT( SUM( xa % qcw(its:ite, jts:jte, kts:kte) &
                          * xa % qcw(its:ite, jts:jte, kts:kte) ) )
      rms_diff = SQRT( SUM( diff(its:ite, jts:jte, kts:kte) &
                          * diff(its:ite, jts:jte, kts:kte) ) )

      IF ( rms_fild == 0.0 ) THEN
         write(UNIT=stdout, fmt='(a)') ' qcw is zero '
      ELSE
         write(UNIT=stdout, fmt='(a,1pe10.4)') ' qcw RMS error = ', rms_diff
         write(UNIT=stdout, fmt='(a,1pe10.4)') ' qcw RMS field = ', rms_fild
         write(UNIT=stdout, fmt='(a,1pe10.4)') ' qcw RMS error/RMS field = ', &
            rms_diff/rms_fild
      END IF

      !-------------------------------------------------------------------
      ! [10.0]: Check qrn differences:
      !-------------------------------------------------------------------

      diff(its:ite, jts:jte, kts:kte) = xa2_qrn(its:ite, jts:jte, kts:kte) &
                                      - xa% qrn(its:ite, jts:jte, kts:kte)

      rms_fild = SQRT( SUM( xa % qrn(its:ite, jts:jte, kts:kte) &
                          * xa % qrn(its:ite, jts:jte, kts:kte) ) )
      rms_diff = SQRT( SUM( diff(its:ite, jts:jte, kts:kte) &
                          * diff(its:ite, jts:jte, kts:kte) ) )

      IF ( rms_fild == 0.0 ) THEN
         write(UNIT=stdout, fmt='(a)') ' qrn is zero '
      ELSE
         write(UNIT=stdout, fmt='(a,1pe10.4)') ' qrn RMS error = ', rms_diff
         write(UNIT=stdout, fmt='(a,1pe10.4)') ' qrn RMS field = ', rms_fild
         write(UNIT=stdout, fmt='(a,1pe10.4)') ' qrn RMS error/RMS field = ', &
            rms_diff/rms_fild
      END IF

   endif

   if (trace_use) call da_trace_exit("da_check_xtovpx_errors")
         
end subroutine da_check_xtovptox_errors
