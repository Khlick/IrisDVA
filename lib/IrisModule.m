classdef IrisModule < iris.infra.ModulePreferenceManager
  events
    CloseRequested
    UICreated
    DataUpdated
    DestroyingModule % todo: Iris should listen for module destruction in moduleservice
  end
  
  properties %(Access = protected)
    Data
  end
  
  properties (SetAccess=private,GetAccess=protected)
    container
    MenuOptions
    refreshMenu
    resetMenu
    saveOnExit (1,1) logical = true
  end

  % internal properties
  properties (Access=private)
    listeners
  end

  properties (Dependent)
    Position
    Name
    isready
    isvisible
    hasdata
  end

  %% Public Methods
  methods
    % constructor
    function obj = IrisModule(data)
      if nargin < 1, data = []; end
      obj = obj@iris.infra.ModulePreferenceManager();
      % construct the ui and run the startup
      obj.constructContainer();
      % run startup procedure to load defaults and preferences
      obj.runStartup();
      % parse data
      try %#ok<TRYNC> 
        obj.setData(data);
      end
      % show the figure
      obj.show();
    end

    % validators
    function tf = get.isready(obj)
      tf = (~isempty(obj.container) && obj.container.isvalid);
    end

    function tf = get.isvisible(obj)
      tf = (~isempty(obj.container) && ~~obj.container.Visible);
    end

    function tf = get.hasdata(obj)
      tf = (~isempty(obj.Data) && isa(obj.Data,'IrisData'));
    end

    % destructor
    function delete(obj)
      notify(obj,'DestroyingModule');
      obj.save();
      obj.detachListeners();
      delete(obj.container);
    end

    % set/get
    % MAIN METHOD FOR SETTING/UPDATING DATA!
    function setData(obj,data,varargin)
      try
        obj.Data = data;
      catch dataErr
        rethrow(dataErr);
      end
    end
    % this method corresponds to the protected data property
    function set.Data(obj,data)
      try
        assert(isa(data,'IrisData') || isempty(data),"Data must be of type: 'IrisData'");
      catch dataErr
        obj.show();
        rethrow(dataErr);
      end
      obj.Data = data;
      notify(obj,'DataUpdated');
    end

    function set.Position(obj,pos)
      obj.container.Position = pos;
    end

    function p = get.Position(obj)
      p = obj.container.Position;
    end

    function set.Name(obj,name)
      obj.container.Name = name;
    end

    function name = get.Name(obj)
      name = obj.container.Name;
    end
    
    function close(obj)
      obj.onClose();
    end

  end
  %% Abstract methods
  %   These methods must be defined, even if just empty, in your module class
  methods (Abstract=true,Access=protected)
    createUI(obj)
    startupFcn(obj)
  end

  %% Changeble Methods
  % When overriding method, call these superclass methods first
  methods (Access=protected)

    function loadPreferences(obj)
      if ~obj.isready, return; end
      % load previous position
      pos = obj.getPref('Position',obj.Position);
      obj.Position = pos;
      obj.Name = obj.getPref('Name',obj.PREF_KEY);
    end

    function savePreferences(obj)
      obj.putPref('Position', obj.Position); % store position
      obj.putPref('Name', obj.Name); % store name
    end

    function onClose(obj)
      % default close method, override to alter behavior
      if obj.saveOnExit
        obj.savePreferences();
      end
      delete(obj);
    end

    function onResetPreferences(obj)
      obj.reset();
      obj.saveOnExit = false;
    end

    function onRefreshView(obj)
      obj.hide();
      obj.reset();
      delete(obj.container.Children);
      obj.createUI();
      obj.addMenus();
      obj.savePreferences();
      obj.setData(obj.Data);
      obj.show();
    end

    % convenience show/hide
    function show(obj)
      obj.container.Visible = "on";
    end

    function hide(obj)
      obj.container.Visible = "off";
    end
    
    function recenter(obj)
      pos = obj.Position;
      obj.Position = IrisModule.getCenteredPosition(pos(3),pos(4));
    end

  end

  %% Internal Methods
  methods (Access=private)

    function constructContainer(obj)
      obj.container = uifigure( ...
        'Visible', 'off', ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none', ...
        'Toolbar', 'none', ...
        'Color', [1, 1, 1], ...
        'AutoResizeChildren', 'off', ...
        'Resize', 'on', ...
        'HandleVisibility', 'off', ...
        'Tag', obj.PREF_KEY, ...
        'CloseRequestFcn', ...
        @(src, evnt)obj.onClose() ...
        );
      params = IrisModule.getContainerProperties();
      for p = 1:size(params, 2)
        try %#ok<TRYNC>
          set(obj.container, params{1, p}, params{2, p});
        end
      end

      try
        obj.createUI();
        obj.addMenus();
      catch creationErr
        delete(obj);
        rethrow(creationErr);
      end
      

      % notify creation to allow subclass to inject functionality before stored
      % preferences are loaded.
      notify(obj,'UICreated');
    end

    function runStartup(obj)
      % load previous defaults
      obj.loadPreferences();
      % run subclass startup function
      obj.startupFcn();
    end

    function addMenus(obj)
      obj.MenuOptions = uimenu(obj.container,'Text','Options');

      obj.refreshMenu = uimenu( ...
        obj.MenuOptions, ...
        "Text","Refresh View", ...
        "MenuSelectedFcn",@(s,e)obj.onRefreshView() ...
        );
      
      obj.resetMenu = uimenu( ...
        obj.MenuOptions, ...
        "Text", "Rest Preferences", ...
        "MenuSelectedFcn",@(s,e)obj.onResetPreferences() ...
        );
    end

  end

  %% Listener Management
  methods (Access = protected)

    function l = addListener(obj, varargin)
      l = addlistener(varargin{:});
      obj.listeners{end + 1} = l;
    end

    function lsn = getListenerByEvent(obj, eventName)
      % always return cell array
      loc = ismember( ...
        cellfun(@(l)l.EventName, obj.listeners, 'UniformOutput', false), ...
        eventName ...
        );

      if ~any(loc)
        lsn = {};
        return
      end

      lsn = obj.listeners(loc);
    end

    function removeListenerByEvent(obj, eventName)
      lsn = obj.getListnerByEvent(eventName);
      if isempty(lsn), return; end

      for L = 1:numel(lsn)
        delete(lsn{L});
      end

      obj.cleanupListeners();
    end

    function cleanupListeners(obj)
      drop = false(numel(obj.listeners), 1);

      for L = 1:numel(obj.listeners)
        drop(L) = ~obj.listeners{L}.isvalid;
      end

      if ~any(drop), return; end
      obj.listeners(drop) = [];
    end

    function detachListeners(obj)

      while ~isempty(obj.listeners)
        delete(obj.listeners{1});
        obj.listeners(1) = [];
      end
      % convert to cell array
      obj.listeners = {};
    end

  end


  %% Helper Methods (Static)
  methods (Static)
    
    function p = getCenteredPosition(w,h,screenId)
      G = get(groot);
      if nargin < 3
        if ~strcmp(G.Units,'pixels')
          screenUnits = get(groot,'Units');
          set(groot,'Units','pixels');
          G = get(groot);
          set(groot,'Units',screenUnits);
        end
        % locate main monitor
        mons = G.MonitorPositions;
        loc = mons(:,1:2) == 1;
        screenId = find(all(loc,2),1,'first');
        if isempty(screenId), screenId = 1; end
      end
      
      s = G.MonitorPositions(screenId,:);
      if any([w<=1 && w>0,h<=1 && h>0])
        if ~all([w<=1 && w>0,h<=1 && h>0])
          error('If w & h are normalized, must be (0,1].');
        end
        w = w*s(3);
        h = h*s(4);
      end

      p = [(s(3) - w) / 2 + s(1) - 1, (s(4) - h) / 2 + s(2) - 1, w, h];
    end

    function params = getContainerProperties()
      params = { ...
        'DefaultAxesInterruptible', 'off', ...
        'DefaultAxesFontName', 'Times New Roman', ...
        'DefaultAxesFontsize', 11, ...
        'DefaultAxesColor', [1, 1, 1, 0], ...
        'DefaultAxesBox', 'off', ...
        'DefaultAxesXLimMode', 'manual', ...
        'DefaultAxesYLimMode', 'manual', ...
        'DefaultTextFontName', 'Times New Roman', ...
        'DefaultTextBackgroundColor', [1, 1, 1, 0], ...
        'DefaultUipanelUnits', 'pixels', ...
        'DefaultUipanelPosition', [20, 20, 260, 221], ...
        'DefaultUipanelBackgroundColor', [1, 1, 1], ...
        'DefaultUipanelBorderType', 'line', ...
        'DefaultUipanelFontname', 'Times New Roman', ...
        'DefaultUipanelFontunits', 'pixels', ...
        'DefaultUipanelFontsize', 14, ...
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
        'DefaultUibuttongroupFontname', 'Times New Roman', ...
        'DefaultUibuttongroupFontunits', 'pixels', ...
        'DefaultUibuttongroupFontsize', 14, ...
        'DefaultUibuttongroupAutoresizechildren', 'off', ...
        'DefaultUibuttongroupInterruptible', 'off', ...
        'DefaultUitabBackgroundColor', [1, 1, 1], ...
        'DefaultUitableBackgroundColor', [1, 1, 1], ...
        'DefaultUitableFontname', 'Times New Roman', ...
        'DefaultUitableFontunits', 'pixels', ...
        'DefaultUitableFontsize', 11, ...
        'DefaultUitableBusyAction', 'cancel', ...
        'DefaultUitableInterruptible', 'off', ...
        'DefaultLineInterruptible', 'off', ...
        'DefaultUicontainerBackgroundColor', [1, 1, 1], ...
        'DefaultUicontrolFontName', 'Times New Roman', ...
        'DefaultUicontrolInterruptible', 'off', ...
        'defaultUicontrolBackgroundColor', [1, 1, 1, 0], ...
        'defaultUigridcontainerBackgroundColor', [1, 1, 1], ...
        'defaultUiflowcontainerBackgroundColor', [1, 1, 1], ...
        'DefaultHgjavacomponentBackgroundColor', [1, 1, 1], ...
        'DefaultUitabBackgroundColor', [1,1,1], ...
        'Icon', fullfile(iris.app.Info.getResourcePath, 'icn', 'favicon.png')
        };

      params = reshape(params, 2, []);
    end

  end

end
