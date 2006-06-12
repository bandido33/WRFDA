#	Top level Makefile for wrf system

include ./configure.wrf

deflt :
		@ echo Please compile the code using ./compile

EM_MODULE_DIR = -I$(DYN_EM)
EM_MODULES =  $(EM_MODULE_DIR)

DA_WRFVAR_MODULES = $(INCLUDE_MODULES)
DA_WRFVAR_MODULES_2 = $(INC_MOD_WRFVAR)

#JRB -p is not a valid option on Linux or Aix, I wonder
# what it was for?
#DA_CONVERTOR_MOD_DIR = -I$(CONVERTOR) -p$(CONVERTOR)
DA_CONVERTOR_MOD_DIR = -I$(CONVERTOR)
DA_CONVERTOR_MODULES = $(DA_CONVERTOR_MOD_DIR) $(INCLUDE_MODULES)

#### 3.d.   add macros to specify the modules for this core

#EXP_MODULE_DIR = -I$(DYN_EXP)
#EXP_MODULES =  $(EXP_MODULE_DIR)


NMM_MODULE_DIR = -I$(DYN_NMM)
NMM_MODULES =  $(NMM_MODULE_DIR)

ALL_MODULES =                           \
               $(EM_MODULE_DIR)         \
               $(NMM_MODULES)           \
               $(EXP_MODULES)           \
               $(INCLUDE_MODULES)

configcheck:
	@if [ "$(A2DCASE)" -a "$(DMPARALLEL)" ] ; then \
	 echo "------------------------------------------------------------------------------" ; \
	 echo "WRF CONFIGURATION ERROR                                                       " ; \
	 echo "The $(A2DCASE) case cannot be used on distributed memory parallel systems." ; \
	 echo "Only 3D WRF cases will run on these systems." ; \
	 echo "Please chose a different case or rerun configure and chose a different option."  ; \
	 echo "------------------------------------------------------------------------------" ; \
         exit 2 ; \
	fi

framework_only : configcheck
	$(MAKE) MODULE_DIRS="$(ALL_MODULES)" ext
	$(MAKE) MODULE_DIRS="$(ALL_MODULES)" toolsdir
	/bin/rm -f main/libwrflib.a
	$(MAKE) MODULE_DIRS="$(ALL_MODULES)" framework
	$(MAKE) MODULE_DIRS="$(ALL_MODULES)" shared

#TBH:  for now, build wrf.exe, wrf_ESMFApp.exe, and wrf_SST_ESMF.exe when ESMF_COUPLING is set
#TBH:  Either wrf.exe or wrf_ESMFApp.exe can be used for stand-alone testing in this case
#TBH:  wrf_SST_ESMF.exe is a coupled application
wrf : framework_only
	$(MAKE) MODULE_DIRS="$(ALL_MODULES)" physics
	if [ $(WRF_CHEM) -eq 1 ]    ; then $(MAKE) MODULE_DIRS="$(ALL_MODULES)" chemics ; fi
	if [ $(WRF_EM_CORE) -eq 1 ]    ; then $(MAKE) MODULE_DIRS="$(ALL_MODULES)" em_core ; fi
	if [ $(WRF_NMM_CORE) -eq 1 ]   ; then $(MAKE) MODULE_DIRS="$(ALL_MODULES)" nmm_core ; fi
	if [ $(WRF_EXP_CORE) -eq 1 ]   ; then $(MAKE) MODULE_DIRS="$(ALL_MODULES)" exp_core ; fi
	( cd main ; $(MAKE) MODULE_DIRS="$(ALL_MODULES)" SOLVER=em em_wrf )
	( cd run ; /bin/rm -f wrf.exe ; ln -s $(MAIN)/wrf.exe . )
	if [ $(ESMF_COUPLING) -eq 1 ] ; then \
	  ( cd main ; $(MAKE) MODULE_DIRS="$(ALL_MODULES)" SOLVER=em em_wrf_ESMFApp ) ; \
	  ( cd run ; /bin/rm -f wrf_ESMFApp.exe ; ln -s $(MAIN)/wrf_ESMFApp.exe . ) ; \
	  ( cd run ; /bin/rm -f wrf_SST_ESMF.exe ; ln -s $(MAIN)/wrf_SST_ESMF.exe . ) ; \
	fi

