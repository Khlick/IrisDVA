classdef statistics < iris.infra.StoredPrefs

  properties
    GroupBy
    Aggregate
    BaselineZeroing
    BaselinePoints
    BaselineRegion
    ShowOriginal
  end

  methods
    
    % GroupBy
    function v = get.GroupBy(obj)
      v = obj.get('GroupBy',{'None'});
    end

    function set.GroupBy(obj,v)
      validateattributes(v,{'cell'},{'2d'}); 
      obj.put('GroupBy',v);
    end


    % Aggregate
    function v = get.Aggregate(obj)
      v = obj.get('Aggregate','Mean');
    end

    function set.Aggregate(obj,v)
      v = validatestring(v,...
        {'Mean', 'Median', 'Variance', 'Sum'});
      obj.put('Aggregate',v);
    end


    % BaselineZeroing
    function v = get.BaselineZeroing(obj)
      v = obj.get('BaselineZeroing',true);
    end

    function set.BaselineZeroing(obj,v)
      validateattributes(v,{'logical'},{'scalar'});
      obj.put('BaselineZeroing',v);
    end


    % BaselinePoints
    function v = get.BaselinePoints(obj)
      v = obj.get('BaselinePoints',100);
    end

    function set.BaselinePoints(obj,v)
      validateattributes(v,{'numeric'},{'>=',1,'scalar'});
      obj.put('BaselinePoints',fix(v));
    end


    % BaselineRegion
    function v = get.BaselineRegion(obj)
      v = obj.get('BaselineRegion','Beginning');
    end

    function set.BaselineRegion(obj,v)
      v = validatestring(v,{'Beginning', 'End', 'Protocol'});
      obj.put('BaselineRegion',v);
    end
    
    
    % ShowOriginal
    function v = get.ShowOriginal(obj)
      v = obj.get('ShowOriginal',false);
    end

    function set.ShowOriginal(obj,v)
      validateattributes(v,{'logical'},{'scalar'});
      obj.put('ShowOriginal',v);
    end

  end
  
  methods (Static)
    function d = getDefault()
      persistent default;
      if isempty(default) || ~isvalid(default)
        default = iris.pref.statistics();
      end
      d = default;
    end
  end

end

