/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkQtTimePointUtility.h,v $

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
// .NAME vtkQtTimePointUtility - performs common time operations
//
// .SECTION Description
// vtkQtTimePointUtility is provides methods to perform common time operations.

#ifndef __vtkQtTimePointUtility_h
#define __vtkQtTimePointUtility_h

#include "QVTKWin32Header.h"
#include "vtkObject.h"
#include <QDateTime>

class QVTK_EXPORT vtkQtTimePointUtility : public vtkObject
{
public:
  vtkTypeRevisionMacro(vtkQtTimePointUtility,vtkObject);

  static QDateTime TimePointToQDateTime(vtkTypeUInt64 time);
  static vtkTypeUInt64 QDateTimeToTimePoint(QDateTime time);  
  static vtkTypeUInt64 QDateToTimePoint(QDate date);  
  static vtkTypeUInt64 QTimeToTimePoint(QTime time);  

protected:
  vtkQtTimePointUtility() {};
  ~vtkQtTimePointUtility() {};

private:
  vtkQtTimePointUtility(const vtkQtTimePointUtility&);  // Not implemented.
  void operator=(const vtkQtTimePointUtility&);  // Not implemented.
};

#endif
