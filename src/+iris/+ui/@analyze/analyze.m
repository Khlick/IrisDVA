classdef analyze < iris.ui.JContainer
  %ANALYZE User interface for conducting a selected analysis.
  events
    requestData
  end
  
  properties (Hidden = true)
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
    checkboxSendToCmd
    checkboxAppend
    selectAnalysis
    epochInput
    %Data
    Args = struct('Input', {[]}, 'Output', {[]}, 'Call', @(){[]});
    FileName
  end
  
  properties (Access=private)
    EnLisn
  end
  
  properties
    Fx
    DataObject
    Opts
    OutputValues = struct();
  end
  
  properties (SetObservable=true)
    EpochNumbers
  end
  
  properties (Dependent)
    analysisReady
    availableAnalyses
    dataLoaded
  end
  
  methods (Access=private)
    function startUp(obj)
      obj.Fx = [];
      obj.DataObject = [];
      obj.Opts = iris.pref.analysis.getDefault();
      obj.FileName = [];
    end
  end
  %% Method Definitions
  methods (Access = protected)
    createUI(obj)
    function startupFcn(obj,varargin)
      if nargin > 1
        obj.EpochNumbers = varargin{1};
      else
        obj.EpochNumbers = [];
      end
      if isempty(obj.EnLisn)
        obj.EnLisn = addlistener(obj, ...
          'EpochNumbers','PostSet', ...
          @(s,e)obj.setEpochs() ...
          );
      else
        obj.EnLisn.Enabled = true;
      end
    end
  end
  
  methods
    
    loadObj(obj,fxString)
    
    function setFxn(obj,fx)
      if strcmpi(fx.Data,'select')
        obj.clearUI();
        return; 
      end
      obj.loadObj(fx.Data);
    end
    
    function setEpochs(obj,str)
      if nargin < 2
        %called from the postset
        if isempty(obj.EpochNumbers)
          obj.epochInput.String = 'Enter Epochs';
        else
          if length(obj.EpochNumbers) <= 10
            obj.epochInput.String = strjoin(strsplit(num2str(obj.EpochNumbers),' '),',');
          else
            epSorted = sort(obj.EpochNumbers);
            eInds = find(diff([epSorted,-1]) ~= 1);
            starts = epSorted([1,eInds(1:end-1)+1]);
            ends = epSorted(eInds);
            strs = sprintfc('%d',[starts(:),ends(:)]);
            out = cell(size(strs,1),1);
            for i = 1:size(strs,1)
              if strcmp(strs{i,:})%start == end
                out{i} = strs{i,1};
              else
                out{i} = strjoin(strs(i,:),':');
              end
            end
            obj.epochInput.String = strjoin(out,',');
          end
        end
        return;
      end
      %Here we are converting the input to a double vector, we then sort
      %the values and make sure there are no repeats. Once we set the value
      %here, the PostSet listener callback to this function will then
      %correct the input string to reflect 
      obj.EpochNumbers = unique(str2num(str));%#ok
    end
    
  end
  
  methods (Access = protected)
    %%callback methods
    function clearUI(obj)
      obj.DataObject = [];
      obj.Args = struct('Input', {[]}, 'Output', {[]}, 'Call', @(){[]});
      obj.OutputValues = struct();
      obj.tableInput.Data = {[],[]};
      obj.tableOutput.Data = {[],[]};
      obj.labelFunction.String = 'Function Call';
      obj.editFileOutput.String = 'FileName';
    end
    
    function executeFunction(obj,~,~)
      %collect inputs and create function call string and then save in base
      %Make sure both fx and DataObject are present
      if ~obj.analysisReady, return; end
      
      %clear the current dataObject
      obj.DataObject = [];
      % request new Data objcet.
      notify(obj,'requestData',iris.infra.eventData(obj.EpochNumbers));
      % wait
      waitLimit = 200; % 2 seconds
      for iter = 1:waitLimit
        if ~obj.dataLoaded
          pause(0.01);
          continue;
        else
          break;
        end
      end
      
      if ~obj.checkboxAppend.Value
        % reset outputValues so they don't get appended
        obj.OutputValues = struct();  
      end
      %Check for valid output file name
      if isempty(obj.FileName)
        warndlg('Enter a valid file name.', 'Save Error');
        return;
      end
      %Check args for empties
      check = [...
          cellfun(@isempty, obj.Args.Input(:,2),  'unif',1)  ;...
          cellfun(@isempty, obj.Args.Output(:,2), 'unif',1)  ...
        ];
      if any(check)
        error('Cannot provide empty arguments for function ''%s(...)''.',obj.Fx);
      end
      %Parse Args
      ArgOut = obj.Args.Output(:,2);
      ArgIn = obj.Args.Input(:,2);
      try
        ArgIn{strcmpi(ArgIn,'DataObject')} = 'obj.DataObject';
      catch x
        warndlg('Input values must contain a ''DataObject'' reference.');
        rethrow(x);
      end
      %Set outputs into obj outputs
      S = struct();
      S.Call = struct();
      S.Call.TimeStamp = datestr(now,'YYYYmmmDD-HH:MM:SS.FFF');
      
      S.Call.ArgsIn = ArgIn;
      S.Call.ArgsOut = ArgOut;
      ArgOut = strcat('S.', ArgOut);
      callString = obj.Args.Call(ArgOut, ArgIn);
      S.Call.String = callString;
      
      %maybe this should be wrapped in a try/catch... for now let the fail
      %occur with whatever errorhandling inside the function. Fails here do
      %not have effect on Iris (so far)-2018kg
      evalc(callString);
            
      %% save and assign
      outputFile = fullfile( ...
        obj.Opts.OutputLocation, ...
        [ ...
          obj.Opts.AnalysisPrefix(), ...
          '_',obj.FileName,'.mat' ...
        ]);
      % does saving to an existing Mat file override or append? -kg
      save(outputFile,'-struct', 'S');
      % send to global workspace
      if obj.checkboxSendToCmd.Value
        W = evalin('base', 'whos');
        AlreadyInBase = cellfun(@isempty,...
          regexp({W(:).name}',obj.FileName),'unif',1);
        if any(AlreadyInBase)
          if obj.checkboxAppend.Value
            %if in base and we want to append, first send S to base and
            %then run through the fields assigning S.(field) to
            %desiredOutput.(field). Then remove S from the base workspace
            %(since we don't need it anymore)
            assignin('base', 'S', S);
            for a = 1:length(ArgOut)
              evalin('base', ...
                sprintf('%s.%s = %s;', ...
                  obj.FileName, ArgOut{a}(3:end), ArgOut{a})...
                );
            end
            evalin('base', 'clear S');
          else
            % in base but we don't want to mess with it.
            possibleNewNames = sprintfc(...
              [sprintf('%s',obj.FileName),'%0.2d'],...
              1:(1+sum(~AlreadyInBase)))';
            newName = possibleNewNames{...
                find(~ismember(possibleNewNames, {W(:).name}'), 1, 'first')...
              };
            assignin('base', newName, S);
          end
        end
      end
      fprintf('Succesful export!\n');
      
    end
    
    function validateFilename(obj,src,~)
      theStr = matlab.lang.makeValidName(src.String);
      src.String = theStr;
      obj.FileName = theStr;
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
      pause(0.001); drawnow;
      outputCalling = [];
      inputCalling = [];
    end
    
  end
  
  methods 
    
    function tf = get.analysisReady(obj)
      tf = ~isempty(obj.Fx) && ...
        ~any(cellfun(@isempty,struct2cell(obj.Args),'unif',1)) && ...
        ~isempty(obj.EpochNumbers);
    end
    
    function str = get.availableAnalyses(obj)
      if ~obj.isready, str = {''}; return; end
      str = [ ...
        {'Select'}; ...
        iris.app.Info.getAvailableAnalyses() ...
        ];
      str = str(~cellfun(@isempty,str,'UniformOutput',1));
    end
    
    function tf = get.dataLoaded(obj)
      tf = ~isempty(obj.DataObject);
    end
    
    function selfDestruct(obj)
      if obj.analysisReady
        obj.clearUI();
      end
      obj.shutdown;
      obj.EnLisn.Enabled = false;
      obj.EpochNumbers = [];
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
  
  %% Static
  methods (Static)
    
  end
end

