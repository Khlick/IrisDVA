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
obj.CurrentEpochTicker.Value = num2str(sel.highlighted);
obj.OverlapTicker.Value = num2str(length(sel.selected));

% set the labels/values of the slider (if selected length > 1)
if length(sel.selected) > 1
  % enable the slider and update the values
  newDomain = domain(sel.selected);
  obj.CurrentEpochSlider.Limits = [-0.49,0.49]+newDomain;
  obj.CurrentEpochSlider.MajorTicks = unique( ...
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
  obj.CurrentEpochSlider.Limits = [-0.5,0.5] + sel.highlighted;
  obj.CurrentEpochSlider.MajorTicks = sel.highlighted;
  obj.setSlider('off');
end
obj.CurrentEpochSlider.Value = sel.highlighted;

% update showing n of total
dom = unique(domain(sel.selected));
showStr = strjoin(cellstr(num2str(dom')), '...');
showStr = sprintf('%s of %d', showStr,sel.total);
obj.ShowingValueString.Text = showStr;

% update devices
obj.DevicesSelection.Items = sel.devices;
% select shown device
obj.DevicesSelection.Value = sel.showingDevices;

% update the Epoch toggle of the highlighted value
hIncl = sel.inclusion(sel.selected == sel.highlighted);
obj.updateInclusion(hIncl);

end

