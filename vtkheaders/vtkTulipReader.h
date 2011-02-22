/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkTulipReader.h,v $

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
// .NAME vtkTulipReader - Reads tulip graph files.
//
// .SECTION Description
// vtkTulipReader reads in files in the Tulip format.
// An example is the following
// <code>
// (nodes 0 1 2 3 4 5 6 7 8 9)
// (edge 0 0 1)
// (edge 1 1 2)
// (edge 2 2 3)
// (edge 3 3 4)
// (edge 4 4 5)
// (edge 5 5 6)
// (edge 6 6 7)
// (edge 7 7 8)
// (edge 8 8 9)
// (edge 9 9 0)
// (edge 10 0 5)
// (edge 11 2 7)
// (edge 12 4 9)
// </code>
// where "nodes" defines all the nodes ids in the graph, and "edge"
// is a triple of edge id, source vertex id, and target vertex id.
// The graph is read in as undirected graph.
// NOTE: This currently only supports reading connectivity information.
// Display information is discarded.

#ifndef _vtkTulipReader_h
#define _vtkTulipReader_h

#include "vtkUndirectedGraphAlgorithm.h"

class VTK_INFOVIS_EXPORT vtkTulipReader : public vtkUndirectedGraphAlgorithm
{
public:
  static vtkTulipReader *New();
  vtkTypeRevisionMacro(vtkTulipReader, vtkUndirectedGraphAlgorithm);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // The Chaco file name.
  vtkGetStringMacro(FileName);
  vtkSetStringMacro(FileName);

protected:
  vtkTulipReader();
  ~vtkTulipReader();

  virtual int RequestData(
    vtkInformation *, 
    vtkInformationVector **, 
    vtkInformationVector *);

private:
  char* FileName;

  vtkTulipReader(const vtkTulipReader&);  // Not implemented.
  void operator=(const vtkTulipReader&);  // Not implemented.
};

#endif // _vtkTulipReader_h

