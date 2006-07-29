   subroutine da_transform_vtovv_adj( cv_size, xb, be, cv, vv, xp, &
                                      ids,ide, jds,jde, kds,kde,  &
                                      ims,ime, jms,jme, kms,kme,  &
                                      its,ite, jts,jte, kts,kte )

   implicit none

   integer, intent(in)              :: cv_size ! Size of cv array.
   type (xb_type), intent(in)       :: xb   ! First guess structure.
   type (be_type), intent(in)       :: be   ! Background error structure.
   real, intent(inout)              :: cv(1:cv_size)   ! control variables.
   type (vp_type), intent(inout)    :: vv   ! Grid point/EOF control var.
   type (xpose_type), intent(inout) :: xp   ! Dimensions and xpose buffers. 
   integer, intent(in)              :: ids,ide, jds,jde, kds,kde ! domain dims.
   integer, intent(in)              :: ims,ime, jms,jme, kms,kme ! memory dims.
   integer, intent(in)              :: its,ite, jts,jte, kts,kte ! tile   dims.

   integer                          :: mz   ! Vertical truncation.

   IF (trace_use) call da_trace_entry("da_transform_vtovv_adj")

!-------------------------------------------------------------------------
!  [2.0] Perform VToVV Transform:
!-------------------------------------------------------------------------

!  [2.1] Transform 1st control variable:

   mz = be % v1 % mz
   IF ( mz > 0 ) then
      call da_transform_through_rf_adj( mz, xb % grid_box_area, be % v1 % rf_alpha,&
                                    be % v1 % val, xp, vv % v1, &
                                    ids,ide, jds,jde, kds,kde,  &
                                    ims,ime, jms,jme, kms,kme,  &
                                    its,ite, jts,jte, kts,kte )
   END IF

!  [2.2] Transform 2nd control variable:

   mz = be % v2 % mz
   IF ( mz > 0 ) then
      call da_transform_through_rf_adj( mz, xb % grid_box_area, be % v2 % rf_alpha,&
                                    be % v2 % val, xp, vv % v2, &
                                    ids,ide, jds,jde, kds,kde,  &
                                    ims,ime, jms,jme, kms,kme,  &
                                    its,ite, jts,jte, kts,kte )
   END IF

!  [2.3] Transform 3rd control variable

   mz = be % v3 % mz
   IF ( mz > 0 ) then
      call da_transform_through_rf_adj( mz, xb % grid_box_area, be % v3 % rf_alpha,&
                                    be % v3 % val, xp, vv % v3, &
                                    ids,ide, jds,jde, kds,kde,  &
                                    ims,ime, jms,jme, kms,kme,  &
                                    its,ite, jts,jte, kts,kte )
   END IF
   
!  [2.4] Transform 4th control variable
      
   mz = be % v4 % mz
   IF ( mz > 0 ) then
      call da_transform_through_rf_adj( mz, xb % grid_box_area, be % v4 % rf_alpha,&
                                    be % v4 % val, xp, vv % v4, &
                                    ids,ide, jds,jde, kds,kde,  &
                                    ims,ime, jms,jme, kms,kme,  &
                                    its,ite, jts,jte, kts,kte )
   END IF

!  [2.5] Transform 5th control variable

   mz = be % v5 % mz
   IF ( mz > 0 ) then
      call da_transform_through_rf_adj( mz, xb % grid_box_area, be % v5 % rf_alpha,&
                                    be % v5 % val, xp, vv % v5, &
                                    ids,ide, jds,jde, kds,kde,  &
                                    ims,ime, jms,jme, kms,kme,  &
                                    its,ite, jts,jte, kts,kte )
   END IF

!  [2.6] Transform alpha control variable

   mz = be % alpha % mz
   IF ( mz > 0 ) then
      call da_transform_through_rf_adj( mz, xb % grid_box_area, be % alpha % rf_alpha,&
                                        be % alpha % val, xp, vv % alpha, &
                                        ids,ide, jds,jde, kds,kde,  &
                                        ims,ime, jms,jme, kms,kme,  &
                                        its,ite, jts,jte, kts,kte )
   END IF

!-------------------------------------------------------------------------
!  [1.0] Fill 1D cv array from 3-dimensional vv arrays.
!-------------------------------------------------------------------------

   call da_vv_to_cv( vv, xp, &
                  (/ be%v1%mz, be%v2%mz, be%v3%mz, be%v4%mz, be%v5%mz, be%ne /), &
                  cv_size, cv )

   IF (trace_use) call da_trace_exit("da_transform_vtovv_adj")


END subroutine da_transform_vtovv_adj
