classdef (Abstract) JContainer < iris.infra.UIWindow

  properties
    position
    isBound = false
  end

  properties (Dependent)
    isClosed
  end

  methods
    %% Constructor
    function obj = JContainer(varargin)
      obj = obj@iris.infra.UIWindow(varargin{:});
    end

    function constructContainer(obj, varargin)
      % Contains dependencies for iris.infra.eventData and iris.app.Aes
      import iris.infra.*;
      import iris.app.*;

      %build figure base
      obj.container = figure( ...
      'Visible', 'off', ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none', ...
        'Toolbar', 'none', ...
        'DockControls', 'off', ...
        'Interruptible', 'off', ...
        'HitTest', 'off', ...
        'Color', [1, 1, 1], ...
        'Tag', [iris.app.Info.name, 'UI'], ...
        'WindowKeyPressFcn', ...
        @(src, evnt)notify(obj, 'KeyPress', eventData(evnt)), ...
        'CloseRequestFcn', ...
        @(src, evnt)notify(obj, 'Close'), ...
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
        'DefaultUicontrolBackgroundColor', [1, 1, 1, 0], ...
        'DefaultUigridcontainerBackgroundColor', [1, 1, 1], ...
        'DefaultHgjavacomponentBackgroundColor', [1, 1, 1], ...
        'HandleVisibility', 'off' ...
      );
      oldWarn = warning('off', 'MATLAB:ui:javaframe:PropertyToBeRemoved');

      try
        obj.createUI(varargin{:});
      catch r

        try
          obj.createUI();
        catch x
          warning(oldWarn);
          delete(obj.container);
          rethrow(x);
        end

        iris.app.Info.showWarning( ...
          sprintf( ...
          '<%s> "%s".', ...
          strjoin( ...
          arrayfun( ...
          @(s) sprintf("%s[line %d]", s.name, s.line), ...
          r.stack, ...
          'UniformOutput', true ...
        ), ...
          ':' ...
        ), ...
          r.message ...
        ) ...
        );
      end

      % now gather the web window for the container
      obj.window = [];
      % make modifications
      obj.startup(varargin{:});
      warning(oldWarn);
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
      props = metaclass(obj);
      props = props.PropertyList;
      props = string({props.Name}');
      uiObjName = uiObjName(contains(uiObjName, props));

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
      rootMonitors = get(groot, 'MonitorPositions');

      if f(1) > (max(rootMonitors(:, 3)) - f(3))
        f(1) = max(rootMonitors(:, 3)) - f(3);
      end

      if f(2) > (max(rootMonitors(:, 4)) - f(4))
        f(2) = max(rootMonitors(:, 4)) - f(4);
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

    function v = getUI(obj, uiObj, propName)
      uiObj = validatestring(uiObj, properties(obj));
      v = obj.(uiObj).(propName);
    end

    function tf = isVisible(obj)
      tf = obj.container.isvalid && strcmpi(obj.container.Visible, 'on');
    end

    %% interactive functions

    function startup(obj, varargin)
      obj.getContainerPrefs;

      try
        obj.startupFcn(varargin{:}); %abstract
      catch x
        delete(obj.container);
        rethrow(x)
      end

      % set the favicon
      warnState = warning('query', ...
      'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame' ...
      );
      warning('off', 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');

      try
        jframe = get(obj.container, 'javaframe');
        jIcon = javax.swing.ImageIcon( ...
          fullfile( ...
          iris.app.Info.getResourcePath, 'icn', 'favicon.png' ...
        ) ...
        );
        jframe.setFigureIcon(jIcon);
      catch x %#ok
        % log x.message?
      end

      warning(warnState.state, ...
        'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame' ...
      );
    end

    function shutdown(obj)
      obj.setContainerPrefs;
      obj.save();
      obj.hide;
      obj.close;
    end

    function rebuild(obj)
      if ~obj.isClosed, return; end
      obj.isBound = false;
      obj.constructContainer();
    end

    function show(obj)

      if strcmpi(obj.container.Visible, 'off')
        obj.container.Visible = 'on';
      end

      figure(obj.container);
    end

    function hide(obj)
      obj.container.Visible = 'off';
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
      %drawnow();
      pause(0.01);

      try %#ok<TRYNC>
        obj.setContainerPrefs();
      end

    end

    function setWindowStyle(obj, s)
      set(obj.container, 'WindowStyle', s);
    end

    function wait(obj)
      waitfor(obj, 'isready');
    end

    function resume(obj)
      uiresume(obj.container);
    end

    function focus(obj)
      figure(obj.container);
    end

  end

  methods (Access = private)
    %% base routines
    function close(obj)
      delete(obj.container);
    end

    function destroy(obj)
      if obj.isClosed, return; end

      try %#ok<TRYNC>
        delete(obj.container.Children);
      end

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
