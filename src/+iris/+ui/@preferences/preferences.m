classdef preferences < iris.ui.UIContainer
%PREFERENCES Preferences window. 

events
  AxesChanged
  DisplayChanged
  FilterChanged
  StatisticsChanged
  ScalingChanged
end

% Properties that correspond to app components
properties (Access = public)
  PreferencesLabel               matlab.ui.control.Label
  PreferencesTree                matlab.ui.container.Tree
  NavigationNode                 matlab.ui.container.TreeNode
  KeyboardNode                   matlab.ui.container.TreeNode
  ControlNode                    matlab.ui.container.TreeNode
  WorkspaceNode                  matlab.ui.container.TreeNode
  VariablesNode                  matlab.ui.container.TreeNode
  DisplayNode                    matlab.ui.container.TreeNode
  DataNode                       matlab.ui.container.TreeNode
  FilterNode                     matlab.ui.container.TreeNode
  StatisticsNode                 matlab.ui.container.TreeNode
  ScalingNode                    matlab.ui.container.TreeNode
  SelectSubsetPanel              matlab.ui.container.Panel
  SelectSubsetLabel              matlab.ui.control.Label
  KeyboardPanel                  matlab.ui.container.Panel
  KeyboardConfig                 matlab.ui.container.Panel
  ControlPanel                   matlab.ui.container.Panel
  EpochStepSmallLabel            matlab.ui.control.Label
  EpochStepSmallInput            matlab.ui.control.NumericEditField
  EpochStepBigLabel              matlab.ui.control.Label
  EpochStepBigInput              matlab.ui.control.NumericEditField
  OverlaySmallLabel              matlab.ui.control.Label
  OverlaySmallInput              matlab.ui.control.NumericEditField
  OverlayBigLabel                matlab.ui.control.Label
  OverlayBigInput                matlab.ui.control.NumericEditField
  ControlValuesLabel             matlab.ui.control.Label
  WorkspacePanel                 matlab.ui.container.Panel
  WorkspaceVariablesLabel        matlab.ui.control.Label
  OutputDirectoryLabel            matlab.ui.control.Label
  OutputDirectoryInput            matlab.ui.control.EditField
  OutputLocatoinButton           matlab.ui.control.Button
  AnalysisDirectoryButton        matlab.ui.control.Button
  AnalysisDirectoryLabel         matlab.ui.control.Label
  AnalysisDirectoryInput         matlab.ui.control.EditField
  AnalysisPrefixLabel            matlab.ui.control.Label
  AnalysisPrefixInput            matlab.ui.control.EditField
  AnalysisPrefixPreviewLabel     matlab.ui.control.Label
  AnalysisPrefixPreviewString    matlab.ui.control.Label
  FilterPanel                    matlab.ui.container.Panel
  FilterSettingsLabel            matlab.ui.control.Label
  FilterOrderLabel               matlab.ui.control.Label
  FilterOrderSelect              matlab.ui.control.DropDown
  FilterFrequencyLowLabel        matlab.ui.control.Label
  FilterFrequencyLowSelect       matlab.ui.control.DropDown
  FilterFrequencyHighLabel       matlab.ui.control.Label
  FilterFrequencyHighSelect      matlab.ui.control.DropDown
  FilterTypeLabel                matlab.ui.control.Label
  FilterTypeSelect               matlab.ui.control.DropDown
  StatisticsPanel                matlab.ui.container.Panel
  StatisticsLabel                matlab.ui.control.Label
  GroupByLabel                   matlab.ui.control.Label
  GroupBySelect                  matlab.ui.control.ListBox
  AggregationStatisticLabel      matlab.ui.control.Label
  AggregationStatisticSelect     matlab.ui.control.DropDown
  ShowAll                        matlab.ui.control.CheckBox
  ZeroBaseline                   matlab.ui.control.CheckBox
  BaselineRegionLabel            matlab.ui.control.Label
  BaselineRegionSelect           matlab.ui.control.DropDown
  PTSEditFieldLabel              matlab.ui.control.Label
  BaselinePoints                 matlab.ui.control.NumericEditField
  ScalingPanel                   matlab.ui.container.Panel
  ScalingLabel                   matlab.ui.control.Label
  ScalingmethodSelectLabel       matlab.ui.control.Label
  ScaleMethodSelect              matlab.ui.control.DropDown
  ScaleValueLabel                matlab.ui.control.Label
  ScaleValue                     matlab.ui.control.NumericEditField
  DisplayPanel                   matlab.ui.container.Panel
  DisplayLabel                   matlab.ui.control.Label
  LineDisplayStyleDropDownLabel  matlab.ui.control.Label
  LineStyle                      matlab.ui.control.DropDown
  MarkerDisplayStyleDropDownLabel  matlab.ui.control.Label
  MarkerStyle                    matlab.ui.control.DropDown
  LineDisplayWidthLabel          matlab.ui.control.Label
  LineWidth                      matlab.ui.control.NumericEditField
  LineWidthSlider                matlab.ui.control.Slider
  MarkerSizeSlider               matlab.ui.control.Slider
  MarkerSize                     matlab.ui.control.NumericEditField
  MarkerDisplaySizeLabel         matlab.ui.control.Label
  GridDropDownLabel              matlab.ui.control.Label
  Grid                           matlab.ui.control.DropDown
  XAxisDropDownLabel             matlab.ui.control.Label
  AxesScaleX                     matlab.ui.control.DropDown
  YAxisDropDownLabel             matlab.ui.control.Label
  AxesScaleY                     matlab.ui.control.DropDown
  ResetPreferences               matlab.ui.control.Button
