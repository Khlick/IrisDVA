function keyedAction(app,action)
switch action
  case 'resetView'
    app.ui.Axes.resetView();
  case 'save'
    app.saveSession([],[]);
  case 'quit'
    app.shutdownApp([],[]);
  otherwise
    fprintf('keyedAction:"%s"\n', action);
end
end

