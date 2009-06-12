subroutine bkgvar_rewgt(sfvar,vpvar,tvar,psvar,mype)
!$$$  subprogram documentation block
!                .      .    .                                       .
! subprogram:    bkgvar_rewgt   add flow dependence to variances
!   prgmmr: kleist           org: np22                date: 2007-07-03
!
! abstract: perform background error variance reweighting based on 
!           flow dependence
!
! program history log:
!   2007-07-03  kleist
!
!   input argument list:
!     sfvar     - stream function variance
!     vpvar     - unbalanced velocity potential variance
!     tvar      - unbalanced temperature variance
!     psvar     - unbalanced surface pressure variance
!     mype      - integer mpi task id
!
!   output argument list:
!     sfvar     - reweighted stream function variance
!     vpvar     - reweighted unbalanced velocity potential variance
!     tvar      - reweighted unbalanced temperature variance
!     psvar     - reweighted unbalanced surface pressure variance
!
! attributes:
!   language: f90
!   machine:  ibm RS/6000 SP
!
!$$$
  use kinds, only: r_kind,i_kind,r_quad
  use constants, only:  one,zero,two,three,half,quarter
  use gridmod, only: nlat,nlon,nsig,lat2,lon2
  use guess_grids, only: ges_div,ges_vor,ges_tv,ges_ps,nfldsig
  use mpimod, only: npe,mpi_comm_world,ierror,mpi_sum,mpi_rtype,mpi_max
  use balmod, only: agvz,wgvz,bvz
  use berror, only: bkgv_rewgtfct
  implicit none

! Declare passed variables
  real(r_kind),dimension(lat2,lon2,nsig),intent(inout):: sfvar,vpvar,tvar
  real(r_kind),dimension(lat2,lon2),intent(inout):: psvar
  integer(i_kind),intent(in):: mype

! Declare local variables
  real(r_kind),dimension(lat2,lon2,nsig):: psi1,chi1,psi2,chi2,bald,balt
  real(r_kind),dimension(lat2,lon2,nsig):: delpsi,delchi,deltv
  real(r_kind),dimension(lat2,lon2,nsig):: zresc,dresc,tresc
  real(r_kind),dimension(lat2,lon2):: delps,psresc,balps

  real(r_quad),dimension(nsig):: mean_dz,mean_dd,mean_dt
  real(r_quad) mean_dps,count

  real(r_kind),dimension(nsig,2,npe):: mean_dz0,mean_dd0,mean_dz1,mean_dd1,&
       mean_dt0,mean_dt1
  real(r_kind),dimension(2,npe):: mean_dps0,mean_dps1

  real(r_kind),dimension(nsig):: mean_dzout,mean_ddout,mean_dtout
  real(r_kind) mean_dpsout

  real(r_kind),dimension(nsig):: max_dz,max_dd,max_dt,max_dz0,max_dd0,&
       max_dt0
  real(r_kind) max_dps,max_dps0
  integer(i_kind) i,j,k,l,nsmth,mm1


! Initialize local arrays
  psi1=zero ; chi1=zero ; psi2=zero ; chi2=zero ; psresc=zero

  mean_dpsout=zero ; mean_dzout=zero ; mean_ddout=zero ; mean_dtout=zero
  mean_dps0=zero ; mean_dz0=zero ; mean_dd0=zero ; mean_dt0=zero
  mean_dps1=zero ; mean_dz1=zero ; mean_dd1=zero ; mean_dt1=zero

  max_dps=zero ; max_dps0=zero
  max_dz=zero ; max_dd=zero ; max_dt=zero ; max_dz0=zero
  max_dd0=zero ; max_dt0=zero
  balt=zero ; bald=zero ; balps=zero

! Set count to number of global grid points in quad precision
  count = float(nlat)*float(nlon)

! Set parameter for communication
  mm1=mype+1

! NOTES:
! This subroutine will only work if FGAT (more than one guess time level)
! is used.  For the current operational GDAS with a 6 hour time window, 
! the default is to use sigf09-sigf03 to compute the delta variables
!
! Because of the FGAT component and vorticity/divergence issues, this is
! currently set up for global only
!
! No reweighting of ozone, cloud water, moisture yet

  if (nfldsig.eq.1) then
    if (mype==0) then
      write(6,*)'BKGVAR_REWGT: Only one guess time level available'
      write(6,*)'BKGVAR_REWGT: Stopping flow dependence reweighting, using default variances'
    end if
    goto 300
  end if

