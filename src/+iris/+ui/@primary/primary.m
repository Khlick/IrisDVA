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
    InstallHelpersRequest
    TickerChanged
    NavigateData
    DatumToggled
    DeviceViewChanged
    RequestRedraw
    SessionConversionCalled
    FixLayoutRequest
    PlotCompletedUpdate
    RevertView
  end
  
  
  properties (Access = public) %private)
    % Menus
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
    ModulesMenu             matlab.ui.container.Menu
    ModulesRefresh           matlab.ui.container.Menu
    HelpMenu                 matlab.ui.container.Menu
    AboutMenu                matlab.ui.container.Menu
    DocumentationMenu        matlab.ui.container.Menu
    FixLayoutMenu            matlab.ui.container.Menu
    SessionConverterMenu     matlab.ui.container.Menu
    InstallHelpersMenu       matlab.ui.container.Menu
    
    % Grids
    containerGrid                  matlab.ui.container.GridLayout
    PlotControlGrid                matlab.ui.container.GridLayout
    SwitchGrid                     matlab.ui.container.GridLayout
    OverlapGrid                    matlab.ui.container.GridLayout
    NavigatorGrid                  matlab.ui.container.GridLayout
    ExtendedInfoGrid               matlab.ui.container.GridLayout
    CurrentInfoGrid                matlab.ui.container.GridLayout
    
    % Panels
    AxesPanel                matlab.ui.container.Panel
    CurrentInfoPanel         matlab.ui.container.Panel
    ExtendedInfoPanel        matlab.ui.container.Panel
    PlotControlTools         matlab.ui.container.Panel
    SwitchPanel              matlab.ui.container.Panel
    Axes                     iris.ui.elements.AxesPanel
    
    % Labels
    ShowingLabel             matlab.ui.control.Label
    ShowingValueLabel        matlab.ui.control.Label
    DevicesLabel             matlab.ui.control.Label
    OverlapLabel             matlab.ui.control.Label
    CurrentDataLabel         matlab.ui.control.Label
    SelectionNavigatorLabel  matlab.ui.control.Label
    StatsLabel               matlab.ui.control.Label
    ScaleLabel               matlab.ui.control.Label
    BaselineLabel            matlab.ui.control.Label
    FilterLabel              matlab.ui.control.Label
    DataLabel                matlab.ui.control.Label
    
    % Components
    CurrentDatumDecSmall     matlab.ui.control.Button
    CurrentDatumIncSmall     matlab.ui.control.Button
    OverlapInc               matlab.ui.control.Button
    OverlapDec               matlab.ui.control.Button
    CurrentDatumIncBig       matlab.ui.control.Button
    CurrentDatumDecBig       matlab.ui.control.Button
    OverlapTicker            matlab.ui.control.EditField
    CurrentDataTicker        matlab.ui.control.EditField
    StatsLamp                matlab.ui.control.Lamp
    ScaleLamp                matlab.ui.control.Lamp
    BaselineLamp             matlab.ui.control.Lamp
    FilterLamp               matlab.ui.control.Lamp
    DataLamp                matlab.ui.control.Lamp
    DevicesSelection         matlab.ui.control.ListBox
    SelectionNavigatorSlider matlab.ui.control.Slider
    CurrentInfoTable         matlab.ui.control.Table
    DatumSwitch              matlab.ui.control.ToggleSwitch
    FilterSwitch             matlab.ui.control.ToggleSwitch
    BaselineSwitch           matlab.ui.control.ToggleSwitch
    StatsSwitch              matlab.ui.control.ToggleSwitch
    ScaleSwitch              matlab.ui.control.ToggleSwitch
    
    % Containers
    ModulesContainer         cell
  end
  
  properties (SetAccess= ?Iris, GetAccess= public, SetObservable = true)
    LUT %lookup for html to matlab elements (not impl.)
    selection
    previousSelction
    layout
  end
  
  properties (SetAccess= private, GetAccess= ?Iris, SetObservable= true)
    lastDataPoint = struct('lastDataCoordinates',[0,0],'datumIndex',0,'datumID','');
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
    
    % Store a selection update before it changes
    function onSelectionWillUpdate(obj,~,~)
      obj.previousSelction = obj.selection;
    end
    
    function onSelectionDidUpdate(obj,~,~)
      if isequal(obj.previousSelction,obj.selection)
        return
      end
      obj.onSelectionUpdate();
    end
    
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
      switches = switches(~contains(switches,{'Panel','Grid'}));
      obj.setUI(switches,'Enable', status);
      
      % Controls and buttons
      controls = uiObjs( ...
        contains( ...
        uiObjs, ...
        {'Ticker','Devices','Showing','Button','Selection','Overlap','CurrentDatum'} ...
        ));
      controls(contains(controls,'Grid')) = [];
      obj.setUI(controls, 'Enable', status);
      if isempty(obj.selection) || (length(obj.selection.selected) < 2)
        obj.setSlider('off');
      end
      if invStatus
        %data is present, show the axes
        obj.Axes.toggleAxes(true);
      else
        % data is not present, hide the axes
        obj.Axes.showLabel("Load data to get started.");
      end
    end
    
    function setSlider(obj, status)
      status = validatestring(status,{'off','on'});
      obj.setUI( ...
        {'SelectionNavigatorSlider','SelectionNavigatorLabel'}, ...
        'Enable', status ...
        );
    end
    
    function updateInclusion(obj,value)
      % toggle the datum lamp/switch for the selected EPOCH
      if value
        col = iris.app.Aes.appColor(1,'green');
      else
        col = iris.app.Aes.appColor(1,'red');
      end
      obj.DataLamp.Color = col;
      obj.DatumSwitch.Value = num2str(value);
      
    end
    
    function runJS(obj, jsString)
      out = obj.window.executeJS(jsString);
      fprintf('JOut: %s.\n', out)
    end
    
    function A = getScreenshot(obj,display)
      if nargin < 2, display = false; end
      if obj.isClosed
        A = [];
        return
      end
      A = obj.window.getScreenshot;
      if display
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
        a.DataAspectRatio = [1 1 1];
        f.Visible = 'on';
      end
    end
    
    function setDisplayData(obj,propCell)
      % collapse to only unique entries in the first column.
      propCell = utilities.collapseUnique(propCell,1,true,true);
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
    
    % Validate datum ticker and overlay ticker values
    function ValidateTicker(obj,tag,event)
      switch tag
        case {'Overlap','CurrentDatum'}
          try
            num = eval(sprintf('[%s]',event.Value));
          catch
            event.Source.Value = event.PreviousValue;
            return
          end
          if isempty(num)
            event.Source.Value = event.PreviousValue;
            return
          end
          event.Source.Value = num2str(num(1));
        case 'Slider'
          % sliders case, round to nearest int and determine if it is one of the
          % current selections.
          num = round(event.Value);
          if ~ismember(num,obj.selection.selected), return; end
          % set the selection and allow postset to handle changes
          obj.selection.highlighted = num;
          % quantize slider position
          obj.SelectionNavigatorSlider.Value = num;
          obj.selection.highlighted = num;
          return
        case 'selection'
          % if we click the only line on the figure, do nothing
          if length(obj.selection.selected) == 1, return; end
          
          num = double(event.Data.datumIndex);
          if isempty(num), return; end
          curSelection = obj.selection;
          if curSelection.highlighted == num, return; end
          curSelection.highlighted = num;
          obj.selection = curSelection;
          % allow selection update to capture the change.
          return
        otherwise
          if isfield(event,'PreviousValue') && isa(event.Source,'matlab.ui.control.EditField')
            try
              num = eval(sprintf('[%s]',event.Value));
            catch
              event.Source.Value = event.PreviousValue;
              return
            end
            if isempty(num)
              event.Source.Value = event.PreviousValue;
              return
            end
          else
            return
          end
      end
      notify(obj, 'TickerChanged', ...
        iris.infra.eventData( ...
        struct('Type', tag, 'Value', num)) ...
        );
    end
    
    % Data slider changing
    function SliderChanging(obj,source,event)
      num = round(event.Value);
      if (source.Value == num)
        return
      end
      if ~ismember(num,obj.selection.selected), return; end
      source.Value = num;
      obj.CurrentDataTicker.Value = sprintf('%d',num);
      dOpts = iris.pref.display.getDefault();
      obj.Axes.setHighlighted(num,dOpts.LineWidth);
      obj.updateInclusion( ...
        logical(obj.selection.inclusion(obj.selection.selected == num)) ...
        );
      
      if num == obj.selection.highlighted, return; end
      % use selection update
      obj.selection.highlighted = num;
    end
    
    % Display control switch flipped
    function SwitchFlipped(obj,source,event)
      value = event.Value == '1';
      if value && strcmpi(source.Tag,'Data')
        col = iris.app.Aes.appColor(1,'green');
      elseif ~value && strcmpi(source.Tag,'Data')
        col = iris.app.Aes.appColor(1,'red');
      else
        col = iris.app.Aes.appColor(1,'amber');
      end
      obj.([source.Tag,'Lamp']).Color = col;
      drawnow('update');
      
      % if we are toggling the datum, send the info to Iris for handling
      if strcmp(source.Tag,'Data')
        notify(obj, 'DatumToggled', ...
          iris.infra.eventData( ...
          struct( ...
          'index', obj.selection.highlighted, ...
          'value', value ...
          ) ...
          ) ...
          );
        return
      end
      
      % otherwise, notify for redraw
      notify(obj,'SwitchToggled', ...
        iris.infra.eventData(struct('source',source.Tag,'value',value)));
    end
    
    function populateModules(obj)
      modNames = Iris.getModules(true); % will copy modules into +iris/+modules
      
      % First delete module links
      cellfun(@delete,obj.ModulesContainer,'unif', false);
      % build new modules
      obj.ModulesContainer = cell(numel(modNames),1);
      for I = 1:numel(modNames)
        obj.ModulesContainer{I} = uimenu(obj.ModulesMenu);
        obj.ModulesContainer{I}.Text = utilities.camelizer(modNames{I},true);
        obj.ModulesContainer{I}.Enable = 'on';
        obj.ModulesContainer{I}.MenuSelectedFcn = ...
          @(s,e) ...
          notify(obj,'ModuleCalled', iris.infra.eventData(modNames{I}));
        obj.ModulesContainer{I}.Tag = modNames{I};
      end
      % reorder menus to keep Reset on bottom
      chld = obj.ModulesMenu.Children;
      
      % locate Refresh and Session Converter
      rfInd = strcmpi({chld.Text}, 'Refresh');
      scInd = strcmpi({chld.Text}, 'Session Converter');
      
      obj.ModulesMenu.Children = [ ...
        obj.ModulesMenu.Children(rfInd); ...
        obj.ModulesMenu.Children(scInd); ...
        obj.ModulesMenu.Children(~any([rfInd(:),scInd(:)],2)) ...
        ];
      pause(0.01);%drawnow('limitrate');
    end
    
    function onAxesDataSelected(obj,~,event)
      import iris.infra.eventData;
      % Send the index to the ticker validation method
      obj.ValidateTicker('selection', eventData(event.Data) );
      if ~isequal(obj.lastDataPoint, event.Data.lastDataCoordinates)
        obj.lastDataPoint = event.Data;
      end
    end
    
    function SwitchDisabled(obj,source,~)
      col = iris.app.Aes.appColor(1,'red');
      obj.([source.Tag,'Lamp']).Color = col;
      source.Value = '0';
      %obj.drawnow('limitrate');
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
      drawnow('limitrate');
      % send notification to main class
      notify(obj,'PlotCompletedUpdate');
    end
    
    function resetContainerView(obj,~,~)
      p = obj.position;
      p(3:4) = [1610,931];
      obj.position = p;
    end
    
    % copy cell contents callback
    function doCopyUITableCell(obj,source,event) %#ok<INUSL>
      try
        ids = event.Indices;
        nSelections = size(ids,1);
        merged = cell(nSelections,1);
        for sel = 1:nSelections
          merged{sel} = source.Data{ids(sel,1),ids(sel,2)};
        end
        stringified = utilities.unknownCell2Str(merged,';',false);
        clipboard('copy',stringified);
      catch x
        fprintf('Copy failed for reason:\n "%s"\n',x.message);
      end
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
      end
      if obj.isFiltered
        obj.manualSwitchThrow('Filter');
      end
      if obj.isBaselined
        obj.manualSwitchThrow('Baseline');
      end
      if obj.isScaled
        obj.manualSwitchThrow('Scale');
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