wrfplus : framework_only
	$(MAKE) MODULE_DIRS="$(ALL_MODULES)" physics
	if [ $(WRF_CHEM) -eq 1 ]    ; then $(MAKE) MODULE_DIRS="$(ALL_MODULES)" chemics ; fi
	if [ $(WRF_EM_CORE) -eq 1 ]    ; then $(MAKE) MODULE_DIRS="$(ALL_MODULES)" em_core ; fi
	if [ $(WRF_NMM_CORE) -eq 1 ]   ; then $(MAKE) MODULE_DIRS="$(ALL_MODULES)" nmm_core ; fi
	if [ $(WRF_EXP_CORE) -eq 1 ]   ; then $(MAKE) MODULE_DIRS="$(ALL_MODULES)" exp_core ; fi
	( cd main ; $(MAKE) MODULE_DIRS="$(ALL_MODULES)" SOLVER=em em_wrfplus )
	( cd run ; /bin/rm -f wrfplus.exe ; ln -s $(MAIN)/wrfplus.exe . )
	if [ $(ESMF_COUPLING) -eq 1 ] ; then \
	  ( cd main ; $(MAKE) MODULE_DIRS="$(ALL_MODULES)" SOLVER=em em_wrf_ESMFApp ) ; \
	  ( cd run ; /bin/rm -f wrf_ESMFApp.exe ; ln -s $(MAIN)/wrf_ESMFApp.exe . ) ; \
	  ( cd run ; /bin/rm -f wrf_SST_ESMF.exe ; ln -s $(MAIN)/wrf_SST_ESMF.exe . ) ; \
	fi

var : wrfvar

wrfvar : framework_only
	$(MAKE) MODULE_DIRS="$(DA_WRFVAR_MODULES)" wrfvar_src
	( cd main ; $(MAKE) MODULE_DIRS="$(DA_WRFVAR_MODULES)" wrfvar )

pure_var : 
	@ echo 'This option assumes that you have already compiled the WRF frame part correctly.'
	@ echo 'If you have not done so, please use compile var'
	$(MAKE) MODULE_DIRS="$(DA_WRFVAR_MODULES)" wrfvar_io
	$(MAKE) MODULE_DIRS="$(DA_WRFVAR_MODULES)" wrfvar_src
	$(MAKE) MODULE_DIRS="$(DA_WRFVAR_MODULES)" wrfvar_interface
	( cd main ; $(MAKE) MODULE_DIRS="$(DA_WRFVAR_MODULES)" wrfvar )

k2n : framework_only
	$(MAKE) MODULE_DIRS="$(ALL_MODULES)" physics
	$(MAKE) MODULE_DIRS="$(ALL_MODULES)" em_core
	$(MAKE) MODULE_DIRS="$(DA_WRFVAR_MODULES)" wrfvar_io
	$(MAKE) MODULE_DIRS="$(DA_CONVERTOR_MODULES)" convertor_drivers
	( cd main ; \
          /bin/rm -f kma2netcdf.exe ; \
	  $(MAKE) MODULE_DIRS="$(DA_CONVERTOR_MODULES)" kma2netcdf )

n2k : framework_only
	$(MAKE) MODULE_DIRS="$(ALL_MODULES)" physics
	$(MAKE) MODULE_DIRS="$(ALL_MODULES)" em_core
	$(MAKE) MODULE_DIRS="$(DA_WRFVAR_MODULES)" wrfvar_io
	$(MAKE) MODULE_DIRS="$(DA_CONVERTOR_MODULES)" convertor_drivers
	( cd main ; \
          /bin/rm -f netcdf2kma.exe ; \
	  $(MAKE) MODULE_DIRS="$(DA_CONVERTOR_MODULES)" netcdf2kma )

BE_OBJS = da_gen_be.o da_constants.o da_be_spectral.o lapack.o blas.o fftpack5.o
BE_MODULES1 = -I$(FRAME)
BE_MODULES2 = -I$(DA) -I$(FRAME)
be : 
	( cd tools; $(MAKE) FC="$(FC)" FCFLAGS="$(FCFLAGS)" advance_cymdh registry )
	( cd frame; $(MAKE) MODULE_DIRS="$(DA_WRFVAR_MODULES)" module_wrf_error.o externals \
          module_state_description.o module_driver_constants.o )
	( cd da; $(MAKE) MODULE_DIRS="$(BE_MODULES1)" $(BE_OBJS) da_gen_be.o )
	( cd gen_be ; \
	$(RM) *.exe ; \
	$(MAKE) MODULE_DIRS="$(BE_MODULES2)" gen_be )

