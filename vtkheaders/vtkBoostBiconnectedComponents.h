/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkBoostBiconnectedComponents.h,v $

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
// .NAME vtkBoostBiconnectedComponents - Find the biconnected components of a graph
//
// .SECTION Description
// The biconnected components of a graph are maximal regions of the graph where
// the removal of any single vertex from the region will not disconnect the
// graph.  Every edge belongs to exactly one biconnected component.  The
// biconnected component of each edge is given in the edge array named
// "biconnected component".  The biconnected component of each vertex is also
// given in the vertex array named "biconnected component".  Cut vertices (or
// articulation points) belong to multiple biconnected components, and break
// the graph apart if removed.  These are indicated by assigning a component
// value of -1.  To get the biconnected components that a cut vertex belongs
// to, traverse its edge list and collect the distinct component ids for its
// incident edges.
//
// .SECTION Caveats
// The boost graph bindings currently only support boost version 1.33.1.
// There are apparently backwards-compatibility issues with later versions.

#ifndef __vtkBoostBiconnectedComponents_h
#define __vtkBoostBiconnectedComponents_h

#include "vtkUndirectedGraphAlgorithm.h"

class VTK_INFOVIS_EXPORT vtkBoostBiconnectedComponents : public vtkUndirectedGraphAlgorithm 
{
public:
  static vtkBoostBiconnectedComponents *New();
  vtkTypeRevisionMacro(vtkBoostBiconnectedComponents, vtkUndirectedGraphAlgorithm);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Description:
  // Set the output array name. If no output array name is
  // set then the name 'VertexDegree' is used.
  vtkSetStringMacro(OutputArrayName);

protected:
  vtkBoostBiconnectedComponents();
  ~vtkBoostBiconnectedComponents();

  int RequestData(vtkInformation *, vtkInformationVector **, vtkInformationVector *);
  
private:

  char* OutputArrayName;
  
  vtkBoostBiconnectedComponents(const vtkBoostBiconnectedComponents&);  // Not implemented.
  void operator=(const vtkBoostBiconnectedComponents&);  // Not implemented.
};

#endif
