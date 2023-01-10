function onAddNewCorrection(app,~,~)
  d = app.EditorTable.Data;
  nCrx = width(d);
  if ~nCrx
    d.C_1 = nan(1,2);
  else
    d.("C_"+(nCrx+1)) = nan(height(d),2);
  end
  app.EditorTable.Data = d;
  app.EditorTable.ColumnName = d.Properties.VariableNames;
  app.setActiveCorrectionIndex(nCrx+1);
  pause(0.01);
  app.updateEditCorrectionLines();
end

