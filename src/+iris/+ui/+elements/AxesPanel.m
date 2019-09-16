classdef AxesPanel < handle
  
  events
    DataSelected
    PlotUpdated
  end
  
  properties (SetObservable = true)
    Position
    XLabel
    YLabel
  end
  
  properties (Access = private)
    container
    Parent
    Axes
    I_Axes % the underlying Axes to the UIAxes
    margins
    xlab
    ylab
    domMap
    window
    currentLines
    mlVer
  end
  
  properties (Dependent = true,Access = private)
    domain
    nLines
  end
  
%%  Constructor
  methods
    
    function obj = AxesPanel(parent,varargin)
      import iris.app.Aes;
      
      if isempty(which('mlapptools'))
        error('AxesPanel requires mlapptools.');
      end
      
      % matlab version
      v = ver('matlab');
      obj.mlVer = str2double(v.Version);
      
      pr = inputParser();
      
      pr.addRequired('Parent',@ishandle);
      % margins in pixels: left, top, right, bottom
      pr.addParameter('margins', [20,10,10,15], ...
        @(x)validateattributes(x,{'numeric'},{'numel', 4}) ...
        );
      % position is used to determine the container position
      pr.addParameter('Position', [0,0,200,100], ...
        @(x)validateattributes(x,{'numeric'},{'numel', 4}) ...
        );
      pr.addParameter('XLabel', 'X', @ischar);
      pr.addParameter('YLabel', 'Y', @ischar);
      
      pr.KeepUnmatched = true;
      pr.parse(parent,varargin{:});
      
      % create UI
      parentTypes = {'matlab.ui.Figure', 'matlab.ui.container.Panel'};
      if ~ismember(class(pr.Results.Parent), parentTypes)
        error('Axes Parent must be a panel or a figure object.');
      end
      
      obj.Parent = pr.Results.Parent;
      obj.Position = pr.Results.Position;
      obj.margins = pr.Results.margins;
      obj.window = mlapptools.getWebWindow(obj.Parent);
      
      % Create the container
      obj.container = uipanel(obj.Parent, ...
          'Position', obj.Position, ...
          'Visible', 'off', ...
          'BorderType', 'none', ...
          'FontName', Aes.uiFontName ...
          );
      
      obj.Axes = uiaxes(obj.container);
      obj.Axes.BackgroundColor = [1 1 1,0];
      obj.Axes.Position = obj.getAxesPosition;
      
      sooState = warning('query','MATLAB:structOnObject');
      warning('off','MATLAB:structOnObject');
      pause(0.001);
      
      obj.I_Axes = struct(obj.Axes).Axes;
      
      % reset the warnign state to user pref
      warning(sooState);
      
      %%% Experimental modification of the HTMLCanvas object.
      % Combining these hacks appears to have no effect on plotting but highly
      % increases performance. One caveat is that with serversiderendering = 'on', we
      % get a slight degradation of highly sampled data. Not a problem considering
      % the huge amount of speed increase.
      % Let's hope MW don't see this and disable it, as they are wont to do.
      
      %{
      % this might break drawnow calls, not sure
      try %#ok<TRYNC>
        for lsn = 1:length(obj.Axes.AutoListeners__)
          % there are 2 listeners here that call on every postset. Not sure what the
          % callbacks do, as without them we see no change in visible or in clip. It
          % may have something to do with specific types of plots excluding points
          % and lines.
          obj.Axes.AutoListeners__{lsn}.Enabled = false;
        end
      end
      %}
      try %#ok<TRYNC>
        % Setting this to 'on' reduces the quality of the lines but increases speed
        % of drawing them and zooming/panning. So I can't seem to find what exactly
        % is changed, I would expect that the render is being sent rather than the
        % data, meaning, possibly, a bmp is displayed rather than a svg.
        % NodeChildren(1) == Axes.Canvas but 'Canvas' is not public
        obj.Axes.NodeChildren(1).ServerSideRendering = 'on';
      end
      
      try %#ok<TRYNC>
        % This may not have an effect. It seems a slight increase, maybe, when this
        % warning is turned off, perhaps only because the function is called or
        % terminates early?
        obj.Axes.NodeChildren(1).RenderWarningLevel = 'off';
      end
      
      % set other properties on the axis, or allow override of default
      fields = fieldnames(pr.Unmatched);
      for f = fields(:)'
        try
          obj.Axes.(f) = pr.Unmatched.(f);
        catch
          continue;
        end
      end
      
      % determine best location for labels
      ip = obj.Axes.InnerPosition;
      ofstX_x = ip(3)*0.08;
      ofstX_y = ip(4)*0.02;
      
      
      
      % xlabel
      obj.xlab = uilabel(obj.container,'Text', pr.Results.XLabel);
      obj.xlab.FontName = Aes.uiFontName;
      obj.xlab.FontSize = 20;
      obj.xlab.FontColor = [1,1,1].*0.85;
      obj.xlab.BackgroundColor = 'none';
      obj.xlab.HorizontalAlignment = 'left';
      obj.xlab.VerticalAlignment = 'bottom';
      obj.xlab.Position = ip + [ofstX_x,ofstX_y,-ofstX_x*1.1,-(ip(4)-25)];
      
      % ylabel
      % for y, we need the vertical center of our label position to be set
      % such that a css rotate(90) will give us the correct final Y
      % position for the label.
      % To account for the rotation, we need to set the width of the label
      % to height of the innerposition less the desired offsets.
      Y_width = fix(ip(4)*0.95);
      Y_height = 25;
      
      Y_x = ip(3)*0.035+Y_height-Y_width/2;
      Y_y = Y_width/2+ip(4)*0.05+Y_height;
      
      obj.ylab = uilabel(obj.container,'Text', pr.Results.YLabel);
      obj.ylab.FontName = Aes.uiFontName;
      obj.ylab.FontSize = 20;
      obj.ylab.FontColor = [1,1,1].*0.85;
      obj.ylab.BackgroundColor = 'none';
      obj.ylab.HorizontalAlignment = 'left';
      obj.ylab.VerticalAlignment = 'bottom';
      obj.ylab.Position = [Y_x,Y_y,Y_width,Y_height];
      
      % load in the katex for parsing latex into the labels
      try
        obj.setupDOM;
      catch err
        obj.delete;
        rethrow(err);
      end
      
      obj.container.Visible = 'on';
      import iris.infra.eventData;
      addlistener(obj,'Position','PostSet',@obj.positionChanged);
      addlistener(obj,'XLabel','PostSet', ...
        @(s,e)obj.labelChanged(s,eventData('X')) ...
        );
      addlistener(obj,'YLabel','PostSet', ...
        @(s,e)obj.labelChanged(s,eventData('Y')) ...
        );
      % init lines.
      obj.currentLines = {};
    end
    
  end

