function onUndoLastCorrection(app,~,~)
  % behavior for undo button and right-click on existing point.
  if ~app.hasEditTarget, return; end
  target = app.EditTarget;
  t = app.EditorTable.Data;
  v = t.(target);
  targetRow = find(~isnan(v(:,1)),1,'last');
  v(targetRow,:) = [];
  % pad data to fig height
  h = height(t);
  nV = size(v,1);
  if nV < h
    df = h-nV;
    v(end+(1:df),:) = nan;
  elseif nV > h
    df = nV - h;
    t(end+(1:df),:) = repmat({nan(1,2)},df,width(t));
  end
  % set new data in
  t.(target) = v;
  % trim table end
  lastNans = table2array(varfun(@(v)any(isnan(v),2),t));
  dropInds = all(lastNans,2);
  t(dropInds,:) = [];

  % set table in
  if isequal(app.EditorTable.Data,t), return; end
  app.EditorTable.Data = t;
  drawnow();
  % update lines
  app.updateEditCorrectionLines(); % turn back on after finishing above
end

