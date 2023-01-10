function updateDatum(app)
  dLabel = string(app.Data.IndexMap(app.datumIndex));
  dInd = startsWith(get(app.DataLines,'DisplayName'),dLabel+"-");

  % show selected, hide others
  set(app.DataLines(~dInd),Visible='off');
  selectedLine = app.DataLines(dInd);
  set(selectedLine,Visible='on');

  
  if ~app.isinit
    % set new limits
    lims = app.dataLimits.X(:)';
    roiW = app.roiWidth;
    app.ViewAxes.XLim = lims + [-1,1].*roiW;
  
    app.StartSpinner.Limits = lims;
    app.StartSpinner.Value = lims(1);
    app.EndSpinner.Limits = lims;
    app.EndSpinner.Value = lims(2);
    % update roi
    for i = 1:2
      verts = app.AnalysisROI(i).Vertices;
      vertCenter = mean(verts([1,end],1));
      app.AnalysisROI(i).Vertices(:,1) = verts(:,1) - vertCenter + lims(i);
    end
    % set roi to top
    idx = ismember(app.ViewAxes.Children,app.AnalysisROI);
    app.ViewAxes.Children = [app.ViewAxes.Children(idx);app.ViewAxes.Children(~idx)];
  end
  
  % update label
  app.CurrentIndexLabel.Text = sprintf("Showing %s of %d",dLabel,app.Data.nDatums);

  % update the edit line
  drawnow();
  app.updateEditLine();
end
