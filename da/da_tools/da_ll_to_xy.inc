subroutine da_ll_to_xy (info, loc, xp, &
                        outside, outside_all)

!  This routine convert the (lat, lon) into (x,y) coordinates
!  Additions:      10/26/2004    Syed RH Rizvi
!                  Global domain co-ordinates
   IMPLICIT NONE

   !  Argument

   TYPE(info_type),       intent(in)    :: info
   TYPE(model_loc_type),  intent(inout) :: loc
   TYPE(xpose_type),      intent(in)    :: xp           !Domain decomposition vars.
   LOGICAL      ,         intent(out)   :: outside      !wrt local domain
   LOGICAL, OPTIONAL,     intent(out)   :: outside_all  !wrt all domains

   outside = .false.
   loc % x   = -1.0
   loc % y   = -1.0
   
!  get the (x, y) coordinates

   if(fg_format == fg_format_wrf) then
      call da_latlon_to_ij(map_info, info%lat, info%lon, loc%x, loc%y)
   else if(fg_format == fg_format_kma) then
      call da_global_ll_to_xy (info%lat, info%lon, loc%x, loc%y)
   else
      call da_llxy (info%lat, info%lon, loc%x, loc%y)
   endif

   call da_togrid (loc%x, xp%its-2, xp%ite+2, loc%i, loc%dx, loc%dxm)
   call da_togrid (loc%y, xp%jts-2, xp%jte+2, loc%j, loc%dy, loc%dym)

   ! refactor to remove this ugly duplication later
   IF ( PRESENT( outside_all ) ) THEN
     outside_all = .false.
! Syed RH Rizvi  03/16/2006
! Do not check for global options 
    IF ( .not. global) then 
     if((int(loc%x) < xp%ids) .or. (int(loc%x) >= xp%ide) .or. &
        (int(loc%y) < xp%jds) .or. (int(loc%y) >= xp%jde)) then
!     if((loc%i < xp%ids) .or. (loc%i >= xp%ide) .or. &
!        (loc%j < xp%jds) .or. (loc%j >= xp%jde)) then
        outside_all = .true. 
     endif
     if(def_sub_domain ) then
        if( x_start_sub_domain > loc%x .or. y_start_sub_domain > loc%y .or. &
            x_end_sub_domain   < loc%x .or. y_end_sub_domain   < loc%y) then
            outside_all = .true.
        endif
     endif
    ENDIF
   ENDIF

   if (fg_format == fg_format_kma) then
      if((loc%j < xp%jts-1) .or. (loc%j > xp%jte)) then
         outside = .true.
         return
      endif

      if(loc%j == xp%jde) then
         loc%j = loc%j - 1
         loc%dy  = 1.0
         loc%dym = 0.0
      end if

      return
   endif

!--Computation to check for edge of domain:
   if((loc%i < xp%ids) .or. (loc%i >= xp%ide) .or. &
      (loc%j < xp%jds) .or. (loc%j >= xp%jde)) then
      outside     = .true. 
      return
   endif

   if((loc%i < xp%its-1) .or. (loc%i > xp%ite) .or. &
      (loc%j < xp%jts-1) .or. (loc%j > xp%jte)) then
      outside = .true.
      return

      if(def_sub_domain ) then
         if( x_start_sub_domain > loc%x .or. y_start_sub_domain > loc%y .or. &
             x_end_sub_domain   < loc%x .or. y_end_sub_domain   < loc%y) then
             outside = .true.
         endif
      endif
   endif

end subroutine da_ll_to_xy
