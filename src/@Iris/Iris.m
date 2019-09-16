classdef Iris < iris.app.Container
  %IRIS Main application to visualize and analyze electrophysiological data
  %   Written By Khris Griffis, for Sampath lab 2016-2019
  %   Contact khrisgriffis@ucla.edu
  
  properties
    sessionInfo %contains a log of current session actions
  end
  
  properties (Access = private)
    validFiles iris.data.validFiles
    loadShow
    keyMap
    navMap
  end
  
  
  methods (Access = private)
    %% Startup

    function startupFcn(app)
      % need to initialize 
      fprintf('Starting Iris {%s}.\n',app.sessionInfo.sessionStart);
    end
    
  end
    
  methods
    
    function app = Iris(varargin)
      app@iris.app.Container(varargin{:});
      app.validFiles = iris.data.validFiles();
      app.keyMap = iris.pref.keyboard.getDefault();
      app.navMap = iris.pref.controls.getDefault();
    end
    
  end
  
  methods (Access=protected)
    
    function preRun(app)
      preRun@iris.app.Container(app);
      
      cT = now;
      if ispc
        app.sessionInfo = struct( ...
          'sessionStart', cT, ...
          'sessionEnd', cT, ...
          'User', getenv('UserName'), ...
          'Profile', getenv('UserProfile'), ...
          'Domain', getenv('UserDomain') ...
          );
      else
        app.sessionInfo = struct( ...
          'sessionStart', cT, ...
          'sessionEnd', cT, ...
          'User', getenv('USER'), ...
          'Profile', getenv('HOME'), ...
          'Domain', getenv('LOGNAME') ...
          );
      end
      % Start ButterParam saving/loading parameters
      ButterParam('save');
      % Make the app visible
      app.visualize();
    end
    
    function postRun(app)
      postRun@iris.app.Container(app);
      app.loadShow = iris.ui.loadShow();
    end
    
    function preStop(app)
      preStop@iris.app.Container(app);
      cT = now;
      app.sessionInfo.sessionEnd = cT;
      if app.handler.isready
        % if data is running prompt if you would like to save the session
        doSave = iris.ui.questionBox( ...
          'Prompt', 'Would you like to save the current session?', ...
          'Title', 'Quit Iris', ...
          'Options', {'Yes','No'}, ...
          'Default', 'No' ...
          );
        if strcmp(doSave.response,'Yes')
          try
            app.saveSession([],[]);
          catch x
            %log x?
            iris.app.Info.showWarning('Session not saved.');
          end
        end
      end
      % reset stored prefs for toggles to false
      import iris.infra.eventData;
      for tID = {'Filter', 'Scale', 'Baseline'}
        Iris.setTogglePref(eventData(struct('source',tID{1},'value',false)));
      end
    end
    
    function postStop(app)
      postStop@iris.app.Container(app);
      startTime = app.sessionInfo.sessionStart;
      endTime = app.sessionInfo.sessionEnd;
      duration = datestr(endTime - startTime,'hh:MM:ss');
      dtime = @(t)sprintf('%s (%s)',datestr(t,'mmm DD, YYYY'),strtrim(datestr(t,'hh:MM:ssPM')));
      
      displayStruct = fastrmField(app.sessionInfo, {'sessionStart','sessionEnd'});
      displayStruct.startTime = dtime(startTime);
      displayStruct.endTime = dtime(endTime);
      displayStruct.duration = duration;
      fprintf('Exiting Iris DVA:\n');
      disp(displayStruct);
      fprintf('%%%s%%\n\n', repmat('-',1,40));
      try
        if ~app.loadShow.isClosed
          app.loadShow.shutdown();
        end
      catch x
        % log x
        h = findall(groot,'HandleVisibility', 'off');
        if ~isempty(h)
          for i = 1:length(h)
            try
              if contains(h(i).Name,'Iris')
                delete(h(i));
              end
            catch
              continue
            end
          end
        end
      end
    end
    
    function bind(app)
      bind@iris.app.Container(app);
      import iris.infra.eventData;
      
      %shorthands
      v = app.ui;
      s = app.services;
      h = app.handler;
      
      
      % Listen to the UI      
      app.addListener(v, 'KeyPress',              @app.keyedInput);
      app.addListener(v, 'LoadData',              @app.fileLoad);
      app.addListener(v, 'LoadSession',           @app.fileLoad);
      app.addListener(v, 'ImportData',            @app.fileLoad);
      app.addListener(v, 'ImportSession',         @app.fileLoad);
      app.addListener(v, 'SaveSession',           @app.saveSession);
      app.addListener(v, 'ExportDataView',        @app.onExportDataView);
      app.addListener(v, 'MenuCalled',            @app.callMenu);
      app.addListener(v, 'ModuleCalled',          @app.callModule);
      app.addListener(v, 'Close',                 @app.shutdownApp);
      app.addListener(v, 'DeviceViewChanged',     @app.onDeviceViewChange);
      app.addListener(v, 'TickerChanged',         @app.onTickerUpdated);
      app.addListener(v, 'NavigateData',          @app.onButtonNav);
      app.addListener(v, 'EpochToggled',          @app.onToggleEpoch);
      app.addListener(v, 'SwitchToggled',         @app.onToggleSwitch);
      app.addListener(v, 'SendToCmd',             @app.onSendToCmd);
      app.addListener(v, 'ImportAnalysis',        @app.onAnalysisImport);
      app.addListener(v, 'lastDataPoint', 'PostSet', @app.onLastDataPointSet);
      app.addListener(v, 'RequestRedraw',         @app.onRedrawRequest);
      app.addListener(v, 'SessionConversionCalled', @app.openSessionConverter);
      app.addListener(v, 'FixLayoutRequest',        @app.onFixLayoutRequest);
      app.addListener(v, 'RevertView',            @app.onRevertRequest);
      %app.addListener(v, 'PlotCompletedUpdate', @app.onPlottingCompleted); %unused
      
      % Listen to menu server
      app.addListener(s, 'onReaderAdded',     @app.updateReaders);
      app.addListener(s, 'onDisplayChanged',  @app.onServiceDisplayUpdate);
      
      % Listen to the data handler
      app.addListener(h, 'fileLoadStatus',  @app.updateLoadPercent);
      app.addListener(h, 'onCompletedLoad', @(s,e)app.visualize);
      app.addListener(h, 'onSelectionUpdated', @(s,e)app.draw);
      
    end
    
  end
