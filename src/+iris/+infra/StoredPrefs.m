classdef (Abstract) StoredPrefs < handle
%% STOREDPREFS
% Modified from Settings class at:
% https://github.com/cafarm/appbox/tree/017bb417e6519db79434fd004904a9cee8264303
% TODO: write a way to check if the prefs exist.
  properties (Hidden)
    settingsKey
  end

  properties (Access = private)
    settingsGroup
    settingsPreference
    instanceMap
  end

  methods

    function save(obj)
      settingsMap = getpref(obj.settingsGroup, obj.settingsPreference);
      settingsMap(obj.settingsKey) = obj.instanceMap;
      setpref(obj.settingsGroup, obj.settingsPreference, settingsMap);
    end

    function reset(obj)
      settingsMap = getpref(obj.settingsGroup, obj.settingsPreference);
      settingsMap(obj.settingsKey) = containers.Map();
      setpref(obj.settingsGroup, obj.settingsPreference, settingsMap);
      obj.instanceMap = settingsMap(obj.settingsKey);
    end
    
    function delete(obj)
      obj.save();
      pause(0.001);
    end
    
  end

  methods (Access = protected)

    function obj = StoredPrefs()
      split = strsplit(class(obj), '.');
      settingsGroup = split{1};
      settingsKey = matlab.lang.makeValidName(class(obj));
      obj.settingsGroup = settingsGroup;
      obj.settingsPreference = matlab.lang.makeValidName(class(obj));
      obj.settingsKey = settingsKey;
      settingsMap = getpref(obj.settingsGroup, obj.settingsPreference, containers.Map());
      if ~settingsMap.isKey(settingsKey)
        settingsMap(settingsKey) = containers.Map();
      end
      obj.instanceMap = settingsMap(settingsKey);
    end

    function tf = isKey(obj, key)
      tf = obj.instanceMap.isKey(key);
    end

    function v = get(obj, key, default)
      if nargin < 3
        default = [];
      end
      if obj.instanceMap.isKey(key)
        v = obj.instanceMap(key);
      else
        v = [];
      end
      if isempty(v)
        v = default;
        obj.put(key,v);
      end
    end

    function put(obj, key, value)
      obj.instanceMap(key) = value;
    end
    
  end

end