! Get stream function and velocity potential from guess vorticity and divergence
  call getpsichi(ges_vor(1,1,1,1),ges_div(1,1,1,1),psi1,chi1)
  call getpsichi(ges_vor(1,1,1,nfldsig),ges_div(1,1,1,nfldsig),psi2,chi2)

! Get delta variables
  do k=1,nsig
    do j=1,lon2
      do i=1,lat2
        delpsi(i,j,k)=psi2(i,j,k)-psi1(i,j,k)
        delchi(i,j,k)=chi2(i,j,k)-chi1(i,j,k)
        deltv(i,j,k) =ges_tv(i,j,k,nfldsig)-ges_tv(i,j,k,1)
      end do
    end do
  end do
  do j=1,lon2
    do i=1,lat2
      delps(i,j) = ges_ps(i,j,nfldsig)-ges_ps(i,j,1)
    end do
  end do

! Balanced surface pressure and velocity potential from delta stream function
  do k=1,nsig
    do j=1,lon2
      do i=1,lat2
        balps(i,j)=balps(i,j)+wgvz(i,k)*delpsi(i,j,k)
        bald(i,j,k)=bvz(i,k)*delpsi(i,j,k)
      end do
    end do
  end do

! Balanced temperature from delta stream function
  do k=1,nsig
    do l=1,nsig
      do j=1,lon2
        do i=1,lat2
          balt(i,j,l)=balt(i,j,l)+agvz(i,l,k)*delpsi(i,j,k)
        end do
      end do
    end do
  end do

! Subtract off balanced parts
  do k=1,nsig
    do j=1,lon2
      do i=1,lat2
        deltv(i,j,k) = deltv(i,j,k) - balt(i,j,k)
        delchi(i,j,k) = delchi(i,j,k) - bald(i,j,k)
      end do
    end do
  end do
  do j=1,lon2
    do i=1,lat2
      delps(i,j) = delps(i,j) - balps(i,j)
    end do
  end do

! Convert to root mean square
  do k=1,nsig
    do j=1,lon2
      do i=1,lat2
        delpsi(i,j,k)=sqrt( delpsi(i,j,k)**two )
        delchi(i,j,k)=sqrt( delchi(i,j,k)**two )
        deltv(i,j,k)=sqrt( deltv(i,j,k)**two )
      end do
    end do
  end do
  do j=1,lon2
    do i=1,lat2
      delps(i,j)=sqrt( delps(i,j)**two )
    end do
  end do

 300 CONTINUE

! Smooth the delta fields before computing variance reweighting
  nsmth=8
  call smooth2d(delpsi,nsig,nsmth,mype)
  call smooth2d(delchi,nsig,nsmth,mype)
  call smooth2d(deltv,nsig,nsmth,mype)
  call smooth2d(delps,1,nsmth,mype)


! Get global maximum and mean of each of the delta fields; while accounting for
! reproducibility of this kind of calculation 
  mean_dz=0.0_r_quad ; mean_dd=0.0_r_quad ; mean_dt=0.0_r_quad
  mean_dps=0.0_r_quad

  do k=1,nsig
    do j=2,lon2-1
      do i=2,lat2-1
        mean_dz(k) = mean_dz(k) + delpsi(i,j,k)
        mean_dd(k) = mean_dd(k) + delchi(i,j,k)
        mean_dt(k) = mean_dt(k) + deltv(i,j,k)

        max_dz(k)=max(max_dz(k),delpsi(i,j,k))
        max_dd(k)=max(max_dd(k),delchi(i,j,k))
        max_dt(k)=max(max_dt(k),deltv(i,j,k))
      end do
    end do
  end do
  do j=2,lon2-1
    do i=2,lat2-1
      mean_dps = mean_dps + delps(i,j)
      max_dps = max(max_dps,delps(i,j))
    end do
  end do

