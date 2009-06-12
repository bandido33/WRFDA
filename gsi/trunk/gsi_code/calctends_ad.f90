subroutine calctends_ad(u,v,t,q,oz,cw,u_x,u_y,v_x,v_y,t_x,t_y,ps_x,ps_y,&
   q_x,q_y,oz_x,oz_y,cw_x,cw_y,mype,u_t,v_t,t_t,p_t,q_t,oz_t,cw_t,pri,tracer)
!$$$  subprogram documentation block
!                .      .    .                                       .
! subprogram:    calctends_ad         adjoint of calctends_tl
!   prgmmr: kleist           org: np20                date: 2005-09-29
!
! abstract: adjoint of routine that compute tendencies for u,v,Tv,prs
!
! program history log:
!   2005-09-29  kleist
!   2005-10-17  kleist - changes to improve computational efficiency
!   2005-11-21  kleist - add tracer tendencies, use new module
!   2006-01-31  kleist - add indices to sum* variables being initialized in loop
!   2006-04-12  treadon - replace sigi with bk5
!   2006-04-21  kleist - add divergence tendency bits
!   2006-07-31  kleist - changes to use ps instead of ln(ps)
!   2006-09-21  kleist - add rescaling to divergence tendency formulation
!   2007-03-13  kleist - move jcrescale_ad (and related code) into if (divtflg) block
!   2007-04-16  kleist - move constraint specific items elsewhere
!   2007-05-08  kleist - add bits for fully generalized vertical coordinate
!   2007-06-21  rancic - add pbl 
!   2007-07-26  cucurull - add 3d pressure pri in argument list;
!                          move getprs_ad outside calctends_ad;
!                          call getprs_horiz_ad; remove ps from argument
!                          list
!   2007-08-08  derber - optimize
!
! usage:
!   input argument list:
!     u        - zonal wind on subdomain
!     v        - meridional wind on subdomain
!     t        - virtual temperature on subdomain
!     q        - q on subdomain
!     oz       - ozone on subdomain
!     cw       - cloud water mixing ratio on subdomain
!     u_x      - zonal derivative of u
!     u_y      - meridional derivative of u
!     v_x      - zonal derivative of v
!     v_y      - meridional derivative of v
!     t_x      - zonal derivative of t
!     t_y      - meridional derivative of t
!     ps_x     - zonal derivative of ps
!     ps_y     - meridional derivative of ps
!     q_x      - zonal derivative of q
!     q_y      - meridional derivative of q
!     oz_x     - zonal derivative of ozone
!     oz_y     - meridional derivative of ozone
!     cw_x     - zonal derivative of cloud water
!     cw_y     - meridional derivative of cloud water
!     u_t      - time tendency of u
!     v_t      - time tendency of v
!     t_t      - time tendency of t
!     p_t      - time tendency of 3d prs
!     q_t      - time tendency of q
!     oz_t     - time tendency of ozone
!     cw_t     - time tendency of cloud water
!     mype     - mpi integer task id
!     tracer   - logical flag - if true tracer time derivatives calculated
!
!   output argument list:
!     u        - zonal wind on subdomain
!     v        - meridional wind on subdomain
!     t        - virtual temperature on subdomain
!     q        - q on subdomain
!     oz       - ozone on subdomain
!     cw       - cloud water mixing ratio on subdomain
!     u_x      - zonal derivative of u
!     u_y      - meridional derivative of u
!     v_x      - zonal derivative of v
!     v_y      - meridional derivative of v
!     t_x      - zonal derivative of t
!     t_y      - meridional derivative of t
!     ps_x     - zonal derivative of ps
!     ps_y     - meridional derivative of ps
!     q_x      - zonal derivative of q
!     q_y      - meridional derivative of q
!     oz_x     - zonal derivative of ozone
!     oz_y     - meridional derivative of ozone
!     cw_x     - zonal derivative of cloud water
!     cw_y     - meridional derivative of cloud water
!
!   notes:
!     adjoint check performed succesfully on 2005-09-29 by d. kleist
!
! attributes:
!   language: f90
!   machine:  ibm RS/6000 SP
!
!$$$
  use kinds,only: r_kind,i_kind
  use gridmod, only: lat2,lon2,nsig,istart,rlats,nlat,idvc5,bk5,&
      eta2_ll,wrf_nmm_regional,nsig1o,regional
  use constants, only: zero,half,one,two,rearth,rd,rcp,omega,grav
  use tendsmod, only: what9,prsth9,r_prsum9,prdif9,r_prdif9,pr_xsum9,pr_xdif9,&
      pr_ysum9,pr_ydif9,curvfct,coriolis
  use guess_grids, only: ntguessig,ges_u,&
      ges_u_lon,ges_u_lat,ges_v,ges_v_lon,ges_v_lat,ges_tv,ges_tvlat,ges_tvlon,&
      ges_q,ges_qlon,ges_qlat,ges_oz,ges_ozlon,ges_ozlat,ges_cwmr,ges_cwmr_lon,&
      ges_cwmr_lat,ges_teta,ges_prsi
  implicit none

