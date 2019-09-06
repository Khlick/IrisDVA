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

% send to command
assignin('base',sessionId,iData);
% let the user know they should have IrisData definition on their path
fprintf('Sent "%s" to the global workspace.\n', sessionId);

fprintf('Be sure to add the location for the IrisData class definition to your path.\n');
fprintf('It is located at:\n  "%s"\n', ...
  fullfile(iris.app.Info.getAppPath(), 'lib', 'IrisData.m') ...
  );


end