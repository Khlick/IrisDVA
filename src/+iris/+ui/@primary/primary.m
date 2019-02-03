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
    ImportAnalysis
    DoAnalysis
    ShowOverview
    CreateNewAnalysis
    ExportDataView
    SendToCmd
    ShowHelpDocs
    TickerChanged
    NavigateData
    SwitchChanged
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
    HelpMenu                 matlab.ui.container.Menu
    AboutMenu                matlab.ui.container.Menu
    DocumentationMenu        matlab.ui.container.Menu
    AxesPanel                matlab.ui.container.Panel
    %Axes                     matlab.ui.control.UIAxes
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
    CurrentDataLabel         matlab.ui.control.Label
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
    KeyboardButton           matlab.ui.control.Button
  end
  
  properties (Access = private)
    LUT %lookup for html to matlab elements
  end
  
  %% Public Functions
  methods (Access = public)
    % External Methods
    % UI update
    updateView(obj,data,layout)
    % Plot update
    updatePlot(obj,data,layout)
    
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
          {'Ticker', 'Button','Selection','Slider','Dec','Inc'} ...
        ));
      obj.setUI(controls, 'Enable', status);
      if invStatus
        %turning on UI so hide startpanel
        obj.StartPanel.Visible = 'off';
      else
        obj.StartPanel.Visible = 'on';
      end
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
          disp('ticker modified')
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
    function SliderChanging(obj,~,event)
      num = round(event.Value);
      obj.CurrentEpochTicker.Value = sprintf('%d',num);
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
      notify(obj, 'SwitchChanged', ...
        iris.infra.eventData(struct('Type', source.Tag, 'Value', value)) ...
        );
    end
    
    % Track keypresses (2018a -> using javascript hack)
    function KeypressCapture(obj,~,~)
      try
        keyData = obj.window.executeJS('keyData');
      catch x %#ok
        %log
        return
      end
      
      %parse data from window
      keyData = jsondecode(keyData);
      if ismember(keyData.SOURCE, obj.LUT.keys())
        return;
      end
      disp(keyData)
      notify(obj,'KeyPress',iris.infra.eventData(keyData));
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
end

