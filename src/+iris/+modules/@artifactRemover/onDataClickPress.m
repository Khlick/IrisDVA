function onDataClickPress(app,src,~)

  if strcmp(app.currentROITag,'')
    app.selectedROI = [];
    app.didClickROI = false;
    return
  end

  app.selectedROI = findobj(src,"Tag",app.currentROITag);
  app.currentAlpha = app.selectedROI.FaceAlpha;
  app.selectedROI.FaceAlpha = app.ALPHA_DRAG;
  app.didClickROI = true;
  app.isMouseDown = true;
  if strcmp(src.SelectionType,'open')
    switch app.currentROITag
      case "START"
        id = 1;
        spin = app.StartSpinner;
      case "END"
        id = 2;
        spin = app.EndSpinner;
    end
    lims = app.dataLimits.X;
    app.selectedROI.Vertices(:,1) = ...
      app.selectedROI.Vertices(:,1) - ...
      mean(app.selectedROI.Vertices(:,1)) + ...
      lims(id);
    spin.Value = lims(id);
    % double-click causes update
    app.didChange = true;
  end
end