end

%% Public
methods (Access = public)
  
  function styles = getStyles(obj)
    if ~obj.isClosed
      obj.setContainerPrefs
    end
    styles = obj.options.DisplayProps;
  end
  
end

%% Startup and Callback Methods  
methods (Access = protected)
  % Startup
  startupFcn(obj,varargin)
  % Construct view
  createUI(obj)
  % Inject html and css for keyboard
  createKeyboardMenu(obj)
  % switch settings pages
  PageActivation(obj,~,~)
  % update folder
  function updateDirectory(obj,~,event)
   loc = iris.app.Info.getFolder( ...
     ['Select ', event.Data, ' directory.'], ...
     fileparts(obj.([event.Data,'DirectoryInput']).Value));
   stored = obj.options.AnalysisProps.([event.Data,'Directory']);
   if isempty(loc)
     loc = stored;
   else
     try
      obj.options.AnalysisProps.([event.Data,'Directory']) = loc;
     catch x
       warning(x.message);
       obj.options.AnalysisProps.([event.Data,'Directory']) = stored;
       loc = stored;
     end
   end
   obj.([event.Data,'DirectoryInput']).Value = loc;
  end
  % validate analysis prefix
  function validatePrefix(obj,source,~)
    if ~contains(source.Value,'@')
      source.Value = ['@()',source.Value];
    end
    value = str2func(source.Value);
    try
      validateattributes(value(), ...
      {'char'}, {'scalartext'});
      obj.options.AnalysisProps.prefix = value;
    catch
      warning('Analysis prefix must evaluate to scalar char string.');
      value = obj.options.AnalysisProps.prefix;
      source.Value = func2str(value);
    end
    obj.AnalysisPrefixPreviewString.Text = value();
    obj.setContainerPrefs;
  end
  % handling scaling method internally before notify
  function ScaleMethodChanged(obj,source,~)
    switch source.Value
      case 'Custom'
        obj.ScaleValue.Value = 1;
        obj.ScaleValue.Editable = 'on';
        obj.ScaleValue.Enable = 'on';
      case 'Select'
        warning('Scale method, ''Select'' is not currently available.');
        obj.ScaleMethodSelect.Value = 'Custom';
        obj.ScaleValue.Value = 1;
        obj.ScaleValue.Editable = 'on';
        obj.ScaleValue.Enable = 'on';
      otherwise
      if ~strcmpi(obj.ScaleValue.Editable, 'off')
        obj.ScaleValue.Editable = 'off';
        obj.ScaleValue.Enable = 'off';
      end
    end
    obj.setContainerPrefs;
    notify(obj, 'ScalingChanged', iris.infra.eventData('ScaleValue'));
  end
  % Display control, slider changing
  function DisplaySliderChanging(obj, ~, event)
    %changes are local and do not affect plot until slider has stopped
    %moving
    changingValue = event.Data.Value;
    obj.(event.Data.Type).Value = changingValue;
  end
  
  function DisplaySliderChanged(obj,source,event)
    value = event.Data.Value;
    if obj.(event.Data.Type).Value ~= value
      obj.(event.Data.Type).Value = value;
    end
    notify(obj,'DisplayChanged', iris.infra.eventData({event.Data.Type,source.Value}));
    obj.setContainerPrefs;
  end
  
  function DisplayValueChanged(obj,~,event)
    value = event.Data{2};
    obj.([event.Data{1},'Slider']).Value = value;
    notify(obj,'DisplayChanged', event);
    obj.setContainerPrefs;
  end
end

%% Preferences

methods (Access = protected)
  
  function onCloseRequest(obj)
    obj.setContainerPrefs;
    obj.hide;
    %%% 
  end
  
  resetContainerPrefs(obj)
  
  getContainerPrefs(obj)
  
  setContainerPrefs(obj)
end
end % end of class