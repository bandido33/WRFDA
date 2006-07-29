/*********************************************************************
 *   Copyright 1992, University Corporation for Atmospheric Research
 *   See netcdf/README file for copying and redistribution conditions.
 *
 *   Purpose:   C++ class interface for netCDF
 *
 *   $Header: /afs/ncsa/projects/hdf/cvs/hdf4/mfhdf/c++/netcdf.hh,v 1.2 1993/04/30 20:29:48 koziol Exp $
 *********************************************************************/

#ifndef NETCDF_HH
#define NETCDF_HH

#include "netcdf.h"             // the C interface
#include "ncvalues.hh"          // arrays that know their element type

typedef const char* NcToken;    // names for netCDF objects
typedef unsigned int NcBool;    // many members return 0 on failure

class NcDim;                    // dimensions
class NcVar;                    // variables
class NcAtt;                    // attributes


/*
 * ***********************************************************************
 * Abstract base class for netCDF files.  The concrete derived classes are
 * NcOldFile and NcNewFile.
 * ***********************************************************************
 */
class NcFile
{
  public:

    // Pure destructor used to make this an abstract base class.
    virtual ~NcFile( void )=0;

    NcBool is_valid( void ) const;         // opened OK in ctr, still valid

    int num_dims( void ) const;            // number of dimensions
    int num_vars( void ) const;            // number of variables
    int num_atts( void ) const;            // number of (global) attributes

    NcDim* get_dim( NcToken ) const;       // dimension by name
    NcVar* get_var( NcToken ) const;       // variable by name
    NcAtt* get_att( NcToken ) const;       // global attribute by name

    NcDim* get_dim( int ) const;           // n-th dimension
    NcVar* get_var( int ) const;           // n-th variable
    NcAtt* get_att( int ) const;           // n-th global attribute
    NcDim* rec_dim( void ) const;          // unlimited dimension, if any
    
    // Add new dimensions, variables, global attributes.
    // These put the file in "define" mode, so could be expensive.
    NcDim* add_dim( NcToken dimname, long dimsize );
    NcDim* add_dim( NcToken dimname );     // unlimited

    NcVar* add_var( NcToken varname, NcType type,       // scalar
                    const NcDim* dim0=0,                // 1-dim
                    const NcDim* dim1=0,                // 2-dim
                    const NcDim* dim2=0,                // 3-dim
                    const NcDim* dim3=0,                // 4-dim
                    const NcDim* dim4=0 );              // 5-dim
    NcVar* add_var( NcToken varname, NcType type,       // n-dim
                          int ndims, const NcDim* dims );

    NcBool add_att( NcToken attname, char );             // scalar attributes
    NcBool add_att( NcToken attname, short );
    NcBool add_att( NcToken attname, int );
    NcBool add_att( NcToken attname, long );
    NcBool add_att( NcToken attname, float );
    NcBool add_att( NcToken attname, double );
    NcBool add_att( NcToken attname, const char*);       // string attribute
    NcBool add_att( NcToken attname, int, const char* ); // vector attributes
    NcBool add_att( NcToken attname, int, const short* );
    NcBool add_att( NcToken attname, int, const int* );
    NcBool add_att( NcToken attname, int, const long* );
    NcBool add_att( NcToken attname, int, const float* );
    NcBool add_att( NcToken attname, int, const double* );

    enum FillMode {
        Fill = NC_FILL,                    // prefill (default)
        NoFill = NC_NOFILL,                // don't prefill
        Bad
      };

    NcBool set_fill( FillMode = Fill );    // set fill-mode
    FillMode get_fill( void );             // get fill-mode

    NcBool sync( void );                   // synchronize to disk
    NcBool close( void );                  // to close earlier than dtr
    NcBool abort( void );                  // back out of bad defines
    
    // Needed by other Nc classes, but users will not need them
    NcBool define_mode( void ); // leaves in define mode, if possible
    NcBool data_mode( void );   // leaves in data mode, if possible
    int id( void ) const;       // id used by C interface

  protected:
    int the_id;
    int in_define_mode;
    NcDim** dimensions;
    NcVar** variables;
    NcVar* globalv;             // "variable" for global attributes
};


/*
 * **********************************************************************
 * To create new netCDF files, opened in definition mode for adding new
 * dimensions, variables, and attributes.
 * **********************************************************************
 */
class NcNewFile : public NcFile
{
  public:

    enum CreateMode {
        NoClobber = NC_NOCLOBBER, // create only if doesn't exist (default)
        Clobber = NC_CLOBBER      // create new file, even if exists
      };

    NcNewFile( const char * path, CreateMode = NoClobber );
    virtual ~NcNewFile( void ) {};
};


/*
 * **********************************************************************
 * For existing netCDF files, opened in data access mode.
 * **********************************************************************
 */
class NcOldFile : public NcFile
{
  public:

    enum OpenMode {
        ReadOnly = NC_NOWRITE,  // open for read only (default)
        Write = NC_WRITE        // open for write
      };

