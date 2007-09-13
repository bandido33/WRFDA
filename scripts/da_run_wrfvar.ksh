#!/bin/ksh
#########################################################################
# Script: da_run_wrfvar.ksh
#
# Purpose: Run wrfvar
#########################################################################

export REL_DIR=${REL_DIR:-$HOME/trunk}
export WRFVAR_DIR=${WRFVAR_DIR:-$REL_DIR/wrfvar}
. ${WRFVAR_DIR}/scripts/da_set_defaults.ksh
export RUN_DIR=${RUN_DIR:-$EXP_DIR/wrfvar}

export WORK_DIR=$RUN_DIR/working

export WINDOW_START=${WINDOW_START:--3}
export WINDOW_END=${WINDOW_END:-3}

export YEAR=$(echo $DATE | cut -c1-4)
export MONTH=$(echo $DATE | cut -c5-6)
export DAY=$(echo $DATE | cut -c7-8)
export HOUR=$(echo $DATE | cut -c9-10)
export PREV_DATE=$($WRFVAR_DIR/build/da_advance_time.exe $DATE -$CYCLE_PERIOD 2>/dev/null)
export ANALYSIS_DATE=${YEAR}-${MONTH}-${DAY}_${HOUR}:00:00
export NL_ANALYSIS_DATE=${ANALYSIS_DATE}.0000

export DA_FIRST_GUESS=${DA_FIRST_GUESS:-${RC_DIR}/$DATE/wrfinput_d01}

if $NL_VAR4D; then
   export DA_BOUNDARIES=${DA_BOUNDARIES:-$RC_DIR/$DATE/wrfbdy_d01}
   #DALE: Boundaries look wrong to me.
fi
if $CYCLING; then
   if [[ $CYCLE_NUMBER -gt 0 ]]; then
      if $NL_VAR4D; then
         export DA_BOUNDARIES=$FC_DIR/$DATE/wrfbdy_d01    # wrfvar boundaries input.
      fi
      export DA_FIRST_GUESS=${FC_DIR}/${PREV_DATE}/wrfinput_d01_${ANALYSIS_DATE}
   fi
fi

export DA_ANALYSIS=${DA_ANALYSIS:-analysis}
export DA_BACK_ERRORS=${DA_BACK_ERRORS:-$BE_DIR/be.dat} # wrfvar background errors.

export RTTOV=${RTTOV:-$HOME/rttov/rttov87}                            # RTTOV
export DA_RTTOV_COEFFS=${DA_RTTOV_COEFFS:-$RTTOV/rtcoef_rttov7}
export CRTM=${CRTM:-$HOME/crtm}
export DA_CRTM_COEFFS=${DA_CRTM_COEFFS:-$CRTM/crtm_coeffs}

# Error tuning namelist parameters
# Assign random seeds

export NL_SEED_ARRAY1=$DATE
export NL_SEED_ARRAY2=$DATE

# Change defaults from Registry.wrfvar which is required to be
# consistent with WRF's Registry.EM
export NL_INTERP_TYPE=${NL_INTERP_TYPE:-1}
export NL_T_EXTRAP_TYPE=${NL_T_EXTRAP_TYPE:-1}
export NL_I_PARENT_START=${NL_I_PARENT_START:-0}
export NL_J_PARENT_START=${NL_J_PARENT_START:-0}
export NL_JCDFI_USE=${NL_JCDFI_USE:-false}
export NL_CO2TF=${NL_CO2TF:-0}
export NL_W_SPECIFIED=${NL_W_SPECIFIED:-true}
export NL_REAL_DATA_INIT_TYPE=${NL_REAL_DATA_INIT_TYPE:-3}

#=======================================================

mkdir -p $RUN_DIR

echo "<HTML><HEAD><TITLE>$EXPT wrfvar</TITLE></HEAD><BODY><H1>$EXPT wrfvar</H1><PRE>"

date

