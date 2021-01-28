classdef layout < handle
  
  properties (SetAccess = private)
    width
    height
    titlefont
    font
    margin
  end
  
  properties
    xaxis iris.data.encode.axis
    yaxis iris.data.encode.axis
  end
  
  methods
    
    function obj = layout(XTitle,YTitle)
      if nargin < 2
        YTitle = 'Y';
      end
      if nargin < 1
        XTitle = 'X';
      end
      % all built on constructor
      import iris.app.Aes;
      
      obj.width = 1230;
      obj.height = 716;
      obj.titlefont = struct('family', Aes.uiFontName);
      obj.margin = struct( ...
        'r', 10, ... %d3 15, ... %ml 10, ...
        'b', 30, ... %d3 40, ... %ml 15, ...
        'l', 42, ... %d3 60, ... %ml 20, ...
        't', 15 ... %d3 15 ... %ml 10 ...
        );
      obj.font = struct( ...
        'family', Aes.uiFontName, ...
        'size', 16 ...
        );
      % generate from display options
      vOpts = iris.pref.display.getDefault();
      
      xGrid = ismember(vOpts.Grid, {'Both', 'X Axis'});
      yGrid = ismember(vOpts.Grid, {'Both', 'Y Axis'});
      
      xScale = lower(vOpts.XScale);
      yScale = lower(vOpts.YScale);
      
      obj.xaxis = iris.data.encode.axis(XTitle,xScale,xGrid);
      obj.yaxis = iris.data.encode.axis(YTitle,yScale,yGrid);
    end
    %% Convenience Functions
    function setTitle(obj, ax, title)
      ax = validatestring(ax, {'x','y'});
      obj.([ax,'axis']).title = title;
    end
    function update(obj)
      % generate from display options
      vOpts = iris.pref.display.getDefault();
      
      obj.xaxis.update( ...
        struct( ...
          'grid', ismember(vOpts.Grid, {'Both', 'X Axis'}), ...
          'scale', lower(vOpts.XScale) ...
          ) ...
        );
      
      obj.yaxis.update( ...
        struct( ...
          'grid', ismember(vOpts.Grid, {'Both', 'Y Axis'}), ...
          'scale', lower(vOpts.YScale) ...
          ) ...
        );
      
    end
  end
  
end

