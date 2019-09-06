classdef scales < iris.infra.StoredPrefs

  properties
    Method
    Value
    isScaled
  end
  
  methods
    
    % Method
    function v = get.Method(obj)
      v = obj.get('Method','Absolute Max');
    end

    function set.Method(obj,v)
      v = validatestring(v, ...
        {'Absolute Max', 'Max', 'Min', 'Custom', 'Select'});
      obj.put('Method',v);
    end

    % Value
    function v = get.Value(obj)
      v = obj.get('Value',{'(unknown)', 1});
    end

    function set.Value(obj,v)
      validateattributes(v, {'cell'},{'nonempty','size',[NaN,2]})
      obj.put('Value',v);
    end
    
    % isScaled
    function v = get.isScaled(obj)
      v = obj.get('isScaled',false);
    end

    function set.isScaled(obj,v)
      validateattributes(v,{'logical','numeric'},{'binary','scalar'});
      obj.put('isScaled',logical(v));
    end

  end

  methods (Static)
    function d = getDefault()
      persistent default;
      if isempty(default) || ~isvalid(default)
        default = iris.pref.scales();
      end
      d = default;
    end
  end
  
end