### 3.a.  rules to build the framework and then the experimental core

exp_wrf : framework_only
	( cd main ; $(MAKE) MODULE_DIRS="$(ALL_MODULES)" SOLVER=exp exp_wrf )


nmm_wrf : wrf


#  Eulerian mass coordinate initializations

#TBH:  for now, link wrf.exe, wrf_ESMFApp.exe, and wrf_SST_ESMF.exe when ESMF_COUPLING is set
#TBH:  Either wrf.exe or wrf_ESMFApp.exe can be used for stand-alone testing in this case
#TBH:  wrf_SST_ESMF.exe is a coupled application
em_quarter_ss : wrf
	@ echo '--------------------------------------'
	( cd main ; $(MAKE) MODULE_DIRS="$(ALL_MODULES)" SOLVER=em IDEAL_CASE=quarter_ss em_ideal )
	( cd test/em_quarter_ss ; /bin/rm -f wrf.exe ; ln -s $(MAIN)/wrf.exe . )
	if [ $(ESMF_COUPLING) -eq 1 ] ; then \
	  ( cd test/em_quarter_ss ; /bin/rm -f wrf_ESMFApp.exe ; ln -s $(MAIN)/wrf_ESMFApp.exe . ) ; \
	  ( cd test/em_quarter_ss ; /bin/rm -f wrf_SST_ESMF.exe ; ln -s $(MAIN)/wrf_SST_ESMF.exe . ) ; \
	fi
	( cd test/em_quarter_ss ; /bin/rm -f ideal.exe ; ln -s $(MAIN)/ideal.exe . )
	( cd test/em_quarter_ss ; /bin/rm -f README.namelist ; ln -s ../../run/README.namelist . )
	( cd test/em_quarter_ss ; /bin/rm -f gribmap.txt ; ln -s ../../run/gribmap.txt . )
	( cd test/em_quarter_ss ; /bin/rm -f grib2map.tbl ; ln -s ../../run/grib2map.tbl . )
	( cd run ; /bin/rm -f ideal.exe ; ln -s $(MAIN)/ideal.exe . )
	( cd run ; /bin/rm -f namelist.input ; ln -s ../test/em_quarter_ss/namelist.input . )
	( cd run ; /bin/rm -f input_sounding ; ln -s ../test/em_quarter_ss/input_sounding . )

#TBH:  for now, link wrf.exe, wrf_ESMFApp.exe, and wrf_SST_ESMF.exe when ESMF_COUPLING is set
#TBH:  Either wrf.exe or wrf_ESMFApp.exe can be used for stand-alone testing in this case
#TBH:  wrf_SST_ESMF.exe is a coupled application
em_squall2d_x : wrf
	@ echo '--------------------------------------'
	( cd main ; $(MAKE) MODULE_DIRS="$(ALL_MODULES)" SOLVER=em IDEAL_CASE=squall2d_x em_ideal )
	( cd test/em_squall2d_x ; /bin/rm -f wrf.exe ; ln -s $(MAIN)/wrf.exe . )
	if [ $(ESMF_COUPLING) -eq 1 ] ; then \
	  ( cd test/em_squall2d_x ; /bin/rm -f wrf_ESMFApp.exe ; ln -s $(MAIN)/wrf_ESMFApp.exe . ) ; \
	  ( cd test/em_squall2d_x ; /bin/rm -f wrf_SST_ESMF.exe ; ln -s $(MAIN)/wrf_SST_ESMF.exe . ) ; \
	fi
	( cd test/em_squall2d_x ; /bin/rm -f ideal.exe ; ln -s $(MAIN)/ideal.exe . )
	( cd test/em_squall2d_x ; /bin/rm -f README.namelist ; ln -s ../../run/README.namelist . )
	( cd test/em_squall2d_x ; /bin/rm -f gribmap.txt ; ln -s ../../run/gribmap.txt . )
	( cd test/em_squall2d_x ; /bin/rm -f grib2map.tbl ; ln -s ../../run/grib2map.tbl . )
	( cd run ; /bin/rm -f ideal.exe ; ln -s $(MAIN)/ideal.exe . )
	( cd run ; /bin/rm -f namelist.input ; ln -s ../test/em_squall2d_x/namelist.input . )
	( cd run ; /bin/rm -f input_sounding ; ln -s ../test/em_squall2d_x/input_sounding . )


