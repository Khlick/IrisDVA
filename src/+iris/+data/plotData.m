classdef plotData < handle
  %PLOTDATA Collect data for generating plot information.
  properties
    line iris.data.line
    marker iris.data.marker
    name
    x
    y
    mode
  end
  
  
  methods
    
    function obj = plotData(d,dPrefs,lineOpacity,markerOpacity)
      if nargin < 1, return; end
      if nargin < 4, markerOpacity = 0.6; end
      if nargin < 3, lineOpacity = 0.8; end
      if nargin < 2
        dPrefs = iris.pref.display.getDefault;
      end
      %create mode string
      modeStr = {};
      if ~strcmpi(dPrefs.LineStyle, 'None')
        modeStr{end+1} = 'lines';
      end
      if ~strcmpi(dPrefs.Marker, 'None')
        modeStr{end+1} = 'markers';
      end
      modeStr = strjoin(modeStr,'+');
      % generate array based on the number of response devices
      N = length(d.y);
      colorMap = iris.app.Aes.appColor(N,'contrast');
      obj(N,1) = iris.data.plotData();%empty
      for ix = 1:N
        obj(ix).line = iris.data.line( ...
          dPrefs.LineWidth, ... %width
          colorMap(ix,:),   ... %color
          dPrefs.LineStyle, ... %style
          lineOpacity       ... %opacity
          );
        obj(ix).marker = iris.data.marker( ...
          dPrefs.MarkerSize, ... %size
          colorMap(ix,:),    ... %color
          dPrefs.Marker,     ... %style
          markerOpacity      ... %opacity
          );
        obj(ix).name = sprintf('%s (%s)', d.id, d.devices{ix});
        obj(ix).x = d.x{ix};
        obj(ix).y = d.y{ix};
        obj(ix).mode = modeStr;
      end
    end
    
  end
  
end