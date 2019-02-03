function loadObj(obj,fxString)
if obj.isClosed, return; end
%if isempty(obj.EpochNumbers), return; end

%currentEpochs = ['[',num2str(obj.EpochNumbers, '%d,'),']'];

%fxString should include .m at the end
validateattributes(fxString, {'char'}, {'nonempty'});
if isempty(regexp(fxString,'\.m$','ONCE'))
  error('Invalid function filename.');
end
%read the text from the file to determine input and output names
fid= fopen(fxString); %either full path or on matlab path
if fid==-1
  error('Cannot open file %s.', fxString);
end
% get the function call string
allText= textscan(fid,'%s','delimiter','\n','whitespace','');
%filter out 'function' part and save the rest as a string for parse
fxText= regexprep(regexprep(allText{1}{1}, 'function', ''),'\s', '');
% get defaults if they exist
defText = allText{1}( ...
  find( ...
    ~cellfun(@isempty, ...
      strfind(allText{1},':=','ForceCellOutput',1), ...
      'unif',1 ...
    ) ...
  ) ...
); %#ok

% go through and split up the values
defText = cellfun(@(x)strsplit(x,':='),defText,'unif',0);
fclose(fid);
% check the function for nargs and construct data for UI tables
[pt,fn,~]= fileparts(fxString);
%make sure fxn is on the path
if ~strcmp(pt,''), addpath(pt); end
Input = cell(nargin(fn),2);
Output = cell(nargout(fn),2);
%parse function's first line
try
  args = strsplit(fxText, '=');
  Output(:,1) = cellfun(@(x)regexprep(x,'[^a-zA-Z_]',''),...
    strsplit(args{1}, ','),'unif', 0);
  Output(:,2) = Output(:,1); %init
catch x
  fprintf(2, ...
    ['\n---\n', ...
    'Analysis functions are required to have at', ...
    ' least 1 output, even if empty.', ...
    '\n---\n']);
  rethrow(x)
end
Input(:,1) = cellfun(...
  @(x)regexprep(x,'[^a-zA-Z_]',''),...
  strsplit(...
    regexprep(args{2}, fn, ''), ...
    ',' ...
  ), ...
  'uniformoutput', 0 ...
  );

% Analyses can contain any named arguments, but the first argument 
% Must contain the DataObject as its value.
Input(1,2) = {'DataObject'};%assume first arg is Data
%{
% epoch values
epochIndex = strcmpi(Input(:,1),'epochs');
if any(epochIndex)
  Input{find(epochIndex,1),2} = currentEpochs;%assume first arg is Data
end
%}
% set Default values
for dd = 1:length(defText)
  param = defText{dd};
  paramIndex = strcmpi(Input(:,1),param{1});
  if any(paramIndex)
    Input{find(paramIndex,1),2} = param{2};
  end
end
%Create Fx string
obj.Fx = fn;
obj.Args.Call = @(out,in)...
  sprintf('[%s] = %s(%s)', ...
  strjoin(out, ', '), obj.Fx, strjoin(in, ', '));
obj.Args.Input = Input;
obj.Args.Output = Output;
%updateUI
obj.labelFunction.String = obj.Args.Call(Output(:,1), Input(:,1));
obj.tableOutput.Data = Output;
obj.tableInput.Data = Input;
if ~strcmp(pt,''), rmpath(pt); end
end