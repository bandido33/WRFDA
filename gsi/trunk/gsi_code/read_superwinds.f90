subroutine read_superwinds(nread,ndata,nodata,infile,obstype,lunout, &
            twind,sis)
!$$$  subprogram documentation block
!                .      .    .                                       .
! subprogram:    read_superwinds   read in and reformat wind superobs
!   prgmmr: parrish          org: np22       date: 2004-03-17
!
! abstract: read in and reformat data for wind superobs
!           from non-bufr file
!
! program history log:
!   2004-03-17  parrish
!   2004-06-22  parrish, document
!   2004-07-29  treadon - add only to module use, add intent in/out
!   2005-08-02  derber  - modify to use convinfo file
!   2005-09-08  derber - modify to use input group time window
!   2005-10-11  treadon - change convinfo read to free format
!   2005-10-17  treadon - add grid and earth relative obs location to output file
!   2005-10-18  treadon - remove array obs_load and call to sumload 
!   2005-10-26  treadon - add routine tag to convinfo printout
!   2006-01-04  liu - correct unit error when bounding longitude
!   2006-02-03  derber  - modify for new obs control and obs count
!   2006-02-08  derber  - modify to use new convinfo module
!   2006-02-24  derber  - modify to take advantage of convinfo module
!
!   input argument list:
!     nread    - counter for all data on this pe
!     infile   - input file array
!     obstype  - observation type array for each processor ( = "superuv" for superob winds)
!     lunout   - output unit number to write reformated data
!     twind    - input group time window (hours)
!
!   output argument list:
!     nread    - counter for all data on this pe
!     ndata    - number of observation records
!     nodata   - number of observation data
!     sis      - satellite/instrument/sensor indicator
!
!   remarks: 
!   input file format: 
!    rec 1: number of superobs,iord,iuvw,nbar,ref_date_super(yr,mon,day,hr,min,sec)
!    rec 2,etc: suplon,suplat,suphgt,suptime,supyhat(nbar),suprhat(nbar),supbigu(nbar,nbar)
!       suplon,suplat -- coordinates of superob centroid (degrees)
!       suptime       -- superob time, relative to ref_date_super (hours)
!       supyhat       -- superob
!       suprhat       -- superob error variance
!       supbigu       -- superob forward model
!
!      the forward model is like this
!
!      given u,v, (and w if iuvw=3) interpolated to suplon,suplat,suphgt, then
!
!  iuvw=2:
!                                | u |
!             yhat(model) =  U * | v | 
!                                
!                 where U is a 2x2 matrix and yhat is a 2-vector
!
!  iuvw=3:
!                                | u |
!             yhat(model) =  U * | v | 
!                                | w |
!                                
!                 where U is a 3x3 matrix and yhat is a 3-vector
!
!   for now we will only allow iuvw=2, and also iord=0, which means this is a conventional
!    (except for the u-v transformation to yhat) superob.
!
! attributes:
!   language: f90
!   machine:  ibm RS/6000 SP
!
!$$$
  use kinds, only: r_kind,r_single,i_kind
  use constants, only: deg2rad,rad2deg,zero
  use gridmod, only: regional,nlat,nlon,tll2xy,rotate_wind_ll2xy,rlats,rlons
  use convinfo, only: nconvtype,ctwind,cgross,cermax,cermin,cvar_b,cvar_pg, &
        ncmiter,ncgroup,ncnumgrp,icuse,ictype,icsubtype,ioctype
  use obsmod, only: iadate,offtime_data
  implicit none

! Declare local parameters
  real(r_kind),parameter:: r360=360.0_r_kind

! Declare passed variables
  character(10),intent(in):: obstype,infile
  character(20),intent(in):: sis
  real(r_kind),intent(in):: twind
  integer(i_kind),intent(in):: lunout
  integer(i_kind),intent(inout):: nread,ndata,nodata
  
