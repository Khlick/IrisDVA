classdef artifactRemover < IrisModule
  % ARTIFACTREMOVER Interactive Iris module to remove artifacts & thermal events.
  % Opens IrisData files and allows saving/exporting results as IrisData class.
  

  properties (Constant)
    ALPHA           = 0.7
    ALPHA_DRAG      = 0.2
    ALPHA_HOVER     = 0.5
    ROI_FRACTION    = 0.0035
    ROI_TAG         = ["START","END"]
    EDIT_ACTIVE     = [0.298,0.733,0.09]
    EDIT_INACTIVE   = [1,0.765,0]
  end

  properties %UI Elements
    FileMenu             matlab.ui.container.Menu
    LoadMenu             matlab.ui.container.Menu
    SaveMenu             matlab.ui.container.Menu
    RevertMenu           matlab.ui.container.Menu
    ExportMenu           matlab.ui.container.Menu
    CloseMenu            matlab.ui.container.Menu
    ViewMenu             matlab.ui.container.Menu
    DataPropMenu         matlab.ui.container.Menu
    InclusionsMenu       matlab.ui.container.Menu
    SettingsMenu         matlab.ui.container.Menu
    MainLayout           matlab.ui.container.GridLayout
    ControlLayout        matlab.ui.container.GridLayout
    StartSpinner         matlab.ui.control.Spinner
    StartSpinnerLabel    matlab.ui.control.Label
    EndSpinner           matlab.ui.control.Spinner
    EndSpinnerLabel      matlab.ui.control.Label
    xLabel               matlab.ui.control.Label
    yLabel               matlab.ui.control.Label
    DeviceDropDown       matlab.ui.control.DropDown
    DeviceDropDownLabel  matlab.ui.control.Label
    EditorLayout         matlab.ui.container.GridLayout
    EditorTable          matlab.ui.control.Table
    EditControlLayout    matlab.ui.container.GridLayout
    UndoButton           matlab.ui.control.Button
    AddButton            matlab.ui.control.Button
    RemoveButton         matlab.ui.control.Button
    ApplyButton          matlab.ui.control.Button
    EditAxes             matlab.ui.control.UIAxes
    DataLayout           matlab.ui.container.GridLayout
    CurrentIndexLabel    matlab.ui.control.Label
    DecrementDataButton  matlab.ui.control.Button
    DatumIndexField      matlab.ui.control.NumericEditField
    IncrementDataButton  matlab.ui.control.Button
    ToggleLayout         matlab.ui.container.GridLayout
    ToggleDataButton     matlab.ui.control.StateButton
    ViewAxes             matlab.ui.control.UIAxes
    DataLines
    AnalysisROI
    CurrentEditLine
    EditorCorrectionLines
  end

  properties (Access=private) % props for interactive axis
    lastEditClickedPoint  double  = []
    lastEditHitObject             = []
    currentROITag   (1,1) string  = ""
    selectedROI                   = []
    currentAlpha    (1,1) double
    didClickROI     (1,1) logical = false
    didClickEdit    (1,1) logical = false
    isMouseDown     (1,1) logical = false
    didChange       (1,1) logical = false
    isinit          (1,1) logical = false
    EditTarget      (1,1) string = ""
    ptMgr = @(roi,self) struct( ...
      enterFcn= @(s,e)self.onSetPointer(s,roi,'in'), ...
      exitFcn= @(s,e)self.onSetPointer(s,roi,'out'), ...
      traverseFcn= [] ...
      );
  end

  properties (Access=private) % SETTINGS
    rawBackup = {}
    setting_Precision
    setting_FilterBandwidth
    setting_ShowWarnOnApply
    lastLoadDirectory = ""
    lastSaveDirectory = ""
  end

  properties (Dependent)
    roiWidth
    dataLimits
    analysisLimits
    selectedDataLine
    selectedDevice
    datumIndex
    hasEditTarget
  end

  methods
    % CONSTRUCTOR
    function app = artifactRemover(data)
      if nargin < 1, data = []; end
      app = app@IrisModule(data);
    end

    % GET/SET
    % Main Data Setter: Required by IRIS
    function setData(app,data)
      % call superclass method:
      % superclass sets the Data property and validates the data type (IrisData)
      % data is also allowed to be an empty array ([]), so we should perform a check
      % before trying to use it.
      % REMEMBER: IrisData objects are VALUE objects, so self.Data will be a clone,
      % and NOT A POINTER, to the input argument data.
      
      % verify if we are overwriting an existing data file
      doClear = app.hasdata;
      % set the data property using the superclass method      
      setData@IrisModule(app,data);

      % now that data is set or cleared, let's update the UI accordingly
      hasData = app.hasdata;
      set( ...
        [ ...
        app.EditControlLayout.Children; ...
        app.DeviceDropDown; ...
        app.DataPropMenu; ...
        app.InclusionsMenu; ...
        app.StartSpinner; ...
        app.EndSpinner; ...
        app.DecrementDataButton; ...
        app.IncrementDataButton;...
        app.DatumIndexField; ...
        app.ExportMenu; ...
        app.SaveMenu; ...
        app.RevertMenu ...
        ], ...
        'Enable', ...
        hasData ...
        );

      if ~hasData
        app.ClearView();
        app.DatumIndexField.Value = 1;
        app.DatumIndexField.Limits = [1 1];
        return
      end

      % initialize data view
      if doClear
        app.ClearView();
      end
      % set device from data
      devices = app.Data.AvailableDevices;
      app.DeviceDropDown.Items = devices;
      app.DeviceDropDown.Value = devices{1};
      app.DatumIndexField.Value = 1;
      app.DatumIndexField.Limits = [1 app.Data.nDatums+0.1];
      
      % draw data
      app.initialize();
    end

    function w = get.roiWidth(app)
      w=[];
      if ~app.hasdata || isempty(app.dataLimits), return; end
      w(1) = app.ROI_FRACTION * diff(app.dataLimits.X) / 2;
    end

    function dev = get.selectedDevice(app)
      dev = [];
      if ~app.hasdata, return; end
      dev = app.DeviceDropDown.Value;
    end

    function l = get.dataLimits(app)
      l = [];
      if ~app.hasdata, return; end
      d = app.Data(app.datumIndex);
      l = d.getDomains(app.selectedDevice);
    end

    function idx = get.datumIndex(app)
      idx = [];
      if ~app.hasdata, return; end
      idx = app.DatumIndexField.Value;
    end

    function reg = get.analysisLimits(app)
      reg = [app.StartSpinner.Value,app.EndSpinner.Value];
    end

    function L = get.selectedDataLine(app)
      L = [];
      if ~app.hasdata, return; end
      dLabel = string(app.Data.IndexMap(app.datumIndex));
      dInd = startsWith(get(app.DataLines,'DisplayName'),dLabel+"-");
      L = app.DataLines(dInd);
    end

    function tf = get.hasEditTarget(app)
      tf = ~isempty(app.EditTarget) && (app.EditTarget ~= "");
    end
    
    function spinner = getSpinnerFromTag(app,tag)
      tag = char(tag);
      spinner = app.(sprintf('%s%sSpinner',upper(tag(1)),lower(tag(2:end))));
    end
    
    function setPrecision(app)
      app.EndSpinner.Step = 10^(-app.setting_Precision);
      app.EndSpinner.ValueDisplayFormat = sprintf('%%.%df',app.setting_Precision);
      app.StartSpinner.Step = 10^(-app.setting_Precision);
      app.StartSpinner.ValueDisplayFormat = sprintf('%%.%df',app.setting_Precision);
    end
  
    function [pts,lns] = getCorrectionLinesByTag(app,target)
      pts = [];
      lns = [];
      if isempty(app.EditorCorrectionLines),return; end
      pts = app.EditorCorrectionLines( ...
        ismember({app.EditorCorrectionLines.Tag},target+"_P") ...
        );
      lns = app.EditorCorrectionLines( ...
        ismember({app.EditorCorrectionLines.Tag},target+"_C") ...
        );
    end

  end

  methods (Access = protected)


    %%% REQUIRED METHODS

    function startupFcn(app)
      % STARTUPFCN Startup routine for module

      % Give module a name
      app.Name = "Artifact Remover";

      % update precision
      app.setPrecision();

      %%% Bind callback functions
      iptPointerManager(app.container,'enable'); % requires image processing toolbox

      % menus
      app.LoadMenu.MenuSelectedFcn = @app.onLoadData;
      app.ExportMenu.MenuSelectedFcn = @app.onExportData;
      app.DataPropMenu.MenuSelectedFcn = @app.onViewDataProperties;
      app.InclusionsMenu.MenuSelectedFcn = @app.onEditDataInclusions;
      app.SettingsMenu.MenuSelectedFcn = @app.onViewSettings;
      app.SaveMenu.MenuSelectedFcn = @app.onSaveChanges;
      app.RevertMenu.MenuSelectedFcn = @app.onRevertChanges;
      app.CloseMenu.MenuSelectedFcn = @(s,e)app.onClose();

      % ui components
      app.ToggleDataButton.ValueChangedFcn = @app.onToggleDataView;
      app.DatumIndexField.ValueChangedFcn = @app.onDatumIndexChanged;
      app.IncrementDataButton.ButtonPushedFcn = @app.onDatumIndexChanged;
      app.DecrementDataButton.ButtonPushedFcn = @app.onDatumIndexChanged;
      app.DeviceDropDown.ValueChangedFcn = @app.onDeviceChanged;
      app.StartSpinner.ValueChangedFcn = @app.onSpinnerChanged;
      app.EndSpinner.ValueChangedFcn = @app.onSpinnerChanged;
      app.UndoButton.ButtonPushedFcn = @app.onUndoLastCorrection;
      app.AddButton.ButtonPushedFcn = @app.onAddNewCorrection;
      app.RemoveButton.ButtonPushedFcn = @app.onRemoveLastCorrection;
      app.ApplyButton.ButtonPushedFcn = @app.onApplyCurrentCorrections;
      app.EditorTable.SelectionChangedFcn = @app.onEditorColumnSelected;

      % window
      app.container.WindowButtonDownFcn = @app.onWindowClickCapture;
      app.container.WindowButtonMotionFcn = @app.onWindowMotionCapture;
      app.container.WindowButtonUpFcn = @app.onWindowReleaseCapture;
    end

    createUI(app)

    function loadPreferences(app)
      loadPreferences@IrisModule(app);
      % individually load settings to set defaults
      app.setting_Precision = app.getPref("Precision",5);
      app.setting_FilterBandwidth = app.getPref("FilterBandwidth", 1000);
      app.setting_ShowWarnOnApply = app.getPref("ShowWarnOnApply", true);
      app.lastLoadDirectory = app.getPref("lastLoadDir","");
      app.lastSaveDirectory = app.getPref("lastSaveDir","");
    end

    function savePreferences(app)
      savePreferences@IrisModule(app);
      % gather settings property names from metaclass
      m = metaclass(app);
      p = string({m.PropertyList.Name});
      p(~startsWith(p,"setting_")) = [];
      p = regexprep(p,"^setting_","");
      % loop and store
      for prop = p
        app.putPref(prop,app.(sprintf("setting_%s",prop)));
      end
      % save/load directories
      app.putPref("lastLoadDir",app.lastLoadDirectory);
      app.putPref("lastSaveDir",app.lastSaveDirectory);
    end

    function onClose(app)
      if app.hasdata
        p = iris.ui.questionBox( ...
          Title= 'Save and Export?', ...
          Options= {'Save','Quit','Cancel'}, ...
          Prompt= 'Save any changes and export file?', ...
          Default= 'Quit' ...
          );
        switch p.response
          case 'Save'
            % run save and export
            app.onExportData([],[]);
            pause(0.1);
          case 'Cancel'
            return
          otherwise
            % NO/Quit
        end
      end
      % run the close method to delete the app
      onClose@IrisModule(app);
    end

  end

  methods (Access = private)

    %%% CUSTOM METHODS

    initialize(app)
    ClearView(app)
    updateDatum(app)
    updateEditLine(app)
    setActiveCorrectionIndex(app,idx)
    processEditClick(app,type)
    updateEditCorrectionLines(app)
    drawCorrections(app,result)
    

    %%% CALLBACKS

    % menus
    onLoadData(app,src,evt)
    onExportData(app,src,evt)
    onViewDataProperties(app,src,evt)
    onEditDataInclusions(app,src,evt)
    onSaveChanges(app,src,evt)
    onRevertChanges(app,src,evt)

    % Settings
    onViewSettings(app,src,evt)
    onCloseSettings(app,src,evt)

    % Manage Edit Axes actions
    onUndoLastCorrection(app,src,evt)
    onAddNewCorrection(app,src,evt)
    onRemoveLastCorrection(app,src,evt)
    onApplyCurrentCorrections(app,src,evt)
    onEditorColumnSelected(app,src,evt)

    % Manage device changed
    function onDeviceChanged(app,~,~)
      % clear current fields
      app.ClearView();
      % re-initialize with new device
      app.initialize();
    end

    % Manage ROI Changes and Window Mouse events
    onSpinnerChanged(app,src,evt)
    onWindowClickCapture(app,src,evt)
    onDataClickPress(app,src,evt)
    onWindowMotionCapture(app,src,evt)
    onDataClickDrag(app,src,evt)
    onWindowReleaseCapture(app,src,evt)
    onDataClickRelease(app,src,evt)
    onSetPointer(app,fig,src,type)

    
    % Manage Data manipulations
    onDatumIndexChanged(app,src,evt)

    % Manage UI modifications
    onToggleDataView(app,src,evt)
    
  end

  methods (Static)

    [xValue,yValue] = getNearestDataPoint(target,Xs,Ys,radiusStep)
    tf = isWithinRange(values,extents,inclusive)
    value = ternary(condition,whenTrue,whenFalse)
    result = computeCorrection(pts,data,target)
    par = pointPar(color,target)
    par = linePar(color,target)
    
  end

end
