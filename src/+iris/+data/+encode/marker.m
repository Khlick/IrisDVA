classdef marker < handle
  
  properties
    type
    size
    color
    opacity
  end
  
  methods
    
    % Constructor
    function obj = marker(s,c,t,o)
      if nargin < 4, o = 0.6; end
      if nargin < 3, t = 'circle'; end
      if nargin < 2, c = iris.app.Aes.appColor(1,'contrast'); end
      if nargin < 1, s = 8; end
      obj.type = t;
      obj.color = c;
      obj.size = s;
      obj.opacity = o;
    end
    
    % Convenience Collecter
    function S = collect(obj)
      S = struct( ...
        'Marker', obj.type, ...
        'MarkerSize', obj.size ...
        );
    end
    
    %% set
    function set.size(obj,value)
      validateattributes(value, {'numeric'}, {'scalar', '>', 0});
      obj.size = value;
    end
    function set.color(obj,value)
      validateattributes(value, {'numeric'}, {'numel',3,'<=',1,'>=',0});
      obj.color = value;%iris.data.encode.marker.parseColor(value);
    end
    function set.type(obj,value)
      validateattributes(lower(value), {'char'}, {'nonempty'});
      try
        validType = validatestring(value, ...
          {'circle','cross','diamond','square','star','y','triangle','none'} ...
          );
      catch x%#ok
        %log?
        validType = 'none';
      end
      obj.type = validType;
    end
    function set.opacity(obj,value)
      validateattributes(value, {'numeric'}, {'scalar','>=',0,'<=',1});
      obj.opacity = value;
    end
    %% get
    %% get
    function col = get.color(obj)
      col = [obj.color,obj.opacity];
    end
    function sty = get.type(obj)
      switch lower(obj.type)
        case 'circle'
          sty = '.';
        case 'cross'
          sty = 'x';
        case 'diamond'
          sty = 'd';
        case 'square'
          sty = 's';
        case 'star'
          sty = 'p';
        case 'y'
          sty = 'v';
        case 'triangle'
          sty = '^';
        otherwise
          sty = 'none';
      end
    end
  end
  methods (Access = private,Static = true)
    function c = parseColor(vec)
      c = sprintf('rgb(%d,%d,%d)', round(vec.*256));
    end
  end
end