! Declare passed variables
  real(r_kind),dimension(lat2,lon2,nsig),intent(inout):: u_t,v_t
  real(r_kind),dimension(lat2,lon2,nsig),intent(in):: t_t,q_t,oz_t,cw_t
  real(r_kind),dimension(lat2,lon2,nsig+1),intent(in):: p_t
  real(r_kind),dimension(lat2,lon2,nsig),intent(inout):: u,v,t,u_x,u_y,&
     v_x,v_y,t_x,t_y,q,oz,cw,q_x,q_y,oz_x,oz_y,cw_x,cw_y
  real(r_kind),dimension(lat2,lon2),intent(inout):: ps_x,ps_y
  real(r_kind),dimension(lat2,lon2,nsig+1),intent(inout):: pri
  integer(i_kind),intent(in):: mype
  logical,intent(in)::tracer

! Declare local variables
  real(r_kind),dimension(lat2,lon2,nsig+1):: pri_x,pri_y,prsth,what
  real(r_kind),dimension(lat2,lon2,nsig):: prsum,prdif,pr_xsum,pr_xdif,pr_ysum,&
       pr_ydif

  real(r_kind),dimension(lat2,lon2,nsig):: t_thor9
  real(r_kind),dimension(lat2,lon2):: sumkm1,sumvkm1,sum2km1,sum2vkm1
  real(r_kind) tmp,tmp2,tmp3,var,sumk,sumvk,sum2k,sum2vk
  integer(i_kind) i,j,k,ix,it,nnn

  it=ntguessig

! zero arrays
  do k=1,nsig+1
    do j=1,lon2
      do i=1,lat2
        what(i,j,k)=zero
        prsth(i,j,k)=zero
