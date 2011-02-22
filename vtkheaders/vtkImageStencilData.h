/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkImageStencilData.h,v $

  Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/
// .NAME vtkImageStencilData - efficient description of an image stencil
// .SECTION Description
// vtkImageStencilData describes an image stencil in a manner which is
// efficient both in terms of speed and storage space.  The stencil extents
// are stored for each x-row across the image (multiple extents per row if
// necessary) and can be retrieved via the GetNextExtent() method.
// .SECTION see also
// vtkImageStencilSource vtkImageStencil

#ifndef __vtkImageStencilData_h
#define __vtkImageStencilData_h


#include "vtkDataObject.h"

class VTK_IMAGING_EXPORT vtkImageStencilData : public vtkDataObject
{
public:
  static vtkImageStencilData *New();
  vtkTypeRevisionMacro(vtkImageStencilData, vtkDataObject);
  void PrintSelf(ostream& os, vtkIndent indent);

  void Initialize();
  void DeepCopy(vtkDataObject *o);
  void ShallowCopy(vtkDataObject *f);
  void InternalImageStencilDataCopy(vtkImageStencilData *s);

  // Description:
  // Get the data type as an integer (this will return VTK_DATA_OBJECT
  // for now, maybe a proper type constant will be reserved later).
  int GetDataObjectType() { return VTK_DATA_OBJECT; }

  // Description:
  // The extent type is 3D, just like vtkImageData.
  int GetExtentType() { return VTK_3D_EXTENT; };

  // Description:
  // Given the total output x extent [xMin,xMax] and the current y, z indices,
  // return each sub-extent [r1,r2] that lies within within the unclipped
  // region in sequence.  A value of '0' is returned if no more sub-extents
  // are available.  The variable 'iter' must be initialized to zero before
  // the first call, unless you want the complementary sub-extents in which
  // case you must initialize 'iter' to -1.  The variable 'iter' is used
  // internally to keep track of which sub-extent should be returned next.
  int GetNextExtent(int &r1, int &r2, int xMin, int xMax,
                    int yIdx, int zIdx, int &iter);

  // Description:
  // This method is used by vtkImageStencilDataSource to add an x 
  // sub extent [r1,r2] for the x row (yIdx,zIdx).  The specified sub
  // extent must not intersect any other sub extents along the same x row.
  // As well, r1 and r2 must both be within the total x extent
  // [Extent[0],Extent[1]].
  void InsertNextExtent(int r1, int r2, int yIdx, int zIdx);
  
  // Description:
  // Similar to InsertNextExtent, except that the extent (r1,r2) at yIdx, 
  // zIdx is merged with other extents, (if any) on that row. So a 
  // unique extent may not necessarily be added. For instance, if an extent 
  // [5,11] already exists adding an extent, [7,9] will not affect the 
  // stencil. Likewise adding [10, 13] will replace the existing extent 
  // with [5,13].
  void InsertAndMergeExtent(int r1, int r2, int yIdx, int zIdx);

  // Description:
  // Remove the extent from (r1,r2) at yIdx, zIdx
  void RemoveExtent(int r1, int r2, int yIdx, int zIdx);

  // Description:
  // Set the desired spacing for the stencil.
  // This must be called before the stencil is Updated, ideally 
  // in the ExecuteInformation method of the imaging filter that
  // is using the stencil.
  vtkSetVector3Macro(Spacing, double);
  vtkGetVector3Macro(Spacing, double);

  // Description:
  // Set the desired origin for the stencil.
  // This must be called before the stencil is Updated, ideally 
  // in the ExecuteInformation method of the imaging filter that
  // is using the stencil.
  vtkSetVector3Macro(Origin, double);
  vtkGetVector3Macro(Origin, double);

  // Description:
  // Set the extent of the data.  This is should be called only 
  // by vtkImageStencilSource, as it is part of the basic pipeline
  // functionality.
  void SetExtent(int extent[6]);
  void SetExtent(int x1, int x2, int y1, int y2, int z1, int z2);
  vtkGetVector6Macro(Extent, int);

  // Description:
  // Allocate space for the sub-extents.  This is called by
  // vtkImageStencilSource.
  void AllocateExtents();

  // Description:
  // Override these to handle origin, spacing, scalar type, and scalar
  // number of components.  See vtkDataObject for details.
  virtual void CopyInformationToPipeline(vtkInformation* request,
                                         vtkInformation* input,
                                         vtkInformation* output,
                                         int forceCopy);
  virtual void CopyInformationFromPipeline(vtkInformation* request);

  //BTX
  // Description:
  // Retrieve an instance of this class from an information object.
  static vtkImageStencilData* GetData(vtkInformation* info);
  static vtkImageStencilData* GetData(vtkInformationVector* v, int i=0);
  //ETX
  
  // Description:
  // Add merges the stencil supplied as argument into Self.
  virtual void Add     ( vtkImageStencilData * ); 

  // Description:
  // Subtract removes the portion of the stencil, supplied as argument, 
  // that lies within Self from Self.   
  virtual void Subtract( vtkImageStencilData * ); 

  // Description:
  // Clip the stencil with the supplied extents. In other words, discard data
  // outside the specified extents. Return 1 if something changed.
  virtual int Clip( int extent[6] );

protected:
  vtkImageStencilData();
  ~vtkImageStencilData();

  // Description:
  // Get important info from pipeline.
  void CopyOriginAndSpacingFromPipeline();

  // Description:
  // Merges portions of the stencil that are within Self's extents into 
  // itself. 
  virtual void InternalAdd( vtkImageStencilData * );
  
  // Description:
  // The Spacing and Origin of the data.
  double Spacing[3];
  double Origin[3];
  
  int Extent[6];

  // Description:
  // The actual 'data' is stored here.
  int NumberOfExtentEntries;
  int *ExtentListLengths;
  int **ExtentLists;
private:
  vtkImageStencilData(const vtkImageStencilData&);  // Not implemented.
  void operator=(const vtkImageStencilData&);  // Not implemented.
};

#endif


