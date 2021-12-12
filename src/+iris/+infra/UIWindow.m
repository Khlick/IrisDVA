classdef (Abstract) UIWindow < iris.infra.StoredPrefs
  %UIWINDOW Super class holding either figure or uifigure base properties
  %   Detailed explanation goes here

  events
    KeyPress
    MouseEvent
    ScrollWheel
    Close
    WindowReady
  end

  properties (Access = protected)
    container
    window
    options
    listeners
  end

  properties (Dependent)
    isready
  end

  properties (Access = private)
    DRAWTIMEOUT = 10 % 10 seconds timeout
  end

  methods

    function obj = UIWindow(varargin)
      obj.listeners = {};
      cName = regexp(class(obj), '(?<=\.)\w*$', 'match', 'once');

      try
        options = iris.pref.(cName).getDefault();
      catch
        options = [];
      end

      obj.options = options;
      w = warning('off', 'MATLAB:ui:javaframe:PropertyToBeRemoved');
      pause(0.001);
      obj.constructContainer(varargin{:});

      pause(0.001);
      warning(w);
    end

    %% SET / GET
    function tf = get.isready(obj)
      tf = ~isempty(obj.container) && obj.container.isvalid;
    end
    function set.isready(obj,status)
      status = ~~status;
      notify(obj,'WindowReady',iris.infra.eventData(status));
    end

    % Main Constructor from solid subclass
    constructContainer(obj, varargin)

  end

  methods (Access = protected)

    %% Container Prefs

    setContainerPrefs(obj)

    getContainerPrefs(obj)

    %% Listener
    function l = addListener(obj, varargin)
      l = addlistener(varargin{:});
      obj.listeners{end + 1} = l;
    end

    function enableListener(obj, listener)
      loc = ismember( ...
        cellfun(@(l)l.EventName, obj.listeners, 'UniformOutput', false), ...
        listener ...
      );
      if ~any(loc), disp('Listener non-existent'); end
      obj.listeners{loc}.Enabled = true;
    end

    function disableListener(obj, listener)
      loc = ismember( ...
        cellfun(@(l)l.EventName, obj.listeners, 'UniformOutput', false), ...
        listener ...
      );
      if ~any(loc), disp('Listener non-existent'); end
      obj.listeners{loc}.Enabled = false;
    end

    function lsn = getListener(obj, eventName)
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

    function removeListener(obj, eventName)
      lsn = obj.getListner(eventName);
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

      obj.listeners = {};
    end

  end

end
