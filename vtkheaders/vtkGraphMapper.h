/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkGraphMapper.h,v $

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
// .NAME vtkGraphMapper - map vtkGraph and derived 
// classes to graphics primitives

// .SECTION Description
// vtkGraphMapper is a mapper to map vtkGraph 
// (and all derived classes) to graphics primitives. 

#ifndef __vtkGraphMapper_h
#define __vtkGraphMapper_h

#include "vtkMapper.h"

#include "vtkSmartPointer.h"    // Required for smart pointer internal ivars.

class vtkCamera;
class vtkGraph;
class vtkGlyph2D;
class vtkGraphToPolyData;
class vtkIconGlyphFilter;
class vtkCellCenters;
class vtkPolyDataMapper;
class vtkLookupTable;
class vtkTexture;
class vtkVertexGlyphFilter;
class vtkViewTheme;
class vtkActor2D;
class vtkFollower;
class vtkTransformCoordinateSystems;


class VTK_INFOVIS_EXPORT vtkGraphMapper : public vtkMapper 
{
public:
  static vtkGraphMapper *New();
  vtkTypeRevisionMacro(vtkGraphMapper,vtkMapper);
  void PrintSelf(ostream& os, vtkIndent indent);
  void Render(vtkRenderer *ren, vtkActor *act);
  
  // Description:
  // The array to use for coloring vertices.  Default is "color".
  void SetVertexColorArrayName(const char* name);
  const char* GetVertexColorArrayName();
  
  // Description:
  // Whether to color vertices.  Default is off.
  void SetColorVertices(bool vis);
  bool GetColorVertices();
  void ColorVerticesOn();
  void ColorVerticesOff();
  
  // Description:
  // The array to use for coloring edges.  Default is "color".
  void SetEdgeColorArrayName(const char* name);
  const char* GetEdgeColorArrayName();
  
  // Description:
  // Whether to color edges.  Default is off.
  void SetColorEdges(bool vis);
  bool GetColorEdges();
  void ColorEdgesOn();
  void ColorEdgesOff();

  // Description:
  // Specify the Width and Height, in pixels, of an icon in the icon sheet.
  void SetIconSize(int *size);
  int *GetIconSize();

  // Description:
  // The texture containing the icon sheet.
  vtkTexture *GetIconTexture();
  void SetIconTexture(vtkTexture *texture);

  // Description:
  // Whether to show icons.  Default is off.
  void SetIconVisibility(bool vis);
  bool GetIconVisibility();
  vtkBooleanMacro(IconVisibility, bool);
  
  // Description:
  // Get/Set the vertex point size
  vtkGetMacro(VertexPointSize,float);
  void SetVertexPointSize(float size);
  
  // Description:
  // Get/Set the edge line width
  vtkGetMacro(EdgeLineWidth,float);
  void SetEdgeLineWidth(float width);
  
  // Description:
  // Apply the theme to this view.
  virtual void ApplyViewTheme(vtkViewTheme* theme);

  // Description:
  // Release any graphics resources that are being consumed by this mapper.
  // The parameter window could be used to determine which graphic
  // resources to release.
  void ReleaseGraphicsResources(vtkWindow *);

  // Description:
  // Get the mtime also considering the lookup table.
  unsigned long GetMTime();

  // Description:
  // Set the Input of this mapper.
  void SetInput(vtkGraph *input);
  vtkGraph *GetInput();
  
  // Description:
  // Return bounding box (array of six doubles) of data expressed as
  // (xmin,xmax, ymin,ymax, zmin,zmax).
  virtual double *GetBounds();
  virtual void GetBounds(double* bounds)
    { Superclass::GetBounds(bounds); }

protected:
  vtkGraphMapper();
  ~vtkGraphMapper();
  
  // Description:
  // Used to store the vertex and edge color array names
  vtkGetStringMacro(VertexColorArrayNameInternal);
  vtkSetStringMacro(VertexColorArrayNameInternal);
  vtkGetStringMacro(EdgeColorArrayNameInternal);
  vtkSetStringMacro(EdgeColorArrayNameInternal);
  char* VertexColorArrayNameInternal;
  char* EdgeColorArrayNameInternal;

  //BTX
  vtkSmartPointer<vtkGraphToPolyData>   GraphToPoly;
  vtkSmartPointer<vtkVertexGlyphFilter> VertexGlyph;
  vtkSmartPointer<vtkIconGlyphFilter>   IconGlyph;
  //vtkSmartPointer<vtkTransformCoordinateSystems> IconTransform;
  
  vtkSmartPointer<vtkPolyDataMapper>    EdgeMapper;
  vtkSmartPointer<vtkPolyDataMapper>    VertexMapper;
  vtkSmartPointer<vtkPolyDataMapper>    OutlineMapper;
  vtkSmartPointer<vtkPolyDataMapper>    IconMapper;
  
  vtkSmartPointer<vtkActor>             EdgeActor;
  vtkSmartPointer<vtkActor>             VertexActor;
  vtkSmartPointer<vtkActor>             OutlineActor;
  vtkSmartPointer<vtkFollower>           IconActor;
  
  // Color maps
  vtkSmartPointer<vtkLookupTable>       EdgeLookupTable;
  vtkSmartPointer<vtkLookupTable>       VertexLookupTable;
  //ETX

  virtual void ReportReferences(vtkGarbageCollector*);

  // see algorithm for more info
  virtual int FillInputPortInformation(int port, vtkInformation* info);

private:
  vtkGraphMapper(const vtkGraphMapper&);  // Not implemented.
  void operator=(const vtkGraphMapper&);  // Not implemented.
  
  float VertexPointSize;
  float EdgeLineWidth;
};

#endif