!       pri(i,j,k)=zero
      end do
    end do
  end do
  do k=1,nsig
    do j=1,lon2
      do i=1,lat2
        prsum(i,j,k)=zero
        prdif(i,j,k)=zero
        pr_xsum(i,j,k)=zero
        pr_xdif(i,j,k)=zero
        pr_ysum(i,j,k)=zero
        pr_ydif(i,j,k)=zero
      end do
    end do
  end do
  do j=1,lon2
    do i=1,lat2
      sumkm1(i,j)=zero
      sumvkm1(i,j)=zero
      sum2km1(i,j)=zero
      sum2vkm1(i,j)=zero
    end do
  end do

  if(tracer) then
    do k=nsig,1,-1
      do j=1,lon2
        do i=1,lat2
          if(k < nsig) then
            tmp2=half*what9(i,j,k+1)*r_prdif9(i,j,k)
            tmp = - q_t(i,j,k)*(ges_q(i,j,k,it)-ges_q(i,j,k+1,it)) - &
                    oz_t(i,j,k)*(ges_oz(i,j,k,it)-ges_oz(i,j,k+1,it)) - &
                    cw_t(i,j,k)*(ges_cwmr(i,j,k,it)-ges_cwmr(i,j,k+1,it))
                    q(i,j,k) = q(i,j,k) - q_t(i,j,k)*tmp2
                    q(i,j,k+1) = q(i,j,k+1) + q_t(i,j,k)*tmp2
                    oz(i,j,k) = oz(i,j,k) - oz_t(i,j,k)*tmp2
                    oz(i,j,k+1) = oz(i,j,k+1) + oz_t(i,j,k)*tmp2
                    cw(i,j,k) = cw(i,j,k) - cw_t(i,j,k)*tmp2
                  cw(i,j,k+1) = cw(i,j,k+1) + cw_t(i,j,k)*tmp2
            prdif(i,j,k) = prdif(i,j,k)+(tmp2*r_prdif9(i,j,k))* &
                (((ges_q(i,j,k,it)-ges_q(i,j,k+1,it))*q_t(i,j,k)) + &
                 ((ges_oz(i,j,k,it)-ges_oz(i,j,k+1,it))*oz_t(i,j,k)) + &
                 ((ges_cwmr(i,j,k,it)-ges_cwmr(i,j,k+1,it))*cw_t(i,j,k)) )
            what(i,j,k+1) = what(i,j,k+1)+half*tmp*r_prdif9(i,j,k)
          end if

          if(k > 1)then
            tmp2=half*what9(i,j,k)*r_prdif9(i,j,k)
            tmp= - q_t(i,j,k)*(ges_q(i,j,k-1,it)-ges_q(i,j,k,it)) - &
                   oz_t(i,j,k)*(ges_oz(i,j,k-1,it)-ges_oz(i,j,k,it)) - &
                   cw_t(i,j,k)*(ges_cwmr(i,j,k-1,it)-ges_cwmr(i,j,k,it))
                   q(i,j,k-1) = q(i,j,k-1) - q_t(i,j,k)*tmp2
                   q(i,j,k) = q(i,j,k) + q_t(i,j,k)*tmp2
                   oz(i,j,k-1) = oz(i,j,k-1) - oz_t(i,j,k)*tmp2
                   oz(i,j,k) = oz(i,j,k) + oz_t(i,j,k)*tmp2
                   cw(i,j,k-1) = cw(i,j,k-1) - cw_t(i,j,k)*tmp2
                   cw(i,j,k) = cw(i,j,k) + cw_t(i,j,k)*tmp2
  
            prdif(i,j,k) = prdif(i,j,k) + (tmp2*r_prdif9(i,j,k))* &
                (((ges_q(i,j,k-1,it)-ges_q(i,j,k,it))*q_t(i,j,k)) + &
                 ((ges_oz(i,j,k-1,it)-ges_oz(i,j,k,it))*oz_t(i,j,k)) + &
                 ((ges_cwmr(i,j,k-1,it)-ges_cwmr(i,j,k,it))*cw_t(i,j,k)) )
            what(i,j,k) = what(i,j,k)+half*tmp*r_prdif9(i,j,k)
          end if
! adjoint of tracer advective terms
          u(i,j,k) = u(i,j,k) - q_t(i,j,k)*ges_qlon(i,j,k,it) -  &
             oz_t(i,j,k)*ges_ozlon(i,j,k,it) - cw_t(i,j,k)*ges_cwmr_lon(i,j,k,it)
          v(i,j,k) = v(i,j,k) - q_t(i,j,k)*ges_qlat(i,j,k,it) -  &
             oz_t(i,j,k)*ges_ozlat(i,j,k,it) - cw_t(i,j,k)*ges_cwmr_lat(i,j,k,it)
          q_x(i,j,k) = q_x(i,j,k) - q_t(i,j,k)*ges_u(i,j,k,it)
          q_y(i,j,k) = q_y(i,j,k) - q_t(i,j,k)*ges_v(i,j,k,it)
          oz_x(i,j,k) = oz_x(i,j,k) - oz_t(i,j,k)*ges_u(i,j,k,it)
          oz_y(i,j,k) = oz_y(i,j,k) - oz_t(i,j,k)*ges_v(i,j,k,it)
          cw_x(i,j,k) = cw_x(i,j,k) - cw_t(i,j,k)*ges_u(i,j,k,it)
          cw_y(i,j,k) = cw_y(i,j,k) - cw_t(i,j,k)*ges_v(i,j,k,it)
        end do
      end do
    end do
  end if