#TBH:  for now, link wrf.exe, wrf_ESMFApp.exe, and wrf_SST_ESMF.exe when ESMF_COUPLING is set
#TBH:  Either wrf.exe or wrf_ESMFApp.exe can be used for stand-alone testing in this case
#TBH:  wrf_SST_ESMF.exe is a coupled application
em_squall2d_y : wrf
	@ echo '--------------------------------------'
	( cd main ; $(MAKE) MODULE_DIRS="$(ALL_MODULES)" SOLVER=em IDEAL_CASE=squall2d_y em_ideal )
	( cd test/em_squall2d_y ; /bin/rm -f wrf.exe ; ln -s $(MAIN)/wrf.exe . )
	if [ $(ESMF_COUPLING) -eq 1 ] ; then \
	  ( cd test/em_squall2d_y ; /bin/rm -f wrf_ESMFApp.exe ; ln -s $(MAIN)/wrf_ESMFApp.exe . ) ; \
	  ( cd test/em_squall2d_y ; /bin/rm -f wrf_SST_ESMF.exe ; ln -s $(MAIN)/wrf_SST_ESMF.exe . ) ; \
	fi
	( cd test/em_squall2d_y ; /bin/rm -f ideal.exe ; ln -s $(MAIN)/ideal.exe . )
	( cd test/em_squall2d_y ; /bin/rm -f README.namelist ; ln -s ../../run/README.namelist . )
	( cd test/em_squall2d_y ; /bin/rm -f gribmap.txt ; ln -s ../../run/gribmap.txt . )
	( cd test/em_squall2d_y ; /bin/rm -f grib2map.tbl ; ln -s ../../run/grib2map.tbl . )
	( cd run ; /bin/rm -f ideal.exe ; ln -s $(MAIN)/ideal.exe . )
	( cd run ; /bin/rm -f namelist.input ; ln -s ../test/em_squall2d_y/namelist.input . )
	( cd run ; /bin/rm -f input_sounding ; ln -s ../test/em_squall2d_y/input_sounding . )

#TBH:  for now, link wrf.exe, wrf_ESMFApp.exe, and wrf_SST_ESMF.exe when ESMF_COUPLING is set
#TBH:  Either wrf.exe or wrf_ESMFApp.exe can be used for stand-alone testing in this case
#TBH:  wrf_SST_ESMF.exe is a coupled application
em_b_wave : wrf
	@ echo '--------------------------------------'
	( cd main ; $(MAKE) MODULE_DIRS="$(ALL_MODULES)" SOLVER=em IDEAL_CASE=b_wave em_ideal )
	( cd test/em_b_wave ; /bin/rm -f wrf.exe ; ln -s $(MAIN)/wrf.exe . )
	if [ $(ESMF_COUPLING) -eq 1 ] ; then \
	  ( cd test/em_b_wave ; /bin/rm -f wrf_ESMFApp.exe ; ln -s $(MAIN)/wrf_ESMFApp.exe . ) ; \
	  ( cd test/em_b_wave ; /bin/rm -f wrf_SST_ESMF.exe ; ln -s $(MAIN)/wrf_SST_ESMF.exe . ) ; \
	fi
	( cd test/em_b_wave ; /bin/rm -f ideal.exe ; ln -s $(MAIN)/ideal.exe . )
	( cd test/em_b_wave ; /bin/rm -f README.namelist ; ln -s ../../run/README.namelist . )
	( cd test/em_b_wave ; /bin/rm -f gribmap.txt ; ln -s ../../run/gribmap.txt . )
	( cd test/em_b_wave ; /bin/rm -f grib2map.tbl ; ln -s ../../run/grib2map.tbl . )
	( cd run ; /bin/rm -f ideal.exe ; ln -s $(MAIN)/ideal.exe . )
	( cd run ; /bin/rm -f namelist.input ; ln -s ../test/em_b_wave/namelist.input . )
	( cd run ; /bin/rm -f input_jet ; ln -s ../test/em_b_wave/input_jet . )

convert_em : framework_only
	if [ $(WRF_CONVERT) -eq 1 ] ; then \
            ( cd main ; $(MAKE) MODULE_DIRS="$(ALL_MODULES)" convert_em ) ; \
        fi

