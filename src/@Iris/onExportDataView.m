function onExportDataView(app, ~, ~)
import iris.ui.questionBox;
doSave = questionBox( ...
  'Prompt', 'Export data from the current view or entire session?', ...
  'Title', 'Export Data', ...
  'Options', {'Current','Session','Cancel'}, ...
  'Default', 'Cancel' ...
  );

switch doSave.response
  case 'Current'
    iData = app.handler.exportCurrent();
  case 'Session'
    iData = app.handler.export();
  otherwise
    fprintf('Data not exported!\n');
    return
end

% update the progress dialog
app.loadShow.update('Preparing for export');

% create a generic save name with filter
fn = fullfile( ...
  app.options.LastSavedDirectory, ...
  [datestr(app.sessionInfo.sessionStart,'YYYY-mmm-DD'),'.idata'] ...
  );

% prompt user for final save location
% hide a csv option here
filterText = [
  {'*.idata','IrisData File'};
  {'*.csv', 'Comma-Separated Values'};
  {'*.tsv', 'Tab-Separated Values'}
  ];
[userFile,~,~,fType] = iris.app.Info.putFile( ...
  'Save IrisData File', ...
  filterText, ...
  fn ...
  );

if isempty(userFile)
  app.loadShow.update('Cancelled!','forceDelay',2);
  app.loadShow.shutdown();
  app.ui.focus();
  return
end

% set the desired file name into the iData object
iData = iData.UpdateFileList(userFile);

% parse display options
vStatus = app.ui.viewStatus;

% If saving iData, only apply switches to shown devices
shownDevices = vStatus.selection.showingDevices;

% check for switch status
switchOptions = ["filter","baseline"];
switchStatus = struct2array(utilities.fastKeepField(vStatus.switches,switchOptions));
if any(switchStatus)
  for s = 1:numel(switchStatus)
    if ~switchStatus(s), continue; end
    prompt = questionBox( ...
      'Prompt', sprintf('Apply %s selection to exported data\?',switchOptions(s)), ...
      'Title', sprintf('Apply %s\?',regexprep(lower(switchOptions(s)), "(^|\.)\s*.","${upper($0)}")), ...
      'Options', {'Yes','No'}, ...
      'Default', 'No' ...
      );
    switchStatus(s) = strcmpi(prompt.response,'Yes');
  end
  % apply selections
  for stype = switchOptions(switchStatus)
    app.loadShow.update(sprintf("Applying %s...",stype),"animate",true);
    tmr = tic;
    switch stype
      case "filter"
        prefs = app.services.getPref('filter');
        iData = iData.Filter( ...
          'type', lower(prefs.Type), ...
          'frequencies', [prefs.LowPassFrequency,prefs.HighPassFrequency], ...
          'order', prefs.Order, ...
          'devices', shownDevices ...
          );
      case "baseline"
        prefs = app.services.getPref('statistics');
        iData = iData.Baseline( ...
          'baselineRegion', lower(prefs.BaselineRegion), ...
          'numBaselinePoints', prefs.BaselinePoints, ...
          'baselineOffsetPoints', prefs.BaselineOffset, ...
          'noFitWarning', true, ... % prevent fitting warning
          'devices', shownDevices ...
          );
      otherwise
        continue
    end
    while toc(tmr) < 1.2, end
    app.loadShow.update("Done!","animate",false,'forceDelay',0.8);
  end
end

app.loadShow.update("Saving...","animate",true,'forceDelay',0.5);

if fType == 1
  try
    save(userFile,'iData','-mat','-v7.3');
  catch e
    app.loadShow.update('Error!');
    pause(1.5);
    app.loadShow.shutdown();
    app.ui.focus();
    iris.app.Info.throwError(e.message);  
  end
  fprintf('IrisData saved to:\n"%s"\n',userFile);
  fprintf('To load the data use:\n    load("%s",''-mat'');\n',userFile);
  
  fprintf('Be sure to add the location for the IrisData class definition to your path.\n');
  fprintf('It is currently located at:\n  "%s"\n', ...
    fullfile(iris.app.Info.getAppPath(), 'lib', 'IrisData.m') ...
    );
else
  % export only shown data
  dataMatrix = iData.getDataMatrix('devices',shownDevices);
  delims = [",","\t"];
  delim = delims(fType-1);
  wSpec = @(t,n)strcat(strjoin(utilities.rep(t,n),delim),"\n");
  % export based on devices
  for dev = string(shownDevices)
    % append file name
    dFile = regexprep(userFile,"(\.)(\w+$)",sprintf("_%s.$2",dev));
    dIdx = find(strcmp(dataMatrix.device,dev),1,'first');
    dU = dataMatrix.units{dIdx};
    dX = dataMatrix.x{dIdx};
    dY = dataMatrix.y{dIdx};
    [dL,dN] = size(dX);
    dspec = @(dim)sprintf("%s%%d_%s",dim,dU.(dim));
    dLabs = [string(sprintfc(dspec('x'),1:dN)),string(sprintfc(dspec('y'),1:dN))];
    fid = fopen(dFile,'w'); %overwrite contents
    if fid < 0
      fprintf("Could not create file: %s\n",dFile);
      continue
    end
    fprintf(fid,wSpec("%s",dN*2),dLabs);
    for row = 1:dL
      fprintf(fid,wSpec("%f",dN*2),[dX(row,:),dY(row,:)]);
    end
    fclose(fid);
    pause(0.01);
    fprintf("Data saved to:\n\t'%s'\n",dFile);
  end
end

% finalize
app.loadShow.update('Completed!');
app.options.LastSavedDirectory = fileparts(userFile);
tmr = tic;
while toc(tmr) < 1.2, end

app.loadShow.shutdown();
app.ui.focus();
end

