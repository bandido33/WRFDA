subroutine getvvel(t,t_thor,prsth,prdif,what)
!$$$  subprogram documentation block
!                .      .    .                                       .
! subprogram:    get_vvel       compute vertical velocity
!   prgmmr: kleist           org: np20                date: 2007-05-08
!
! abstract: get model level vertical velocity for generalized coordinate
!
! program history log:
!   2007-05-08  kleist
!
! usage:
!   input argument list:
!     t        - temperature
!     t_thor   - horizontal component to temperature tendency (advection)
!     prsth    - horizontal component to pressure tendency (advection)
!     prdif    - delta pressure
!
!   output argument list:
!     what     - model level vertical velocity
!
!   notes:
!     see NCEP Office Note 445 (Juang 2005)
!
! attributes:
!   language: f90
!   machine:  ibm RS/6000 SP
!
!$$$
  use kinds,only: r_kind,i_kind
  use constants, only: zero,one,two,rd,cp,half
  use gridmod, only: lat2,lon2,nsig,ak5,bk5,ck5,tref5
  use tendsmod, only: adiag9,bdiag9,cdiag9,factk9,wint9,wint9_f,&
       r_bdiag9
  implicit none

! Declare passed variables:
  real(r_kind),dimension(lat2,lon2,nsig),intent(in):: t,t_thor,prdif
  real(r_kind),dimension(lat2,lon2,nsig+1),intent(in):: prsth
  real(r_kind),dimension(lat2,lon2,nsig+1),intent(out):: what

! Declare local variables:
  real(r_kind),dimension(lat2,lon2,nsig):: r_prdif,tsum,t_tsum,tdiff
  real(r_kind) kapr
  integer(i_kind):: i,j,k

! IN:
! t: temperature
! t_t: horizontal part of temperature tendency
! prsth: horizontal part of pressure tendency
! prdif: P(k)-P(k+1)

! OUT:
! what: model level vertical velocity

! ***NOTES*** on vertical velocity for general coordinates
!  general formula for pressure  (on 445, eq 7.1)
!    p(i,j,k)  = ak5(k) + bk5(k)*psfc(i,j)+ck5(k)*(t(i,j,k)/tref5(k))**(cp/rd)

!  following taken from on445, eq 7.8a

!  solve  adiag(k)*w(k-1) + bdiag(k)*w(k) + cdiag(k)*w(k+1) = rhs(k)
!
!  factor = (ck5(k)/(t(i,j,k-1)+t(i,j,k))) * (cp/(2*rd)) *  &
!                ( (t(i,j,k-1)+t(i,j,k))/(tref(k-1)+tref(k)) )**(cp/rd)
!  Multiplies w(k-1) :
!     adiag(k)=factor*(t(i,j,k-2)-t(i,j,k-1))*r_prdif9(i,j,k-1)
!  Multiplies w(k) :
!     bdiag(k)=factor*(t(i,j,k-1)-t(i,j,k))*(r_prdif9(i,j,k-1)+r_prdif9(i,j,k)) - one
!  Multiplies w(k+1) :
!     cdiag(k)=factor*(t(i,j,k)-t(i,j,k+1))*r_prdif9(i,j,k)
!  Right hand forcing:
!     rhs(k)=bk5*prsth9(i,j,1)-prsth9(i,j,k)+2*factor*(t_t(i,j,k-1)+t_t(i,j,k))
!
!  to solve above tridiagonal matrix, do following:
!  **** do forward elimination in a loop from k=2 to nsig,
!       do k=3,nsig
!         rhs(k)=rhs(k)-adiag(k)*rhs(k-1)/bdiag(k-1)
!         bdiag(k)=bdiag(k)-adiag(k)*cdiag(k-1)/bdiag(k-1)
!       end do
!
!  **** then backward substitution in loop from k=nsig to k=2.
!       w(nsig)=rhs(nsig)/bdiag(nsig)
!       do k=nsig-1,2,-1
!         w(k)=(rhs(k)-cdiag(k)*w(k+1))/bdiag(k)
!       end do
!


  kapr=cp/rd
  what=zero ; adiag9=zero ; bdiag9=zero ; cdiag9=zero ; factk9=zero
  wint9=zero ; wint9_f=zero ; r_bdiag9=zero

  do k=1,nsig-1
    do j=1,lon2
      do i=1,lat2
        tsum(i,j,k)=t(i,j,k)+t(i,j,k+1)
        t_tsum(i,j,k)=t_thor(i,j,k)+t_thor(i,j,k+1)
        tdiff(i,j,k)=t(i,j,k)-t(i,j,k+1)
      end do
    end do
  end do
  do k=1,nsig
    do j=1,lon2
      do i=1,lat2
        r_prdif(i,j,k)=one/prdif(i,j,k)
      end do
    end do
  end do

