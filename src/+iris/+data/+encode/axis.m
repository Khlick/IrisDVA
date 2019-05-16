classdef axis < handle

  properties
    title
    zerolinecolor
    zeroline
    scale
    grid
  end
  
  
  methods
    
    function obj = axis(title,scale,grid,zeroline,zerolinecolor)
      % No defaults for title,scale,grid
      if nargin < 5
        zerolinecolor = [1 1 1].*0.6823;
      end
      if nargin < 4
        zeroline = true;
      end
      
      obj.zerolinecolor = zerolinecolor;
      obj.zeroline = zeroline;
      obj.grid = grid;
      obj.scale = scale;
      obj.title = title;
      
    end
    
    function update(obj,varargin)
      ps = inputParser();
      ps.addParameter('title', '', @ischar);
      ps.addParameter('zerolinecolor', [1 1 1].*0.6823, ...
        @(x)validateattributes(x,{'numeric'},{'row','numel',3,'<=',1}) ...
        );
      ps.addParameter('zeroline', true, @islogical);
      ps.addParameter('scale', 'linear', ...
        @(x)ismember(x,{'linear', 'logarithmic'}) ...
        );
      ps.addParameter('grid', false, @islogical);
      
      ps.parse(varargin{:});
      
      toUpdate = ps.Parameters(~ismember(ps.Parameters,ps.UsingDefaults));
      for ix = 1:length(toUpdate)
        par = toUpdate{ix};
        val = ps.Results.(par);
        obj.(par) = val;
      end
      
    end
    
    function s = get.scale(obj)
      switch obj.scale
        case 'linear'
          s = 'linear';
        case 'logarithmic'
          s = 'log';
      end
    end
    
  end
  
  
end

