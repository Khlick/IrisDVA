function keyedInput(app,~,evt)

if isempty(evt.Data.Character), return; end

event.Data = struct(...
  'SOURCE', class(evt.Data.Source), ...
  'CTRL', ismember('control', evt.Data.Modifier), ...
  'SHIFT', ismember('shift', evt.Data.Modifier), ...
  'ALT', ismember('alt', evt.Data.Modifier), ...
  'KEY', evt.Data.Key, ...
  'CHAR', evt.Data.Character, ...
  'CODE', unicode2native(evt.Data.Character) ...
  );
if ~app.handler.isready
  % check if the call was to open/load, quit, help, about
  if ~ismember(event.Data.KEY, {'n','o','q','h'}), return; end    
end

% n, o, q, h
modifiers = fastrmField(event.Data,{'SOURCE','KEY','CHAR','CODE'});
key = event.Data.KEY;
try
  stored = app.keyMap.(lower(key));
  action = '';
  for I = 1:numel(stored)
    % find the first match
    if isequal(modifiers,fastrmField(stored(I),{'ACTION'}))
      action = stored(I).ACTION;
      break;
    end
  end
catch
  return;
end

if isempty(action), return; end

[aType,~,remI] = regexp(action,'^[a-z]*(?=[A-Z]{1})','match'); 
action = [lower(action(remI+1)),action(remI+2:end)];
switch char(aType)
  case 'menu'
    app.callMenu([],iris.infra.eventData(action));
    return;
  case 'action'
    if contains(action,{'new','import'})
      app.fileLoad([],iris.infra.eventData(action));
      return;
    end
    app.keyedAction(action);
  case 'toggle'
    switch action
      case 'epoch'
        app.handler.toggleInclusion(app.ui.selection.highlighted);
        app.draw(app.ui.selection.highlighted);
      otherwise
        % is toggling a switch
        app.ui.manualSwitchThrow(action);
    end
  case 'navigate'
    app.navigate(action);
  otherwise
    
end

  
end