!    forward elimination:
  k=2
  do j=1,lon2
    do i=1,lat2
      factk9(i,j,k) = ck5(k)*half*kapr/tsum(i,j,k-1) * &
                      ( half*tsum(i,j,k-1)/tref5(k-1) )**kapr
      bdiag9(i,j,k)=factk9(i,j,k)*tdiff(i,j,k-1)*(r_prdif(i,j,k-1) + &
           r_prdif(i,j,k)) - one
      cdiag9(i,j,k)=factk9(i,j,k)*tdiff(i,j,k)*r_prdif(i,j,k)
      wint9(i,j,k)=bk5(k)*prsth(i,j,1)-prsth(i,j,k)+two*factk9(i,j,k)*t_tsum(i,j,k-1)

      wint9_f(i,j,k)=wint9(i,j,k)
      r_bdiag9(i,j,k)=one/bdiag9(i,j,k)
    end do
  end do

  do k=3,nsig
    do j=1,lon2
      do i=1,lat2
        factk9(i,j,k) = ck5(k)*half*kapr/tsum(i,j,k-1) * &
                            ( half*tsum(i,j,k-1)/tref5(k-1) )**kapr

        adiag9(i,j,k)=factk9(i,j,k)*tdiff(i,j,k-2)*r_prdif(i,j,k-1)
        bdiag9(i,j,k)=factk9(i,j,k)*tdiff(i,j,k-1)*(r_prdif(i,j,k-1)+ &
             r_prdif(i,j,k)) - one
        cdiag9(i,j,k)=factk9(i,j,k)*tdiff(i,j,k)*r_prdif(i,j,k)

        wint9(i,j,k)=bk5(k)*prsth(i,j,1)-prsth(i,j,k)+two*factk9(i,j,k)*t_tsum(i,j,k-1)
        wint9(i,j,k)=wint9(i,j,k)-adiag9(i,j,k)*wint9(i,j,k-1)*r_bdiag9(i,j,k-1)
        bdiag9(i,j,k)=bdiag9(i,j,k)-adiag9(i,j,k)*cdiag9(i,j,k-1)*r_bdiag9(i,j,k-1)

        wint9_f(i,j,k)=wint9(i,j,k)
        r_bdiag9(i,j,k)=one/bdiag9(i,j,k)
      end do
    end do
  end do

!    back substitution
  k=nsig
  do j=1,lon2
    do i=1,lat2
      wint9(i,j,k)=wint9(i,j,k)*r_bdiag9(i,j,k)
    end do
  end do
  do k=nsig-1,2,-1
    do j=1,lon2
      do i=1,lat2
        wint9(i,j,k)=(wint9(i,j,k)-cdiag9(i,j,k)*wint9(i,j,k+1))*r_bdiag9(i,j,k)
      end do
    end do
  end do

  do k=1,nsig+1
    do j=1,lon2
      do i=1,lat2
        what(i,j,k)=wint9(i,j,k)
      end do
    end do
  end do

  return
end subroutine getvvel


