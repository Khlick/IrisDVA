classdef (Abstract) UIContainer < iris.infra.UIWindow
  
  properties
    position
    isBound = false
  end
  
  properties (Dependent)
    isClosed
    isready
  end
  
  properties (SetAccess = protected)
    container
    window
    synchronizer
  end
  
  methods
    %% Constructor
    function obj = UIContainer(varargin)
      obj = obj@iris.infra.UIWindow(varargin{:});
    end
    
    %function obj = UIContainer()
    function constructContainer(obj,varargin)
      % Contains dependencies for iris.infra.eventData and iris.app.Aes
      import iris.infra.*;
      import iris.app.*;
      
      SJO = warning('off','MATLAB:ui:javaframe:PropertyToBeRemoved');
      SOO = warning('off','MATLAB:structOnObject');
      
      %build figure base
      params = { ...
        'DefaultAxesInterruptible', 'off', ...
        'DefaultAxesFontName', Aes.uiFontName, ...
        'DefaultAxesFontsize', Aes.uiFontSize(),...
        'DefaultAxesColor', [1,1,1,0], ...
        'DefaultAxesBox', 'off', ...
        'DefaultAxesXLimMode', 'manual', ...
        'DefaultAxesYLimMode', 'manual', ...
        'DefaultTextFontName', Aes.uiFontName, ...
        'DefaultTextBackgroundColor', [1,1,1,0], ...
        'DefaultUitableFontname', Aes.uiFontName, ...
        'DefaultUipanelUnits', 'pixels', ...
        'DefaultUipanelPosition', [20,20, 260, 221],...
        'DefaultUipanelBackgroundColor', [1,1,1], ...
        'DefaultUipanelBorderType', 'line', ...
        'DefaultUipanelFontname', Aes.uiFontName,...
        'DefaultUipanelFontunits', 'pixels', ...
        'DefaultUipanelFontsize', Aes.uiFontSize('label'),...
        'DefaultUipanelAutoresizechildren', 'off', ...
        'DefaultUipanelInterruptible', 'off', ...
        'DefaultUitabgroupUnits', 'pixels', ...
        'DefaultUitabgroupPosition', [20,20, 250, 210],...
        'DefaultUitabgroupAutoresizechildren', 'off', ...
        'DefaultUitabUnits', 'pixels', ...
        'DefaultUitabAutoresizechildren', 'off', ...
        'DefaultUibuttongroupUnits', 'pixels', ...
        'DefaultUibuttongroupPosition', [20,20, 260, 210],...
        'DefaultUibuttongroupBordertype', 'line', ...
        'DefaultUibuttongroupFontname', Aes.uiFontName,...
        'DefaultUibuttongroupFontunits', 'pixels', ...
        'DefaultUibuttongroupFontsize', Aes.uiFontSize('custom',2),...
        'DefaultUibuttongroupAutoresizechildren', 'off', ...
        'DefaultUibuttongroupInterruptible', 'off', ...
        'DefaultUitabBackgroundColor', [1,1,1], ...
        'DefaultUitableBackgroundColor', [1,1,1], ...
        'DefaultUitableFontname', Aes.uiFontName, ...
        'DefaultUitableFontunits', 'pixels',...
        'DefaultUitableFontsize', Aes.uiFontSize, ...
        'DefaultUitableBusyAction', 'cancel', ...
        'DefaultUitableInterruptible', 'off', ...
        'DefaultLineInterruptible', 'off', ...
        'DefaultUicontainerBackgroundColor', [1,1,1], ...
        'DefaultUicontrolFontName', Aes.uiFontName, ...
        'DefaultUicontrolInterruptible', 'off', ...
        'DefaultUicontrolBackgroundColor', [1,1,1,0], ...
        'DefaultUigridcontainerBackgroundColor', [1,1,1], ...
        'DefaultHgjavacomponentBackgroundColor', [1,1,1], ...
        'defaultAnimatedlineInterruptible', 'off', ...
        'defaultAreaInterruptible', 'off', ...
        'defaultArrowshapeInterruptible', 'off', ...
        'defaultAxesInterruptible', 'off', ...
        'defaultAxestoolbarInterruptible', 'off', ...
        'defaultBarInterruptible', 'off', ...
        'defaultBinscatterInterruptible', 'off', ...
        'defaultCategoricalhistogramInterruptible', 'off', ...
        'defaultColorbarInterruptible', 'off', ...
        'defaultContourInterruptible', 'off', ...
        'defaultDoubleendarrowshapeInterruptible', 'off', ...
        'defaultEllipseshapeInterruptible', 'off', ...
        'defaultErrorbarInterruptible', 'off', ...
        'defaultFigureInterruptible', 'off', ...
        'defaultFunctioncontourInterruptible', 'off', ...
        'defaultFunctionlineInterruptible', 'off', ...
        'defaultFunctionsurfaceInterruptible', 'off', ...
        'defaultGeoaxesInterruptible', 'off', ...
        'defaultGraphplotInterruptible', 'off', ...
        'defaultHggroupInterruptible', 'off', ...
        'defaultHgjavacomponentInterruptible', 'off', ...
        'defaultHgtransformInterruptible', 'off', ...
        'defaultHistogram2Interruptible', 'off', ...
        'defaultHistogramInterruptible', 'off', ...
        'defaultImageInterruptible', 'off', ...
        'defaultImplicitfunctionlineInterruptible', 'off', ...
        'defaultImplicitfunctionsurfaceInterruptible', 'off', ...
        'defaultLegendInterruptible', 'off', ...
        'defaultLightInterruptible', 'off', ...
        'defaultLineInterruptible', 'off', ...
        'defaultLineshapeInterruptible', 'off', ...
        'defaultParameterizedfunctionlineInterruptible', 'off', ...
        'defaultParameterizedfunctionsurfaceInterruptible', 'off', ...
        'defaultPatchInterruptible', 'off', ...
        'defaultPolaraxesInterruptible', 'off', ...
        'defaultQuiverInterruptible', 'off', ...
        'defaultRectangleInterruptible', 'off', ...
        'defaultRectangleshapeInterruptible', 'off', ...
        'defaultScatterInterruptible', 'off', ...
        'defaultStairInterruptible', 'off', ...
        'defaultStemInterruptible', 'off', ...
        'defaultSurfaceInterruptible', 'off', ...
        'defaultTextInterruptible', 'off', ...
        'defaultTextarrowshapeInterruptible', 'off', ...
        'defaultTextboxshapeInterruptible', 'off', ...
        'defaultUibuttongroupInterruptible', 'off', ...
        'defaultUicontainerInterruptible', 'off', ...
        'defaultUicontextmenuInterruptible', 'off', ...
        'defaultUicontrolInterruptible', 'off', ...
        'defaultUiflowcontainerInterruptible', 'off', ...
        'defaultUigridcontainerInterruptible', 'off', ...
        'defaultUimenuInterruptible', 'off', ...
        'defaultUipanelInterruptible', 'off', ...
        'defaultUipushtoolInterruptible', 'off', ...
        'defaultUisplittoolInterruptible', 'off', ...
        'defaultUitabInterruptible', 'off', ...
        'defaultUitabgroupInterruptible', 'off', ...
        'defaultUitableInterruptible', 'off', ...
        'defaultUitogglesplittoolInterruptible', 'off', ...
        'defaultUitoggletoolInterruptible', 'off', ...
        'defaultUitoolbarInterruptible', 'off' ...
        };
      
      params = reshape(params,2,[]);
      
      obj.container = uifigure( ...
        'Visible', 'off', ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none', ...
        'Toolbar', 'none', ...
        'Color', [1,1,1], ...
        'AutoResizeChildren', 'off', ...
        'Resize', 'off', ...
        'HandleVisibility', 'off', ...
        'Tag', [iris.app.Info.name,'UI'], ...
        'CloseRequestFcn', ...
          @(src,evnt)notify(obj, 'Close') ...
        );
      
      try
        obj.container.WindowKeyPressFcn = ...
            @(src,evnt)notify(obj, 'KeyPress', eventData(evnt));
      catch x
        fprintf('Keyboard functionality is not available.\n');
      end
      
      for p = 1:size(params,2)
        try %#ok<TRYNC>
          set(obj.container,params{1,p},params{2,p});
        end
      end
      
      
      try
        obj.createUI(varargin{:});
        pause(0.2);
      catch
        try
          obj.createUI();
          pause(0.2);
        catch x
          delete(obj.container);
          warning(SOO);
          warning(SJO);
          rethrow(x);
        end
      end
      
      % This overcomes some "infinite" loop in MATLAB, which appears to be a workaround for "g1658467".
      % The consequences of doing this are unclear.
      % See also MATLAB\R20###\toolbox\matlab\uitools\uicomponents\components\...
      %            +matlab\+ui\+internal\+controller\FigureController.m\flushCoalescer()
      % See  https://gist.github.com/Dev-iL/398a38ae03c6ef9ebf935d46884ce74d
      obj.synchronizer = struct(struct(struct(obj.container).Controller).PeerModelInfo).Synchronizer;
      obj.synchronizer.setCoalescerMinDelay(1);
      obj.synchronizer.setCoalescerMaxDelay(5);
      pause(0.001);
      
      
      % now gather the web window for the container
      while true
        try
        obj.window = mlapptools.getWebWindow(obj.container);
        catch x
          %log this
          continue
        end
        break
      end
      % make modifications
      obj.startup(varargin{:});
      
      %return warning status
      warning(SOO);
      warning(SJO);
    end
    
    
    %% set
    
    function set.position(obj, p)
      validateattributes(p, {'numeric'}, {'2d', 'numel', 4});
      obj.container.Position = p; %#ok<MCSUP>
      obj.put('position', p);
      obj.position = p;
    end
    
    function setUI(obj, uiObjName, propName, newVal)
      % sets a single gui property value for any number of ui objects.
      if ischar(uiObjName), uiObjName = cellstr(uiObjName); end
      if ~ischar(propName), propName = propName{1}; end
      
      uiObjName = uiObjName(contains(uiObjName,properties(obj)));
      
      if isempty(uiObjName), error('Requires valid UI property.'); end
      for i = 1:length(uiObjName)
        try
          obj.(uiObjName{i}).(propName) = newVal;
        catch x
          warning('%s property ''%s'' not set with message: "%s"', ...
            uiObjName{i}, propName, x.message);
        end
      end
    end
    
    
    %% get

    function f = get.position(obj)
      f = obj.get('position', []);
      if isempty(f), return; end
      rootMonitors = get(groot,'MonitorPositions');
      if f(1) > (max(rootMonitors(:,3)) - f(3))
        f(1) = max(rootMonitors(:,3)) - f(3);
      end
      if f(2) > (max(rootMonitors(:,4))-f(4))
        f(2) = max(rootMonitors(:,4)) - f(4);
      end
    end
    
    function tf = get.isClosed(obj)
      try 
        tf = ~obj.isready;
      catch x %#ok
        % log x
        tf = true;
      end
    end
    
    function tf = get.isready(obj)
      try
        tf = obj.window.isWindowValid || obj.container.isvalid;
      catch
        tf = false;
      end
    end
    
    function v = getUI(obj, uiObj, propName)
      uiObj = validatestring(uiObj,properties(obj));
      v = obj.(uiObj).(propName);
    end
      
    function tf = isVisible(obj)
      tf = strcmpi(obj.container.Visible, 'on');
    end
 
    
    %% interactive functions
    
    function startup(obj,varargin)
      obj.getContainerPrefs;
      try
        obj.startupFcn(varargin{:}); %abstract
      catch x
        delete(obj);
        rethrow(x)
      end
      import iris.app.*;
      obj.window.Icon = fullfile(Info.getResourcePath,'icn','favicon.ico');
      pause(0.01);
      % remove interrupts in attempt to prevent the drawnow crash
      hAll = findall(obj.container);
      for h = 1:numel(hAll)
        try %#ok<TRYNC>
          hAll(h).Interruptible = 'off';
        end
        try %#ok<TRYNC>
          hAll(h).BusyAction = 'cancel';
        end
      end
    end
    
    function shutdown(obj)
      obj.setContainerPrefs();
      obj.save();
      obj.hide();
      obj.close();
    end
    
    function rebuild(obj)
      if ~obj.isClosed, return; end
      obj.constructContainer();
    end
    
    function show(obj)
      if obj.isClosed, error('%s is closed.',class(obj)); end
      if strcmpi(obj.container.Visible, 'off')
        obj.container.Visible = 'on';
      end
      obj.window.show;
      drawnow();
      obj.window.bringToFront;
    end
    
    function hide(obj)
      if strcmpi(obj.container.Visible, 'on')
        obj.container.Visible = 'off';
      end
      obj.window.hide;
      %obj.window.executeJS('window.blur();');
      obj.resume();
    end
    
    function save(obj)
      save@iris.infra.StoredPrefs(obj);
      try
        obj.options.save();
      catch x %#ok
        %no options
        % setup logging to store this info.
      end
    end
    
    function update(obj)
      try %#ok<TRYNC>
        obj.setContainerPrefs();
      end
    end
    
    function executeJSFile(obj,fileName, timeOut)
      if nargin < 3
        timeOut = 100;
      end
      iter = 0;
      while true
        try
          obj.window.executeJS(fileread(fileName));
        catch x
          %log
          iter = iter+1;
          if iter > timeOut, rethrow(x); end
          pause(0.2)
          continue
        end
        break
      end
    end
    
    function wait(obj)
      waitfor(obj,'isready');
    end

    function resume(obj)
      uiresume(obj.container);
    end
    
    function focus(obj)
      obj.window.bringToFront;
    end
    
    
  end
  
  methods (Access = private)  
    %% base routines
    function close(obj)
      if ~obj.isClosed
        delete(obj.container);
      end
    end
    
    function destroy(obj)
      if obj.isClosed, return; end
      delete(obj.container.Children);
    end
    
  end
  methods (Access = protected)
    %% Abstract
    createUI(obj);
    startupFcn(obj,varargin);
    
    %% Container Prefs
    function setContainerPrefs(obj)
      % see position set method
      obj.position = obj.container.Position;
      % call this super first
    end
    
    function getContainerPrefs(obj)
      if ~isempty(obj.position)
        pos = obj.position;
      else
        pos = obj.get('position', obj.container.Position);
      end
      obj.container.Position = pos;
      % call this super first.
    end

  end
  
end

