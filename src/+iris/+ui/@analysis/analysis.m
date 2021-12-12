classdef analysis < iris.ui.UIContainer
  %analysisExport User interface for conducting a selected analysis.

  events
    createNewAnalysis
  end

  properties (Constant)
    DATA_OBJECT_LABEL = 'DataObject'
    WIDTH = 950
    BATCH_OFFSET = 300
    HEIGHT = 400
    FUNCTION_CALL_MAX_HEIGHT = 85;
  end

  properties %(Access = protected) % UI ELements
    % Menus
    optionsMenu
    appendOption
    appendYes
    appendNo
    appendAsk
    sendToCommandOption
    backtrackDataIndicesOption
    createAnalysisOption
    resetDefaultsOption
    % Main
    containerGrid
    % Analysis selection
    inputPanel
    inputGrid
    selectLabel
    selectDropdown
    editAnalysisButton
    refreshAnalysisButton
    updateDefaultsButton
    functionCallLabel % function signature custom element
    % Batch processing (TODO!)
    batchButtonGrid
    batchVisibilityButton
    batchPanel
    % Function Interactions
    functionPanel
    functionGrid
    dataPanel
    dataGrid
    dataLabel
    dataInput % input epochs / read epochs from handler
    % Function Arguments Tables
    argumentsPanel
    argumentsGrid
    argumentsOutLabel
    argumentsToggleGrid
    argumentsToggleOut
    argumentsToggleIn
    argumentsInLabel
    argumentsOutTable
    argumentsInTable
    % Output File Location and processing button.
    outputPanel
    outputGrid
    outputFile
    outputLocation
    outputAnalyzeButton
  end

  properties (Access = public, SetObservable = true) % local storage
    workingDirectory
  end

  properties (SetAccess = private,Hidden) % Pointers
    Handler
  end

  properties (Dependent, Access = private)
    dataIndices
    hasAnalysis
    AppendMethod
    currentAnalysisFile
    currentResultsFile
  end

  %% Constructors / Destructors
  methods (Access = protected)

    % Construct view
    createUI(obj)
    % Bind elements
    bindUI(obj)
    % rebind
    function rebindUI(obj)
      obj.isBound = false;
      obj.detachListeners();
      obj.attachListeners();
    end

    % Startup
    function startupFcn(obj, handler)

      arguments
        obj
        handler (1, 1) iris.data.Handler
      end

      obj.Handler = handler;
      obj.bindUI();
      obj.attachListeners();
      obj.buildUI(handler);
      obj.setSelectionFromHandler();
    end

    function attachListeners(obj)
      
      % listener for the handler selection updates to sync iris to analysis
      obj.addListener(obj.Handler, ...
      'onSelectionUpdated', ...
        @(src, evt) obj.setSelectionFromHandler() ...
      );

      % listen to changes on the output directory; keep local storage to prevent calling
      % it from prefs on disk
      obj.addListener(obj, ...
      'workingDirectory', 'PostSet', ...
        @obj.didUpdateWorkingDirectory ...
      );
      
      % check for a close listener and add one if none exist
      if ~event.hasListener(obj,'Close')
        addlistener(obj, 'Close', @(s,e)obj.selfDestruct());
      end
      
      % set bound status
      obj.isBound = true;
    end

    % get and set preferences (options)
    function resetContainerPrefs(obj)
      % clear all container settings:
      obj.hide();
      obj.reset();
      obj.position = utilities.centerFigPos(obj.WIDTH, obj.HEIGHT);

      % Clear the ui
      obj.clearUI();

      % toggles
      obj.setBatchVisibility(obj.get('showBatch', false));
      showOut = obj.get('showOutputs', true);
      showIn = obj.get('showInputs', true);
      obj.setArgumentsVisibility('out', showOut);
      obj.setArgumentsVisibility('in', showIn);

      obj.sendToCommandOption.Checked = obj.options.SendToCommandWindow;
      obj.AppendMethod = obj.options.AppendAnalysis;
      obj.backtrackDataIndicesOption.Checked = obj.get('backtrack', false);
      obj.functionCallLabel.isOpen = obj.get('fcnCallVisible', false);
      obj.setFunctionCallHeight(obj.functionCallLabel.Height);

      % load the default prefix and set the tooltip for the output file/directory
      obj.outputFile.Value = obj.options.AnalysisPrefix();
      obj.workingDirectory = obj.options.OutputDirectory;
      obj.outputFile.Tooltip = sprintf("Root: '%s'", obj.workingDirectory);

      drawnow();
      pause(0.01);
      obj.show();
    end

    function setContainerPrefs(obj)
      % store current preferences
      setContainerPrefs@iris.ui.UIContainer(obj);

      % store settings for view toggles
      obj.put('showBatch', obj.batchVisibilityButton.Value);
      obj.put('showOutputs', obj.argumentsToggleOut.Value);
      obj.put('showInputs', obj.argumentsToggleIn.Value);
      obj.put('backtrack', obj.backtrackDataIndicesOption.Checked);
      obj.put('fcnCallVisible', obj.functionCallLabel.isOpen);

      % store options settings
      obj.options.SendToCommandWindow = obj.sendToCommandOption.Checked;
      obj.options.AppendAnalysis = obj.AppendMethod;
      obj.options.OutputDirectory = obj.workingDirectory;
      obj.save();
    end

    function getContainerPrefs(obj)
      % get stored preferences
      getContainerPrefs@iris.ui.UIContainer(obj);
      % get previous position
      pos = obj.position;

      % toggles
      obj.setBatchVisibility(obj.get('showBatch', false));
      showOut = obj.get('showOutputs', true);
      showIn = obj.get('showInputs', true);
      obj.setArgumentsVisibility('out', showOut);
      obj.setArgumentsVisibility('in', showIn);

      % options
      obj.sendToCommandOption.Checked = obj.options.SendToCommandWindow;
      obj.AppendMethod = obj.options.AppendAnalysis;
      obj.backtrackDataIndicesOption.Checked = obj.get('backtrack', false);
      obj.functionCallLabel.isOpen = obj.get('fcnCallVisible', false);
      obj.setFunctionCallHeight(obj.functionCallLabel.Height);

      % load the default prefix and set the tooltip for the output file/directory
      obj.outputFile.Value = obj.options.AnalysisPrefix();
      obj.workingDirectory = obj.options.OutputDirectory;
      obj.outputFile.Tooltip = sprintf("Root: '%s'", obj.workingDirectory);

      % set the position from previous store
      obj.position = pos;
      drawnow();
      pause(0.05);
    end

    % Reset View
    function clearUI(obj)
      % set UI elements to empty/default values
      obj.selectDropdown.Value = 'Select';
      obj.selectDropdown.Items = obj.getAvailableAnalyses();
      obj.toggleInteractivity();
      obj.parseSelectedAnalysis();
    end

  end

  methods

    buildUI(obj, handler)

    function selfDestruct(obj)
      obj.shutdown();
    end

    function refresh(obj)
      obj.clearUI();
      obj.show();
    end

  end

  %% Get/Set
  methods

    function fx = get.currentAnalysisFile(obj)
      fx = struct('Name', '', 'Path', '');
      if ~obj.hasAnalysis, return; end
      fx.Name = obj.selectDropdown.Value;
      fxPaths = iris.app.Info.getAvailableAnalyses().Full;
      idx = ismember(fxPaths(:, 2), [fx.Name, '.m']);
      fx.Path = fullfile(fxPaths{idx, :});
    end

    function idx = get.dataIndices(obj)
      idx = [];
      if (isempty(obj.Handler) || ~obj.Handler.isready), return; end
      [~, idx] = obj.formatDatumIndices(str2num(obj.dataInput.Value)); %#ok<ST2NM>
    end

    function tf = get.hasAnalysis(obj)
      tf = ~strcmp(obj.selectDropdown.Value, 'Select');
    end

    function setBatchVisibility(obj, flag)
      obj.batchVisibilityButton.Value = flag;

      if ~flag
        settings = {'+', obj.WIDTH - obj.BATCH_OFFSET, 0};
      else
        settings = {'-', obj.WIDTH, obj.BATCH_OFFSET};
      end

      obj.batchVisibilityButton.Text = settings{1};
      pos = obj.container.Position;
      pos(3) = settings{2};
      obj.position = pos;
      obj.containerGrid.ColumnWidth{end} = settings{3};
    end

    function setArgumentsVisibility(obj, type, value)
      import utilities.ternary;
      type = char(type);
      type(1) = upper(type(1));
      obj.(sprintf("argumentsToggle%s", type)).Value = value;
      idx = ternary(strcmp(type, 'In'), 3, 1);
      obj.argumentsGrid.ColumnWidth{idx} = ternary(value, {'1x'}, 0);
    end

    function setMenuStatus(obj, name, newStatus)

      switch lower(name)
        case 'command'
          obj.sendToCommandOption.Checked = newStatus;
          obj.options.SendToCommandWindow = newStatus;
        case 'append'
          obj.appendOption.Checked = newStatus;
          obj.options.AppendAnalysis = newStatus;
        case 'backtrack'
          obj.backtrackDataIndicesOption.Checked = newStatus;
          obj.put('backtrack', newStatus);
        otherwise
          % do nothing
          return
      end

      % save any updated preferences
      obj.options.save();
    end

    function setSelectionFromHandler(obj)
      if obj.isClosed, return; end
      obj.dataInput.Value = obj.formatDatumIndices(obj.Handler.currentSelection.selected);
    end

    function setFunctionCallHeight(obj, newHeight)
      totalHeight = sum([newHeight.label, newHeight.contents]);
      obj.inputGrid.RowHeight{2} = min([totalHeight, obj.FUNCTION_CALL_MAX_HEIGHT]);
    end

    function m = get.AppendMethod(obj)

      if obj.appendYes.Checked
        m = "yes";
      elseif obj.appendNo.Checked
        m = "no";
      else
        m = "ask";
      end

    end

    function set.AppendMethod(obj, m)
      opts = true(1, 4);
      props = strcat("append", ["Option", "Yes", "No", "Ask"]);

      switch m
        case "yes"
          opts(3:4) = false;
        case "no"
          opts(3) = false;
          opts = ~opts;
        case "ask"
          opts(1:3) = false;
      end

      ch = ["off", "on"];
      states = ch(opts + 1);

      for p = 1:4
        obj.(props(p)).Checked = states(p);
      end

    end

    function fileInfo = get.currentResultsFile(obj)
      fileInfo = struct( ...
        'Name', obj.outputFile.Value, ...
        'Path', fullfile(obj.workingDirectory, [obj.outputFile.Value, '.mat']) ...
      );
    end

  end

  methods (Access = private)

    function str = getAvailableAnalyses(obj)
      str = {'Select'};
      if ~obj.isready, return; end
      str = cat(1, str, iris.app.Info.getAvailableAnalyses().Names);
      str = str(~cellfun(@isempty, str, 'UniformOutput', true));
    end

    function toggleInteractivity(obj)
      status = obj.hasAnalysis;
      obj.editAnalysisButton.Enable = status;
      obj.updateDefaultsButton.Enable = status;
      obj.dataInput.Enable = status;
      obj.outputFile.Enable = status;
      obj.outputLocation.Enable = status;
      obj.outputAnalyzeButton.Enable = status;
    end

  end

  %% Callbacks
  methods (Access = protected)

    function devShutdown(obj, ~, ~)

      try %#ok<TRYNC>
        cellfun(@delete, obj.Handler.AutoListeners__);
        obj.Handler.AutoListeners__ = {};
      end

      obj.shutdown();
    end

    function onAppendMethodChanged(obj, src, ~)
      m = src.Tag;
      obj.options.AppendAnalysis = m;
      obj.options.save();
      obj.AppendMethod = m;
    end

    function onUpdateBatchVisibility(obj, src, evt) %#ok<INUSD,INUSL>
      % not implemented yet, for now make sure the value is closed
      %obj.setBatchVisibility(evt.Value);
      src.Value = false;
    end

    function onUpdateArgumentsVisibilty(obj, ~, evt)
      obj.setArgumentsVisibility(evt.Data{:});
    end

    function onOptionMenuChanged(obj, ~, evt)
      obj.setMenuStatus(evt.Data{:});
    end

    function onDataIndicesChanged(obj, ~, evt)

      try
        [newStr, newIdx] = obj.formatDatumIndices(str2num(evt.Value)); %#ok<ST2NM>
      catch
        obj.dataInput.Value = evt.PreviousValue;
        return
      end

      % check if we are backtracking handler
      if obj.backtrackDataIndicesOption.Checked
        % let handler status changed listener update the string
        obj.Handler.currentSelection = newIdx;
        return
      end

      obj.dataInput.Value = newStr;
    end

    function onAnalysisChanged(obj, src, evt)
      obj.toggleInteractivity();

      try
        obj.parseSelectedAnalysis();
      catch err
        iris.app.Info.showWarning( ...
          sprintf("Couldn't parse '%s' for reasion: '%'.", evt.Value, err.message) ...
        );
        src.Value = evt.PreviousValue;
        return
      end

    end

    function onEditCurrentAnalysis(obj, ~, ~)
      analysisFile = obj.currentAnalysisFile;
      edit(analysisFile.Path);
    end

    function onRefreshAnalysesList(obj, ~, ~)
      obj.refresh(); 
    end

    function onSetCurrentAnalysisDefaults(obj, ~, ~)
      fxInfo = obj.currentAnalysisFile;
      inputs = obj.argumentsInTable.Data;
      % escape single quotes (leave " alone).
      inputs(:, 2) = regexprep(inputs(:, 2), '''+', '''');
      % new definitions
      newDefs = strcat(inputs(:, 1), ':=', inputs(:, 2));

      % get the current contents of the analysis file
      fid = fopen(fxInfo.Path, 'r');

      if fid < 0
        iris.app.Info.throwError(sprintf("Cannot open file '%s'.", fxInfo.Name));
      end

      allText = textscan(fid, '%s', 'delimiter', '\n', 'whitespace', '');
      %unpack
      allText = allText{1};
      fclose(fid);

      % find defaults in the file
      defLocs = find( ...
      ~cellfun(@isempty, ...
        strfind(allText, ':=', 'ForceCellOutput', true), ...
        'unif', 1 ...
      ) ...
      );

      % make sure we have only deflocs that pertain to the arguments
      defText = cellfun(@(x)strsplit(x, ':='), allText(defLocs), 'UniformOutput', false);
      defLocs(~cellfun(@(x)contains(x{1}, inputs(:, 1)), defText, 'UniformOutput', true)) = [];

      if isempty(defLocs)
        % going to append them on the end
        insertAfter = numel(allText);
        allText{end + 1} = '';
      else
        insertAfter = min(defLocs) - 1;
      end

      % remove the existing definitions so we can replace them
      allText(defLocs) = [];

      % determine if we removed defaults from a defaults block
      defBlockRow = find( ...
      ~cellfun( ...
        @isempty, ...
        regexp(allText, '^DEFAULTS', 'once'), ...
        'UniformOutput', true ...
      ), ...
        1 ...
      );

      if isempty(defBlockRow)
        newDefs = [ ...
                  { ...
                  '% --- SET YOUR DEFAULTS BELOW --- %';
                '%{';
                'DEFAULTS';
                }; ...
                  newDefs; ...
                  { ...
                  '%}'; ...
                  '%' ...
                } ...
                ];
      else
        % maybe check that insertAfter == defblockRow?
      end

      % insert the new definitions
      newText = [ ...
              allText(1:insertAfter);
              newDefs;
              allText((insertAfter + 1):end) ...
              ];

      % open the file to replace all content
      fid = fopen(fxInfo.Path, 'w');

      for c = 1:numel(newText)
        fprintf(fid, '%s\r\n', newText{c});
      end

      fclose(fid);

      obj.parseSelectedAnalysis();
    end

    function didUpdateWorkingDirectory(obj, ~, ~)
      obj.options.OutputDirectory = obj.workingDirectory;
      obj.options.save();
      obj.outputFile.Tooltip = sprintf("Root: '%s'", obj.workingDirectory);
    end

    function onOutputFileChanged(obj, src, evt) %#ok<INUSL> 
      % triggered when user types in a custom file name
      str = strtrim(evt.Value);
      if ~iris.app.Info.isValidFilename(str)
        src.Value = evt.PreviousValue;
        iris.app.Info.throwError("File name is not valid.");
      end
      % see if the trimming changed the string
      if strcmp(evt.Value,str), return; end
      % apply trimmed string to value
      src.Value = str;
    end

    function onGetNewLocation(obj, ~, ~)
      [~, f, root] = iris.app.Info.putFile( ...
        'Analysis Output File', ...
        '*.mat', ...
        fullfile(obj.workingDirectory, [obj.outputFile.Value, '.mat']) ...
      );
      if isempty(root), return; end
      obj.outputFile.Value = char(f);
      obj.workingDirectory = root;
    end

    function onToggleFunctionCallString(obj, ~, evt)
      h = obj.functionCallLabel.Height;

      if ~evt.Data
        h.contents = 0;
      end

      obj.setFunctionCallHeight(h);
    end

    function onFunctionCallHeightChanged(obj, ~, evt)
      h = evt.Data;
      if ~obj.functionCallLabel.isOpen, return; end
      obj.setFunctionCallHeight(h);
    end

    function onOutputTableCellChanged(obj,~,evt)
      str = matlab.lang.makeValidName(evt.EditData);
      if strcmp(str,evt.EditData),return;end
      inds = num2cell(evt.Indices);
      obj.argumentsOutTable.Data{inds{:}} = str;
    end

    function onInputTableCellChanged(obj,~,evt)
      inds = num2cell(evt.Indices);
      % changing of data object value is disallowed
      if inds{1} == 1
        obj.argumentsInTable.Data{inds{:}} = obj.DATA_OBJECT_LABEL;
        return
      end
      % verify that the input is a valid MATLAB expression
      try
        evalc(evt.EditData);
      catch err
        obj.argumentsInTable.Data{inds{:}} = evt.PreviousData;
        iris.app.Info.showWarning( ...
          sprintf( ...
            [ ...
            'Couldn''t evaluate the expression, ">>%s", ',...
            'for reason: "%s".' ...
            ], ...
            evt.EditData, err.message ...
            ) ...
          );
      end
    end

    function onRequestAnalysis(obj,~,~)
      if ~obj.hasAnalysis, return; end
      obj.executeAnalysis();
    end
  end

  %% Utilities
  methods (Access = private)

    parseSelectedAnalysis(obj)

    executeAnalysis(obj)

    function varargout = formatDatumIndices(obj, inds)
      % validate range
      allInds = 1:obj.Handler.currentSelection.total;
      cur = intersect(allInds, inds); %sorted

      % shorten the numbers into matlab expressions.
      seqs = [cur([true, diff(cur) > 1]); cur([diff(cur) > 1, true])];
      nChunks = size(seqs, 2);
      expressions = cell(1, nChunks);

      for s = 1:nChunks

        if seqs(1, s) == seqs(2, s)
          expressions{s} = sprintf('%d', seqs(1, s));
        else
          expressions{s} = sprintf('%d:%d', seqs(1, s), seqs(2, s));
        end

      end

      % set the string.
      varargout{1} = strjoin(expressions, ',');

      if nargout > 1
        varargout{2} = cur;
      end

    end
    
  end

end
