function onSelectionUpdate(obj)
%%%
if isempty(obj.selection)
  obj.setSlider('off');
  % reset all values?
  return;
end
% copy sel to prevent recursion
sel = obj.selection;

% update the tickers
obj.CurrentDataTicker.Value = num2str(sel.highlighted);
obj.OverlapTicker.Value = num2str(length(sel.selected));

% set the labels/values of the slider (if selected length > 1)
if length(sel.selected) > 1
  % enable the slider and update the values
  newDomain = utilities.domain(sel.selected);
  obj.SelectionNavigatorSlider.Limits = [-0.49,0.49]+newDomain;
  obj.SelectionNavigatorSlider.MajorTicks = unique( ...
    round( ...
    linspace( ...
    newDomain(1), ...
    newDomain(end), ...
    min([7,length(sel.selected)]) ...
    ) ...
    ) ...
    );
  obj.setSlider('on');
else
  obj.SelectionNavigatorSlider.Limits = [-0.5,0.5] + sel.highlighted;
  obj.SelectionNavigatorSlider.MajorTicks = sel.highlighted;
  obj.setSlider('off');
end
obj.SelectionNavigatorSlider.Value = sel.highlighted;

% update showing n of total
dom = unique(utilities.domain(sel.selected));
showStr = strjoin(cellstr(num2str(dom')), '...');
showStr = sprintf('%s of %d', showStr,sel.total);
obj.ShowingValueLabel.Text = showStr;

% update devices
obj.DevicesSelection.Items = sel.devices;

% select shown device
obj.DevicesSelection.Value = sel.showingDevices;

% update the Data toggle of the highlighted value
hIncl = sel.inclusion(sel.selected == sel.highlighted);
obj.updateInclusion(hIncl);

% update the highlighted string
dPrefs = iris.pref.display.getDefault();
if length(sel.selected) > 1
  obj.Axes.setHighlighted(sel.highlighted,dPrefs.LineWidth);
end

end

