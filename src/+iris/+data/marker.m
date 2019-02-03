classdef marker < handle
  
  properties
    type
    size
    color
    opacity
  end
  
  methods
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
    
    %% set/get
    function set.size(obj,value)
      validateattributes(value, {'numeric'}, {'scalar', '>', 0});
      obj.size = value;
    end
    function set.color(obj,value)
      validateattributes(value, {'numeric'}, {'numel',3,'<=',1,'>=',0});
      obj.color = value;
    end
    function set.type(obj,value)
      validateattributes(value, {'char'}, {'nonempty'});
      try
        validType = validatestring(value, ...
          {'circle','cross','diamond','square','star','y','triangle'} ...
          );
      catch x%#ok
        %log?
        validType = 'circle';
      end
      obj.type = validType;
    end
    function set.opacity(obj,value)
      validateattributes(value, {'numeric'}, {'scalar','>=',0,'<=',1});
      obj.opacity = value;
    end
  end
end