! Break quadruple precision into two double precision arrays
  do k=1,nsig
    mean_dz0(k,1,mm1) = mean_dz(k)
    mean_dz0(k,2,mm1) = mean_dz(k) - mean_dz0(k,1,mm1)
    mean_dd0(k,1,mm1) = mean_dd(k)
    mean_dd0(k,2,mm1) = mean_dd(k) - mean_dd0(k,1,mm1)
    mean_dt0(k,1,mm1) = mean_dt(k)
    mean_dt0(k,2,mm1) = mean_dt(k) - mean_dt0(k,1,mm1)
  end do
  mean_dps0(1,mm1) = mean_dps
  mean_dps0(2,mm1) = mean_dps - mean_dps0(1,mm1)

! Get task specific max and mean to every task
  call mpi_allreduce(mean_dz0,mean_dz1,nsig*2*npe,mpi_rtype,mpi_sum,mpi_comm_world,ierror)
  call mpi_allreduce(mean_dd0,mean_dd1,nsig*2*npe,mpi_rtype,mpi_sum,mpi_comm_world,ierror)
  call mpi_allreduce(mean_dt0,mean_dt1,nsig*2*npe,mpi_rtype,mpi_sum,mpi_comm_world,ierror)
  call mpi_allreduce(mean_dps0,mean_dps1,2*npe,mpi_rtype,mpi_sum,mpi_comm_world,ierror)

  call mpi_allreduce(max_dz,max_dz0,nsig,mpi_rtype,mpi_max,mpi_comm_world,ierror)
  call mpi_allreduce(max_dd,max_dd0,nsig,mpi_rtype,mpi_max,mpi_comm_world,ierror)
  call mpi_allreduce(max_dt,max_dt0,nsig,mpi_rtype,mpi_max,mpi_comm_world,ierror)
  call mpi_allreduce(max_dps,max_dps0,1,mpi_rtype,mpi_max,mpi_comm_world,ierror)

! Reintegrate quad precision number and sum over all mpi tasks  
  mean_dz=0.0_r_quad ; mean_dd=0.0_r_quad ; mean_dt=0.0_r_quad
  mean_dps=0.0_r_quad
  do i=1,npe
    do k=1,nsig
      mean_dz(k) = mean_dz(k) + mean_dz1(k,1,i) + mean_dz1(k,2,i)
      mean_dd(k) = mean_dd(k) + mean_dd1(k,1,i) + mean_dd1(k,2,i)
      mean_dt(k) = mean_dt(k) + mean_dt1(k,1,i) + mean_dt1(k,2,i)
    end do
    mean_dps = mean_dps + mean_dps1(1,i) + mean_dps1(2,i)
  end do

! Divide by number of grid points to get the mean
  do k=1,nsig
    mean_dz(k)=mean_dz(k)/count
    mean_dd(k)=mean_dd(k)/count
    mean_dt(k)=mean_dt(k)/count
  end do
  mean_dps = mean_dps/count

! Load quad precision array back into double precision array for use
  do k=1,nsig
    mean_dzout(k)=mean_dz(k)
    mean_ddout(k)=mean_dd(k)
    mean_dtout(k)=mean_dt(k)
  end do
  mean_dpsout = mean_dps

! Get rescaling factor for each of the variables based on factor, mean, and max
  do k=1,nsig
    do j=1,lon2
      do i=1,lat2
        zresc(i,j,k) = one + bkgv_rewgtfct*(delpsi(i,j,k)-mean_dzout(k))/max_dz0(k)
        dresc(i,j,k) = one + bkgv_rewgtfct*(delchi(i,j,k)-mean_ddout(k))/max_dd0(k)
        tresc(i,j,k) = one + bkgv_rewgtfct*(deltv(i,j,k)-mean_dtout(k))/max_dt0(k)
      end do
    end do
  end do
  do j=1,lon2
    do i=1,lat2
      psresc(i,j)=one + bkgv_rewgtfct*(delps(i,j)-mean_dpsout)/max_dps0
    end do
  end do

