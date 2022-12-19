classdef AxesPanel < handle

  events
    DataSelected
    PlotUpdated
  end

  properties (Constant = true)
    SCRIPT_ID = "axisLabel"
  end

  properties (SetObservable = true)
    Location
    Position % used to keep track of the container size
    DisplayLabel
    XLabel
    YLabel
  end

  properties %(Access = private)
    container
    Parent
    Grid
    Axes
    margins
    xlab
    ylab
    dlab
    domMap
    window
    currentLines
    isDomSet = false;
    isShowingAxes
  end

  properties (Dependent = true, Access = private)
    domain
    nLines
    HTMLSource
    XData
    YData
  end

  %%  Constructor
  methods

    function obj = AxesPanel(parent, varargin)
      import iris.app.Aes;
      import iris.infra.eventData;

      pr = inputParser();

      pr.addRequired('Parent', @ishandle);
      % location within the parent grid, default [0,0] will use the next
      % available grid
      pr.addParameter('location', [0, 0], ...
      @(x)validateattributes(x, {'numeric'}, {'numel', 2}) ...
      );
      % margins in pixels: left, top, right, bottom
      pr.addParameter('margins', [20, 10, 10, 15], ...
      @(x)validateattributes(x, {'numeric'}, {'numel', 4}) ...
      );
      pr.addParameter('XLabel', 'X', @ischar);
      pr.addParameter('YLabel', 'Y', @ischar);

      pr.addParameter('displayLabel', "Load data to get started.", ...
        @(v)validateattributes(v, {'char', 'string'}, {'scalartext'}) ...
      );

      pr.addParameter('displayMode', 'text', ...
        @(v) ismember(lower(v), {'text', 'axes'}) ...
      );

      pr.KeepUnmatched = true;
      pr.parse(parent, varargin{:});

      % create UI
      parentTypes = {'matlab.ui.Figure', 'matlab.ui.container.Panel', 'matlab.ui.container.GridLayout'};
      parentTypeIndex = ismember(parentTypes, class(pr.Results.Parent));

      if ~any(parentTypeIndex)
        iris.app.Info.throwError( ...
          'Axes Parent must be a uiFigure, uiPanel or GridLayout object.' ...
        );
      end

      % Allow a gridlayout, panel of figure
      % if we've received a handle to a figure or panel, let's create a 1x1 grid
      % without padding or spacing.
      switch parentTypes{parentTypeIndex}
        case {'matlab.ui.Figure', 'matlab.ui.container.Panel'}
          obj.Parent = pr.Results.Parent;
        case 'matlab.ui.container.GridLayout'
          % create a panel and place the grid inside
          obj.Parent = uipanel(pr.Results.Parent);
          % default for parent panel
          obj.Parent.BorderType = 'none';
          obj.Parent.FontName = Aes.uiFontName;
          obj.Parent.BackgroundColor = [1, 1, 1];
          drawnow();
      end

      % set the parent location if specified
      if all(~pr.Results.location)
        obj.Location = [obj.Parent.Layout.Row, obj.Parent.Layout.Column];
      else
        obj.Location = pr.Results.location;
        obj.Parent.Layout.Row = obj.Location(1);
        obj.Parent.Layout.Column = obj.Location(2);
      end

      % Parse object information and build axes
      obj.margins = pr.Results.margins;

      % Create the Grid for holding components
      obj.Grid = uigridlayout(obj.Parent);
      obj.Grid.ColumnWidth = {obj.margins(1) - 8, '1x'};
      obj.Grid.RowHeight = {'1x', '1x', obj.margins(4) - 8};
      obj.Grid.ColumnSpacing = 0;
      obj.Grid.RowSpacing = 0;
      obj.Grid.Padding = [8 8 8 obj.margins(2)];
      obj.Grid.BackgroundColor = [1, 1, 1, 0];

      % Create y label container
      obj.ylab = uihtml(obj.Grid);
      obj.ylab.Layout.Row = [1, 2];
      obj.ylab.Layout.Column = 1;

      % Create the container
      obj.container = uipanel(obj.Grid, ...
      'Visible', 'off', ...
        'BorderType', 'none', ...
        'FontName', Aes.uiFontName, ...
        'AutoResizeChildren', 'off' ...
      );
      obj.container.BackgroundColor = [1, 1, 1];
      obj.container.Units = 'pixels';
      obj.container.Layout.Row = 1;
      obj.container.Layout.Column = 2;

      % Display Label
      obj.DisplayLabel = pr.Results.displayLabel;
      obj.dlab = uilabel(obj.Grid, 'Text', pr.Results.displayLabel);
      obj.dlab.Layout.Row = 2;
      obj.dlab.Layout.Column = 2;
      obj.dlab.FontName = Aes.uiFontName;
      obj.dlab.FontSize = 32;
      obj.dlab.FontColor = [1, 1, 1] .* 0.25;
      obj.dlab.BackgroundColor = 'none';
      obj.dlab.HorizontalAlignment = 'center';
      obj.dlab.VerticalAlignment = 'center';

      % Create x label container
      obj.xlab = uihtml(obj.Grid);
      obj.xlab.Layout.Row = 3;
      obj.xlab.Layout.Column = [1, 2];

      % Create the Axes on the container
      obj.Axes = axes(obj.container);
      obj.Axes.Units = 'pixels';
      obj.Axes.Color = [1 1 1, 0];
      obj.Axes.FontWeight = 'normal';
      obj.Axes.Interactions = [rulerPanInteraction zoomInteraction];
      drawnow(); %force
      %{
      % cleanup interactions
      disableDefaultInteractivity(obj.Axes);
      pause(0.01);
      enableDefaultInteractivity(obj.Axes);
      %}
      % set other properties on the axis, or allow override of default
      fields = fieldnames(pr.Unmatched);

      for f = string(fields(:))'

        try
          set(obj.Axes, f, pr.Unmatched.(f));
        catch
          continue
        end

      end

      obj.toggleAxes(strcmp(pr.Results.displayMode, 'axes'));

      try
        obj.setupDOM();
      catch err
        delete(obj);
        iris.app.Info.throwError(err.message);
      end

      % Set Labels
      obj.YLabel = pr.Results.YLabel;
      obj.XLabel = pr.Results.XLabel;

      obj.container.SizeChangedFcn = @obj.onContainerResized;

      addlistener(obj, 'DisplayLabel', 'PostSet', @obj.displayLabelChanged);
      addlistener(obj, 'Position', 'PostSet', @obj.positionChanged);
      addlistener(obj, 'XLabel', 'PostSet', ...
        @(s, e)obj.labelChanged(s, eventData('X')) ...
      );
      addlistener(obj, 'YLabel', 'PostSet', ...
        @(s, e)obj.labelChanged(s, eventData('Y')) ...
      );
      % init lines.
      obj.currentLines = {};
      obj.container.Visible = 'on';
    end

  end

  %% Local Methods
  methods (Access = private)

    function f = getFigure(obj)
      f = ancestor(obj.Parent, 'matlab.ui.Figure');
    end

    function pos = getAxesPosition(obj)
      m = obj.margins;
      % position contains dims of the container, we will set margins
      % of the axes relative to this.
      dims = obj.Position(3:4);
      pos = [1, 1, dims(1) - m(3), dims(2)];
      %{
      % old method
      pos = [ ...
            m(1), ...
            m(4), ...
            dims(1) - sum(m([1, 3])), ...
            dims(2) - sum(m([2, 4])) ...
          ];
      %}
    end

    function setupDOM(obj)
      obj.ylab.Data = obj.YData;
      obj.xlab.Data = obj.XData;
      obj.ylab.HTMLSource = obj.HTMLSource;
      obj.xlab.HTMLSource = obj.HTMLSource;
      obj.isDomSet = true;
    end

    function bringLinesToFront(obj, lObjs)
      % get the axes children that are lines
      axChInds = false(numel(obj.Axes.Children), 1);

      for ch = 1:numel(obj.Axes.Children)
        axChInds(ch) = isa(obj.Axes.Children(ch), 'matlab.graphics.primitive.Line');
      end

      childLines = obj.Axes.Children(axChInds);
      inds = ismember(childLines, cat(1, lObjs{:}));
      childLines = [childLines(inds); childLines(~inds)];

      % order doesnt matter, but let's keep them consistent.
      obj.currentLines = num2cell(childLines)';
      obj.Axes.Children(axChInds) = childLines;
      drawnow('update');
    end

    function d = constructData(obj, xy)

      arguments
        obj
        xy (1, 1) string {mustBeMember(xy, ["X", "Y"])}
      end

      if xy == "X"
        isvert = false;
        lab = obj.XLabel;
      else
        isvert = true;
        lab = obj.YLabel;
      end

      d = struct( ...
        "String", lab, ...
        "FontSize", obj.Axes.FontSize, ...
        "Vertical", isvert, ...
        "isValid", true ...
      );
    end

  end

  %% Callbacks
  methods (Access = protected)

    function onContainerResized(obj, source, ~)

      if obj.isShowingAxes
        drawnow();
        obj.Position = source.Position;
      end

    end

    function positionChanged(obj, ~, ~)
      % new position available in PostSet event
      obj.Axes.OuterPosition = obj.getAxesPosition;
    end

    function labelChanged(obj, ~, event)

      switch event.Data
        case 'X'
          obj.xlab.Data = obj.XData;
        case 'Y'
          obj.ylab.Data = obj.YData;
      end

    end

    function onDataSelected(obj, source, event)
      import iris.infra.eventData;

      [x, y] = utilities.getNearestDataPoint( ...
        event.IntersectionPoint(1:2), ...
        source.XData, ...
        source.YData ...
      );

      eventStruct = struct();
      eventStruct.lastDataCoordinates = [x, y];
      eventStruct.datumIndex = source.UserData.index;
      eventStruct.datumID = source.DisplayName;

      notify(obj, 'DataSelected', eventData(eventStruct));
      % for future: selection of data finds nearest data point and broadcasts. This
      % can be used to mimic ginput when we want to select the best scaling value.
      % to do that we would likely have a uiwait called on the figure handle so we
      % need to get the handle and resume it after we make the selection
      %{
      % locate the figure handle
      figureHandle = ancestor(obj.Axes,'figure','toplevel');
      % Call uiresume on figure in the event that Iris is waiting for a press
      uiresume(figureHandle);
      %}

    end

    function displayLabelChanged(obj, ~, ~)
      obj.dlab.Text = obj.DisplayLabel;
    end

  end

  %% GET SET
  methods

    function d = get.domain(obj)
      import utilities.domain

      lineArray = obj.currentLines;

      if isempty(lineArray)
        d = struct('x', [0, 1], 'y', [0, 1]);
        return;
      end

      doms = cellfun( ...
        @(ln)[domain(ln.XData(:)), domain(ln.YData(:))], ...
        lineArray, ...
        'UniformOutput', false ...
      ); %#ok<CPROP>
      doms = domain(cat(1, doms{:})); %#ok<CPROP>
      d = struct('x', doms(:,1).', 'y', doms(:, 2).');
    end

    function n = get.nLines(obj)
      n = length(obj.currentLines);
    end

    function src = get.HTMLSource(obj)
      src = fullfile( ...
        iris.app.Info.getResourcePath(), ...
        "scripts", ...
        obj.SCRIPT_ID, ...
        sprintf("%s.html", obj.SCRIPT_ID) ...
      );
    end

    function d = get.XData(obj)
      d = obj.constructData("X");
    end

    function d = get.YData(obj)
      d = obj.constructData("Y");
    end

    function delete(obj)
      delete(obj.Grid);
    end

  end

  %% Plotting/Updating
  methods (Access = public)

    function update(obj, hD, hL)
      nExist = numel(obj.currentLines);

      for ix = 1:numel(hD)
        % plot the lines and markers
        % For now, we cannot set alph transparency during call to line()
        % So we must create the object and set the transparency/color
        % after.
        if ix <= nExist
          appendLine = false;
          lObj = obj.currentLines{ix};
          set(lObj, {'XData', 'YData'}, {hD(ix).x, hD(ix).y});
          set(lObj, hD(ix).line.collect);
          set(lObj, hD(ix).marker.collect);
        else
          appendLine = true;
          lObj = line(obj.Axes, ...
            'XData', hD(ix).x, ...
            'YData', hD(ix).y, ...
            hD(ix).line.collect, ...
            hD(ix).marker.collect, ...
            'pickableparts', 'visible', ...
            'hittest', 'on' ...
          );
        end

        % apply transparency and color for lines/markers
        lObj.Color = hD(ix).line.color;

        if contains(hD(ix).mode, 'markers')
          lObj.MarkerFaceColor = hD(ix).marker.color(1:3);
          lObj.MarkerEdgeColor = hD(ix).marker.color(1:3);
        end

        % Add the "name (device)" to displayNames
        lObj.DisplayName = hD(ix).name; % for exported figures
        % Add the User Data for interactive purposes
        lObj.UserData = hD(ix).UserData;
        % Use a lines hit interactivity to select the line
        if hD(ix).isInteractive
          lObj.ButtonDownFcn = @obj.onDataSelected;
        end

        % if appending, simply grow the currentLines property. Otherwise
        % the handles are the same
        if appendLine
          obj.currentLines{end + 1} = lObj;
        end

      end

      % after updating data, delete any lines we didnt use (ix will be the
      % number of the last edited/appended line
      if ix < nExist
        %delete grobs
        cellfun(@delete, obj.currentLines((1:(nExist - ix)) + ix), 'unif', 0);
        %remove from list
        obj.currentLines((1:(nExist - ix)) + ix) = [];
      end

      obj.resetView;
      % update labels
      obj.XLabel = hL.xaxis.title;
      obj.YLabel = hL.yaxis.title;

      % update grids
      onoff = {'off', 'on'};
      obj.Axes.XGrid = onoff{hL.xaxis.grid + 1};
      obj.Axes.YGrid = onoff{hL.yaxis.grid + 1};

      % update scales
      obj.Axes.XScale = hL.xaxis.scale;
      obj.Axes.YScale = hL.yaxis.scale;

      % update baselines (zero lines)
      % x
      if hL.xaxis.zeroline
        obj.Axes.XBaseline.Color = hL.xaxis.zerolinecolor;
        obj.Axes.XBaseline.LineWidth = 2.5;
        obj.Axes.XBaseline.Visible = 'on';
      else
        obj.Axes.XBaseline.Visible = 'off';
      end

      % y
      if hL.yaxis.zeroline
        obj.Axes.YBaseline.Color = hL.yaxis.zerolinecolor;
        obj.Axes.YBaseline.LineWidth = 2.5;
        obj.Axes.YBaseline.Visible = 'on';
      else
        obj.Axes.YBaseline.Visible = 'off';
      end

      obj.toggleAxes(true);

      %notify plot updated
      notify(obj, 'PlotUpdated');
    end

    function clearView(obj)

      try %#ok<TRYNC>
        delete(obj.Axes.Children);
        obj.currentLines = {};
      end

      obj.XLabel = 'X';
      obj.YLabel = 'Y';
      obj.resetView;
    end

    function resetView(obj)
      % need to manually set ylim in case zero line is on and zero is far
      % away.
      % Let's create a 10% padding (5% on each top/bottom)

      yRange = obj.domain.y;

      if diff(yRange) ~= 0
        obj.Axes.YLimMode = 'manual';
        obj.Axes.YLim = yRange + [-0.05, 0.05] .* diff(yRange);
      end

      % I want the xaxis to clip directly on the data bounds.
      xRange = obj.domain.x;

      if diff(xRange) ~= 0
        obj.Axes.XLimMode = 'manual';
        obj.Axes.XLim = obj.domain.x;
      end

    end

    function setHighlighted(obj, pos, defaultWidth, newColor)
      if nargin < 4, newColor = []; end
      hlWidth = defaultWidth + max([abs((defaultWidth - 1) * 0.65), 2]);
      hlInds = false(1, obj.nLines);

      for I = 1:obj.nLines
        lObj = obj.currentLines{I};
        if strcmpi(lObj.LineStyle, 'none'), continue; end

        if any(lObj.UserData.index == pos)
          lObj.LineWidth = hlWidth;
          hlInds(I) = true;
        else
          lObj.LineWidth = defaultWidth;
        end

        if ~isempty(newColor)
          lObj.Color = newColor;
        end

      end

      obj.bringLinesToFront(obj.currentLines(hlInds));
    end

    function highlightByName(obj, names, defaultWidth, newColor)
      if nargin < 4, newColor = []; end
      if ~iscell(names), names = cellstr(names); end
      hlWidth = defaultWidth + max([abs((defaultWidth - 1) * 0.65), 2]);
      hlInds = false(1, obj.nLines);

      for I = 1:numel(obj.currentLines)
        lObj = obj.currentLines{I};
        if strcmpi(lObj.LineStyle, 'none'), continue; end

        if contains(lObj.DisplayName, names)
          lObj.LineWidth = hlWidth;
          hlInds(I) = true;
        else
          lObj.LineWidth = defaultWidth;
        end

        if ~isempty(newColor)
          lObj.Color = newColor;
        end

      end

      obj.bringLinesToFront(obj.currentLines(hlInds));
    end

    function showLabel(obj, txt)

      if nargin < 2
        txt = "";
      else
        txt = string(txt);
      end

      if txt ~= ""
        obj.DisplayLabel = txt;
      end

      obj.toggleAxes(false);
    end

    function toggleAxes(obj, bool)

      if nargin < 2
        bool = ~obj.isShowingAxes;
      end

      obj.isShowingAxes = bool;

      if bool
        % turn axes on
        ax = 'on';
        rh = {'1x', 0};
      else
        ax = 'off';
        rh = {0, '1x'};
      end

      obj.Grid.RowHeight(1:2) = rh;
      obj.xlab.Visible = ax;
      obj.ylab.Visible = ax;
    end

  end

end
