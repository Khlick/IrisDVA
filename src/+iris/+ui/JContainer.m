classdef (Abstract) JContainer < iris.infra.UIWindow
  
  properties
    position
  end
  
  properties (Dependent)
    isClosed
    isready
  end
  
  properties (Access = protected)
    container
    window
  end
  
  methods
    %% Constructor
    function obj = JContainer(varargin)
      obj = obj@iris.infra.UIWindow(varargin{:});
    end
    
    function constructContainer(obj,varargin)
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
        'Interruptible', 'on', ...
        'HitTest', 'off', ...
        'Color', [1,1,1], ...
        'WindowKeyPressFcn', ...
          @(src,evnt)notify(obj, 'KeyPress', eventData(evnt)),...
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
        'DefaultUitableFontsize', Aes.uiFontSize, ...
        'HandleVisibility', 'off' ...
        );
      % set the favicon
      warnState = warning('query', ...
        'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame' ...
        );
      warning('off', 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
      try
        jframe=get(obj.container,'javaframe');
        jIcon=javax.swing.ImageIcon( ...
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
      try
        obj.createUI(varargin{:});
      catch r
        try
          obj.createUI();
        catch x
          delete(obj.container);
          rethrow(x);
        end
      end
      % now gather the web window for the container
      obj.window = [];
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
      tf = obj.container.isvalid;
    end
    
    function v = getUI(obj, uiObj, propName)
      uiObj = validatestring(uiObj,properties(obj));
      v = obj.(uiObj).(propName);
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
    end
    
    function shutdown(obj)
      obj.setContainerPrefs;
      obj.save();
      obj.hide;
      obj.close;
    end
    
    function rebuild(obj)
      if ~obj.isClosed, return; end
      obj.constructContainer;
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
    
    function update(obj)%#ok
      drawnow('update');
    end
    
    function setWindowStyle(obj, s)
      set(obj.container, 'WindowStyle', s);
    end

  end
  methods (Access = private)  
    %% base routines
    function close(obj)
      delete(obj.container);
    end

    function wait(obj)
      uiwait(obj.container);
    end

    function resume(obj)
      uiresume(obj.container);
    end
    
    function delete(obj)
      if ~obj.isClosed
        obj.close();
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

