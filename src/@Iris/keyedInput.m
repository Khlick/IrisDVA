function keyedInput(app,~,evt)

% disallow key press capture if current object is an edit field of the ui.
if isa(app.ui.CurrentObject,'matlab.ui.control.EditField'), return; end

% 
keyDat = evt.Data;

key = lower(keyDat.Key);
% return if the key is not an action key
if ~ismember(key,properties(app.keyMap)), return; end

modifiers = struct( ...
  'CTRL', ismember('control', keyDat.Modifier), ...
  'SHIFT', ismember('shift', keyDat.Modifier), ...
  'ALT', ismember('alt', keyDat.Modifier) ...
  );

if ~app.handler.isready
  % check if the call was to open/load, quit, help, about
  isOK = modifiers.CTRL && ismember(key, {'n','o','q','h'});
  isPrintScreen = modifiers.CTRL && modifiers.ALT && strcmpi(key,'p');
  isAllowed = isOK || isPrintScreen;
  if ~isAllowed, return; end    
end

% locate the action stored for the key combination recieved. If no action is
% found, die.
try
  stored = app.keyMap.(key);
  action = '';
  for I = 1:numel(stored)
    % find the first match
    if isequal(modifiers,utilities.fastrmField(stored(I),{'ACTION'}))
      action = stored(I).ACTION;
      break
    end
  end
catch
  iris.app.Info.showWarning('No stored keypress action.');
  return
end

if isempty(action), return; end
% actions should be camelCase, grab task as its own camelCase,
% so that actionTaskName -> {'action', 'taskName'}
% and that menuMenuName -> {'menu', 'menuName'}

[aType,~,remI] = regexp(action,'^[a-z]*(?=[A-Z]{1})','match'); 
action = [lower(action(remI+1)),action(remI+2:end)];
switch char(aType)
  case 'menu'
    app.callMenu([],iris.infra.eventData(action));
    return
  case 'action'
    if contains(action,{'new','import'})
      app.fileLoad([],iris.infra.eventData(action));
      return
    end
    app.keyedAction(action);
  case 'toggle'
    switch action
      case 'datum'
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
