function onRevertChanges(app,~,~)
  % only can revert if we have save points
  if ~isempty(app.rawBackup)
    app.setData(app.rawBackup{end});
    app.rawBackup(end) = [];%pop the end
  end
end

