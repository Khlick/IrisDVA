function onSaveChanges(app,~,~)
  % check if there is pending changes and ask to apply them
  if ~isempty(app.EditorTable.Data) && app.setting_ShowWarnOnApply
    p = iris.ui.questionBox( ...
      Title= 'Apply Changes?', ...
      Options= {'Yes','No'}, ...
      Prompt= 'There are unsaved corrections, apply them first?', ...
      Default= 'Yes' ...
      );
    if strcmp(p.response,'Yes')
      app.onApplyCurrentCorrections([],[]);
      pause(0.1);
    end
  end
  app.rawBackup = {app.rawBackup,app.Data};
  % get irisdata copydata and overwrite x,y for selected device
  dev = app.selectedDevice;
  dIx = app.Data.DeviceMap(dev);
  d = app.Data.copyData(); % includes all data regardless of inclusion status
  inc = app.Data.InclusionList;
  N = app.Data.nDatums;
  % loop and update YData for selected device
  for idx = 1:N
    if ~inc(idx), continue; end
    dLabel = string(app.Data.IndexMap(idx));
    dInd = startsWith(get(app.DataLines,'DisplayName'),dLabel+"-");
    L = app.DataLines(dInd);
    if ~isequal(d(idx).y{dIx(idx)}(:),L.YData(:))
      d(idx).y{dIx(idx)} = L.YData(:);
    end
  end
  % set the new data
  newData = app.Data.UpdateData(d);
  if ~isequal(newData,app.Data)
    %set data method will clear on update
    app.setData(newData);
  end
end