! Multiply rescaling factor times the variances
  do k=1,nsig
    do j=1,lon2
      do i=1,lat2
        sfvar(i,j,k)=sfvar(i,j,k)*zresc(i,j,k)
        vpvar(i,j,k)=vpvar(i,j,k)*dresc(i,j,k)
        tvar(i,j,k)=tvar(i,j,k)*tresc(i,j,k)
      end do
    end do
  end do
  do j=1,lon2
    do i=1,lat2
      psvar(i,j)=psvar(i,j)*psresc(i,j)
    end do
  end do


! Smooth background error variances and write out grid
  nsmth=8
  call smooth2d(sfvar,nsig,nsmth,mype)
  call smooth2d(vpvar,nsig,nsmth,mype)
  call smooth2d(tvar,nsig,nsmth,mype)
  call smooth2d(psvar,1,nsmth,mype)

  call write_bkgvars_grid(sfvar,vpvar,tvar,psvar,mype)

  return
end subroutine bkgvar_rewgt


subroutine getpsichi(vor,div,psi,chi)
!$$$  subprogram documentation block
!                .      .    .                                       .
! subprogram:    getpsichi   compute psi and chi on subdomains
!   prgmmr: kleist           org: np22                date: 2007-07-03
!
! abstract: get stream function and velocity potential from vorticity
!           and divergence
!
! program history log:
!   2007-07-03  kleist
!
!   input argument list:
!     vor       - vorticity on subdomains
!     div       - divergence on subdomains
!
!   output argument list:
!     psi       - stream function on subdomains
!     chi       - velocity potential on subdomains
!
! attributes:
!   language: f90
!   machine:  ibm RS/6000 SP
!
!$$$
  use kinds, only: r_kind,i_kind
  use constants, only:  one,zero
  use gridmod, only: regional,lat2,nsig,iglobal,lon1,itotsub,lon2,lat1,&
       nlat,nlon,ltosi,ltosj,ltosi_s,ltosj_s
  use mpimod, only: iscuv_s,ierror,mpi_comm_world,irduv_s,ircuv_s,&
       isduv_s,isduv_g,iscuv_g,nuvlevs,irduv_g,ircuv_g,mpi_rtype,&
       strip,reorder,reorder2
  use specmod, only: ncd2,nc,enn1
  implicit none

! Declare passed variables
  real(r_kind),dimension(lat2,lon2,nsig),intent(in):: vor,div
  real(r_kind),dimension(lat2,lon2,nsig),intent(out):: psi,chi

! Declare local variables
  integer(i_kind) i,j,k,kk,ni1,ni2

  real(r_kind),dimension(lat1,lon1,nsig):: vorsm,divsm
  real(r_kind),dimension(itotsub,nuvlevs):: work1,work2
  real(r_kind),dimension(nlat,nlon):: work3,work4
  real(r_kind),dimension(nc):: spc1,spc2

  psi=zero ; chi=zero

! Zero out work arrays
  do k=1,nuvlevs
    do j=1,itotsub
      work1(j,k)=zero
      work2(j,k)=zero
    end do
  end do

! Strip off endpoints arrays on subdomains
  call strip(vor,vorsm,nsig)
  call strip(div,divsm,nsig)

  call mpi_alltoallv(vorsm(1,1,1),iscuv_g,isduv_g,&
       mpi_rtype,work1(1,1),ircuv_g,irduv_g,mpi_rtype,&
       mpi_comm_world,ierror)
  call mpi_alltoallv(divsm(1,1,1),iscuv_g,isduv_g,&
       mpi_rtype,work2(1,1),ircuv_g,irduv_g,mpi_rtype,&
       mpi_comm_world,ierror)

! Reorder work arrays
  call reorder(work1,nuvlevs)
  call reorder(work2,nuvlevs)

! Perform scalar g2s on work array
  do k=1,nuvlevs
    spc1=zero ; spc2=zero
    work3=zero ; work4=zero

    do kk=1,iglobal
      ni1=ltosi(kk); ni2=ltosj(kk)
      work3(ni1,ni2)=work1(kk,k)
      work4(ni1,ni2)=work2(kk,k)
    end do

    call g2s0(spc1,work3)
    call g2s0(spc2,work4)

