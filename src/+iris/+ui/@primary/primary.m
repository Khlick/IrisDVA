classdef primary < iris.ui.UIContainer
  %PRIMARY Main view of Iris app
  events
    MenuCalled
    ModuleCalled
    LoadData
    LoadSession
    ImportData
    ImportSession
    SaveSession
    SwitchToggled
    ImportAnalysis
    DoAnalysis
    CreateNewAnalysis
    ExportDataView
    SendToCmd
    ShowHelpDocs
    TickerChanged
    NavigateData
    EpochToggled
    DeviceViewChanged
    RequestRedraw
    SessionConversionCalled
    FixLayoutRequest
    PlotCompletedUpdate
    RevertView
  end
  
  
  properties (Access = public) %private)
    FileMenu                 matlab.ui.container.Menu
    NewMenu                  matlab.ui.container.Menu
    DataMenu                 matlab.ui.container.Menu
    SessionMenu              matlab.ui.container.Menu
    ImportMenuD              matlab.ui.container.Menu
    FromDataMenuD            matlab.ui.container.Menu
    FromSessionMenuD         matlab.ui.container.Menu
    SaveMenuD                matlab.ui.container.Menu
    QuitMenu                 matlab.ui.container.Menu
    ViewMenu                 matlab.ui.container.Menu
    FileInfoMenuD            matlab.ui.container.Menu
    NotesMenuD               matlab.ui.container.Menu
    ProtocolsMenuD           matlab.ui.container.Menu
    PreferencesMenu          matlab.ui.container.Menu
    AnalysisMenu             matlab.ui.container.Menu
    ImportAnalysisMenu       matlab.ui.container.Menu
    AnalyzeMenuD             matlab.ui.container.Menu
    OverviewMenuD             matlab.ui.container.Menu
    CreateNewMenu            matlab.ui.container.Menu
    ExportFigureMenuD        matlab.ui.container.Menu
    SendtoCmdMenuD           matlab.ui.container.Menu
    ModulesMenuD             matlab.ui.container.Menu
    ModulesContainer         cell
    ModulesRefresh           matlab.ui.container.Menu
    HelpMenu                 matlab.ui.container.Menu
    AboutMenu                matlab.ui.container.Menu
    DocumentationMenu        matlab.ui.container.Menu
    FixLayoutMenu            matlab.ui.container.Menu
    SessionConverterMenu     matlab.ui.container.Menu
    AxesPanel                matlab.ui.container.Panel
    Axes                     iris.ui.elements.AxesPanel%matlab.ui.control.UIAxes
    CurrentInfo              matlab.ui.container.Panel
    ExtendedInfo             matlab.ui.container.Panel
    ShowingLabel             matlab.ui.control.Label
    ShowingValueString       matlab.ui.control.Label
    DevicesLabel             matlab.ui.control.Label
    DevicesSelection         matlab.ui.control.ListBox
    ViewNotesButton          matlab.ui.control.Button
    ExtendedInfoButton       matlab.ui.control.Button
    CurrentInfoTable         matlab.ui.control.Table
    PlotControlTools         matlab.ui.container.Panel
    OverlapLabel             matlab.ui.control.Label
    OverlapTicker            matlab.ui.control.EditField
    CurrentEpochLabel         matlab.ui.control.Label
    CurrentEpochTicker       matlab.ui.control.EditField
    CurrentEpochSlider       matlab.ui.control.Slider
    CurrentEpochDecSmall     matlab.ui.control.Button
    CurrentEpochIncSmall     matlab.ui.control.Button
    OverlapInc               matlab.ui.control.Button
    OverlapDec               matlab.ui.control.Button
    CurrentEpochIncBig       matlab.ui.control.Button
    CurrentEpochDecBig       matlab.ui.control.Button
    SelectionNavigatorLabel  matlab.ui.control.Label
    SwitchPanel              matlab.ui.container.Panel
    StatsLabel               matlab.ui.control.Label
    StatsLamp                matlab.ui.control.Lamp
    StatsSwitch              matlab.ui.control.ToggleSwitch
    ScaleLabel               matlab.ui.control.Label
    ScaleLamp                matlab.ui.control.Lamp
    ScaleSwitch              matlab.ui.control.ToggleSwitch
    BaselineLabel            matlab.ui.control.Label
    BaselineLamp             matlab.ui.control.Lamp
    BaselineSwitch           matlab.ui.control.ToggleSwitch
    FilterLabel              matlab.ui.control.Label
    FilterLamp               matlab.ui.control.Lamp
    FilterSwitch             matlab.ui.control.ToggleSwitch
    EpochLabel               matlab.ui.control.Label
    EpochLamp                matlab.ui.control.Lamp
    EpochSwitch              matlab.ui.control.ToggleSwitch
    StartPanel              matlab.ui.container.Panel
    StartLabel              matlab.ui.control.Label
    %KeyboardButton           matlab.ui.control.Button
  end
  
  properties (Access= public, SetObservable = true)
    LUT %lookup for html to matlab elements
    selection
    layout
  end
  
  properties (SetAccess= private, GetAccess= ?Iris, SetObservable= true)
    lastDataPoint = [0,0]
  end
  
  properties (Dependent)
    isFiltered
    isScaled
    isBaselined
    isAggregated
    viewStatus
  end
  
  %% Public Functions
  methods (Access = public)
    % External Methods
    % UI update
    %updateView(obj,handler)
    updateView(obj, newSelection, newDisplay, newData, newUnits)
    % Update view during selection changes
    onSelectionUpdate(obj)
    
    function toggleDataDependentUI(obj,status)
      %data dependent menu items
      status = validatestring(status, {'off','on'});
      invStatus = strcmp(status,'on');
      uiObjs = properties(obj);
      % Toggle Menus
      dMenus = uiObjs(contains(uiObjs,'MenuD'));
      obj.setUI(dMenus,'Enable', status);
      % Switches
      switches = uiObjs(contains(uiObjs,{'Switch','Lamp'}));
      switches = switches(~contains(switches,'Panel'));
      obj.setUI(switches,'Enable', status);
      % Set axes visibility
      obj.AxesPanel.Visible = status;
      % Controls and buttons
      controls = uiObjs( ...
        contains( ...
          uiObjs, ...
          {'Ticker','Devices','Showing','Button','Selection','Overlap','CurrentEpoch'} ...
        ));
      obj.setUI(controls, 'Enable', status);
      if isempty(obj.selection) || (length(obj.selection.selected) < 2)
        obj.setSlider('off');
      end
      if invStatus
        %turning on UI so hide startpanel
        obj.StartPanel.Visible = 'off';
      else
        obj.StartPanel.Visible = 'on';
      end
    end
    
    function setSlider(obj, status)
      status = validatestring(status,{'off','on'});
      obj.setUI( ...
        {'CurrentEpochSlider','SelectionNavigatorLabel'}, ...
        'Enable', status ...
        );
    end
    
    function updateInclusion(obj,value)
      % toggle the epoch lamp/switch for the selected EPOCH
      if value
        col = iris.app.Aes.appColor(1,'green');
      else
        col = iris.app.Aes.appColor(1,'red');
      end
      obj.EpochLamp.Color = col;
      obj.EpochSwitch.Value = num2str(value);
      
    end
    
    function runJS(obj, jsString)
      out = obj.window.executeJS(jsString);
      fprintf('JOut: %s.\n', out)
    end
    
    function A = getScreenshot(obj)
      if obj.isClosed
        A = [];
        return
      end
      A = obj.window.getScreenshot;
      f = figure( ...
        'Name','Iris Screenshot', ...
        'NumberTitle', 'on', ...
        'Visible', 'off', ...
        'units', 'pixels' ...
        );
      f.Position = [100,100,obj.position(3:4)+[0,-10]];
      a = axes(f,'units', 'pixels');
      image(a,A);
      a.Visible = 'off';
      a.Position = [0,0,f.InnerPosition(3:4)];
      f.Visible = 'on';
    end
    
    function setDisplayData(obj,propCell)
      % collapse to only unique entries in the first column.
      propCell = collapseUnique(propCell,1,true);
      % set the data
      obj.CurrentInfoTable.Data = propCell;
      % determine the best widths
      lens = cellfun(@length,propCell(:,2),'UniformOutput',true);
      tWidth = obj.CurrentInfoTable.Position(3)-127;
      obj.CurrentInfoTable.ColumnWidth = {125,max([tWidth,max(lens)*6.56])};
    end
  
  end
  
  %% Startup and Callback Methods
  methods (Access = protected)
    % Startup
    startupFcn(obj,varargin)
    % Construct view
    createUI(obj)
    % Bind elements
    bindUI(obj)
    % resize components
    windowResized(obj,source,event)
    
    % Validate epoch ticker and overlay ticker values
    function ValidateTicker(obj,tag,event)
      switch tag
        case {'Overlap','CurrentEpoch'}
          try
            num = eval(sprintf('[%s]',event.Value));
          catch
            obj.([tag,'Ticker']).Value = event.PreviousValue;
            return
          end
          if isempty(num)
            obj.([tag,'Ticker']).Value = event.PreviousValue;
            return
          end
        case 'Slider'
          % sliders case, round to nearest int and determine if it is one of the
          % current selections.
          num = round(event.Value);
          if ~ismember(num,obj.selection.selected), return; end
          obj.CurrentEpochTicker.Value = sprintf('%d',num);
          % quantize slider position
          obj.CurrentEpochSlider.Value = num;
          obj.selection.highlighted = num;
        case 'selection'
          % if we click the only line on the figure, do nothing
          if length(obj.selection.selected) == 1, return; end
          num = double(event.Data);
          if isempty(num), return; end
          if ~ismember(num,obj.selection.selected), return; end
          obj.CurrentEpochTicker.Value = sprintf('%d',num);
          obj.CurrentEpochSlider.Value = num;
          obj.selection.highlighted = num;
          % override tag so Iris knows what to do:
          tag = 'Slider';
      end
      notify(obj, 'TickerChanged', ...
        iris.infra.eventData( ...
          struct('Type', tag, 'Value', num)) ...
        );
    end
    
    % Epoch slider changing
    function SliderChanging(obj,source,event)
      num = round(event.Value);
      if (source.Value == num)
        return;
      end
      if ~ismember(num,obj.selection.selected), return; end
      source.Value = num;
      obj.CurrentEpochTicker.Value = sprintf('%d',num);
      dOpts = iris.pref.display.getDefault();
      obj.Axes.setHighlighted(num,dOpts.LineWidth);
      obj.updateInclusion( ...
        logical(obj.selection.inclusion(obj.selection.selected == num)) ...
        );
      
      if num == obj.selection.highlighted, return; end
      obj.selection.highlighted = num;
      
    end
    
    % Display control switch flipped
    function SwitchFlipped(obj,source,event)
      value = event.Value == '1';
      if value && strcmpi(source.Tag,'Epoch')
        col = iris.app.Aes.appColor(1,'green');
      elseif ~value && strcmpi(source.Tag,'Epoch')
        col = iris.app.Aes.appColor(1,'red');
      else
        col = iris.app.Aes.appColor(1,'amber');
      end
      obj.([source.Tag,'Lamp']).Color = col;
      pause(0.01);%drawnow('limitrate'); pause(0.01);
      
      % if we are toggling the epoch, send the info to Iris for handling
      if strcmp(source.Tag,'Epoch')
        notify(obj, 'EpochToggled', ...
          iris.infra.eventData( ...
          struct( ...
            'index', obj.selection.highlighted, ...
            'value', value ...
            ) ...
          ) ...
          );
        return;
      end
      % otherwise, notify for redraw
      notify(obj,'SwitchToggled', ...
        iris.infra.eventData(struct('source',source.Tag,'value',value)));
    end
    
    function populateModules(obj)
      modNames = Iris.getModules(); % will copy modules into +iris/+modules
      
      % First delete module links
      cellfun(@delete,obj.ModulesContainer,'unif', false);
      % build new modules
      obj.ModulesContainer = cell(numel(modNames),1);
      for I = 1:numel(modNames)
        obj.ModulesContainer{I} = uimenu(obj.ModulesMenuD);
        obj.ModulesContainer{I}.Text = camelizer(modNames{I},true);
        obj.ModulesContainer{I}.Enable = 'on';
        obj.ModulesContainer{I}.MenuSelectedFcn = ...
          @(s,e) ...
            notify(obj,'ModuleCalled', iris.infra.eventData(modNames{I}));
        obj.ModulesContainer{I}.Tag = modNames{I};
      end
       % reorder menus to keep Reset on bottom
       chld = obj.ModulesMenuD.Children;
       
       % locate Refresh
       rfInd = strcmpi({chld.Text}, 'Refresh');
       obj.ModulesMenuD.Children = [ ...
         obj.ModulesMenuD.Children(rfInd); ...
         obj.ModulesMenuD.Children(~rfInd) ...
         ];
       pause(0.01);%drawnow('limitrate');
    end
    
    function onAxesDataSelected(obj,~,event)
      import iris.infra.eventData;
      % Send the index to the ticker validation method
      obj.ValidateTicker('selection', eventData(event.Data.datumIndex) );
      if ~isequal(obj.lastDataPoint, event.Data.lastDataCoordinates)
        obj.lastDataPoint = event.Data.lastDataCoordinates;
      end
    end
    
    function SwitchDisabled(obj,source,~)
      col = iris.app.Aes.appColor(1,'red');
      obj.([source.Tag,'Lamp']).Color = col;
      source.Value = '0';
      %obj.drawnow();
    end
    
    function onPlotUpdated(obj,~,~)
      % update any switches that are amber to green.
      
      if obj.isAggregated
        obj.StatsLamp.Color = iris.app.Aes.appColor(1,'green');
      else
        obj.StatsLamp.Color = iris.app.Aes.appColor(1,'red');
      end
      if obj.isBaselined
        obj.BaselineLamp.Color = iris.app.Aes.appColor(1,'green');
      else
        obj.BaselineLamp.Color = iris.app.Aes.appColor(1,'red');
      end
      if obj.isFiltered
        obj.FilterLamp.Color = iris.app.Aes.appColor(1,'green');
      else
        obj.FilterLamp.Color = iris.app.Aes.appColor(1,'red');
      end
      if obj.isScaled
        obj.ScaleLamp.Color = iris.app.Aes.appColor(1,'green');
      else
        obj.ScaleLamp.Color = iris.app.Aes.appColor(1,'red');
      end
      %obj.drawnow();
      % send notification to main class
      notify(obj,'PlotCompletedUpdate');
    end
    
  end
  
  %% Preferences
  methods (Access = protected)

    function resetContainerPrefs(obj)
      obj.reset;
    end

    function setContainerPrefs(obj)
      setContainerPrefs@iris.ui.UIContainer(obj);
    end
    
    function getContainerPrefs(obj)
      getContainerPrefs@iris.ui.UIContainer(obj);
    end
    
  end
  
  %% Get/Set methods
  methods
    
    function tf = get.isScaled(obj)
      tf = false;
      try %#ok<TRYNC>
        tf = obj.ScaleSwitch.Value == '1';
      end
    end
    
    function tf = get.isBaselined(obj)
      tf = false;
      try %#ok<TRYNC>
        tf = obj.BaselineSwitch.Value == '1';
      end
    end
    
    function tf = get.isFiltered(obj)
      tf = false;
      try %#ok<TRYNC>
        tf = obj.FilterSwitch.Value == '1';
      end
    end
    
    function tf = get.isAggregated(obj)
      tf = false;
      try %#ok<TRYNC>
        tf = obj.StatsSwitch.Value == '1';
      end
    end
    
    function s = get.viewStatus(obj)
      s = struct();
      s.switches = struct( ...
        'scale', obj.isScaled, ...
        'filter', obj.isFiltered, ...
        'baseline', obj.isBaselined, ...
        'aggregate', obj.isAggregated ...
        );
      s.selection = obj.selection;
    end
    
    function toggleSwitches(obj,status) %#ok
      if nargin < 2
        status = 'off'; %#ok
      end
      
      if obj.isAggregated
        obj.manualSwitchThrow('Stats');
        pause(1);
      end
      if obj.isFiltered
        obj.manualSwitchThrow('Filter');
        pause(1);
      end
      if obj.isBaselined
        obj.manualSwitchThrow('Baseline');
        pause(1);
      end
      if obj.isScaled
        obj.manualSwitchThrow('Scale');
        pause(1);
      end
      %pause(0.01);%drawnow('limitrate');
      %notify(obj,'RequestRedraw');
    end
    
    function manualSwitchThrow(obj,switchName)
      % get the source and create event data to toggle it.
      prps = properties(obj);
      pName = prps(endsWith(prps,'Switch')&contains(prps,switchName,'IgnoreCase',true));
      prop = obj.(pName{1});
      % get current value:
      prevVal = prop.Value;
      newVal = num2str(~strcmp(prevVal,'1'));
      evt = matlab.ui.eventdata.ValueChangedData(newVal,prevVal);
      prop.Value = newVal;
      prop.ValueChangedFcn(prop,evt);
    end
  end
end

