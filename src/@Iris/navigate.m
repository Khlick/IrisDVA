function navigate(app,event)

% event should be a camelCase char array giving sizeDirection e.g.
% smallRight
[sz,dr] = regexp(event, '^[a-zA-z]{1}[a-z]*(?=[A-Z]?)','match','split');
sz = [upper(sz{1}(1)),lower(sz{1}(2:end))];
dr = lower(dr{end});

cSel = app.handler.currentSelection;

kOpt = app.navMap;

switch dr
  case {'up','down'}
    stepSize = ((2*strcmpi(dr,'up')-1)*kOpt.(['Overlay',sz]));
    nCur = numel(cSel.selected);
    nNew = nCur + stepSize;
    % handle if we sent request for less than 1
    if nNew < 1, nNew = 1; end
    % handle if we requested more than possible
    if (nNew + cSel.selected(1)-1) > (cSel.total - cSel.selected(1) + 1)
      nNew = (cSel.total - cSel.selected(1) + 1);
    end
    % just adding or reducing, so take cSel.selected(1) + 1:nNew
    newSel = cSel.selected(1) + (0:1:(nNew-1));
  case {'left', 'right'}
    if strcmpi(sz, 'within')
      sz = 'Small';
      within = true;
    else
      within = false;
    end
    if strcmpi(sz,'End') && strcmpi(dr,'left')
      stepSize = 1-min(cSel.selected);
    elseif strcmpi(sz,'End') && strcmpi(dr,'right')
      stepSize = cSel.total - max(cSel.selected);
    else
      stepSize = (2*strcmpi(dr,'right')-1)*kOpt.(['Step',sz]);
    end
    if within
      % new selecion stays the same so we will terminate the function from
      % here after updating the ui.selection
      uiSel = app.ui.selection;
      newHl = uiSel.highlighted + stepSize;
      if newHl > uiSel.selected(end)
        newHl = uiSel.selected(end);
      elseif newHl < uiSel.selected(1)
        newHl =  uiSel.selected(1);
      end
      if isequal(newHl,uiSel.highlighted), return; end
      uiSel.highlighted = newHl;
      app.ui.selection = uiSel;
      
      return
    else
      % left and right will shift the current selection by the step
      newSel = cSel.selected + stepSize;
    end
end
% validate
newSel(newSel < 1) = 1;
newSel(newSel > cSel.total) = cSel.total;
newSel = unique(newSel);
if isequal(newSel,cSel.selected)
  % check if highlight is different?
  return
end
app.handler.currentSelection = newSel;
end