echo 'REL_DIR               <A HREF="file:'$REL_DIR'">'$REL_DIR'</a>'
echo 'WRFVAR_DIR            <A HREF="file:'$WRFVAR_DIR'">'$WRFVAR_DIR'</a>' $WRFVAR_VN
if $NL_VAR4D; then
   echo 'WRFNL_DIR             <A HREF="file:'$WRFNL_DIR'">'$WRFNL_DIR'</a>' $WRFNL_VN
   echo 'WRFPLUS_DIR           <A HREF="file:'$WRFPLUS_DIR'">'$WRFPLUS_DIR'</a>' $WRFPLUS_VN
fi
echo "DA_BACK_ERRORS        $DA_BACK_ERRORS"
if [[ -d $DA_RTTOV_COEFFS ]]; then
   echo "DA_RTTOV_COEFFS       $DA_RTTOV_COEFFS"
fi
if [[ -d $DA_CRTM_COEFFS ]]; then
   echo "DA_CRTM_COEFFS        $DA_CRTM_COEFFS"
fi
if [[ -d $BIASCORR_DIR ]]; then
   echo "BIASCORR_DIR          $BIASCORR_DIR"
fi
if [[ -d $OBS_TUNING_DIR ]] ; then
   echo "OBS_TUNING_DIR        $OBS_TUNING_DIR"
