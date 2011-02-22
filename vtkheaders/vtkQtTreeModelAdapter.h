/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkQtTreeModelAdapter.h,v $

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
// .NAME vtkQtTreeModelAdapter - Adapts a tree to a Qt item model.
//
// .SECTION Description
// vtkQtTreeModelAdapter is a QAbstractItemModel with a vtkTree as its
// underlying data model. 
//
// .SECTION See also
// vtkQtAbstractModelAdapter vtkQtTableModelAdapter

#ifndef __vtkQtTreeModelAdapter_h
#define __vtkQtTreeModelAdapter_h

#include "QVTKWin32Header.h"
#include "vtkType.h"
#include "vtkSelection.h"

#include "vtkQtAbstractModelAdapter.h"
#include <QHash>

class vtkTree;

class QVTK_EXPORT vtkQtTreeModelAdapter : public vtkQtAbstractModelAdapter
{
  Q_OBJECT

public:
  vtkQtTreeModelAdapter(QObject *parent = 0, vtkTree* tree = 0);
  ~vtkQtTreeModelAdapter();
  
  // Description:
  // Set/Get the VTK data object as input to this adapter
  virtual void SetVTKDataObject(vtkDataObject *data);
  virtual vtkDataObject* GetVTKDataObject() const;
  
  vtkIdType IdToPedigree(vtkIdType id) const;
  vtkIdType PedigreeToId(vtkIdType pedigree) const;
  QModelIndex PedigreeToQModelIndex(vtkIdType id) const;
  vtkIdType QModelIndexToPedigree(QModelIndex index) const;
  
  virtual void SetKeyColumnName(const char* name);

  // Description:
  // Set up the model based on the current tree.
  void setTree(vtkTree* t);
  vtkTree* tree() const { return this->Tree; }
  
  QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
  bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole);
  Qt::ItemFlags flags(const QModelIndex &index) const;
  QVariant headerData(int section, Qt::Orientation orientation,
                      int role = Qt::DisplayRole) const;
  QModelIndex index(vtkIdType index) const;
  QModelIndex index(int row, int column,
                    const QModelIndex &parent = QModelIndex()) const;
  QModelIndex parent(const QModelIndex &index) const;
  int rowCount(const QModelIndex &parent = QModelIndex()) const;
  int columnCount(const QModelIndex &parent = QModelIndex()) const;

protected:
  void treeModified();
  void GenerateHashMap(vtkIdType & row, vtkIdType id, QModelIndex index);
  
  vtkTree* Tree;
  unsigned long TreeMTime;
  QHash<vtkIdType, vtkIdType> IdToPedigreeHash;
  QHash<vtkIdType, QModelIndex> PedigreeToIndexHash;
  QHash<QModelIndex, vtkIdType> IndexToIdHash;
  QHash<vtkIdType, vtkIdType> RowToPedigreeHash;

  QHash<QModelIndex, QVariant> IndexToDecoration;
  
private:
  vtkQtTreeModelAdapter(const vtkQtTreeModelAdapter &);  // Not implemented
  void operator=(const vtkQtTreeModelAdapter&);  // Not implemented.
};

#endif