! 5) adjoint of sum 2d individual terms into 3d tendency arrays
! because of sum arrays/dependencies, have to go from nsig --> 1

  if(.not.wrf_nmm_regional)then
    do k=1,nsig
      do j=1,lon2
        do i=1,lat2
          ix=istart(mype+1)+i-2
          if (ix == 1 .or. ix == nlat) then
            u_t(i,j,k)=zero ; v_t(i,j,k)=zero
          end if
        end do
      end do
    end do                         
  end if

  call turb_ad(ges_prsi(1,1,1,it),ges_tv  (1,1,1,it),&
                 ges_teta,u_t,v_t,t_t,t,u,v,pri,p_t)

  do k=nsig,1,-1               


! vertical summation terms for u,v
    do j=1,lon2
      do i=1,lat2
        sumk=sumkm1(i,j) - u_t(i,j,k)
        sumvk=sumvkm1(i,j) - v_t(i,j,k)
        sum2k=sum2km1(i,j) - rd*u_t(i,j,k) 
        sum2vk=sum2vkm1(i,j) - rd*v_t(i,j,k)

        sumkm1(i,j) = -u_t(i,j,k)
        sumvkm1(i,j) = -v_t(i,j,k)
        sum2km1(i,j) = -rd*u_t(i,j,k)
        sum2vkm1(i,j) = -rd*v_t(i,j,k)

! arrays tmp2 and tmp3 are from basic state variables
        tmp2=rd*ges_tv(i,j,k,it)*r_prsum9(i,j,k)
        tmp3=prdif9(i,j,k)*r_prsum9(i,j,k)
        t_y(i,j,k) = t_y(i,j,k) + sum2vk*tmp3
        var=sum2vk*r_prsum9(i,j,k)
        prdif(i,j,k) = prdif(i,j,k) + ges_tvlat(i,j,k,it)*var
        prsum(i,j,k) = prsum(i,j,k) - ges_tvlat(i,j,k,it)*tmp3*var
        sum2vkm1(i,j)=sum2vkm1(i,j)+sum2vk

        t_x(i,j,k) = t_x(i,j,k) + sum2k*tmp3
        var=sum2k*r_prsum9(i,j,k)
        prdif(i,j,k) = prdif(i,j,k) + ges_tvlon(i,j,k,it)*var
        prsum(i,j,k) = prsum(i,j,k) - ges_tvlon(i,j,k,it)*tmp3*var
        sum2km1(i,j)=sum2km1(i,j) + sum2k    

        pr_ydif(i,j,k) = pr_ydif(i,j,k) + tmp2*sumvk
        pr_ysum(i,j,k) = pr_ysum(i,j,k) - tmp2*tmp3*sumvk
        var=tmp2*sumvk*r_prsum9(i,j,k)
        prsum(i,j,k) = prsum(i,j,k) + tmp3*var*pr_ysum9(i,j,k)
        prdif(i,j,k) = prdif(i,j,k) - var*pr_ysum9(i,j,k)
! tmp is a reused variable
        tmp = sumvk*( pr_ydif9(i,j,k) - (pr_ysum9(i,j,k)*tmp3) )
        prsum(i,j,k) = prsum(i,j,k) - var* &
           ( pr_ydif9(i,j,k) - (pr_ysum9(i,j,k)*tmp3) )
        sumvkm1(i,j)= sumvkm1(i,j)+ sumvk

        pr_xdif(i,j,k) = pr_xdif(i,j,k) + tmp2*sumk
        pr_xsum(i,j,k) = pr_xsum(i,j,k) - tmp2*tmp3*sumk
        var=tmp2*sumk*r_prsum9(i,j,k)
        prsum(i,j,k) = prsum(i,j,k) + tmp3*var*pr_xsum9(i,j,k)
        prdif(i,j,k) = prdif(i,j,k) - var*pr_xsum9(i,j,k)
        tmp = tmp + sumk*( pr_xdif9(i,j,k) - &
           (pr_xsum9(i,j,k)*tmp3) )
        prsum(i,j,k) = prsum(i,j,k) - var* &
           ( pr_xdif9(i,j,k) - (pr_xsum9(i,j,k)*tmp3) )
        sumkm1(i,j)=sumkm1(i,j)+sumk

        t(i,j,k) = t(i,j,k) + rd*tmp*r_prsum9(i,j,k)
      end do
    end do