#TBH:  for now, link wrf.exe, wrf_ESMFApp.exe, and wrf_SST_ESMF.exe when ESMF_COUPLING is set
#TBH:  Either wrf.exe or wrf_ESMFApp.exe can be used for stand-alone testing in this case
#TBH:  wrf_SST_ESMF.exe is a coupled application
em_real : wrf
	@ echo '--------------------------------------'
	( cd main ; $(MAKE) MODULE_DIRS="$(ALL_MODULES)" SOLVER=em IDEAL_CASE=real em_real )
	( cd test/em_real ; /bin/rm -f wrf.exe ; ln -s $(MAIN)/wrf.exe . )
	if [ $(ESMF_COUPLING) -eq 1 ] ; then \
	  ( cd test/em_real ; /bin/rm -f wrf_ESMFApp.exe ; ln -s $(MAIN)/wrf_ESMFApp.exe . ) ; \
	  ( cd test/em_real ; /bin/rm -f wrf_SST_ESMF.exe ; ln -s $(MAIN)/wrf_SST_ESMF.exe . ) ; \
	fi
	( cd test/em_real ; /bin/rm -f real.exe ; ln -s $(MAIN)/real.exe . )
	( cd test/em_real ; /bin/rm -f ndown.exe ; ln -s $(MAIN)/ndown.exe . )
	( cd test/em_real ; /bin/rm -f nup.exe ; ln -s $(MAIN)/nup.exe . )
	( cd test/em_real ; /bin/rm -f README.namelist ; ln -s ../../run/README.namelist . )
	( cd test/em_real ; /bin/rm -f ETAMPNEW_DATA RRTM_DATA ;    \
             ln -sf ../../run/ETAMPNEW_DATA . ;                     \
             ln -sf ../../run/RRTM_DATA . ;                         \
             if [ $(RWORDSIZE) -eq 8 ] ; then                       \
                ln -sf ../../run/ETAMPNEW_DATA_DBL ETAMPNEW_DATA ;  \
                ln -sf ../../run/RRTM_DATA_DBL RRTM_DATA ;          \
             fi )
	( cd test/em_real ; /bin/rm -f GENPARM.TBL ; ln -s ../../run/GENPARM.TBL . )
	( cd test/em_real ; /bin/rm -f LANDUSE.TBL ; ln -s ../../run/LANDUSE.TBL . )
	( cd test/em_real ; /bin/rm -f SOILPARM.TBL ; ln -s ../../run/SOILPARM.TBL . )
	( cd test/em_real ; /bin/rm -f VEGPARM.TBL ; ln -s ../../run/VEGPARM.TBL . )
	( cd test/em_real ; /bin/rm -f tr49t67 ; ln -s ../../run/tr49t67 . )
	( cd test/em_real ; /bin/rm -f tr49t85 ; ln -s ../../run/tr49t85 . )
	( cd test/em_real ; /bin/rm -f tr67t85 ; ln -s ../../run/tr67t85 . )
	( cd test/em_real ; /bin/rm -f gribmap.txt ; ln -s ../../run/gribmap.txt . )
	( cd test/em_real ; /bin/rm -f grib2map.tbl ; ln -s ../../run/grib2map.tbl . )
	( cd run ; /bin/rm -f real.exe ; ln -s $(MAIN)/real.exe . )
	( cd run ; /bin/rm -f ndown.exe ; ln -s $(MAIN)/ndown.exe . )
	( cd run ; /bin/rm -f nup.exe ; ln -s $(MAIN)/nup.exe . )
	( cd run ; /bin/rm -f namelist.input ; ln -s ../test/em_real/namelist.input . )


