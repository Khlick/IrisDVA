classdef primary < iris.ui.UIContainer
  %PRIMARY Main view of Iris app
  events
    MenuCalled
    LoadData
    LoadSession
    ImportData
    ImportSession
    SaveSession
    ShowNotes
    ShowProtocols
    ShowPreferences
    ShowStatistics
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
  end
  
  
  properties (Access = public)
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
    HelpMenu                 matlab.ui.container.Menu
    AboutMenu                matlab.ui.container.Menu
    DocumentationMenu        matlab.ui.container.Menu
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
  
  properties (Access = public,SetObservable = true)
    LUT %lookup for html to matlab elements
    selection
    layout
  end
  
  properties (Dependent)
    isFiltered
    isScaled
    isBaselined
  end
  
  %% Public Functions
  methods (Access = public)
    % External Methods
    % UI update
    updateView(obj,handler)
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
      f = figure;
      a = axes(f,'Visible', 'off');
      image(a,A);
    end
  
  end
  
  %% Startup and Callback Methods
  methods (Access = protected)
    % Startup
    startupFcn(obj,varargin)
    % Construct view
    createUI(obj)
    
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
          num = round(event.Value);
          if ~ismember(num,obj.selection.selected), return; end
          obj.CurrentEpochTicker.Value = sprintf('%d',num);
          % quantize slider position
          obj.CurrentEpochSlider.Value = num;
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
      %{
      if num == obj.selection.highlighted, return; end
      obj.selection.highlighted = num;
      %}
    end
    
    % Display control switch flipped
    function SwitchFlipped(obj,source,event)
      value = event.Value == '1';
      if value
        col = iris.app.Aes.appColor(1,'green');
      else
        col = iris.app.Aes.appColor(1,'red');
      end
      obj.([source.Tag,'Lamp']).Color = col;
      
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
    
    % Track keypresses (<=2018a:  using javascript hack)
    function KeypressCapture(obj,~,event)
      if isempty(event.Character), return; end
      
      keyData = struct(...
        'SOURCE', class(event.Source), ...
        'CTRL', ismember('control', event.Modifier), ...
        'SHIFT', ismember('shift', event.Modifier), ...
        'ALT', ismember('alt', event.Modifier), ...
        'KEY', event.Key, ...
        'CHAR', event.Character, ...
        'CODE', unicode2native(event.Character) ...
        );
      %{
      v = ver('matlab');
      if str2double(v.Version) < 9.5
        try
          keyData = obj.window.executeJS('keyData');
          disp('keyData');
          
        catch x %#ok
          %log
          return
        end

        %parse data from window
        keyData = jsondecode(keyData);
        %if ismember(keyData.SOURCE, obj.LUT.keys())
        %  return;
        %end
      else
        
      end
      %}
      notify(obj,'KeyPress',iris.infra.eventData(keyData));
    end
    
    function populateModules(obj)
      builtinModules = cellstr(ls( ...
        fullfile( ...
          iris.app.Info.getResourcePath, ...
          'Modules', ...
          '*.mlapp' ...
          ) ...
        ));
      % get custom from preferences Module directory.
      disp('TODO:Iris.ui.populateModules');
        
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
  
  %% Get methods
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
  end
end

