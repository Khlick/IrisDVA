classdef Iris < iris.infra.StoredPrefs

  properties
    UserDirectory
    PreviousExtension
    CurrentVersion
  end
  
  methods
    
    function d = get.UserDirectory(obj)
      d = obj.get('UserDirectory', iris.app.Info.getUserPath());
    end
    
    function set.UserDirectory(obj,d)
      validateattributes(d,{'char'}, {'nonempty'});
      obj.put('UserDirectory', d);
    end
    
    function d = get.PreviousExtension(obj)
      d = obj.get('PreviousExtension', '*.h5');
    end
    
    function set.PreviousExtension(obj,d)
      validateattributes(d,{'cell','char'}, {'nonempty'});
      obj.put('PreviousExtension', d);
    end
    
    function d = get.CurrentVersion(obj)
      d = obj.get('CurrentVersion', iris.app.Info.version);
    end
    
    function set.CurrentVersion(obj,d)
      validateattributes(d,{'char'}, {'nonempty'});
      obj.put('CurrentVersion', d);
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
