/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkMySQLDatabase.h,v $

  Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/
/*----------------------------------------------------------------------------
  Copyright (c) Sandia Corporation
  See Copyright.txt or http://www.paraview.org/HTML/Copyright.html for details.
  ----------------------------------------------------------------------------*/
// .NAME vtkMySQLDatabase - maintain a connection to a MySQL database
//
// .SECTION Description
//
// This class provides a VTK interface to MySQL
// (http://www.mysql.com).  Unlike file-based databases like SQLite, you
// talk to MySQL through a client/server connection.  You must specify
// the hostname, (optional) port to connect to, username, password and
// database name in order to connect.
//
// .SECTION See Also
// vtkMySQLQuery

#ifndef __vtkMySQLDatabase_h
#define __vtkMySQLDatabase_h

#include "vtkSQLDatabase.h"

class vtkSQLQuery;
class vtkMySQLQuery;
class vtkStringArray;
class vtkMySQLDatabasePrivate;

class VTK_IO_EXPORT vtkMySQLDatabase : public vtkSQLDatabase
{
//BTX
  friend class vtkMySQLQuery;
//ETX

public:
  vtkTypeRevisionMacro(vtkMySQLDatabase, vtkSQLDatabase);
  void PrintSelf(ostream& os, vtkIndent indent);
  static vtkMySQLDatabase *New();

  // Description:
  // Open a new connection to the database.  You need to set the
  // filename before calling this function.  Returns true if the
  // database was opened successfully; false otherwise.
  bool Open();

  // Description:
  // Close the connection to the database.
  void Close();
  
  // Description:
  // Return whether the database has an open connection
  bool IsOpen();

  // Description:
  // Return an empty query on this database.
  vtkSQLQuery* GetQueryInstance();
  
  // Description:
  // Get the list of tables from the database
  vtkStringArray* GetTables();
    
  // Description:
  // Get the list of fields for a particular table
  vtkStringArray* GetRecord(const char *table);

  // Description:
  // Return whether a feature is supported by the database.
  bool IsSupported(int feature);
  
  // Description:
  // Did the last operation generate an error
  bool HasError();
  
  // Description:
  // Get the last error text from the database
  const char* GetLastErrorText();
  
  // Description:
  // String representing database type (e.g. "mysql").
  vtkGetStringMacro(DatabaseType);

  // Description:
  // The database server host name.
  vtkSetStringMacro(HostName);
  vtkGetStringMacro(HostName);

  // Description:
  // The user name for connecting to the database server.
  vtkSetStringMacro(User);
  vtkGetStringMacro(User);

  // Description:
  // The user's password for connecting to the database server.
  vtkSetStringMacro(Password);
  vtkGetStringMacro(Password);

  // Description:
  // The name of the database to connect to.
  vtkSetStringMacro(DatabaseName);
  vtkGetStringMacro(DatabaseName);

  // Description:
  // Additional options for the database.
  vtkSetStringMacro(ConnectOptions);
  vtkGetStringMacro(ConnectOptions);

  // Description:
  // The port used for connecting to the database.
  vtkSetClampMacro(ServerPort, int, 0, VTK_INT_MAX);
  vtkGetMacro(ServerPort, int);
  
  // Description:
  // Get the URL of the database.
  virtual vtkStdString GetURL();

  // Description:
  // Return the SQL string with the syntax of the preamble following a
  // "CREATE TABLE" SQL statement.
  // NB: this method implements the MySQL-specific IF NOT EXISTS syntax,
  // used when b = false.
  virtual vtkStdString GetTablePreamble( bool b ) { return b ? vtkStdString() :"IF NOT EXISTS "; }
 
  // Description:
  // Return the SQL string with the syntax to create a column inside a
  // "CREATE TABLE" SQL statement.
  // NB1: this method implements the MySQL-specific syntax:
  // `<column name>` <column type> <column attributes>
  // NB2: if a column has type SERIAL in the schema, this will be turned
  // into INT NOT NULL AUTO_INCREMENT. Therefore, one should not pass
  // NOT NULL as an attribute of a column whose type is SERIAL.
  virtual vtkStdString GetColumnSpecification( vtkSQLDatabaseSchema* schema,
                                               int tblHandle,
                                               int colHandle );
 
  // Description:
  // Return the SQL string with the syntax to create an index inside a
  // "CREATE TABLE" SQL statement.
  // NB1: this method implements the MySQL-specific syntax:
  // <index type> [<index name>]  (`<column name 1>`,... )
  // NB2: since MySQL supports INDEX creation within a CREATE TABLE statement,
  // skipped is always returned false.
  virtual vtkStdString GetIndexSpecification( vtkSQLDatabaseSchema* schema,
                                              int tblHandle,
                                              int idxHandle,
                                              bool& skipped );

  // Description:
  // Create a new database, optionally dropping any existing database of the same name.
  // Returns true when the database is properly created and false on failure.
  bool CreateDatabase( const char* dbName, bool dropExisting );

  // Description:
  // Drop a database if it exists.
  // Returns true on success and false on failure.
  bool DropDatabase( const char* dbName );

protected:
  vtkMySQLDatabase();
  ~vtkMySQLDatabase();

private:
  // We want this to be private, a user of this class
  // should not be setting this for any reason
  vtkSetStringMacro(DatabaseType);
  
  vtkStringArray *Tables;
  vtkStringArray *Record;

  char* DatabaseType;
  char* HostName;
  char* User;
  char* Password;
  char* DatabaseName;
  int ServerPort;
  char* ConnectOptions;

//BTX
  vtkMySQLDatabasePrivate* const Private;
//ETX

  vtkMySQLDatabase(const vtkMySQLDatabase &); // Not implemented.
  void operator=(const vtkMySQLDatabase &); // Not implemented.
};

#endif // __vtkMySQLDatabase_h

