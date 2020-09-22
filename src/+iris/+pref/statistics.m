classdef statistics < iris.infra.StoredPrefs

  properties
    GroupBy
    GroupFields
    SplitDevices
    Aggregate
    BaselineZeroing
    BaselinePoints
    BaselineRegion
    BaselineOffset
    ShowOriginal
    isBaselined
  end

  methods
    
    function obj = statistics()
      obj = obj@iris.infra.StoredPrefs();
      % gather the public visible properties
      this = properties(obj);
      for p = 1:numel(this)
        obj.(this{p}) = obj.(this{p});
      end
      obj.save();
    end

    % GroupBy
    function v = get.GroupBy(obj)
      v = obj.get('GroupBy',{'None'});
    end

    function set.GroupBy(obj,v)
      validateattributes(v,{'cell'},{'2d'}); 
      obj.put('GroupBy',v);
    end
    
    
    % GroupFields
    function v = get.GroupFields(obj)
      v = obj.get('GroupFields',{'None'});
    end

    function set.GroupFields(obj,v)
      validateattributes(v,{'cell'},{'2d'}); 
      obj.put('GroupFields',v);
    end

    % BaselineZeroing
    function v = get.SplitDevices(obj)
      v = obj.get('SplitDevices',true);
    end

    function set.SplitDevices(obj,v)
      validateattributes(v,{'logical'},{'scalar'});
      obj.put('SplitDevices',v);
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
      v = obj.get('BaselineZeroing',false);
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
      v = validatestring(v,{'Beginning', 'End', 'Fit (Asym)', 'Fit (Sym)'});
      obj.put('BaselineRegion',v);
    end
    
    
    % BaselineOffset
    function v = get.BaselineOffset(obj)
      v = obj.get('BaselineOffset',0);
    end

    function set.BaselineOffset(obj,v)
      validateattributes(v,{'numeric'},{'>=',0,'scalar'})
      obj.put('BaselineOffset',fix(v));
    end
    
    
    % ShowOriginal
    function v = get.ShowOriginal(obj)
      v = obj.get('ShowOriginal',false);
    end

    function set.ShowOriginal(obj,v)
      validateattributes(v,{'logical'},{'scalar'});
      obj.put('ShowOriginal',v);
    end
    
    
    % isBaselined
    function v = get.isBaselined(obj)
      v = obj.get('isBaselined',false);
    end

    function set.isBaselined(obj,v)
      validateattributes(v,{'logical','numeric'},{'binary','scalar'});
      obj.put('isBaselined',logical(v));
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

