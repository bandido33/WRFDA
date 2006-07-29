# 
# Clear all conditional flags
sgi_mode=""
hdfeos_f90_comp=""
hdfeos_nag_flag=""
 
# set the HDFEOS home directory and HDF variables
# HDFEOS installation done on Mon Jun 26 15:48:32 MDT 2006 
# 
 
HDFEOS_HOME=/standalone/users/bray/temp/mike/trunk/external/HDF-EOS/hdfeos	# the HDFEOS home directory
HDFLIB=/standalone/users/bray/temp/mike/trunk/external/HDF-EOS/HDF4.2r1/NewHDF/lib 		# the HDF lib directory
HDFINC=/standalone/users/bray/temp/mike/trunk/external/HDF-EOS/HDF4.2r1/NewHDF/include 		# the HDF include directory
sgi_mode=32 		# SGI for standard mode
opt_flag='-O'		# set compiler optimization level
 
#-----------------------------------------------------------------------------
# file:	
# 	hdfeos_env.ksh
#
# description:
# 	This file defines environment variables used by HDFEOS.
# 	This version is for use under the Korn shell (ksh).
#
# usage:
# 	This file should be called from your .profile file with the line:
#
# 	    . <HDFEOS-home-dir>/bin/hdfeos_env.ksh
#	
# 	where <HDFEOS-home-dir> is the full path of the HDFEOS home directory.
#
# author:
# 	Mike Sucher / A.R.C.
#       Guru Tej S. Khalsa / Applied Research Corporation
#
# notes:
# 	1) This file is compatible with the following platforms:
# 	   Sun, SGI, HP-9000, IBM RS-6000 and DEC Alpha.
# 	   It automatically figures out which platform you are on,
# 	   and sets environment variables accordingly.
# 	2) This file defines a variable called hdfeos_path which contains
# 	   all the directories likely to be needed on a given machine
# 	   type, including the HDFEOS bin directories.  Users 
# 	   may choose to set their path variable with:
# 	   
# 	           PATH=<user-path-additions>:$hdfeos_path
# 	           export PATH
#
# 	   where <user-path-additions> is an optional list of other
# 	   directories added to the search path.
#
# history:
#	17-Jun-1996 MES  Initial version 
# 
#-----------------------------------------------------------------------------

: ${sgi_mode:=32}		# by default, SGI mode is standard 32-bit

: ${hdfeos_f90_comp:=""}	# by default, no FORTRAN-90 compiler

: ${hdfeos_nag_flag:=0}		# by default, not using NAG FORTRAN-90

: ${use_flavor:=0}		# by default, not using "flavor"

: ${opt_flag:=-O}		# by default, optimizing code



user_path=$PATH		# save user path

# set path to a base subset of directories, allowing startup on unknown host
# note: once the host has been determined the path is appropriately customized

PATH=/usr/local/bin:/bin:/usr/bin:/etc:/usr/etc:/usr/ucb:/usr/bin/X11
export PATH 

# get operating system type, login name
# special cases: SCO and Cray  - uname works differently,

MACHINE="`uname -m | awk '{print $1}'`"	# needed on Cray & SCO

case "$MACHINE" in

    i386)        			# SCO box
        OSTYPE=sco386 
        ;;

    CRAY) 				# CRAY
        OSTYPE=UNICOS 
        ;;

    *)     				# everybody else
        OSTYPE="`uname`"
        ;;

esac

user=`id | cut -d\( -f2 | cut -d\) -f1`
LOGNAME=$user				# make sure $LOGNAME is defined
USER=$LOGNAME				# make sure $USER is defined
export USER LOGNAME

# set machine-dependent environment variables:
# 	HOST   the host name of this machine
# 	BRAND  used by other achitecture-specific code
# 	PATH   the execution search path 

