/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkRISReader.h,v $

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
// .NAME vtkRISReader - reader for RIS files
//
// .SECTION Description
// RIS is a tagged format for expressing bibliographic citations.  Data is
// structured as a collection of records with each record composed of
// one-to-many fields.  See
//
// http://en.wikipedia.org/wiki/RIS_(file_format)
// http://www.refman.com/support/risformat_intro.asp
// http://www.adeptscience.co.uk/kb/article/A626
//
// for details.  vtkRISReader will convert an RIS file into a vtkTable, with
// the set of table columns determined dynamically from the contents of the
// file.

#ifndef __vtkRISReader_h
#define __vtkRISReader_h

#include "vtkTableAlgorithm.h"

class vtkTable;

class VTK_INFOVIS_EXPORT vtkRISReader : public vtkTableAlgorithm
{
public:
  static vtkRISReader* New();
  vtkTypeRevisionMacro(vtkRISReader,vtkTableAlgorithm);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // Set/get the file to load
  vtkGetStringMacro(FileName);
  vtkSetStringMacro(FileName);
  
  // Description:
  // Set/get the delimiter to be used for concatenating field data (default: ";")
  vtkGetStringMacro(Delimiter);
  vtkSetStringMacro(Delimiter);

  // Description:
  // Set/get the maximum number of records to read from the file (zero = unlimited)
  vtkGetMacro(MaxRecords,int);
  vtkSetMacro(MaxRecords,int);

 protected:
  vtkRISReader();
  ~vtkRISReader();

  int RequestData(
    vtkInformation*, 
    vtkInformationVector**, 
    vtkInformationVector*);

  char* FileName;
  char* Delimiter;
  int MaxRecords;

private:
  vtkRISReader(const vtkRISReader&); // Not implemented
  void operator=(const vtkRISReader&);   // Not implemented
};

#endif
