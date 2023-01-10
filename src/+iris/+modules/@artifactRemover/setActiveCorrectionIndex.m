function setActiveCorrectionIndex(app,idx)
  if ~idx
    t = "";
  else
    t = "C_" + idx;
  end
  app.EditTarget = t;
  set( ...
    app.EditorCorrectionLines, ...
    Color=app.EDIT_INACTIVE, ...
    MarkerFaceColor=app.EDIT_INACTIVE ...
    );
  if app.hasEditTarget
    % update colors for lines
    pts = artifactRemover.pointPar(app.EDIT_ACTIVE);
    lns = artifactRemover.linePar(app.EDIT_ACTIVE);
    [pLine,cLine] = app.getCorrectionLinesByTag(app.EditTarget);
    set(cLine,lns{:});
    set(pLine,pts{:});
  end

end