%% Local Methods
  methods (Access = private)
    
    function f = getFigure(obj)
      f = ancestor(obj.Parent,'matlab.ui.Figure');
    end
    
    function pos = getAxesPosition(obj)
      m = obj.margins;
      % position contains dims of the container, we will set margins
      % of the axes relative to this.
      dims = obj.Position(3:4);
      pos = [ ...
        m(1), ...
        m(4), ...
        dims(1) - sum(m([1,3])), ...
        dims(2) - sum(m([2,4])) ...
        ];
    end
    
    function setupDOM(obj)
      jsVars = {'mj', 'Ynode', 'Xnode','arr','children','firstScript'};
      for var = jsVars
        obj.window.executeJS( ...
          sprintf( ...
            'if(typeof %s === ''undefined'') {var %s;}', ...
            var{:}, var{:} ...
            ) ...
          );
      end
      
      obj.window.executeJS( [ ...
        'require(["https://cdnjs.cloudflare.com/ajax/libs/',...
        'mathjax/2.7.5/MathJax.js?config=TeX-MML-AM_CHTML"], ', ...
        '(mj) => { window.MathJax = mj; return mj; });' ...
        ]);
      
      mlapptools.addClasses(obj.ylab, 'YLABEL' );
      obj.window.executeJS( ...
        [ ...
          'if (typeof mystyle === ''undefined'') {', ...
          '  var mystyle = document.createElement(''style'');', ...
          '  document.head.appendChild(mystyle);', ...
          '  mystyle.innerHTML = "";', ...
          '}' ...
        ] ...
        );
      cssText = [ ...
        '\n',...
        '.YLABEL {\n', ...
        '  transform: rotate(90deg) !important;\n', ...
        '}\n' ...
        ];
      obj.window.executeJS(sprintf('mystyle.innerHTML += `%s`;',cssText));
      [~,id] = mlapptools.getWebElements(obj.ylab);
      nodeText = sprintf( ...
          [ ...
            'Ynode = dojo.query("[%s = ''%s'']")[0].parentNode;', ...
            'dojo.setStyle(Ynode,"overflow", "visible");', ...
            'children = Ynode.getElementsByTagName("*");', ...
            'arr = [ ...children];', ...
            'arr.forEach( (ch) => dojo.setStyle(ch,"overflow","visible") );' ...
          ], ...
          id.ID_attr, id.ID_val ...
        );
      obj.window.executeJS(nodeText);
      % get the domMap
      [~,xid] = mlapptools.getWebElements(obj.xlab);
      xtext = sprintf( ...
        'Xnode = dojo.query("[%s = ''%s'']")[0].parentNode;', ...
        xid.ID_attr, xid.ID_val ...
        );
      obj.window.executeJS(xtext);
      %
      obj.domMap = containers.Map( ...
        {'X','Y'}, ...
        {'Xnode', 'Ynode'} ...
        );
    end
    
    function bringLinesToFront(obj,lObjs)
      % get the axes children that are lines
      axChInds = false(numel(obj.Axes.Children),1);
      for ch = 1:numel(obj.Axes.Children)
        axChInds(ch) = isa(obj.Axes.Children(ch),'matlab.graphics.primitive.Line');
      end
      
      inds = ismember(obj.Axes.Children(axChInds),cat(1,lObjs{:}));
      % order doesnt matter, but let's keep them consistent.
      obj.currentLines = [obj.currentLines(inds),obj.currentLines(~inds)];
      obj.Axes.Children(axChInds) = cat(1,obj.currentLines{:});
      
    end
    
  end
  
