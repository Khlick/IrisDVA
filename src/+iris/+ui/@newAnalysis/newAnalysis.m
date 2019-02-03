classdef newAnalysis < iris.ui.UIContainer
  %NEWANALYSIS User Interface for specifying name and parameters of new analysis for Iris
  events
    createFunction
  end
  
  
  % Properties that correspond to app components
  properties (Access = public)
    nameLabel            matlab.ui.control.Label
    analysisName         matlab.ui.control.EditField
    createButton         matlab.ui.control.Button
    cancelButton         matlab.ui.control.Button
    argPanel             matlab.ui.container.Panel
    inputArgs            matlab.ui.control.Table
    outputArgs           matlab.ui.control.Table
    outputsLabel         matlab.ui.control.Label
    InputArgumentsLabel  matlab.ui.control.Label
    addOutput            matlab.ui.control.Button
    addInput             matlab.ui.control.Button
    showArgs             matlab.ui.control.StateButton
  end
  
  % properties for validation
  properties (Dependent)
    isValidFx
  end
  
  %% Public methods
  methods 
    
    function tf = get.isValidFx(obj)
      existingAnalyses = iris.app.Info.getAvailableAnalyses();
      tf = ~ismember([obj.analysisName.Value,'.m'], existingAnalyses);
      if tf
        %prevent default input from being used
        tf = ~strcmpi(obj.analysisName.Value,'irisAnalysis');
      end
    end
    
  end
  
  %% Protected
  methods (Access = protected)
    %startup
    startupFcn(obj,varargin)
    %createUI
    createUI(obj)
    %callbacks
    %validate input args
    function validateInput(obj,src,evt)
      inputString = evt.NewData;
      idx = evt.Indices;
      if idx(2) == 1
          % The name of the input argument was edited: let's validate it
          % We can set the name of arguments to any valid string
          % First check if we should delete the row.
          if isempty(inputString)
            %delete only if it isn't the DataObject argument, that is a requirement
            if idx(1) == 1
              src.Data{idx(1),idx(2)} = evt.PreviousData;
            else
              src.Data(idx(1),:) = [];
            end
            return;
          end
          % validate using the argname method
          obj.validateArgName(src,evt);
          return;
      end
      % The following will handle the default value being set.
      if idx(1) == 1
          %is data object row, force to DataObject and return
          obj.inputArgs.Data{1,2} = 'DataObject';
          return;
      end
      valueString = evt.NewData;
      valueString = regexprep(valueString,'''', '''''');
      src.Data{evt.Indices(1),evt.Indices(2)} = valueString;
    end
    %validate output vargs
    function validateArgName(~,src,evt)
      if isempty(evt.NewData)
        src.Data(evt.Indices(1),:) = [];
        return;
      end
      oldData = src.Data(~ismember(1:size(src.Data,1),evt.Indices(1)),1);
      argName = camelizer(evt.NewData);
      if ismember(argName,oldData)
        argName = evt.PreviousData;
        warning('IRIS:NEWANALYSIS:VALIDATEOUPUT','Argument already exists.');
      end
      src.Data{evt.Indices(1),1} = argName;
    end
    
    %validate function name
    function validateFxName(obj,src,evt) 
       value = camelizer(evt.Value);
       src.Value = value;
       drawnow;
       % check for existing functions and throw error message
       if ~obj.isValidFx
         warndlg( ...
          sprintf( ...
            '%s is not valid. Use a different name.', ...
            value ...
          ), ...
          'Existing Analysis', ...
          'modal' ...
          );
        src.Value = evt.PreviousValue;
       end
    end
    % add an input or output arg
    function addArg(obj,src,~)
      switch src.Tag
        case 'in'
          hTable = obj.inputArgs;
          dAppend = { ...
            sprintf('%sput%d',src.Tag,size(hTable.Data,1)), ...
            '' ...
            };
        case 'out'
          hTable = obj.outputArgs;
          dAppend = {sprintf('%sput%d',src.Tag,1+size(hTable.Data,1))};
      end
      hTable.Data = [ ...
        hTable.Data; ...
        dAppend ...
        ];
    end
    % Toggle app to show optional args
    function toggleArgs(obj,~,~)
      value = obj.showArgs.Value;
      if value
        obj.showArgs.Text = '-';
        obj.container.Position(4) = 135+255;
        obj.showArgs.Position(2) = 10+255;
        obj.createButton.Position(2) = 10+255;
        obj.cancelButton.Position(2) = 10+255;
        obj.analysisName.Position(2) = 65+255;
        obj.nameLabel.Position(2) = 105+255;
        obj.argPanel.Position(2) = 5;
        obj.argPanel.Visible = 'on';
      else
        obj.showArgs.Text = '+';
        obj.container.Position(4) = 135;
        obj.showArgs.Position(2) = 10;
        obj.createButton.Position(2) = 10;
        obj.cancelButton.Position(2) = 10;
        obj.analysisName.Position(2) = 65;
        obj.nameLabel.Position(2) = 105;
        obj.argPanel.Visible = 'off';
      end
    end
    %create function
    function createNewFunction(obj,~,~)
      % validate forms
      if ~obj.isValidFx
        errordlg( ...
          sprintf( ...
            '%s is not valid. Use a different name.', ...
            obj.analysisName.Value ...
          ), ...
          'Existing Analysis', ...
          'modal' ...
          );
      end
      % package contents
      package = struct( ...
        'name', obj.analysisName.Value, ...
        'input', {obj.inputArgs.Data}, ...
        'output', {obj.outputArgs.Data} ...
        );
      % notify createFunction event with package
      notify(obj, 'createFunction', iris.infra.eventData(package));
      % prompt to continue or quit
      qb = iris.ui.questionBox( ...
        'Title', 'Create another?', ...
        'Prompt', {'Would you like to create another?'}, ...
        'Options', {'Yes', 'No'}, ...
        'Default', 'No' ...
        );
      if strcmpi(qb.response,'Yes')
        return;
      end
      % shutdown view
      obj.onCloseRequest;
    end
  end
  
  %% Preferences
  methods (Access = protected)
    
    function onCloseRequest(obj)
      obj.shutdown;
    end

    function setContainerPrefs(obj)
      setContainerPrefs@iris.ui.UIContainer(obj);
    end
    
    function getContainerPrefs(obj)
      getContainerPrefs@iris.ui.UIContainer(obj);
    end
    
  end
end