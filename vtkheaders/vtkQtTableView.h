/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkQtTableView.h,v $

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
// .NAME vtkQtTableView - A VTK view based on a Qt table view.
//
// .SECTION Description
// vtkQtTableView is a VTK view with an underlying QTableView. 
//
// .SECTION Thanks
// Thanks to Brian Wylie from Sandia National Laboratories for implementing
// this class

#ifndef __vtkQtTableView_h
#define __vtkQtTableView_h

#include "QVTKWin32Header.h"
#include "vtkQtItemView.h"

class QTableView;
class vtkQtTableModelAdapter;

class QVTK_EXPORT vtkQtTableView : public vtkQtItemView
{
public:
  static vtkQtTableView *New();
  vtkTypeRevisionMacro(vtkQtTableView, vtkQtItemView);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Description:
  // Set the underlying Qt view.
  virtual void SetItemView(QAbstractItemView*);
  
  // Description:
  // Set the underlying Qt model adapter.
  virtual void SetItemModelAdapter(vtkQtAbstractModelAdapter* qma);
  
  // Description:
  // Get the underlying vtkTable
  virtual vtkTable* GetVTKTable();

protected:
  vtkQtTableView();
  ~vtkQtTableView();

private:
  vtkQtTableView(const vtkQtTableView&);  // Not implemented.
  void operator=(const vtkQtTableView&);  // Not implemented.
  
  QTableView* TableViewPtr;
  vtkQtTableModelAdapter* TableAdapterPtr;
  
  bool IOwnTableView;
  bool IOwnTableAdapter;
};

#endif
