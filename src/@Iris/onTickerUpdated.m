function onTickerUpdated(app,src,event)
%src will be shortcut handle to primary ui
cSel = app.handler.currentSelection;
switch event.Data.Type
  case 'CurrentDatum'
    if length(event.Data.Value) > 1
      newSel = event.Data.Value;
    else
      newSel = (0:(numel(cSel.selected)-1)) + event.Data.Value;
    end
    app.handler.currentSelection = newSel;
  case 'Overlap'
    newSel = (0:(event.Data.Value-1)) + cSel.selected(1);
    if isequal(newSel,cSel.selected), return; end
    app.handler.currentSelection = newSel;
  case 'Slider'
    % selection is already updated by the sliderChanging method, 
    % so now we just
    % update the primary view axes object to show which line is selected.
    %HLpos = find(src.selection.selected == event.Data.Value,1,'first');
    HLName = app.handler(event.Data.Value).id;
    dOpts = iris.pref.display.getDefault();
    src.Axes.highlightByName(HLName,dOpts.LineWidth);
end
end