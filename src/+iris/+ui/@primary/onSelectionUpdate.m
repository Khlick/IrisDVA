function onSelectionUpdate(obj)
%%%
if isempty(obj.selection)
  obj.setSlider('off');
  % reset all values?
  return
end

% copy sel to prevent recursion
sel = obj.selection;
pre = obj.previousSelction;

isNewSelection = isempty(pre) || ~isequal(sel.selected,pre.selected);
isNewHighlight = isempty(pre) || ~isequal(sel.highlighted,pre.highlighted);
isNewTotal = isempty(pre) || ~isequal(sel.total,pre.total);

% update if selection
if isNewSelection
  obj.OverlapTicker.Value = num2str(length(sel.selected));
  newDomain = utilities.domain(sel.selected);
  newDomain = [-0.49,0.49]+newDomain;
  % set slider domain if not the same
  if ~isequal(obj.SelectionNavigatorSlider.Limits, newDomain)
    obj.SelectionNavigatorSlider.Limits = newDomain;
    obj.SelectionNavigatorSlider.MajorTicks = unique( ...
      round( ...
      linspace( ...
      newDomain(1), ...
      newDomain(end), ...
      min([10,length(sel.selected)]) ...
      ) ...
      ) ...
      );
  end
  % update showing n of total
  dom = unique(utilities.domain(sel.selected));
  showStr = strjoin(cellstr(num2str(dom')), '...');
  showStr = sprintf('%s of %d', showStr,sel.total);
  obj.ShowingValueLabel.Text = showStr;
end

% check if the highlight has changed
if isNewHighlight
  obj.CurrentDataTicker.Value = num2str(sel.highlighted);
  % set the slider value to the highlighted value
  obj.SelectionNavigatorSlider.Value = sel.highlighted;
end

if isNewTotal
  dom = unique(utilities.domain(sel.selected));
  showStr = strjoin(cellstr(num2str(dom')), '...');
  showStr = sprintf('%s of %d', showStr,sel.total);
  obj.ShowingValueLabel.Text = showStr;
end


% set the labels/values of the slider (if selected length > 1)
if length(sel.selected) > 1
  % enable the slider and update the values
  obj.setSlider('on');
  % highlight the new selection
  dPrefs = iris.pref.display.getDefault();
  if length(sel.selected) > 1
    obj.Axes.setHighlighted(sel.highlighted,dPrefs.LineWidth);
  end
else
  obj.setSlider('off');
  dPrefs = iris.pref.display.getDefault();
  if length(sel.selected) > 1
    obj.Axes.setHighlighted(0,dPrefs.LineWidth);
  end
end

% update devices
if ~isequal(obj.DevicesSelection.Items, sel.devices)
  obj.DevicesSelection.Items = sel.devices;
end

% select shown device
if ~isequal(obj.DevicesSelection.Value, sel.showingDevices)
  obj.DevicesSelection.Value = sel.showingDevices;
end

% update the Data toggle of the highlighted value
hIncl = sel.inclusion(sel.selected == sel.highlighted);
obj.updateInclusion(hIncl);

end

