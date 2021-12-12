function executeAnalysis(obj)
  if ~obj.hasAnalysis, return; end
  % function info
  fxInfo = obj.currentAnalysisFile;
  %% build the progress indicator
  timer = tic;
  announcer = iris.ui.Ticker();
  announcer.update("Executing...", animate = true);
  drawnow();
  pause(0.1);
  % construct cleanup
  CU = onCleanup(@()killAnnouncer(announcer, fxInfo.Name));
  while toc(timer) < 1.25, end
  timer = tic;
  announcer.update("Parsing arguments...");

  % result file info
  rsInfo = obj.currentResultsFile;
  rsCx = matfile(rsInfo.Path, 'Writable', true);

  %% parse inputs and outputs
  ArgsOut = obj.argumentsOutTable.Data;

  if any(cellfun(@isempty, ArgsOut(:, 2)))
    announcer.update("<span class='red'>Error!</span>");
    pause(0.8);
    iris.app.Info.throwError("Cannot supply empty argument names!");
  end

  ArgsIn = obj.argumentsInTable.Data;
  % convert empty arguments to '[]'
  ArgsIn(cellfun(@isempty, ArgsIn(:, 2)), :) = {'[]'};

  %Set outputs into obj outputs
  S = struct();
  S.Call = struct();
  S.Call.TimeStamp = datestr(now, 'YYYYmmmDD-HH:MM:SS.FFF');
  S.Call.ArgsIn = ArgsIn;
  S.Call.ArgsOut = ArgsOut;
  S.Call.String = sprintf( ...
    '[%s] = %s(%s);', ...
    strjoin(strcat('S.', ArgsOut(:, 2)), ','), ...
    fxInfo.Name, ...
    strjoin(ArgsIn(:, 2), ',') ...
  );
  while toc(timer) < 1, end
  announcer.update("Collecting data...");
  timer = tic;
  % collect the data from the handler
  S.Call.Indices = obj.dataIndices;
  DataObject = obj.Handler.exportSubs(S.Call.Indices);
  DataObject = DataObject.AppendUserData('AnalysisPath', rsInfo.Path); %#ok<NASGU>

  %% Run Analysis
  while toc(timer) < 1.2, end
  announcer.update("Analyzing...");

  try
    T = evalc(S.Call.String);
  catch err
    iris.app.Info.throwError( ...
      sprintf( ...
      'Could not perform analysis with reason:\n"%s"\n(%s)\n', ...
      x.message, ...
      strjoin( ...
      arrayfun( ...
      @(s)sprintf("[line %d : %s]", s.line, s.name), ...
      err.stack, ...
      'UniformOutput', true ...
    ), ...
      " > " ...
    ) ...
    ) ...
    );
  end

  if ~isempty(T)
    fprintf('Anaalysis output:\n"%s"\n', T);
  end

  %% Determine append status

  switch obj.AppendMethod
    case "ask"
      % only ask if the file exists already
      doAppend = ~~exist(rsInfo.Path, 'file');

      if doAppend
        appendQuestion = iris.ui.questionBox( ...
          'Prompt', 'File exists already, how would you like to write the results to disk?', ...
          'Title', 'Overwrite File', ...
          'Options', {'Overwrite', 'New', 'Append', 'Cancel'}, ...
          'Default', 'Append' ...
        );

        if strcmp(appendQuestion.response, 'Cancel')
          iris.app.Info.showWarning("Results not saved!");
          return
        end

        if strcmp(appendQuestion.response, 'New')

          while strcmp(appendQuestion.response, 'New')
            % Do no want to overwrite after all, prompt for new path
            outFile = iris.app.Info.putFile( ...
            'Analysis Output File', ...
              '*.mat', ...
              rsInfo.Path ...
            );

            if isempty(outFile)
              appendQuestion = iris.ui.questionBox( ...
                'Prompt', [ ...
                  'No file chosen. ', ...
                  'The earlier specified file already exists, ', ...
                  'how would you like to proceed?' ...
                ], ...
                'Title', 'No File Chosen', ...
                'Options', {'Overwrite', 'New', 'Append', 'Cancel'}, ...
                'Default', 'Append' ...
              );

              if strcmp(appendQuestion.response, 'Cancel')
                iris.app.Info.showWarning("Results not saved!");
                return
              end

            end

          end

          [obj.workingDirectory, obj.outputFile.Value, ~] = fileparts(outFile);
          rsInfo = obj.currentResultsFile;
          rsCx = matfile(rsInfo.Path, 'Writable', true);
        end

        doAppend = ~~exist(rsInfo.Path, 'file') && ...
          strcmp(appendQuestion.response, 'Append');
      end

    otherwise
      doAppend = strcmp(obj.AppendMethod, "yes");
  end

  %% Send data to workspace
  % If sending analysis to workspace, prompt to save in file as well
  % This process will not append values, will instead create a new struct
  if ~ ~obj.options.SendToCommandWindow
    announcer.update("Sending to workspace...");
    timer = tic;
    vName = matlab.lang.makeValidName(rsInfo.Name);

    if doAppend
      W = evalin('base', 'whos');
      namesInBase = string({W(:).name}');
      existInBase = startsWith(namesInBase, vName);

      if any(existInBase)
        nExistingVars = sum(existInBase);
        vName = sprintf('%s_%d', nExistingVars + 1);
      end

    end

    % finally, assign in the base workspace
    assignin('base', vName, S);
    while toc(timer) < 2, end
    % check if we should proceed
    proceedQuestion = iris.ui.questionBox( ...
    'Prompt', 'Results have been sent to the base workspace. Continue to save to disk?', ...
      'Title', 'Save To Disk?', ...
      'Options', {'Yes', 'No'}, ...
      'Default', 'Yes' ...
    );
    if strcmp(proceedQuestion.response, 'No'), return; end
  end

  %% Save Data to File

  announcer.update("Saving...");

  % save results to file
  vars = fieldnames(S);

  if doAppend
    % subset to vars that need appending
    existingVars = intersect(vars, who(rsCx));
    % handle special cases and build the output array.
    % theres probably a better method to doing this, but typically individual outputs
    % won't have too many repeating variables, and the variable array elements
    % shouldn't be too large...(hopefully)
    for v = string(existingVars')
      val = rsCx.(v);

      if (isscalar(val) || ~iscell(val)) && ~isa(val, 'IrisData') && ~istable(val)

        try
          tmp = [val(:)', S.(v)];
        catch
          tmp = [arrayfun(@(g)g, val(:)', 'uniformoutput', false), {S.(v)}];
        end

      elseif iscell(val)
        % preserve cell array (assume it was there for a reason)
        tmp = [val(:)', {S.(v)}];
      elseif isa(val, 'IrisData')
        tmp = {val, S.(v)};
      elseif istable(val)
        % try to append rows, or wrap in cells
        try
          tmp = vertcat(val, S.(v));
        catch err
          iris.app.Info.showWarning( ...
            sprintf("Tables couldn't be merged because: '%s'", err.message) ...
          );
          tmp = {val, S.(v)};
        end

      end

      rsCx.(v) = tmp;
    end

    % store any other non-existing variables
    vars = vars(~ismember(vars, existingVars));

    for v = string(vars')
      rsCx.(v) = S.(v);
    end

  else
    rsCx.Call = S.Call;

    for v = string(vars')
      rsCx.(v) = S.(v);
    end

  end

  %% HELPER FUNCTIONS
  % helper for deleting load show
  function killAnnouncer(LS, fx)
    fprintf('Analysis done! (%s @ %s)\n', fx, datestr(datetime('now')));
    LS.update("Done!");
    pause(0.5);
    LS.shutdown();
  end

end
