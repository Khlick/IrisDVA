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
    v = struct();
    v.StepSmall = obj.c.StepSmall;
    v.StepBig = obj.c.StepBig;
    v.OverlaySmall = obj.c.OverlaySmall;
    v.OverlayBig = obj.c.OverlayBig;
  end

  function set.ControlProps(obj,v)
    validateattributes(v,{'struct'},{'scalar'});
    fnames = fieldnames(v);
    fnames = fnames(contains(fnames,properties(obj.c)));
    for nm = fnames(:)'
      obj.c.(nm{1}) = v.(nm{1});
    end
  end


  % AnalysisProps
  function v = get.AnalysisProps(obj)
    v = struct();
    v.OutputDirectory = obj.a.OutputDirectory;
    v.AnalysisDirectory = obj.a.AnalysisDirectory;
    v.AnalysisPrefix = obj.a.AnalysisPrefix;
  end

  function set.AnalysisProps(obj,v)
    validateattributes(v,{'struct'},{'scalar'});
    fnames = fieldnames(v);
    fnames = fnames(contains(fnames,properties(obj.a)));
    for nm = fnames(:)'
      obj.a.(nm{1}) = v.(nm{1});
    end
  end


  % DisplayProps
  function v = get.DisplayProps(obj)
    v = struct();
    v.LineStyle = obj.d.LineStyle;
    v.LineWidth = obj.d.LineWidth;
    v.Marker = obj.d.Marker;
    v.MarkerSize = obj.d.MarkerSize;
    v.XScale = obj.d.XScale;
    v.YScale = obj.d.YScale;
    v.Grid = obj.d.Grid;
  end

  function set.DisplayProps(obj,v)
    validateattributes(v,{'struct'},{'scalar'});
    fnames = fieldnames(v);
    fnames = fnames(contains(fnames,properties(obj.d)));
    for nm = fnames(:)'
      obj.d.(nm{1}) = v.(nm{1});
    end
  end


  % FilterProps
  function v = get.FilterProps(obj)
    v = struct();
    v.Order = obj.f.Order;
    v.LowPassFrequency = obj.f.LowPassFrequency;
    v.HighPassFrequency = obj.f.HighPassFrequency;
    v.Type = obj.f.Type;
  end

  function set.FilterProps(obj,v)
    validateattributes(v,{'struct'},{'scalar'});
    fnames = fieldnames(v);
    fnames = fnames(contains(fnames,properties(obj.f)));
    for nm = fnames(:)'
      obj.f.(nm{1}) = v.(nm{1});
    end
  end


  % StatisticsProps
  function v = get.StatisticsProps(obj)
    v = struct();
    v.GroupBy = obj.st.GroupBy;
    v.Aggregate = obj.st.Aggregate;
    v.BaselineZeroing = obj.st.BaselineZeroing;
    v.BaselinePoints = obj.st.BaselinePoints;
    v.BaselineRegion = obj.st.BaselineRegion;
    v.ShowOriginal = obj.st.ShowOriginal;
  end

  function set.StatisticsProps(obj,v)
    validateattributes(v,{'struct'},{'scalar'});
    fnames = fieldnames(v);
    fnames = fnames(contains(fnames,properties(obj.st)));
    for nm = fnames(:)'
      obj.st.(nm{1}) = v.(nm{1});
    end
  end


  % ScaleProps
  function v = get.ScaleProps(obj)
    v = struct();
    v.Value = obj.sc.Value;
    v.Method = obj.sc.Method;
  end

  function set.ScaleProps(obj,v)
    validateattributes(v,{'struct'},{'scalar'});
    fnames = fieldnames(v);
    fnames = fnames(contains(fnames,properties(obj.sc)));
    for nm = fnames(:)'
      obj.sc.(nm{1}) = v.(nm{1});
    end
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

end