subroutine getvvel_tl(t,t_thor,t_thor9,prsth,prdif,what)
!$$$  subprogram documentation block
!                .      .    .                                       .
! subprogram:    get_vvel_tl       tlm of getvvel
!   prgmmr: kleist           org: np20                date: 2007-05-08
!
! abstract: tangent linear calculation of vertical velocity
!
! program history log:
!   2007-05-08  kleist
!
! usage:
!   input argument list:
!     t        - temperature
!     t_thor   - horizontal component to temperature tendency (advection)
!     t_thor9  - basic state horizontal component to temperature tendency (advection)
!     prsth    - horizontal component to pressure tendency (advection)
!     prdif    - delta pressure
!
!   output argument list:
!     what     - perturbation model level vertical velocity
!
!   notes:
!     see NCEP Office Note 445 (Juang 2005)
!
! attributes:
!   language: f90
!   machine:  ibm RS/6000 SP
!
!$$$
  use kinds,only: r_kind,i_kind
  use constants, only: zero,one,two,rd,cp,half
  use gridmod, only: lat2,lon2,nsig,ak5,bk5,ck5,tref5
  use guess_grids, only: ges_tv,ges_tv_ten,ntguessig
  use tendsmod, only: prdif9,r_prdif9,prsth9,adiag9,bdiag9,cdiag9,factk9,&
       r_bdiag9,wint9,wint9_f
  implicit none

! Declare passed variables:
  real(r_kind),dimension(lat2,lon2,nsig),intent(in):: t,t_thor,t_thor9,prdif
  real(r_kind),dimension(lat2,lon2,nsig+1),intent(in):: prsth
  real(r_kind),dimension(lat2,lon2,nsig+1),intent(out):: what

! Declare local variables:
  real(r_kind),dimension(lat2,lon2,nsig):: tsum,t_tsum,tdiff,factk
  real(r_kind),dimension(lat2,lon2,nsig):: tsum9,t_tsum9,tdiff9
  real(r_kind),dimension(lat2,lon2,nsig):: adiag,bdiag,cdiag
  real(r_kind) kapr,kaprm1,terma,termb
  real(r_kind) c1,c2,fprime
  integer(i_kind):: i,j,k,it

! Constants/Parameters:
  kapr=cp/rd
  kaprm1=kapr-one
  it=ntguessig

  what=zero ; factk=zero ; adiag=zero ; bdiag=zero ; cdiag=zero

! 
  do k=1,nsig-1
    do j=1,lon2
      do i=1,lat2
        tsum(i,j,k)=t(i,j,k)+t(i,j,k+1)
        t_tsum(i,j,k)=t_thor(i,j,k)+t_thor(i,j,k+1)
        tdiff(i,j,k)=t(i,j,k)-t(i,j,k+1)
        tsum9(i,j,k)=ges_tv(i,j,k,it)+ges_tv(i,j,k+1,it)
        tdiff9(i,j,k)=ges_tv(i,j,k,it)-ges_tv(i,j,k+1,it)
        t_tsum9(i,j,k)=t_thor9(i,j,k)+t_thor9(i,j,k+1)
      end do
    end do
  end do

