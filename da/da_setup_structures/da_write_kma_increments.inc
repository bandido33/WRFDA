subroutine da_write_kma_increments(xp, xb, xa)

   !---------------------------------------------------------------------------
   ! PURPOSE: Gathers KMA analysis increments and writes 
   !           on i"anl_inc_unit" unit 
   !---------------------------------------------------------------------------

   IMPLICIT NONE

   TYPE(xb_type)                               :: xb
   TYPE(x_type)                                :: xa
   TYPE(xpose_type)                            :: xp

   ! Arrays for write out increments:
   integer                                     :: ix, jy, kz
   real, dimension(1:xb%mix,1:xb%mjy)          :: gbuf_2d
   real, dimension(1:xb%mix,1:xb%mjy,1:xb%mkz) :: gbuf

   real, dimension(:,:)  , allocatable :: psfc_g
   real, dimension(:,:,:), allocatable :: u_g, v_g, t_g, q_g, p_g

   integer                                     :: i, j, k,anl_inc_unit

   IF (trace_use) call da_trace_entry("da_write_kma_increments")

   ! Dimension of the domain:
   ix = xb%mix
   jy = xb%mjy
   kz = xb%mkz

#ifdef DM_PARALLEL
 
   ! 3-d and 2-d increments:

   ALLOCATE ( psfc_g (1:ix,1:jy) )
   ALLOCATE (    u_g (1:ix,1:jy,1:kz) )
   ALLOCATE (    v_g (1:ix,1:jy,1:kz) )
   ALLOCATE (    t_g (1:ix,1:jy,1:kz) )
   ALLOCATE (    q_g (1:ix,1:jy,1:kz) )
   ALLOCATE (    p_g (1:ix,1:jy,1:kz) )

   call da_local_to_global( xp, xa % psfc, gbuf_2d, 2 ) 
   IF (rootproc) THEN 
      psfc_g(1:ix,1:jy) = gbuf_2d(1:ix,1:jy) 
   END IF 

   call da_local_to_global( xp, xa % u, gbuf, 3 ) 
   IF (rootproc) THEN 
      u_g(1:ix,1:jy,1:kz) = gbuf(1:ix,1:jy,1:kz) 
   END IF 

   call da_local_to_global( xp, xa % v, gbuf, 3 ) 
   IF (rootproc) THEN 
      v_g(1:ix,1:jy,1:kz) = gbuf(1:ix,1:jy,1:kz) 
   END IF 

   call da_local_to_global( xp, xa % t, gbuf, 3 ) 
   IF (rootproc) THEN 
      t_g(1:ix,1:jy,1:kz) = gbuf(1:ix,1:jy,1:kz) 
   END IF 

   call da_local_to_global( xp, xa % q, gbuf, 3 ) 
   IF (rootproc) THEN 
      q_g(1:ix,1:jy,1:kz) = gbuf(1:ix,1:jy,1:kz) 
   END IF 

   call da_local_to_global( xp, xa % p, gbuf, 3 ) 
   IF (rootproc) THEN 
      p_g(1:ix,1:jy,1:kz) = gbuf(1:ix,1:jy,1:kz) 
   END IF 
#endif

   IF (rootproc) then

