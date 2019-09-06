function setContainerPrefs(obj)
  setContainerPrefs@iris.ui.UIContainer(obj);
  selectedNodes = obj.PreferencesTree.SelectedNodes;
  if isempty(selectedNodes),selectedNodes = struct('Text','');end
  obj.put('SelectedNodes', selectedNodes.Text);
  %apply options values to objects
  Control = obj.options.ControlProps;
  Analysis = obj.options.AnalysisProps;
  Display = obj.options.DisplayProps;
  Signal = obj.options.FilterProps;
  Stats = obj.options.StatisticsProps;
  Scale = obj.options.ScaleProps;
  %% Controls
  Control.StepSmall = obj.EpochStepSmallInput.Value;
  Control.StepBig = obj.EpochStepBigInput.Value;
  Control.OverlaySmall= obj.OverlaySmallInput.Value;
  Control.OverlayBig = obj.OverlayBigInput.Value;
  %% Display
  Display.LineStyle = obj.LineStyle.Value;
  Display.LineWidth = obj.LineWidth.Value;
  Display.LineWidth = obj.LineWidthSlider.Value;
  Display.Marker = obj.MarkerStyle.Value;
  Display.MarkerSize = obj.MarkerSize.Value;
  Display.MarkerSize = obj.MarkerSizeSlider.Value;
  Display.XScale = obj.AxesScaleX.Value;
  Display.YScale = obj.AxesScaleY.Value;
  Display.Grid = obj.Grid.Value;
  %% Workspace
  Analysis.OutputDirectory = obj.OutputDirectoryInput.Value;
  Analysis.AnalysisDirectory = obj.AnalysisDirectoryInput.Value;
  Analysis.ExternalModulesDirectory = obj.ModulesDirectoryInput.Value;
  Analysis.ExternalReadersDirectory = obj.ReadersDirectoryInput.Value;
  % prefix handler
  pfx = obj.AnalysisPrefixInput.Value;
  if ~strcmpi(pfx(1),'@')
    pfx = ['@()',pfx];
  end
  nIter = 0;
  while true
    nIter = nIter+1;
    pfxx = str2func(pfx);
    try
      pfxx();
    catch exception
      if nIter > 5, rethrow(exception); end
      if contains(lower(exception.identifier), 'undefined')
        % like a string was entered only
        pfx = sprintf('@()''%s''',pfx(4:end));
        continue;
      else
        rethrow(exception);  
      end
    end
    break;
  end
  Analysis.AnalysisPrefix = pfxx;
  %% Filter
  Signal.Order = str2double(obj.FilterOrderSelect.Value);
  Signal.LowPassFrequency = str2double(obj.FilterFrequencyLowSelect.Value);
  Signal.HighPassFrequency = str2double(obj.FilterFrequencyHighSelect.Value);
  Signal.Type = obj.FilterTypeSelect.Value;
  %% Statistics
  Stats.Aggregate = obj.AggregationStatisticSelect.Value;
  Stats.BaselinePoints = obj.BaselinePoints.Value;
  Stats.BaselineRegion = obj.BaselineRegionSelect.Value;
  Stats.BaselineOffset = obj.OffsetPoints.Value;
  Stats.BaselineZeroing = obj.ZeroBaseline.Value;
  Stats.SplitDevices = true;%obj.SplitDevices.Value;
  Stats.ShowOriginal = obj.ShowAll.Value;
  Stats.GroupBy = obj.GroupBySelect.Value;
  %% Scale
  Scale.Method = obj.ScaleMethodSelect.Value;
  Scale.Value = obj.ScaleValue.Data;
  %% STORE
  obj.options.ControlProps = Control ;
  obj.options.AnalysisProps = Analysis ;
  obj.options.DisplayProps = Display ;
  obj.options.FilterProps = Signal ;
  obj.options.StatisticsProps = Stats ;
  obj.options.ScaleProps = Scale ;
  %% SAVE
  % writes prefs to memory
  obj.save();
end