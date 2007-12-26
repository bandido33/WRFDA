/* -*- Mode: C; c-basic-offset:4 ; -*- */
/*  
 *  (C) 2001 by Argonne National Laboratory.
 *      See COPYRIGHT in top-level directory.
 *
 * This file is automatically generated by buildiface 
 * DO NOT EDIT
 */
#include "mpi_fortimpl.h"


/* Begin MPI profiling block */
#if defined(USE_WEAK_SYMBOLS) && !defined(USE_ONLY_MPI_NAMES) 
#if defined(HAVE_MULTIPLE_PRAGMA_WEAK) && defined(F77_NAME_LOWER_2USCORE)
extern FORT_DLL_SPEC void FORT_CALL MPI_INIT( MPI_Fint * );
extern FORT_DLL_SPEC void FORT_CALL mpi_init__( MPI_Fint * );
extern FORT_DLL_SPEC void FORT_CALL mpi_init( MPI_Fint * );
extern FORT_DLL_SPEC void FORT_CALL mpi_init_( MPI_Fint * );
extern FORT_DLL_SPEC void FORT_CALL pmpi_init_( MPI_Fint * );

#pragma weak MPI_INIT = pmpi_init__
#pragma weak mpi_init__ = pmpi_init__
#pragma weak mpi_init_ = pmpi_init__
#pragma weak mpi_init = pmpi_init__
#pragma weak pmpi_init_ = pmpi_init__


#elif defined(HAVE_PRAGMA_WEAK)

#if defined(F77_NAME_UPPER)
extern FORT_DLL_SPEC void FORT_CALL MPI_INIT( MPI_Fint * );

#pragma weak MPI_INIT = PMPI_INIT
#elif defined(F77_NAME_LOWER_2USCORE)
extern FORT_DLL_SPEC void FORT_CALL mpi_init__( MPI_Fint * );

#pragma weak mpi_init__ = pmpi_init__
#elif !defined(F77_NAME_LOWER_USCORE)
extern FORT_DLL_SPEC void FORT_CALL mpi_init( MPI_Fint * );

#pragma weak mpi_init = pmpi_init
#else
extern FORT_DLL_SPEC void FORT_CALL mpi_init_( MPI_Fint * );

#pragma weak mpi_init_ = pmpi_init_
#endif

#elif defined(HAVE_PRAGMA_HP_SEC_DEF)
#if defined(F77_NAME_UPPER)
#pragma _HP_SECONDARY_DEF PMPI_INIT  MPI_INIT
#elif defined(F77_NAME_LOWER_2USCORE)
#pragma _HP_SECONDARY_DEF pmpi_init__  mpi_init__
#elif !defined(F77_NAME_LOWER_USCORE)
#pragma _HP_SECONDARY_DEF pmpi_init  mpi_init
#else
#pragma _HP_SECONDARY_DEF pmpi_init_  mpi_init_
#endif

#elif defined(HAVE_PRAGMA_CRI_DUP)
#if defined(F77_NAME_UPPER)
#pragma _CRI duplicate MPI_INIT as PMPI_INIT
#elif defined(F77_NAME_LOWER_2USCORE)
#pragma _CRI duplicate mpi_init__ as pmpi_init__
#elif !defined(F77_NAME_LOWER_USCORE)
#pragma _CRI duplicate mpi_init as pmpi_init
#else
#pragma _CRI duplicate mpi_init_ as pmpi_init_
#endif
#endif /* HAVE_PRAGMA_WEAK */
#endif /* USE_WEAK_SYMBOLS */
/* End MPI profiling block */


/* These definitions are used only for generating the Fortran wrappers */
#if defined(USE_WEAK_SYBMOLS) && defined(HAVE_MULTIPLE_PRAGMA_WEAK) && \
    defined(USE_ONLY_MPI_NAMES)
extern FORT_DLL_SPEC void FORT_CALL MPI_INIT( MPI_Fint *, MPI_Fint * );
extern FORT_DLL_SPEC void FORT_CALL mpi_init__( MPI_Fint *, MPI_Fint * );
extern FORT_DLL_SPEC void FORT_CALL mpi_init( MPI_Fint *, MPI_Fint * );
extern FORT_DLL_SPEC void FORT_CALL mpi_init_( MPI_Fint *, MPI_Fint * );

#pragma weak MPI_INIT = mpi_init__
#pragma weak mpi_init_ = mpi_init__
#pragma weak mpi_init = mpi_init__
#endif

/* Map the name to the correct form */
#ifndef MPICH_MPI_FROM_PMPI
#ifdef F77_NAME_UPPER
#define mpi_init_ PMPI_INIT
#elif defined(F77_NAME_LOWER_2USCORE)
#define mpi_init_ pmpi_init__
#elif !defined(F77_NAME_LOWER_USCORE)
#define mpi_init_ pmpi_init
#else
#define mpi_init_ pmpi_init_
#endif
/* This defines the routine that we call, which must be the PMPI version
   since we're renaming the Fortran entry as the pmpi version.  The MPI name
   must be undefined first to prevent any conflicts with previous renamings,
   such as those put in place by the globus device when it is building on
   top of a vendor MPI. */
#undef MPI_Init
#define MPI_Init PMPI_Init 

#else

#ifdef F77_NAME_UPPER
#define mpi_init_ MPI_INIT
#elif defined(F77_NAME_LOWER_2USCORE)
#define mpi_init_ mpi_init__
#elif !defined(F77_NAME_LOWER_USCORE)
#define mpi_init_ mpi_init
/* Else leave name alone */
#endif


#endif /* MPICH_MPI_FROM_PMPI */

/* Prototypes for the Fortran interfaces */
#include "fproto.h"
FORT_DLL_SPEC void FORT_CALL mpi_init_ ( MPI_Fint *ierr ){
#ifndef F77_RUNTIME_VALUES
    /* any compile/link time values go here */
#else
#   error "Fortran values must be determined at configure time"
#endif
    mpirinitf_(); MPIR_F_NeedInit = 0;
    *ierr = MPI_Init( 0, 0 );
}