!    forward elimination:
  k=2
  do j=1,lon2
    do i=1,lat2
      c1=ck5(k)*half*kapr
      c2=half/tref5(k-1)

      fprime=kapr*c2*tsum(i,j,k-1)*((c2*tsum9(i,j,k-1))**kaprm1)
      factk(i,j,k) = c1* ( (tsum9(i,j,k-1)*fprime) - (tsum(i,j,k-1)* &
                  ((c2*tsum9(i,j,k-1))**kapr)) ) / (tsum9(i,j,k-1)**two) 

      terma = ( prdif9(i,j,k-1)*(factk(i,j,k)*tdiff9(i,j,k-1) + tdiff(i,j,k-1)* &
           factk9(i,j,k)) - (factk9(i,j,k)*tdiff9(i,j,k-1)*prdif(i,j,k-1)) ) * &
           (r_prdif9(i,j,k-1)**two)
      termb= ( prdif9(i,j,k)*(factk(i,j,k)*tdiff9(i,j,k-1) + tdiff(i,j,k-1)* &
           factk9(i,j,k)) - (factk9(i,j,k)*tdiff9(i,j,k-1)*prdif(i,j,k)) ) * &
           (r_prdif9(i,j,k)**two)
      bdiag(i,j,k) = terma+termb

      cdiag(i,j,k) = ( prdif9(i,j,k)*(factk(i,j,k)*tdiff9(i,j,k) + &
           tdiff(i,j,k)*factk9(i,j,k)) - factk9(i,j,k)*tdiff9(i,j,k)* &
           prdif(i,j,k) ) * (r_prdif9(i,j,k)**two)

      what(i,j,k)=bk5(k)*prsth(i,j,1)-prsth(i,j,k) + two* &
           (factk9(i,j,k)*t_tsum(i,j,k-1) + factk(i,j,k)*t_tsum9(i,j,k-1))
   end do
  end do

  do k=3,nsig
    do j=1,lon2
      do i=1,lat2
        c1=ck5(k)*half*kapr
        c2=half/tref5(k-1)

        fprime=kapr*c2*tsum(i,j,k-1)*((c2*tsum9(i,j,k-1))**kaprm1)
        factk(i,j,k) = c1* ( (tsum9(i,j,k-1)*fprime) - (tsum(i,j,k-1)* &
                    ((c2*tsum9(i,j,k-1))**kapr)) ) / (tsum9(i,j,k-1)**two)

        adiag(i,j,k) = ( prdif9(i,j,k-1)*(factk(i,j,k)*tdiff9(i,j,k-2) + &
             tdiff(i,j,k-2)*factk9(i,j,k)) - factk9(i,j,k)*tdiff9(i,j,k-2)* &
             prdif(i,j,k-1) ) * (r_prdif9(i,j,k-1)**two)

        terma = ( prdif9(i,j,k-1)*(factk(i,j,k)*tdiff9(i,j,k-1) + &
             tdiff(i,j,k-1)*factk9(i,j,k)) - factk9(i,j,k)*tdiff9(i,j,k-1)* &
             prdif(i,j,k-1) ) * (r_prdif9(i,j,k-1)**two)
        termb = ( prdif9(i,j,k)*(factk(i,j,k)*tdiff9(i,j,k-1) + &
             tdiff(i,j,k-1)*factk9(i,j,k)) - factk9(i,j,k)*tdiff9(i,j,k-1)* &
             prdif(i,j,k) ) * (r_prdif9(i,j,k)**two)
        bdiag(i,j,k) = terma+termb

        cdiag(i,j,k) = ( prdif9(i,j,k)*(factk(i,j,k)*tdiff9(i,j,k) + &
             tdiff(i,j,k)*factk9(i,j,k)) - factk9(i,j,k)*tdiff9(i,j,k)* &
             prdif(i,j,k) ) * (r_prdif9(i,j,k)**two)

        what(i,j,k)=bk5(k)*prsth(i,j,1)-prsth(i,j,k) + two* &
             (factk9(i,j,k)*t_tsum(i,j,k-1) + factk(i,j,k)*t_tsum9(i,j,k-1))

        what(i,j,k) = what(i,j,k) - ( (bdiag9(i,j,k-1)*(adiag(i,j,k)*wint9_f(i,j,k-1) + &
              what(i,j,k-1)*adiag9(i,j,k)) - adiag9(i,j,k)*wint9_f(i,j,k-1)* &
              bdiag(i,j,k-1)) * (r_bdiag9(i,j,k-1)**two) )

        bdiag(i,j,k)=bdiag(i,j,k) - ( (bdiag9(i,j,k-1)*(adiag(i,j,k)*cdiag9(i,j,k-1) + &
              cdiag(i,j,k-1)*adiag9(i,j,k)) - adiag9(i,j,k)*cdiag9(i,j,k-1)* &
              bdiag(i,j,k-1)) * (r_bdiag9(i,j,k-1)**two) )
      end do
    end do
  end do

!    back substitution
  k=nsig
  do j=1,lon2
    do i=1,lat2
       what(i,j,k) = (bdiag9(i,j,k)*what(i,j,k) - wint9_f(i,j,k)*bdiag(i,j,k)) * &
           (r_bdiag9(i,j,k)**two)
    end do
  end do

  do k=nsig-1,2,-1
    do j=1,lon2
      do i=1,lat2
         what(i,j,k) = ( bdiag9(i,j,k)*(what(i,j,k)-(cdiag9(i,j,k)*what(i,j,k+1) + &
             cdiag(i,j,k)*wint9(i,j,k+1)) ) - bdiag(i,j,k)*(wint9_f(i,j,k)- &
             cdiag9(i,j,k)*wint9(i,j,k+1)) ) * (r_bdiag9(i,j,k)**two)
      end do
    end do
  end do

  return 
