subroutine da_reflectivity_lin( rf, qrn, qrn9 )

   implicit none

   real, intent(in)  :: qrn
   real, intent(in)  :: qrn9
   real, intent(out) :: rf

   REAL, PARAMETER   :: leh1=43.1
   REAL, PARAMETER   :: leh2=17.5

   rf = leh2 * qrn /(qrn9*alog(10.)) 

end subroutine da_reflectivity_lin