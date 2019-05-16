function updateView(obj,h)
%% Update UI elemets
% Use data to update all the data-dependent UI elements and call the plot
% update method.
% Update to:
%   ShowingValueString: # of Total.
%   CurrentEpochTicker: lowest selected #
%   OverlapTicker: # of selected 
%   DevicesSelection: select all which current # has: this needs tracking
%   CurrentInfoTable: Non-data parts
%
%
% Called from Iris class

%DEV
%tt = tic();

%%% First we will collect the data
sel = h.currentSelection;
d = h(sel.selected);
% then copy the epoch metainfo 
sel.highlighted = sel.selected(1);
% we need to post some information about the selected devices
sel.devices = unique(cat(2,d.devices));
if ~isempty(obj.selection)
  % let's determine if the devices from previous view are the same as the
  % new view. If not, i.e. now we have a different number of devices, or
  % there are different named devices... ?
  
  % first determine if the new device list is the same as the last one
  if isequal(sel.devices,obj.selection.devices)
    % devices are the same, simply copy the previsous showing devices.
    sel.showingDevices = obj.selection.showingDevices;
  else
    % devices are different, show any new devices and copy the previously
    % shown devices (if the are there).
    [sameD,newD,~] = intersect(sel.devices,obj.selection.devices);
    sameD = sameD(ismember(sameD,obj.selection.showingDevices));
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
else
  sel.showingDevices = sel.devices;
end
% double check to make sure we don't have empty device list
if isempty(sel.showingDevices)
  sel.showingDevices = sel.devices;
end

if ~isequal(sel,obj.selection)
  % if we are changing something, we need to update the tickers
  % We can do this by simply relying on the onSelectionUpdate method
  obj.selection = sel;
end

%%% Update the current info view
% collect the info
infoCells = cat(1,d.displayProperties);
[labels,ix,ux] = unique(infoCells(:,1),'stable');
labels = [labels,cell(length(ix),1)];
% collapse like fields and separate (in arrival order) different values by
% a ";".
lens = zeros(length(ix),1);
for I = ix'
  tmpCell = unknown2CellStr(infoCells(ux == ix(I),2));
  labels{I,2} = strjoin(tmpCell,'; ');
  lens(I) = length(labels{I,2});
end

obj.CurrentInfoTable.Data = labels;
obj.CurrentInfoTable.ColumnWidth = {'auto', max(lens)*6.5};
% If we arent changing the selection, then we are likely changing layout or
% some other aesthetic componenet. So we need to get the plotting data and
% send it to the DOM for the custom JS D3.js to process into the canvas
% (HTML5)

obj.layout.update;