%% CALLBACKS  
  methods (Access = protected)
    % external files
    keyedInput          ( app, source, event )
    fileLoad            ( app, source, event )
    callMenu            ( app, source, event )
    onTickerUpdated     ( app, source, event ) 
    onExportDataView    ( app,  source,  event )
    onServiceDisplayUpdate( app, source, event )
    onSendToCmd         ( app, source, event )
    keyedAction         ( app, action )
    navigate            ( app, event )
    
    %
    function onDeviceViewChange(app,~,event)
      if isempty(event.Data.Value)
        event.Data.Source.Value = event.Data.PreviousValue;
        return;
      end
      app.ui.selection.showingDevices = event.Data.Value;
      app.draw();
    end
    %
    function updateLoadPercent(app,~,event)
      if ~app.loadShow.isvalid || app.loadShow.isClosed
        app.loadShow = iris.ui.loadShow();
      end
      app.loadShow.updatePercent(event.Data);
    end
    %
    function resetView(app)
      app.ui.Axes.resetView();
    end
    %
    function onButtonNav(app,~,event)
      ed = event.Data;
      %struct('Direction','Increment', 'Amount', 'Small', 'Type', 'Epoch') ...
      if strcmpi(ed.Type, 'epoch')
        if strcmpi(ed.Direction, 'Increment')
          navString = [lower(ed.Amount),'Right'];
        else
          navString = [lower(ed.Amount),'Left'];
        end
      else
        if strcmpi(ed.Direction, 'Increment')
          navString = [lower(ed.Amount),'Up'];
        else
          navString = [lower(ed.Amount),'Down'];
        end
      end
      app.navigate(navString);
    end
    %
    function onLastDataPointSet(app,source,event)
      %%% TODO:
      % use this method to set the scale values on click.
      %disp(app.ui.lastDataPoint);
    end
    %
    function updateReaders(app,source,event)
      %%% TODO: update app.validFiles
      
      fprintf( ...
      '(TODO) Iris.updateReaders.\n' ...
      );
    end
    %
    function visualize(app)
      if ~app.handler.isready
        app.ui.toggleDataDependentUI('off');
        % also close open menus, etc.
        openMenus = app.services.getOpenMenus();
        prefLoc = strcmp(openMenus,'Preferences');
        openMenus(prefLoc) = [];
        if any(~prefLoc)
          app.services.shutdown(openMenus);
        end
        % exit
        return;
      end
      app.ui.toggleDataDependentUI('on');
      app.updateMenus();
      app.draw();
    end
    %
    function onToggleEpoch(app,~,event)
      % sel toggle selection
      app.handler.setInclusion(event.Data.index,event.Data.value);
      % allow primary to recolor through the axes object
      %app.draw(event.Data.index);
    end
    %
    function onToggleSwitch(app,~,event)
      Iris.setTogglePref(event);
      % Update any open menus, set calculations for stats and scales prefs.
      app.updateMenus();
      % update view
      if ~app.isStopped
        app.draw();
      end
    end
    %
    function onAnalysisImport(app,~,~)
      import iris.app.Info;
      [fxName,~,root] = Info.getFile( ...
        'Import Analysis File',...
        {'*.m','MATLAB Function'}, ...
        app.options.UserDirectory ...
        );
      if isempty(fxName), return; end
      fxName = char(fxName);
      [~,fx] = fileparts(fxName);
      % validate that we have a function
      try
        addpath(root);
        nIn = nargin(fxName);
        nOut = nargout(fxName);
        rmpath(root);
      catch x %log
        rmpath(root);
        Info.throwError(x.message);
      end
      if ~nOut
        Info.throwError('Function must have at least 1 output argument!');
      end
      if ~nIn
        Info.throwError('Function must have at least 1 input argument!');
      end
      azDir = iris.pref.analysis.getDefault().AnalysisDirectory;
      [success,msg] = copyfile(fxName,fullfile(azDir,[fx,'.m']),'f');
      if ~success
        Info.throwError(msg);
      end
    end
    %
    function onRevertRequest(app,~,~)
      app.handler.revertToLastView();
    end
    %
    function callModule(app,~,event)
      if ~app.handler.isready, return; end
      % collect current data from handler then send to module.
      doSave = iris.ui.questionBox( ...
        'Prompt', 'Send data from the current view, entire session, or without any inputs?', ...
        'Title', 'Open Module', ...
        'Options', {'Current','Session','Empty','Cancel'}, ...
        'Default', 'Cancel' ...
        );

      switch doSave.response
        case 'Current'
          iData = app.handler.exportCurrent();
        case 'Session'
          iData = app.handler.export();
        case 'Empty'
          iData = [];
        otherwise
          return;
      end
      
      try
        iris.modules.(event.Data)(iData);
      catch x
        iris.app.Info.throwError( ...
          sprintf( ...
          'Could not open module with reason:\n"%s"\n', ...
          x.message ...
          ) ...
          );
      end
    end
    %%%
    function saveSession(app,~,~)
      % get the session file filter text
      vf = app.validFiles;
      fInfo = vf.getIDFromLabel('Session');
      filterText = { ...
        strjoin(strcat('*.',fInfo.exts),';'), ...
        fInfo.label ...
        };
      % create a generic save name with filter
      fn = fullfile( ...
        app.options.UserDirectory, ...
        [datestr(app.sessionInfo.sessionStart,'YYYY-mmm-DD'),'.',fInfo.exts{1}] ...
        );
      % prompt user for final save location
      userFile = iris.app.Info.putFile('Save Iris Session', filterText, fn);
      if isempty(userFile)
        app.ui.focus();
        return;
      end
      app.loadShow.updatePercent('Saving Session...');
      session = app.handler.saveobj();
      try
        save(userFile,'session','-mat','-v7.3');
      catch e
        app.loadShow.updatePercent('Error!');
        pause(1.5);
        app.loadShow.shutdown();
        app.ui.focus();
        iris.app.Info.throwError(e.message);
        return %?
      end
      app.loadShow.updatePercent('Saved!');
      pause(1.5);
      fprintf('Iris Session saved to:\n"%s"\n',userFile);
      app.ui.focus();
      app.loadShow.shutdown();
    end
    
    function shutdownApp(app,~,~)
      % shutdown the application
      app.stop;
    end
    
    function onRedrawRequest(app,~,~)
      if ~app.handler.isready, return; end
      % future: when stats switch is implemented
      app.draw();
    end
    
    function openSessionConverter(app,~,~)
      app.ui.hide();
      files = ReadToSession();
      if ~isempty(files)
        openFiles = iris.ui.questionBox( ...
          'Prompt', 'Would you like to import converted files?', ...
          'Title', 'Import Conversions?', ...
          'Options', {'Import','Load','No'}, ...
          'Default', 'Import' ...
          );
        readerFx = app.validFiles.getReadFxnByLabel('Session');
        switch openFiles.response
          case 'Import'
            app.handler.import(files,readerFx);
          case 'Load'
            app.handler.new(files,readerFx);
          otherwise
            %do nothing
        end
      end
      % app.show() to redraw as well.
      app.show();
    end
    
    function onFixLayoutRequest(app,~,~)
      hasData = app.handler.isready;
      if hasData
        import iris.infra.eventData;
        currentState = app.handler.currentSelection.selected;
        tmpData = [tempname,'.isf'];
        session = app.handler.saveobj();
        save(tmpData,'session','-v7.3');
        pause(0.01);
        for tID = {'Filter', 'Scale', 'Baseline'}
          Iris.setTogglePref(eventData(struct('source',tID{1},'value',false)));
        end
      end  
      
      app.removeAllListeners();
      
      app.ui.shutdown();
      app.ui.reset();
      pause(0.01);
      
      app.ui.rebuild();
      pause(0.01);
      
      app.bind();
      if hasData
        app.handler.new(tmpData);
        app.handler.currentSelection = currentState;
        drawnow();
      else
        app.ui.toggleDataDependentUI('off');
      end
      app.show();
    end
    
  end
  
