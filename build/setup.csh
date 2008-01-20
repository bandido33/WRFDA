if (! $?MACHINE) then
   setenv MACHINE `uname -n`
endif

if (! $?EXT_DIR) then
   setenv EXT_DIR ~wrfhelp/external
endif

if (! -d $EXT_DIR) then
   echo "Cannot find EXT_DIR=$EXT_DIR"
endif

# Search for queuing systems.
# Don't use which, as it always returns 0 on BSD
bjobs -V >& /dev/null
if ($status == 0) then
   setenv SUBMIT LSF
else
   llq >& /dev/null
   if ($status == 0) then
      setenv SUBMIT LoadLeveller
   else
      which qsub >& /dev/null
      # could be SGE of course, so might need better way to check
      if ($? == 0) then
         setenv SUBMIT PBS
      else
         setenv SUBMIT none
      endif
   endif
endif

if (! $?PROCESSOR) then
   # Unix people can't even report processor class properly
   # across different machines or between ksh/bash on Linux
   # They all need their heads banged together
   # This kludge should give powerpc/i686/i386(for intel Mac)
   if ( `uname` == "AIX" ) then
      # Thanks Aix for reporting a hex string with -m, when
      # all I wanted was powerpc
      setenv PROCESSOR `uname -p`
   else
      # Thanks Linux for either reporting nothing with -n,
      # or different values for ksh and bash, FFS
      setenv PROCESSOR `uname -m`
      if ("$PROCESSOR" == "Power Macintosh") then
         setenv PROCESSOR powerpc
      endif
   endif
endif 

if ( `uname` == "AIX" ) then
   # Brain dead Aix /bin/csh cannot handle arguments to 
   # sourced scripts, so force use of ibm
   setenv COMPILER ibm
else
   if ("$1" != "") then
      setenv COMPILER $1
   else
      setenv COMPILER gnu
   endif
endif

if ($COMPILER == g95) then
   setenv COMPILER gnu
endif

if ($COMPILER == xlf) then
   setenv COMPILER ibm
endif

if ($COMPILER == gnu) then
   setenv G95_ENDIAN BIG
endif

if ($COMPILER == cray) then
   setenv PROCESSOR x1
endif


# List options in order of increasing preference

if (-d ${EXT_DIR}/netcdf/netcdf-3.6.1/${COMPILER}_${PROCESSOR}) then
   setenv NETCDF ${EXT_DIR}/netcdf/netcdf-3.6.1/${COMPILER}_${PROCESSOR}
endif
if (-d ${EXT_DIR}/mpi/mpich2-1.0.6p1/${COMPILER}_${PROCESSOR}) then
   setenv MPIHOME ${EXT_DIR}/mpi/mpich2-1.0.6p1/${COMPILER}_${PROCESSOR}
endif
if (-d ${EXT_DIR}/blas/blas/${COMPILER}_${PROCESSOR}) then
   setenv BLAS ${EXT_DIR}/blas/blas/${COMPILER}_${PROCESSOR}
endif
if (-d ${EXT_DIR}/lapack/lapack-3.1.1/${COMPILER}_${PROCESSOR}) then
   setenv LAPACK ${EXT_DIR}/lapack/lapack-3.1.1/${COMPILER}_${PROCESSOR}
endif
if (-d ${EXT_DIR}/makedepf90/makedepf90-2.8.8/${COMPILER}_${PROCESSOR}) then
   setenv MAKEDEPF90 ${EXT_DIR}/makedepf90/makedepf90-2.8.8/${COMPILER}_${PROCESSOR}
endif
if (-d ${EXT_DIR}/netcdf/pnetcdf-1.0.1/${COMPILER}_${PROCESSOR}) then
   setenv PNETCDF ${EXT_DIR}/netcdf/pnetcdf-1.0.1/${COMPILER}_${PROCESSOR}
endif

if (-d /usr/lpp/ppe.poe) then
   setenv MPIHOME /usr/lpp/ppe.poe
endif

# Lightning

if ( $MACHINE == "lightning" ) then 
   if ( $COMPILER == "pathscale" ) then
      setenv MPIHOME /contrib/2.6/mpich-gm/1.2.6..14a-pathscale-2.4-64
   endif
   if ( $COMPILER == "pgi" ) then
      setenv MPIHOME /contrib/2.6/mpich-gm/1.2.6..14a-pgi-6.2-64
   endif
   if ( $COMPILER == "intel" ) then
      source /contrib/2.6/intel/9.1.036-64/bin/ifortvars.csh
      setenv MPIHOME /contrib/2.6/mpich-gm/1.2.6..14a-intel-9.1.042-64
   endif
endif

setenv LINUX_MPIHOME $MPIHOME
setenv PATH $MPIHOME/bin:$PATH

if ($?MAKEDEPF90) then
   setenv PATH $MPIHOME/bin\:$MAKEDEPF90\:$PATH
endif

echo
if ($?PROCESSOR) then
   echo "PROCESSOR       " $PROCESSOR
endif
if ($?COMPILER) then
   echo "COMPILER        " $COMPILER       
endif
if ($?MPIHOME) then
   echo "MPIHOME         " $MPIHOME
endif
if ($?NETCDF) then
   echo "NETCDF          " $NETCDF
endif
if ($?BLAS) then
   echo "BLAS            " $BLAS
endif
if ($?LAPACK) then
   echo "LAPACK          " $LAPACK
endif
if ($?MAKEDEPF90) then
   echo "MAKEDEPF90      " $MAKEDEPF90
endif
if ($?PNETCDF) then
   echo "PNETCDF         " $PNETCDF
endif
if ($?SUBMIT) then
   echo "SUBMIT          " $SUBMIT
endif
if ($?SUBMIT_OPTIONS1) then
   echo "SUBMIT_OPTIONS1  $SUBMIT_OPTIONS1"
endif
if ($?SUBMIT_OPTIONS2) then
   echo "SUBMIT_OPTIONS2  $SUBMIT_OPTIONS2"
endif
if ($?SUBMIT_OPTIONS3) then
   echo "SUBMIT_OPTIONS3  $SUBMIT_OPTIONS3"
endif
if ($?SUBMIT_OPTIONS4) then
   echo "SUBMIT_OPTIONS4  $SUBMIT_OPTIONS4"
endif
if ($?SUBMIT_OPTIONS5) then
   echo "SUBMIT_OPTIONS5  $SUBMIT_OPTIONS5"
endif
if ($?SUBMIT_OPTIONS6) then
   echo "SUBMIT_OPTIONS6  $SUBMIT_OPTIONS6"
endif
if ($?SUBMIT_OPTIONS7) then
   echo "SUBMIT_OPTIONS7  $SUBMIT_OPTIONS7"
endif
if ($?SUBMIT_OPTIONS8) then
   echo "SUBMIT_OPTIONS8  $SUBMIT_OPTIONS8"
endif
if ($?SUBMIT_OPTIONS9) then
   echo "SUBMIT_OPTIONS9  $SUBMIT_OPTIONS9"
endif
if ($?SUBMIT_OPTIONS10) then
   echo "SUBMIT_OPTIONS10 $SUBMIT_OPTIONS10"
endif
if ($?SUBMIT_WAIT_FLAG) then
   echo "SUBMIT_WAIT_FLAG $SUBMIT_WAIT_FLAG"
endif

if ($COMPILER == cray) then
   # Cray use COMPILER for their own purposes, so reset
   unsetenv COMPILER
endif