case "$OSTYPE" in

  AIX) 
    PATH=/usr/local/bin:/bin:/usr/bin:/etc:/usr/etc:/usr/ucb:/usr/bin/X11:/usr/sbin
    HOST="`hostname`"
    BRAND="ibm"
    ;;

  HP-UX) 
    PATH=/usr/local/bin:/bin:/usr/bin:/etc:/usr/bin/X11
    HOST="`hostname`"
    BRAND="hp"
    ;;

  IRIX) 
    PATH=/usr/local/bin:/bin:/usr/bin:/etc:/usr/etc:/usr/bsd:/usr/sbin
    HOST="`hostname`"
    case $sgi_mode in
      64 ) BRAND=sgi64 ;;
      n32) BRAND=sgi32 ;;
      65 ) BRAND=irix65 ;;
      32 ) BRAND=sgi ;;
      *  ) BRAND=sgi ;;  # just in case
    esac
    ;;

  IRIX64) 
    PATH=/usr/local/bin:/bin:/usr/bin:/etc:/usr/etc:/usr/bsd:/usr/sbin
    HOST="`hostname`"
    case $sgi_mode in
      64 ) BRAND=sgi64 ;;
      n32) BRAND=sgi32 ;;
      65 ) BRAND=irix65 ;;
      32 ) BRAND=sgi ;;
      *  ) BRAND=sgi ;;  # just in case
    esac
    ;;

  Linux )
    PATH=/usr/local/bin:/bin:/usr/bin:/etc:/usr/etc:/usr/X11/bin
    HOST=`hostname`
    BRAND=linux
    ;;

  Darwin )
    PATH=/bin:/sbin:/usr/bin:/usr/sbin
    HOST=`hostname`
    BRAND=macintosh
    ;;

  OSF1) 
    PATH=/usr/local/bin:/bin:/usr/bin:/etc:/usr/etc:/usr/ucb:/usr/bin/X11:/usr/sbin
    HOST="`hostname -s`"
    BRAND="dec"
    ;;

  sco386) 
    PATH=/usr/local/bin:/bin:/usr/bin:/etc:/usr/bin/X11
    HOST="`hostname -s`"
    BRAND="sco"
    ;;

  SunOS) 
    # distinguish between SunOS 5.x and 4.x versions
    if [ `uname -r | awk -F. '{print $1}'` = "5" ] ; then 
       if [ `uname -r | awk -F. '{print $2}'` = "8" ] ; then
        BRAND="sun5.8"
       elif [ `uname -r | awk -F. '{print $2}'` = "9" ] ; then
        BRAND="sun5.9"
       elif [ `uname -r | awk -F. '{print $2}'` = "10" ] ; then
        BRAND="sun5.10"
       else
        BRAND="sun5"			# release V5.x SunOS
       fi
        PATH=/usr/local/bin:/opt/SUNWspro/bin:/bin:/usr/bin:/etc:/usr/etc:/usr/ucb:/usr/openwin/bin:/usr/openwin/demo:/usr/ccs/bin:/usr/sbin
    else                                
        BRAND="sun4"			# release V4.x SunOS
        PATH=/usr/local/bin:/usr/local/lang:/usr/lang:/bin:/usr/bin:/etc:/usr/etc:/usr/ucb:/usr/openwin/demo
    fi
    HOST="`hostname`"
    ;;

  UNICOS) 
    PATH=/usr/local/bin:/bin:/usr/bin:/etc:/usr/bin/X11
    HOST="`hostname`"
    BRAND="cray"
    ;;

  Linux)
    PATH=/usr/local/bin:/bin:/usr/bin:/etc:/usr/X11/bin
    HOST="`hostname`"
    BRAND="linux"
    ;;

  *)	
    echo "Operating system: $OSTYPE not supported"
    echo "This release of HDFEOS supports: "
    echo "   Sun, SGI HP-9000 IBM-6000 DEC-Alpha and Cray/Unicos "
    ;;

esac

export PATH HOST BRAND


# set machine-dependent compilers and compilation switches:
#
#

NSL_FLAG="" 			# this is nil on all but Sun platforms
NSL_LIB="" 			# this is nil on all but Sun platforms