#TBH:  for now, link wrf.exe, wrf_ESMFApp.exe, and wrf_SST_ESMF.exe when ESMF_COUPLING is set
#TBH:  Either wrf.exe or wrf_ESMFApp.exe can be used for stand-alone testing in this case
#TBH:  wrf_SST_ESMF.exe is a coupled application
em_hill2d_x : wrf
	@ echo '--------------------------------------'
	( cd main ; $(MAKE) MODULE_DIRS="$(ALL_MODULES)" SOLVER=em IDEAL_CASE=hill2d_x em_ideal )
	( cd test/em_hill2d_x ; /bin/rm -f wrf.exe ; ln -s $(MAIN)/wrf.exe . )
	if [ $(ESMF_COUPLING) -eq 1 ] ; then \
	  ( cd test/em_hill2d_x ; /bin/rm -f wrf_ESMFApp.exe ; ln -s $(MAIN)/wrf_ESMFApp.exe . ) ; \
	  ( cd test/em_hill2d_x ; /bin/rm -f wrf_SST_ESMF.exe ; ln -s $(MAIN)/wrf_SST_ESMF.exe . ) ; \
	fi
	( cd test/em_hill2d_x ; /bin/rm -f ideal.exe ; ln -s $(MAIN)/ideal.exe . )
	( cd test/em_hill2d_x ; /bin/rm -f README.namelist ; ln -s ../../run/README.namelist . )
	( cd test/em_hill2d_x ; /bin/rm -f gribmap.txt ; ln -s ../../run/gribmap.txt . )
	( cd test/em_hill2d_x ; /bin/rm -f grib2map.tbl ; ln -s ../../run/grib2map.tbl . )
	( cd run ; /bin/rm -f ideal.exe ; ln -s $(MAIN)/ideal.exe . )
	( cd run ; /bin/rm -f namelist.input ; ln -s ../test/em_hill2d_x/namelist.input . )
	( cd run ; /bin/rm -f input_sounding ; ln -s ../test/em_hill2d_x/input_sounding . )



#TBH:  for now, link wrf.exe, wrf_ESMFApp.exe, and wrf_SST_ESMF.exe when ESMF_COUPLING is set
#TBH:  Either wrf.exe or wrf_ESMFApp.exe can be used for stand-alone testing in this case
#TBH:  wrf_SST_ESMF.exe is a coupled application
em_grav2d_x : wrf
	@ echo '--------------------------------------'
	( cd main ; $(MAKE) MODULE_DIRS="$(ALL_MODULES)" SOLVER=em IDEAL_CASE=grav2d_x em_ideal )
	( cd test/em_grav2d_x ; /bin/rm -f wrf.exe ; ln -s $(MAIN)/wrf.exe . )
	if [ $(ESMF_COUPLING) -eq 1 ] ; then \
	  ( cd test/em_grav2d_x ; /bin/rm -f wrf_ESMFApp.exe ; ln -s $(MAIN)/wrf_ESMFApp.exe . ) ; \
	  ( cd test/em_grav2d_x ; /bin/rm -f wrf_SST_ESMF.exe ; ln -s $(MAIN)/wrf_SST_ESMF.exe . ) ; \
	fi
	( cd test/em_grav2d_x ; /bin/rm -f ideal.exe ; ln -s $(MAIN)/ideal.exe . )
	( cd test/em_grav2d_x ; /bin/rm -f README.namelist ; ln -s ../../run/README.namelist . )
	( cd test/em_grav2d_x ; /bin/rm -f gribmap.txt ; ln -s ../../run/gribmap.txt . )
	( cd test/em_grav2d_x ; /bin/rm -f grib2map.tbl ; ln -s ../../run/grib2map.tbl . )
	( cd run ; /bin/rm -f ideal.exe ; ln -s $(MAIN)/ideal.exe . )
	( cd run ; /bin/rm -f namelist.input ; ln -s ../test/em_grav2d_x/namelist.input . )
	( cd run ; /bin/rm -f input_sounding ; ln -s ../test/em_grav2d_x/input_sounding . )

#### anthropogenic emissions converter

emi_conv : wrf
	@ echo '--------------------------------------'
	( cd chem ; $(MAKE) MODULE_DIRS="$(ALL_MODULES)" SOLVER=em IDEAL_CASE=real convert_emiss )
	( cd test/em_real ; /bin/rm -f convert_emiss.exe ; ln -s ../../chem/convert_emiss.exe . )
	( cd test/em_real ; /bin/rm -f README.namelist ; ln -s ../../run/README.namelist . )
	( cd run ; /bin/rm -f namelist.input ; ln -s ../test/em_real/namelist.input . )

#### biogenic emissions converter

bio_conv : wrf
	@ echo '--------------------------------------'
	( cd chem ; $(MAKE) MODULE_DIRS="$(ALL_MODULES)" SOLVER=em IDEAL_CASE=real convert_bioemiss )
	( cd test/em_real ; /bin/rm -f convert_bioemiss.exe ; ln -s ../../chem/convert_bioemiss.exe . )
	( cd test/em_real ; /bin/rm -f README.namelist ; ln -s ../../run/README.namelist . )
	( cd run ; /bin/rm -f namelist.input ; ln -s ../test/em_real/namelist.input . )

