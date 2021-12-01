classdef loadShow < iris.ui.UIContainer
  %LOADSHOW A dialog box for displaying while long processes load.
  % Properties that correspond to app components
  events
    shuttingDown
  end
  
  properties (Constant=true)
    WIDTH = 360
    HEIGHT = 125
    SCRIPT_ID = "spinner"
  end

  properties (Access = private)
    Spinner      matlab.ui.control.HTML
    textListen % listener for text setting
    Animate (1,1) logical = false
  end

  properties (SetObservable=true,AbortSet=true,Access=private)
    Text (1,1) string = "Loading..."
  end

  properties (Dependent)
    isHidden
    HTMLSource
    TextData
  end
  
  %% Public Functions
  methods
    function updatePercent(obj,frac,preText,doAnimation)
      if nargin < 4, doAnimation = false; end
      if nargin < 3, preText = 'Loading...'; end
      obj.Animate = doAnimation;
      if obj.isClosed
        obj.rebuild;
        pause(0.01);
      end
      if obj.isHidden
        obj.show();
      else
        obj.focus();
      end
      
      switch class(frac)
        case 'double'
          if frac > 1
            frac = 1;
          end
          
          obj.Text = sprintf("%s (%d%%)",preText,fix(frac*100));
          if frac < 1
            drawnow;
            return
          end
          pause(0.8);
          obj.Text = "Done!";
          pause(1.5);
        case {'char','string'}
          obj.Text = string(frac);
          obj.focus();
          drawnow;
          return
      end
      % shutdown after completion
      obj.shutdown;
    end
    
    % override shutdown to notify shutdown event. This should be a common feature
    function shutdown(obj)
      if obj.isClosed, return; end
      obj.reset; % always show in the center of the screen
      notify(obj,'shuttingDown');
      shutdown@iris.ui.UIContainer(obj);
    end
    
    function tf = get.isHidden(obj)
      if obj.isClosed, tf = true; return; end
      tf = strcmpi(obj.container.Visible,'off') && ~obj.window.isVisible;
    end
    
    function src = get.HTMLSource(obj)
      src = fullfile(iris.app.Info.getResourcePath(),"scripts",obj.SCRIPT_ID,"spin.html");
    end

    function txt = get.Text(obj)
      txt = obj.Text;
    end

    function set.Text(obj,str)
      obj.Text = str;
    end

    function d = get.TextData(obj)
      d = struct("String",obj.Text,"Dims",[obj.WIDTH,obj.HEIGHT],"Animate",obj.Animate);
    end

    function selfDestruct(obj)
      % required for integration with menuservices
      obj.shutdown;
    end
    
  end
  %% Startup and Callback Methods
  methods (Access = protected)
    % Startup
    function startupFcn(obj,varargin)
      
      % define listener
      obj.textListen = addlistener(obj,'Text','PostSet',@obj.updateText);
      % update text
      if nargin > 1
        obj.updatePercent(varargin{:});
      end
    end
    
    % callback
    function updateText(obj,~,~)
      obj.Spinner.Data = obj.TextData;
      drawnow;
    end
    
    % Construct view
    function createUI(obj)
      import iris.app.Info;
      %% Initialize
      initW = obj.WIDTH;
      initH = obj.HEIGHT;
      pos = obj.position;
      if isempty(pos)
        pos = utilities.centerFigPos(initW,initH);
      end
      
      % force specific size regardless of if the window was resized previously
      pos(3:4) = [initW,initH];
      
      obj.position = pos; %sets container too
      
      % Setup container
      obj.container.Name = sprintf('%s v%s',Info.name,Info.version('short'));
      
      gridLayout = uigridlayout(obj.container,[1,1]);
      gridLayout.RowHeight = {'1x'};
      gridLayout.ColumnWidth = {'1x'};
      gridLayout.BackgroundColor = [1,1,1,0];
      gridLayout.Padding = [10 5 10 5];
      
      % Create Spinner
      obj.Spinner = uihtml(gridLayout);
      obj.Spinner.Data = obj.TextData;
      obj.Spinner.HTMLSource = obj.HTMLSource;
      
      drawnow;
    end
    
  end
end
