/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkStringToCategory.h,v $

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
// .NAME vtkStringToCategory - Creates a category array from a string array
//
// .SECTION Description
// vtkStringToCategory creates an integer array named "category" based on the
// values in a string array.  You may use this filter to create an array that
// you may use to color points/cells by the values in a string array.  Currently
// there is not support to color by a string array directly.
// The category values will range from zero to N-1,
// where N is the number of distinct strings in the string array.  Set the string
// array to process with SetInputArrayToProcess(0,0,0,...).  The array may be in
// the point, cell, or field data of the data object.

#ifndef __vtkStringToCategory_h
#define __vtkStringToCategory_h

#include "vtkDataObjectAlgorithm.h"

class VTK_INFOVIS_EXPORT vtkStringToCategory : public vtkDataObjectAlgorithm
{
public:
  static vtkStringToCategory* New();
  vtkTypeRevisionMacro(vtkStringToCategory,vtkDataObjectAlgorithm);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // The name to give to the output vtkIntArray of category values.
  vtkSetStringMacro(CategoryArrayName);
  vtkGetStringMacro(CategoryArrayName);
  
  // Description:
  // This is required to capture REQUEST_DATA_OBJECT requests.
  virtual int ProcessRequest(vtkInformation* request, 
                             vtkInformationVector** inputVector,
                             vtkInformationVector* outputVector);

protected:
  vtkStringToCategory();
  ~vtkStringToCategory();

  // Description:
  // Creates the same output type as the input type.
  virtual int RequestDataObject(vtkInformation* request,
                                vtkInformationVector** inputVector,
                                vtkInformationVector* outputVector);
  
  int RequestData(
    vtkInformation*, 
    vtkInformationVector**, 
    vtkInformationVector*);

  char *CategoryArrayName;
    
private:
  vtkStringToCategory(const vtkStringToCategory&); // Not implemented
  void operator=(const vtkStringToCategory&);   // Not implemented
};

#endif

