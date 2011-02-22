/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkQtAbstractModelAdapter.h,v $

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
// .NAME vtkQtAbtractModelAdapter - Superclass for Qt model adapters.
//
// .SECTION Description
// vtkQtAbstractModelAdapter is the superclass for classes that adapt
// VTK objects to QAbstractItemModel. This class contains API for converting
// between QModelIndex and VTK ids, as well as some additional specialized
// functionality such as setting a column of data to use as the Qt header
// information.
//
// .SECTION See also
// vtkQtTableModelAdapter vtkQtTreeModelAdapter

#ifndef __vtkQtAbstractModelAdapter_h
#define __vtkQtAbstractModelAdapter_h

#include "QVTKWin32Header.h"
#include "vtkType.h"
#include "vtkSelection.h"
class vtkDataObject;

#include <QAbstractItemModel>

class QModelIndex;

class QVTK_EXPORT vtkQtAbstractModelAdapter : public QAbstractItemModel
{
  Q_OBJECT

public:

  // The view types.
  enum {
    FULL_VIEW,
    DATA_VIEW,
    METADATA_VIEW
  };

  vtkQtAbstractModelAdapter(QObject* p) : 
    QAbstractItemModel(p), 
    ViewType(FULL_VIEW),
    KeyColumn(-1),
    DataStartColumn(-1),
    DataEndColumn(-1),
    ViewRows(true)
    { }

  // Description:
  // Set/Get the VTK data object as input to this adapter
  virtual void SetVTKDataObject(vtkDataObject *data) = 0;
  virtual vtkDataObject* GetVTKDataObject() const = 0;
  
  // Description:
  // Mapping methods for converting from VTK land to Qt land
  virtual vtkIdType IdToPedigree(vtkIdType id) const = 0;
  virtual vtkIdType PedigreeToId(vtkIdType pedigree) const = 0;
  virtual QModelIndex PedigreeToQModelIndex(vtkIdType id) const = 0;
  virtual vtkIdType QModelIndexToPedigree(QModelIndex index) const = 0;

  // Description:
  // Set/Get the view type.
  // FULL_VIEW gives access to all the data.
  // DATA_VIEW gives access only to the data columns.
  // METADATA_VIEW gives access only to the metadata (non-data) columns.
  // The default is FULL_VIEW.
  virtual void SetViewType(int type) { this->ViewType = type; }
  virtual int GetViewType() { return this->ViewType; }

  // Description:
  // Set/Get the key column.
  // The key column is used as the row headers in a table view,
  // and as the first column in a tree view.
  // Set to -1 for no key column.
  // The default is no key column.
  virtual void SetKeyColumn(int col) { this->KeyColumn = col; }
  virtual int GetKeyColumn() { return this->KeyColumn; }
  virtual void SetKeyColumnName(const char* name) = 0;

  // Description:
  // Set the range of columns that specify the main data matrix.
  // The data column range should not include the key column.
  // The default is no data columns.
  virtual void SetDataColumnRange(int c1, int c2)
    { this->DataStartColumn = c1; this->DataEndColumn = c2; }

  virtual bool GetViewRows()
    { return this->ViewRows; }

  // We make the reset() method public because it isn't always possible for
  // an adapter to know when its input has changed, so it must be callable
  // by an outside entity.
  void reset() { QAbstractItemModel::reset(); }

public slots:
  // Description:
  // Sets the view to either rows (standard) or columns.
  // When viewing columns, each row in the item model will contain the name
  // of a column in the underlying data object.
  // This essentially flips the table on its side.
  void SetViewRows(bool b)
    { this->ViewRows = b; this->reset(); emit this->modelChanged(); }

signals:
  void modelChanged();
  
protected:
  virtual int ModelColumnToFieldDataColumn(int col) const;

  int ViewType;
  int KeyColumn;
  int DataStartColumn;
  int DataEndColumn;
  bool ViewRows;
};

#endif
