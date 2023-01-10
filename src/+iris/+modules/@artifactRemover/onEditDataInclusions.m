function onEditDataInclusions(app,~,~)
  d = app.Data.uiSetInclusionList();
  if ~isequal(app.Data,d)
    app.setData(d);
  end
end