%% Convenience
  methods (Access = private)
    
    %update menus
    updateMenus(app)
    
    draw(app,varargin)
    
  end
  
%% Static
  methods (Static)
    
    function varargout = getModules(forceReload)
      % getModules Locate and install external and builtin modules
      %  Use @param forceRelaod = true to reload from builtin and user modules
      if nargin < 1, forceReload = true; end
      % module package location
      modulePkgDir = fullfile( ...
        iris.app.Info.getAppPath(),'src','+iris','+modules' ...
        );
      installedModules = regexprep(cellstr(ls([modulePkgDir,filesep,'*.mlapp'])),'\.mlapp', '');
      % reload from builtin and user directories?
      if forceReload
        %Builtin modules will be stored in a resource folder, which isn't added to
        %path.
        builtinDir = fullfile( ...
          iris.app.Info.getResourcePath, ...
          'Modules' ...
          );
        builtinModules = cellstr(ls( ...
          fullfile(builtinDir,'*.mlapp') ...
          ));
        % get custom from preferences Module directory.
        wsVars = iris.pref.analysis.getDefault();
        externalModules = cellstr(ls( ...
          fullfile( ...
            wsVars.ExternalModulesDirectory, ...
            '*.mlapp' ...
            ) ...
          ));
        % make absolute paths
        modules = [ ...
          fullfile(builtinDir,builtinModules(:)); ...
          fullfile(wsVars.ExternalModulesDirectory,externalModules(:)) ...
          ];
        % filter out the empty case (doesn't end with .mlapp)
        modules = modules(endsWith(modules,'.mlapp','IgnoreCase',true));
        % copy to a package folder to prevent overloading any functions. This method
        % will always search the user and builtin directories and replace/clear missing
        % modules in the package folder +modules. This let's us make changes to module
        % code and refresh
        if ispc
          folderSep = [filesep,filesep];
        else
          folderSep = filesep;
        end
        modNames = regexp( ...
          modules, ...
          sprintf('(?<=%s)\\w*(?=\\.mlapp$)', ...
          folderSep), ...
          'match' ...
          );
        if ~ischar(modNames{1})
          modNames = cat(1,modNames{:});
        end
        modNames = regexprep(modNames, '\.mlapp', '');
        % camelize names
        modNames = cellfun(@camelizer,modNames,'unif',0);
        % gen paths
        newPaths = fullfile( ...
          modulePkgDir, ...
          strcat(modNames,'.mlapp') ...
          );
        
        % clear modules package
        delete(fullfile(modulePkgDir,'*.mlapp'));
        % copy files to package
        msgs = cell(length(modules),1);
        for m = 1:length(modules)
          [status,msg] = copyfile(modules{m},newPaths{m},'f');
          if ~status
            msgs{m} = msg;
          end
        end
      else
        msgs = {};
        modNames = installedModules(:);
      end
      
      %outputs
      if ~nargout, return; end
      varargout{1} = modNames;
      varargout{2} = msgs;
    end
    
    function status = versionCheck()
      %default output
      status = false;
      
      instVer = iris.pref.Iris.getDefault().CurrentVersion;
      prevPrefs = getpref('iris');
      if isempty(prevPrefs)
        %first run, ok return good
        status = true;
        return;
      end
      
      % compare versions
      prevVer = prevPrefs.iris_pref_Iris('iris_pref_Iris');
      prevVer = prevVer('CurrentVersion');
      
      if strcmp(instVer,prevVer)
        % same version, ok return good
        status = true;
        return;
      end
      
      
      %Assume we are upgrading, try to cycle through and update new prefs
      %with olds prefs
      %%% TODO
      
    end
    
    function setTogglePref(event)
      prefName = [upper(event.Data.source(1)),lower(event.Data.source(2:end))];
      switch prefName
        case 'Filter'
          prefs = iris.pref.dsp.getDefault();
          sx = 'ed';
        case 'Scale'
          prefs = iris.pref.scales.getDefault();
          sx = 'd';
        case 'Baseline'
          prefs = iris.pref.statistics.getDefault();
          sx = 'd';
        otherwise
          return;
      end
      prefs.(['is',prefName,sx]) = event.Data.value;
      prefs.save();
    end
    
  end
end