end subroutine getvvel_tl

subroutine getvvel_ad(t,t_thor,t_thor9,prsth,prdif,whatin)
!$$$  subprogram documentation block
!                .      .    .                                       .
! subprogram:    get_vvel_ad       adjoint of getvvel
!   prgmmr: kleist           org: np20                date: 2007-05-08
!
! abstract: adjoint of calculation of vertical velocity
!
! program history log:
!   2007-05-08  kleist
!
! usage:
!   input argument list:
!     t        - temperature
!     t_thor   - horizontal component to temperature tendency (advection)
!     t_thor9  - basic state horizontal component to temperature tendency (advection)
!     prsth    - horizontal component to pressure tendency (advection)
!     prdif    - delta pressure
!     what     - model level vertical velocity
!
!   output argument list:
!     t        - temperature
!     t_thor   - horizontal component to temperature tendency (advection)
!     prsth    - horizontal component to pressure tendency (advection)
!     prdif    - delta pressure
!
!   notes:
!     see NCEP Office Note 445 (Juang 2005)
!
! attributes:
!   language: f90
!   machine:  ibm RS/6000 SP
!
!$$$
  use kinds,only: r_kind,i_kind
  use constants, only: zero,one,two,rd,cp,half
  use gridmod, only: lat2,lon2,nsig,ak5,bk5,ck5,tref5
  use guess_grids, only: ges_tv,ges_tv_ten,ntguessig
  use tendsmod, only: prdif9,r_prdif9,prsth9,adiag9,bdiag9,cdiag9,factk9,&
       r_bdiag9,wint9,wint9_f
  implicit none

! Declare passed variables:
  real(r_kind),dimension(lat2,lon2,nsig+1),intent(in):: whatin
  real(r_kind),dimension(lat2,lon2,nsig),intent(in):: t_thor9
  real(r_kind),dimension(lat2,lon2,nsig),intent(inout):: t,t_thor,prdif
  real(r_kind),dimension(lat2,lon2,nsig+1),intent(inout):: prsth

! Declare local variables:
  real(r_kind),dimension(lat2,lon2,nsig+1):: what
  real(r_kind),dimension(lat2,lon2,nsig):: tsum,t_tsum,tdiff,factk
  real(r_kind),dimension(lat2,lon2,nsig):: tsum9,t_tsum9,tdiff9
  real(r_kind),dimension(lat2,lon2,nsig):: adiag,bdiag,cdiag
  real(r_kind) kapr,kaprm1,terma,termb
  real(r_kind) c1,c2,fprime,tmp1,tmp2
  integer(i_kind):: i,j,k,it

! Constants/Parameters:
  kapr=cp/rd
  kaprm1=kapr-one
  it=ntguessig

  factk=zero ; adiag=zero ; bdiag=zero ; cdiag=zero
  fprime=zero ; tsum=zero ; t_tsum=zero ; tdiff=zero

  do k=1,nsig-1
    do j=1,lon2
      do i=1,lat2
        tsum9(i,j,k)=ges_tv(i,j,k,it)+ges_tv(i,j,k+1,it)
        tdiff9(i,j,k)=ges_tv(i,j,k,it)-ges_tv(i,j,k+1,it)
        t_tsum9(i,j,k)=t_thor9(i,j,k)+t_thor9(i,j,k+1)
      end do
    end do
  end do
  do k=1,nsig+1
    do j=1,lon2
      do i=1,lat2
        what(i,j,k)=whatin(i,j,k)
      end do
    end do
  end do

!    back substitution
  do k=2,nsig-1
    do j=1,lon2
      do i=1,lat2
! Use the _f (forwared/fixed) value of wint9 for the k-level here, but use the update
! real value of wint9 for the k+1 level
         tmp1=what(i,j,k)*(r_bdiag9(i,j,k)**two)
         what(i,j,k+1) = what(i,j,k+1) - tmp1*bdiag9(i,j,k)*cdiag9(i,j,k)
         cdiag(i,j,k) = cdiag(i,j,k) - tmp1*bdiag9(i,j,k)*wint9(i,j,k+1)
         bdiag(i,j,k) = bdiag(i,j,k) - tmp1*(wint9_f(i,j,k)-cdiag9(i,j,k)*wint9(i,j,k+1))