%% Callbacks
  methods (Access = protected)
    
    function positionChanged(obj,~,~)
      % new position available in PostSet event
      obj.container = obj.Position;
      obj.Axes.Position = obj.getAxesPosition;
      
      ip = obj.Axes.InnerPosition;
      %xlab
      ofstX_x = ip(3)*0.1;
      ofstX_y = ip(4)*0.02;
      obj.xlab.Position = ip + [ofstX_x,ofstX_y,-ofstX_x*1.1,-(ip(4)-20)];
      %ylab
      Y_width = fix(ip(4)*0.95);
      Y_height = 20;
      Y_x = ip(3)*0.05+2*Y_height-Y_width/2;
      Y_y = Y_width/2+ip(4)*0.08+2*Y_height;
      obj.ylab.Position = [Y_x,Y_y,Y_width,Y_height];
    end
    
    function labelChanged(obj,src,event)
      switch event.Data
        case 'X'
          obj.xlab.Text = obj.(src.Name);
        case 'Y'
          obj.ylab.Text =  obj.(src.Name);
      end
      % drawnow has some bug that causes uifigures to hang forever use pause?
      %drawnow('limitrate');
      pause(0.01);
      if isempty(regexp(obj.(src.Name),'[^a-zA-Z0-9\[\]\s,]','once'))
        % Not math leave as non jax
        return;
      end
      
      tf = obj.window.executeJS('typeof MathJax === ''undefined''');
      if strcmpi(tf,'true'), return; end
      
      % assume jax equation is present, convert to math
      pause(0.1)
      obj.window.executeJS('if(typeof labNode === ''undefined''){ var labNode; }');
      obj.window.executeJS( ...
        sprintf( ...
          [ ...
            'labNode = %s.getElementsByTagName("*");', ...
            'labNode = labNode[labNode.length - 1];' ...
          ], ...
          obj.domMap(event.Data),obj.domMap(event.Data) ...
          ) ...
        );
      obj.window.executeJS( ...
        [ ...
          'labNode.innerHTML = "\\( " + labNode.innerText + "\\)";', ...
          'MathJax.Hub.Typeset();' ...
        ] ...
        );
      
    end
    
    function onDataSelected(obj,source,event)
      import iris.infra.eventData;
      
      [x,y] = getNearestDataPoint( ...
        event.IntersectionPoint(1:2), ...
        source.XData, ...
        source.YData ...
        );
      
      eventStruct = struct();
      eventStruct.lastDataCoordinates = [x,y];
      eventStruct.datumIndex = source.UserData.index;
      
      notify(obj,'DataSelected',eventData(eventStruct));
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
    
  end

