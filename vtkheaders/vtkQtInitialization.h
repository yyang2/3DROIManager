/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkQtInitialization.h,v $

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
// .NAME vtkQtInitialization - Initializes a Qt application.
//
// .SECTION Description
// Utility class that initializes Qt by creating an instance of 
// QCoreApplication in its ctor, if one doesn't already exist.
// This is mainly of use in ParaView with filters that use Qt in
// their implementation - create an instance of vtkQtInitialization
// prior to instantiating any filters that require Qt.

#ifndef __vtkQtInitialization_h
#define __vtkQtInitialization_h

#include "QVTKWin32Header.h"
#include <vtkObject.h>

class QVTK_EXPORT vtkQtInitialization : public vtkObject
{
public:
  static vtkQtInitialization* New();
  vtkTypeRevisionMacro(vtkQtInitialization, vtkObject);
  void PrintSelf(ostream& os, vtkIndent indent);

protected:
  vtkQtInitialization();
  ~vtkQtInitialization();

private:
  vtkQtInitialization(const vtkQtInitialization &); // Not implemented.
  void operator=(const vtkQtInitialization &); // Not implemented.
};

#endif // __vtkQtInitialization_h

