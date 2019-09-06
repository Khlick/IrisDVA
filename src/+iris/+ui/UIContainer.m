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
      
      %build figure base
      obj.container = uifigure( ...
        'Visible', 'off', ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none', ...
        'Toolbar', 'none', ...
        'Color', [1,1,1], ...
        'AutoResizeChildren', 'off', ...
        'Resize', 'off', ...
        'CloseRequestFcn', ...
          @(src,evnt)notify(obj, 'Close'),...
        'DefaultUicontrolFontName', Aes.uiFontName, ...
        'DefaultAxesColor', [1,1,1], ...
        'DefaultAxesFontName', Aes.uiFontName, ...
        'DefaultTextFontName', Aes.uiFontName, ...
        'DefaultUibuttongroupFontname', Aes.uiFontName,...
        'DefaultUitableFontname', Aes.uiFontName, ...
        'DefaultUipanelUnits', 'pixels', ...
        'DefaultUipanelPosition', [20,20, 260, 221],...
        'DefaultUipanelBordertype', 'line', ...
        'DefaultUipanelFontname', Aes.uiFontName,...
        'DefaultUipanelFontunits', 'pixels', ...
        'DefaultUipanelFontsize', Aes.uiFontSize('label'),...
        'DefaultUipanelAutoresizechildren', 'off', ...
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
        'DefaultUitableFontname', Aes.uiFontName, ...
        'DefaultUitableFontunits', 'pixels',...
        'DefaultUitableFontsize', Aes.uiFontSize ...
        );

      try
        obj.container.WindowKeyPressFcn = ...
            @(src,evnt)notify(obj, 'KeyPress', eventData(evnt));
      catch x
        fprintf('Keyboard functionality is not available.\n');
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
          rethrow(x)
        end
      end
      % now gather the web window for the container
      while ~obj.isready
        try
          obj.window = mlapptools.getWebWindow(obj.container);
        catch x
          %log this
        end
      end
      % make modifications
      obj.startup(varargin{:});
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
        tf = obj.window.isWindowValid;
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
        delete(obj.container);
        rethrow(x)
      end
      import iris.app.*;
      obj.window.Icon = fullfile(Info.getResourcePath,'icn','favicon.ico');
      % remove focus from window
      %obj.window.executeJS('window.blur();');
    end
    
    function shutdown(obj)
      obj.setContainerPrefs;
      obj.save;
      obj.hide;
      obj.destroy;
      obj.close;
    end
    
    function rebuild(obj)
      if ~obj.isClosed, return; end
      obj.constructContainer();
    end
    
    function show(obj)
      if obj.isClosed, error('%s already closed.',class(obj)); end
      if strcmpi(obj.container.Visible, 'off')
        obj.container.Visible = 'on';
      end
      obj.window.show;
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
        try %#ok<TRYNC>
          obj.window.close();
        end
        try %#ok<TRYNC>
          delete(obj.container);
        end
      end
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