! Declare local variables  
  logical outside
  integer(i_kind) ndata_in,iord_in,iuvw_in,nbar_in,ithin
  integer(i_kind) iyref,imref,idref,ihref
  real(r_single)suplon0,suplat0,suphgt,suptime0,supyhat(2),suprhat(2),supbigu(2,2)
  real(r_single)suptime,supid(2)
  real(r_kind) supid8
  equivalence(supid(1),supid8)
  real(r_kind) rstation_id,rmesh,usage
  real(r_kind),allocatable,dimension(:,:):: cdata_all
  integer(i_kind) lnbufr,nmrecs,i,maxobs,ikx
  integer(i_kind) ilon,ilat,k,icount,nchanl,nreal

  real(r_kind) dlat,dlon,dlat_earth,dlon_earth
  real(r_kind) u0,v0,superror,uob,vob,rlat,rlon,rlat0,rlon0,superrinv(2)

  integer(i_kind) idate5(5),minobs,minan
  real(r_kind) time_correction


  data ithin / -9 /
  data rmesh / -99.999/  

!**************************************************************************
! Initialize variables
  lnbufr=10
  maxobs=2e6
  nreal=17
  nchanl=0
  ilon=1
  ilat=2

  ikx = 0
  do i=1,nconvtype
    if(trim(obstype) == trim(ioctype(i)))ikx=i
  end do
  if(ikx == 0)then
    write(6,*) ' READSUPERWIND: NO DATA REQUESTED'
    return
  end if
  allocate(cdata_all(nreal,maxobs))

  
! Open, then read date from bufr data
  open(lnbufr,file=infile,form='unformatted')
  rewind lnbufr
  read(lnbufr,end=1010,err=1010)ndata_in,iord_in,iuvw_in,nbar_in,iyref,imref,idref,ihref
  if(offtime_data) then

!      obtain time correction for observations to account for analysis
!                  time being different from obs file time

    idate5(1)=iyref
    idate5(2)=imref
    idate5(3)=idref
    idate5(4)=ihref
    idate5(5)=0
    call w3fs21(idate5,minobs)          !  obs ref time in minutes relative to historic date
    call w3fs21(iadate,minan)           !  analysis ref time in minutes relative to historic date

!     add obs reference time, then subtract analysis time to get obs time relative to analysis

     time_correction=float(minobs-minan)/60._r_kind

  else
     time_correction=zero
  end if
  write(6,*)'READ_SUPERWINDS: input file date is ',iyref,imref,idref,ihref
  if(iyref/=iadate(1).or.imref/=iadate(2).or.idref/=iadate(3).or.&
       ihref/=iadate(4)) then
     if(offtime_data) then
          write(6,*)'***allow off time READ_PREPBUFR file ',&
             'observation date/time and time_correction follow:'
     else
       write(6,*)'***READ_SUPERWINDS ERROR*** incompatable analysis ',&
          'and observation date/time'
     end if
     write(6,*)' year  anal/obs ',iadate(1),iyref
     write(6,*)' month anal/obs ',iadate(2),imref
     write(6,*)' day   anal/obs ',iadate(3),idref
     write(6,*)' hour  anal/obs ',iadate(4),ihref
     if(offtime_data) write(6,'(" time_correction = ",f12.2)') time_correction
     if(.not.offtime_data) call stop2(92)
  end if
  rstation_id=999.
  write(6,*)'READ_SUPERWINDS:  ndata_in,iord_in,iuvw_in,nbar_in =', &
       ndata_in,iord_in,iuvw_in,nbar_in
  if(iord_in.ne.0.or.iuvw_in.ne.2.or.nbar_in.ne.2) then
     write(6,*)'READ_SUPERWINDS:  ***ERROR*** iord =',iord_in,' iuvw=',iuvw_in,' nbar=',nbar_in
     write(6,*)'  currently only able to do iord=0 (traditional superob), iuvw=2 (u,v only), and nbar=2'
     call stop2(97)
  end if

  
! Loop to read in data
  do icount=1,ndata_in
     nread=nread+2
     read(lnbufr)suplon0,suplat0,suphgt,suptime0,supyhat,suprhat,supbigu,supid
     suptime=suptime0+time_correction
                         
     if(abs(suptime) > ctwind(ikx) .or. abs(suptime) > twind)cycle
     dlat_earth = suplat0
     dlon_earth = suplon0
     if (dlon_earth>=r360) dlon_earth = dlon_earth - r360
     if (dlon_earth<zero ) dlon_earth = dlon_earth + r360
     dlat_earth = dlat_earth*deg2rad
     dlon_earth = dlon_earth*deg2rad
     if(regional)then
             call tll2xy(dlon_earth,dlat_earth,dlon,dlat,outside)
        if(outside) cycle
     else
        dlat = dlat_earth
        dlon = dlon_earth
        call grdcrd(dlat,1,rlats,nlat,1)
        call grdcrd(dlon,1,rlons,nlon,1)
     endif

     ndata=min(ndata+1,maxobs)
     nodata=min(nodata+1,maxobs)

