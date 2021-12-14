classdef (Abstract) UIContainer < iris.infra.UIWindow

  properties (SetObservable = true)
    position
    isBound = false
  end

  properties (Dependent)
    isClosed
    isVisible
    hasWindow
  end

  properties (Access = protected)
    synchronizer
  end

  methods
    %% Constructor
    function obj = UIContainer(varargin)
      obj = obj@iris.infra.UIWindow(varargin{:});
    end

    %function obj = UIContainer()
    function constructContainer(obj, varargin)
      % Contains dependencies for iris.infra.eventData and iris.app.Aes
      import iris.infra.*;
      import iris.app.*;

      SJO = warning('off', 'MATLAB:ui:javaframe:PropertyToBeRemoved');
      SOO = warning('off', 'MATLAB:structOnObject');
      greys = Aes.appColor(6, 'greys', 'matrix');
      %build figure base
      params = { ...
              'DefaultAxesInterruptible', 'off', ...
                'DefaultAxesFontName', Aes.uiFontName, ...
                'DefaultAxesFontsize', Aes.uiFontSize(), ...
                'DefaultAxesColor', [1, 1, 1, 0], ...
                'DefaultAxesBox', 'off', ...
                'DefaultAxesXLimMode', 'manual', ...
                'DefaultAxesYLimMode', 'manual', ...
                'DefaultTextFontName', Aes.uiFontName, ...
                'DefaultTextBackgroundColor', [1, 1, 1, 0], ...
                'DefaultUitableFontname', Aes.uiFontName, ...
                'DefaultUipanelUnits', 'pixels', ...
                'DefaultUipanelPosition', [20, 20, 260, 221], ...
                'DefaultUipanelBackgroundColor', [1, 1, 1], ...
                'DefaultUipanelBorderType', 'line', ...
                'DefaultUipanelHightlightColor', greys(end, :), ...
                'DefaultUipanelFontname', Aes.uiFontName, ...
                'DefaultUipanelFontunits', 'pixels', ...
                'DefaultUipanelFontsize', Aes.uiFontSize('label'), ...
                'DefaultUipanelAutoresizechildren', 'off', ...
                'DefaultUipanelInterruptible', 'off', ...
                'DefaultUitabgroupUnits', 'pixels', ...
                'DefaultUitabgroupPosition', [20, 20, 250, 210], ...
                'DefaultUitabgroupAutoresizechildren', 'off', ...
                'DefaultUitabUnits', 'pixels', ...
                'DefaultUitabAutoresizechildren', 'off', ...
                'DefaultUibuttongroupUnits', 'pixels', ...
                'DefaultUibuttongroupPosition', [20, 20, 260, 210], ...
                'DefaultUibuttongroupBordertype', 'line', ...
                'DefaultUibuttongroupFontname', Aes.uiFontName, ...
                'DefaultUibuttongroupFontunits', 'pixels', ...
                'DefaultUibuttongroupFontsize', Aes.uiFontSize('custom', 2), ...
                'DefaultUibuttongroupAutoresizechildren', 'off', ...
                'DefaultUibuttongroupInterruptible', 'off', ...
                'DefaultUitabBackgroundColor', [1, 1, 1], ...
                'DefaultUitableBackgroundColor', [1, 1, 1], ...
                'DefaultUitableFontname', Aes.uiFontName, ...
                'DefaultUitableFontunits', 'pixels', ...
                'DefaultUitableFontsize', Aes.uiFontSize, ...
                'DefaultUitableBusyAction', 'cancel', ...
                'DefaultUitableInterruptible', 'off', ...
                'DefaultLineInterruptible', 'off', ...
                'DefaultUicontainerBackgroundColor', [1, 1, 1], ...
                'DefaultUicontrolFontName', Aes.uiFontName, ...
                'DefaultUicontrolInterruptible', 'off', ...
                'defaultUicontrolBackgroundColor', [1, 1, 1, 0], ...
                'defaultUigridcontainerBackgroundColor', [1, 1, 1], ...
                'defaultUiflowcontainerBackgroundColor', [1, 1, 1], ...
                'DefaultHgjavacomponentBackgroundColor', [1, 1, 1], ...
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

      params = reshape(params, 2, []);

      obj.container = uifigure( ...
        'Visible', 'off', ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none', ...
        'Toolbar', 'none', ...
        'Color', [1, 1, 1], ...
        'AutoResizeChildren', 'off', ...
        'Resize', 'off', ...
        'HandleVisibility', 'off', ...
        'Tag', [iris.app.Info.name, 'UI'], ...
        'CloseRequestFcn', ...
        @(src, evnt)notify(obj, 'Close') ...
      );

      try
        obj.container.WindowKeyPressFcn = ...
          @(src, evnt)notify(obj, 'KeyPress', eventData(evnt));
      catch x
        iris.app.Info.showWarning( ...
          sprintf( ...
          'Keyboard functionality is not available because: "%s"', ...
          x.message ...
        ) ...
        );
      end

      for p = 1:size(params, 2)

        try %#ok<TRYNC>
          set(obj.container, params{1, p}, params{2, p});
        end

      end

      try
        obj.createUI(varargin{:});
      catch
        obj.destroy(); %deletes children

        try
          obj.createUI();
        catch x
          delete(obj.container); %remove container
          warning(SOO);
          warning(SJO);
          rethrow(x);
        end

      end

      v = version('-release');
      v = str2double(regexprep(v, '[^\d]*', ''));

      if v < 2021
        % This overcomes some "infinite" loop in MATLAB, which appears to be a workaround for "g1658467".
        % The consequences of doing this are unclear.
        % See also MATLAB\R20###\toolbox\matlab\uitools\uicomponents\components\...
        %            +matlab\+ui\+internal\+controller\FigureController.m\flushCoalescer()
        % See  https://gist.github.com/Dev-iL/398a38ae03c6ef9ebf935d46884ce74d
        obj.synchronizer = struct(struct(struct(obj.container).Controller).PeerModelInfo).Synchronizer;
        obj.synchronizer.setCoalescerMinDelay(0);
        obj.synchronizer.setCoalescerMaxDelay(5);
      end

      % now gather the web window for the container
      drawnow();
      pause(0.01);

      % Move away from mlapptools for release 2.1
      while true

        try
          obj.window = mlapptools.getWebWindow(obj.container);
        catch x
          %log this
          continue
        end

        break
      end

      % invoke the startup function
      obj.startup(varargin{:});

      %return warning status
      warning(SOO);
      warning(SJO);
    end

    %% set

    function set.position(obj, p)
      validateattributes(p, {'numeric'}, {'2d', 'numel', 4});
      obj.put('position', p);
      obj.position = p;
      obj.container.Position = p;
    end

    function setUI(obj, uiObjName, propName, newVal)
      % sets a single gui property value for any number of ui objects.
      if ischar(uiObjName), uiObjName = cellstr(uiObjName); end
      if ~ischar(propName), propName = propName{1}; end
      % skip prop check and let error occur on setting
      %uiObjName = uiObjName(contains(uiObjName,properties(obj)));

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

    function set.isVisible(obj, status)

      arguments
        obj
        status (1, 1) matlab.lang.OnOffSwitchState
      end

      if obj.isClosed, return; end
      obj.container.Visible = status;
    end

    %% get

    function f = get.position(obj)
      f = obj.get('position', []);
    end

    function tf = get.isClosed(obj)

      try
        tf = ~obj.isready;
      catch x %#ok
        % log x
        tf = true;
      end

    end

    function tf = get.hasWindow(obj)
      tf = ~isempty(obj.window);
    end

    function v = getUI(obj, uiObj, propName)
      props = metaclass(obj);
      props = props.PropertyList;
      props = string({props.Name}');
      uiObj = validatestring(uiObj, props);
      v = obj.(uiObj).(propName);
    end

    function tf = get.isVisible(obj)
      tf = ~obj.isClosed && logical(obj.container.Visible);
    end

    %% interactive functions

    function startup(obj, varargin)

      import iris.app.Info

      obj.getContainerPrefs;

      try
        obj.startupFcn(varargin{:}); %abstract
      catch x
        obj.close();
        rethrow(x)
      end

      try
        obj.window.Icon = fullfile(Info.getResourcePath, 'icn', 'favicon.ico');
      catch

        try %#ok<TRYNC>
          obj.window.Icon = fullfile(Info.getResourcePath, 'icn', 'favicon.png');
        end

      end

    end

    function shutdown(obj)
      if obj.isClosed, return; end
      obj.setContainerPrefs();
      obj.save();
      obj.hide();
      obj.close();
    end

    function rebuild(obj, varargin)
      if ~obj.isClosed, return; end
      obj.isBound = false;
      obj.constructContainer(varargin{:});
    end

    function show(obj)
      if obj.isClosed, error('%s is closed.', class(obj)); end

      if ~obj.isVisible
        obj.container.Visible = 'on';
      end

    end

    function hide(obj)

      if strcmpi(obj.container.Visible, 'on')
        obj.container.Visible = 'off';
      end

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

    function executeJSFile(obj, fileName, timeOut)

      if nargin < 3
        timeOut = 100;
      end

      iter = 0;

      while true

        try
          obj.window.executeJS(fileread(fileName));
        catch x
          %log
          iter = iter + 1;
          if iter > timeOut, rethrow(x); end
          pause(0.2)
          continue
        end

        break
      end

    end

    function wait(obj)
      waitfor(obj, 'isready');
    end

    function resume(obj)
      uiresume(obj.container);
    end

    function focus(obj)
      if obj.isClosed, return; end

      if obj.hasWindow
        obj.window.bringToFront;
      else
        figure(obj.container);
      end

    end

  end

  methods (Access = private)
    %% base routines
    function close(obj)
      if obj.isClosed, return; end
      delete(obj.container);
    end

    function destroy(obj)
      if obj.isClosed, return; end
      delete(obj.container.Children);
    end

  end

  methods (Access = protected)
    %% Abstract
    createUI(obj);
    startupFcn(obj, varargin);

    %% Container Prefs
    function setContainerPrefs(obj)
      % see position set method
      obj.position = obj.container.Position;
      % call this super first
    end

    function getContainerPrefs(obj)
      pos = obj.position;

      if isempty(pos)
        % collect current container position
        pos = obj.container.Position;
        obj.position = pos; % save it for next session
      end

      obj.container.Position = pos;
      % call this super first.
    end

  end

end
