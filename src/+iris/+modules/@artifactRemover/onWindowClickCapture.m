function onWindowClickCapture(app,src,evt)
  if ~app.hasdata, return; end
  if isequal(ancestor(evt.HitObject,'axes'),app.EditAxes)
    % check if it was a 'button' type: if so, then we probably clicked the
    % interactive menu, zoom, etc
    if isa(evt.HitObject,'matlab.graphics.shape.internal.Button')
      app.lastEditClickedPoint = [];
      return
    end
    app.didClickEdit = src.SelectionType ~= "open";
    [x,y] = artifactRemover.getNearestDataPoint( ...
      evt.IntersectionPoint(1:2), ...
      app.CurrentEditLine.XData(:), ...
      app.CurrentEditLine.YData(:), ...
      10^(-app.setting_Precision) ...
      );
    app.lastEditClickedPoint = round([x,y],app.setting_Precision);
    app.lastEditHitObject = evt.HitObject;
    return
  end
  % otherwise send click to dataclick
  if any(ismember(["normal","open"],src.SelectionType))
    app.onDataClickPress(src,evt);
  else
    app.didChange = false;
    app.didClickROI = false;
  end
end

