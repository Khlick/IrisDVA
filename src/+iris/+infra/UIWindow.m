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
    
    function drawnow(obj)
      drawnow('limitrate','nocallbacks');
      pause(0.01);
      %{
      t = timer( ...
        'TimerFcn', ...
        [ ...
          'com.mathworks.mde.cmdwin.CmdWinMLIF.getInstance().processKeyFromC(', ...
            '2,67,''C''', ...
          ')' ...
        ], ...
        'StartDelay', obj.DRAWTIMEOUT ...
        );
      t.StartFcn = @doDraw;
      t.StopFcn = @onStop;
      
      try
        t.start();
      catch mr
        iris.app.Info.showWarning(mr.message);
      end
      
      % timer functions
      function doDraw(~,~)
        drawnow('limitrate');
      end
      function onStop(hT,~)
        delete(hT);
      end
      %}
    end
    
  end
  
end

