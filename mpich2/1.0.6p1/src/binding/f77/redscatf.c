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
extern FORT_DLL_SPEC void FORT_CALL MPI_REDUCE_SCATTER( void*, void*, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint * );
extern FORT_DLL_SPEC void FORT_CALL mpi_reduce_scatter__( void*, void*, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint * );
extern FORT_DLL_SPEC void FORT_CALL mpi_reduce_scatter( void*, void*, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint * );
extern FORT_DLL_SPEC void FORT_CALL mpi_reduce_scatter_( void*, void*, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint * );
extern FORT_DLL_SPEC void FORT_CALL pmpi_reduce_scatter_( void*, void*, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint * );

#pragma weak MPI_REDUCE_SCATTER = pmpi_reduce_scatter__
#pragma weak mpi_reduce_scatter__ = pmpi_reduce_scatter__
#pragma weak mpi_reduce_scatter_ = pmpi_reduce_scatter__
#pragma weak mpi_reduce_scatter = pmpi_reduce_scatter__
#pragma weak pmpi_reduce_scatter_ = pmpi_reduce_scatter__


#elif defined(HAVE_PRAGMA_WEAK)

#if defined(F77_NAME_UPPER)
extern FORT_DLL_SPEC void FORT_CALL MPI_REDUCE_SCATTER( void*, void*, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint * );

#pragma weak MPI_REDUCE_SCATTER = PMPI_REDUCE_SCATTER
#elif defined(F77_NAME_LOWER_2USCORE)
extern FORT_DLL_SPEC void FORT_CALL mpi_reduce_scatter__( void*, void*, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint * );

#pragma weak mpi_reduce_scatter__ = pmpi_reduce_scatter__
#elif !defined(F77_NAME_LOWER_USCORE)
extern FORT_DLL_SPEC void FORT_CALL mpi_reduce_scatter( void*, void*, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint * );

#pragma weak mpi_reduce_scatter = pmpi_reduce_scatter
#else
extern FORT_DLL_SPEC void FORT_CALL mpi_reduce_scatter_( void*, void*, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint * );

#pragma weak mpi_reduce_scatter_ = pmpi_reduce_scatter_
#endif

#elif defined(HAVE_PRAGMA_HP_SEC_DEF)
#if defined(F77_NAME_UPPER)
#pragma _HP_SECONDARY_DEF PMPI_REDUCE_SCATTER  MPI_REDUCE_SCATTER
#elif defined(F77_NAME_LOWER_2USCORE)
#pragma _HP_SECONDARY_DEF pmpi_reduce_scatter__  mpi_reduce_scatter__
#elif !defined(F77_NAME_LOWER_USCORE)
#pragma _HP_SECONDARY_DEF pmpi_reduce_scatter  mpi_reduce_scatter
#else
#pragma _HP_SECONDARY_DEF pmpi_reduce_scatter_  mpi_reduce_scatter_
#endif

#elif defined(HAVE_PRAGMA_CRI_DUP)
#if defined(F77_NAME_UPPER)
#pragma _CRI duplicate MPI_REDUCE_SCATTER as PMPI_REDUCE_SCATTER
#elif defined(F77_NAME_LOWER_2USCORE)
#pragma _CRI duplicate mpi_reduce_scatter__ as pmpi_reduce_scatter__
#elif !defined(F77_NAME_LOWER_USCORE)
#pragma _CRI duplicate mpi_reduce_scatter as pmpi_reduce_scatter
#else
#pragma _CRI duplicate mpi_reduce_scatter_ as pmpi_reduce_scatter_
#endif
#endif /* HAVE_PRAGMA_WEAK */
#endif /* USE_WEAK_SYMBOLS */
/* End MPI profiling block */


/* These definitions are used only for generating the Fortran wrappers */
#if defined(USE_WEAK_SYBMOLS) && defined(HAVE_MULTIPLE_PRAGMA_WEAK) && \
    defined(USE_ONLY_MPI_NAMES)
extern FORT_DLL_SPEC void FORT_CALL MPI_REDUCE_SCATTER( void*, void*, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint * );
extern FORT_DLL_SPEC void FORT_CALL mpi_reduce_scatter__( void*, void*, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint * );
extern FORT_DLL_SPEC void FORT_CALL mpi_reduce_scatter( void*, void*, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint * );
extern FORT_DLL_SPEC void FORT_CALL mpi_reduce_scatter_( void*, void*, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint *, MPI_Fint * );

#pragma weak MPI_REDUCE_SCATTER = mpi_reduce_scatter__
#pragma weak mpi_reduce_scatter_ = mpi_reduce_scatter__
#pragma weak mpi_reduce_scatter = mpi_reduce_scatter__
#endif

/* Map the name to the correct form */
#ifndef MPICH_MPI_FROM_PMPI
#ifdef F77_NAME_UPPER
#define mpi_reduce_scatter_ PMPI_REDUCE_SCATTER
#elif defined(F77_NAME_LOWER_2USCORE)
#define mpi_reduce_scatter_ pmpi_reduce_scatter__
#elif !defined(F77_NAME_LOWER_USCORE)
#define mpi_reduce_scatter_ pmpi_reduce_scatter
#else
#define mpi_reduce_scatter_ pmpi_reduce_scatter_
#endif
/* This defines the routine that we call, which must be the PMPI version
   since we're renaming the Fortran entry as the pmpi version.  The MPI name
   must be undefined first to prevent any conflicts with previous renamings,
   such as those put in place by the globus device when it is building on
   top of a vendor MPI. */
#undef MPI_Reduce_scatter
#define MPI_Reduce_scatter PMPI_Reduce_scatter 

#else

#ifdef F77_NAME_UPPER
#define mpi_reduce_scatter_ MPI_REDUCE_SCATTER
#elif defined(F77_NAME_LOWER_2USCORE)
#define mpi_reduce_scatter_ mpi_reduce_scatter__
#elif !defined(F77_NAME_LOWER_USCORE)
#define mpi_reduce_scatter_ mpi_reduce_scatter
/* Else leave name alone */
#endif


#endif /* MPICH_MPI_FROM_PMPI */

/* Prototypes for the Fortran interfaces */
#include "fproto.h"
FORT_DLL_SPEC void FORT_CALL mpi_reduce_scatter_ ( void*v1, void*v2, MPI_Fint *v3, MPI_Fint *v4, MPI_Fint *v5, MPI_Fint *v6, MPI_Fint *ierr ){

    if (MPIR_F_NeedInit){ mpirinitf_(); MPIR_F_NeedInit = 0; }
    if (v1 == MPIR_F_MPI_IN_PLACE) v1 = MPI_IN_PLACE;
    *ierr = MPI_Reduce_scatter( v1, v2, v3, (MPI_Datatype)(*v4), *v5, (MPI_Comm)(*v6) );
}
