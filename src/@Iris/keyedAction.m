function keyedAction(app,action)
fprintf('keyedAction:"%s"\n', action);
switch action
  case 'resetView'
    app.ui.Axes.resetView();
  case 'save'
    app.saveSession([],[]);
  otherwise
    disp('tbd')
end
end

