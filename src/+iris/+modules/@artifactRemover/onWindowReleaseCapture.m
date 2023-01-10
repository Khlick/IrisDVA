function onWindowReleaseCapture(app,src,evt)
  if ~app.hasdata, return; end
  if app.didClickROI && app.isMouseDown
    app.onDataClickRelease(src,evt);
    return
  end
  % didn't click ROI
  % check if clicked on EditAxis
  if app.didClickEdit
    if ~isempty(app.lastEditClickedPoint) && ...
        (app.hasEditTarget || (src.SelectionType == "extend"))
      app.processEditClick(src.SelectionType);
    end
    app.didClickEdit = false;
  end
end

