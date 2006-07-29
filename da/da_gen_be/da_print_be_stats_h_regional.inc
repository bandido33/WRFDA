subroutine da_print_be_stats_h_regional( outunit, variable, nk, scale_length )

   implicit none 

   integer, intent(inout)   :: outunit               ! Output file unit.
   character*10, intent(in) :: variable              ! Variable name.
   integer, intent(in)      :: nk                    ! Dimension of vertical index.
   real, intent(in)         :: scale_length(1:nk)    ! Correlation scale lengths.

   integer                  :: k                     ! Loop counter.

   write(UNIT=6,FMT='(3a,i5)')' Scale length for variable ', trim(variable), ' in unit ', outunit

   do k = 1, nk
     write(UNIT=outunit,FMT='(i4,1pe15.5)')k, scale_length(k)
   end do

   outunit = outunit + 1
   write(UNIT=6,FMT=*) ' '

end subroutine da_print_be_stats_h_regional
