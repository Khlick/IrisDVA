// isMatlabVer.c
// Compare Matlab version to specified number
// Match = isMatlabVer(Relop, N)
// INPUT:
//   Relop: Comparison operator as string: '<', '<=', '>', '>=', '=='.
//   N:     Number to compare with as DOUBLE vector with 1 to 4 elements.
//
// OUTPUT:
//   Match: Locical scalar, TRUE for matching comparison, FALSE otherwise.
//
// EXAMPLES:
//   version ==> '7.8.0.342 (R2009a)'  (different results for other version!)
//   isMatlabVer('<=', 7)               % ==> TRUE
//   isMatlabVer('>',  6)               % ==> TRUE
//   isMatlabVer('<',  [7, 8])          % ==> FALSE
//   isMatlabVer('<=', [7, 8])          % ==> TRUE
//   isMatlabVer('>',  [7, 8, 0, 342])  % ==> FALSE
//   isMatlabVer('==', 7)               % ==> TRUE
//   isMatlabVer('==', [7, 10])         % ==> FALSE
//   isMatlabVer('>',  [7, 8, 0])       % ==> FALSE (the 342 is not considered!)
//
// NOTES: The C-Mex function takes about 0.6% of the processing time needed
//   by Matlab's VERLESSTHAN, which can check other toolboxes also.
//   The simple "sscanf(version, '%f', 1) <= 7.8" fails for the funny version
//   number 7.10 of Matlab 2010a, which is confused with 7.1 (R14SP3).
//
// Compile:   mex -O isMatlabVer.c
// Linux/GCC: mex -O CFLAGS="\$CFLAGS -std=C99" isMatlabVer.c
// Pre-compiled files: http://www.n-simon.de/mex
//
// Tested: Matlab 6.5, 7.7, 7.8, WinXP 32 bit
//         Compatibility to Linux, Mac, 64 bit is assumed.
// Compiler: BCC 5.5, LCC 2.4/3.8, Open Watcom 1.8, MSVC 2008
// Author: Jan Simon, Heidelberg, (C) 2010 matlab.THISYEAR(a)nMINUSsimon.de
// License: BSD - use, copy, modify on own risk, mention the author.
//
// See also: VER, VERLESSTHAN.

/*
% $JRev: R0d V:003 Sum:PESD4Qe2aN2S Date:12-Apr-2010 16:13:38 $
% $License: BSD $
% $File: Tools\Mex\Source\isMatlabVer.c $
% History:
% 001: 12-Apr-2010 03:48, Replace weak SSCANF(VERSION, '%f', 1) < X.
*/

#include "mex.h"
#include <math.h>

// Error messages do not contain the function name in Matlab 6.5! This is not
// necessary in Matlab 7, but it does not bother:
#define ERR_FUNC "isMatlabVer.c: "

// Assume 32 bit addressing for Matlab 6.5:
// See MEX option "compatibleArrayDims" for MEX in Matlab >= 7.7.
#ifndef MWSIZE_MAX
#define mwSize  int32_T           // Defined in tmwtypes.h
#define mwIndex int32_T
#define MWSIZE_MAX MAX_int32_T
#endif

static int MatlabV[4] = {0, 0, 0, 0};

void Init(void);
void BadRelopError(void);