#### nmm converter

#TBH:  for now, link wrf.exe, wrf_ESMFApp.exe, and wrf_SST_ESMF.exe when ESMF_COUPLING is set
#TBH:  Either wrf.exe or wrf_ESMFApp.exe can be used for stand-alone testing in this case
#TBH:  wrf_SST_ESMF.exe is a coupled application
nmm_real : nmm_wrf
	@ echo '--------------------------------------'
	( cd main ; $(MAKE) MODULE_DIRS="$(ALL_MODULES)" SOLVER=nmm IDEAL_CASE=real real_nmm )
	( cd test/nmm_real ; /bin/rm -f wrf.exe ; ln -s $(MAIN)/wrf.exe . )
	if [ $(ESMF_COUPLING) -eq 1 ] ; then \
	  ( cd test/nmm_real ; /bin/rm -f wrf_ESMFApp.exe ; ln -s $(MAIN)/wrf_ESMFApp.exe . ) ; \
	  ( cd test/nmm_real ; /bin/rm -f wrf_SST_ESMF.exe ; ln -s $(MAIN)/wrf_SST_ESMF.exe . ) ; \
	fi
	( cd test/nmm_real ; /bin/rm -f real_nmm.exe ; ln -s $(MAIN)/real_nmm.exe . )
	( cd test/nmm_real ; /bin/rm -f README.namelist ; ln -s ../../run/README.namelist . )
	( cd test/nmm_real ; /bin/rm -f ETAMPNEW_DATA RRTM_DATA ;    \
	     ln -sf ../../run/ETAMPNEW_DATA . ;                     \
	     ln -sf ../../run/RRTM_DATA . ;                         \
	     if [ $(RWORDSIZE) -eq 8 ] ; then                       \
	        ln -sf ../../run/ETAMPNEW_DATA_DBL ETAMPNEW_DATA ;  \
	        ln -sf ../../run/RRTM_DATA_DBL RRTM_DATA ;          \
	     fi )
	( cd test/nmm_real ; /bin/rm -f GENPARM.TBL ; ln -s ../../run/GENPARM.TBL . )
	( cd test/nmm_real ; /bin/rm -f LANDUSE.TBL ; ln -s ../../run/LANDUSE.TBL . )
	( cd test/nmm_real ; /bin/rm -f SOILPARM.TBL ; ln -s ../../run/SOILPARM.TBL . )
	( cd test/nmm_real ; /bin/rm -f VEGPARM.TBL ; ln -s ../../run/VEGPARM.TBL . )
	( cd test/nmm_real ; /bin/rm -f tr49t67 ; ln -s ../../run/tr49t67 . )
	( cd test/nmm_real ; /bin/rm -f tr49t85 ; ln -s ../../run/tr49t85 . )
	( cd test/nmm_real ; /bin/rm -f tr67t85 ; ln -s ../../run/tr67t85 . )
	( cd test/nmm_real ; /bin/rm -f gribmap.txt ; ln -s ../../run/gribmap.txt . )
	( cd test/nmm_real ; /bin/rm -f grib2map.txt ; ln -s ../../run/grib2map.txt . )
	( cd run ; /bin/rm -f real_nmm.exe ; ln -s $(MAIN)/real_nmm.exe . )
	( cd run ; /bin/rm -f namelist.input ; ln -s ../test/nmm_real/namelist.input . )



# semi-Lagrangian initializations


ext :
	@ echo '--------------------------------------'
	( cd frame ; $(MAKE) module_wrf_error.o externals )

framework :
	@ echo '--------------------------------------'
	( cd frame ; $(MAKE) framework; \
	cd $(IO_NETCDF) ; make NETCDFPATH="$(NETCDFPATH)" FC="$(SFC) $(FCBASEOPTS)" RANLIB="$(RANLIB)" CPP="$(CPP) $(LIBINCLUDE)" LDFLAGS="$(LDFLAGS)" ESMF_IO_LIB_EXT="$(ESMF_IO_LIB_EXT)" ESMF_MOD_DEPENDENCE="../$(ESMF_MOD_DEPENDENCE)" diffwrf_netcdf; \
	cd $(IO_INT) ; $(MAKE) SFC="$(SFC) $(FCBASEOPTS)" FC="$(SFC) $(FCBASEOPTS)" RANLIB="$(RANLIB)" CPP="$(CPP)" ESMF_IO_LIB_EXT="$(ESMF_IO_LIB_EXT)" ESMF_MOD_DEPENDENCE="../$(ESMF_MOD_DEPENDENCE)" diffwrf_int ; cd $(FRAME) )