! adjoint of vertical flux terms
    do j=1,lon2
      do i=1,lat2
        if(k < nsig) then
          tmp2=half*what9(i,j,k+1)*r_prdif9(i,j,k)

          tmp = -u_t(i,j,k)*(ges_u(i,j,k,it)-ges_u(i,j,k+1,it)) - &
             v_t(i,j,k)*(ges_v(i,j,k,it)-ges_v(i,j,k+1,it)) - &
             t_t(i,j,k)*(ges_tv(i,j,k,it)-ges_tv(i,j,k+1,it))    

          t(i,j,k) = t(i,j,k) - t_t(i,j,k)*tmp2
          t(i,j,k+1) = t(i,j,k+1) + t_t(i,j,k)*tmp2
          u(i,j,k) = u(i,j,k) - u_t(i,j,k)*tmp2
          u(i,j,k+1) = u(i,j,k+1) + u_t(i,j,k)*tmp2
          v(i,j,k) = v(i,j,k) - v_t(i,j,k)*tmp2
          v(i,j,k+1) = v(i,j,k+1) + v_t(i,j,k)*tmp2
 
          prdif(i,j,k) = prdif(i,j,k) + (tmp2*r_prdif9(i,j,k))* &
            ( ((ges_tv(i,j,k,it)-ges_tv(i,j,k+1,it))*t_t(i,j,k)) + &
            ((ges_u(i,j,k,it)-ges_u(i,j,k+1,it))*u_t(i,j,k)) + &
            ((ges_v(i,j,k,it)-ges_v(i,j,k+1,it))*v_t(i,j,k)) )

          what(i,j,k+1) = what(i,j,k+1) + half*tmp*r_prdif9(i,j,k)
        end if
        if(k > 1) then
          tmp2=half*what9(i,j,k)*r_prdif9(i,j,k)

          tmp = - u_t(i,j,k)*(ges_u(i,j,k-1,it)-ges_u(i,j,k,it)) - &
             v_t(i,j,k)*(ges_v(i,j,k-1,it)-ges_v(i,j,k,it)) - &
             t_t(i,j,k)*(ges_tv(i,j,k-1,it)-ges_tv(i,j,k,it)) 

          t(i,j,k-1) = t(i,j,k-1) - t_t(i,j,k)*tmp2
          t(i,j,k) = t(i,j,k) + t_t(i,j,k)*tmp2
          u(i,j,k-1) =u(i,j,k-1) - u_t(i,j,k)*tmp2
          u(i,j,k) = u(i,j,k) + u_t(i,j,k)*tmp2
          v(i,j,k-1) = v(i,j,k-1) - v_t(i,j,k)*tmp2
          v(i,j,k) = v(i,j,k) + v_t(i,j,k)*tmp2

          prdif(i,j,k) = prdif(i,j,k) + (tmp2*r_prdif9(i,j,k))* &
            ( ((ges_tv(i,j,k-1,it)-ges_tv(i,j,k,it))*t_t(i,j,k)) + &
            ((ges_u(i,j,k-1,it)-ges_u(i,j,k,it))*u_t(i,j,k)) + &
            ((ges_v(i,j,k-1,it)-ges_v(i,j,k,it))*v_t(i,j,k)) )

          what(i,j,k) = what(i,j,k) + half*tmp*r_prdif9(i,j,k)
        end if

