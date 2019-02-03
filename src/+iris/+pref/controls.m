classdef controls < iris.infra.StoredPrefs

  properties
    StepSmall
    StepBig
    OverlaySmall
    OverlayBig
  end

  methods
    
    % StepSmall
    function v = get.StepSmall(obj)
      v = obj.get('StepSmall',1);
    end

    function set.StepSmall(obj,v)
      validateattributes(v,{'numeric'},{'numel',1,'>=',1,'<=',100});
      obj.put('StepSmall',v);
    end


    % StepBig
    function v = get.StepBig(obj)
      v = obj.get('StepBig',10);
    end

    function set.StepBig(obj,v)
      validateattributes(v,{'numeric'},{'numel',1,'>=',1,'<=',100});
      obj.put('StepBig',v);
    end


    % OverlaySmall
    function v = get.OverlaySmall(obj)
      v = obj.get('OverlaySmall',1);
    end

    function set.OverlaySmall(obj,v)
      validateattributes(v,{'numeric'},{'numel',1,'>=',1,'<=',100});
      obj.put('OverlaySmall',v);
    end


    % OverlayBig
    function v = get.OverlayBig(obj)
      v = obj.get('OverlayBig',5);
    end

    function set.OverlayBig(obj,v)
      validateattributes(v,{'numeric'},{'numel',1,'>=',1,'<=',100});
      obj.put('OverlayBig',v);
    end
    
  end
  
  methods (Static)
    function d = getDefault()
      persistent default;
      if isempty(default) || ~isvalid(default)
        default = iris.pref.controls();
      end
      d = default;
    end
  end
  
end