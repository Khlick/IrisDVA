classdef dsp < iris.infra.StoredPrefs

  properties
    Order
    LowPassFrequency
    HighPassFrequency
    Type
  end

  methods
    
    % Order
    function v = get.Order(obj)
      v = obj.get('Order',7);
    end

    function set.Order(obj,v)
      validateattributes(v,{'numeric'},{'numel',1,'>=',4,'<=',11});
      obj.put('Order',fix(v));
    end


    % LowPassFrequency
    function v = get.LowPassFrequency(obj)
      v = obj.get('LowPassFrequency',100);
    end

    function set.LowPassFrequency(obj,v)
      validateattributes(v,{'numeric'},{'numel',1,'>=',50,'<=',1000});
      obj.put('LowPassFrequency',fix(v));
    end


    % HighPassFrequency
    function v = get.HighPassFrequency(obj)
      v = obj.get('HighPassFrequency',10);
    end

    function set.HighPassFrequency(obj,v)
      validateattributes(v,{'numeric'},{'numel',1,'>=',5,'<=',200});
      obj.put('HighPassFrequency',fix(v));
    end


    % Type
    function v = get.Type(obj)
      v = obj.get('Type','Lowpass');
    end

    function set.Type(obj,v)
      v = validatestring(v,{'Lowpass','Highpass','Bandpass'});
      obj.put('Type',v);
    end

  end
  methods (Static)
    function d = getDefault()
      persistent default;
      if isempty(default) || ~isvalid(default)
        default = iris.pref.dsp();
      end
      d = default;
    end
  end
  
end