! Now finish up with adjoint of the rest of the terms
! tmp is now a basic state variable, whereas tmp2 is used in computation

        tmp=rd*ges_tv(i,j,k,it)*r_prsum9(i,j,k)

        pr_ysum(i,j,k) = pr_ysum(i,j,k) - tmp*v_t(i,j,k)
        prsum(i,j,k) = prsum(i,j,k) + tmp*v_t(i,j,k)*pr_ysum9(i,j,k)* &
           r_prsum9(i,j,k)

        tmp2 = - v_t(i,j,k)*pr_ysum9(i,j,k)

        pr_xsum(i,j,k) = pr_xsum(i,j,k) - tmp*u_t(i,j,k)
        prsum(i,j,k) = prsum(i,j,k) + tmp*u_t(i,j,k)*pr_xsum9(i,j,k)* &
           r_prsum9(i,j,k)
        tmp2 = tmp2 - u_t(i,j,k)*pr_xsum9(i,j,k)

        t(i,j,k) = t(i,j,k) + rd*tmp2*r_prsum9(i,j,k)


! load t_thor

        u(i,j,k) = u(i,j,k) - v_t(i,j,k)*(ges_v_lon(i,j,k,it) + two*curvfct(i,j)* &
           ges_u(i,j,k,it) + coriolis(i,j))
        v_x(i,j,k) = v_x(i,j,k) - v_t(i,j,k)*ges_u(i,j,k,it)
        v(i,j,k) = v(i,j,k) - v_t(i,j,k)*(ges_v_lat(i,j,k,it) + two*curvfct(i,j)* &
           ges_v(i,j,k,it))
        v_y(i,j,k) = v_y(i,j,k) - v_t(i,j,k)*ges_v(i,j,k,it)

        u(i,j,k) = u(i,j,k) - u_t(i,j,k)*ges_u_lon(i,j,k,it)
        u_x(i,j,k) = u_x(i,j,k) - u_t(i,j,k)*ges_u(i,j,k,it)
        v(i,j,k) = v(i,j,k) - u_t(i,j,k)*(ges_u_lat(i,j,k,it) - coriolis(i,j))
        u_y(i,j,k) = u_y(i,j,k) - u_t(i,j,k)*ges_v(i,j,k,it)

      end do  !end do i
    end do    !end do j
  end do      !end do k

! 3) adjoint of calculating full three-dimensional dp/dt
  do k=1,nsig+1
    do j=1,lon2
      do i=1,lat2
        prsth(i,j,k)=prsth(i,j,k) + p_t(i,j,k)
        what(i,j,k)=what(i,j,k) - p_t(i,j,k)
      end do
    end do
  end do

! 2) adjoint of calculation of vertical velocity
  if ( (.not.regional) .AND. (idvc5.eq.3)) then
!   Basic state horizontal temperature tendency
!   1.1) Get horizontal part of temperature tendency for vertical velocity term
    do k=1,nsig
      do j=1,lon2
        do i=1,lat2
          tmp=-rd*ges_tv(i,j,k,it)*r_prsum9(i,j,k)
          t_thor9(i,j,k)=-ges_u(i,j,k,it)*ges_tvlon(i,j,k,it) - &
               ges_v(i,j,k,it)*ges_tvlat(i,j,k,it)
          t_thor9(i,j,k)=t_thor9(i,j,k) -tmp*rcp * ( ges_u(i,j,k,it)*pr_xsum9(i,j,k) + &
             ges_v(i,j,k,it)*pr_ysum9(i,j,k) + &
             prsth9(i,j,k) + prsth9(i,j,k+1) )
        end do
      end do
    end do
    call getvvel_ad(t,t_t,t_thor9,prsth,prdif,what)
  else
    do k=2,nsig
      do j=1,lon2
        do i=1,lat2
          if (wrf_nmm_regional) then
            prsth(i,j,1) = prsth(i,j,1)-eta2_ll(k)*what(i,j,k)
            prsth(i,j,k) = prsth(i,j,k) + what(i,j,k)
          else
            prsth(i,j,1) = prsth(i,j,1)-bk5(k)*what(i,j,k)
            prsth(i,j,k) = prsth(i,j,k) + what(i,j,k)
          end if
        end do
      end do
    end do 
  end if

