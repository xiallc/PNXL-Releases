/*----------------------------------------------------------------------
 * Copyright (c) 2019,2021 XIA LLC
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, 
 * with or without modification, are permitted provided 
 * that the following conditions are met:
 *
 *   * Redistributions of source code must retain the above 
 *     copyright notice, this list of conditions and the 
 *     following disclaimer.
 *   * Redistributions in binary form must reproduce the 
 *     above copyright notice, this list of conditions and the 
 *     following disclaimer in the documentation and/or other 
 *     materials provided with the distribution.
 *   * Neither the name of XIA LLC
 *     nor the names of its contributors may be used to endorse 
 *     or promote products derived from this software without 
 *     specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND 
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
 * IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE 
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON 
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR 
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
 * SUCH DAMAGE.
 *----------------------------------------------------------------------*/
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <time.h>
#include <signal.h>
#include <assert.h>
#include <errno.h>
#include <string.h>
#include <sys/mman.h>
#include <stdint.h>
#include <inttypes.h>

#include <map>
#include <vector>
#include <string>
#include <sstream>
#include <fstream>
#include <iostream>
#include <algorithm>


#include "PixieNetDefs.h"
#include "PixieNetConfig.h"

using namespace std;


namespace {
  
  void split( std::vector<std::string> &resutls,
             const std::string &input, const char *delims )
  {
    resutls.clear();
    
    size_t prev_delim_end = 0;
    size_t delim_start = input.find_first_of( delims, prev_delim_end );
    
    while( delim_start != std::string::npos )
    {
      if( (delim_start-prev_delim_end) > 0 )
        resutls.push_back( input.substr(prev_delim_end,(delim_start-prev_delim_end)) );
      
      prev_delim_end = input.find_first_not_of( delims, delim_start + 1 );
      if( prev_delim_end != std::string::npos )
        delim_start = input.find_first_of( delims, prev_delim_end + 1 );
      else
        delim_start = std::string::npos;
    }//while( this_pos < input.size() )
    
    if( prev_delim_end < input.size() )
      resutls.push_back( input.substr(prev_delim_end) );
  }//split(...)
  
  
 
  
  bool starts_with( const std::string &line, const std::string &label ){
    const size_t len1 = line.size();
    const size_t len2 = label.size();
    
    if( len1 < len2 )
      return false;
    
    return (line.substr(0,len2) == label);
  }//istarts_with(...)
  
  
  // trim from start
  static inline std::string &ltrim(std::string &s)
  {
    s.erase(s.begin(), std::find_if(s.begin(), s.end(), std::not1(std::ptr_fun<int, int>(std::isspace))));
    
    if( s.size() )
    {
      const size_t pos = s.find_first_not_of( '\0' );
      if( pos != 0 && pos != string::npos )
        s.erase( s.begin(), s.begin() + pos );
      else if( pos == string::npos )
        s.clear();
    }
    
    return s;
  }
  
  // trim from end
  static inline std::string &rtrim(std::string &s)
  {
    s.erase(std::find_if(s.rbegin(), s.rend(), std::not1(std::ptr_fun<int, int>(std::isspace))).base(), s.end());
    
    const size_t pos = s.find_last_not_of( '\0' );
    if( pos != string::npos && (pos+1) < s.size() )
      s.erase( s.begin() + pos + 1, s.end() );
    else if( pos == string::npos )
      s.clear();  //string is all '\0' characters
    
    return s;
  }
  
  // trim from both ends
  void trim( std::string &s )
  {
    ltrim( rtrim(s) );
  }//trim(...)
  
  bool split_label_values( const string &line, string &label, string &values )
  {
    label.clear();
    values.clear();
    const size_t pos = line.find_first_of( " \t,;" );
    if( !pos || pos == string::npos )
      return false;
    label = line.substr( 0, pos );
    values = line.substr( pos );
    trim( values );
    
    return true;
  }
  
  std::istream &safe_get_line( std::istream &is, std::string &t, const size_t maxlength )
  {
    //adapted from  http://stackoverflow.com/questions/6089231/getting-std-ifstream-to-handle-lf-cr-and-crlf
    t.clear();
    
    // The characters in the stream are read one-by-one using a std::streambuf.
    // That is faster than reading them one-by-one using the std::istream.
    // Code that uses streambuf this way must be guarded by a sentry object.
    // The sentry object performs various tasks,
    // such as thread synchronization and updating the stream state.
    std::istream::sentry se( is, true );
    std::streambuf *sb = is.rdbuf();
    
    for( ; !maxlength || (t.length() < maxlength); )
    {
      int c = sb->sbumpc(); //advances pointer to current location by one
      switch( c )
      {
        case '\r':
          c = sb->sgetc();  //does not advance pointer to current location
          if(c == '\n')
            sb->sbumpc();   //advances pointer to one current location by one
          return is;
        case '\n':
          return is;
        case EOF:
          is.setstate( ios::eofbit );
          return is;
        default:
          t += (char)c;
      }//switch( c )
    }//for(;;)
    
    return is;
  }//safe_get_line(...)
  