! Inverse laplacian
    do i=2,ncd2
      spc1(2*i-1)=spc1(2*i-1)/(-enn1(i))
      spc1(2*i)=spc1(2*i)/(-enn1(i))
      spc2(2*i-1)=spc2(2*i-1)/(-enn1(i))
      spc2(2*i)=spc2(2*i)/(-enn1(i))
    end do

    work3=zero ; work4=zero
    call s2g0(spc1,work3)
    call s2g0(spc2,work4)

    do kk=1,itotsub
      ni1=ltosi_s(kk); ni2=ltosj_s(kk)
      work1(kk,k)=work3(ni1,ni2)
      work2(kk,k)=work4(ni1,ni2)
    end do
  end do  !end do nuvlevs

! Reorder the work array for the mpi communication
  call reorder2(work1,nuvlevs)
  call reorder2(work2,nuvlevs)

! Get psi/chi back on subdomains
  call mpi_alltoallv(work1(1,1),iscuv_s,isduv_s,&
       mpi_rtype,psi(1,1,1),ircuv_s,irduv_s,mpi_rtype,&
       mpi_comm_world,ierror)
  call mpi_alltoallv(work2(1,1),iscuv_s,isduv_s,&
       mpi_rtype,chi(1,1,1),ircuv_s,irduv_s,mpi_rtype,&
       mpi_comm_world,ierror)

  return
end subroutine getpsichi

subroutine smooth2d(subd,nlevs,nsmooth,mype)
!$$$  subprogram documentation block
!                .      .    .                                       .
! subprogram:    smooth2d    perform nine point smoother to interior
!   prgmmr: kleist           org: np22                date: 2007-07-03
!
! abstract: perform communication necessary, then apply simple nine
!           point smoother to interior of domain
!
! program history log:
!   2007-07-03  kleist
!
!   input argument list:
!     subd      - field to be smoothed on subdomains
!     nlevs     - number of levels to perform smoothing
!     nsmooth   - number of times to perform smoother
!     mype      - mpi integer task ik
!
!   output argument list:
!     subd      - smoothed field
!
! attributes:
!   language: f90
!   machine:  ibm RS/6000 SP
!
!$$$
  use gridmod,only: nlat,nlon,lat2,lon2
  use kinds,only: r_kind,i_kind
  implicit none

  integer(i_kind),intent(in):: nlevs,mype,nsmooth
  real(r_kind),intent(inout):: subd(lat2,lon2,nlevs)

  real(r_kind),dimension(nlat,nlon,nlevs):: grd
  real(r_kind),dimension(nlat,0:nlon+1,nlevs):: grd2
  real(r_kind) corn,cent,side,temp,c2,c3,c4
  integer i,j,k,n,workpe

  workpe=0

! Get subdomains on the grid
  call gather_stuff2(subd,grd,nlevs,mype,workpe)

! Set weights for nine point smoother
  corn=0.3_r_kind
  cent=1.0_r_kind
  side=0.5_r_kind
  c4=4.0_r_kind
  c3=3.0_r_kind
  c2=2.0_r_kind

  if (mype==workpe) then

! Do nsmooth number of passes over the 9pt smoother
    do n=1,nsmooth

! Load grd2 which is used in computing the smoothed fields
      do k=1,nlevs
        do j=1,nlon
          do i=1,nlat
            grd2(i,j,k)=grd(i,j,k)
          end do
        end do
      end do

! Load longitude wrapper rows
      do k=1,nlevs
        do i=1,nlat
          grd2(i,0,k)=grd(i,nlon,k)
          grd2(i,nlon+1,k)=grd(i,1,k)
        end do
      end do

! Perform smoother on interior (no special treatment for near-poles)
      do k=1,nlevs
         do j=1,nlon
           do i=2,nlat-1
             temp = cent*grd2(i,j,k) + side*(grd2(i+1,j,k) + &
                grd2(i-1,j,k) + grd2(i,j+1,k) + grd2(i,j-1,k)) + &
                corn*(grd2(i+1,j+1,k) + grd2(i+1,j-1,k) + grd2(i-1,j-1,k) + &
                grd2(i-1,j+1,k))
             grd(i,j,k) = temp/(cent + c4*side + c4*corn)
           end do
         end do
       end do  ! k levs
     end do    ! n smooth number of passes
   end if    ! mype

