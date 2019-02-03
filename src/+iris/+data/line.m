classdef line < handle
  
  properties
    width
    color
    style
    opacity
  end
  
  methods
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
    
    %% set/get
    function set.width(obj,value)
      validateattributes(value, {'numeric'}, {'scalar', '>', 0});
      obj.width = value;
    end
    function set.color(obj,value)
      validateattributes(value, {'numeric'}, {'numel',3,'<=',1,'>=',0});
      obj.color = value;
    end
    function set.style(obj,value)
      validateattributes(value, {'char'}, {'nonempty'});
      try
        type = validatestring(lower(value), ...
          {'solid','dashed','dotted','dashed-dotted'} ...
          );
      catch x%#ok
        %log?
        type = 'solid';
      end
      obj.style = type;
    end
    function set.opacity(obj,value)
      validateattributes(value, {'numeric'}, {'scalar','>=',0,'<=',1});
      obj.opacity = value;
    end
  end
end