  int get_single_value_str( const map<string,string> &label_to_values,
                            const string &label, string &value, int ignore_missing )
  // returns 0 if value sucessfully updated, negative value if error, +1 if value not in file (sometimes ok)
  {
    const map<string,string>::const_iterator pos = label_to_values.find( label );
    if( pos == label_to_values.end() )
    {
      if(ignore_missing==1)  
            cerr << label << " ";  
      if(ignore_missing==0) 
            cerr << "Parameter '" << label << "' was not in config file" << endl;
      return 1;
    }
    
    value = pos->second;
    trim( value );
    
    vector<string> fields;
    split( fields, value, " \t,;" );
    if( fields.size() != 1 )
    {
      cerr << "Parameter '" << label << "' had " << fields.size() << " values\n";
      return -1;
    }
    
    return 0;
  }
  
  
  int get_multiple_value_str( const map<string,string> &label_to_values,
                            const string &label, string values[NCHANNELS], int ignore_missing )
   // returns 0 if value sucessfully updated, negative value if error, +1 if value not in file (sometimes ok)
 {
    const map<string,string>::const_iterator pos = label_to_values.find( label );
    if( pos == label_to_values.end() )
    {
      if(ignore_missing==1)   
            cerr << label << " ";
      if(ignore_missing==0) 
            cerr << "Parameter '" << label << "' was not in config file" << endl;
      return 1;
    }
    
    string valuestr = pos->second;
    trim( valuestr );
    
    vector<string> fields;
    split( fields, valuestr, " \t,;" );
    if( fields.size() != NCHANNELS )
    {
      cerr << "Parameter '" << label << "' had " << fields.size()
           << " values, and not " << NCHANNELS << "\n";
      return -1;
    }
    
    for( int i = 0; i < NCHANNELS; ++i )
    {
      trim( fields[i] );
      values[i] = fields[i];
    }
    
    return 0;
  }
  
   int parse_single_bool_val( const map<string,string> &label_to_values,
                             const string &label, bool &value, int ignore_missing )
    // returns 0 if value sucessfully updated, negative value if error, +1 if value not in file (sometimes ok)
    {
    string valstr;
    int ret;
    ret =  get_single_value_str( label_to_values, label, valstr, ignore_missing); //  //  0 if valid, <0 if error, +1 not in file (sometimes ok)
    if( ret!=0 )
      return ret;
    

    if( valstr == "true" || valstr == "1" )
    {
      value = true;
      return 0;
    }

    if( valstr == "false" || valstr == "0" )
    {
      value = false;
      return 0;
    }

    cerr << "Parameter '" << label << "' with value " << valstr
            << " could not be interpredted as a boolean\n";
    return -1;
  }//parse_single_bool_val(...)


  int parse_multiple_bool_val( const map<string,string> &label_to_values,
                            const string &label, bool values[NCHANNELS], int ignore_missing )
    // returns 0 if value sucessfully updated, negative value if error, +1 if value not in file (sometimes ok)
    {
    string valstrs[NCHANNELS];
    int ret;
    ret =  get_multiple_value_str( label_to_values, label, valstrs, ignore_missing ); //  //  0 if valid, <0 if error, +1 not in file (sometimes ok)
    if( ret!=0 )
      return ret;
    
    for( int i = 0; i < NCHANNELS; ++i )
    {
      if( valstrs[i] == "true" || valstrs[i] == "1" )
        values[i] = true;
      else if( valstrs[i] == "false" || valstrs[i] == "0" )
        values[i] = false;
      else
      {
        cerr << "Parameter '" << label << "' with value '" << valstrs[i]
             << "' could not be interpredted as a boolean\n";
        return -1;
      }
    }
    
    return 0;
  }//parse_multiple_bool_val(...)


  int parse_single_int_val( const map<string,string> &label_to_values,
                             const string &label, unsigned int &value, int ignore_missing )
  // returns 0 if value sucessfully updated, negative value if error, +1 if value not in file (sometimes ok)
  {
    string valstr;
    int ret;
    ret =  get_single_value_str( label_to_values, label, valstr, ignore_missing); //  //  0 if valid, <0 if error, +1 not in file (sometimes ok)
    if( ret!=0 )
      return ret;

    
    char *cstr = &valstr[0u];    // c++11 avoidance
    char *end;
    try
    {
      value = strtol(cstr, &end, 0);
      // value = std::stoul( valstr, nullptr, 0 );   // requires c++11
    }catch(...)
    {
       cerr << "Parameter '" << label << "' with value " << valstr
            << " could not be interpredted as an unsigned int\n";
      return -1;
    }
    
    return 0;
  }//parse_single_int_val(...)

  int parse_single_ull_val( const map<string,string> &label_to_values,
                             const string &label, unsigned long long &value, int ignore_missing )
  // returns 0 if value sucessfully updated, negative value if error, +1 if value not in file (sometimes ok)
  {
    string valstr;
    int ret;
    ret =  get_single_value_str( label_to_values, label, valstr, ignore_missing); //  //  0 if valid, <0 if error, +1 not in file (sometimes ok)
    if( ret!=0 )
      return ret;

    
    char *cstr = &valstr[0u];    // c++11 avoidance
    char *end;
    try
    {
      value = strtoll(cstr, &end, 0);                // requires c++11 ? if so use strtoq
      // value = std::stoul( valstr, nullptr, 0 );   // requires c++11
    }catch(...)
    {
       cerr << "Parameter '" << label << "' with value " << valstr
            << " could not be interpredted as an unsigned long long\n";
      return -1;
    }
    
    return 0;
  }//parse_single_ull_val(...)


  
  
