subroutine da_biascorr ( i, ob, iv)

   !---------------------------------------------------------------------------
   ! Purpose: perform bias correction for radiance data.
   !
   ! METHOD:  omb(corrected)=omb-scanbias-airbias
   !---------------------------------------------------------------------------

   implicit none

   integer,        intent(in)    :: i       ! sensor index.
   type (y_type),  intent(in)    :: ob      ! Observation structure.
   type (ob_type), intent(inout) :: iv      ! O-B structure.

   ! Local variables
   integer   :: k,iband,iscan, n1,n2,n,j,npred,nlevels
   real      :: q(43),pred(4),airbias

   if (trace_use) call da_trace_entry("da_biascorr")

   npred=4
   nlevels=iv%instid(i)%nlevels-1

   n1 = iv%ob_numb(iv%current_ob_time-1)%radiance(i)+1
   n2 = iv%ob_numb(iv%current_ob_time)%radiance(i)

   do n=n1,n2
      ! get airmass predictors
      !-------------------------
        if (rtm_option==rtm_option_rttov) then
         q(1:43) = iv%instid(i)%mr(1:43,n)/q2ppmv
         call da_predictor_rttov(pred(1:npred), npred, iv%instid(i)%t(1:43,n), &
            q(1:43), iv%instid(i)%ts(n))
        else if (rtm_option==rtm_option_crtm) then
         call da_predictor_crtm(pred(1:npred), npred, nlevels,iv%instid(i)%tm(1:nlevels,n), &
            iv%instid(i)%qm(1:nlevels,n), iv%instid(i)%ts(n), &
            iv%instid(i)%pm(1:nlevels,n),iv%instid(i)%pf(0:nlevels,n))
        end if
        iscan = iv%instid(i)%scanpos(n)
        iband = floor(iv%instid(i)%info(n)%lat/10.0001) + 10
      do k=1,iv%instid(i)%nchan
       ! scan bias correction
       !-----------------------
        if (global) then
          iv%instid(i)%tb_inv(k,n) = iv%instid(i)%tb_inv(k,n) - satinfo(i)%scanbias_b(k,iscan,iband)
        else
          iv%instid(i)%tb_inv(k,n) = iv%instid(i)%tb_inv(k,n) - satinfo(i)%scanbias(k,iscan) 
        end if
       ! airmass bias correction
       !----------------------------
          airbias = satinfo(i)%bcoef0(k)
         do j=1,npred
          airbias= airbias + satinfo(i)%bcoef(k,j)*pred(j)
         end do
          iv%instid(i)%tb_inv(k,n) = iv%instid(i)%tb_inv(k,n)-airbias
        !if (k==5) then
        !  write(*,'(6f15.5)') satinfo(i)%scanbias(k,iscan), satinfo(i)%bcoef(k,1:npred),satinfo(i)%bcoef0(k)
        !  write(*,'(5f15.5)') airbias,pred(1:npred)
        !end if
      end do
   end do

   if (trace_use) call da_trace_exit("da_biascorr")

end subroutine da_biascorr
