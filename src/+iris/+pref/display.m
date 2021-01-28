classdef display < iris.infra.StoredPrefs

  properties (Dependent)
    LineStyle
    LineWidth
    Marker
    MarkerSize
    XScale
    YScale
    Grid
    Decimate
    DecimationFactor
  end
  
  properties (Dependent=true,Hidden=true)
    LineStyleDomain
    LineWidthDomain
    MarkerStyleDomain
    MarkerSizeDomain
    ScaleDomain
    GridDomain
    DecimateDomain
  end
  
  methods
    
    function obj = display() %#ok<DISPLAY> parser doesn't know this isn't overloading
      obj = obj@iris.infra.StoredPrefs();
      % gather the public visible properties
      this = properties(obj);
      for p = 1:numel(this)
        obj.(this{p}) = obj.(this{p});
      end
      obj.save();
    end
    
    %% Domains
    
    % LineStyle
    function v = get.LineStyleDomain(obj)
      v = obj.get('LineStyleDomain',{'Solid', 'Dashed', 'Dotted', 'Dash-Dotted', 'None'});
    end

    function set.LineStyleDomain(obj,v) %#ok<*INUSD>
      error("Cannot set domain.");
    end
    
    
    % LineWidth
    function v = get.LineWidthDomain(obj)
      v = obj.get('LineWidthDomain',[0.5,5.0]);
    end

    function set.LineWidthDomain(obj,v)
      error("Cannot set domain.");
    end
    
    
    % MarkerStyle
    function v = get.MarkerStyleDomain(obj)
      v = obj.get( ...
        'MarkerStyleDomain', ...
        {'None','Circle','Cross','Diamond','Square','Star','Y','Triangle'} ...
        );
    end

    function set.MarkerStyleDomain(obj,v)
      error("Cannot set domain.");
    end
    
    
    % MarkerSize
    function v = get.MarkerSizeDomain(obj)
      v = obj.get('MarkerSizeDomain',[1,35]);
    end

    function set.MarkerSizeDomain(obj,v)
      error("Cannot set domain.");
    end
    
    
    % ScaleDomain
    function v = get.ScaleDomain(obj)
      v = obj.get('ScaleDomain',{'Linear','Logarithmic'});
    end

    function set.ScaleDomain(obj,v)
      error("Cannot set domain.");
    end
    
    
    % GridDomain
    function v = get.GridDomain(obj)
      v = obj.get('GridDomain',{'None', 'X Axis', 'Y Axis', 'Both'});
    end

    function set.GridDomain(obj,v)
      error("Cannot set domain.");
    end
    
    
    % DecimateDomain
    function v = get.DecimateDomain(obj)
      v = obj.get('DecimateDomain',[uint16(1),intmax('uint16')]);
    end

    function set.DecimateDomain(obj,v)
      error("Cannot set domain.");
    end
    
    
    %% Values
    % LineStyle
    function v = get.LineStyle(obj)
      dom = obj.LineStyleDomain;
      v = obj.get('LineStyle',dom{1});
    end

    function set.LineStyle(obj,v)
      v = validatestring(v, obj.LineStyleDomain);
      obj.put('LineStyle',v);
    end


    % LineWidth
    function v = get.LineWidth(obj)
      v = obj.get('LineWidth',2.0);
    end

    function set.LineWidth(obj,v)
      dom = obj.LineWidthDomain;
      validateattributes(v,{'numeric'},{'numel',1,'>=',dom(1),'<=',dom(2)});
      obj.put('LineWidth',v);
    end


    % Marker
    function v = get.Marker(obj)
      dom = obj.MarkerStyleDomain;
      v = obj.get('Marker',dom{1});
    end

    function set.Marker(obj,v)
      v = validatestring(v,obj.MarkerStyleDomain);
      obj.put('Marker',v);
    end


    % MarkerSize
    function v = get.MarkerSize(obj)
      v = obj.get('MarkerSize',8.0);
    end

    function set.MarkerSize(obj,v)
      dom = obj.MarkerSizeDomain;
      validateattributes(v,{'numeric'},{'numel',1,'>=',dom(1),'<=',dom(2)});
      obj.put('MarkerSize',v);
    end


    % XScale
    function v = get.XScale(obj)
      dom = obj.ScaleDomain;
      v = obj.get('XScale',dom{1});
    end

    function set.XScale(obj,v)
      v = validatestring(v,obj.ScaleDomain);
      obj.put('XScale',v);
    end


    % YScale
    function v = get.YScale(obj)
      dom = obj.ScaleDomain;
      v = obj.get('YScale',dom{1});
    end

    function set.YScale(obj,v)
      v = validatestring(v,obj.ScaleDomain);
      obj.put('YScale',v);
    end


    % Grid
    function v = get.Grid(obj)
      dom = obj.GridDomain;
      v = obj.get('Grid',dom{1});
    end

    function set.Grid(obj,v)
      v = validatestring(v,obj.GridDomain);
      obj.put('Grid',v);
    end

    
    % Decimate
    function tf = get.Decimate(obj)
      tf = obj.get('Decimate',false);
    end
    
    function set.Decimate(obj,tf)
      v = logical(tf);
      validateattributes(v,{'logical'},{'numel',1});
      obj.put('Decimate',v);
    end
    
    % DecimationFactor
    function v = get.DecimationFactor(obj)
      v = obj.get('DecimationFactor', uint16(10));
    end
    
    function set.DecimationFactor(obj,v)
      dom = obj.DecimateDomain;
      v = uint16(v);
      validateattributes(v,{'uint16'},{'numel',1,'>',dom(1),'<=',dom(2)});
      obj.put('DecimationFactor',uint16(v));
    end
    
  end
  methods (Static)
    function d = getDefault()
      persistent default;
      if isempty(default) || ~isvalid(default)
        default = iris.pref.display();
      end
      d = default;
    end
  end
  
end

