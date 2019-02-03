classdef Iris < iris.infra.StoredPrefs

  properties
    UserDirectory
  end
  
  methods
    
    function d = get.UserDirectory(obj)
      d = obj.get('UserDirectory', iris.app.Info.getUserPath());
    end
    
    function set.UserDirectory(obj,d)
      validateattributes(d,{'char'}, {'nonempty'});
      obj.put('UserDirectory', d);
    end
    
  end
  
  methods (Static)
    
    function d = getDefault()
      persistent default;
      if isempty(default) || ~isvalid(default)
        default = iris.pref.Iris();
      end
      d = default;
    end
    
  end
  
end