! Get back on subdomains
  call scatter_stuff2(grd,subd,nlevs,mype,workpe)

  return
end subroutine smooth2d

subroutine gather_stuff2(f,g,nvert,mype,outpe)
!$$$  subprogram documentation block
!                .      .    .                                       .
! subprogram:    gather_stuff2    gather subdomains onto global slabs
!   prgmmr: kleist           org: np22                date: 2007-07-03
!
! abstract: perform communication necessary to gather subdomains to 
!           global slabs
!
! program history log:
!   2007-07-03  kleist
!
!   input argument list:
!     f        - field on subdomains
!     nvert    - number of vertical levels
!     mype     - mpi integer task id
!     outpe    - task to output global slab onto
!
!   output argument list:
!     g        - global slab on task outpe
!
! attributes:
!   language: f90
!   machine:  ibm RS/6000 SP
!
!$$$
  use kinds, only: r_kind,i_kind
  use gridmod, only: iglobal,itotsub,nlat,nlon,lat1,lon1,lat2,lon2,ijn,displs_g,&
     ltosi,ltosj
  use mpimod, only: mpi_rtype,mpi_comm_world,ierror,strip,reorder
  implicit none
  integer(i_kind),intent(in):: nvert,mype,outpe
  real(r_kind),intent(in):: f(lat2,lon2,nvert)
  real(r_kind),intent(out):: g(nlat,nlon,nvert)
  real(r_kind) fsm(lat1,lon1)
  real(r_kind),allocatable:: tempa(:)
  integer(i_kind) i,ii,isize,j,k

  isize=max(iglobal,itotsub)
  allocate(tempa(isize))

! Strip off endpoints of input array on subdomains

  do k=1,nvert
    call strip(f(1,1,k),fsm,1)
    call mpi_gatherv(fsm,ijn(mype+1),mpi_rtype, &
                    tempa,ijn,displs_g,mpi_rtype,outpe,mpi_comm_world,ierror)
    call reorder(tempa,1)

    do ii=1,iglobal
      i=ltosi(ii)
      j=ltosj(ii)
      g(i,j,k)=tempa(ii)
    end do

  end do

  deallocate(tempa)

end subroutine gather_stuff2

subroutine scatter_stuff2(g,f,nvert,mype,inpe)
!$$$  subprogram documentation block
!                .      .    .                                       .
! subprogram:    scatter_stuff2    scatter global slabs to subdomains
!   prgmmr: kleist           org: np22                date: 2007-07-03
!
! abstract: perform communication necessary to scatter global slabs
!           onto the subdomains
!
! program history log:
!   2007-07-03  kleist
!
!   input argument list:
!     g        - field on global slabs
!     nvert    - number of vertical levels
!     mype     - mpi integer task id
!     inpe     - task which contains slab
!
!   output argument list:
!     f        - field on subdomains
!
! attributes:
!   language: f90
!   machine:  ibm RS/6000 SP
!
!$$$
  use kinds, only: r_kind,i_kind
  use gridmod, only: iglobal,itotsub,nlat,nlon,lat1,lon1,lat2,lon2,ijn_s,displs_s,&
     ltosi_s,ltosj_s
  use mpimod, only: mpi_rtype,mpi_comm_world,ierror,strip,reorder
  implicit none
  integer(i_kind),intent(in):: nvert,mype,inpe

  real(r_kind),intent(in):: g(nlat,nlon,nvert)
  real(r_kind),intent(out):: f(lat2,lon2,nvert)

  real(r_kind),allocatable:: tempa(:)
  integer(i_kind) i,ii,isize,j,k,mm1

  isize=max(iglobal,itotsub)
  allocate(tempa(isize))

  mm1=mype+1

  do k=1,nvert
    if (mype==0) then
      do ii=1,itotsub
        i=ltosi_s(ii) ; j=ltosj_s(ii)
        tempa(ii)=g(i,j,k)
      end do
    end if

    call mpi_scatterv(tempa,ijn_s,displs_s,mpi_rtype,&
         f(1,1,k),ijn_s(mm1),mpi_rtype,inpe,mpi_comm_world,ierror)
  end do

  return
end subroutine scatter_stuff2
