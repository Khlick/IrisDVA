function loadObj(obj,fxString)
% LOADOBJ This method loads a script and collects the defaults for inputs.
if obj.isClosed, return; end

% get the full path of the current function
avails = iris.app.Info.getAvailableAnalyses().Full;

idx = ismember(avails(:,2), [fxString,'.m']);

aFile = fullfile(avails{idx,:});


%read the text from the file to determine input and output names
fid= fopen(aFile); %either full path or on matlab path
if fid == -1
  error('Cannot open file %s.', fxString);
end
% get the function call string
allText= textscan(fid,'%s','delimiter','\n','whitespace','');
% get the function string. Parse in case it is on multiple lines
% tokens are: 
% {1} == outputs
% {2} == ' = '
% {3} == function name
% {4} == inputs
fxTokens = regexp( ...
  cat(2,allText{1}{:}), ...
  '(?<=^function\s)([^=]+)(\s+=\s+)([^\(]+\()([^\)]+\))', ...
  'tokens' ...
  );
fxTokens = fxTokens{1}; % must be only 1 file

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

% verify we can parse the arguments
if numel(fxTokens) ~= 4
  iris.app.Info.throwError(...
    "Function definition must be in the form of: 'function outputs = name(inputs)'." ...
    );
end

% check the function for nargs and construct data for UI tables
[pt,fn,~]= fileparts(aFile);
%make sure fxn is on the path
if ~strcmp(pt,''), addpath(pt); end
Input = cell(nargin(fn),2);
Output = cell(nargout(fn),2);
%parse function's first line
Output(:,1) = cellfun(@(x)regexprep(x,'[^a-zA-Z_]',''),...
  strsplit(fxTokens{1}, ','), ...
  'UniformOutput', false ...
  );
Output(:,2) = Output(:,1); %init

Input(:,1) = cellfun(...
  @(x)regexprep(x,'[^a-zA-Z_]',''), ...
  strsplit(fxTokens{4},','), ...
  'UniformOutput', false ...
  );

% set Default values
for dd = 1:length(defText)
  param = defText{dd};
  paramIndex = strcmpi(Input(:,1),param{1});
  if any(paramIndex)
    Input{find(paramIndex,1),2} = param{2};
  end
end

% Analyses can contain any named arguments, but the first argument 
% Must contain the DataObject as its value.
Input(1,2) = {obj.DATA_OBJECT_LABEL};%assume first arg is Data

%Create Fx string
obj.Args.Call = @(out,name,in)...
  sprintf('[%s] = %s(%s);', ...
    strjoin(out, ', '), name, strjoin(in, ', ') ...
    );
obj.Args.Input = Input;
obj.Args.Output = Output;
%updateUI
obj.labelFunction.String = obj.Args.Call(Output(:,1), fn, Input(:,1));
obj.tableOutput.Data = Output;
obj.tableInput.Data = Input;
obj.buttonGo.Enable = 'on';
obj.editAnalysisButton.Enable = 'on';
obj.setDefaultsButton.Enable = 'on';
end