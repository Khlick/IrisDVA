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
  
  methods
    
    function obj = UIWindow(varargin)
      cName = regexp(class(obj), '(?<=\.)\w*$', 'match', 'once');
      try
        options = iris.pref.(cName);
      catch
        options = [];
      end
      obj.options = options;
      obj.constructContainer(varargin{:});
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

