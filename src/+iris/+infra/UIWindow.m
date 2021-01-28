classdef (Abstract) UIWindow < iris.infra.StoredPrefs
  %UIWINDOW Super class holding either figure or uifigure base properties
  %   Detailed explanation goes here
  
  events
    KeyPress
    MouseEvent
    ScrollWheel
    Close
  end
  
  properties (Access = protected)
    options
    listeners
  end
  
  properties (Access = private)
    DRAWTIMEOUT = 10 % 5 seconds timeout
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
      w = warning('off','MATLAB:ui:javaframe:PropertyToBeRemoved');
      pause(0.001);
      obj.constructContainer(varargin{:});
      
      pause(0.001);
      warning(w);
    end
    
    %abstract
    constructContainer(obj,varargin)
    
  end
  
  methods (Access = protected)
    
    %% Container Prefs
    
    setContainerPrefs(obj)
    
    getContainerPrefs(obj)
    
    function l = addListener(obj, varargin)
      l = addlistener(varargin{:});
      obj.listeners{end+1} = l;
    end
    
    function enableListener(obj, listener)
      loc = ismember(...
        cellfun(@(l)l.EventName, obj.listeners, 'UniformOutput',false), ...
        listener ...
        );
      if ~any(loc), disp('Listener non-existent'); end
      obj.listeners{loc}.Enabled = true;
    end
    
    function disableListener(obj,listener)
      loc = ismember(...
        cellfun(@(l)l.EventName, obj.listeners,'UniformOutput',false), ...
        listener ...
        );
      if ~any(loc), disp('Listener non-existent'); end
      obj.listeners{loc}.Enabled = false;
    end
    
    function lsn = getListener(obj, eventName)
      loc = ismember( ...
        cellfun(@(l)l.EventName,obj.listeners,'UniformOutput',false), ...
        eventName ...
        );
      if ~any(loc)
        lsn = {};
      else
        
      end
    end
    
  end
  
end

