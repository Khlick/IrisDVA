classdef analysis < iris.infra.StoredPrefs

  properties
    OutputDirectory
    AnalysisDirectory
    AnalysisPrefix
  end

  methods
    
    % OutputDirectory
    function v = get.OutputDirectory(obj)
      v = obj.get('OutputDirectory',...
        fullfile(iris.app.Info.getUserPath,'Iris', 'Output'));
    end

    function set.OutputDirectory(obj,v)
      validateattributes(v,{'char'}, {'scalartext'});
      obj.put('OutputDirectory',v);
    end


    % AnalysisDirectory
    function v = get.AnalysisDirectory(obj)
      v = obj.get('AnalysisDirectory', ...
        fullfile(iris.app.Info.getUserPath,'Iris', 'Analyses'));
    end

    function set.AnalysisDirectory(obj,v)
      validateattributes(v,{'char'}, {'scalartext'});
      obj.put('AnalysisDirectory',v);
    end


    % AnalysisPrefix
    function v = get.AnalysisPrefix(obj)
      v = obj.get('AnalysisPrefix',...
        @()sprintf('Analyzed_%s',datestr(now, 'YYYYmmmDD_HHMMSS'))...
        );
    end

    function set.AnalysisPrefix(obj,v)
      validateattributes(v,{'function_handle'},{'2d'});
      obj.put('AnalysisPrefix',v);
    end

    
  end
  
  methods (Static)
    function d = getDefault()
      persistent default;
      if isempty(default) || ~isvalid(default)
        default = iris.pref.analysis();
      end
      d = default;
    end
  end
end

