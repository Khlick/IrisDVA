function onSpinnerChanged(app,src,evt)
  newValue = evt.Value;
  switch src.Tag
    case "OPEN"
      roiTag = app.ROI_TAG(1);
      otherTag = app.ROI_TAG(2);
      limIdx = 1;
    case "CLOSE"
      roiTag = app.ROI_TAG(2);
      otherTag = app.ROI_TAG(1);
      limIdx = 2;
  end
  roi = findobj(app.container,"Tag",roiTag);
  other = findobj(app.container,"Tag",otherTag);
  allowedRange = sort( ...
    [ ...
    mean(other.Vertices(:,1)), ...
    app.dataLimits.X(limIdx) ...
    ] ...
    );
  if ~artifactRemover.isWithinRange(newValue,allowedRange,true)
    [~,newValue] = artifactRemover.getNearestDataPoint(newValue,1:2,allowedRange);
  end
  app.didChange = newValue ~= evt.PreviousValue;
  roi.Vertices(:,1) = roi.Vertices(:,1) - mean(roi.Vertices(:,1)) + newValue;
  src.Value = newValue;
  app.updateEditLine();
end

