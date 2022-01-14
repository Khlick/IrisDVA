classdef about < iris.ui.UIContainer
  %ABOUT Display information about Iris.
  properties (Constant,Hidden)
    WIDTH = 500
    HEIGHT = 480
    SCRIPT_ID = "icon3d"
  end

  properties %(Access=private)
    Grid
    Contents
  end

  properties (Dependent=true)
    headline
    message
    HTMLSource
  end
  
  methods (Access = protected)
    
    % Startup
    function startupFcn(obj,varargin) %#ok<INUSD> 
    end
    
    % Construct view
    function createUI(obj)
      % imports
      import iris.app.Info;
      
      pos = obj.position;
      if isempty(pos)
        pos = utilities.centerFigPos(obj.WIDTH,obj.HEIGHT);
      end
      obj.position = pos;
      
      % Container
      obj.container.Name = sprintf('%s v%s',Info.name,Info.version('development'));
      obj.container.Color = [0 0 0];
      
      % Create Grid
      obj.Grid = uigridlayout(obj.container,[1,1]);
      obj.Grid.RowHeight = {'1x'};
      obj.Grid.ColumnWidth = {'1x'};
      obj.Grid.BackgroundColor = [0,0,0];
      obj.Grid.Padding = [5 10 5 10];
      
      % content layout spec
      flayout = matlab.ui.layout.GridLayoutOptions();
      flayout.Row = 1;
      flayout.Column = 1;
      
      % Create Contents
      obj.Contents = uihtml(obj.Grid);
      obj.Contents.Layout.Row = 1;
      obj.Contents.Layout.Column = 1;
      obj.Contents.HTMLSource = obj.HTMLSource;
      obj.Contents.Data = struct( ...
          'headline', obj.headline, ...
          'content', obj.message ...
          );
    end
    
  end
  
  methods
    
    function selfDestruct(obj)
      % selfDestruct Integration with menuServices
      obj.shutdown;
      obj.reset();
      obj.save();
    end

    function s = get.headline(obj) %#ok<MANU> 
      import iris.app.Info;
      s = sprintf( ...
        strcat( ...
          "<p class='title lab'><span class='b'>%s</span></p>", ...
          "<p class='lab by'><span class='i'>%s</span></p>"...
        ), ...
        Info.name, ...
        Info.extendedName ...
        );
    end

    function s = get.message(obj) %#ok<MANU>
      import iris.app.Info;
      aboutText = Info.Summary;
      s = sprintf( ...
        strcat( ...
          "<p class='lab'><span class='inc b'>%s</span> (%s). %s.</p>", ...
          "<p class='lab dec'>%s <span class='b'>Version %s</span>, ", ...
          "developed for the %s, by %s. ", ...
          "This software is provided as-is under the MIT License. See the ", ...
          "<a href='%s' target='_system'>documentation</a> for more information.</p>" ...
        ), ...
        aboutText{:} ...
        );
    end
    
    % html source
    function src = get.HTMLSource(obj)
      src = fullfile( ...
        iris.app.Info.getResourcePath(), ...
        "scripts", ...
        obj.SCRIPT_ID, ...
        sprintf("%s.html",obj.SCRIPT_ID) ...
        );
    end

  end
end