  int parse_single_dbl_val( const map<string,string> &label_to_values,
                            const string &label, double &value, int ignore_missing )
   // returns 0 if value sucessfully updated, negative value if error, +1 if value not in file (sometimes ok)
   {
    string valstr;

    int ret;
    ret =  get_single_value_str( label_to_values, label, valstr, ignore_missing); //  //  0 if valid, <0 if error, +1 not in file (sometimes ok)
    if( ret!=0 )
      return ret;

    
    char *cstr = &valstr[0u];    // c++11 avoidance
    char *end;
    try
    {
      value = strtod(cstr, &end);
      //value = std::stod( valstr );      // requires c++11
    }catch(...)
    {
      cerr << "Parameter '" << label << "' with value " << valstr
      << " could not be interpredted as an double\n";
      return -1;
    }
    
    return 0;
  }//parse_single_dbl_val(...)
  
  
  int parse_multiple_int_val( const map<string,string> &label_to_values,
                            const string &label, unsigned int values[NCHANNELS], int ignore_missing )
   // returns 0 if value sucessfully updated, negative value if error, +1 if value not in file (sometimes ok)
   {
    string valstrs[NCHANNELS];
    int ret;
    ret =  get_multiple_value_str( label_to_values, label, valstrs, ignore_missing ); //  //  0 if valid, <0 if error, +1 not in file (sometimes ok)
    if( ret!=0 )
      return ret;

    char *cstr;    // c++11 avoidance
    char *end;
    string valstr;
    
    for( int i = 0; i < NCHANNELS; ++i )
    {
      try
      {
      valstr = valstrs[i];
      cstr = &valstr[0u];
      values[i] = strtol(cstr, &end, 0);
      //  values[i] = std::stoul( valstrs[i], nullptr, 0 );   // requires c++11
      }catch(...)
      {
        cerr << "Parameter '" << label << "' with value " << valstrs[i]
             << " could not be interpredted as an unsigned int\n";
        return -1;
      }
    }
    
    return 0;
  }//parse_multiple_int_val(...)
  
  
  int parse_multiple_dbl_val( const map<string,string> &label_to_values,
                              const string &label, double values[NCHANNELS], int ignore_missing )
   // returns 0 if value sucessfully updated, negative value if error, +1 if value not in file (sometimes ok)
   {
    string valstrs[NCHANNELS];
    int ret;
    ret =  get_multiple_value_str( label_to_values, label, valstrs, ignore_missing ); //  //  0 if valid, <0 if error, +1 not in file (sometimes ok)
    if( ret!=0 )
      return ret;

    char *cstr;    // c++11 avoidance
    char *end;
    string valstr;
    
    for( int i = 0; i < NCHANNELS; ++i )
    {
      try
      {
        valstr = valstrs[i];
        cstr = &valstr[0u];
        values[i] = strtod(cstr, &end);
        //values[i] = std::stod( valstrs[i] );     // requires c++11
      }catch(...)
      {
        cerr << "Parameter '" << label << "' with value " << valstrs[i]
        << " could not be interpredted as a double\n";
        return -1;
      }
    }
    
    return 0;
  }//parse_multiple_dbl_val(...)
  
  bool read_config_file_lines( const char * const filename,
                               map<string,string> &label_to_values )
  {
    string line;
    
    ifstream input( filename, ios::in | ios::binary );
    
    if( !input )
    {
      cerr << "Failed to open '" << filename << "'" << endl;
      return false;
    }
    
    while( safe_get_line( input, line, LINESZ ) )
    {
      trim( line );
      if( line.empty() || line[0] == '#' )
        continue;
      
      string label, values;
      const bool success = split_label_values( line, label, values );
      
      if( !success || label.empty() || values.empty() )
      {
        cerr << "Warning: encountered invalid config file line '" << line
        << "', skipping" << endl;
        continue;
      }
      
      label_to_values[label] = values;
    }///more lines in config file
    
    return true;
  }//read_config_file_lines(..)
  
}//namespace


int SetBit(int bit, int value)      // returns "value" with bit "bit" set
{
	return (value | (1<<bit) );
}

int ClrBit(int bit, int value)      // returns "value" with bit "bit" cleared
{
	value=SetBit(bit, value);
	return(value ^ (1<<bit) );
}

int SetOrClrBit(int bit, int value, int set)      // returns "value" with bit "bit" cleared or set, depending on "set"
{
	value=SetBit(bit, value);
   if(set)
      return(value);
   else
	   return(value ^ (1<<bit) );
}


int init_PixieNetFippiConfig_from_file( const char * const filename, 
                                        int ignore_missing,                     
                                        struct PixieNetFippiConfig *config )
{
   // if ignore_missing == 0, missing parameters (parse_XXX returns 1) give an error
   // if ignore_missing == 1, missing parameters (parse_XXX returns 1) are ok, but a warning is printed
   // if ignore_missing == 2, missing parameters (parse_XXX returns 1) are ok, no warning is printed
   // this is set for a second pass, after filling parameters with defaults
  bool bit, bits[NCHANNELS];
  int ret;

  if(ignore_missing==1) 
  {
      cerr << "Using defaults for following parameters " << endl;
  }


  map<string,string> label_to_values;
  
  if( !read_config_file_lines( filename, label_to_values ) )
    return -1;

  // *************** system parameters ********************************* 
  