    NcOldFile( const char * path, OpenMode = ReadOnly );
    virtual ~NcOldFile( void ) {};
};


/*
 * **********************************************************************
 * A netCDF dimension, with a name and a size.  These are only created
 * by NcFile member functions, because they cannot exist independently
 * of an open netCDF file.
 * **********************************************************************
 */
class NcDim
{
  public:
    NcToken name( void ) const;
    long size( void ) const;
    NcBool is_valid( void ) const;
    NcBool is_unlimited( void ) const;
    NcBool rename( NcToken newname );
    int id( void ) const;

  private:
    const NcFile *the_file;
    int the_id;
    char *the_name;

    NcDim(const NcFile*, int num);         // existing dimension
    NcDim(NcFile*, NcToken name, long sz); // defines a new dim
    virtual ~NcDim( void );
    
    // to construct dimensions, since constructor is private
  friend NcOldFile::NcOldFile( const char *, NcOldFile::OpenMode );
  friend NcBool NcFile::sync( void );
  friend NcDim* NcFile::add_dim( NcToken, long );
    // to delete dimensions, since destructor is private
  friend NcBool NcFile::close( void );
};


/*
 * **********************************************************************
 * Abstract base class for a netCDF variable or attribute, both of which
 * have a name, a type, and associated values.  These only exist as
 * components of an open netCDF file.
 * **********************************************************************
 */
class NcTypedComponent
{
  public:
    virtual NcToken name( void ) const = 0;
    virtual NcType type( void ) const = 0;
    virtual NcBool is_valid( void ) const = 0;
    virtual long num_vals( void ) const = 0; 
    virtual NcBool rename( NcToken newname ) = 0;
    virtual NcValues* values( void ) const = 0; // block of all values

    // The following member functions provide conversions from the value
    // type to a desired basic type.  If the value is out of range,
    // the default "fill-value" for the appropriate type is returned.

    virtual ncbyte as_ncbyte( int n ) const;    // nth value as an unsgnd char
    virtual char as_char( int n ) const;        // nth value as char
    virtual short as_short( int n ) const;      // nth value as short
    virtual long as_long( int n ) const;        // nth value as long
    virtual float as_float( int n ) const;      // nth value as floating-point
    virtual double as_double( int n ) const;    // nth value as double
    virtual char* as_string( int n ) const;     // nth value as string

  protected:
    NcFile *the_file;
    NcTypedComponent( NcFile* );
    virtual NcValues* get_space( void ) const;  // to hold values
};


/*
 * **********************************************************************
 * netCDF variables.  In addition to a name and a type, these also have
 * a shape, given by a list of dimensions
 * **********************************************************************
 */
class NcVar : public NcTypedComponent
{
  public:
    virtual ~NcVar( void );
    NcToken name( void ) const;
    NcType type( void ) const;
    NcBool is_valid( void ) const;
    int num_dims( void ) const;         // dimensionality of variable
    NcDim* get_dim( int ) const;        // n-th dimension
    const long* edges( void ) const;    // dimension sizes
    int num_atts( void ) const;         // number of attributes
    NcAtt* get_att( NcToken ) const;    // attribute by name
    NcAtt* get_att( int ) const;        // n-th attribute
    long num_vals( void ) const;        // product of dimension sizes
    NcValues* values( void ) const;     // all values

    // Put scalar or 1, ..., 5 dimensional arrays by providing enough
    // arguments.  Arguments are edge lengths, and their number must not
    // exceed variable\'s dimensionality.  Start corner is [0,0,..., 0] by
    // default, but may be reset using the set_cur() member.  FALSE is
    // returned if type of values does not match type for variable.
    NcBool put( const char* vals,
                long c0=0, long c1=0, long c2=0, long c3=0, long c4=0 );
    NcBool put( const short* vals,
                long c0=0, long c1=0, long c2=0, long c3=0, long c4=0 );
    NcBool put( const long* vals,
                long c0=0, long c1=0, long c2=0, long c3=0, long c4=0 );
    NcBool put( const int* vals,
                long c0=0, long c1=0, long c2=0, long c3=0, long c4=0 );
    NcBool put( const float* vals,
                long c0=0, long c1=0, long c2=0, long c3=0, long c4=0 );
    NcBool put( const double* vals,
                long c0=0, long c1=0, long c2=0, long c3=0, long c4=0 );

    // Put n-dimensional arrays, starting at [0, 0, ..., 0] by default,
    // may be reset with set_cur().
    NcBool put( const char* vals, const long* counts );
    NcBool put( const short* vals, const long* counts );
    NcBool put( const long* vals, const long* counts );
    NcBool put( const int* vals, const long* counts );
    NcBool put( const float* vals, const long* counts );
    NcBool put( const double* vals, const long* counts );