#ifdef DM_PARALLEL

      ! 3d- and 2d-increments:

      call da_get_unit(anl_inc_unit)
      open(unit=anl_inc_unit,file="ANALYSIS_INCREMEMTS_KMA",status="new")

      write(anl_inc_unit) &
      ((psfc_g(i,j),i=xb%ids,xb%ide),j=xb%jds,xb%jde)
      write(anl_inc_unit) &
      (((u_g(i,j,k),i=xb%ids,xb%ide),j=xb%ids,xb%jde),k=xb%kds,xb%kde)
      write(anl_inc_unit) &
      (((v_g(i,j,k),i=xb%ids,xb%ide),j=xb%ids,xb%jde),k=xb%kds,xb%kde)
      write(anl_inc_unit) &
      (((t_g(i,j,k),i=xb%ids,xb%ide),j=xb%ids,xb%jde),k=xb%kds,xb%kde)
      write(anl_inc_unit) &
      (((q_g(i,j,k),i=xb%ids,xb%ide),j=xb%ids,xb%jde),k=xb%kds,xb%kde)
      write(anl_inc_unit) &
      (((p_g(i,j,k),i=xb%ids,xb%ide),j=xb%ids,xb%jde),k=xb%kds,xb%kde)

      write(UNIT=stdout,FMT='(10e15.7)') & 
         ((psfc_g(i,j),i=xb%ids,xb%ide),j=xb%jds,xb%jde)
      write(UNIT=stdout,FMT='(10e15.7)') &
         (((u_g(i,j,k),i=xb%ids,xb%ide),j=xb%ids,xb%jde),k=xb%kds,xb%kde)
      write(UNIT=stdout,FMT='(10e15.7)') &
         (((v_g(i,j,k),i=xb%ids,xb%ide),j=xb%ids,xb%jde),k=xb%kds,xb%kde)
      write(UNIT=stdout,FMT='(10e15.7)') &
         (((t_g(i,j,k),i=xb%ids,xb%ide),j=xb%ids,xb%jde),k=xb%kds,xb%kde)
      write(UNIT=stdout,FMT='(10e15.7)') &
         (((q_g(i,j,k),i=xb%ids,xb%ide),j=xb%ids,xb%jde),k=xb%kds,xb%kde)
      write(UNIT=stdout,FMT='(10e15.7)') &
         (((p_g(i,j,k),i=xb%ids,xb%ide),j=xb%ids,xb%jde),k=xb%kds,xb%kde)

#else

      ! 3d- and 2d-increments:

      write(anl_inc_unit) &
         ((xa%psfc(i,j),i=xb%ids,xb%ide),j=xb%jds,xb%jde)
      write(anl_inc_unit) &
         (((xa%u(i,j,k),i=xb%ids,xb%ide),j=xb%jds,xb%jde),k=xb%kds,xb%kde)
      write(anl_inc_unit) &
         (((xa%v(i,j,k),i=xb%ids,xb%ide),j=xb%jds,xb%jde),k=xb%kds,xb%kde)
      write(anl_inc_unit) &
         (((xa%t(i,j,k),i=xb%ids,xb%ide),j=xb%jds,xb%jde),k=xb%kds,xb%kde)
      write(anl_inc_unit) &
         (((xa%q(i,j,k),i=xb%ids,xb%ide),j=xb%jds,xb%jde),k=xb%kds,xb%kde)
      write(anl_inc_unit) &
         (((xa%p(i,j,k),i=xb%ids,xb%ide),j=xb%jds,xb%jde),k=xb%kds,xb%kde)

      write(UNIT=stdout,FMT='(10e15.7)') &
         ((xa%psfc(i,j),i=xb%ids,xb%ide),j=xb%jds,xb%jde)
      write(UNIT=stdout,FMT='(10e15.7)') &
         (((xa%u(i,j,k),i=xb%ids,xb%ide),j=xb%jds,xb%jde),k=xb%kds,xb%kde)
      write(UNIT=stdout,FMT='(10e15.7)') &
         (((xa%v(i,j,k),i=xb%ids,xb%ide),j=xb%jds,xb%jde),k=xb%kds,xb%kde)
      write(UNIT=stdout,FMT='(10e15.7)') &
         (((xa%t(i,j,k),i=xb%ids,xb%ide),j=xb%jds,xb%jde),k=xb%kds,xb%kde)
      write(UNIT=stdout,FMT='(10e15.7)') &
         (((xa%q(i,j,k),i=xb%ids,xb%ide),j=xb%jds,xb%jde),k=xb%kds,xb%kde)
      write(UNIT=stdout,FMT='(10e15.7)') &
         (((xa%p(i,j,k),i=xb%ids,xb%ide),j=xb%jds,xb%jde),k=xb%kds,xb%kde)
#endif
      close(anl_inc_unit)
      call da_free_unit(anl_inc_unit)

   end if

   IF (trace_use) call da_trace_exit("da_write_kma_increments")

end subroutine da_write_kma_increments 