fi
echo 'OB_DIR                <A HREF="file:'$OB_DIR'">'$OB_DIR'</a>'
echo 'RC_DIR                <A HREF="file:'$RC_DIR'">'$RC_DIR'</a>'
echo 'FC_DIR                <A HREF="file:'$FC_DIR'">'$FC_DIR'</a>'
echo 'RUN_DIR               <A HREF="file:'${RUN_DIR##$RUN_DIR/}'">'$RUN_DIR'</a>'
echo 'WORK_DIR              <A HREF="file:'${WORK_DIR##$RUN_DIR/}'">'$WORK_DIR'</a>'
echo "DATE                  $DATE"
echo "WINDOW_START          $WINDOW_START"
echo "WINDOW_END            $WINDOW_END"

rm -rf ${WORK_DIR}
mkdir -p ${WORK_DIR}
cd $WORK_DIR

START_DATE=$($WRFVAR_DIR/build/da_advance_time.exe $DATE $WINDOW_START)
END_DATE=$($WRFVAR_DIR/build/da_advance_time.exe $DATE $WINDOW_END)

for INDEX in 01 02 03 04 05 06 07; do
   let H=$INDEX-1+$WINDOW_START
   D_DATE[$INDEX]=$($WRFVAR_DIR/build/da_advance_time.exe $DATE $H)
   export D_YEAR[$INDEX]=$(echo ${D_DATE[$INDEX]} | cut -c1-4)
   export D_MONTH[$INDEX]=$(echo ${D_DATE[$INDEX]} | cut -c5-6)
   export D_DAY[$INDEX]=$(echo ${D_DATE[$INDEX]} | cut -c7-8)
   export D_HOUR[$INDEX]=$(echo ${D_DATE[$INDEX]} | cut -c9-10)
done

if $NL_GLOBAL; then
   export NL_NPROC_X=1
fi

export YEAR=$(echo $DATE | cut -c1-4)
export MONTH=$(echo $DATE | cut -c5-6)
export DAY=$(echo $DATE | cut -c7-8)
export HOUR=$(echo $DATE | cut -c9-10)

export NL_START_YEAR=$YEAR
export NL_START_MONTH=$MONTH
export NL_START_DAY=$DAY
export NL_START_HOUR=$HOUR

export NL_END_YEAR=$YEAR
export NL_END_MONTH=$MONTH
export NL_END_DAY=$DAY
export NL_END_HOUR=$HOUR

export START_YEAR=$(echo $START_DATE | cut -c1-4)
export START_MONTH=$(echo $START_DATE | cut -c5-6)
export START_DAY=$(echo $START_DATE | cut -c7-8)
export START_HOUR=$(echo $START_DATE | cut -c9-10)

export END_YEAR=$(echo $END_DATE | cut -c1-4)
export END_MONTH=$(echo $END_DATE | cut -c5-6)
export END_DAY=$(echo $END_DATE | cut -c7-8)
export END_HOUR=$(echo $END_DATE | cut -c9-10)

export NL_TIME_WINDOW_MIN=${NL_TIME_WINDOW_MIN:-${START_YEAR}-${START_MONTH}-${START_DAY}_${START_HOUR}:00:00.0000}
export NL_TIME_WINDOW_MAX=${NL_TIME_WINDOW_MAX:-${END_YEAR}-${END_MONTH}-${END_DAY}_${END_HOUR}:00:00.0000}

if $NL_VAR4D; then

   export NL_START_YEAR=$(echo $START_DATE | cut -c1-4)
   export NL_START_MONTH=$(echo $START_DATE | cut -c5-6)
   export NL_START_DAY=$(echo $START_DATE | cut -c7-8)
   export NL_START_HOUR=$(echo $START_DATE | cut -c9-10)

   export NL_END_YEAR=$(echo $END_DATE | cut -c1-4)
   export NL_END_MONTH=$(echo $END_DATE | cut -c5-6)
   export NL_END_DAY=$(echo $END_DATE | cut -c7-8)
   export NL_END_HOUR=$(echo $END_DATE | cut -c9-10)

fi

#-----------------------------------------------------------------------
# [2.0] Perform sanity checks:
#-----------------------------------------------------------------------

if [[ ! -r $DA_FIRST_GUESS ]]; then
   echo "${ERR}First Guess file >$DA_FIRST_GUESS< does not exist:$END"
   exit 1
fi

if [[ ! -d $OB_DIR ]]; then
   echo "${ERR}Observation directory >$OB_DIR< does not exist:$END"
   exit 1
fi

if [[ ! -r $DA_BACK_ERRORS ]]; then
   echo "${ERR}Background Error file >$DA_BACK_ERRORS< does not exist:$END"
   exit 1
fi

#-----------------------------------------------------------------------
# [3.0] Prepare for assimilation:
#-----------------------------------------------------------------------

if [[ -d $DA_RTTOV_COEFFS ]]; then
   ln -fs $DA_RTTOV_COEFFS/* .
fi

if [[ -d $DA_CRTM_COEFFS ]]; then
   ln -fs $DA_CRTM_COEFFS crtm_coeffs
fi

ln -fs $WRFVAR_DIR/run/gribmap.txt .
ln -fs $WRFVAR_DIR/run/*.TBL .
ln -fs $WRFVAR_DIR/run/RRTM_DATA_DBL RRTM_DATA
ln -fs $WRFVAR_DIR/run/gmao_airs_bufr.tbl .
ln -fs $WRFVAR_DIR/build/da_wrfvar.exe .
export PATH=$WRFVAR_DIR/scripts:$PATH

if $NL_VAR4D; then
   ln -fs $DA_BOUNDARIES wrfbdy_d01
fi
ln -fs $DA_FIRST_GUESS fg01
ln -fs $DA_FIRST_GUESS wrfinput_d01
ln -fs $DA_BACK_ERRORS be.dat

for FILE in $DAT_DIR/*.inv; do
   if [[ -f $FILE ]]; then
      ln -fs $FILE .
   fi
done

if [[ -d $BIASCORR_DIR ]]; then
   ln -fs $BIASCORR_DIR biascorr
fi

if [[ -d $OBS_TUNING_DIR ]]; then
   ln -fs $OBS_TUNING_DIR/* .
fi

ln -fs $WRFVAR_DIR/run/radiance_info .

if [[ $NL_NUM_FGAT_TIME -gt 1 ]]; then
   if $NL_VAR4D; then
      # More than one observation file of each type
      ln -fs $OB_DIR/${D_DATE[01]}/ob.ascii+ ob01.ascii
      for I in 02 03 04 05 06; do
         ln -fs $OB_DIR/${D_DATE[$I]}/ob.ascii ob${I}.ascii
      done
      ln -fs $OB_DIR/${D_DATE[07]}/ob.ascii- ob07.ascii

      if [[ -e $OB_DIR/${D_DATE[01]}/ob.ssmi+ ]]; then
         ln -fs $OB_DIR/${D_DATE[01]}/ob.ssmi+ ob01.ssmi
         for I in 02 03 04 05 06; do
            ln -fs $OB_DIR/${D_DATE[$I]}/ob.ssmi ob${I}.ssmi
         done
         ln -fs $OB_DIR/${D_DATE[07]}/ob.ssmi- ob07.ssmi
      fi

      if [[ -e $OB_DIR/${D_DATE[01]}/ob.radar+ ]]; then
         ln -fs $OB_DIR/${D_DATE[01]}/ob.radar+ ob01.radar
         for I in 02 03 04 05 06; do
            ln -fs $OB_DIR/${D_DATE[$I]}/ob.radar ob${I}.radar
         done
         ln -fs $OB_DIR/${D_DATE[07]}/ob.radar- ob07.radar
      fi
   else
      if [[ $DATE -eq $START_DATE ]]; then
         ln -fs $OB_DIR/$DATE/ob.ascii+ ob01.ascii
      else
         ln -fs $OB_DIR/$DATE/ob.ascii  ob01.ascii
      fi
      typeset -i N
      let N=1
      FGAT_DATE=$START_DATE
      # while [[ $FGAT_DATE < $END_DATE || $FGAT_DATE -eq $END_DATE ]] ; do
      until [[ $FGAT_DATE > $END_DATE ]]; do
         if [[ $FGAT_DATE -ne $DATE ]]; then
            let N=$N+1
            if [[ $FGAT_DATE -eq $START_DATE ]]; then
               ln -fs $OB_DIR/$FGAT_DATE/ob.ascii+ ob0${N}.ascii
            elif [[ $FGAT_DATE -eq $END_DATE ]]; then
               ln -fs $OB_DIR/$FGAT_DATE/ob.ascii- ob0${N}.ascii
            else
               ln -fs $OB_DIR/$FGAT_DATE/ob.ascii ob0${N}.ascii
            fi
            FYEAR=$(echo ${FGAT_DATE} | cut -c1-4)
            FMONTH=$(echo ${FGAT_DATE} | cut -c5-6)
            FDAY=$(echo ${FGAT_DATE} | cut -c7-8)
            FHOUR=$(echo ${FGAT_DATE} | cut -c9-10)
            ln -fs ${FC_DIR}/${PREV_DATE}/wrfinput_d01_${FYEAR}-${FMONTH}-${FDAY}_${FHOUR}:00:00 fg0${N}
         fi
         FGAT_DATE=$($WRFVAR_DIR/build/da_advance_time.exe $FGAT_DATE $OBS_FREQ)
      done
   fi
else
   ln -fs $OB_DIR/${DATE}/ob.ascii  ob01.ascii
   if [[ -e $OB_DIR/${DATE}/ob.ssmi ]]; then
      ln -fs $OB_DIR/${DATE}/ob.ssmi ob01.ssmi
   fi
   if [[ -e $OB_DIR/${DATE}/ob.radar ]]; then
      ln -fs $OB_DIR/${DATE}/ob.radar ob01.radar
   fi
fi

for FILE in $OB_DIR/$DATE/*.bufr; do
   if [[ -f $FILE ]]; then
      ln -fs $FILE .
   fi
done

if $NL_VAR4D; then
   # Create nl, tl, ad links structures
   mkdir nl tl ad

   # nl

   # Inputs
   export NL_AUXHIST2_OUTNAME='auxhist2_d<domain>_<date>'
   if [[ $NUM_PROCS -gt 1 ]]; then
      export NL_AUXHIST2_OUTNAME='./nl/auxhist2_d<domain>_<date>'
   fi
   export NL_DYN_OPT=2
   export NL_INPUT_OUTNAME='nl_d<domain>_<date>'
   if [[ $NUM_PROCS -gt 1 ]]; then
      export NL_INPUT_OUTNAME='./nl/nl_d<domain>_<date>'
   fi
   export NL_INPUTOUT_INTERVAL=60
   let NL_AUXHIST2_INTERVAL=$NL_TIME_STEP/60
   export NL_FRAMES_PER_AUXHIST2=1
   export NL_HISTORY_INTERVAL=9999
   export NL_RESTART=false
   export NL_FRAMES_PER_OUTFILE=1000
   export NL_INPUT_FROM_FILE=true
   export NL_WRITE_INPUT=true
   export NL_DEBUG_LEVEL=0

   export NL_SMOOTH_OPTION=0
   export NL_MP_PHYSICS=3
   export NL_RA_LW_PHYSICS=1
   export NL_RA_SW_PHYSICS=1
   export NL_SF_SFCLAY_PHYSICS=1
   export NL_BL_PBL_PHYSICS=1
   export NL_BLDT=0
   export NL_CU_PHYSICS=1
   export NL_CUDT=5
   export NL_ISFFLX=1
   export NL_ICLOUD=1
   export NL_MP_ZERO_OUT=2
   export NL_W_DAMPING=1
   export NL_DIFF_OPT=1
   export NL_KM_OPT=4
   export NL_DAMP_OPT=0
   export NL_DAMPCOEF=0.0
   export NL_SMDIV=0.1
   export NL_EMDIV=0.01
   export NL_TIME_STEP_SOUND=4
   export NL_SPECIFIED=true
   export NL_NESTED=false
   export NL_REAL_DATA_INIT_TYPE=1
   . $WRFNL_DIR/inc/namelist_script.inc 
   mv namelist.input nl
   export NL_DEBUG_LEVEL=0
   unset NL_AUXHIST2_OUTNAME
   unset NL_AUXHIST2_INTERVAL
   unset NL_FRAMES_PER_AUXHIST2
   ln -fs $WORK_DIR/*.TBL nl
   ln -fs $WORK_DIR/RRTM_DATA nl
   ln -fs $WORK_DIR/wrfbdy_d01 nl
   ln -fs $WORK_DIR/fg01 nl/wrfinput_d01
   # if [[ -e $WORK_DIR/wrfvar_output ]]; then
   #    ln -fs $WORK_DIR/wrfvar_output nl/wrfinput_d01
   # else
      ln -fs $WORK_DIR/fg01 nl/wrfinput_d01
   # fi
   ln -fs $WRFNL_DIR/main/wrf.exe nl

   # Outputs
   for I in 02 03 04 05 06 07; do
      ln -fs nl/nl_d01_${D_YEAR[$I]}-${D_MONTH[$I]}-${D_DAY[$I]}_${D_HOUR[$I]}:00:00 fg$I
   done

   # tl

   # Inputs

   export NL_DYN_OPT=202
   export NL_INPUT_OUTNAME='tl_d<domain>_<date>'
   export NL_AUXINPUT2_INNAME='../nl/auxhist2_d<domain>_<date>'
   if [[ $NUM_PROCS -gt 1 ]]; then
      export NL_INPUT_OUTNAME='./tl/tl_d<domain>_<date>'
      export NL_AUXINPUT2_INNAME='./nl/auxhist2_d<domain>_<date>'
   fi
   let NL_AUXINPUT2_INTERVAL=$NL_TIME_STEP/60
   export NL_MP_PHYSICS=0
   export NL_RA_LW_PHYSICS=0
   export NL_RA_SW_PHYSICS=0
   export NL_RADT_OLD=$NL_RADT
   export NL_RADT=0
   export NL_SF_SFCLAY_PHYSICS=0
   export NL_SF_SURFACE_PHYSICS_OLD=$NL_SF_SURFACE_PHYSICS
   export NL_SF_SURFACE_PHYSICS=0 # Just for tl/ad
   export NL_BL_PBL_PHYSICS=0
   export NL_BLDT=0
   export NL_CU_PHYSICS=0
   export NL_CUDT=0
   export NL_ISFFLX=0
   export NL_ICLOUD=0
   export NL_W_DAMPING=0
   export NL_DIFF_OPT=0
   export NL_DAMPCOEF=0.01
   . $WRFPLUS_DIR/inc/namelist_script.inc
   mv namelist.input tl
   ln -fs $WORK_DIR/*.TBL tl
   ln -fs $WORK_DIR/RRTM_DATA tl
   ln -fs $WORK_DIR/wrfbdy_d01 tl
   ln -fs $WORK_DIR/tl01 tl/wrfinput_d01
   ln -fs $WRFPLUS_DIR/main/wrfplus.exe tl
   mkdir tl/trace

   # Outputs
   for I in 02 03 04 05 06 07; do
      ln -fs tl/tl_d01_${D_YEAR[$I]}-${D_MONTH[$I]}-${D_DAY[$I]}_${D_HOUR[$I]}:00:00 tl$I
   done
   if [[ $NUM_PROCS -gt 1 ]]; then
      ln -fs auxhist3_d01_${NL_END_YEAR}-${NL_END_MONTH}-${NL_END_DAY}_${NL_END_HOUR}:00:00 tldf
   else
      ln -fs tl/auxhist3_d01_${NL_END_YEAR}-${NL_END_MONTH}-${NL_END_DAY}_${NL_END_HOUR}:00:00 tldf
   fi

   # ad

   # Inputs
   export NL_DYN_OPT=302
   export NL_INPUT_OUTNAME='ad_d<domain>_<date>'
   export NL_AUXINPUT2_INNAME='../nl/auxhist2_d<domain>_<date>'
   if [[ $NUM_PROCS -gt 1 ]]; then
      export NL_INPUT_OUTNAME='./ad/ad_d<domain>_<date>'
      export NL_AUXINPUT2_INNAME='./nl/auxhist2_d<domain>_<date>'
   fi
   let NL_AUXINPUT2_INTERVAL=$NL_TIME_STEP/60
   export NL_AUXINPUT3_INNAME='auxinput3_d<domain>_<date>'
   if [[ $NUM_PROCS -gt 1 ]]; then
      export NL_AUXINPUT3_INNAME='./ad/auxinput3_d<domain>_<date>'
   fi
   export NL_AUXINPUT3_INTERVAL=60
   export NL_HISTORY_INTERVAL=9999
   export NL_AUXHIST3_INTERVAL=60
   export NL_INPUTOUT_INTERVAL=60
   . $WRFPLUS_DIR/inc/namelist_script.inc
   mv namelist.input ad
   ln -fs $WORK_DIR/*.TBL ad
   ln -fs $WORK_DIR/RRTM_DATA ad
   ln -fs $WORK_DIR/wrfbdy_d01 ad
   ln -fs $WORK_DIR/fg01 ad/wrfinput_d01
   for I in 01 02 03 04 05 06 07; do
      ln -fs $WORK_DIR/af$I ad/auxinput3_d01_${D_YEAR[$I]}-${D_MONTH[$I]}-${D_DAY[$I]}_${D_HOUR[$I]}:00:00
   done
   # JRB
   # if $NL_JCDFI_USE; then
      ln -fs $WORK_DIR/auxhist3_d01_${D_YEAR[01]}-${D_MONTH[01]}-${D_DAY[01]}_${D_HOUR[01]}:00:00 ad/auxinput3_d01_${D_YEAR[$I]}-${D_MONTH[$I]}-${D_DAY[$I]}_${D_HOUR[$I]}:00:00_dfi
   # fi   
   ln -fs $WRFPLUS_DIR/main/wrfplus.exe ad
   mkdir ad/trace

   # Outputs
   ln -fs ad/ad_d01_${YEAR}-${MONTH}-${DAY}_${HOUR}:00:00 gr01

   export NL_DYN_OPT=2
   unset NL_MP_PHYSICS
   unset NL_RA_LW_PHYSICS
   unset NL_RA_SW_PHYSICS
   unset NL_SF_SFCLAY_PHYSICS
   unset NL_BL_PBL_PHYSICS
   unset NL_BLDT
   unset NL_CU_PHYSICS
   unset NL_CUDT
   unset NL_ISFFLX
   unset NL_ICLOUD
   # Restore values
   export NL_SF_SURFACE_PHYSICS=$NL_SF_SURFACE_PHYSICS_OLD
   export NL_RADT=$NL_RADT_OLD

fi

. $WRFVAR_DIR/build/inc/namelist_script.inc 

if $NL_VAR4D; then
   cp namelist.input $RUN_DIR/namelist_wrfvar.input
   cp nl/namelist.input $RUN_DIR/namelist_nl.input
   cp tl/namelist.input $RUN_DIR/namelist_tl.input
   cp ad/namelist.input $RUN_DIR/namelist_ad.input
   echo '<A HREF="namelist_wrfvar.input">WRFVAR namelist.input</a>'
   echo '<A HREF="namelist_nl.input">NL namelist.input</a>'
   echo '<A HREF="namelist_tl.input">TL namelist.input</a>'
   echo '<A HREF="namelist_ad.input">AD namelist.input</a>'
else
   cp namelist.input $RUN_DIR
   echo '<A HREF="namelist.input">Namelist.input</a>'
fi

#-------------------------------------------------------------------
#Run WRF-Var:
#-------------------------------------------------------------------
mkdir trace

if $DUMMY; then
   echo Dummy wrfvar
   echo "Dummy wrfvar" > $DA_ANALYSIS
   RC=0
else
   if $NL_VAR4D; then
      if [[ $NUM_PROCS -gt 1 ]]; then
         # JRB kludge until we work out what we are doing here
         if [[ $SUBMIT != "LSF" ]]; then
            echo "da_run_wrfvar.ksh: Can only handle LSF at present, aborting"
            exit 1
         fi
         export MP_PGMMODEL=mpmd
         export MP_CMDFILE=poe.cmdfile
         if [[ $NUM_PROCS -lt 3 ]]; then
            echo "Need at least 3 processors for 4dvar"
            exit 1
         fi
         export NUM_PROCS_VAR=${NUM_PROCS_VAR:-2}
         export NUM_PROCS_WRF=${NUM_PROCS_WRF:-2}
         let NUM_PROCS_WRFPLUS=$NUM_PROCS-$NUM_PROCS_VAR-$NUM_PROCS_WRF
         echo "NUM_PROCS_VAR                $NUM_PROCS_VAR"
         echo "NUM_PROCS_WRF                $NUM_PROCS_WRF"
         echo "NUM_PROCS_WRFPLUS            $NUM_PROCS_WRFPLUS"

         rm -f $MP_CMDFILE
         let I=0
         while [[ $I -lt $NUM_PROCS_VAR ]]; do
            echo "da_wrfvar.exe" >> $MP_CMDFILE
            let I=$I+1
         done
         while [[ $I -lt $NUM_PROCS_VAR+$NUM_PROCS_WRF ]]; do
            echo "./nl/wrf.exe" >> $MP_CMDFILE
            let I=$I+1
         done
         while [[ $I -lt $NUM_PROCS ]]; do
            echo "./ad/wrfplus.exe" >> $MP_CMDFILE
            let I=$I+1
         done
         mpirun.lsf -cmdfile poe.cmdfile
         RC=$?
      else
         $RUN_CMD ./da_wrfvar.exe
         RC=$?
      fi
   else
      # 3DVAR
      $RUN_CMD ./da_wrfvar.exe
      RC=$?
   fi

   if [[ -f statistics ]]; then
      cp statistics $RUN_DIR
   fi

   if [[ -f cost_fn ]]; then 
      cp cost_fn $RUN_DIR
   fi

   if [[ -f grad_fn ]]; then
      cp grad_fn $RUN_DIR
   fi

   if [[ -f ob.etkf.000 ]]; then
      cp ob.etkf.000 $RUN_DIR
   fi

   # remove intermediate output files

   rm -f unpert_obs.*
   rm -f pert_obs.*
   rm -f rand_obs_error.*
   rm -f gts_omb_oma.*
   rm -f qcstat_*.*
   # No routine to merge these files across processors yet
   # rm -f inv_*.*
   # rm -f oma_*.*
   # rm -f filtered_*.*

   if [[ -f wrfvar_output ]]; then
      if [[ $DA_ANALYSIS != wrfvar_output ]]; then 
         mv wrfvar_output $DA_ANALYSIS
      fi
   fi

   if [[ -d trace ]]; then
      mkdir -p $RUN_DIR/trace
      mv trace/* $RUN_DIR/trace
   fi

   rm -rf $RUN_DIR/rsl
   mkdir -p $RUN_DIR/rsl
   cd $RUN_DIR/rsl
   for FILE in $WORK_DIR/rsl*; do
      if [[ -f $FILE ]]; then
         FILE1=$(basename $FILE)
         echo "<HTML><HEAD><TITLE>$FILE1</TITLE></HEAD>" > $FILE1.html
         echo "<H1>$FILE1</H1><PRE>" >> $FILE1.html
         cat $FILE >> $FILE1.html
         echo "</PRE></BODY></HTML>" >> $FILE1.html
         rm $FILE
      fi
   done
   cd $RUN_DIR

   if $NL_VAR4D; then
      cp $WORK_DIR/namelist_wrfvar.output namelist_wrfvar.output
      cp $WORK_DIR/nl/namelist.output     namelist_nl.output
      cp $WORK_DIR/tl/namelist.output     namelist_tl.output
      cp $WORK_DIR/ad/namelist.output     namelist_ad.output
      echo '<A HREF="namelist_wrfvar.output">WRFVAR namelist.output</a>'
      echo '<A HREF="namelist_nl.output">NL namelist.output</a>'
      echo '<A HREF="namelist_tl.output">TL namelist.output</a>'
      echo '<A HREF="namelist_ad.output">AD namelist.output</a>'
   else
      cp $WORK_DIR/namelist.output .
      echo '<A HREF="namelist.output">Namelist.output</a>'
   fi

   echo '<A HREF="rsl/rsl.out.0000.html">rsl.out.0000</a>'
   echo '<A HREF="rsl/rsl.error.0000.html">rsl.error.0000</a>'
   echo '<A HREF="rsl">Other RSL output</a>'
   echo '<A HREF="trace/0.html">PE 0 trace</a>'
   echo '<A HREF="trace">Other tracing</a>'
   echo '<A HREF="cost_fn">Cost function</a>'
   echo '<A HREF="grad_fn">Gradient function</a>'
   echo '<A HREF="statistics">Statistics</a>'

   cat $RUN_DIR/cost_fn

   echo $(date +'%D %T') "Ended $RC"
fi

# We never look at core files

for DIR in $WORK_DIR/coredir.*; do
   if [[ -d $DIR ]]; then
      rm -rf $DIR
   fi
done

if $CLEAN; then
   rm -rf $WORK_DIR
fi

echo '</PRE></BODY></HTML>'

exit $RC
