/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkDuplicatePolyData.h,v $

  Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/
// .NAME vtkDuplicatePolyData - For distributed tiled displays.
// .SECTION Description
// This filter collects poly data and duplicates it on every node.
// Converts data parallel so every node has a complete copy of the data.
// The filter is used at the end of a pipeline for driving a tiled
// display.


#ifndef __vtkDuplicatePolyData_h
#define __vtkDuplicatePolyData_h

#include "vtkPolyDataAlgorithm.h"
class vtkSocketController;
class vtkMultiProcessController;

class VTK_PARALLEL_EXPORT vtkDuplicatePolyData : public vtkPolyDataAlgorithm
{
public:
  static vtkDuplicatePolyData *New();
  vtkTypeRevisionMacro(vtkDuplicatePolyData, vtkPolyDataAlgorithm);
  void PrintSelf(ostream& os, vtkIndent indent);
  
  // Description:
  // By defualt this filter uses the global controller,
  // but this method can be used to set another instead.
  virtual void SetController(vtkMultiProcessController*);
  vtkGetObjectMacro(Controller, vtkMultiProcessController);

  void InitializeSchedule(int numProcs);

  // Description:
  // This flag causes sends and receives to be matched.
  // When this flag is off, two sends occur then two receives.
  // I want to see if it makes a difference in performance.
  // The flag is on by default.
  vtkSetMacro(Synchronous, int);
  vtkGetMacro(Synchronous, int);
  vtkBooleanMacro(Synchronous, int);

  // Description:
  // This duplicate filter works in client server mode when this
  // controller is set.  We have a client flag to diferentiate the
  // client and server because the socket controller is odd:
  // Proth processes think their id is 0.
  vtkSocketController *GetSocketController() {return this->SocketController;}
  void SetSocketController (vtkSocketController *controller);
  vtkSetMacro(ClientFlag,int);
  vtkGetMacro(ClientFlag,int);

  // Description:
  // This returns to size of the output (on this process).
  // This method is not really used.  It is needed to have
  // the same API as vtkCollectPolyData.
  vtkGetMacro(MemorySize, unsigned long);

protected:
  vtkDuplicatePolyData();
  ~vtkDuplicatePolyData();

  // Data generation method
  virtual int RequestUpdateExtent(vtkInformation *, vtkInformationVector **, vtkInformationVector *);
  virtual int RequestData(vtkInformation *, vtkInformationVector **, vtkInformationVector *);
  void ClientExecute(vtkPolyData *output);
  virtual int RequestInformation(vtkInformation *, vtkInformationVector **, vtkInformationVector *);

  vtkMultiProcessController *Controller;
  int Synchronous;

  int NumberOfProcesses;
  int ScheduleLength;
  int **Schedule;

  // For client server mode.
  vtkSocketController *SocketController;
  int ClientFlag;

  unsigned long MemorySize;

private:
  vtkDuplicatePolyData(const vtkDuplicatePolyData&); // Not implemented
  void operator=(const vtkDuplicatePolyData&); // Not implemented
};

#endif

