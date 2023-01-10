function onRemoveLastCorrection(app,~,~)
  d = app.EditorTable.Data;
  nCrx = width(d);
  if nCrx == 0, return; end
  target = d.Properties.VariableNames(end);
  d(:,end) = [];
  app.EditorTable.Data = d;
  app.EditorTable.ColumnName = d.Properties.VariableNames;
  % remove lines
  [pLine,cLine] = app.getCorrectionLinesByTag(target);
  idx = ismember(app.EditorCorrectionLines,[pLine,cLine]);
  delete([pLine,cLine]);
  app.EditorCorrectionLines(idx) = [];
  app.setActiveCorrectionIndex(nCrx-1);
  if (nCrx-1) == 0
    % last column was removed, clear table
    app.EditorTable.Data = table();
    app.EditorTable.ColumnName = {};
  end
end

