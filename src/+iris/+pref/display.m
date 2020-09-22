classdef display < iris.infra.StoredPrefs

  properties
    LineStyle
    LineWidth
    Marker
    MarkerSize
    XScale
    YScale
    Grid
  end
  
  methods
    
    function obj = display()
      obj = obj@iris.infra.StoredPrefs();
      % gather the public visible properties
      this = properties(obj);
      for p = 1:numel(this)
        obj.(this{p}) = obj.(this{p});
      end
      obj.save();
    end

    % LineStyle
    function v = get.LineStyle(obj)
      v = obj.get('LineStyle','Solid');
    end

    function set.LineStyle(obj,v)
      v = validatestring(v,...
        {'Solid', 'Dashed', 'Dotted', 'Dash-Dotted', 'None'});
      obj.put('LineStyle',v);
    end


    % LineWidth
    function v = get.LineWidth(obj)
      v = obj.get('LineWidth',2.0);
    end

    function set.LineWidth(obj,v)
      validateattributes(v,{'numeric'},{'numel',1,'>=',0.5,'<=',5.0});
      obj.put('LineWidth',v);
    end


    % Marker
    function v = get.Marker(obj)
      v = obj.get('Marker','None');
    end

    function set.Marker(obj,v)
      v = validatestring(v,...
        {'Circle','Cross','Diamond','Square','Star','Y','Triangle','None'});
      obj.put('Marker',v);
    end


    % MarkerSize
    function v = get.MarkerSize(obj)
      v = obj.get('MarkerSize',8.0);
    end

    function set.MarkerSize(obj,v)
      validateattributes(v,{'numeric'},{'numel',1,'>=',1.0,'<=',30.0});
      obj.put('MarkerSize',v);
    end


    % XScale
    function v = get.XScale(obj)
      v = obj.get('XScale','Linear');
    end

    function set.XScale(obj,v)
      v = validatestring(v,{'Linear','Logarithmic'});
      obj.put('XScale',v);
    end


    % YScale
    function v = get.YScale(obj)
      v = obj.get('YScale','Linear');
    end

    function set.YScale(obj,v)
      v = validatestring(v,{'Linear','Logarithmic'});
      obj.put('YScale',v);
    end


    % Grid
    function v = get.Grid(obj)
      v = obj.get('Grid','None');
    end

    function set.Grid(obj,v)
      v = validatestring(v,{'None', 'X Axis', 'Y Axis', 'Both'});
      obj.put('Grid',v);
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

