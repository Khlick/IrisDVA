classdef Iris < iris.infra.StoredPrefs

  properties
    UserDirectory
    PreviousExtension
    CurrentVersion
    LastSavedDirectory
    HelpersDirectory
  end
  
  methods
    
    function obj = Iris()
      obj = obj@iris.infra.StoredPrefs();
      % gather the public visible properties
      this = properties(obj);
      for p = 1:numel(this)
        obj.(this{p}) = obj.(this{p});
      end
      obj.save();
    end

    function d = get.UserDirectory(obj)
      d = obj.get('UserDirectory', iris.app.Info.getUserPath());
    end
    
    function set.UserDirectory(obj,d)
      validateattributes(d,{'char','string'}, {'nonempty'});
      obj.put('UserDirectory', d);
    end
    
    function d = get.PreviousExtension(obj)
      d = obj.get('PreviousExtension', '*.h5');
    end
    
    function set.PreviousExtension(obj,d)
      validateattributes(d,{'cell','char','string'}, {'nonempty'});
      obj.put('PreviousExtension', d);
    end
    
    function d = get.CurrentVersion(obj)
      d = obj.get('CurrentVersion', iris.app.Info.version);
    end
    
    function set.CurrentVersion(obj,d) %#ok
      % for d to be the current version
      d = iris.app.Info.version;
      obj.put('CurrentVersion', d);
    end
    
    function d = get.LastSavedDirectory(obj)
      d = obj.get('LastSavedDirectory', iris.app.Info.getUserPath());
    end
    
    function set.LastSavedDirectory(obj,d)
      validateattributes(d,{'char','string'}, {});
      if isempty(d)
        d = iris.app.Info.getUserPath();
      end
      obj.put('LastSavedDirectory', d);
    end
    
    function d = get.HelpersDirectory(obj)
      d = obj.get('HelpersDirectory', '');
    end
    
    function set.HelpersDirectory(obj,d)
      validateattributes(d,{'char','string'}, {});
      obj.put('HelpersDirectory', d);
    end
    
  end
  
  methods (Static)
    
    function d = getDefault()
      % force init of each default if class doesn't exist.
      persistent default;
      if isempty(default) || ~isvalid(default)
        default = iris.pref.Iris();
      end
      d = default;
    end
    
  end
  
end
