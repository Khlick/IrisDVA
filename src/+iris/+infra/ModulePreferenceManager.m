classdef (Abstract) ModulePreferenceManager < handle
  
  events
    preferencesReset
    preferencesSaved
  end

  properties (Constant,Hidden)
    PREF_GROUP = 'iris_modules'
    PREF_TYPE = 'module'
  end
  properties (Access=private)
    settingsMap
  end
  properties (Access=protected)
    PREF_KEY
  end

  methods
    % constructor
    function obj = ModulePreferenceManager()
      className = strsplit(class(obj),'.');
      obj.PREF_KEY = matlab.lang.makeValidName(className{end});
      % load the settings map
      storedMap = obj.getStoredPreferences();
      obj.settingsMap = storedMap(obj.PREF_KEY);
    end
    % save preferences to disk
    function save(obj)
      storedMap = obj.getStoredPreferences();
      storedMap(obj.PREF_KEY) = obj.settingsMap;
      setpref(obj.PREF_GROUP,obj.PREF_TYPE,storedMap);
      notify(obj,'preferencesSaved');
    end
    % reset stored preferences
    function reset(obj)
      storedMap = obj.getStoredPreferences();
      storedMap(obj.PREF_KEY) = containers.Map();
      setpref(obj.PREF_GROUP,obj.PREF_TYPE,storedMap);
      obj.settingsMap = storedMap(obj.PREF_KEY);
      notify(obj,'preferencesReset');
    end
    % save on delete
    function delete(obj)
      obj.save();
    end
  end
  
  methods (Abstract,Access=protected)
    loadPreferences(obj)
    savePreferences(obj)
  end

  methods (Access = private)
    
    function storedMap = getStoredPreferences(obj)
      storedMap = getpref(obj.PREF_GROUP,obj.PREF_TYPE,containers.Map());
      if ~storedMap.isKey(obj.PREF_KEY)
        storedMap(obj.PREF_KEY) = containers.Map();
      end
    end

  end

  methods %(Access = protected)

    function v = getPref(obj,key,default)
      if nargin < 3
        default = [];
      end
      if obj.settingsMap.isKey(key)
        v = obj.settingsMap(key);
      else
        v = [];
      end
      if isempty(v)
        v = default;
        obj.putPref(key,v);
      end
    end

    function putPref(obj,key,value)
      obj.settingsMap(key) = value;
    end

    function keys = getPrefKeys(obj)
      keys = string(obj.settingsMap.keys);
    end

  end


end