!  rotate forward matrix to account for input u,v being in regional coordinate
!
!                           forward model for superobs:
!
!                      yhat(1) = bigu(1,1)*u(earth) + bigu(1,2)*v(earth)
!                      yhat(2) = bigu(2,1)*u(earth) + bigu(2,2)*v(earth)
!
!                       error variance is rhat(1), rhat(2)
!
!                                              T  T     -1                      T
!                  2*Jo = (yhat_ob - bigu*(u,v)  )  rhat   (yhat_ob - bigu*(u,v) )
!
!  in rotated coordinate, we multiply bigu by rotation matrix since u,v are no longer earth relative
!
!                      ue =  epsilonv*ur -   deltav*vr   (subroutine rotate_wind_xy2ll)
!                      ve = -epsilonu*ur +   deltau*vr
!
!              bigur(1,1) =  epsilonv*bigue(1,1) - epsilonu*bigue(1,2)  (subroutine rotate_wind_ll2xy)
!              bigvr(1,1) =   -deltav*bigue(1,1) +   deltau*bigue(1,2)
!              bigur(2,1) =  epsilonv*bigue(2,1) - epsilonu*bigue(2,2)
!              bigvr(2,1) =   -deltav*bigue(2,1) +   deltau*bigue(2,2)

     if(regional) then
        do i=1,2
           u0=supbigu(i,1)
           v0=supbigu(i,2)
           call rotate_wind_ll2xy(u0,v0,uob,vob,dlon_earth,dlat_earth,dlon,dlat)
           supbigu(i,1)=uob
           supbigu(i,2)=vob
        end do
     end if
     
     superror=sqrt(suprhat(1))
     superrinv(2)=superror/(sqrt(suprhat(2))+1.e-20)
     if(suprhat(2).lt.1.e-20)superrinv(2)=0.
     superrinv(1)=1.
     usage = 0.
     if(icuse(ikx) < 0)usage=100.
     if(ncnumgrp(ikx) > 0 )then                     ! cross validation on
       if(mod(ndata,ncnumgrp(ikx))== ncgroup(ikx)-1)usage=ncmiter(ikx)
     end if


!    Load superobs wind data into output array
     cdata_all(1,ndata)=dlon     ! grid relative longitude
     cdata_all(2,ndata)=dlat     ! grid relative latitude
     cdata_all(3,ndata)=suphgt
     cdata_all(4,ndata)=suptime
     cdata_all(5,ndata)=supyhat(1)*superrinv(1)
     cdata_all(6,ndata)=supyhat(2)*superrinv(2)
     cdata_all(7,ndata)=superror
     cdata_all( 8,ndata)=supbigu(1,1)*superrinv(1)
     cdata_all( 9,ndata)=supbigu(2,1)*superrinv(2)
     cdata_all(10,ndata)=supbigu(1,2)*superrinv(1)
     cdata_all(11,ndata)=supbigu(2,2)*superrinv(2)
     cdata_all(12,ndata)=ikx            !  type number--later change for different radar sources
     cdata_all(13,ndata)=rstation_id    ! station id
     cdata_all(14,ndata)=usage          ! usage parameter
     cdata_all(15,ndata)=supid8         ! 8byte character string, first 4 are radar station id,
                                        !   second 4 are mean range of superob from radar 
                                        !    (integer, in km, between 0 and 9999)
     cdata_all(16,ndata)=dlon_earth*rad2deg     ! earth relative longitude (degrees)
     cdata_all(17,ndata)=dlat_earth*rad2deg     ! earth relative latitude (degrees)

! End of data read loop
  end do


! Write observations to scratch file
  write(lunout) obstype,sis,nreal,nchanl,ilat,ilon
  write(lunout) ((cdata_all(k,i),k=1,nreal),i=1,ndata)

! Close units
1010 continue
  close(lnbufr)
  deallocate(cdata_all)

! End of routine
  return
  
end subroutine read_superwinds
