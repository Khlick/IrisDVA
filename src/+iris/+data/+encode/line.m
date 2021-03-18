classdef line < handle
  
  properties
    width
    color
    style
    opacity
  end
  
  methods
    % Constructor
    function obj = line(w,c,s,o)
      if nargin < 4, o = 1; end
      if nargin < 3, s = 'solid'; end
      if nargin < 2, c = iris.app.Aes.appColor(1,'contrast'); end
      if nargin < 1, w = 5; end
      obj.width = w;
      obj.color = c;
      obj.style = s;
      obj.opacity = o;
    end
    % Convenience Collecter
    function S = collect(obj)
      S = struct( ...
        'LineWidth', obj.width, ...
        'LineStyle', obj.style, ...
        'LineJoin', 'miter' ...
        );
    end
    %% set
    function set.width(obj,value)
      validateattributes(value, {'numeric'}, {'scalar', '>', 0});
      obj.width = value;
    end
    function set.color(obj,value)
      validateattributes(value, {'numeric'}, {'numel',3,'<=',1,'>=',0});
      obj.color = value;%iris.data.encode.line.parseColor(value);
    end
    function set.style(obj,value)
      validateattributes(value, {'char'}, {'nonempty'});
      try
        type = validatestring(lower(value), ...
          {'solid','dashed','dotted','dashed-dotted','none'} ...
          );
      catch x %#ok
        %log?
        type = 'solid';
      end
      obj.style = type;
    end
    function set.opacity(obj,value)
      validateattributes(value, {'numeric'}, {'scalar','>=',0,'<=',1});
      obj.opacity = value;
    end
    %% get
    function col = get.color(obj)
      col = [obj.color,obj.opacity];
    end
    function sty = get.style(obj)
      switch lower(obj.style)
        case 'none' 
          sty = 'none';
        case 'solid'
          sty = '-';
        case 'dotted'
          sty = ':';
        case 'dashed'
          sty = '--';
        case 'dash-dotted'
          sty = '-.';
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