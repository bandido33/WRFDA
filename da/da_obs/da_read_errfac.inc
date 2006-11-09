subroutine da_read_errfac( ob_name, f1, f2, f3, f4, f5 )

   implicit none
   
   character (len=5), intent(in) :: ob_name
   real, intent(out)             :: f1
   real, intent(out)             :: f2
   real, intent(out)             :: f3
   real, intent(out)             :: f4
   real, intent(out)             :: f5

   character (len=5)             :: ob_name1
   character (len=21)            :: string1
   character (len=91)            :: string2
   integer                       :: ierr, fac_unit
   real                          :: d1, d2, d3, d4, d5

   f1 = 1.0
   f2 = 1.0
   f3 = 1.0
   f4 = 1.0
   f5 = 1.0

   call da_get_unit(fac_unit)
   open(UNIT=fac_unit, status='old', file = 'errfac.dat', iostat=ierr )

   if ( ierr == 0 ) then
   
      do 
         read(UNIT=fac_unit,FMT='(1x,a5,a21,a91)')ob_name1, string1, string2

         if ( ob_name == ob_name1 .and. &
              string1 == ' obs, Error Factor = ' ) then
            read(UNIT=string2(17:31),FMT=*)d1
            read(UNIT=string2(32:46),FMT=*)d2
            read(UNIT=string2(47:61),FMT=*)d3
            read(UNIT=string2(62:76),FMT=*)d4
            read(UNIT=string2(77:91),FMT=*)d5
            if ( d1 > 0.0 ) f1 = d1
            if ( d2 > 0.0 ) f2 = d2
            if ( d3 > 0.0 ) f3 = d3
            if ( d4 > 0.0 ) f4 = d4
            if ( d5 > 0.0 ) f5 = d5

            exit
         else if ( ob_name1 == 'Total' ) then
            write(UNIT=stderr,FMT='(a,a)')' No Tuning Error factors for ', ob_name
            write(UNIT=stderr,FMT='(a)')' So setting to 1.0 i.e. default errors.'  
            exit
         end if

      end do
      
   else   
      write(UNIT=stderr,FMT='(a)')' WARNING: Error reading errfac.dat - Not tuning ob errors'
   end if

   close( fac_unit )
   call da_free_unit(fac_unit)

end subroutine da_read_errfac