%% GET SET
  methods
    
    function d = get.domain(obj)
      lineArray = obj.Axes.Children;
      if isempty(lineArray) 
        d = struct('x',[0,1],'y',[0,1]); 
        return; 
      end
      doms = arrayfun( ...
        @(ln)[domain(ln.XData);domain(ln.YData)], ...
        lineArray, ...
        'UniformOutput', false ...
        ); %#ok
      doms = domain(cat(2,doms{:})')';%#ok
      d = struct('x',doms(1,:), 'y', doms(2,:));
    end
    
    function n = get.nLines(obj)
      n = length(obj.currentLines);
    end
    
  end
  
%% Plotting/Updating
  methods (Access = public)
    
    function update(obj,hD,hL)
      %obj.resetView;
      % temporarily set axis modes to auto
      %obj.Axes.YLimMode = 'auto';
      %obj.Axes.XLimMode = 'auto';
      % if lines exist, 
      nExist = numel(obj.currentLines);
      for ix = 1:numel(hD)
        % plot the lines and markers
        % For now, we cannot set alph transparency during call to line()
        % So we must create the object and set the transparency/color
        % after.
        if ix <= nExist
          appendLine = false;
          lObj = obj.currentLines{ix};
          set(lObj, {'XData', 'YData'}, {hD(ix).x,hD(ix).y});
          set(lObj, hD(ix).line.collect);
          set(lObj, hD(ix).marker.collect);
        else
          appendLine = true;
          lObj = line(obj.Axes, ...
            'XData', hD(ix).x, ...
            'YData', hD(ix).y, ...
            hD(ix).line.collect, ...
            hD(ix).marker.collect ...
            );
        end
        % apply transparency and color for lines/markers
        lObj.Color = hD(ix).line.color;
        if contains(hD(ix).mode,'markers')
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
          obj.currentLines{end+1} = lObj;
        end
      end
      % after updating data, delete any lines we didnt use (ix will be the
      % number of the last edited/appended line
      if ix < nExist
        %delete grobs
        cellfun(@delete,obj.currentLines((1:(nExist-ix)) + ix), 'unif', 0);
        %remove from list
        obj.currentLines((1:(nExist-ix)) + ix) = [];
      end
      obj.resetView;
      % update labels
      obj.XLabel = hL.xaxis.title;
      obj.YLabel = hL.yaxis.title;
      
      % update grids
      onoff = {'off','on'};
      obj.Axes.XGrid = onoff{hL.xaxis.grid+1};
      obj.Axes.YGrid = onoff{hL.yaxis.grid+1};
      
      % update scales
      obj.Axes.XScale = hL.xaxis.scale;
      obj.Axes.YScale = hL.yaxis.scale;
      
      % update baselines (zero lines)
      % x
      if hL.xaxis.zeroline
        obj.I_Axes.XBaseline.Color = hL.xaxis.zerolinecolor;
        obj.I_Axes.XBaseline.LineWidth = 2.5;
        obj.I_Axes.XBaseline.Visible = 'on';
      else
        obj.I_Axes.XBaseline.Visible = 'off';
      end
      % y
      if hL.yaxis.zeroline
        obj.I_Axes.YBaseline.Color = hL.yaxis.zerolinecolor;
        obj.I_Axes.YBaseline.LineWidth = 2.5;
        obj.I_Axes.YBaseline.Visible = 'on';
      else
        obj.I_Axes.YBaseline.Visible = 'off';
      end
      
      
      %notify plot updated
      notify(obj,'PlotUpdated');
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
    
    function delete(obj)
      delete(obj.Axes);
      delete(obj.xlab);
      delete(obj.ylab);
      delete(obj.container);
    end
    
    function resetView(obj)
      % need to manually set ylim in case zero line is on and zero is far
      % away.
      % Let's create a 10% padding (5% on each top/bottom)
      
      yRange = obj.domain.y;
      if diff(yRange) ~= 0
        obj.Axes.YLimMode = 'manual';
        obj.Axes.YLim = yRange + [-0.05,0.05].*diff(yRange);
      end
      
      % I want the xaxis to clip directly on the data bounds.
      xRange = obj.domain.x;
      if diff(xRange) ~= 0
        obj.Axes.XLimMode = 'manual';
        obj.Axes.XLim = obj.domain.x;
      end
      %drawnow('limitrate');
    end
    
    function setHighlighted(obj,pos,defaultWidth,newColor)
      if nargin < 4, newColor = []; end
      hlWidth = defaultWidth+2;
      hlInds = false(1,obj.nLines);
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
    
    function highlightByName(obj,names,defaultWidth,newColor)
      if nargin < 4, newColor = []; end
      if ~iscell(names), names = cellstr(names); end
      hlWidth = defaultWidth+2;
      hlInds = false(1,obj.nLines);
      for I = 1:numel(obj.currentLines)
        lObj = obj.currentLines{I};
        if strcmpi(lObj.LineStyle, 'none'), continue; end
        if contains(lObj.DisplayName,names)
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
    
  end

end

