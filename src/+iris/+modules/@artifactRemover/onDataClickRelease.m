function onDataClickRelease(app,~,~)
  % released after click/drag on ROI
  if any(ismember(app.ROI_TAG,app.currentROITag))
    % still hovering
    nAlpha = app.currentAlpha;
  else
    % not still hovering
    nAlpha = app.ALPHA;
  end
  app.selectedROI.FaceAlpha = nAlpha;

  % on release, let go of the selected roi
  app.selectedROI = [];
  app.isMouseDown = false;
  if app.didChange
    %app.updateAnalysis();
    app.updateEditLine();
  end
  app.didClickROI = false;
end