  ret = parse_single_int_val( label_to_values, "C_CONTROL", config->C_CONTROL, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -2;

  ret = parse_single_dbl_val( label_to_values, "REQ_RUNTIME", config->REQ_RUNTIME, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -3;

  ret = parse_single_int_val( label_to_values, "POLL_TIME", config->POLL_TIME, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -4;

  ret = parse_single_int_val( label_to_values, "CRATE_ID", config->CRATE_ID, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -5;

  ret = parse_single_int_val( label_to_values, "SLOT_ID", config->SLOT_ID, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -6;

  ret = parse_single_int_val( label_to_values, "MODULE_ID", config->MODULE_ID, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -7;

  ret = parse_single_int_val( label_to_values, "AUX_CTRL", config->AUX_CTRL, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -11;

  ret = parse_single_int_val( label_to_values, "CLK_CTRL", config->CLK_CTRL, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -11;

  ret = parse_single_int_val( label_to_values, "WR_RUNTIME_CTRL", config->WR_RUNTIME_CTRL, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -12;

  ret = parse_single_int_val( label_to_values, "UDP_PAUSE", config->UDP_PAUSE, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -1;

  ret = parse_single_ull_val( label_to_values, "DEST_MAC0", config->DEST_MAC0, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -13;

  ret = parse_single_ull_val( label_to_values, "DEST_MAC1", config->DEST_MAC1, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -14;

  ret = parse_single_ull_val( label_to_values, "SRC_MAC0", config->SRC_MAC0, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -13;

  ret = parse_single_ull_val( label_to_values, "SRC_MAC1", config->SRC_MAC1, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -14;

  ret = parse_single_ull_val( label_to_values, "DEST_IP0", config->DEST_IP0, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -15;

  ret = parse_single_ull_val( label_to_values, "DEST_IP1", config->DEST_IP1, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -16;

  ret = parse_single_ull_val( label_to_values, "SRC_IP0", config->SRC_IP0, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -17;

  ret = parse_single_ull_val( label_to_values, "SRC_IP1", config->SRC_IP1, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -18;

  ret = parse_single_int_val( label_to_values, "DEST_PORT0", config->DEST_PORT0, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -15;

  ret = parse_single_int_val( label_to_values, "DEST_PORT1", config->DEST_PORT1, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -16;

  ret = parse_single_int_val( label_to_values, "SRC_PORT0", config->SRC_PORT0, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -17;

  ret = parse_single_int_val( label_to_values, "SRC_PORT1", config->SRC_PORT1, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -18;

  ret = parse_single_int_val( label_to_values, "DATA_FLOW", config->DATA_FLOW, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -19;

  ret = parse_single_int_val( label_to_values, "SLEEP_TIMEOUT", config->SLEEP_TIMEOUT, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -20;

  ret = parse_single_int_val( label_to_values, "USER_PACKET_DATA", config->USER_PACKET_DATA, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -21;
  

  
  // *************** module parameters ************************************

   // --------------- MODULE_CSRA/B bits -------------------------------------
  if (ignore_missing==0)           // initialize only when reading defaults 
      config->MODULE_CSRA = 0;

  ret = parse_single_bool_val( label_to_values, "MCSRA_CWGROUP_00", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -1;
  if(ret==0) config->MODULE_CSRA = SetOrClrBit(0, config->MODULE_CSRA, bit); 

  ret = parse_single_bool_val( label_to_values, "MCSRA_P4ERUNSTATS_01", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -1;
  if(ret==0) config->MODULE_CSRA = SetOrClrBit(1, config->MODULE_CSRA, bit); 

  ret = parse_single_bool_val( label_to_values, "MCSRA_FPTTCL_03", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -1;
  if(ret==0) config->MODULE_CSRA = SetOrClrBit(3, config->MODULE_CSRA, bit); 

  ret = parse_single_bool_val( label_to_values, "MCSRA_FPCOUNT_04", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -1;
  if(ret==0) config->MODULE_CSRA = SetOrClrBit(4, config->MODULE_CSRA, bit); 

  ret = parse_single_bool_val( label_to_values, "MCSRA_FPVETO_05", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -1;
  if(ret==0) config->MODULE_CSRA = SetOrClrBit(5, config->MODULE_CSRA, bit); 
  
  ret = parse_single_bool_val( label_to_values, "MCSRA_FPEXTCLR_06", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -1;
  if(ret==0) config->MODULE_CSRA = SetOrClrBit(6, config->MODULE_CSRA, bit); 
  
  ret = parse_single_bool_val( label_to_values, "MCSRA_FPPEDGE_07", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -2;
  if(ret==0) config->MODULE_CSRA = SetOrClrBit(7, config->MODULE_CSRA, bit); 
  
  if (ignore_missing==0)           // initialize only when reading defaults 
      config->MODULE_CSRB = 0;
                         
 /* ret = parse_single_bool_val( label_to_values, "MCSRB_TERM01_01", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -3;
  if(ret==0) config->MODULE_CSRB = SetOrClrBit(1, config->MODULE_CSRB, bit);  
 
  ret = parse_single_bool_val( label_to_values, "MCSRB_TERM23_02", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -4;
  if(ret==0) config->MODULE_CSRB = SetOrClrBit(2, config->MODULE_CSRB, bit);  
  */

  ret = parse_single_int_val( label_to_values, "RUN_TYPE", config->RUN_TYPE, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -8;
/*
//   printf("COINCIDENCE_PATTERN = 0x%x\n",config->COINCIDENCE_PATTERN);
   // --------------- COINC PATTERN bits -------------------------------------
  if (ignore_missing==0)           // initialize only when reading defaults  
       config->COINCIDENCE_PATTERN = 0;

  ret = parse_single_bool_val( label_to_values, "COINC_PATTERN_0000", bit, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -5;
  if(ret==0) config->COINCIDENCE_PATTERN = SetOrClrBit(0, config->COINCIDENCE_PATTERN, bit);  

  ret = parse_single_bool_val( label_to_values, "COINC_PATTERN_0001", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -6;
  if(ret==0) config->COINCIDENCE_PATTERN = SetOrClrBit(1, config->COINCIDENCE_PATTERN, bit);  

  ret = parse_single_bool_val( label_to_values, "COINC_PATTERN_0010", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -7;
  if(ret==0) config->COINCIDENCE_PATTERN = SetOrClrBit(2, config->COINCIDENCE_PATTERN, bit);  
  
  ret = parse_single_bool_val( label_to_values, "COINC_PATTERN_0011", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -8;
  if(ret==0) config->COINCIDENCE_PATTERN = SetOrClrBit(3, config->COINCIDENCE_PATTERN, bit);  
  
  ret = parse_single_bool_val( label_to_values, "COINC_PATTERN_0100", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )     return -9;
  if(ret==0) config->COINCIDENCE_PATTERN = SetOrClrBit(4, config->COINCIDENCE_PATTERN, bit);  

  ret = parse_single_bool_val( label_to_values, "COINC_PATTERN_0101", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -10;
  if(ret==0) config->COINCIDENCE_PATTERN = SetOrClrBit(5, config->COINCIDENCE_PATTERN, bit);  

  ret = parse_single_bool_val( label_to_values, "COINC_PATTERN_0110", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -11;  
  if(ret==0) config->COINCIDENCE_PATTERN = SetOrClrBit(6, config->COINCIDENCE_PATTERN, bit);  

  ret = parse_single_bool_val( label_to_values, "COINC_PATTERN_0111", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -12;  
  if(ret==0) config->COINCIDENCE_PATTERN = SetOrClrBit(7, config->COINCIDENCE_PATTERN, bit);  

  ret = parse_single_bool_val( label_to_values, "COINC_PATTERN_1000", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -13;  
  if(ret==0) config->COINCIDENCE_PATTERN = SetOrClrBit(8, config->COINCIDENCE_PATTERN, bit);  

  ret = parse_single_bool_val( label_to_values, "COINC_PATTERN_1001", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -14;
  if(ret==0) config->COINCIDENCE_PATTERN = SetOrClrBit(9, config->COINCIDENCE_PATTERN, bit);  
                                         
  ret = parse_single_bool_val( label_to_values, "COINC_PATTERN_1010", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -15;
  if(ret==0) config->COINCIDENCE_PATTERN = SetOrClrBit(10, config->COINCIDENCE_PATTERN, bit);  
                                         
  ret = parse_single_bool_val( label_to_values, "COINC_PATTERN_1011", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -16;
  if(ret==0) config->COINCIDENCE_PATTERN = SetOrClrBit(11, config->COINCIDENCE_PATTERN, bit);  
                                         
  ret = parse_single_bool_val( label_to_values, "COINC_PATTERN_1100", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -17;
  if(ret==0) config->COINCIDENCE_PATTERN = SetOrClrBit(12, config->COINCIDENCE_PATTERN, bit);  

  ret = parse_single_bool_val( label_to_values, "COINC_PATTERN_1101", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -18;
  if(ret==0) config->COINCIDENCE_PATTERN = SetOrClrBit(13, config->COINCIDENCE_PATTERN, bit);  
                                         
  ret = parse_single_bool_val( label_to_values, "COINC_PATTERN_1110", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -19;
  if(ret==0) config->COINCIDENCE_PATTERN = SetOrClrBit(14, config->COINCIDENCE_PATTERN, bit);  
                                         
  ret = parse_single_bool_val( label_to_values, "COINC_PATTERN_1111", bit, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -20;
  if(ret==0) config->COINCIDENCE_PATTERN = SetOrClrBit(15, config->COINCIDENCE_PATTERN, bit);  
*/                                         
//   printf("COINCIDENCE_PATTERN = 0x%x\n",config->COINCIDENCE_PATTERN);

  // --------------- Other module parameters -------------------------------------

  //ret = parse_single_int_val( label_to_values, "MAX_EVENTS", config->MAX_EVENTS, ignore_missing ) ;
  //if( (ignore_missing==0 && ret==1) || (ret<0) )   return -21;
  
  //ret = parse_single_dbl_val( label_to_values, "COINCIDENCE_WINDOW", config->COINCIDENCE_WINDOW, ignore_missing ) ;
  //if( (ignore_missing==0 && ret==1) || (ret<0) )   return -22;

  ret = parse_single_int_val( label_to_values, "SYNC_AT_START", config->SYNC_AT_START, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -23;

  ret = parse_single_int_val( label_to_values, "SLOW_FILTER_RANGE", config->SLOW_FILTER_RANGE, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -24;
  
  ret = parse_single_int_val( label_to_values, "FAST_FILTER_RANGE", config->FAST_FILTER_RANGE, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -25;
  
  //ret = parse_single_int_val( label_to_values, "FASTTRIG_BACKPLANEENA", config->FASTTRIG_BACKPLANEENA, ignore_missing ) ;
  //if( (ignore_missing==0 && ret==1) || (ret<0) )   return -26;

  //ret = parse_single_int_val( label_to_values, "TRIG_CONFIG0", config->TRIG_CONFIG0, ignore_missing ) ;
  //if( (ignore_missing==0 && ret==1) || (ret<0) )   return -27;
  
  //ret = parse_single_int_val( label_to_values, "TRIG_CONFIG1", config->TRIG_CONFIG1, ignore_missing ) ;
  //if( (ignore_missing==0 && ret==1) || (ret<0) )   return -28;

  //ret = parse_single_int_val( label_to_values, "TRIG_CONFIG2", config->TRIG_CONFIG2, ignore_missing ) ;
  //if( (ignore_missing==0 && ret==1) || (ret<0) )   return -29;

  //ret = parse_single_int_val( label_to_values, "TRIG_CONFIG3", config->TRIG_CONFIG3, ignore_missing ) ;
  //if( (ignore_missing==0 && ret==1) || (ret<0) )   return -30;

  ret = parse_single_int_val( label_to_values, "GROUPMODE_FIP", config->GROUPMODE_FIP, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -31;

  ret = parse_single_int_val( label_to_values, "GATE_LENGTH", config->GATE_LENGTH, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -32;

  ret = parse_single_int_val( label_to_values, "VETO_MODE", config->VETO_MODE, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -33;
   
  ret = parse_single_int_val( label_to_values, "DYNODE_LENGTH", config->DYNODE_LENGTH, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -34;
 
  ret = parse_single_int_val( label_to_values, "TTCL_APPR_WINDOW", config->TTCL_APPR_WINDOW, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )   return -35;
 


  //unsigned int MOD_U4, MOD_U3, MOD_U2, MOD_U1, MOD_U0;

  // *************** channel parameters ************************************

     // --------------- Channel CSR bits -------------------------------------
  
   if (ignore_missing==0)           // initialize only when reading defaults 
   {
      for( int i = 0; i < NCHANNELS; ++i )
     {
       config->CHANNEL_CSRA[i] = 0;
       config->CHANNEL_CSRB[i] = 0;
       config->CHANNEL_CSRC[i] = 0;
     }
  }

  ret = parse_multiple_bool_val( label_to_values, "CCSRA_FTRIGSEL_00", bits, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -26;
  if(ret==0) 
     for( int i = 0; i < NCHANNELS; ++i )
       config->CHANNEL_CSRA[i] = SetOrClrBit(0, config->CHANNEL_CSRA[i], bits[i]);  

  ret = parse_multiple_bool_val( label_to_values, "CCSRA_EXTTRIGSEL_01", bits, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -27;
  if(ret==0) 
     for( int i = 0; i < NCHANNELS; ++i )
       config->CHANNEL_CSRA[i] = SetOrClrBit(1, config->CHANNEL_CSRA[i], bits[i]);  
                               
  ret = parse_multiple_bool_val( label_to_values, "CCSRA_GOOD_02", bits, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -28;
  if(ret==0) 
    for( int i = 0; i < NCHANNELS; ++i )
       config->CHANNEL_CSRA[i] = SetOrClrBit(2, config->CHANNEL_CSRA[i], bits[i]);  
                               
  ret = parse_multiple_bool_val( label_to_values, "CCSRA_CHANTRIGSEL_03", bits, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -29;
  if(ret==0) 
    for( int i = 0; i < NCHANNELS; ++i )
       config->CHANNEL_CSRA[i] = SetOrClrBit(3, config->CHANNEL_CSRA[i], bits[i]);  
                               
  ret = parse_multiple_bool_val( label_to_values, "CCSRA_SYNCDATAACQ_04", bits, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -30;
  if(ret==0) 
    for( int i = 0; i < NCHANNELS; ++i )
      config->CHANNEL_CSRA[i] = SetOrClrBit(4, config->CHANNEL_CSRA[i], bits[i]);  
                              
  ret = parse_multiple_bool_val( label_to_values, "CCSRA_INVERT_05", bits, ignore_missing) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -31;
  if(ret==0) 
    for( int i = 0; i < NCHANNELS; ++i )
      config->CHANNEL_CSRA[i] = SetOrClrBit(5, config->CHANNEL_CSRA[i], bits[i]);  
                            
  ret = parse_multiple_bool_val( label_to_values, "CCSRA_VETOENA_06", bits, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -32;
  if(ret==0) 
   for( int i = 0; i < NCHANNELS; ++i )
     config->CHANNEL_CSRA[i] = SetOrClrBit(6, config->CHANNEL_CSRA[i], bits[i]);  

  ret = parse_multiple_bool_val( label_to_values, "CCSRA_HISTOE_07", bits, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -26;
  if(ret==0) 
     for( int i = 0; i < NCHANNELS; ++i )
       config->CHANNEL_CSRA[i] = SetOrClrBit(7, config->CHANNEL_CSRA[i], bits[i]);  

  ret = parse_multiple_bool_val( label_to_values, "CCSRA_TRACEENA_08", bits, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -27;
  if(ret==0) 
     for( int i = 0; i < NCHANNELS; ++i )
       config->CHANNEL_CSRA[i] = SetOrClrBit(8, config->CHANNEL_CSRA[i], bits[i]);  
                               
  ret = parse_multiple_bool_val( label_to_values, "CCSRA_QDCENA_09", bits, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -28;
  if(ret==0) 
    for( int i = 0; i < NCHANNELS; ++i )
       config->CHANNEL_CSRA[i] = SetOrClrBit(9, config->CHANNEL_CSRA[i], bits[i]);  
                               
  ret = parse_multiple_bool_val( label_to_values, "CCSRA_CFDMODE_10", bits, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -29;
  if(ret==0) 
    for( int i = 0; i < NCHANNELS; ++i )
       config->CHANNEL_CSRA[i] = SetOrClrBit(10, config->CHANNEL_CSRA[i], bits[i]);  
                               
  ret = parse_multiple_bool_val( label_to_values, "CCSRA_GLOBTRIG_11", bits, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -30;
  if(ret==0) 
    for( int i = 0; i < NCHANNELS; ++i )
      config->CHANNEL_CSRA[i] = SetOrClrBit(11, config->CHANNEL_CSRA[i], bits[i]);  
                              
  ret = parse_multiple_bool_val( label_to_values, "CCSRA_ESUMSENA_12", bits, ignore_missing) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -31;
  if(ret==0) 
    for( int i = 0; i < NCHANNELS; ++i )
      config->CHANNEL_CSRA[i] = SetOrClrBit(12, config->CHANNEL_CSRA[i], bits[i]);  
                            
  ret = parse_multiple_bool_val( label_to_values, "CCSRA_CHANTRIG_13", bits, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -32;
  if(ret==0) 
    for( int i = 0; i < NCHANNELS; ++i )
     config->CHANNEL_CSRA[i] = SetOrClrBit(13, config->CHANNEL_CSRA[i], bits[i]);  

  ret = parse_multiple_bool_val( label_to_values, "CCSRA_ENARELAY_14", bits, ignore_missing) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -31;
  if(ret==0) 
    for( int i = 0; i < NCHANNELS; ++i )
      config->CHANNEL_CSRA[i] = SetOrClrBit(14, config->CHANNEL_CSRA[i], bits[i]);  
                            
  ret = parse_multiple_bool_val( label_to_values, "CCSRA_PILEUPCTRL_15", bits, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -32;
  if(ret==0) 
   for( int i = 0; i < NCHANNELS; ++i )
     config->CHANNEL_CSRA[i] = SetOrClrBit(15, config->CHANNEL_CSRA[i], bits[i]);       
 
  //   for( int i = 0; i < NCHANNELS; ++i )
  //     printf("CHANNEL_CSRA = 0x%x\n",config->CHANNEL_CSRA[i]);                       

  //CSRC
  ret = parse_multiple_bool_val( label_to_values, "CCSRC_INVERSEPILEUP_00", bits, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -33;
  if(ret==0) 
    for( int i = 0; i < NCHANNELS; ++i )
      config->CHANNEL_CSRC[i] = SetOrClrBit(0, config->CHANNEL_CSRC[i], bits[i]);  
 
  ret = parse_multiple_bool_val( label_to_values, "CCSRC_ENAENERGYCUT_01", bits, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -34;
  if(ret==0) 
    for( int i = 0; i < NCHANNELS; ++i )
      config->CHANNEL_CSRC[i] = SetOrClrBit(1, config->CHANNEL_CSRC[i], bits[i]);  

  ret = parse_multiple_bool_val( label_to_values, "CCSRC_GROUPTRIGSEL_02", bits, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -35;
  if(ret==0) 
    for( int i = 0; i < NCHANNELS; ++i )
      config->CHANNEL_CSRC[i] = SetOrClrBit(2, config->CHANNEL_CSRC[i], bits[i]);   

  ret = parse_multiple_bool_val( label_to_values, "CCSRC_CHANVETOSEL_03", bits, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -2;
  if(ret==0) 
    for( int i = 0; i < NCHANNELS; ++i )
      config->CHANNEL_CSRC[i] = SetOrClrBit(3, config->CHANNEL_CSRC[i], bits[i]);   

  ret = parse_multiple_bool_val( label_to_values, "CCSRC_MODVETOSEL_04", bits, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -36;
  if(ret==0) 
    for( int i = 0; i < NCHANNELS; ++i )
      config->CHANNEL_CSRC[i] = SetOrClrBit(4, config->CHANNEL_CSRC[i], bits[i]);   
    
  ret = parse_multiple_bool_val( label_to_values, "CCSRC_EXTTSENA_05", bits, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -37;
  if(ret==0) 
    for( int i = 0; i < NCHANNELS; ++i )
      config->CHANNEL_CSRC[i] = SetOrClrBit(5, config->CHANNEL_CSRC[i], bits[i]);   
 
  ret = parse_multiple_bool_val( label_to_values, "CCSRC_RBADDIS_06", bits, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -37;
  if(ret==0) 
    for( int i = 0; i < NCHANNELS; ++i )
      config->CHANNEL_CSRC[i] = SetOrClrBit(6, config->CHANNEL_CSRC[i], bits[i]);  

  ret = parse_multiple_bool_val( label_to_values, "CCSRC_PAUSEPILEUP_07", bits, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -37;
  if(ret==0) 
    for( int i = 0; i < NCHANNELS; ++i )
      config->CHANNEL_CSRC[i] = SetOrClrBit(7, config->CHANNEL_CSRC[i], bits[i]);   

  ret = parse_multiple_bool_val( label_to_values, "CCSRC_LOCAL_ENERGY_09", bits, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -37;
  if(ret==0) 
    for( int i = 0; i < NCHANNELS; ++i )
      config->CHANNEL_CSRC[i] = SetOrClrBit(9, config->CHANNEL_CSRC[i], bits[i]);  
        
  ret = parse_multiple_bool_val( label_to_values, "CCSRC_SIMADC_10", bits, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -37;
  if(ret==0) 
    for( int i = 0; i < NCHANNELS; ++i )
      config->CHANNEL_CSRC[i] = SetOrClrBit(10, config->CHANNEL_CSRC[i], bits[i]);   

  ret = parse_multiple_bool_val( label_to_values, "CCSRC_GATEADC_11", bits, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )    return -37;
  if(ret==0) 
    for( int i = 0; i < NCHANNELS; ++i )
      config->CHANNEL_CSRC[i] = SetOrClrBit(11, config->CHANNEL_CSRC[i], bits[i]);  
  

      // --------------- other channel parameters -------------------------------------
  ret = parse_multiple_dbl_val( label_to_values, "ANALOG_GAIN", config->ANALOG_GAIN, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -20;
  
  ret = parse_multiple_dbl_val( label_to_values, "DIG_GAIN", config->DIG_GAIN, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -21;
  
  ret = parse_multiple_dbl_val( label_to_values, "VOFFSET", config->VOFFSET, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -22;
      
  ret = parse_multiple_dbl_val( label_to_values, "ENERGY_RISETIME", config->ENERGY_RISETIME, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -15;
  
  ret = parse_multiple_dbl_val( label_to_values, "ENERGY_FLATTOP", config->ENERGY_FLATTOP, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -16;
  
  ret = parse_multiple_dbl_val( label_to_values, "TRIGGER_RISETIME", config->TRIGGER_RISETIME, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -17;
  
  ret = parse_multiple_dbl_val( label_to_values, "TRIGGER_FLATTOP", config->TRIGGER_FLATTOP, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -18;
  
  ret = parse_multiple_dbl_val( label_to_values, "TRIGGER_THRESHOLD", config->TRIGGER_THRESHOLD, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -19;
  
  ret = parse_multiple_dbl_val( label_to_values, "THRESH_WIDTH", config->THRESH_WIDTH, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -27;
    
  ret = parse_multiple_dbl_val( label_to_values, "TRACE_LENGTH", config->TRACE_LENGTH, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -23;
  
  ret = parse_multiple_dbl_val( label_to_values, "TRACE_DELAY", config->TRACE_DELAY, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -24;
  
  ret = parse_multiple_int_val( label_to_values, "BINFACTOR", config->BINFACTOR, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -27;

  ret = parse_multiple_int_val( label_to_values, "INTEGRATOR", config->INTEGRATOR, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -33;

  ret = parse_multiple_int_val( label_to_values, "BLCUT", config->BLCUT, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -29;

  ret = parse_multiple_dbl_val( label_to_values, "BASELINE_PERCENT", config->BASELINE_PERCENT, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -31;

  ret = parse_multiple_int_val( label_to_values, "BLAVG", config->BLAVG, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -37;

  ret = parse_multiple_dbl_val( label_to_values, "TAU", config->TAU, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -28;
     
  ret = parse_multiple_dbl_val( label_to_values, "XDT", config->XDT, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -30;
  
  ret = parse_multiple_int_val( label_to_values, "MULTIPLICITY_MASKL", config->MULTIPLICITY_MASKL, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -29;

  ret = parse_multiple_int_val( label_to_values, "MULTIPLICITY_MASKM", config->MULTIPLICITY_MASKM, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -29;

  ret = parse_multiple_int_val( label_to_values, "MULTIPLICITY_MASKH", config->MULTIPLICITY_MASKH, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -29;

  ret = parse_multiple_int_val( label_to_values, "MULTIPLICITY_MASKX", config->MULTIPLICITY_MASKX, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -29;

  ret = parse_multiple_dbl_val( label_to_values, "FASTTRIG_BACKLEN", config->FASTTRIG_BACKLEN, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -29;

  ret = parse_multiple_int_val( label_to_values, "CFD_THRESHOLD", config->CFD_THRESHOLD, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -27;

  ret = parse_multiple_int_val( label_to_values, "CFD_DELAY", config->CFD_DELAY, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -29;

  ret = parse_multiple_int_val( label_to_values, "CFD_SCALE", config->CFD_SCALE, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -29;

  ret = parse_multiple_dbl_val( label_to_values, "EXTTRIG_STRETCH", config->EXTTRIG_STRETCH, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -29;

  ret = parse_multiple_dbl_val( label_to_values, "VETO_STRETCH", config->VETO_STRETCH, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -29;

  ret = parse_multiple_dbl_val( label_to_values, "CHANTRIG_STRETCH", config->CHANTRIG_STRETCH, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -29;

  ret = parse_multiple_dbl_val( label_to_values, "EXTERN_DELAYLEN", config->EXTERN_DELAYLEN, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -29;

  ret = parse_multiple_dbl_val( label_to_values, "FTRIGOUT_DELAY", config->FTRIGOUT_DELAY, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -29;

  ret = parse_multiple_int_val( label_to_values, "QDCLen0", config->QDCLen0, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -38;
  
  ret = parse_multiple_int_val( label_to_values, "QDCLen1", config->QDCLen1, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -39;
 
  ret = parse_multiple_int_val( label_to_values, "QDCLen2", config->QDCLen2, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -38;
  
  ret = parse_multiple_int_val( label_to_values, "QDCLen3", config->QDCLen3, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -39;
  
  ret = parse_multiple_int_val( label_to_values, "QDCLen4", config->QDCLen4, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -38;
  
  ret = parse_multiple_int_val( label_to_values, "QDCLen5", config->QDCLen5, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -39;
  
  ret = parse_multiple_int_val( label_to_values, "QDCLen6", config->QDCLen6, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -38;
  
  ret = parse_multiple_int_val( label_to_values, "QDCLen7", config->QDCLen7, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -39;

  ret = parse_multiple_dbl_val( label_to_values, "QDCDel0", config->QDCDel0, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -38;
  
  ret = parse_multiple_dbl_val( label_to_values, "QDCDel1", config->QDCDel1, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -39;
 
  ret = parse_multiple_dbl_val( label_to_values, "QDCDel2", config->QDCDel2, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -38;
  
  ret = parse_multiple_dbl_val( label_to_values, "QDCDel3", config->QDCDel3, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -39;
  
  ret = parse_multiple_dbl_val( label_to_values, "QDCDel4", config->QDCDel4, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -38;
  
  ret = parse_multiple_dbl_val( label_to_values, "QDCDel5", config->QDCDel5, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -39;
  
  ret = parse_multiple_dbl_val( label_to_values, "QDCDel6", config->QDCDel6, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -38;
  
  ret = parse_multiple_dbl_val( label_to_values, "QDCDel7", config->QDCDel7, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -39;

  ret = parse_multiple_int_val( label_to_values, "QDC_DIV", config->QDC_DIV, ignore_missing ) ;
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -38;
  
  ret = parse_multiple_int_val( label_to_values, "PSA_THRESHOLD", config->PSA_THRESHOLD, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -39;

  ret = parse_multiple_int_val( label_to_values, "EMIN", config->EMIN, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -39;

  ret = parse_multiple_int_val( label_to_values, "ELO", config->ELO, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -39;

  ret = parse_multiple_int_val( label_to_values, "EHI", config->EHI, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -39;

  ret = parse_multiple_int_val( label_to_values, "GROUPMODE_CH", config->GROUPMODE_CH, ignore_missing );
  if( (ignore_missing==0 && ret==1) || (ret<0) )  return -39;

 
    if(ignore_missing==1) 
  {
      cerr << endl;
  }

  return 0;
}//init_PixieNetFippiConfig_from_file(...)
