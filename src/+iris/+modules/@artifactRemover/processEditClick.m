function processEditClick(app,type)
  % gather editor table
  t = app.EditorTable.Data;
  switch type
    case 'normal'
      % left-click: add new point to current edittarget
      h = height(t);
      v = t.(app.EditTarget);
      targetRow = find(any(isnan(v),2),1,'first');
      if isempty(targetRow), targetRow = h+1; end
      v(targetRow,:) = app.lastEditClickedPoint;
      % also keep the working vector sorted
      [~,sOrder,~] = unique(v(~isnan(v(:,1)),1));
      v = v(sOrder,:);
      nV = size(v,1);
      if nV < h
        df = h-nV;
        v(end+(1:df),:) = nan;
      elseif nV > h
        df = nV - h;
        t(end+(1:df),:) = repmat({nan(1,2)},df,width(t));
      end

      % insert new data and apply to ui table
      t.(app.EditTarget) = v;
    case 'extend'
      % middle-click Add new editor vector and create point at click
      app.onAddNewCorrection([],[]);
      pause(0.001);
      app.processEditClick('normal');
      return
    case 'alt'
      if ismember(app.lastEditHitObject,app.EditorCorrectionLines)
        if endsWith(app.lastEditHitObject.Tag,'C'), return; end
        target = regexprep(app.lastEditHitObject.Tag,"_P$","");
        d = t.(target);
        lastClickPt = app.lastEditClickedPoint;
        v = zeros(1,2);
        [v(1),v(2)] = artifactRemover.getNearestDataPoint( ...
          lastClickPt, ...
          d(:,1), d(:,2) ...
          );
        targetRow = d(:,1)==v(1);
        d(targetRow,:) = [];
        % pad data to fig height
        h = height(t);
        nV = size(d,1);
        if nV < h
          df = h-nV;
          d(end+(1:df),:) = nan;
        elseif nV > h
          df = nV - h;
          t(end+(1:df),:) = repmat({nan(1,2)},df,width(t));
        end
        % set new data in
        t.(target) = d;
      end
  end
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