% if multiple devices are selected for each epoch, we need to 
% Get units for setting the X,Y obj.layout.setTitle('x', 'units')
units = arrayfun(@(a)cellfun(@(b){b.x,b.y},a.units','unif',0),d,'unif',0);
units = cat(1,units{:});
units = cat(1,units{:});
xUnits = unknownCell2Str(unknown2CellStr(units(:,1)),',');
yUnits = unknownCell2Str(unknown2CellStr(units(:,2)),',');
obj.layout.setTitle('x',xUnits);
obj.layout.setTitle('y',yUnits);

%DEV
%prepTime = toc(tt);
%fprintf('Time to prepare data: %0.4f sec.\n',prepTime);

%% MATLAB Axes
% comment this out if using d3.js approach

% plot data will parse the array into a json ready data

%dat = arrayfun(@(a)iris.data.encode.plotData(a), d,'UniformOutput',0);
dat = arrayfun(@(v)v.getPlotArray(), d, 'UniformOutput', false);

% set colors 
% For now, let's just make the traces different colors.
% TODO: move colorization to its own method and determine a way to colorize
% epoch toggles without redrawing the lines. Perhaps colorization needs to
% occur at the axespanel object, but somehow we need to identify lines that
% correspond to a single epoch but are from multiple devices.
if length(dat) > 1
  cmap = flipud(iris.app.Aes.appColor(length(dat),'contrast'));
  for I = 1:length(dat)
    if sel.inclusion(I)
      curColor = cmap(I,:);
    else
      curColor = iris.app.Aes.appColor(1,'red');
    end
    arrayfun(@(v)v.setColor(curColor), dat{I},'unif',0);
  end
end
% set highlight selection
if length(sel.selected) > 1
  hPos = find(sel.selected == sel.highlighted,1,'first');
  % set the selected element's linewidth
  arrayfun(@(v)v.setLW([]), dat{hPos}, 'unif', 0);
end

dat = cat(1,dat{:});
% only show selected devices
dat = dat(contains({dat.name},sel.showingDevices));

try
  obj.Axes.update(dat,obj.layout);
catch exc
  fprintf(2,'Error plotting data, clearing the axes...\n')
  fprintf(2,[exc.message,'\n\n']);
  obj.Axes.clearView();
end

%% D3.js AXES
% Comment this out if using Matlab Axes object
%{
datJson = '[';
for ii = 1:numel(d)
  datJson = [datJson,...
    iris.data.encode.plotData( ...
      d(ii).subsetDevice(sel.showingDevices) ...
    ).jsonify(false) ...
    ]; %#ok
  if ii ~= numel(d)
    datJson = [datJson,',']; %#ok<AGROW>
  end
end
datJson = [datJson,']'];

obj.window.executeJS( ...
  sprintf( ...
    'ax.update(%s,%s);', ...
    datJson, ...
    jsonencode(obj.layout) ...
  ) ...
  );
%}


%% DEV
%plotTime = toc(tt);
%fprintf('Time to plot data: %0.4f sec (%0.4f total).\n',plotTime,plotTime-prepTime);

%{
testTimes = zeros(2000,1);
for TTT = 1:2000
  tto = tic();
  datJson = '[';
  for ii = 1:numel(d)
    datJson = [datJson,...
      iris.data.encode.plotData(d(ii)).jsonify(false) ...
      ]; %#ok
  end
  datJson = [datJson,']'];
  testTimes(TTT) = toc(tto);
end

testTime2 = zeros(2000,1);
for TTT = 1:2000
  ttJ = tic();
  dJ = jsonencode(dat);
  testTime2(TTT) = toc(ttJ);
end
%}


%{
cm = iris.app.Aes.appColor(length(dat),'contrast');
delete(obj.Axes.Children);
for D = 1:length(dat)
  dd = dat(D);
  line(obj.Axes,'XData', dd.x, 'YData', dd.y, 'color', cm(D,:), 'DisplayName', dd.name);
end

%}
%{
dJson = jsonencode(dat);
if length(dat) == 1
  dJson = ['[',dJson,']'];
end
obj.window.executeJS( ...
  sprintf( ...
    'ax.update(%s,%s);', ...
    dJson, ...
    jsonencode(obj.layout) ...
  ) ...
  );
%}

%% NOTES FOR OTHER METHODS
%{
primary properties

currentEpochTicker: updates here should be parsed 
- parsing should check against ui.selection.total
- parsing should only create epoch index array
- parsed array should be sent to Iris where:
  - app.currentSelection = [array] to update handler inclusion
  - new selection will be sent to app.ui.updateView where relavent strings
  will be updated via postSet listener on ui.selection update.

CurrentEpochSlider: active only when selected is longer than 1
- updates here require replotting and redrawing CurrentEpochTicker value

OverlapTicker


Keyboard navigation:
left or right should increase selected range by small/big step until max
(upper) or min(lower) is reached. alt+arrows should increase/decrease
overlay at bottom ends.

e.g. 
range = [1,2,3,4,5];
uparrow -> range = [1,2,3,4,5,6];
alt+downarrow -> range = [2,3,4,5,6];
alt+uparrow -> range = [1,2,3,4,5,6];
alt+shift+downarrow (assume big = 5) -> range = [6];
alt+shift+uparrow (big=5) -> range = [1,2,3,4,5,6];


%}


end