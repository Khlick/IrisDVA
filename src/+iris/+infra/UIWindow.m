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
  end
  
  properties (Access = private)
    DRAWTIMEOUT = 10 % 5 seconds timeout
  end
  
  methods
    
    function obj = UIWindow(varargin)
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
    
  end
  
end

