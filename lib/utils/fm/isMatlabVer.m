function Dummy = isMatlabVer(varargin)
% isMatlabVer - Compare Matlab version to specified number
% Match = isMatlabVer(Relop, N)
% INPUT:
%   Relop: Comparison operator as string: '<', '<=', '>', '>=', '=='.
%   N:     Number to compare with as DOUBLE vector with 1 to 4 elements.
%
% OUTPUT:
%   Match: Locical scalar, TRUE for matching comparison, FALSE otherwise.
%
% EXAMPLES:
%   version ==> '7.8.0.342 (R2009a)'  (different results for other version!)
%   isMatlabVer('<=', 7)               % ==> TRUE
%   isMatlabVer('>',  6)               % ==> TRUE
%   isMatlabVer('<',  [7, 8])          % ==> FALSE
%   isMatlabVer('<=', [7, 8])          % ==> TRUE
%   isMatlabVer('>',  [7, 8, 0, 342])  % ==> FALSE
%   isMatlabVer('==', 7)               % ==> TRUE
%   isMatlabVer('==', [7, 10])         % ==> FALSE
%   isMatlabVer('>',  [7, 8, 0])       % ==> FALSE (the 342 is not considered!)
%
% NOTES: The C-Mex function takes about 0.6% of the processing time needed
%   by Matlab's VERLESSTHAN, which can check other toolboxes also.
%   The simple "sscanf(version, '%f', 1) <= 7.8" fails for the funny version
%   number 7.10 of Matlab 2010a, which is confused with 7.1 (R14SP3).
%
% Compile with: mex -O isMatlabVer.c
% Linux: mex -O CFLAGS="\$CFLAGS -std=C99" isMatlabVer.c
% Pre-compiled files: http://www.n-simon.de/mex
%
% Tested:   Matlab 6.5, 7.7, 7.8, WinXP 32 bit
%           Compatibility to Linux, Mac, 64 bit is assumed.
% Compiler: BCC 5.5, LCC 2.4/3.8, Open Watcom 1.8, MSVC 2008
% Author:   Jan Simon, Heidelberg, (C) 2010 matlab.THISYEAR(a)nMINUSsimon.de
% License:  BSD - use, copy, modify on own risk, mention the author.
%
% See also: VER, VERLESSTHAN.

% This is a dummy M-file to feed the HELP command.
error(['JSimon:', mfilename, ':MexNotFound'], ...
   'Cannot find Mex file. Please compile it!');