case "$BRAND" in

    cray)
	CC=cc 			# C compiler
	CFLAGS="$opt_flag"	# default C flags (optimize, ansi)
	C_CFH="-DCRAYFortran"   # C/cfortran.h called from FORTRAN
	CFHFLAGS="$CFLAGS $C_CFH" # CFLAGS + C_CFH
	C_F77_CFH="$C_CFH"	# calling FORTRAN
	C_F77_LIB=""		# FORTRAN lib called by C main
	F77=cf77		# FORTRAN compiler
	F77FLAGS="" 		# common FORTRAN flags
	F77_CFH=""		# FORTRAN callable from C w/ cfortran.h
	F77_C_CFH="$F77_CFH"	# calling C w/ cfortran.h
	CFH_F77="$F77_C_CFH"	# old version of F77_C_CFH
	F77_C_LIB=""		# C lib called by FORTRAN main 
	HDFSYS=UNICOS		# system type as defined by HDF
	MACHINE=CRAY		# system type as defined by HDFEOS
	;;

    dec)
	CC=cc 			# C compiler
	CFLAGS="$opt_flag -std"	# default C flags (optimize, ansi)
	C_CFH="-DDECFortran"	# C w/ cfortran.h callable from FORTRAN
	CFHFLAGS="$CFLAGS $C_CFH" # CFLAGS + C_CFH
	C_F77_CFH="$C_CFH -Dmain=MAIN__" # calling FORTRAN
	C_F77_LIB=""		# FORTRAN lib called by C main
	F77=f77 		# FORTRAN compiler
	F77FLAGS="" 		# common FORTRAN flags
	F77_CFH=""		# FORTRAN callable from C w/ cfortran.h
	F77_C_CFH="$F77_CFH "   # calling C w/ cfortran.h
	CFH_F77="$F77_C_CFH"	# old version of F77_C_CFH
	F77_C_LIB=""		# C lib called by FORTRAN main
	HDFSYS=DEC_ALPHA	# system type as defined by HDF
	MACHINE=DEC		# system type as defined by HDFEOS
	;;

    hp)
	CC=c89 			# C compiler
	CFLAGS="$opt_flag -Ae" 	# default C flags (optimize, ansi)
	C_CFH="" 		# C w/ cfortran.h callable from FORTRAN
	CFHFLAGS="$CFLAGS $C_CFH" # CFLAGS + C_CFH
	C_F77_CFH="$C_CFH"	# calling FORTRAN
	C_F77_LIB=""		# FORTRAN lib called by C main 
	F77=fort77		# FORTRAN compiler
	F77FLAGS="" 		# common FORTRAN flags
	F77_CFH=""		# FORTRAN callable from C w/ cfortran.h
	F77_C_CFH="$F77_CFH"	# calling C w/ cfortran.h
	CFH_F77="$F77_C_CFH"	# old version of F77_C_CFH
	F77_C_LIB=""		# C lib called by FORTRAN main
	HDFSYS=HP9000		# system type as defined by HDF
	MACHINE=HP		# system type as defined by HDFEOS
	;;

    ibm)
	CC=cc 			# C compiler
	CFLAGS="$opt_flag -qlanglvl=ansi" # default C flags (optimize, ansi)
	C_CFH="" 		# C w/ cfortran.h callable from FORTRAN
	CFHFLAGS="$CFLAGS $C_CFH" # CFLAGS + C_CFH
	C_F77_CFH="$C_CFH"	# calling FORTRAN
	C_F77_LIB=""		# FORTRAN lib called by C main  FORTAN
	F77=xlf 		# FORTRAN compiler
	F77FLAGS="" 		# common FORTRAN flags
	F77_CFH="" 		# FORTRAN callable from C w/ cfortran.h
	F77_C_CFH="$F77_CFH"	# calling C w/ cfortran.h
	CFH_F77="$F77_C_CFH"	# old version of F77_C_CFH
	F77_C_LIB=""		# C lib called by FORTRAN main
	HDFSYS=IBM6000		# system type as defined by HDF
	MACHINE=IBM		# system type as defined by HDFEOS
	;;

    linux)
	CC=gcc 			# C compiler
	CFLAGS="$opt_flag -ansi"	# default C flags (optimize, ansi)
	C_CFH="-Df2cFortran"	# C w/ cfortran.h callable from FORTRAN
	CFHFLAGS="$CFLAGS $C_CFH" # CFLAGS + C_CFH
	C_F77_CFH="$C_CFH"	# calling FORTRAN
	C_F77_LIB=""		# FORTRAN lib called by C main
	F77="g77"		# FORTRAN compiler
	F77FLAGS="" 		# common FORTRAN flags
	F77_CFH=""		# FORTRAN callable from C w/ cfortran.h
	F77_C_CFH="$F77_CFH"	# calling C w/ cfortran.h
	CFH_F77="$F77_C_CFH"	# old version of F77_C_CFH
	F77_C_LIB=""		# C lib called by FORTRAN main
	HDFSYS=LINUX		# system type as defined by HDF
	MACHINE=LINUX		# system type as defined by HDFEOS
	;;

    macintosh)
	CC=gcc 			# C compiler
	CFLAGS="$opt_flag -ansi"	# default C flags (optimize, ansi)
	C_CFH="-Df2cFortran"	# C w/ cfortran.h callable from FORTRAN
	CFHFLAGS="$CFLAGS $C_CFH" # CFLAGS + C_CFH
	C_F77_CFH="$C_CFH"	# calling FORTRAN
	C_F77_LIB=""		# FORTRAN lib called by C main
	F77="g77"		# FORTRAN compiler
	F77FLAGS="" 		# common FORTRAN flags
	F77_CFH=""		# FORTRAN callable from C w/ cfortran.h
	F77_C_CFH="$F77_CFH"	# calling C w/ cfortran.h
	CFH_F77="$F77_C_CFH"	# old version of F77_C_CFH
	F77_C_LIB=""		# C lib called by FORTRAN main
	HDFSYS=MACINTOSH	# system type as defined by HDF
	MACHINE=MACINTOSH	# system type as defined by HDFEOS
	;;

    sco)
	CC=cc 			# C compiler
	CFLAGS="$opt_flag -posix"	# default C flags (optimize, ansi)
	C_CFH="-Df2cFortran"	# C w/ cfortran.h callable from FORTRAN
	CFHFLAGS="$CFLAGS $C_CFH" # CFLAGS + C_CFH
	C_F77_CFH="$C_CFH"	# calling FORTRAN
	C_F77_LIB=""		# FORTRAN lib called by C main
	F77=""			# FORTRAN compiler
	F77FLAGS="" 		# common FORTRAN flags
	F77_CFH=""		# FORTRAN callable from C w/ cfortran.h
	F77_C_CFH="$F77_CFH"	# calling C w/ cfortran.h
	CFH_F77="$F77_C_CFH"	# old version of F77_C_CFH
	F77_C_LIB=""		# C lib called by FORTRAN main
	HDFSYS=SCO		# system type as defined by HDF
	MACHINE=SCO		# system type as defined by HDFEOS
	;;

    sgi)
	if [ $OSTYPE = "IRIX64" ]
        then
		CC="cc -32"	# C compiler (32 bit)
		F77="f77 -32"	# FORTRAN compiler (32 bit)
        else
		CC=cc		# C compiler
		F77=f77		# FORTRAN compiler
        fi
	CFLAGS="$opt_flag -xansi -D_POSIX_SOURCE"	# default C flags (optimize, ansi)
	C_CFH=""	 	# C w/ cfortran.h callable from FORTRAN
	CFHFLAGS="$CFLAGS $C_CFH" # CFLAGS + C_CFH
	C_F77_CFH="$C_CFH"	# calling FORTRAN
	C_F77_LIB="-lI77 -lU77 -lF77" # FORTRAN lib called by C main
	F77FLAGS="" 		# common FORTRAN flags
	F77_CFH=""		# FORTRAN callable from C w/ cfortran.h
	F77_C_CFH="$F77_CFH"	# calling C w/ cfortran.h
	CFH_F77="$F77_C_CFH"	# old version of F77_C_CFH
	F77_C_LIB=""		# C lib called by FORTRAN main
	HDFSYS=IRIS4		# system type as defined by HDF
	MACHINE=SGI		# system type as defined by HDFEOS
	;;

    sgi32)
	CC="cc -n32"		# C compiler (new-style 32 bit)
	F77="f77 -n32"		# FORTRAN compiler (new-style 32 bit)
	CFLAGS="$opt_flag -xansi -D_POSIX_SOURCE"	# default C flags (optimize, ansi)
	C_CFH=""	 	# C w/ cfortran.h callable from FORTRAN
	CFHFLAGS="$CFLAGS $C_CFH" # CFLAGS + C_CFH
	C_F77_CFH="$C_CFH"	# calling FORTRAN
	C_F77_LIB="-lI77 -lU77 -lF77" # FORTRAN lib called by C main
	F77FLAGS="" 		# common FORTRAN flags
	F77_CFH=""		# FORTRAN callable from C w/ cfortran.h
	F77_C_CFH="$F77_CFH"	# calling C w/ cfortran.h
	CFH_F77="$F77_C_CFH"	# old version of F77_C_CFH
	F77_C_LIB=""		# C lib called by FORTRAN main
	HDFSYS=IRIS4		# system type as defined by HDF
	MACHINE=SGI		# system type as defined by HDFEOS
	;;

   irix65)
        CC="cc -n32"            # C compiler (new-style 32 bit)
        F77="f77 -n32"          # FORTRAN compiler (new-style 32 bit)
        CFLAGS="$opt_flag -xansi -D_POSIX_SOURCE"       # default C flags (optimize, ansi)
        C_CFH=""                # C w/ cfortran.h callable from FORTRAN
        CFHFLAGS="$CFLAGS $C_CFH" # CFLAGS + C_CFH
        C_F77_CFH="$C_CFH"      # calling FORTRAN
        C_F77_LIB="-lI77 -lU77 -lF77" # FORTRAN lib called by C main
        F77FLAGS=""             # common FORTRAN flags
        F77_CFH=""              # FORTRAN callable from C w/ cfortran.h
        F77_C_CFH="$F77_CFH"    # calling C w/ cfortran.h
        CFH_F77="$F77_C_CFH"    # old version of F77_C_CFH
        F77_C_LIB=""            # C lib called by FORTRAN main
        HDFSYS=IRIS4            # system type as defined by HDF
        MACHINE=SGI             # system type as defined by HDFEOS
        ;;

    sgi64)
	cpu_type=`hinv | fgrep CPU | head -1 | cut -d' ' -f3 | cut -b2`
	if [ "$cpu_type" = "4" ] ; then
	    CC="cc -64 -mips3"	# C compiler (R4?00 chip)
	    F77="f77 -64 -mips3"	# FORTRAN compiler (R4?00 chip)
        else
            CC="cc -64"      	# C compiler
            F77="f77 -64"    	# FORTRAN compiler
        fi
	CFLAGS="$opt_flag -xansi -D_POSIX_SOURCE"	# default C flags (optimize, ansi)
	C_CFH=""	 	# C w/ cfortran.h callable from FORTRAN
	CFHFLAGS="$CFLAGS $C_CFH" # CFLAGS + C_CFH
	C_F77_CFH="$C_CFH"	# calling FORTRAN
	C_F77_LIB="-lI77 -lU77 -lF77" # FORTRAN lib called by C main
	F77FLAGS="" 		# common FORTRAN flags
	F77_CFH=""		# FORTRAN callable from C w/ cfortran.h
	F77_C_CFH="$F77_CFH"	# calling C w/ cfortran.h
	CFH_F77="$F77_C_CFH"	# old version of F77_C_CFH
	F77_C_LIB=""		# C lib called by FORTRAN main
	HDFSYS=IRIS4		# system type as defined by HDF
	MACHINE=SGI		# system type as defined by HDFEOS
	;;

    sun4)
	CC=acc			# C compiler
	CFLAGS="$opt_flag -Xa" 	# default C flags (optimize, ansi)
	C_CFH="-DsunFortran"	# C w/ cfortran.h callable from FORTRAN
	CFHFLAGS="$CFLAGS $C_CFH" # CFLAGS + C_CFH
	C_F77_CFH="$C_CFH"	# calling FORTRAN
	C_F77_LIB=""		# FORTRAN lib called by C main
	F77=f77 		# FORTRAN compiler
	F77FLAGS="" 		# common FORTRAN flags
	F77_CFH=""		# FORTRAN callable from C w/ cfortran.h
	F77_C_CFH="$F77_CFH" 	# calling C w/ cfortran.h
	CFH_F77="$F77_C_CFH"	# old version of F77_C_CFH
	F77_C_LIB="-lm" 	# C lib called by FORTRAN main
	HDFSYS=SUN		# system type as defined by HDF
	MACHINE=SUN4		# system type as defined by HDFEOS
	NSL_FLAG="-lnsl"	# this is nil on all but Sun platforms
	NSL_LIB="/usr/lib/libnsl.a" # this is nil on all but Sun platforms
	;;

    sun5)
	CC=cc			# C compiler
	CFLAGS="$opt_flag -Xa" 	# default C flags (optimize, ansi)
	C_CFH="-DsunFortran"	# C w/ cfortran.h callable from FORTRAN
	CFHFLAGS="$CFLAGS $C_CFH" # CFLAGS + C_CFH
	C_F77_CFH="$C_CFH"	# calling FORTRAN
	C_F77_LIB=""		# FORTRAN lib called by C main
	F77=f77 		# FORTRAN compiler
	F77FLAGS="" 		# common FORTRAN flags
	F77_CFH=""		# FORTRAN callable from C w/ cfortran.h
	F77_C_CFH="$F77_CFH" 	# calling C w/ cfortran.h
	CFH_F77="$F77_C_CFH"	# old version of F77_C_CFH
	F77_C_LIB="-lm" 	# C lib called by FORTRAN main
	HDFSYS=SUN		# system type as defined by HDF
	MACHINE=SUN5		# system type as defined by HDFEOS
	NSL_FLAG="-lnsl"	# this is nil on all but Sun platforms
	NSL_LIB="/usr/lib/libnsl.a" # this is nil on all but Sun platforms
	;;

    sun5.8)
        CC=cc                   # C compiler
        CFLAGS="$opt_flag -Xa"  # default C flags (optimize, ansi)
        C_CFH="-DsunFortran"    # C w/ cfortran.h callable from FORTRAN
        CFHFLAGS="$CFLAGS $C_CFH" # CFLAGS + C_CFH
        C_F77_CFH="$C_CFH"      # calling FORTRAN
        C_F77_LIB=""            # FORTRAN lib called by C main
        F77=f77                 # FORTRAN compiler
        F77FLAGS=""             # common FORTRAN flags
        F77_CFH=""              # FORTRAN callable from C w/ cfortran.h
        F77_C_CFH="$F77_CFH"    # calling C w/ cfortran.h
        CFH_F77="$F77_C_CFH"    # old version of F77_C_CFH
        F77_C_LIB="-lm"         # C lib called by FORTRAN main
        HDFSYS=SUN              # system type as defined by HDF
        MACHINE=SUN8            # system type as defined by HDFEOS
        NSL_FLAG="-lnsl"        # this is nil on all but Sun platforms
        NSL_LIB="/usr/lib/libnsl.a" # this is nil on all but Sun platforms
        ;;
 
    sun5.9)
        CC=cc                   # C compiler
        CFLAGS="$opt_flag -Xa"  # default C flags (optimize, ansi)
        C_CFH="-DsunFortran"    # C w/ cfortran.h callable from FORTRAN
        CFHFLAGS="$CFLAGS $C_CFH" # CFLAGS + C_CFH
        C_F77_CFH="$C_CFH"      # calling FORTRAN
        C_F77_LIB=""            # FORTRAN lib called by C main
        F77=f77                 # FORTRAN compiler
        F77FLAGS=""             # common FORTRAN flags
        F77_CFH=""              # FORTRAN callable from C w/ cfortran.h
        F77_C_CFH="$F77_CFH"    # calling C w/ cfortran.h
        CFH_F77="$F77_C_CFH"    # old version of F77_C_CFH
        F77_C_LIB="-lm"         # C lib called by FORTRAN main
        HDFSYS=SUN              # system type as defined by HDF
        MACHINE=SUN9            # system type as defined by HDFEOS
        NSL_FLAG="-lnsl"        # this is nil on all but Sun platforms
        NSL_LIB="/usr/lib/libnsl.a" # this is nil on all but Sun platforms
        ;;
 
    sun5.10)
        CC=cc                   # C compiler
        CFLAGS="$opt_flag -Xa"  # default C flags (optimize, ansi)
        C_CFH="-DsunFortran"    # C w/ cfortran.h callable from FORTRAN
        CFHFLAGS="$CFLAGS $C_CFH" # CFLAGS + C_CFH
        C_F77_CFH="$C_CFH"      # calling FORTRAN
        C_F77_LIB=""            # FORTRAN lib called by C main
        F77=f77                 # FORTRAN compiler
        F77FLAGS=""             # common FORTRAN flags
        F77_CFH=""              # FORTRAN callable from C w/ cfortran.h
        F77_C_CFH="$F77_CFH"    # calling C w/ cfortran.h
        CFH_F77="$F77_C_CFH"    # old version of F77_C_CFH
        F77_C_LIB="-lm"         # C lib called by FORTRAN main
        HDFSYS=SUN              # system type as defined by HDF
        MACHINE=SUN10           # system type as defined by HDFEOS
        NSL_FLAG="-lnsl"        # this is nil on all but Sun platforms
        NSL_LIB="/usr/lib/libnsl.a" # this is nil on all but Sun platforms
        ;;
 
    *)
	CC=cc			# C compiler
	CFLAGS="$opt_flag"	# default C flags (optimize)
	C_CFH=""	# C w/ cfortran.h callable from FORTRAN
	CFHFLAGS="$CFLAGS $C_CFH" # CFLAGS + C_CFH
	C_F77_CFH="$C_CFH"	# calling FORTRAN
	C_F77_LIB=""		# FORTRAN lib called by C main
	F77=f77 		# FORTRAN compiler
	F77FLAGS="" 		# common FORTRAN flags
	F77_CFH=""		# FORTRAN callable from C w/ cfortran.h
	F77_C_CFH="$F77_CFH" 	# calling C w/ cfortran.h
	CFH_F77="$F77_C_CFH"	# old version of F77_C_CFH
	F77_C_LIB="-lm" 	# C lib called by FORTRAN main
	HDFSYS=unknown		# system type as defined by HDF
	MACHINE=unknown		# system type as defined by HDFEOS
	;;