    // Get scalar or 1, ..., 5 dimensional arrays by providing enough
    // arguments.  Arguments are edge lengths, and their number must not
    // exceed variable\'s dimensionality.  Start corner is [0,0,..., 0] by
    // default, but may be reset using the set_cur() member.
    NcBool get( char* vals, long c0=0, long c1=0,
                long c2=0, long c3=0, long c4=0 ) const;
    NcBool get( short* vals, long c0=0, long c1=0,
                long c2=0, long c3=0, long c4=0 ) const;
    NcBool get( long* vals, long c0=0, long c1=0,
                long c2=0, long c3=0, long c4=0 ) const;
    NcBool get( int* vals, long c0=0, long c1=0,
                long c2=0, long c3=0, long c4=0 ) const;
    NcBool get( float* vals, long c0=0, long c1=0,
                long c2=0, long c3=0, long c4=0 ) const;
    NcBool get( double* vals, long c0=0, long c1=0,
                long c2=0, long c3=0, long c4=0 ) const; 

    // Get n-dimensional arrays, starting at [0, 0, ..., 0] by default,
    // may be reset with set_cur().
    NcBool get( char* vals, const long* counts ) const;
    NcBool get( short* vals, const long* counts ) const;
    NcBool get( long* vals, const long* counts ) const;
    NcBool get( int* vals, const long* counts ) const;
    NcBool get( float* vals, const long* counts ) const;
    NcBool get( double* vals, const long* counts ) const;

    NcBool set_cur(long c0=-1, long c1=-1, long c2=-1,
                         long c3=-1, long c4=-1);
    NcBool set_cur(long* cur);

    // these put file in define mode, so could be expensive
    NcBool add_att( NcToken, char );             // add scalar attributes
    NcBool add_att( NcToken, short );
    NcBool add_att( NcToken, int );
    NcBool add_att( NcToken, long );
    NcBool add_att( NcToken, float );
    NcBool add_att( NcToken, double );
    NcBool add_att( NcToken, const char* );      // string attribute
    NcBool add_att( NcToken, int, const char* ); // vector attributes
    NcBool add_att( NcToken, int, const short* );
    NcBool add_att( NcToken, int, const int* );
    NcBool add_att( NcToken, int, const long* );
    NcBool add_att( NcToken, int, const float* );
    NcBool add_att( NcToken, int, const double* );

    NcBool rename( NcToken newname );

    int id( void ) const;               // rarely needed, C interface id
    
  private:
    int the_id;
    long* the_cur;
    char* the_name;

    // private constructors because only an NcFile creates these
    NcVar( void );
    NcVar(NcFile*, int);

    int attnum( NcToken attname ) const;
    NcToken attname( int attnum ) const;
    void init_cur( void );

    // to make variables, since constructor is private
  friend NcOldFile::NcOldFile( const char *, OpenMode );
  friend NcNewFile::NcNewFile( const char *, CreateMode );
  friend NcBool NcFile::sync( void );
  friend NcVar* NcFile::add_var( NcToken varname, NcType type,
                                 const NcDim*,
                                 const NcDim*,
                                 const NcDim*,
                                 const NcDim*,
                                 const NcDim*);
  friend NcVar* NcFile::add_var( NcToken, NcType, int,
                                 const NcDim* );
};


/*
 * **********************************************************************
 * netCDF attributes.  In addition to a name and a type, these are each
 * associated with a specific variable, or are global to the file.
 * **********************************************************************
 */
class NcAtt : public NcTypedComponent
{
  public:          
    virtual ~NcAtt( void );
    NcToken name( void ) const;
    NcType type( void ) const;
    NcBool is_valid( void ) const;
    long num_vals( void ) const; 
    NcValues* values( void ) const;
    NcBool rename( NcToken newname );
    NcBool remove( void );

  private:
    const NcVar* the_variable;
    char* the_name;
    // protected constructors because only NcVars and NcFiles create
    // attributes
    NcAtt( NcFile*, const NcVar*, NcToken);
    NcAtt( NcFile*, NcToken); // global attribute
    
    // To make attributes, since constructor is private
  friend NcOldFile::NcOldFile( const char *, OpenMode );
  friend NcNewFile::NcNewFile( const char *, CreateMode );
  friend NcAtt* NcVar::get_att( NcToken ) const;
};


/*
 * **********************************************************************
 * To control error handling.  Declaring an NcError object temporarily
 * changes the error-handling behavior until the object is destroyed, at
 * which time the previous error-handling behavior is restored.
 * **********************************************************************
 */
class NcError {
  public:
    enum Behavior {
        silent_nonfatal = 0,
        verbose_nonfatal = NC_VERBOSE,
        silent_fatal = NC_FATAL,
        verbose_fatal = NC_FATAL | NC_VERBOSE      
      };

    // constructor saves previous error state, sets new state
    NcError( Behavior b = verbose_fatal );

    // destructor restores previous error state
    virtual ~NcError( void );

    int get_err( void );                 // returns most recent error

  private:
    int the_old_state;
    int the_old_err;
};

#endif                          /* NETCDF_HH */