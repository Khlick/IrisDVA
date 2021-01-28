 function executeFunction(obj,~,~)
%collect inputs and create function call string and then save in base
%Make sure both fx and DataObject are present
if ~obj.analysisReady, return; end

% request new Data objcet.
loadSplash = iris.ui.loadShow();
loadSplash.show();
loadSplash.updatePercent('Executing...');

% setup the cleanup
CU = onCleanup(@()killLoad(loadSplash));

% function name
Fx = obj.selectAnalysis.String{obj.selectAnalysis.Value};

if ~obj.checkboxAppend.Value
  % reset outputValues so they don't get appended
  obj.OutputValues = struct();  
end

%Check for valid output file name
if isempty(obj.outputFile)
  iris.app.Info.showWarning('Enter a valid file name.');
  loadSplash.shutdown();
  delete(loadSplash);
  return;
end

%Check args for empties
check = [...
    cellfun(@isempty, obj.Args.Input(:,2),  'unif',1)  ;...
    cellfun(@isempty, obj.Args.Output(:,2), 'unif',1)  ...
  ];
if any(check)
  iris.app.Info.throwError( ...
    sprintf('Cannot provide empty arguments for function ''%s(...)''.',Fx) ...
    );
end
%Parse Args
ArgOut = obj.Args.Output(:,2);
ArgIn = obj.Args.Input(:,2);
try
  ArgIn{strcmpi(ArgIn,obj.DATA_OBJECT_LABEL)} = obj.DATA_OBJECT_LABEL;
catch x
  warndlg('Input values must contain a "%s" reference.',obj.DATA_OBJECT_LABEL);
  rethrow(x);
end

%Set outputs into obj outputs
S = struct();
S.Call = struct();
S.Call.TimeStamp = datestr(now,'YYYYmmmDD-HH:MM:SS.FFF');

S.Call.ArgsIn = ArgIn;
S.Call.ArgsOut = ArgOut;
ArgOut = strcat('S.', ArgOut);


callString = obj.Args.Call(ArgOut, Fx, ArgIn);
S.Call.String = callString;

% load the data object
%clear the current dataObject
subs = obj.datumIndices;
S.Call.Indices = subs;
try
  % Until I find a better way 
  if ~strcmp(obj.DATA_OBJECT_LABEL,'DataObject')
    error('Data object label constant does not match. Expected "DataObject"');
  end
  DataObject = obj.Handler.exportSubs(subs);
catch x
  iris.app.Info.throwError( ...
    sprintf( ...
    'Could not run analysis with reason: "%s" (%s)', ...
    x.message, ...
    strjoin( ...
      arrayfun( ...
        @(s)sprintf("[line %d : %s]",s.line,s.name), ...
        x.stack, ...
        'UniformOutput', true ...
        ), ...
      " > " ...
      ) ...
    ) ...
    );
end

% append the user specified file
outFile = obj.outputFile;
DataObject = DataObject.AppendUserData('AnalysisPath',outFile); %#ok<NASGU>

try
  fprintf("Executing '%s'...\n", Fx);
  % Run function string and capture any outputs
  T = evalc(callString);
catch x
  iris.app.Info.throwError( ...
    sprintf( ...
    'Could not perform analysis with reason:\n"%s"\n(%s)\n', ...
    x.message, ...
    strjoin( ...
      arrayfun( ...
        @(s)sprintf("[line %d : %s]",s.line,s.name), ...
        x.stack, ...
        'UniformOutput', true ...
        ), ...
      " > " ...
      ) ...
    ) ...
    );
end

if ~isempty(T)
  disp(T);
end

%% save and assign
loadSplash.updatePercent('Saving...');
doAppend = obj.checkboxAppend.Value;
fileExists = exist(outFile,'file');

