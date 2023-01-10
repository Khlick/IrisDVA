function onApplyCurrentCorrections(app,~,~)
  % onapplycurrentcorrections
  if isempty(app.EditorTable.Data), return; end
  % get line from editor
  editLine = app.CurrentEditLine;
  cLines = app.EditorCorrectionLines( ...
    endsWith({app.EditorCorrectionLines.Tag},'C') ...
    );
  % apply correction data to line
  for L = 1:numel(cLines)
    target = regexprep(cLines(L).Tag,'_C$',"");
    cX = cLines(L).XData;
    cY = cLines(L).YData;
    editLine.YData(ismember(editLine.XData, cX)) = cY;
    % remove table var
    app.EditorTable.Data = removevars(app.EditorTable.Data,target);
    % remove related lines
    % append _ so that C_1 does not also catch C_10...
    idx = startsWith({app.EditorCorrectionLines.Tag},target+"_");
    % delete lines
    delete(app.EditorCorrectionLines(idx));
    % remove references to deleted lines
    app.EditorCorrectionLines(idx) = [];
  end

  % store line info into the viewAxes line
  datumLine = app.selectedDataLine;
  datumLine.YData(ismember(datumLine.XData,editLine.XData)) = editLine.YData;

  % clear the editor table columns
  app.EditorTable.ColumnName = {};
  app.EditorTable.Data = table();
  app.setActiveCorrectionIndex(0);
end

