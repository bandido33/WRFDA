#! /bin/csh -f
#-----------------------------------------------------------------------
# Purpose : Create BE statistics from input perturbation files.
# Run Stage 0: Calculate ensemble perturbations from model forecasts.
# Run Stage 1: Read "standard fields", and remove time/ensemble/area mean.
# Run Stage 1: Read "standard fields", and remove time/ensemble/area mean.
# Run Stage 2: Calculate regression coefficients.
# Run Stage 2a: Calculate control variable fields.
# Run Stage 3: Read 3D control variable fields, and calculate vertical covariances.
# Run Stage 4: Calculate horizontal covariances.
# Finally, gather data together into a single BE file.
#-----------------------------------------------------------------------

#set echo
#Define job via environment variables:

# Uncomment variables for the stages you wish to run:
#setenv RUN_GEN_BE_STAGE0 # Set to run stage 0 (create perturbation files).
#setenv RUN_GEN_BE_STAGE1 # Set to run stage 1 (Remove mean, split variables).
#setenv RUN_GEN_BE_STAGE2 # Set to run stage 2 (Regression Coefficients).
#setenv RUN_GEN_BE_STAGE2A # Set to run stage 2 (Regression Coefficients).
#setenv RUN_GEN_BE_STAGE3 # Set to run stage 3 (Vertical Covariances).
#setenv RUN_GEN_BE_STAGE4 # Set to run stage 4 (Horizontal Covariances).
setenv RUN_GEN_BE_DIAGS  # Set to run gen_be diagnostics.
setenv RUN_GEN_BE_DIAGS_READ  # Set to run gen_be diagnostics_read.

#-----------------------------------------------------------------------------------
# Don't change anything below this line.
#-----------------------------------------------------------------------------------

if ( ! $?START_DATE )    setenv START_DATE    2003010100 # Time of first perturbation.
if ( ! $?END_DATE )      setenv END_DATE      2003012800 # Time of last perturbation.
if ( ! $?INTERVAL )      setenv INTERVAL      12         # Period between files (hours).
if ( ! $?BE_METHOD )     setenv BE_METHOD     NMC        # NMC (NMC-method), ENS (Ensemble-Method).
if ( ! $?NE )            setenv NE            1          # Number of ensemble members (for ENS).
if ( ! $?BIN_TYPE )      setenv BIN_TYPE      5          # 0=None, 1=1:ni, 2=latitude, ....
if ( ! $?LAT_MIN )       setenv LAT_MIN       -90.0      # Used if BIN_TYPE = 2.
if ( ! $?LAT_MAX )       setenv LAT_MAX       90.0       # Used if BIN_TYPE = 2.
if ( ! $?BINWIDTH_LAT )  setenv BINWIDTH_LAT  10.0       # Used if BIN_TYPE = 2.
if ( ! $?HGT_MIN )       setenv HGT_MIN       0.0        # Used if BIN_TYPE = 2.
if ( ! $?HGT_MAX )       setenv HGT_MAX       20000.0    # Used if BIN_TYPE = 2.
if ( ! $?BINWIDTH_HGT )  setenv BINWIDTH_HGT  1000.0     # Used if BIN_TYPE = 2.
if ( ! $?REMOVE_MEAN )   setenv REMOVE_MEAN   .true.     # Remove time/ensemble/area mean.
if ( ! $?GAUSSIAN_LATS ) setenv GAUSSIAN_LATS .false.    # Set if Gaussian latitudes used (global only).
if ( ! $?TESTING_EOFS )  setenv TESTING_EOFS  .true.     # True if performing EOF tests.
if ( ! $?NUM_PASSES )    setenv NUM_PASSES    0          # Number of passes of recursive filter.
if ( ! $?RF_SCALE )      setenv RF_SCALE      1.0        # Recursive filter scale.
if ( ! $?DATA_ON_LEVELS )  setenv DATA_ON_LEVELS .false. # False if fields projected onto modes.
if ( ! $?GLOBAL )        setenv GLOBAL false             # Global or regional models
if ( ! $?NUM_LEVELS )    setenv NUM_LEVELS    27         # Hard-wired for now....
if ( ! $?N_SMTH_SL )     setenv N_SMTH_SL     0          # Amount of lengthscale smoothing (0=none).
if ( ! $?STRIDE )        setenv STRIDE 1                 # Calculate correlation evert STRIDE point (stage4 regional).
if ( ! $?NUM_JOBS )      setenv NUM_JOBS 8               # Number of jobs to run (stage4 regional)).
if ( ! $?RESOLUTION_KM ) setenv RESOLUTION_KM 200        # Hard-wired for now (only used for regional)
if ( ! $?TESTING_SPECTRAL ) setenv TESTING_SPECTRAL .false. # True if performing spectral tests.