! Update what(i,j,k) last
         what(i,j,k) = bdiag9(i,j,k)*tmp1
      end do
    end do
  end do

  k=nsig
  do j=1,lon2
    do i=1,lat2
! use the _f (forward sub / fixed value) here at the k level
       tmp1=what(i,j,k)*(r_bdiag9(i,j,k)**two)
       bdiag(i,j,k) = bdiag(i,j,k) - wint9_f(i,j,k)*tmp1
       what(i,j,k) = bdiag9(i,j,k)*tmp1
    end do
  end do

  do k=nsig,3,-1
    do j=1,lon2
      do i=1,lat2
        c1=ck5(k)*half*kapr
        c2=half/tref5(k-1)

        tmp1=bdiag(i,j,k)*(r_bdiag9(i,j,k-1)**two)
        adiag(i,j,k) = adiag(i,j,k) - tmp1*bdiag9(i,j,k-1)*cdiag9(i,j,k-1)
        cdiag(i,j,k-1) = cdiag(i,j,k-1) - tmp1*bdiag9(i,j,k-1)*adiag9(i,j,k)
        bdiag(i,j,k-1) = bdiag(i,j,k-1) + tmp1*adiag9(i,j,k)*cdiag9(i,j,k-1)

        tmp2=what(i,j,k)*(r_bdiag9(i,j,k-1)**two)
        adiag(i,j,k) = adiag(i,j,k) - tmp2*bdiag9(i,j,k-1)*wint9_f(i,j,k-1)
        bdiag(i,j,k-1) = bdiag(i,j,k-1) + tmp2*adiag9(i,j,k)*wint9_f(i,j,k-1)
        what(i,j,k-1) = what(i,j,k-1) - tmp2*bdiag9(i,j,k-1)*adiag9(i,j,k)

        prsth(i,j,1) = prsth(i,j,1) + bk5(k)*what(i,j,k)
        prsth(i,j,k) = prsth(i,j,k) - what(i,j,k)
        t_tsum(i,j,k-1) = t_tsum(i,j,k-1) + two*factk9(i,j,k)*what(i,j,k)
        factk(i,j,k) = factk(i,j,k) + two*t_tsum9(i,j,k-1)*what(i,j,k)

        tmp1=cdiag(i,j,k)*(r_prdif9(i,j,k)**two)
        factk(i,j,k) = factk(i,j,k) + tmp1*prdif9(i,j,k)*tdiff9(i,j,k)
        tdiff(i,j,k) = tdiff(i,j,k) + tmp1*prdif9(i,j,k)*factk9(i,j,k)
        prdif(i,j,k) = prdif(i,j,k) - tmp1*factk9(i,j,k)*tdiff9(i,j,k)
 
        tmp1=bdiag(i,j,k)*(r_prdif9(i,j,k)**two)
        factk(i,j,k) = factk(i,j,k) + tmp1*prdif9(i,j,k)*tdiff9(i,j,k-1)
        tdiff(i,j,k-1) =  tdiff(i,j,k-1) + tmp1*prdif9(i,j,k)*factk9(i,j,k)
        prdif(i,j,k) = prdif(i,j,k) - tmp1*factk9(i,j,k)*tdiff9(i,j,k-1)

        tmp2=bdiag(i,j,k)*(r_prdif9(i,j,k-1)**two)
        factk(i,j,k) = factk(i,j,k) + tmp2*prdif9(i,j,k-1)*tdiff9(i,j,k-1)
        tdiff(i,j,k-1) =  tdiff(i,j,k-1) + tmp2*prdif9(i,j,k-1)*factk9(i,j,k)
        prdif(i,j,k-1) = prdif(i,j,k-1) - tmp2*factk9(i,j,k)*tdiff9(i,j,k-1)

        tmp1=adiag(i,j,k)*(r_prdif9(i,j,k-1)**two)
        factk(i,j,k) = factk(i,j,k) + tmp1*prdif9(i,j,k-1)*tdiff9(i,j,k-2)
        tdiff(i,j,k-2) = tdiff(i,j,k-2) + tmp1*prdif9(i,j,k-1)*factk9(i,j,k)
        prdif(i,j,k-1) = prdif(i,j,k-1) - tmp1*factk9(i,j,k)*tdiff9(i,j,k-2)

        tmp2=c1*factk(i,j,k)/(tsum9(i,j,k-1)**two)
        tsum(i,j,k-1) = tsum(i,j,k-1) - tmp2*((c2*tsum9(i,j,k-1))**kapr)
        fprime = tmp2*tsum9(i,j,k-1)
        tsum(i,j,k-1) = tsum(i,j,k-1) + kapr*c2*fprime*((c2*tsum9(i,j,k-1))**kaprm1)
      end do
    end do
  end do

  k=2
  do j=1,lon2
    do i=1,lat2
      c1=ck5(k)*half*kapr
      c2=half/tref5(k-1)

      prsth(i,j,1) = prsth(i,j,1) + bk5(k)*what(i,j,k)
      prsth(i,j,k) = prsth(i,j,k) - what(i,j,k)
      t_tsum(i,j,k-1) = t_tsum(i,j,k-1) + two*factk9(i,j,k)*what(i,j,k)
      factk(i,j,k) = factk(i,j,k) + two*t_tsum9(i,j,k-1)*what(i,j,k)

      tmp1=cdiag(i,j,k)*(r_prdif9(i,j,k)**two)
      factk(i,j,k) = factk(i,j,k) + tmp1*prdif9(i,j,k)*tdiff9(i,j,k)
      tdiff(i,j,k) = tdiff(i,j,k) + tmp1*prdif9(i,j,k)*factk9(i,j,k)
      prdif(i,j,k) = prdif(i,j,k) - tmp1*factk9(i,j,k)*tdiff9(i,j,k)

      terma = bdiag(i,j,k) ; termb=bdiag(i,j,k)
      tmp1=bdiag(i,j,k)*(r_prdif9(i,j,k)**two)
      factk(i,j,k) = factk(i,j,k) + tmp1*prdif9(i,j,k)*tdiff9(i,j,k-1)
      tdiff(i,j,k-1) =  tdiff(i,j,k-1) + tmp1*prdif9(i,j,k)*factk9(i,j,k)
      prdif(i,j,k) = prdif(i,j,k) - tmp1*factk9(i,j,k)*tdiff9(i,j,k-1)

      tmp2=bdiag(i,j,k)*(r_prdif9(i,j,k-1)**two)
      factk(i,j,k) = factk(i,j,k) + tmp2*prdif9(i,j,k-1)*tdiff9(i,j,k-1)
      tdiff(i,j,k-1) =  tdiff(i,j,k-1) + tmp2*prdif9(i,j,k-1)*factk9(i,j,k)
      prdif(i,j,k-1) = prdif(i,j,k-1) - tmp2*factk9(i,j,k)*tdiff9(i,j,k-1)

      tmp1=c1*factk(i,j,k)/(tsum9(i,j,k-1)**two)
      tsum(i,j,k-1) = tsum(i,j,k-1) - tmp1*((c2*tsum9(i,j,k-1))**kapr)
      fprime = tsum9(i,j,k-1)*tmp1
      tsum(i,j,k-1) = tsum(i,j,k-1) + kapr*c2*fprime*((c2*tsum9(i,j,k-1))**kaprm1)
    end do
  end do

  do k=1,nsig-1
    do j=1,lon2
      do i=1,lat2
        t(i,j,k) = t(i,j,k) + tsum(i,j,k) + tdiff(i,j,k)
        t(i,j,k+1) = t(i,j,k+1) + tsum(i,j,k) - tdiff(i,j,k)
        t_thor(i,j,k) = t_thor(i,j,k) + t_tsum(i,j,k)
        t_thor(i,j,k+1) = t_thor(i,j,k+1) + t_tsum(i,j,k)
      end do
    end do
  end do


  return
end subroutine getvvel_ad