// Main function ===============================================================
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  mxChar *Relop;
  mwSize nData, i;
  int    c;
  double *Data;
  
  // Proper number of arguments:
  if (nrhs != 2) {
     mexErrMsgIdAndTxt("JSim:isMatlabVer:BadNInput",
                       ERR_FUNC "2 inputs required.");
  }
  if (nlhs > 1) {
     mexErrMsgIdAndTxt("JSim:isMatlabVer:BadNOutput",
                       ERR_FUNC "1 output allowed.");
  }
  
  // Type of inputs:
  if (!mxIsChar(prhs[0])) {
     mexErrMsgIdAndTxt("JSim:isMatlabVer:BadInput1",
                       ERR_FUNC "1st input must be a string.");
  }
  if (!mxIsDouble(prhs[1])) {
     mexErrMsgIdAndTxt("JSim:isMatlabVer:BadInput2",
                       ERR_FUNC "2nd input must be DOUBLE.");
  }
  nData = mxGetNumberOfElements(prhs[1]);
  if (nData == 0 || nData > 4) {
     mexErrMsgIdAndTxt("JSim:isMatlabVer:BadInput2Len",
                       ERR_FUNC "2nd input must have 1 to 4 elements.");
  }
  
  // Initialize - get Matlab version:
  if (MatlabV[0] == 0) {
     Init();
  }
  
  // Get input data:
  Data = mxGetPr(prhs[1]);
  Relop  = (mxChar *) mxGetData(prhs[0]);

  // Check first element to be integer:
  if (*Data != floor(*Data)) {
     mexErrMsgIdAndTxt("JSim:isMatlabVer:BadInput2Value",
                       ERR_FUNC "Input N must contain integer values.");
  }
  
  // Start the comparison:
  switch (mxGetNumberOfElements(prhs[0])) {
     case 1:
        if (!memcmp(Relop, L"<", sizeof(mxChar))) {         // MatlabV < N
           for (i = 0; i < nData; i++) {
              if ((c = MatlabV[i] - (int) Data[i]) != 0) {
                 plhs[0] = mxCreateLogicalScalar(c < 0);
                 return;
              }
           }
           plhs[0] = mxCreateLogicalScalar(c < 0);
    
        } else if (!memcmp(Relop, L">", sizeof(mxChar))) {  // MatlabV > N
           for (i = 0; i < nData; i++) {
              if ((c = MatlabV[i] - (int) Data[i]) != 0) {
                 plhs[0] = mxCreateLogicalScalar(c > 0);
                 return;
              }
           }
           plhs[0] = mxCreateLogicalScalar(c > 0);
     
        } else {
           BadRelopError();
        }
        break;
        
     case 2:
        if (!memcmp(Relop, L"<=", 2 * sizeof(mxChar))) {         // MatlabV <= N
           for (i = 0; i < nData; i++) {
              if ((c = MatlabV[i] - (int) Data[i]) != 0) {
                 plhs[0] = mxCreateLogicalScalar(c < 0);
                 return;
              }
           }
           plhs[0] = mxCreateLogicalScalar(c <= 0);
           
        } else if (!memcmp(Relop, L">=", 2 * sizeof(mxChar))) {  // MatlabV >= N
           for (i = 0; i < nData; i++) {
              if ((c = MatlabV[i] - (int) Data[i]) != 0) {
                 plhs[0] = mxCreateLogicalScalar(c > 0);
                 return;
              }
           }
           plhs[0] = mxCreateLogicalScalar(c >= 0);
           
        } else if (!memcmp(Relop, L"==", 2 * sizeof(mxChar))) {  // MatlabV == N
           for (i = 0; i < nData; i++) {
              if (MatlabV[i] != (int) Data[i]) {
                 plhs[0] = mxCreateLogicalScalar(false);
                 return;
              }
           }
           plhs[0] = mxCreateLogicalScalar(true);
           
        } else {
           BadRelopError();
        }
        
        break;
        
     default:
         BadRelopError();
  }
  
  return;
}

// =============================================================================
void Init(void)
{
  mxArray *Arg[3], *Ver[1];
  double  *VerP;

  // Call "version", store result in Arg[0]:
  mexCallMATLAB(1, Arg, 0, NULL, "version");
  
  // Call SSCANF(version, '%d.', 4), reuse Arg[0]:
  Arg[1] = mxCreateString("%d.");
  Arg[2] = mxCreateDoubleScalar(4);
  mexCallMATLAB(1, Ver, 3, Arg, "sscanf");
  
  // Store result locally:
  VerP       = mxGetPr(Ver[0]);
  MatlabV[0] = (int) VerP[0];
  MatlabV[1] = (int) VerP[1];
  MatlabV[2] = (int) VerP[2];
  MatlabV[3] = (int) VerP[3];
  
  // Cleanup:
  mxDestroyArray(Arg[0]);
  mxDestroyArray(Arg[1]);
  mxDestroyArray(Arg[2]);
  mxDestroyArray(Ver[0]);
  
  return;
}

// =============================================================================
void BadRelopError(void)
{
  mexErrMsgIdAndTxt("JSim:isMatlabVer:BadRelop",
                    ERR_FUNC "Operator must be: '<=', '<', '>=', '>', '=='.");
}