if ( ! $?EXPT )          setenv EXPT 2003-01.test
if ( ! $?ID1 )           setenv ID1 ${BE_METHOD}.bin_type${BIN_TYPE}
if ( ! $?GEN_BE_DIR )    setenv GEN_BE_DIR ${HOME}/code_development/WRF_V2.1.2/wrfvar
if ( ! $?BUILD_DIR )     setenv BUILD_DIR ${GEN_BE_DIR}/gen_be
if ( ! $?BIN_DIR )       setenv BIN_DIR   ${GEN_BE_DIR}/tools
if ( ! $?DATA_DISK )     setenv DATA_DISK /ocotillo1
if ( ! $?REGION )        setenv REGION con200
if ( ! $?DAT_DIR )       setenv DAT_DIR ${DATA_DISK}/${USER}/data/${REGION}/noobs
if ( ! $?RUN_DIR )       setenv RUN_DIR ${DAT_DIR}/gen_be
if ( ! $?STAGE0_DIR )    setenv STAGE0_DIR ${RUN_DIR}/stage0

if ( ! -d ${RUN_DIR} )   mkdir ${RUN_DIR}
if ( ! -d ${STAGE0_DIR} )  mkdir ${STAGE0_DIR}


if ( $GLOBAL == true ) then
  setenv UH_METHOD power
  if ( ! $?USE_GLOBAL_EOFS ) setenv USE_GLOBAL_EOFS .false.
else
  setenv UH_METHOD scale
  if ( ! $?USE_GLOBAL_EOFS ) setenv USE_GLOBAL_EOFS .true.
endif

#List of control variables:

foreach SV ( fullflds psi chi t rh ps )
   if ( ! -d ${RUN_DIR}/$SV ) mkdir ${RUN_DIR}/$SV
end

set CONTROL_VARIABLES = ( psi chi_u t_u rh ps_u )

foreach CV ( $CONTROL_VARIABLES )
   if ( ! -d ${RUN_DIR}/$CV ) mkdir ${RUN_DIR}/$CV
end

set DELETE_DIRS = (  )
#Uncomment to tidy (after running gen_be_cov3d) set DELETE_DIRS = ( chi t ps )

cd ${RUN_DIR}

#------------------------------------------------------------------------
# Run Stage 0: Calculate ensemble perturbations from model forecasts.
#------------------------------------------------------------------------

if ( $?RUN_GEN_BE_STAGE0 ) then

   echo "---------------------------------------------------------------"
   echo "Run Stage 0: Calculate ensemble perturbations from model forecasts."
   echo "---------------------------------------------------------------"

   set BEGIN_CPU = `date`
   echo "Beginning CPU time: ${BEGIN_CPU}"

   $GEN_BE_DIR/run/gen_be/gen_be_stage0_wrf.csh >& gen_be_stage0_wrf.log

   set RC = $status
   if ( $RC != 0 ) then
     echo "Stage 0 for WRF failed with error" $RC
     exit 1
   endif

   set END_CPU = `date`
   echo "Ending CPU time: ${END_CPU}"
endif

# advance start date by 1 day and end date by 12 hours, as our differencing
# calculation moves the time window

setenv START_DATE `${BIN_DIR}/advance_cymdh $START_DATE $INTERVAL`
setenv START_DATE `${BIN_DIR}/advance_cymdh $START_DATE $INTERVAL`
setenv END_DATE   `${BIN_DIR}/advance_cymdh $END_DATE $INTERVAL`

#------------------------------------------------------------------------
#  Run Stage 1: Read "standard fields", and remove time/ensemble/area mean.
#------------------------------------------------------------------------

