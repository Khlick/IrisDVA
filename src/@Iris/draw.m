function draw(app,varargin)
if ~app.handler.isready, return; end

%{
% send plotting information to the main view
app.ui.updateView(app.handler);
% If varargin{1} is supplied, set the number to the selected value after
% drawing the current data.
if nargin > 1
  sel = app.ui.selection;
  sel.highlighted = varargin{1};
  app.ui.selection = sel;
end

% prevent dev code below from running
return

%}
% TODO::
% Rather than sending the handler, let's send only the plot data
% along with relevant things needed for the UI to update the view.
% Send the selection, display information and plot data. This allows us to
% perform stats if we need to.


% Determine if our current selection from the handler and the UI are the same
sel = app.handler.currentSelection;

% get the devices
sel.devices = app.handler.getCurrentDevices();

% get the current UI selection parameters
uiStatus = app.ui.viewStatus;
uSel = uiStatus.selection;
if isempty(uSel) %this is the first time calling
  sel.showingDevices = sel.devices;
  if nargin > 1
    sel.highlighted = varargin{1};
  else
    sel.highlighted = sel.selected(1);
  end
else
  % let's determine if the devices from previous view are the same as the
  % new view. If not, i.e. now we have a different number of devices, or
  % there are different named devices... ?
  
  % first determine if the new device list is the same as the last one
  if isequal(sel.devices,uSel.devices)
    % devices are the same, simply copy the previsous showing devices.
    sel.showingDevices = uSel.showingDevices;
  else
    % devices are different, show any new devices and copy the previously
    % shown devices (if the are there).
    [sameD,newD,~] = intersect(sel.devices,uSel.devices);
    sameD = sameD(ismember(sameD,uSel.showingDevices));
    sel.showingDevices = sort( ...
      [ ...
        sameD, ...
        sel.devices( ...
          ~ismember( ...
            1:numel(sel.devices), ...
            newD ...
            ) ...
          ) ...
      ] ...
      );
  end
  
  % find the closest epoch to the previously highlighted index
  [~,minLoc] = min(abs(sel.selected - uSel.highlighted));
  sel.highlighted = sel.selected(minLoc);
end

% double check to make sure we don't have empty device list
if isempty(sel.showingDevices)
  sel.showingDevices = sel.devices;
end

% Get the current data set
currentData = app.handler(sel.selected);
currentData = currentData.subsetDevice(sel.showingDevices); % creates a copy
nData = numel(currentData);

% collect display props and unit labels
displayProps = currentData.getDisplayProps(true,false);
unitLabels = currentData.getDatumUnits(true);

% perform aggregation if switched on in the ui
if uiStatus.switches.aggregate
  statsPref = app.services.getPref('statistics');
  % do baseline subtraction for each epoch in stats
  aggZero = statsPref.BaselineZeroing;
  if aggZero
    switch statsPref.BaselineRegion
      case {'Beginning','End'}
        baselineType = lower(statsPref.BaselineRegion);
      case 'Fit (Sym)'
        baselineType = 'sym';
      case 'Fit (Asym)'
        baselineType = 'asym';
    end
    aggData = subtractBaseline( ...
      currentData, ...
      baselineType, ...
      statsPref.BaselinePoints, ...
      statsPref.BaselineOffset ...
      );
  else
    aggData = currentData.duplicate();
  end
  
  switch statsPref.Aggregate
    case 'Mean'
      fx = @(x)mean(x,'omitnan');
    case 'Median'
      fx = @(x)median(x,'omitnan');
    case 'Variance'
      fx = @(x)var(x,'omitnan');
    case 'Sum'
      fx = @(x)sum(x,'omitnan');
  end
  [aggData,ogGrps,grps] = aggData.Aggregate( ...
    'groupBy', statsPref.GroupBy, ...
    'statistic', fx, ...
    'interactive', false ...
    );
  % baseline zero aggs if switch is on but not checked in prefs
  % i.e. let get(aggData.plotData) handle zeroing if zero baseline unchecked in prefs
  % If checked in prefs, zeroing is done before aggregation, otherwise zeroing is
  % done after aggregation only if the baseline switch is on.
  if aggZero
    % if checked in prefs, prevent switch from changing this data
    modStatsPrefs = statsPref;
    modStatsPrefs.isBaselined = false;
    [aggData.statsPrefs] = deal(modStatsPrefs);
  end
  
  % set some properties based on groups
  displayPrefs = app.services.getPref('display');% struct
  
  % determine grouping colors
  nGroups = height(grps.Table);
  colorMap = iris.app.Aes.appColor(nGroups,'contrast');
  
  if statsPref.ShowOriginal
    % colorize the original epochs
    nShades = max(ogGrps.Table.Counts);
    ogColors = iris.app.Aes.shadifyColors(colorMap,nShades);
    for g = 1:height(ogGrps.Table)
      thisGrp = ogGrps.Table.SingularMap(g);
      thisIdx = find(ogGrps.Singular == thisGrp);
      for i = 1:length(thisIdx)
        idx = thisIdx(i);
        currentData(idx).color = ogColors(i,:,g);
        currentData(idx).opacity = 0.25;
      end
    end
  else
    mDispPrefs = displayPrefs;
    mDispPrefs.LineStyle = 'None';
    mDispPrefs.Marker = 'None';
    [currentData.displayPrefs] = deal(mDispPrefs);
  end    
  
  % colorize the grouped data
  for g = 1:nGroups
    aggData(g).color = colorMap(g,:);
    aggData(g).opacity = 1;
  end
  
  % concat the data for plotting
  currentData = [currentData;aggData];
else
  % colorize the lines
  colorMap = iris.app.Aes.appColor(nData,'contrast');
  for d = 1:nData
    currentData(d).color = colorMap(d,:);
    currentData(d).opacity = 0.95;
  end
end


% get the plot data objects for the axes
plotData = cat(1,currentData.plotData);

% send to the ui
app.ui.updateView(sel, displayProps, plotData, unitLabels);

end