! 1.1) Horizontal Part of temperature tendency, now that adjoint of
!      vertical velocity is done
  do k=1,nsig
    do j=1,lon2
      do i=1,lat2
        tmp=rd*ges_tv(i,j,k,it)*r_prsum9(i,j,k)

        tmp2 = t_t(i,j,k)*rcp*( ges_u(i,j,k,it)* &
           pr_xsum9(i,j,k) + &
           ges_v(i,j,k,it)*pr_ysum9(i,j,k) + &
           prsth9(i,j,k)+prsth9(i,j,k+1) )
        prsum(i,j,k) = prsum(i,j,k) - tmp2*tmp*r_prsum9(i,j,k)

        var=t_t(i,j,k)*tmp*rcp
        pr_xsum(i,j,k) = pr_xsum(i,j,k) + var*ges_u(i,j,k,it)
        pr_ysum(i,j,k) = pr_ysum(i,j,k) + var*ges_v(i,j,k,it)
        u(i,j,k) = u(i,j,k) + var*pr_xsum9(i,j,k)
        v(i,j,k) = v(i,j,k) + var*pr_ysum9(i,j,k)
        prsth(i,j,k) = prsth(i,j,k) + var
        prsth(i,j,k+1) = prsth(i,j,k+1) + var
        
        t(i,j,k) = t(i,j,k) + rd*tmp2*r_prsum9(i,j,k)

        u(i,j,k) = u(i,j,k) - t_t(i,j,k)*ges_tvlon(i,j,k,it)
        t_x(i,j,k) = t_x(i,j,k) - t_t(i,j,k)*ges_u(i,j,k,it)
        v(i,j,k) = v(i,j,k) - t_t(i,j,k)*ges_tvlat(i,j,k,it)
        t_y(i,j,k) = t_y(i,j,k) - t_t(i,j,k)*ges_v(i,j,k,it)
      end do
    end do
  end do

! 1) adjoint of horizontal portion of pressure tendency
  do k=1,nsig
    do j=1,lon2
      do i=1,lat2
        u(i,j,k) = u(i,j,k) - prsth(i,j,k)*pr_xdif9(i,j,k)
        pr_xdif(i,j,k) = pr_xdif(i,j,k) - prsth(i,j,k)*ges_u(i,j,k,it)
        v(i,j,k) = v(i,j,k) - prsth(i,j,k)*pr_ydif9(i,j,k)
        pr_ydif(i,j,k) = pr_ydif(i,j,k) - prsth(i,j,k)*ges_v(i,j,k,it)
        u_x(i,j,k) = u_x(i,j,k) - prsth(i,j,k)*(prdif9(i,j,k))
        v_y(i,j,k) = v_y(i,j,k) - prsth(i,j,k)*(prdif9(i,j,k))
        prdif(i,j,k) = prdif(i,j,k) - prsth(i,j,k)*(ges_u_lon(i,j,k,it) + &
           ges_v_lat(i,j,k,it))
        prsth(i,j,k+1) = prsth(i,j,k+1) + prsth(i,j,k)
      end do
    end do
  end do

! adjoint of pressure preliminaries
  pri_x=zero
  pri_y=zero
  do k=1,nsig
    do j=1,lon2
      do i=1,lat2
        pri(i,j,k)=pri(i,j,k) + (prsum(i,j,k)+prdif(i,j,k))
        pri(i,j,k+1)=pri(i,j,k+1) + (prsum(i,j,k)-prdif(i,j,k))
        pri_x(i,j,k)=pri_x(i,j,k) + (pr_xsum(i,j,k)+pr_xdif(i,j,k))
        pri_x(i,j,k+1)=pri_x(i,j,k+1) + (pr_xsum(i,j,k)-pr_xdif(i,j,k))
        pri_y(i,j,k)=pri_y(i,j,k) + (pr_ysum(i,j,k)+pr_ydif(i,j,k))
        pri_y(i,j,k+1)=pri_y(i,j,k+1) + (pr_ysum(i,j,k)-pr_ydif(i,j,k))
      end do
    end do
  end do

  call getprs_horiz_ad(ps_x,ps_y,mype,pri,pri_x,pri_y)

  return
end subroutine calctends_ad