if ( $?RUN_GEN_BE_STAGE1 ) then

   echo "---------------------------------------------------------------"
   echo "Run Stage 1: Read "standard fields", and remove time/ensemble/area mean."
   echo "---------------------------------------------------------------"

   set BEGIN_CPU = `date`
   echo "Beginning CPU time: ${BEGIN_CPU}"

   ln -sf ${BUILD_DIR}/gen_be_stage1.exe .

cat >! gen_be_stage1_nl.nl << EOF
  &gen_be_stage1_nl
    start_date = '${START_DATE}',
    end_date = '${END_DATE}',
    interval = ${INTERVAL},
    be_method = '${BE_METHOD}',
    ne = ${NE},
    bin_type = ${BIN_TYPE},
    lat_min = ${LAT_MIN},
    lat_max = ${LAT_MAX},
    binwidth_lat = ${BINWIDTH_LAT},
    hgt_min = ${HGT_MIN},
    hgt_max = ${HGT_MAX},
    binwidth_hgt = ${BINWIDTH_HGT},
    remove_mean = ${REMOVE_MEAN},
    gaussian_lats = ${GAUSSIAN_LATS},
    expt = '${EXPT}',
    dat_dir = '${STAGE0_DIR}' /
EOF

   ./gen_be_stage1.exe >& gen_be_stage1.log
   set RC = $status
   if ( $RC != 0 ) then
     echo "Stage 1 failed with error" $RC
     exit 1
   endif

   set END_CPU = `date`
   echo "Ending CPU time: ${END_CPU}"

endif

#------------------------------------------------------------------------
#  Run Stage 2: Calculate regression coefficients.
#------------------------------------------------------------------------

if ( $?RUN_GEN_BE_STAGE2 ) then

   echo "---------------------------------------------------------------"
   echo "Run Stage 2: Calculate regression coefficients."
   echo "---------------------------------------------------------------"

   set BEGIN_CPU = `date`
   echo "Beginning CPU time: ${BEGIN_CPU}"


   ln -sf ${BUILD_DIR}/gen_be_stage2.exe .

cat >! gen_be_stage2_nl.nl << EOF
  &gen_be_stage2_nl
    start_date = '${START_DATE}',
    end_date = '${END_DATE}', 
    interval = ${INTERVAL},
    be_method = '${BE_METHOD}',
    ne = ${NE},
    testing_eofs = ${TESTING_EOFS},
    expt = '${EXPT}',
    dat_dir = '${RUN_DIR}' /
EOF

   ./gen_be_stage2.exe >& gen_be_stage2.log
   set RC = $status
   if ( $RC != 0 ) then
     echo "Stage 2 failed with error" $RC
     exit 1
   endif

   set END_CPU = `date`
   echo "Ending CPU time: ${END_CPU}"
endif

#------------------------------------------------------------------------
#  Run Stage 2a: Calculate control variable fields.
#------------------------------------------------------------------------

if ( $?RUN_GEN_BE_STAGE2A ) then

   echo "---------------------------------------------------------------"
   echo "Run Stage 2a: Calculate control variable fields."
   echo "---------------------------------------------------------------"

   set BEGIN_CPU = `date`
   echo "Beginning CPU time: ${BEGIN_CPU}"

   ln -sf ${BUILD_DIR}/gen_be_stage2a.exe .

cat >! gen_be_stage2a_nl.nl << EOF
  &gen_be_stage2a_nl
    start_date = '${START_DATE}',
    end_date = '${END_DATE}', 
    interval = ${INTERVAL},
    be_method = '${BE_METHOD}',
    ne = ${NE},
    num_passes = ${NUM_PASSES},
    rf_scale = ${RF_SCALE},
    testing_eofs = ${TESTING_EOFS},
    expt = '${EXPT}',
    dat_dir = '${RUN_DIR}' /
EOF

   ./gen_be_stage2a.exe >& gen_be_stage2a.log
   set RC = $status
   if ( $RC != 0 ) then
     echo "Stage 2a failed with error" $RC
     exit 1
   endif

   rm -rf ${DELETE_DIRS} >&! /dev/null
   set END_CPU = `date`
   echo "Ending CPU time: ${END_CPU}"

endif

#------------------------------------------------------------------------
#  Run Stage 3: Read 3D control variable fields, and calculate vertical covariances.
#------------------------------------------------------------------------

