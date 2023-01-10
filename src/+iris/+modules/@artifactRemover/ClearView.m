function ClearView(app)
  delete(app.DataLines);
  delete(app.CurrentEditLine);
  delete(app.EditorCorrectionLines);
  app.EditorCorrectionLines = [];
  app.CurrentEditLine = [];
  app.DataLines = [];
  delete(app.AnalysisROI);
  app.AnalysisROI = [];
  app.EditorTable.Data = table();
  app.setActiveCorrectionIndex(0);
  app.ViewAxes.XLabel.String = '';
  app.ViewAxes.YLabel.String = '';
end
