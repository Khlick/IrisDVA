classdef analysis < iris.infra.StoredPrefs

  properties
    OutputDirectory
    AnalysisDirectory
    AnalysisPrefix
    ExternalReadersDirectory
    ExternalModulesDirectory
    AppendAnalysis
    SendToCommandWindow
  end

  methods

    function obj = analysis()
      obj = obj@iris.infra.StoredPrefs();
      % gather the public visible properties
      this = properties(obj);

      for p = 1:numel(this)
        obj.(this{p}) = obj.(this{p});
      end

      obj.save();
    end

    % OutputDirectory
    function v = get.OutputDirectory(obj)
      v = obj.get('OutputDirectory', ...
        fullfile(iris.app.Info.getUserPath, 'Iris', 'Output'));
    end

    function set.OutputDirectory(obj, v)
      validateattributes(v, {'char'}, {'scalartext'});
      obj.put('OutputDirectory', v);
    end

    % AnalysisDirectory
    function v = get.AnalysisDirectory(obj)
      v = obj.get('AnalysisDirectory', ...
        fullfile(iris.app.Info.getUserPath, 'Iris', 'Analyses'));
    end

    function set.AnalysisDirectory(obj, v)
      validateattributes(v, {'char'}, {'scalartext'});
      obj.put('AnalysisDirectory', v);
    end

    % AnalysisPrefix
    function v = get.AnalysisPrefix(obj)
      v = obj.get('AnalysisPrefix', ...
        @()sprintf('Analyzed_%s', datestr(now, 'YYYYmmmDD_HHMMSS')) ...
      );
    end

    function set.AnalysisPrefix(obj, v)
      validateattributes(v, {'function_handle'}, {'2d'});
      obj.put('AnalysisPrefix', v);
    end

    % ExternalReadersDirectory
    function v = get.ExternalReadersDirectory(obj)
      v = obj.get('ExternalReadersDirectory', ...
        fullfile(iris.app.Info.getUserPath, 'Iris', 'Readers'));
    end

    function set.ExternalReadersDirectory(obj, v)
      validateattributes(v, {'char'}, {'scalartext'});
      obj.put('ExternalReadersDirectory', v);
    end

    % ExternalModulesDirectory
    function v = get.ExternalModulesDirectory(obj)
      v = obj.get('ExternalModulesDirectory', ...
        fullfile(iris.app.Info.getUserPath, 'Iris', 'Modules'));
    end

    function set.ExternalModulesDirectory(obj, v)
      validateattributes(v, {'char'}, {'scalartext'});
      obj.put('ExternalModulesDirectory', v);
    end

    % AppendAnalysis
    function v = get.AppendAnalysis(obj)
      v = obj.get('AppendAnalysis', "ask");
    end

    function set.AppendAnalysis(obj, v)

      arguments
        obj
        v (1, 1) string {mustBeMember(v, ["yes", "no", "ask"])} = "ask"
      end

      obj.put('AppendAnalysis', v);
    end

    % AppendAnalysis
    function v = get.SendToCommandWindow(obj)
      v = obj.get('SendToCommandWindow', false);
    end

    function set.SendToCommandWindow(obj, v)

      arguments
        obj
        v (1, 1) logical = false
      end

      obj.put('SendToCommandWindow', v);
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