if fileExists && ~doAppend
  % prompt to overwrite
  doOverwrite = iris.ui.questionBox( ...
    'Prompt', 'File exists already. Are you sure you want to overwrite it?', ...
    'Title', 'Overwrite File', ...
    'Options', {'Overwrite','New','Append','Cancel'}, ...
    'Default', 'Append' ...
    );
  switch doOverwrite.response
    case 'Cancel'
      % changed our minds about exporting the result
      fprintf('Analysis successful. Results not saved!\n');
      return
    case 'New'
      % Do no want to overwrite after all, prompt for new path
      outFile = iris.app.Info.putFile( ...
        'Analysis Output File', ...
        '*.mat', ...
        fullfile(obj.Opts.OutputDirectory,[obj.Opts.AnalysisPrefix(),'.mat']) ...
        );
      if isempty(outFile)
        fprintf('Analysis successful. Results not saved!\n');
        return
      end
      [obj.labelFileRoot.String, obj.editFileOutput.String,~] = fileparts(outFile);
      obj.validateFilename(obj.editFileOutput,[]);
      pause(0.001);
    case 'Append'
      % don't overwrite but append new variables.
      doAppend = true;
  end
end

% save the vars to mat file.
vars = fieldnames(S);
vars(ismember(vars,'Call')) = []; %Call is always present
  
if doAppend && fileExists
  fConts = who(obj.outputFileHandle);
  if ismember('Call',fConts)
    tmp = obj.outputFileHandle.Call;
    try
      tmp = [tmp,S.Call];
    catch x
      iris.app.Info.showWarning( ...
        sprintf( ...
          "Call structures are dissimilar, packaging them as cells. Message:'%s'", ...
          x.message ...
          ) ...
        );
      tmp = {tmp,S.Call};
    end
    obj.outputFileHandle.Call = tmp;
  else
    obj.outputFileHandle.Call = S.Call;
  end
  % loop, if a variable already exists, load it and make a cell array, if not
  % just append the new variables.
  for v = string(vars')
    isExisting = ismember(v,fConts);
    if isExisting
      tmp = obj.outputFileHandle.(v);
      % append same variable only if the new varaible is different.
      if isequaln(tmp,S.(v)), continue; end
      % append onto the end
      switch class(tmp)
        case 'table'
          % try to vertcat (assuming same vars)
          try
            tmp = vertcat(tmp,S.(v)); %#ok<AGROW>
          catch
            % simply turn into cell array
            tmp = [{tmp},{S.(v)}];
          end
        otherwise
          % assuming existing is an array-able data type
          nEx = numel(S.(v));
          try
            % try to horzcat
            tmp(1,end+(1:nEx)) = reshape(S.(v),1,[]);
          catch
            % use cells
            tmp(end) = {S.(v)};
          end
      end
      obj.outputFileHandle.(v) = tmp;
    else
      obj.outputFileHandle.(v) = S.(v);
    end
  end
else
  % store each variable
  obj.outputFileHandle.Call = S.Call;
  for v = string(vars')
    obj.outputFileHandle.(v) = S.(v);
  end
end

% send to global workspace
% this could be made better.
if obj.checkboxSendToCmd.Value
  W = evalin('base', 'whos');
  varsToSave = fieldnames(S);
  varsToSave(ismember(varsToSave,'Call')) = [];
  namesInBase = {W(:).name}';
  AlreadyInBase = ismember(varsToSave,namesInBase);
  for i = 1:length(varsToSave)
    if obj.checkboxAppend.Value && AlreadyInBase(i)
      % if in base and we want to append, bring it into the current scope and
      % append our new value to the end.
      baseVal = evalin('base',varsToSave{i});
      thisVal = S.(varsToSave{i});
      try
        newVal = [baseVal,thisVal];
        assignin('base', varsToSave{i},newVal);
      catch x
        fprintf(2,'Could not append to %s with error:\n"%s"\n',varsToSave{i},x.message);
      end
      continue
    end
    assignin('base',['Iris_',varsToSave{i}],S.(varsToSave{i}));
  end
end
fprintf('Succesful export!\n');

   function killLoad(LS)
     LS.shutdown();
   end

end