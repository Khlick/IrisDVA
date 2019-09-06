function executeFunction(obj,~,~)
%collect inputs and create function call string and then save in base
%Make sure both fx and DataObject are present
if ~obj.analysisReady, return; end

%clear the current dataObject
subs = obj.datumIndices;

try
  DataObject = obj.Handler.exportSubs(subs);%#ok
catch x
  iris.app.Info.throwError(x.message);
end
  
% request new Data objcet.
loadSplash = iris.ui.loadShow();
loadSplash.show();
loadSplash.updatePercent('Executing...');

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
  loadSplash.shutdown();
  delete(loadSplash);
  iris.app.Info.throwError( ...
    sprintf('Cannot provide empty arguments for function ''%s(...)''.',obj.Fx) ...
    );
end
%Parse Args
ArgOut = obj.Args.Output(:,2);
ArgIn = obj.Args.Input(:,2);
try
  ArgIn{strcmpi(ArgIn,'DataObject')} = 'DataObject';
catch x
  warndlg('Input values must contain a ''DataObject'' reference.');
  rethrow(x);
end
%Set outputs into obj outputs
S = struct();
S.Call = struct();
S.Call.TimeStamp = datestr(now,'YYYYmmmDD-HH:MM:SS.FFF');

S.Call.ArgsIn = ArgIn;
S.Call.ArgsOut = ArgOut;
ArgOut = strcat('S.', ArgOut);

Fx = obj.selectAnalysis.String{obj.selectAnalysis.Value};
callString = obj.Args.Call(ArgOut, Fx, ArgIn);
S.Call.String = callString;

try
  evalc(callString);
catch x
  loadSplash.shutdown();
  delete(loadSplash);
  iris.app.Info.throwError(x.message);
end

loadSplash.shutdown();
delete(loadSplash);

%% save and assign
outFile = obj.outputFile;

if exist(outFile,'file')
  % prompt to overwrite
  doOverwrite = iris.ui.questionBox( ...
    'Prompt', 'File exists already. Overwrite?', ...
    'Title', 'Overwrite File', ...
    'Options', {'Yes','No','Cancel'}, ...
    'Default', 'No' ...
    );
  switch doOverwrite.response
    case 'Cancel'
      return
    case 'No'
      outFile = iris.app.Info.putFile( ...
        'Analysis Output File', ...
        '*.mat', ...
        fullfile(obj.Opts.OutputDirectory,[obj.Opts.AnalysisPrefix(),'.mat']) ...
        );
      if isempty(outFile), return; end
  end
end

% save the vars to mat file.
save(outFile,'-struct', 'S');

% send to global workspace
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
    assignin('base',varsToSave{i},S.(varsToSave{i}));
  end
end
fprintf('Succesful export!\n');

end