function updateEditLine(app)
  if app.isinit, return; end
  delete(app.CurrentEditLine);
  delete(app.EditorCorrectionLines);
  app.EditorCorrectionLines = [];
  app.CurrentEditLine = [];
  app.EditorTable.Data = table();
  app.setActiveCorrectionIndex(0);
  selectedLine = app.selectedDataLine;
  x = selectedLine.XData;
  y = selectedLine.YData;
  aRange = app.analysisLimits;
  aInd = (x >= aRange(1)) & (x <= aRange(2));
  app.CurrentEditLine = line( ...
    app.EditAxes, ...
    x(aInd), y(aInd), ...
    Color=selectedLine.Color, ...
    LineWidth= 0.5 ...
    );
end

