function getContainerPrefs(obj)
  getContainerPrefs@iris.ui.UIContainer(obj);
  %apply options values to objects
  Control = obj.options.ControlProps;
  Analysis = obj.options.AnalysisProps;
  Display = obj.options.DisplayProps;
  Signal = obj.options.FilterProps;
  Stats = obj.options.StatisticsProps;
  Scale = obj.options.ScaleProps;
  %% Controls
  obj.EpochStepSmallInput.Value = Control.StepSmall;
  obj.EpochStepBigInput.Value = Control.StepBig;
  obj.OverlaySmallInput.Value = Control.OverlaySmall;
  obj.OverlayBigInput.Value = Control.OverlayBig;
  %% Display
  obj.LineStyle.Value = Display.LineStyle;
  obj.LineWidth.Value = Display.LineWidth;
  obj.LineWidthSlider.Value = Display.LineWidth;
  obj.MarkerStyle.Value = Display.Marker;
  obj.MarkerSize.Value = Display.MarkerSize;
  obj.MarkerSizeSlider.Value = Display.MarkerSize;
  obj.AxesScaleX.Value = Display.XScale;
  obj.AxesScaleY.Value = Display.YScale;
  obj.Grid.Value = Display.Grid;
  %% Workspace
  obj.OutputDirectoryInput.Value = Analysis.OutputDirectory;
  obj.AnalysisDirectoryInput.Value = Analysis.AnalysisDirectory;
  obj.AnalysisPrefixInput.Value = func2str(Analysis.AnalysisPrefix);
  %% Filter
  obj.FilterOrderSelect.Value = sprintf('%d', Signal.Order);
  obj.FilterFrequencyLowSelect.Value = sprintf('%d', Signal.LowPassFrequency);
  obj.FilterFrequencyHighSelect.Value = sprintf('%d', Signal.HighPassFrequency);
  obj.FilterTypeSelect.Value = Signal.Type;
  %% Statistics
  obj.AggregationStatisticSelect.Value = Stats.Aggregate;
  obj.BaselinePoints.Value = Stats.BaselinePoints;
  obj.BaselineRegionSelect.Value = Stats.BaselineRegion;
  obj.ZeroBaseline.Value = Stats.BaselineZeroing;
  obj.ShowAll.Value = Stats.ShowOriginal;
  %% Scaling
  obj.ScaleMethodSelect.Value = Scale.Method;
  obj.ScaleValue.Value = Scale.Value;
  %% Last Selected Pref
  nodeText = obj.get('SelectedNode', '');
  if ~isempty(nodeText)
   try
    obj.PreferencesTree.SelectedNodes = obj.([nodeText,'Node']);
    obj.PageActivation([],[]);
   catch x %#ok
     %log x
   end
  end
  %% Update dependent UI
  obj.validatePrefix(obj.AnalysisPrefixInput,[]);
end