if ( $?RUN_GEN_BE_STAGE3 ) then

   echo "---------------------------------------------------------------"
   echo "Run Stage 3: Read 3D control variable fields, and calculate vertical covariances."
   echo "---------------------------------------------------------------"

   set BEGIN_CPU = `date`
   echo "Beginning CPU time: ${BEGIN_CPU}"

   ln -sf ${BUILD_DIR}/gen_be_stage3.exe .

   foreach CV ( $CONTROL_VARIABLES )

cat >! gen_be_stage3_nl.nl << EOF
  &gen_be_stage3_nl
    start_date = '${START_DATE}',
    end_date = '${END_DATE}', 
    interval = ${INTERVAL},
    variable = '${CV}',
    be_method = '${BE_METHOD}',
    ne = ${NE},
    bin_type = ${BIN_TYPE},
    lat_min = ${LAT_MIN},
    lat_max = ${LAT_MAX},
    binwidth_lat = ${BINWIDTH_LAT},
    hgt_min = ${HGT_MIN},
    hgt_max = ${HGT_MAX},
    binwidth_hgt = ${BINWIDTH_HGT},
    testing_eofs = ${TESTING_EOFS},
    use_global_eofs = ${USE_GLOBAL_EOFS},
    data_on_levels = ${DATA_ON_LEVELS},
    expt = '${EXPT}',
    dat_dir = '${RUN_DIR}' /
EOF

     ./gen_be_stage3.exe >& gen_be_stage3.${CV}.log
     set RC = $status
     if ( $RC != 0 ) then
        echo "Stage 3 failed with error" $RC
        exit 1
     endif
   end

   set END_CPU = `date`
   echo "Ending CPU time: ${END_CPU}"

endif

#------------------------------------------------------------------------
#  Run Stage 4: Calculate horizontal covariances.
#------------------------------------------------------------------------

if ( $?RUN_GEN_BE_STAGE4 ) then

   set BEGIN_CPU = `date`
   echo "Beginning CPU time: ${BEGIN_CPU}"

   if ( ${GLOBAL} == true ) then    

      echo "---------------------------------------------------------------"
      echo "Run Stage 4: Calculate horizontal covariances (global power spectra)."
      echo "---------------------------------------------------------------"

      ${GEN_BE_DIR}/run/gen_be/gen_be_stage4_global.csh >&! gen_be_stage4_global.log
      set RC = $status
      if ( $RC != 0 ) then
        echo "Stage 4 global failed with error" $RC
        exit 1
      endif

   else

      echo "---------------------------------------------------------------"
      echo "Run Stage 4: Calculate horizontal covariances (regional lengthscales)."
      echo "---------------------------------------------------------------"

      ${GEN_BE_DIR}/run/gen_be/gen_be_stage4_regional.csh >&! gen_be_stage4_regional.log
      set RC = $status
      if ( $RC != 0 ) then
        echo "Stage 4 regional failed with error" $RC
        exit 1
      endif

   endif 

   set END_CPU = `date`
   echo "Ending CPU time: ${END_CPU}"

endif

#------------------------------------------------------------------------
#  Finally, gather data together into a single BE file:
#------------------------------------------------------------------------

if ( $?RUN_GEN_BE_DIAGS ) then
   ln -sf ${BUILD_DIR}/gen_be_diags.exe .

cat >! gen_be_diags_nl.nl << EOF
  &gen_be_diags_nl
    be_method = '${BE_METHOD}',
    uh_method = '${UH_METHOD}',
    n_smth_sl = ${N_SMTH_SL}, /
EOF

      ./gen_be_diags.exe >& gen_be_diags.log
      set RC = $status
      if ( $RC != 0 ) then
        echo "BE diags failed with error" $RC
        exit 1
      endif

endif

#------------------------------------------------------------------------
#  Read BE file to check data packed correctly, and write plot diagnostics.
#------------------------------------------------------------------------

if ( $?RUN_GEN_BE_DIAGS_READ ) then

cat >! gen_be_diags_nl.nl << EOF
  &gen_be_diags_nl
    be_method = '${BE_METHOD}',
    uh_method = '${UH_METHOD}' /
EOF

   ln -sf ${BUILD_DIR}/gen_be_diags_read.exe .
   ./gen_be_diags_read.exe >& gen_be_diags_read.log
   set RC = $status
   if ( $RC != 0 ) then
     echo "BE diags read failed with error" $RC
     exit 1
   endif

endif

exit(0)
