classdef spectralAnalyzer < IrisModule
  % spectralAnalyzer View spectral analysis of windowed region.
  % todo: create export
  properties (Constant)
    ALPHA           = 0.7
    ALPHA_DRAG      = 0.2
    ALPHA_HOVER     = 0.5
    ROI_FRACTION    = 0.0025
    ROI_TAG         = ["START","END"]
  end

  properties % UI Elements
    MenuFile             matlab.ui.container.Menu
    MenuImport           matlab.ui.container.Menu
    MenuView             matlab.ui.container.Menu
    MenuSettings         matlab.ui.container.Menu
    MenuDataProp         matlab.ui.container.Menu
    MenuUpdate           matlab.ui.container.Menu
    MenuExport           matlab.ui.container.Menu
    MenuAppend           matlab.ui.container.Menu
    MenuNew              matlab.ui.container.Menu
    MenuEdit             matlab.ui.container.Menu
    MenuInclusions       matlab.ui.container.Menu
    MainLayout           matlab.ui.container.GridLayout
    ControlLayout        matlab.ui.container.GridLayout
    EndSpinner           matlab.ui.control.Spinner
    EndLabel             matlab.ui.control.Label
    StartSpinner         matlab.ui.control.Spinner
    StartSpinnerLabel    matlab.ui.control.Label
    DeviceDropDown       matlab.ui.control.DropDown
    DeviceDropDownLabel  matlab.ui.control.Label
    SpectrumAxes         matlab.ui.control.UIAxes
    DataAxes             matlab.ui.control.UIAxes
    SelectedLineLabel    matlab.ui.control.Label
    EventCutterButton    matlab.ui.control.Button
    DataLines
    SpectrumLines
    AnalysisROI
  end

  properties %(Access=private) % Settings
    setting_Lowcut_Frequencies
    setting_Spectral_Cut_Frequency
    setting_Window_Duration
    setting_Overlap_Duration
    setting_Windowing_Function
    setting_YGrid
    setting_XGrid
    setting_YScale
    setting_XScale
  end

  properties %(Access=private) % props for interactive axis
    currentROITag   (1,1) string  = ""
    selectedROI                   = []
    currentAlpha    (1,1) double
    didClickROI     (1,1) logical = false
    isMouseDown     (1,1) logical = false
    didChange       (1,1) logical = false
    dataLimits                    = []
    ptMgr = @(roi,self) struct( ...
      enterFcn= @(s,e)self.onSetPointer(s,roi,'in'), ...
      exitFcn= @(s,e)self.onSetPointer(s,roi,'out'), ...
      traverseFcn= [] ...
      );
  end

  properties (Dependent)%,Access=private)
    roiWidth
    selectedDevice
    analysisRegion
  end

  methods

    % Constructor
    function self = spectralAnalyzer(data)
      if nargin < 1, data = []; end
      self = self@IrisModule(data);
    end

    % GET/SET
    function w = get.roiWidth(self)
      w=[];
      if ~self.hasdata || isempty(self.dataLimits), return; end
      w(1) = self.ROI_FRACTION * diff(self.dataLimits) / 2;
    end

    function dev = get.selectedDevice(self)
      dev = [];
      if ~self.hasdata, return; end
      dev = self.DeviceDropDown.Value;
    end

    function reg = get.analysisRegion(self)
      reg = [self.StartSpinner.Value,self.EndSpinner.Value];
    end

    function spinner = getSpinnerFromTag(self,tag)
      tag = char(tag);
      spinner = self.(sprintf('%s%sSpinner',upper(tag(1)),lower(tag(2:end))));
    end

    function analysisProps = getAnalysisProperties(self)
      sKeys = self.getPrefKeys();
      sKeys(~startsWith(sKeys,'setting')) = [];
      sKeys(contains(sKeys,["Grid","Scale"])) = []; % remove ui settings
      % get analysis region for parsing
      reg = self.analysisRegion;
      analysisProps = [ ...
        [ ...
          cellstr(regexprep(regexprep(sKeys,"setting_",""),"_"," ")).'; ...
          { ...
            'AnalysisWindowStartTime'; ...
            'AnalysisWindowEndTime'; ...
            'AnalysisWindowDuration'; ...
            'AnalysisDevice' ...
          } ...
        ], ...
        [ ...
          arrayfun(@(k)self.(k),sKeys,'UniformOutput',false).'; ...
          { ...
            reg(1); ...
            reg(2); ...
            diff(reg); ...
            self.selectedDevice ...
          } ...
        ] ...
        ];
    end

    % Handle setting data
    function setData(self,data)
      % call superclass method first:
      % superclass sets the Data property and validates the data type (IrisData)
      % data is also allowed to be an empty array ([]), so we should perform a check
      % before trying to use it.
      % REMEMBER: IrisData objects are VALUE objects, so self.Data will be a clone,
      % and NOT A POINTER, to the input argument data.
      setData@IrisModule(self,data);

      % now that data is set or cleared, let's update the UI accordingly
      hasData = self.hasdata;
      self.MenuDataProp.Enable = hasData;
      self.DeviceDropDown.Enable = hasData;
      self.StartSpinner.Enable = hasData;
      self.EndSpinner.Enable = hasData;
      self.MenuInclusions.Enable = hasData;
      if ~hasData
        delete(self.DataLines);
        self.DataLines = [];
        delete(self.AnalysisROI);
        self.AnalysisROI = [];
        self.dataLimits = [];
        return
      end

      % initialize data view
      % set device from data
      devices = self.Data.AvailableDevices;
      self.DeviceDropDown.Items = devices;
      self.DeviceDropDown.Value = devices{1};
      
      % draw new data
      self.updateDataView();
    end
    
    function d = getData(self)
      d = self.Data.CleanInclusions().Filter( ...
        'frequencies',self.setting_Lowcut_Frequencies,'devices',self.selectedDevice ...
        );
    end
    
    editSelectedDatum(self,src,evt)
  end

  methods (Access=protected)

    function startupFcn(self)
      % predefine some properties
      self.currentAlpha = self.ALPHA;
      iptPointerManager(self.container,'enable'); % requires image processing toolbox

      %%% Bind callback functions

      % menus
      self.MenuImport.MenuSelectedFcn = @self.onLoadData;
      self.MenuDataProp.MenuSelectedFcn = @self.onViewDataProperties;
      self.MenuSettings.MenuSelectedFcn = @self.onViewSettings;
      self.MenuUpdate.MenuSelectedFcn   = @self.onForceUpdate;
      self.MenuInclusions.MenuSelectedFcn = @self.onEditDataInclusions;
      self.MenuAppend.MenuSelectedFcn = @self.onExportAppend;
      self.MenuNew.MenuSelectedFcn = @self.onExportNew;

      % ui components
      self.DeviceDropDown.ValueChangedFcn = @self.onDeviceChanged;
      self.StartSpinner.ValueChangedFcn = @self.onSpinnerChanged;
      self.EndSpinner.ValueChangedFcn = @self.onSpinnerChanged;

      % window
      self.container.WindowButtonDownFcn = @self.onDataClickPress;
      self.container.WindowButtonMotionFcn = @self.onDataClickDrag;
      self.container.WindowButtonUpFcn = @self.onDataClickRelease;

    end
  
    %%% CALLBACKS
    
    % callbacks in files
    


    function onLoadData(self,~,~)
      disp('load file...')
    end

    function onExportNew(self,~,~)
      devPrompt = iris.ui.promptBox( ...
        Title= 'Name Output Device', ...
        Prompts={'Set Output Device Name:'}, ...
        Defaults={sprintf('%s_Spectrum',self.selectedDevice)}, ...
        Labels={'OutputName'}, ...
        Width= 400, ...
        ButtonLabel='Set', ...
        AllowDefaults=true ...
        );
      if ~devPrompt.validClose
        warning("SPECTRALANALYZER:ONEXPORTNEW","Export cancelled!");
        return
      end
      filterText = [
        {'*.idata', 'IrisData File'};
        {'*.csv', 'Comma-Separated Values'};
        {'*.tsv', 'Tab-Separated Values'}
        ];
      [userFile, ~, ~, fType] = iris.app.Info.putFile( ...
        'Save IrisData File', ...
        filterText, ...
        regexprep(self.Data.Files(1),"\.idata","_spectrum.idata") ...
        );
      self.container.Pointer = 'watch';
      drawnow();
      cu = onCleanup(@()set(self.container.Pointer,'arrow'));
      % collect the data
      iData = self.Data.CleanInclusions();
      cdata = iData.copyData();
      N = iData.nDatums;
      idMap = iData.IndexMap(1:N);
      analysisProps = self.getAnalysisProperties();
      for datum = 1:N
        spect = findobj(self.SpectrumAxes,'tag',sprintf("Spectrum#%d",idMap(datum)));
        x = spect.XData(:);
        y = spect.YData(:);
        cdata(datum).devices = {devPrompt.response.OutputName};
        cdata(datum).sampleRate = {1/mean(diff(x(2:end)))};
        cdata(datum).units = {struct(x="Hz",y=self.SpectrumAxes.YLabel.String)};
        cdata(datum).protocols(end+(1:size(analysisProps,1)),:) = analysisProps;
        cdata(datum).x = {x};
        cdata(datum).y = {y};
        cdata(datum).index = double(datum);
        cdata(datum).nDevices = 1;
      end
      iData = iData.UpdateData(cdata);
      switch filterText{fType,1}
        case '*.idata'
          save(userFile,'iData');
          return %%%%%%%%%%%%%% EXIT POINT FOR IRISDATA EXPORT
        case '*.csv'
          delim = ",";
        case '*.tsv'
          delim = "\t";
      end
      % gather data as matrix
      dataMatrix = iData.getDataMatrix('devices',devPrompt.response.OutputName);
      [dL,dN] = size(dataMatrix.x{1});
      % create a writing specification anon. fcn
      wSpec = @(t, n)strcat(strjoin(IrisData.rep(t, n), delim), "\n");
      % create data labeler
      dLab = @(dim)sprintf("%s%%d_%s",dim,dataMatrix.units{1}(dim));
      % create labels
      dataLabels = [ ...
        string(sprintfc(dLab('x'),1:dN)), ...
        string(sprintfc(dLab('y'),1:dN)) ...
        ];
      % open file
      fid = fopen(userFile,'w'); % overwrite contents
      cl
      if fid < 0
        error("Could not create file: %s\n",userFile);
      end
      % write the column names
      fprintf(fid,wSpec("%s",dN * 2),dataLabels);
      % write the data rows
      for row = 1:dL
        fprintf(fid,wSpec("%f",dN * 2), [dataMatrix.x{1}(row,:),dataMatrix.y{1}(row,:)]);
      end
      fclose(fid);
      pause(0.01);
      fprintf("Data saved to:\n\t'%s'\n",userFile);
    end
    
    function onExportAppend(self,~,~)

      newData = self.Data.CleanInclusions();
      idMap = newData.IndexMap(1:newData.nDatums);
      dev = struct( ...
        Name={{'Magnitude Spectrum'}}, ...
        Units= {{struct(x="Hz",y=self.SpectrumAxes.YLabel.String)}}, ...
        SampleRate= {{}}, ...
        Data= {{}} ...
        );
      fftStruct(1:newData.nDatums,1) = struct(x=[],y=[]);
      for datum = 1:newData.nDatums
        spect = findobj(self.SpectrumAxes,'tag',sprintf("Spectrum#%d",idMap(datum)));
        fftStruct(datum).x = spect.XData(:);
        fftStruct(datum).y = spect.YData(:);
        if datum == 1
          dev.SampleRate{1} = 1/mean(diff(spect.XData(2:end)));
        end
      end
      dev.Data{1} = fftStruct;
      % append analysis parameters
      analysisProps = self.getAnalysisProperties();
      analysisProps = analysisProps.';
      analysisProps(1,:) = regexprep(analysisProps(1,:),"\s","");
      newData = newData.AppendDevices(dev,analysisProps{:});
      outputFile = iris.app.Info.putFile( ...
        'Export IrisData File', ...
        {'*.idata', 'IrisData File'}, ...
        regexprep(newData.Files(1),"\.idata","_spectrum.idata") ...
        );
      save(outputFile, 'newData', '-mat', '-v7.3');
    end

    function onViewDataProperties(self,~,~)
      % assume only called when data is available
      self.Data.view("properties");
    end

    function onViewSettings(self,~,~)
      sKeys = self.getPrefKeys();
      sKeys(~startsWith(sKeys,'setting')) = [];
      keyNames = regexprep(regexprep(sKeys,"setting_",""),"_"," ");
      N = numel(keyNames);

      sWin = utilities.createIrisUiFigure("Settings",460,32*(N+1)+40+5*N,true);
      lo = uigridlayout( ...
        sWin, ...
        [N+3,5], ...
        RowSpacing= 5, ...
        ColumnSpacing= 5, ...
        BackgroundColor= [1,1,1], ...
        ColumnWidth={'1x','fit',60,'fit','1x'}, ...
        RowHeight=  [{'1x'};repelem({32},N,1);{'1x'};26], ...
        Padding= 10 ...
        );
      cObj = gobjects(N,2);
      for row = 1:N
        cObj(row,1) = uilabel(lo);
        cObj(row,1).Layout.Row = row+1;
        cObj(row,1).Layout.Column = 2;
        cObj(row,1).Text = keyNames(row)+":";
        cObj(row,1).HorizontalAlignment = 'right';
        cObj(row,2) = uieditfield(lo);
        cObj(row,2).Layout.Row = row+1;
        cObj(row,2).Layout.Column = 4;
        value = self.(sKeys(row));
        vClass = class(value);
        cObj(row,2).Tag = sKeys(row) + ":" + vClass;
        cObj(row,2).Value = string(value);        
        cObj(row,2).ValueChangedFcn = @self.onSettingUpdated;
      end

      btn = uibutton(lo);
      btn.Layout.Row = N+3;
      btn.Layout.Column = 3;
      btn.Text = "Done";
      btn.ButtonPushedFcn = @self.onCloseSettings;
      
      sWin.CloseRequestFcn = @self.onCloseSettings;
      
      sWin.WindowStyle = 'modal';
      uiwait(sWin);
    end
    
    function onCloseSettings(self,src,~)
      sWin = ancestor(src,'figure');
      delete(sWin);
      self.savePreferences();
      self.updateDataView();
    end

    function onSettingUpdated(self,src,evt)
      tags = string(strsplit(src.Tag,":"));
      value = string(evt.Value);
      if tags(2) ~= "string"
        value = cast(value,tags(2));
      end
      self.(tags(1)) = value;
    end

    function onForceUpdate(self,~,~)
      self.didChange = true;
      self.updateAnalysis();
    end

    function onEditDataInclusions(self,~,~)
      inc = self.Data.InclusionList;
      newData = self.Data.uiSetInclusionList();
      if ~all(inc & newData.InclusionList)
        self.Data = newData;
        self.didChange = true;
      end
      self.updateDataView();
    end

    function onSetPointer(self,fig,src,type)
      switch type
        case 'in'
          ptr = 'left';
          alpha = self.ALPHA_HOVER;
          self.currentROITag = src.Tag;
        otherwise
          ptr = 'arrow';
          alpha = self.ALPHA;
          self.currentROITag = "";
      end
      fig.Pointer = ptr;
      src.FaceAlpha = alpha;
    end

    % window button callbacks for dragging ROI
    function onDataClickPress(self,src,~)
      if ~self.hasdata, return; end
      if strcmp(self.currentROITag,'')
        self.selectedROI = [];
        self.didClickROI = false;
        set(self.DataLines,LineWidth=0.5);
        set(self.SpectrumLines,LineWidth=0.5,MarkerSize=6);
        self.SelectedLineLabel.Text = "";
        self.EventCutterButton.Enable = false;
        return
      end
      self.selectedROI = findobj(src,"Tag",self.currentROITag);
      self.currentAlpha = self.selectedROI.FaceAlpha;
      self.selectedROI.FaceAlpha = self.ALPHA_DRAG;
      self.didClickROI = true;
      self.isMouseDown = true;
      if strcmp(src.SelectionType,'open')
        switch self.currentROITag
          case "START"
            id = 1;
            spin = self.StartSpinner;
          case "END"
            id = 2;
            spin = self.EndSpinner;
        end
        lims = self.dataLimits;
        self.selectedROI.Vertices(:,1) = ...
          self.selectedROI.Vertices(:,1) - ...
          mean(self.selectedROI.Vertices(:,1)) + ...
          lims(id);
        spin.Value = lims(id);
        % double-click causes update
        self.didChange = true;
      end
    end

    function onDataClickRelease(self,~,~)
      if ~self.hasdata, return; end
      if self.didClickROI
        % released after click/drag on ROI
        if any(ismember(self.ROI_TAG,self.currentROITag))
          % still hovering
          nAlpha = self.currentAlpha;
        else
          % not still hovering
          nAlpha = self.ALPHA;
        end
        self.selectedROI.FaceAlpha = nAlpha;
      end
      % on release, let go of the selected roi
      self.selectedROI = [];
      self.isMouseDown = false;
      if self.didChange
        self.updateAnalysis();
      end
    end

    function onDataClickDrag(self,src,~)
      if self.didClickROI && self.isMouseDown
        % dragging allowed
        hAx = self.selectedROI.Parent;
        lims = self.dataLimits;
        % new location
        thisX = hAx.CurrentPoint(1,1);
        thisTag = self.selectedROI.Tag;

        verts = self.selectedROI.Vertices;
        vertCenter = mean(verts([1,end],1));

        switch thisTag
          case "START"
            other = findobj(src,"Tag","END");
            allowedRange = [ ...
              lims(1), ...
              mean(other.Vertices([1,end],1)) ...
              ];
          case "END"
            other = findobj(src,"Tag","START");
            allowedRange = [ ...
              mean(other.Vertices([1,end],1)), ...
              lims(2) ...
              ];
        end
        if ~utilities.isWithinRange(thisX,allowedRange,false)
          return
        end
        if round(abs(thisX-vertCenter),5) > (self.roiWidth*0.01)
          self.didChange = true;
        else
          self.didChange = false;
        end
        self.selectedROI.Vertices(:,1) = verts(:,1) - vertCenter + thisX;
        self.selectedROI.FaceAlpha = self.ALPHA_DRAG;
        spinner = self.getSpinnerFromTag(thisTag);
        spinner.Value = thisX;
        drawnow();
      end
    end

    function onDeviceChanged(self,~,evt)
      self.didChange = ~strcmp(evt.Value,evt.PreviousValue);
      if ~self.didChange, return; end
      self.updateDataView();
    end

    function onSpinnerChanged(self,src,evt)
      newValue = evt.Value;
      switch src.Tag
        case "OPEN"
          roiTag = self.ROI_TAG(1);
          otherTag = self.ROI_TAG(2);
          limIdx = 1;
        case "CLOSE"
          roiTag = self.ROI_TAG(2);
          otherTag = self.ROI_TAG(1);
          limIdx = 2;
      end
      roi = findobj(self.container,"Tag",roiTag);
      other = findobj(self.container,"Tag",otherTag);
      allowedRange = sort( ...
        [ ...
        mean(other.Vertices(:,1)), ...
        self.dataLimits(limIdx) ...
        ] ...
        );
      if ~utilities.isWithinRange(newValue,allowedRange,true)
        [~,newValue] = utilities.getNearestDataPoint(newValue,1:2,allowedRange);
      end
      self.didChange = newValue ~= evt.PreviousValue;
      roi.Vertices(:,1) = roi.Vertices(:,1) - mean(roi.Vertices(:,1)) + newValue;
      src.Value = newValue;
      self.updateAnalysis();
    end

    function onLineClicked(self,src,~)
      datum = regexprep(src.Tag,"[^#]+#","");
      self.SelectedLineLabel.Text = sprintf("Datum #%s",datum);
      self.SelectedLineLabel.FontColor = src.Color;
      set(self.SpectrumLines,"LineWidth",0.5,"MarkerSize",6);
      src.LineWidth = 2;
      src.MarkerSize = 12;
      idx = ismember(self.SpectrumLines,src);
      self.SpectrumAxes.Children = [self.SpectrumLines(idx);self.SpectrumLines(~idx)];
      dSrc = findobj(self.DataAxes,"DisplayName",sprintf("%s-%s",datum,self.selectedDevice));
      dIdx = ismember(self.DataLines,dSrc);
      set(self.DataLines,"LineWidth",0.5);
      dSrc.LineWidth = 2;
      self.DataAxes.Children(3:end) = [self.DataLines(dIdx);self.DataLines(~dIdx)];
      self.EventCutterButton.Enable = true;
      drawnow();
    end
    
    %%% CUSTOM METHODS

    function updateDataView(self)
      % clear plot window
      % clear data axes
      delete(self.DataLines);
      delete(self.AnalysisROI);
      delete(self.SpectrumLines);

      device = self.selectedDevice;
      % set device data limits
      tmp = self.Data.Filter('frequencies',self.setting_Lowcut_Frequencies,'devices',device);
      dLim = tmp.getDomains(device);
      self.dataLimits = utilities.domain(dLim.X(:));
      if self.Data.nDatums > 1, colorize = true; else, colorize = false; end
      h = plot(tmp, ...
        'axes',         self.DataAxes,  ...
        'devices',      device,         ...
        'colorize',     colorize,       ...
        'interactive',  false           ...
        );

      self.DataLines = h.Lines;
      set(self.DataLines,LineWidth=0.5);

      roiW = self.roiWidth;
      lims = self.dataLimits.';
      self.DataAxes.XLim = lims + [-1,1].*roiW;

      drawnow(); % to force update for limits below

      self.AnalysisROI = [                  ...
        patch(                                ...
        self.DataAxes,                      ...
        (lims(ones(1,4))+[-1,-1,1,1].*roiW).', ...
        self.DataAxes.YLim([1,2,2,1]).',    ...
        [0,0.1,0.6],                        ...
        FaceColor=      [0,0.1,0.6],        ...
        FaceAlpha=      self.ALPHA,         ...
        LineStyle=      'none',             ...
        Tag=            self.ROI_TAG(1)     ...
        );                                ...
        patch(                                ...
        self.DataAxes,                      ...
        (lims(ones(1,4)+1)+[-1,-1,1,1].*roiW).', ...
        self.DataAxes.YLim([1,2,2,1]).',    ...
        [0.6,0.1,0],                        ...
        FaceColor=      [0.6,0.1,0],        ...
        FaceAlpha=      self.ALPHA,         ...
        LineStyle=      'none',             ...
        Tag=            self.ROI_TAG(2)     ...
        )                                 ...
        ];
      arrayfun( ...
        @(roi)iptSetPointerBehavior(roi,self.ptMgr(roi,self)), ...
        self.AnalysisROI ...
        );
      self.StartSpinner.Limits = lims;
      self.StartSpinner.Value = lims(1);
      self.EndSpinner.Limits = lims;
      self.EndSpinner.Value = lims(2);

      self.didChange = true;
      self.updateAnalysis();
    end

    function updateAnalysis(self)
      if ~self.didChange, return; end
      % update change status
      self.didChange = false;
      
      % cleanup
      delete(self.SpectrumLines);
      self.SpectrumLines = [];
      
      self.container.Pointer = 'watch';
      drawnow();
      
      % parameters
      tmp = self.Data.CleanInclusions();
      dMatrix = tmp.Filter( ...
        'frequencies',self.setting_Lowcut_Frequencies,'devices',self.selectedDevice ...
        ).getDataMatrix( ...
        'devices', self.selectedDevice ...
        );
      nData = size(dMatrix.y{1},2);

      devloc = self.Data.DeviceMap(self.selectedDevice);
      fs = self.Data.Data(1).sampleRate{devloc(1)};
      units = self.Data.Data(1).units{devloc(1)};
      xvals = mean(dMatrix.x{1},2,'omitnan');
      analysisWindow = xvals >= self.StartSpinner.Value & xvals <= self.EndSpinner.Value;
      for d = 1:nData
        dat = dMatrix.y{1}(analysisWindow,d);
        idLabel = string(tmp.getOriginalIndex(d));
        promise(d) = parfeval( ...
          backgroundPool, ...
          @spectralAnalyzer.windowedPSD, ...
          4, ...
          dat, ...
          fs, ...
          idLabel, ...
          'windowDuration',self.setting_Window_Duration, ...
          'windowOverlap',self.setting_Overlap_Duration, ...
          'windowFx',self.setting_Windowing_Function, ...
          'NFFT', 2^nextpow2(fs*self.setting_Window_Duration), ...
          'TruncateFrequency', self.setting_Spectral_Cut_Frequency, ...
          'Color', self.DataLines(d).Color ...
          ); %#ok<AGROW> 
      end
      LineOut = afterEach(promise,@doPlot,1);
      self.SpectrumLines = fetchOutputs(LineOut);
      self.SpectrumAxes.XLimMode = 'auto';
      self.SpectrumAxes.YLimMode = 'auto';
      self.SpectrumAxes.YLabel.String = sprintf("%s^2Hz^{-1}",units.y);
      self.SpectrumAxes.XLabel.String = 'Hz';
      self.updateVisualParameters();
      % return to arrow pointed when done
      set(self.SpectrumLines,"ButtonDownFcn",@self.onLineClicked);
      self.container.Pointer = 'arrow';
      % plot function
      function L = doPlot(x,y,col,id)
        L = line( ...
          self.SpectrumAxes, ...
          x, y, ...
          Color=col, ...
          LineWidth=0.5, ...
          Marker= '.', ...
          MarkerFaceColor= col, ...          
          Tag= sprintf("Spectrum#%s",id) ...
          );
        ax = ancestor(L,'axes');
        L.DisplayName = sprintf("%s;y:%s;x:%s",id,ax.YLabel.String,ax.XLabel.String);
        dt = datatip(L,0,0,'visible','off');
        delete(dt);
        L.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow("Datum",repelem(id,numel(x)));
        drawnow();        
      end
    end

    function updateVisualParameters(self)
      self.SpectrumAxes.XScale = self.setting_XScale;
      self.SpectrumAxes.YScale = self.setting_YScale;
      self.SpectrumAxes.XGrid = self.setting_XGrid;
      self.SpectrumAxes.YGrid = self.setting_YGrid;
    end
    
    
    %%% REQUIRED METHODS
    function createUI(self)
      % Give Module Name
      self.Name = "Spectral Analyzer";

      % set the position
      self.Position = IrisModule.getCenteredPosition(900,600);
      drawnow();

      % Create MenuFile
      self.MenuFile = uimenu(self.container);
      self.MenuFile.Text = 'File';
      
      % Create MenuImport
      self.MenuImport = uimenu(self.MenuFile);
      self.MenuImport.Text = 'Load IrisData';
      
      % Create MenuView
      self.MenuView = uimenu(self.container);
      self.MenuView.Text = 'View';

      % Create MenuDataProp
      self.MenuDataProp = uimenu(self.MenuView);
      self.MenuDataProp.Enable = false;
      self.MenuDataProp.Text = 'Data Properties';

      % Create MenuUpdate
      self.MenuUpdate = uimenu(self.MenuView);
      self.MenuUpdate.Separator = 'on';
      self.MenuUpdate.Text = 'Update';

      % Create MenuEdit
      self.MenuEdit = uimenu(self.container);
      self.MenuEdit.Text = "Edit";

      % Create MenuInclusions
      self.MenuInclusions = uimenu(self.MenuEdit);
      self.MenuInclusions.Enable = false;
      self.MenuInclusions.Text = "Data Inclusions";

      % Create MenuSettings
      self.MenuSettings = uimenu(self.MenuEdit);
      self.MenuSettings.Text = 'Settings';
      
      % Create MenuExport
      self.MenuExport = uimenu(self.container);
      self.MenuExport.Text = "Export";

      % Create MenuAppend
      self.MenuAppend = uimenu(self.MenuExport);
      self.MenuAppend.Text = "Append";

      % Create MenuNew
      self.MenuNew = uimenu(self.MenuExport);
      self.MenuNew.Text = "New";
      
      % Create MainLayout
      self.MainLayout = uigridlayout(self.container);
      self.MainLayout.ColumnWidth = {'1x'};
      self.MainLayout.RowHeight = {'1x', 160, 60};
      self.MainLayout.ColumnSpacing = 5;
      self.MainLayout.RowSpacing = 5;
      self.MainLayout.BackgroundColor = [1 1 1];

      % Create DataAxes
      self.DataAxes = uiaxes(self.MainLayout);
      self.DataAxes.Layout.Row = 2;
      self.DataAxes.Layout.Column = 1;
      disableDefaultInteractivity(self.DataAxes);
      self.DataAxes.Interactions = [];
      self.DataAxes.YAxis.TickDirection = 'out';
      self.DataAxes.XAxis.TickDirection = 'out';
      self.DataAxes.Tag = "DataAxes";
      self.DataAxes.NextPlot = 'add';

      % Create SpectrumAxes
      self.SpectrumAxes = uiaxes(self.MainLayout);
      self.SpectrumAxes.Layout.Row = 1;
      self.SpectrumAxes.Layout.Column = 1;
      self.SpectrumAxes.YAxis.TickDirection = 'out';
      self.SpectrumAxes.XAxis.TickDirection = 'out';
      self.SpectrumAxes.Tag = "SpectrumAxes";
      self.SpectrumAxes.NextPlot = 'add';
      enableDefaultInteractivity(self.SpectrumAxes);

      % Create ControlLayout
      self.ControlLayout = uigridlayout(self.MainLayout);
      self.ControlLayout.ColumnWidth = {90, 90, '1x', 65, '1x'};
      self.ControlLayout.RowHeight = {'1x', 'fit', 'fit', '1x'};
      self.ControlLayout.ColumnSpacing = 5;
      self.ControlLayout.RowSpacing = 5;
      self.ControlLayout.Padding = [5 0 5 5];
      self.ControlLayout.Layout.Row = 3;
      self.ControlLayout.Layout.Column = 1;
      self.ControlLayout.BackgroundColor = [1 1 1];

      % Create DeviceDropDownLabel
      self.DeviceDropDownLabel = uilabel(self.ControlLayout);
      self.DeviceDropDownLabel.Layout.Row = 2;
      self.DeviceDropDownLabel.Layout.Column = 5;
      self.DeviceDropDownLabel.Text = 'Device:';

      % Create DeviceDropDown
      self.DeviceDropDown = uidropdown(self.ControlLayout);
      self.DeviceDropDown.Layout.Row = 3;
      self.DeviceDropDown.Layout.Column = 5;

      % Create StartSpinnerLabel
      self.StartSpinnerLabel = uilabel(self.ControlLayout);
      self.StartSpinnerLabel.Layout.Row = 2;
      self.StartSpinnerLabel.Layout.Column = 1;
      self.StartSpinnerLabel.Text = 'Start:';

      % Create StartSpinner
      self.StartSpinner = uispinner(self.ControlLayout);
      self.StartSpinner.ValueDisplayFormat = '%.3f';
      self.StartSpinner.Step = 0.001;
      self.StartSpinner.Limits = [0,1];
      self.StartSpinner.Layout.Row = 3;
      self.StartSpinner.Layout.Column = 1;
      self.StartSpinner.Tag = "OPEN";

      % Create EndLabel
      self.EndLabel = uilabel(self.ControlLayout);
      self.EndLabel.Layout.Row = 2;
      self.EndLabel.Layout.Column = 2;
      self.EndLabel.Text = 'End:';

      % Create EndSpinner
      self.EndSpinner = uispinner(self.ControlLayout);
      self.EndSpinner.ValueDisplayFormat = '%.3f';
      self.EndSpinner.Step = 0.001;
      self.EndSpinner.Limits = [0,1];
      self.EndSpinner.Layout.Row = 3;
      self.EndSpinner.Layout.Column = 2;
      self.EndSpinner.Tag = "CLOSE";

      % Create SelectedLineLabel
      self.SelectedLineLabel = uilabel(self.ControlLayout);
      self.SelectedLineLabel.Layout.Row = 3;
      self.SelectedLineLabel.Layout.Column = 3;
      self.SelectedLineLabel.Text = "";
      self.SelectedLineLabel.FontColor = [0,0,0];
      self.SelectedLineLabel.HorizontalAlignment = "center";
      self.SelectedLineLabel.VerticalAlignment = "center";
      self.SelectedLineLabel.FontWeight = "bold";

      % Create the edit datum window
      self.EventCutterButton = uibutton(self.ControlLayout);
      self.EventCutterButton.Layout.Row = 3;
      self.EventCutterButton.Layout.Column = 4;
      self.EventCutterButton.Text = "Edit";
      self.EventCutterButton.Enable = 'off';
      self.EventCutterButton.Tooltip = 'Select datum to modify trace in analysis region.';

    end

    function loadPreferences(self)
      loadPreferences@IrisModule(self);
      % load settings
      self.setting_Lowcut_Frequencies   = self.getPref("setting_Lowcut_Frequencies", 100);
      self.setting_Spectral_Cut_Frequency = self.getPref("setting_Spectral_Cut_Frequency",50);
      self.setting_Window_Duration   = self.getPref("setting_Window_Duration"   , 2);
      self.setting_Overlap_Duration  = self.getPref("setting_Overlap_Duration"  , 1.99);
      self.setting_Windowing_Function  = self.getPref("setting_Windowing_Function", "@(n)blackman(n,'periodic')");
      self.setting_YGrid    = self.getPref("setting_YGrid"             , "on");
      self.setting_XGrid    = self.getPref("setting_XGrid"             , "on");
      self.setting_YScale   = self.getPref("setting_YScale"            , "linear");
      self.setting_XScale   = self.getPref("setting_XScale"            , "linear");
    end

    function savePreferences(self)
      savePreferences@IrisModule(self);
      % store updated settings
      self.putPref("setting_Lowcut_Frequencies", self.setting_Lowcut_Frequencies   );
      self.putPref("setting_Spectral_Cut_Frequency", self.setting_Spectral_Cut_Frequency);
      self.putPref("setting_Window_Duration"   , self.setting_Window_Duration      );
      self.putPref("setting_Overlap_Duration"  , self.setting_Overlap_Duration     );
      self.putPref("setting_Windowing_Function", self.setting_Windowing_Function   );
      self.putPref("setting_YGrid"             , self.setting_YGrid                );
      self.putPref("setting_XGrid"             , self.setting_XGrid                );
      self.putPref("setting_YScale"            , self.setting_YScale               );
      self.putPref("setting_XScale"            , self.setting_XScale               );
    end
  end

  methods (Static)

    function [freqs,mags,col,id] = windowedPSD(Y,fs,id,windowParams,fftParams,plotParams)
      arguments
        Y (:,1) double
        fs (1,1) double
        id (1,1) string
        windowParams.windowDuration (1,1) double = fix(length(Y)/5)/fs;
        windowParams.windowOverlap (1,1) double  = fix(length(Y)/5)/fs / 2;
        windowParams.windowFx (1,1) string {spectralAnalyzer.isValidWindow(windowParams.windowFx)} = "hann"
        fftParams.NFFT (1,1) double = 2^nextpow2(length(Y))
        fftParams.TruncateFrequency (1,1) double = 0
        plotParams.Color (1,3) double = [0,0,0]
      end
      if windowParams.windowOverlap >= windowParams.windowDuration
        error("Overlap duration must be shorter than the window duration.");
      end
      % K = (N-ovl) / (L-ovl)

      N = length(Y);
      L = fix(windowParams.windowDuration * fs);
      overlap = fix(windowParams.windowOverlap * fs);
      K = (N-overlap) /  (L-overlap);

      if rem(K,floor(K))
        % update the overall length by padding with zeros
        K = floor(K)+1;
        newLength = K*L - K*overlap + overlap;
        nAppend = newLength - N;
        Y(end+(1:nAppend)) = 0;
        N = newLength;
      end

      columnInds = (0:(K-1))*(L-overlap);
      rowInds = (1:L)';


      % window
      wFx = str2func(windowParams.windowFx);
      h = wFx(L);
      if ~iscolumn(h)
        h = h(:);
      end


      % fourier parameters
      if ~fftParams.NFFT
        fftParams.NFFT = 2^nextpow2(N);
      end

      Y = hilbert(Y); %analytical signal.

      dT = 1/fs;
      nyquistFreq = fs/2;
      nFreqs = fix(fftParams.NFFT/2) + 1;
      freqs = linspace(0,1,nFreqs)' * nyquistFreq;
      factor = dT/sum(h.^2); % for psd

      x = ((1:L)' - 1) / fs;

      if fftParams.TruncateFrequency
        stopIndex = find(freqs <= fftParams.TruncateFrequency,1,'last');
      else
        stopIndex = nFreqs;
      end

      mags = nan(stopIndex,K);

      for k = 1:K
        ix = rowInds + columnInds(k);
        sig = Y(ix);
        % Handle missing data
        sig(isnan(sig)) = mean(sig,'omitnan');
        % remove linear
        %cfs = polyfit(x,sig,1);
        %sig = sig - polyval(cfs,x);

        sig = (sig - mean(sig,'omitnan')) .* h;
        % center the signal and compute nfft size fourier
        fSig = fft(sig,fftParams.NFFT);
        m = abs(fSig) .^ 2;
        mags(:,k) = m(1:stopIndex);
      end
      mags = factor * mean(mags,2);
      freqs = freqs(1:stopIndex);
      col = plotParams.Color;
    end

    function isValidWindow(fxName)

      h = str2func(fxName);
      try
        out = h(2);
      catch me
        error("Window function mast take a scalar length arg.");
      end

      if numel(out) ~= 2
        error("Window function mast take a scalar length arg.");
      end

    end

  end

end