esac

export MACHINE
export NSL_FLAG NSL_LIB

export CC CFLAGS C_CFH CFHFLAGS C_F77_CFH C_F77_LIB F77
export F77FLAGS F77_CFH F77_C_CFH CFH_F77 F77_C_LIB HDFSYS


# 
# set up environment to handle FORTRAN-90 compiler
#

if [ "$hdfeos_f90_comp" != "" ] ; then		# using FORTRAN-90

    F77="$hdfeos_f90_comp"

    if [ "$hdfeos_nag_flag" = "1" ] ; then		# using NAG f90
        C_CFH="$C_CFH -DNAGf90F"
        CFHFLAGS="$CFLAGS $C_CFH"
    fi

    export CFHFLAGS C_CFH F77

fi


# copy the machine-specific path to variable hdfeos_path

hdfeos_path=$PATH

# set HDFEOS-related environment variables
# these may be referred to in makefiles and on compiler command lines

if [ "$HDFEOS_HOME" != "" ] ; then

# set up base set of HDFEOS_ Toolkit directory variables.

    HDFEOS_BIN=${HDFEOS_HOME}/bin/$BRAND	# executable files
    HDFEOS_INC=$HDFEOS_HOME/include		# include header files
    HDFEOS_LIB=${HDFEOS_HOME}/lib/$BRAND  	# library files
    HDFEOS_OBJ=${HDFEOS_HOME}/obj/$BRAND	# object files
    HDFEOS_SRC=$HDFEOS_HOME/src			# HDFEOS source files

    if [ $use_flavor = 1 ] ; then
    if [ "$opt_flag" = "-g" ] ; then

	HDFEOS_LIB=${HDFEOS_LIB}_debug
	HDFEOS_OBJ=${HDFEOS_OBJ}_debug
	HDFEOS_BIN=${HDFEOS_BIN}_debug

        hdflib=`echo $HDFLIB | sed "s/${BRAND}/${BRAND}_debug/"`
        if [ -d $hdflib ] ; then
            HDFLIB=$hdflib
        fi

        hdfinc=`echo $HDFINC | sed "s/${BRAND}/${BRAND}_debug/"`
        if [ -d $hdfinc ] ; then
            HDFINC=$hdfinc
        fi

    fi
    fi

    export HDFEOS_HOME HDFEOS_BIN HDFEOS_DAT HDFEOS_INC HDFEOS_LIB 
    export HDFEOS_MSG  HDFEOS_OBJ HDFEOS_RUN HDFEOS_SRC HDFEOS_TST

# update path variables

    PATH=$PATH:$HDFEOS_BIN; export PATH		# add HDFEOS_BIN to path
    hdfeos_path=$hdfeos_path:$HDFEOS_BIN	# add HDFEOS_BIN to hdfeos path
    user_path=$user_path:$HDFEOS_BIN		# add HDFEOS_BIN to user path


else

    echo "You must first set the environment variable HDFEOS_HOME"

fi



#
# restore augmented user path
#
PATH=$user_path ; export PATH


# done
