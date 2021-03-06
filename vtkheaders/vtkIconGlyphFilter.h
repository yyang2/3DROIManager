/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkIconGlyphFilter.h,v $

  Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/
// .NAME vtkIconGlyphFilter - Filter that generates a polydata with texture
// coordinates corresponding to icons within a sheet of icons.
// .SECTION Description
// vtkIconGlyphFilter takes in a vtkPointSet where each point corresponds to
// the center of an icon. Scalar integer data must also be set to give each
// point an icon index. This index is a zero based row major index into an
// image that contains a grid of icons. You must also set pixel Size of the 
// icon image and the size of a particular icon.

// .SECTION See Also
// vtkPolyDataAlgorithm

#ifndef __vtkIconGlyphFilter_h
#define __vtkIconGlyphFilter_h

#include "vtkPolyDataAlgorithm.h"


class VTK_GRAPHICS_EXPORT vtkIconGlyphFilter : public vtkPolyDataAlgorithm
{
public:

  // Description
  static vtkIconGlyphFilter *New();
  vtkTypeRevisionMacro(vtkIconGlyphFilter,vtkPolyDataAlgorithm);
  void PrintSelf(ostream& os, vtkIndent indent);

  // Description:
  // Specify the Width and Height, in pixels, of an icon in the icon sheet
  vtkSetVector2Macro(IconSize,int);
  vtkGetVectorMacro(IconSize,int,2);

  // Description:
  // Specify the Width and Height, in pixels, of an icon in the icon sheet
  vtkSetVector2Macro(IconSheetSize,int);
  vtkGetVectorMacro(IconSheetSize,int,2);


  // Description:
  // Specify whether the Quad generated to place the icon on will be either
  // 1 x 1 or the dimensions specified by IconSize.
  void SetUseIconSize(bool b);
  bool GetUseIconSize();
  vtkBooleanMacro(UseIconSize, bool);

protected:
  vtkIconGlyphFilter();
  ~vtkIconGlyphFilter();

  virtual int RequestData(vtkInformation *,
                          vtkInformationVector **,
                          vtkInformationVector *);

  int IconSize[2]; // Size in pixels of an icon in an icon sheet
  int IconSheetSize[2]; // Size in pixels of the icon sheet

private:
  vtkIconGlyphFilter(const vtkIconGlyphFilter&);  // Not implemented.
  void operator=(const vtkIconGlyphFilter&);  // Not implemented.

  void IconConvertIndex(int id, int & j, int & k);

  bool UseIconSize;
};

inline void vtkIconGlyphFilter::IconConvertIndex(int id, int & j, int & k)
{
  int dimX = this->IconSheetSize[0]/this->IconSize[0];
  int dimY = this->IconSheetSize[1]/this->IconSize[1];

  j = id - dimX * (int)(id/dimX);
  k = dimY - (int)(id/dimX) - 1;
}

#endif
