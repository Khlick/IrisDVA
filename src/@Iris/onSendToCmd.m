function onSendToCmd(app,~,~)

doSave = iris.ui.questionBox( ...
  'Prompt', 'Export current view or entire session?', ...
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
    return;
end

app.loadShow.update("Collecting data...",'animate',true,'forceDelay',0.8);

sessionId = sprintf( ...
  'IrisExport%s%s', ...
  datestr(app.sessionInfo.sessionStart,'mmmDD'), ...
  doSave.response ...
  );
while ismember(sessionId,evalin('base','who'))
  currentNumber = str2double(regexp(sessionId,'(?<=[a-zA-Z]+)\d+$','match','once'));
  if isnan(currentNumber)
    currentNumber = 1; %#ok
    sessionId = [sessionId,'1']; %#ok
    continue;
  else
    currentNumber = currentNumber+1;
  end
  sessionId = regexprep( ...
    sessionId, ...
    '(^\w+)((?<=[a-zA-Z]+)\d+$)', ...
    sprintf('$1%d', currentNumber) ...
    );
end

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


% send to command
assignin('base',sessionId,iData);
% let the user know they should have IrisData definition on their path
fprintf('Sent "%s" to the global workspace.\n', sessionId);

fprintf('Be sure to add the location for the IrisData class definition to your path.\n');
fprintf('It is located at:\n  "%s"\n', ...
  fullfile(iris.app.Info.getAppPath(), 'lib', 'IrisData.m') ...
  );


end
