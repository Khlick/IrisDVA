classdef analyze < iris.ui.JContainer
  %ANALYZE User interface for conducting a selected analysis.
  
  properties %(Access = private)
    %UI
    labelTitle
    labelFunction
    labelNargout
    labelNargin
    panelInput
    panelOutput
    tableInput
    tableOutput
    buttonGo
    buttonClose
    editFileOutput
    labelFileRoot
    buttonPutFile
    checkboxSendToCmd
    checkboxAppend
    selectAnalysis
    datumInput
    refreshAnalysesButton
    editAnalysisButton
    setDefaultsButton
  end
  
  properties (SetAccess = private)
    OutputValues = struct();
    Args = struct('Input', {[]}, 'Output', {[]}, 'Call', @(){[]});
  end
  
  properties (Dependent)
    selectedFunction
    datumIndices
    analysisReady
    outputFile
    availableAnalyses
  end
  
  properties (Access = private)
    Opts
    handlerListeners
    Handler
  end
  
  %% Public Methods
  
  methods 
    
    function buildUI(obj,handler)
      if nargin < 2
        handler = obj.Handler;
      end
      if obj.isClosed
        obj.rebuild();
      end
      % determine if we are simply unhiding the window or need to reconstruct it
      newHandler = ~isequal(handler,obj.Handler);
      obj.show();
      if ~newHandler
        return
      else
        obj.destroyListeners();
        obj.Handler = handler;
      end
      
      obj.clearUI();
      
      obj.setSelectionFromHandler();
      
      if newHandler
        % set and enable listener
        obj.handlerListeners{end+1} = addlistener( ...
          handler, ...
          'onSelectionUpdated', @(s,e)obj.onHandlerUpdate(e) ...
          );
      end
    end
    
    function tf = get.analysisReady(obj)
      tf = obj.Handler.isready() && ...
        ~any(cellfun(@isempty,struct2cell(obj.Args),'unif',1));
    end
    
    function str = get.availableAnalyses(obj)
      if ~obj.isready, str = {''}; return; end
      str = [ ...
        {'Select'}; ...
        iris.app.Info.getAvailableAnalyses().Names ...
        ];
      str = str(~cellfun(@isempty,str,'UniformOutput',1));
    end
    
    function fx = get.selectedFunction(obj)
      fx = obj.selectAnalysis.Value;
    end
    
    function inds = get.datumIndices(obj)
      if ~obj.Handler.isready, inds = []; return; end
      allInds = 1:obj.Handler.currentSelection.total;
      inds = intersect( ...
        allInds, ...
        str2num(obj.datumInput.String) ...
        );%#ok
    end
    
    function fn = get.outputFile(obj)
      if ~obj.Handler.isready
        fn='';
        return
      end
      fn = fullfile( ...
        obj.labelFileRoot.String, ...
        [obj.editFileOutput.String, '.mat'] ...
        );
    end
    
    function selfDestruct(obj)
      if obj.analysisReady
        obj.clearUI();
      end
      obj.destroyListeners();
      obj.shutdown();
    end
    
    function refresh(obj)
      obj.clearUI();
      obj.show();
    end
    
  end
  
  %% Protected Methods
  
  methods (Access = protected)
    
    createUI(obj)
    
    loadObj(obj,fxString)
    
    onSetNewDefaults(obj,src,evt)
    
    function startupFcn(obj,handler)
      if nargin < 2, return; end
      obj.buildUI(handler);
    end
    
    %% Callbacks
    
    function clearUI(obj)
      obj.Args = struct('Input', {[]}, 'Output', {[]}, 'Call', @(){[]});
      obj.OutputValues = struct();
      obj.tableInput.Data = {[],[]};
      obj.tableOutput.Data = {[],[]};
      obj.labelFunction.String = 'Function Call';
      obj.editFileOutput.String = obj.Opts.AnalysisPrefix();
      obj.selectAnalysis.String = obj.availableAnalyses;
      obj.selectAnalysis.Value = find( ...
        ismember(obj.availableAnalyses,'Select') ...
        );
      obj.buttonGo.Enable = 'off';
      obj.editAnalysisButton.Enable = 'off';
      obj.setDefaultsButton.Enable = 'off';
    end
    
    function setFxn(obj,fx)
      if strcmpi(fx.Data,'select')
        obj.clearUI();
        return
      end
      obj.loadObj(fx.Data);
    end
    
    function setDatums(obj,source,~)
      nums = str2num(source.String);%#ok
      %Here we are converting the input to a double vector, we then sort
      %the values and make sure there are no repeats. 
      source.String = obj.formatDatumString(nums);
    end
    
    function onRefreshAnalyses(obj,~,~)
      import iris.infra.eventData;
      
      obj.selectAnalysis.String = obj.availableAnalyses;
      drawnow;
      
      obj.setFxn(eventData(obj.selectAnalysis.String{obj.selectAnalysis.Value}));
    end
    
    function onEditAnalysis(obj,~,~)
      selAna = obj.selectAnalysis.String{obj.selectAnalysis.Value};
      if strcmp(selAna,'Select'), return; end
      edit([selAna,'.m']);
    end
    
    function validateFilename(obj,src,~)  %#ok<INUSL>
      theStr = matlab.lang.makeValidName(src.String);
      src.String = theStr;
    end
    
    function validateTableEntry(obj,src,evnt)
      if strcmp(src.Tag, 'Output')
        try
          str = matlab.lang.makeValidName(evnt.EditData);
          if strcmp(str,evnt.PreviousData), return; end
        catch
          str = evnt.PreviousData;
        end
        inds = num2cell(evnt.Indices);
        d = src.Data;
        d{inds{:}} = str;
        src.Data = d;
        obj.Args.Output = d;
      else
        if strcmp(evnt.EditData,evnt.PreviousData), return; end
        try
          evalc(evnt.EditData);
        catch
          inds = num2cell(evnt.Indices);
          d = src.Data;
          d{inds{:}} = evnt.PreviousData;
          src.Data = d;
        end
        obj.Args.Input = src.Data;
      end
    end
    
    function tableChangeSize(obj,src,evnt)
      % get the width of the figure
      figureWidth = obj.container.Position(3);
      % check if callback is already running
      persistent outputCalling inputCalling
      if strcmp(src.Tag, 'Output')
        if ~isempty(outputCalling), return; end
        % if callback not running, then execute resize
        outputCalling = true;%#ok
        obj.tableOutput.ColumnWidth = {...
          src.UserData, ...
          evnt.Source.Position(3)*figureWidth-src.UserData-2 ...
          };
      else
        if ~isempty(inputCalling), return; end
        % if callback not running, then execute resize
        inputCalling = true; %#ok
        obj.tableInput.ColumnWidth = {...
          src.UserData, ...
          evnt.Source.Position(3)*figureWidth-src.UserData-2 ...
          };
      end
      pause(0.001); %drawnow;
      outputCalling = [];
      inputCalling = [];
    end
    
    function destroyListeners(obj)
      for i = 1:length(obj.handlerListeners)
        delete(obj.handlerListeners{i});
      end
      obj.handlerListeners = {};
    end
    
    function onHandlerUpdate(obj,event)
      % if the window is open, we need to update the view. Otherwise we will let the
      % buildUI() method handle the update.
      if obj.isClosed, return; end
      
      if endsWith(event.EventName,'Updated')
        % selection update triggered
        obj.setSelectionFromHandler();
      else
        % otherwise
        disp(event.EventName)
      end
    end
    
    function setSelectionFromHandler(obj)
      cur = obj.Handler.currentSelection.selected;
      % set the string.
      obj.datumInput.String = obj.formatDatumString(cur);
    end
    
    function setFile(obj,~,~)
      [~,f,root] = iris.app.Info.putFile( ...
        'Analysis Output File', ...
        '*.mat', ...
        fullfile(obj.labelFileRoot.String,[obj.editFileOutput.String,'.mat']) ...
        );
      if isempty(root), return; end
      obj.labelFileRoot.String = root;
      f = matlab.lang.makeValidName(regexprep(f,'\.mat$',''));
      obj.editFileOutput.String = f;
    end
    
    function expressions = formatDatumString(obj,inds)
      % validate range
      allInds = 1:obj.Handler.currentSelection.total;
      cur = intersect(allInds,inds); %sorted
      
      % shorten the numbers into matlab expressions.
      seqs = [cur([true,diff(cur)>1]);cur([diff(cur)>1,true])];
      nChunks = size(seqs,2);
      expressions = cell(1,nChunks);
      for s = 1:nChunks
        if seqs(1,s) == seqs(2,s)
          expressions{s} = sprintf('%d',seqs(1,s));
        else
          expressions{s} = sprintf('%d:%d',seqs(1,s),seqs(2,s));
        end
      end
      % set the string.
      expressions = strjoin(expressions,',');
    end
    
  end
  
  %% Preferences
  methods (Access = protected)

    function resetContainerPrefs(obj)
      obj.reset;
    end

    function setContainerPrefs(obj)
      setContainerPrefs@iris.ui.JContainer(obj);
    end
    
    function getContainerPrefs(obj)
      getContainerPrefs@iris.ui.JContainer(obj);
    end
    
  end
  
end

