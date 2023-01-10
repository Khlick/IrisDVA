function onDataClickDrag(app,src,~)
  % dragging allowed
  hAx = app.selectedROI.Parent;
  lims = app.dataLimits.X;
  % new location
  thisX = hAx.CurrentPoint(1,1);
  thisTag = app.selectedROI.Tag;

  verts = app.selectedROI.Vertices;
  vertCenter = mean(verts([1,end],1));

  switch thisTag
    case "START"
      other = findobj(src,"Tag","END");
      allowedRange = [ ...
        lims(1), ...
        mean(other.Vertices([1,end],1)) ...
        ];
    case "END"
      other = findobj(src,"Tag","START");
      allowedRange = [ ...
        mean(other.Vertices([1,end],1)), ...
        lims(2) ...
        ];
  end
  if ~artifactRemover.isWithinRange(thisX,allowedRange,false)
    return
  end
  if round(abs(thisX-vertCenter),5) > (app.roiWidth*0.01)
    app.didChange = true;
  else
    app.didChange = false;
  end
  app.selectedROI.Vertices(:,1) = verts(:,1) - vertCenter + thisX;
  app.selectedROI.FaceAlpha = app.ALPHA_DRAG;
  spinner = app.getSpinnerFromTag(thisTag);
  spinner.Value = thisX;
  drawnow();
end

