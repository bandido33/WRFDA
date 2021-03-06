subroutine da_check_max_iv_ships(iv, ob, it, num_qcstat_conv)

   !-----------------------------------------------------------------------
   ! Purpose: TBD
   !-----------------------------------------------------------------------

   implicit none

   type(iv_type), intent(inout) :: iv
   integer,       intent(in)    :: it      ! Outer iteration
   integer,       intent(inout) :: num_qcstat_conv(:,:,:,:)
   type(y_type),  intent(in)    :: ob      ! Observation structure.


   logical :: failed
   integer :: n

   if (trace_use_dull) call da_trace_entry("da_check_max_iv_ships")

   !---------------------------------------------------------------------------
   ! [1.0] Perform maximum innovation vector check:
   !---------------------------------------------------------------------------

   do n=iv%info(ships)%n1,iv%info(ships)%n2
    if( iv%info(ships)%proc_domain(1,n) ) then
     if( iv%ships(n)%u%qc == fails_error_max )iv%ships(n)%u%qc =0
      if( iv%ships(n)%u%qc >= obs_qc_pointer ) then
      call da_max_error_qc (it, iv%info(ships), n, iv%ships(n)%u, max_error_uv, failed)
      num_qcstat_conv(1,ships,1,1)= num_qcstat_conv(1,ships,1,1) + 1
      if(failed) then
      num_qcstat_conv(2,ships,1,1)= num_qcstat_conv(2,ships,1,1) + 1
      write(qcstat_conv_unit,'(2x,a10,2x,a4,3f12.2)')&
           'ships',ob_vars(1),iv%info(ships)%lat(1,n),iv%info(ships)%lon(1,n),0.01*ob%ships(n)%p
      end if
      end if

     if( iv%ships(n)%v%qc == fails_error_max )iv%ships(n)%v%qc =0
      if( iv%ships(n)%v%qc >= obs_qc_pointer ) then
      call da_max_error_qc (it, iv%info(ships), n, iv%ships(n)%v, max_error_uv, failed)             
      num_qcstat_conv(1,ships,2,1)= num_qcstat_conv(1,ships,2,1) + 1
      if(failed) then
      num_qcstat_conv(2,ships,2,1)= num_qcstat_conv(2,ships,2,1) + 1
      write(qcstat_conv_unit,'(2x,a10,2x,a4,3f12.2)')&
           'ships',ob_vars(2),iv%info(ships)%lat(1,n),iv%info(ships)%lon(1,n),0.01*ob%ships(n)%p
      end if
      end if

     if( iv%ships(n)%t%qc == fails_error_max )iv%ships(n)%t%qc =0
      if( iv%ships(n)%t%qc >= obs_qc_pointer ) then
      call da_max_error_qc (it, iv%info(ships), n, iv%ships(n)%t, max_error_t , failed)
      num_qcstat_conv(1,ships,3,1)= num_qcstat_conv(1,ships,3,1) + 1
      if(failed) then
      num_qcstat_conv(2,ships,3,1)= num_qcstat_conv(2,ships,3,1) + 1
      write(qcstat_conv_unit,'(2x,a10,2x,a4,3f12.2)')&
           'ships',ob_vars(3),iv%info(ships)%lat(1,n),iv%info(ships)%lon(1,n),0.01*ob%ships(n)%p
      end if
      end if

     if( iv%ships(n)%q%qc == fails_error_max )iv%ships(n)%q%qc =0
      if( iv%ships(n)%q%qc >= obs_qc_pointer ) then
      call da_max_error_qc (it, iv%info(ships), n, iv%ships(n)%q, max_error_q , failed)
      num_qcstat_conv(1,ships,4,1)= num_qcstat_conv(1,ships,4,1) + 1
      if(failed) then
      num_qcstat_conv(2,ships,4,1)= num_qcstat_conv(2,ships,4,1) + 1
      write(qcstat_conv_unit,'(2x,a10,2x,a4,3f12.2)')&
           'ships',ob_vars(4),iv%info(ships)%lat(1,n),iv%info(ships)%lon(1,n),0.01*ob%ships(n)%p
      end if
      end if

     if( iv%ships(n)%p%qc == fails_error_max )iv%ships(n)%p%qc =0
      if( iv%ships(n)%p%qc >= obs_qc_pointer ) then
      call da_max_error_qc (it, iv%info(ships), n, iv%ships(n)%p, max_error_p , failed)         
      num_qcstat_conv(1,ships,5,1)= num_qcstat_conv(1,ships,5,1) + 1
      if(failed) then
      num_qcstat_conv(2,ships,5,1)= num_qcstat_conv(2,ships,5,1) + 1
      write(qcstat_conv_unit,'(2x,a10,2x,a4,3f12.2)')&
           'ships',ob_vars(5),iv%info(ships)%lat(1,n),iv%info(ships)%lon(1,n),0.01*ob%ships(n)%p
      end if
      end if
    end if 
   end do

   if (trace_use_dull) call da_trace_exit("da_check_max_iv_ships")

end subroutine da_check_max_iv_ships
