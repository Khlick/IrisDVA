function [B, A] = ButterParam(N, Wn, Pass)
% ButterParam - Parameters for a digital Butterworth filter
% This is equivalent to: [B, A] = butter(N, Wn, Pass)
% But because calculating B and A is expensive, this function stores the
% parameters persistently such that following calls with the same inputs are
% answered much faster.
%
% Input and output equal the BUTTER command of the Signal-Processing-Toolbox
% when used with 3 inputs and 2 outputs:
% [B, A] = ButterParam(N, Wn, Pass)
% INPUT:
%   N:  Order of the filter.
%       Note: BUTTER(N, [H,L]) replies a 2*N bandpass filter!
%   Wn: Cutoff frequency, 0.0 < Wn < 1.0. 1.0 corresponds to half the sample
%       rate. For bandpass and stopband filters, Wn is a [1 x 2] double.
%   Pass: String, 'low', 'high', 'bandpass', 'stop'.
%       Optional, default is 'low' if Wn is a scalar, and 'bandpass' otherwise.
%
% OUTPUT:
%   B, A: Filter coefficients. Both are [1 x N+1] double vectors.
%
% FURTHER COMMANDS:
%   ButterParam('save'):  The list of calculated parameters can be stored in a
%                         MAT file which is loaded automatically if this
%                         function runs the first time in a Matlab session.
%   ButterParam('kill'):  Delete the preferences file.
%   ButterParam('clear'): Clear the current list.
%
% REQUIREMENTS:
%   The Signal-Processing-Toolbox is needed to calculate new parameters. If all
%   used parameters are found in the MAT file, the SPT is not needed.
%
% EXAMPLES:
%   x      = rand(10000, 1);
%   [B, A] = ButterParam(3, 0.2, 'low');
%   x2     = filter(B, A, x);
% Run the unit-test to check validity and speed: uTest_ButterParam.
%
% Tested: Matlab 6.5, 7.7, 7.8
% Author: Jan Simon, Heidelberg, (C) 2010-2011 matlab.THISYEAR(a)nMINUSsimon.de
%
% See also BUTTER, BUTTORD, FILTER.

% $JRev: R-j V:009 Sum:vhdRWdd1DWUh Date:22-Jun-2011 02:58:12 $
% $License: BSD (use/copy/change/redistribute on own risk, mention the author) $
% $UnitTest: uTest_ButterParam $
% $File: Tools\GLMath\ButterParam.m $
% History:
% 001: 19-Jan-2011 09:13, First version.

% Initialize: ==================================================================
% Global Interface: ------------------------------------------------------------
persistent List
if isempty(List)
   myPrefFile = [mfilename('fullpath'), '_Pref.mat'];
   if exist(myPrefFile, 'file')   % FileExist(myPrefFile)
      Data = load(myPrefFile);
      List = Data.List;
   else  % One field for each pass type: 'low', 'high', 'bandpass', 'stop'
      List.low.Order = [];
      List.low.Wn    = [];
      List.low.Param = {};
      List.high      = List.low;
      List.bandpass  = List.low;
      List.stop      = List.low;
   end
end

% Initial values: --------------------------------------------------------------
% Program Interface: -----------------------------------------------------------
% Parse and get default values for omitted inputs:
switch nargin
   case 3  % 'Band' => 'bandpass'
      knownType = {'low', 'high', 'bandpass', 'stop'};
      try
         Pass = knownType{strncmpi(Pass, knownType, 3)};
      catch
         error(['JSimon:', mfilename, ':BadInput3'], ...
            ['*** ', mfilename, ': Unknown pass type: ', ...
            'Use {low, high, passband, stop}']);
      end
      
   case 2                     % [Pass] is omitted:
      if numel(Wn) == 1       % Low pass filter for scalar frequency:
         Pass = 'low';
      elseif numel(Wn) == 2   % Band pass filter for [1 x 2] frequency vector:
         Pass = 'bandpass';
      else
         error(['JSimon:', mfilename, ':BadInput2'], ...
            ['*** ', mfilename, ...
            ': Frequency must be scalar or a [1 x 2] vector.']);
      end
      
   case 1  % Meta command:
      myPrefFile = [mfilename('fullpath'), '_Pref.mat'];
      if ~ischar(N)
         error(['JSimon:', mfilename, ':BadInput1'], ...
            ['*** ', mfilename, ...
            ': [Command] must be a string for single input']);
      elseif strcmpi(N, 'save')   % Create a MAT file for future access:
%          if isMatlabVer('>=', 7)
%             save(myPrefFile, 'v6', 'List', '-mat');
%          else
%             save(myPrefFile, 'List', '-mat');
%          end
        save(myPrefFile, 'List', '-mat');
      elseif strcmpi(N, 'clear')  % Clear current list:
         List = [];
      elseif strcmpi(N, 'kill')   % Delete MAT file:
         delete(myPrefFile);
         List = [];
      else
         error(['JSimon:', mfilename, ':UnknownInput1'], ...
            ['*** ', mfilename, ': Unknown command: [', N, ']']);
      end
      
      return;
      
   otherwise
      error(['JSimon:', mfilename, ':BadNInput'], ...
         ['*** ', mfilename, ': Bad number of inputs.']);
end

% User Interface: --------------------------------------------------------------
% Do the work: =================================================================
% Make Wn a single complex number to be able to compare it with "==":
if numel(Wn) == 2
   Wn_ = Wn(1) + 1i * Wn(2);
else
   Wn_ = Wn;
end

% Find the matching pass type, order and frequency:
ListPass   = List.(Pass);
matchParam = and((ListPass.Order == N), (Wn_ == ListPass.Wn));

% Copy or append the parameters:
if any(matchParam)  % Found - copy from persistent list:
   Param = ListPass.Param{matchParam};
   B     = Param{1};
   A     = Param{2};
else                % Not found - ask BUTTER for values:
   try
      [B, A] = butter(N, Wn, Pass);   %  <== The actual calculations
   catch
      if isempty(which('butter'))
         error(['JSimon:', mfilename, ':BadNInput'], ...
            ['*** ', mfilename, ...
            ': Signal-Processing-Toolbox is needed to get new parameters.']);
      else
         error(['JSimon:', mfilename, ':BadNInput'], ...
            ['*** ', mfilename, ': Error in BUTTER:\n%s'], lasterr);
      end
   end
   
   % Append results to the persistent List:
   len                    = length(List.(Pass).Order) + 1;
   List.(Pass).Order(len) = N;
   List.(Pass).Wn(len)    = Wn_;
   List.(Pass).Param{len} = {B, A};
end

% return;
