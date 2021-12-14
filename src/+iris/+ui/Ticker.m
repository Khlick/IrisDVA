classdef Ticker < iris.ui.UIContainer
  events
    shuttingDown
  end

  properties (Constant,Hidden)
    WIDTH = 400
    HEIGHT = 152
    SCRIPT_ID = 'notifier'
  end

  properties (Access=private)
    Grid    matlab.ui.container.GridLayout
    Spinner iris.ui.elements.notifier
  end

  properties (SetObservable=true,AbortSet=true)
    Text = "Loading..."
    Animate (1,1) logical = false
  end

  methods (Access=protected)
    %% Startup
    function startupFcn(obj,varargin)
      % define listener
      obj.addListener(obj,'Text','PostSet',@obj.onTextChanged);
      obj.addListener(obj,'Animate','PostSet',@obj.onAnimateChanged);
      % parse text if supplied
      if nargin == 1, return; end
      
    end

    function createUI(obj)
      import iris.app.Info;
      pos = obj.position;
      if isempty(pos)
        pos = utilities.centerFigPos(obj.WIDTH,obj.HEIGHT);
      end
      
      % force specific size regardless of if the window was resized previously
      pos(3:4) = [obj.WIDTH,obj.HEIGHT];
      
      obj.position = pos; %sets container too

      % Setup container
      obj.container.Name = sprintf('%s v%s Ticker',Info.name,Info.version('short'));
      
      obj.Grid = uigridlayout(obj.container,[1,1]);
      obj.Grid.RowHeight = {'1x'};
      obj.Grid.ColumnWidth = {'1x'};
      obj.Grid.BackgroundColor = [1,1,1,0];
      obj.Grid.Padding = [5 10 5 10];
      
      % Create Spinner
      flayout = matlab.ui.layout.GridLayoutOptions();
      flayout.Row = 1;
      flayout.Column = 1;
      obj.Spinner = iris.ui.elements.notifier( ...
        obj.Grid, ...
        Text=obj.Text, ...
        TextColor=[0 0 0], ...
        TextHeight=70, ...
        Monospaced=false, ...
        Animate=false, ...
        BackgroundColor=[1,1,1], ...
        Layout=flayout ...
        );
      
    end

  end

  methods
    %% Update

    function update(obj,txt,opts)
      arguments
        obj
        txt (1,1) string
        opts.animate (1,1) logical = false
        opts.forceDelay (1,1) double {mustBeGreaterThanOrEqual(opts.forceDelay,0)} = 0
      end
      % Handle closed case by rebuild and update
      if obj.isClosed()
        obj.detachListeners();
        obj.rebuild();
        pause(0.4);
      end
      obj.show(); %grab focus first
      % set the text and animations
      obj.Animate = opts.animate;
      obj.Text = txt;
      drawnow();
      if ~~opts.forceDelay
        pause(opts.forceDelay);
      end
    end
    
    function updateAsPercent(obj,fraction,opts)
      arguments
        obj
        fraction (1,1) double {mustBeInRange(fraction,0,1,'inclusive')}
        opts.preamble (1,1) string = "Loading... "
        opts.animate (1,1) logical = false
        opts.forceDelay (1,1) double {mustBeGreaterThanOrEqual(opts.forceDelay,0)} = 0
      end
      % Handle closed case by rebuild and update
      if obj.isClosed()
        obj.detachListeners();
        obj.rebuild();
        pause(0.4);
      end
      obj.show(); % grab focus first
      obj.Animate = opts.animate;
      obj.Text = sprintf("%s (%d%%)",opts.preamble,floor(fraction*100));
      if fraction == 1
        drawnow();
        pause(1.5);
        obj.Text = "Done!";
        pause(1.5);
        obj.shutdown();
        return
      end
      drawnow();
      % allow forced delay if not terminating object
      if ~~opts.forceDelay
        pause(opts.forceDelay);
      end
    end
    
    
    %% Superclass overrides

    function shutdown(obj)
      % shutdown adds a notification to shuttingdown event to let listeners trigger
      % events after shutdown automatically
      if obj.isClosed, return; end
      notify(obj,'shuttingDown');
      shutdown@iris.ui.UIContainer(obj);
    end

  end

  %% Callbacks
  methods (Access = private)
    
    function onTextChanged(obj,~,~)
      if obj.isClosed
        % rebuild the ui with new text already set
        obj.rebuild();
        obj.show();
        return
      end
      obj.Spinner.Text = obj.Text;
    end
    
    function onAnimateChanged(obj,~,~)
      if obj.isClosed, return; end
      obj.Spinner.Animate = obj.Animate;
    end
  end
  
  %% Utilities
  methods (Access=private)



  end

end
