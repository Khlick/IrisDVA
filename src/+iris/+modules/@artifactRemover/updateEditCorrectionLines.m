function updateEditCorrectionLines(app)
  if ~app.hasEditTarget, return; end
  target = app.EditTarget;
  vals = app.EditorTable.Data.(target);
  % setup for plotting
  pts = artifactRemover.pointPar(app.EDIT_ACTIVE,target);
  lns = artifactRemover.linePar(app.EDIT_ACTIVE,target);
  if isempty(app.EditorCorrectionLines)
    app.EditorCorrectionLines = [ ...
      line(app.EditAxes,nan,nan,lns{:}), ...
      line(app.EditAxes,nan,nan,pts{:}) % draw points on top
      ]; % create lines: use tag
  end
  % locate current tags
  [pLine,cLine] = app.getCorrectionLinesByTag(target);
  if isempty(pLine)
    pLine = line(app.EditAxes,nan,nan,pts{:});
    cLine = line(app.EditAxes,nan,nan,lns{:});
    app.EditorCorrectionLines(end+(1:2)) = [pLine,cLine];
  end

  set(pLine,XData = vals(:,1), YData=vals(:,2));

  % calculate the correction line using promises
  vPts = vals(~isnan(vals(:,1)),:);
  if size(vPts,1) > 1
    data = [app.CurrentEditLine.XData(:),app.CurrentEditLine.YData(:)];
    promise = parfeval( ...
      backgroundPool, ...
      @artifactRemover.computeCorrection, ...
      1, ...
      vPts, ...
      data, ...
      target ...
      );
    % once computation is complete, plot the line and
    afterAll(promise,@app.drawCorrections,0);
  else
    set(cLine,XData=nan,YData=nan);
  end

end

