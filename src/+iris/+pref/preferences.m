classdef preferences < handle
  %PREFERENCES These preferences can be overwritten from here.
  %   Preferences here will serve as a default override for the preferences
  %   located in the stored prefs from iris.ui.preferences. Also, some
  %   preference changes cannot be applied until restart (like setting
  %   colormap and color order of the main axes), this will be the unifying
  %   location for any of those preferences.
  properties (Access = private)
    c
    a
    d
    f
    st
    sc
  end
  
  properties (Dependent)
  ControlProps
  AnalysisProps
  DisplayProps
  FilterProps
  StatisticsProps
  ScaleProps
end


methods
  
  function obj = preferences()
    obj.c = iris.pref.controls.getDefault();
    obj.a = iris.pref.analysis.getDefault();
    obj.d = iris.pref.display.getDefault();
    obj.f = iris.pref.dsp.getDefault();
    obj.st = iris.pref.statistics.getDefault();
    obj.sc = iris.pref.scales.getDefault();
  end
  
  % ControlProps
  function v = get.ControlProps(obj)
    v = iris.pref.preferences.getPropStruct(obj.c);
  end

  function set.ControlProps(obj,v)
    validateattributes(v,{'struct'},{'scalar'});
    iris.pref.preferences.setPropStruct(obj.c,v);
  end


  % AnalysisProps
  function v = get.AnalysisProps(obj)
    v = iris.pref.preferences.getPropStruct(obj.a);
  end

  function set.AnalysisProps(obj,v)
    validateattributes(v,{'struct'},{'scalar'});
    iris.pref.preferences.setPropStruct(obj.a,v);
  end


  % DisplayProps
  function v = get.DisplayProps(obj)
    v = iris.pref.preferences.getPropStruct(obj.d);
  end

  function set.DisplayProps(obj,v)
    validateattributes(v,{'struct'},{'scalar'});
    iris.pref.preferences.setPropStruct(obj.d,v);
  end


  % FilterProps
  function v = get.FilterProps(obj)
    v = iris.pref.preferences.getPropStruct(obj.f);
  end

  function set.FilterProps(obj,v)
    validateattributes(v,{'struct'},{'scalar'});
    iris.pref.preferences.setPropStruct(obj.f,v);
  end


  % StatisticsProps
  function v = get.StatisticsProps(obj)
    v = iris.pref.preferences.getPropStruct(obj.st);
  end

  function set.StatisticsProps(obj,v)
    validateattributes(v,{'struct'},{'scalar'});
    iris.pref.preferences.setPropStruct(obj.st,v);
  end


  % ScaleProps
  function v = get.ScaleProps(obj)
    v = iris.pref.preferences.getPropStruct(obj.sc);
  end

  function set.ScaleProps(obj,v)
    validateattributes(v,{'struct'},{'scalar'});
    iris.pref.preferences.setPropStruct(obj.sc,v);
  end

end

methods
  function save(obj)
    obj.c.save();
    obj.a.save();
    obj.d.save();
    obj.f.save();
    obj.st.save();
    obj.sc.save();
  end
  
  function reset(obj,whichPref)
    if nargin < 2
      whichPref = {'c','a','d','f','st','sc'};
    end
    if ischar(whichPref), whichPref = cellstr(whichPref); end
    for prop = whichPref(:)'
      try
        p = validatestring(prop{1},{'c','a','d','f','st','sc'});
      catch
        continue
      end
      obj.(p).reset();
    end
    
  end
end


methods (Static)
  function s = getPropStruct(pObj)
    s = struct();
    names = string(properties(pObj))';
    for name = names
      s.(name) = pObj.(name);
    end
  end
  
  function setPropStruct(pObj, v)
    fnames = fieldnames(v);
    fnames = string(fnames(contains(fnames,properties(pObj))));
    for nm = fnames(:)'
      pObj.(nm) = v.(nm);
    end
    pObj.save();
  end
end

end

