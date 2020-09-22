function keyedAction(app,action)
switch action
  case 'resetView'
    app.ui.Axes.resetView();
  case 'save'
    app.saveSession([],[]);
  case 'quit'
    app.shutdownApp([],[]);
  case 'screenshot'
    s = app.ui.getScreenshot();
    fn = fullfile( ...
      iris.pref.analysis.getDefault().OutputDirectory, ...
      sprintf('Screenshot_%s.png',datestr(now,'YYYYmmmDD_HH-MM-SS')) ...
      );
    try
      imwrite(s,fn,'Author',sprintf('IrisV%s',app.options.CurrentVersion));
      fprintf('Iris screenshot saved:\n  "%s"\n',fn);
    catch x
      iris.app.Info.showWarning( ...
        sprintf( ...
          'Screenshot unable to save with message:\n  "%s"\n', ...
          x.msg ...
          ) ...
        );
    end
  case 'command'
    app.onSendToCmd([],[]);
  otherwise
    fprintf('keyedAction:"%s"\n', action);
end
end