shared :
	@ echo '--------------------------------------'
	( cd share ; $(MAKE) all )

chemics :
	@ echo '--------------------------------------'
	( cd chem ; $(MAKE) all )

physics :
	@ echo '--------------------------------------'
	( cd phys ; $(MAKE) all )

em_core :
	@ echo '--------------------------------------'
	( cd dyn_em ; $(MAKE) all )

da_links :
	( cd da; $(MAKE) links )

da_constants : da_links
	( cd da; $(MAKE) MODULE_DIRS="$(DA_WRFVAR_MODULES_2)" da_constants.o )

blas : 
	( cd external/blas ; $(MAKE) all )
	
lapack : blas
	( cd external/lapack ; $(MAKE) all )
	
fftpack5 : da_constants
	( cd external/fftpack5 ; $(MAKE) all )
	
bufr_ncep_nco : 
	( cd external/bufr_ncep_nco ; $(MAKE) all )
	
wrfvar_src : bufr_ncep_nco fftpack5 lapack blas
	@ echo '--------------------------------------'
	( cd da; $(MAKE) MODULE_DIRS="$(DA_WRFVAR_MODULES_2)" wrfvar )

convertor_drivers :
	@ echo '--------------------------------------'
	( cd convertor ; $(MAKE) )

# rule used by configure to test if this will compile with MPI 2 calls MPI_Comm_f2c and _c2f
mpi2_test :
	@ cd tools ; /bin/rm -f mpi2_test ; $(CC) -o mpi2_test mpi2_test.c ; cd ..

# rule used by configure to test if fseeko and fseeko64 are supported (for share/landread.c to work right)
fseek_test :
	@ cd $(TOOLS) ; /bin/rm -f fseeko_test ; $(SCC) -DTEST_FSEEKO -o fseeko_test fseek_test.c ; cd ..
	@ cd $(TOOLS) ; /bin/rm -f fseeko64_test ; $(SCC) -DTEST_FSEEKO64 -o fseeko64_test fseek_test.c ; cd ..

### 3.b.  sub-rule to build the expimental core

# uncomment the two lines after exp_core for EXP
exp_core :
	@ echo '--------------------------------------'
	( cd dyn_exp ; $(MAKE) )

# uncomment the two lines after nmm_core for NMM
nmm_core :
	@ echo '--------------------------------------'
	( cd dyn_nmm ; $(MAKE) )

toolsdir :
	@ echo '--------------------------------------'
	( cd tools ; $(MAKE) CC="$(CC_TOOLS)" registry )

# Use this target to build stand-alone tests of esmf_time_f90.  
# Only touches external/esmf_time_f90/.  
esmf_time_f90_only :
	@ echo '--------------------------------------'
	( cd external/esmf_time_f90 ; $(MAKE) FC="$(FC) $(FCFLAGS)" CPP="$(CPP) -DTIME_F90_ONLY" tests )


bufr_little_endian :
	@ echo '--------------------------------------'
	( cd tools ; $(MAKE) CC="$(CC_TOOLS)" DA="$(DA)" \
            FC="$(FC)" FIXEDFLAGS_ENDIAN="$(FIXEDFLAGS_ENDIAN)" bufr_little_endian.exe)

clean :
	@ ( cd chem; make clean )
	@ ( cd da; make clean )
	@ ( cd dyn_em; make clean )
	@ ( cd dyn_exp; make clean )
	@ ( cd dyn_nmm; make clean )
	@ ( cd external; make clean )
	@ ( cd frame; make clean )
	@ ( cd main; make clean )
	@ ( cd phys; make clean )
	@ ( cd share; make clean )
	@ ( cd tools; make clean )

superclean : clean
	@ ( cd chem; make superclean )
	@ ( cd da; make superclean )
	@ ( cd dyn_em; make superclean )
	@ ( cd dyn_exp; make superclean )
	@ ( cd dyn_nmm; make superclean )
	@ ( cd external; make superclean )
	@ ( cd frame; make superclean )
	@ ( cd main; make superclean )
	@ ( cd phys; make superclean )
	@ ( cd share; make superclean )
	@ ( cd tools; make superclean )

# DO NOT DELETE
