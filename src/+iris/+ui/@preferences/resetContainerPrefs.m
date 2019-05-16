function resetContainerPrefs(obj)
selectedNodes = obj.PreferencesTree.SelectedNodes;
% prompt for selection type
buttons = {'Yes', 'All', 'Cancel'};
opts = struct('Default', 'Cancel', 'Interpreter', 'tex');
tCol = num2cell(iris.app.Aes.appColor(1,'red'));
aCol = num2cell(iris.app.Aes.appColor(1,'green'));
msg = sprintf( ...
  [ ...
    'Apply defaults to ',...
    '{\\bf\\color[rgb]{%.1f,%.1f,%.1f} %s}',...
    '\\rm\\color{black} or to ', ...
    '{\\bf\\color[rgb]{%.1f,%.1f,%.1f} All}',...
    '\\rm\\color{black} settings?' ...
  ], ...
  aCol{:}, selectedNodes.Text, tCol{:});

resp = questdlg(msg,'Reset Preferences', buttons{:}, opts);

switch resp
  case 'All'
    obj.reset();
    obj.options.reset();
    obj.getContainerPrefs();
    obj.update();
    notify(obj, 'AxesChanged');
    notify(obj, 'DisplayChanged');
    notify(obj, 'FilterChanged');
    notify(obj, 'StatisticsChanged');
    notify(obj, 'ScalingChanged');
    return
  case 'Cancel'
    return 
  otherwise
    %continue
end


switch selectedNodes.Text
    case 'Navigation'
      rProps = {'c'};
    case 'Workspace'
      rProps = {'a','d'};
    case 'Data'
      rProps = {'f','st','sc'};
    case 'Keyboard'  
      warning('No keyboard settings to reset');
      return
    case 'Control'
      rProps = {'c'};
    case 'Variables'
      rProps = {'a'};
    case 'Filter'
      rProps = {'f'};
    case 'Statistics'
      rProps = {'st'};
    case 'Scaling'
      rProps = {'sc'};
    case 'Display'
      rProps = {'d'};
end

obj.options.reset(rProps);
obj.getContainerPrefs();
obj.update();
end