classdef Iris < iris.app.Container
  %IRIS Main application to visualize and analyze electrophysiological data
  %   Written By Khris Griffis, for Sampath lab 2016-2019
  %   Contact khrisgriffis@ucla.edu
  
  properties
    sessionInfo %contains a log of current session actions
    loadShow
  end
  
  properties (Access = private)
    validFiles iris.data.validFiles
    keyMap
    navMap
    openedModules = {}
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
    
    function onInstallHelpersRequested(app,~,~)
      
      % locate the known directory and the root
      hDir = app.options.HelpersDirectory;
            
      sourceRootPath = fullfile(iris.app.Info.getResourcePath(),'scripts','helper');
      sourcePath = fullfile(sourceRootPath,'@IrisDVA');
      
      if (isempty(hDir) || strcmp(hDir,""))
        % prompt
        pt = iris.ui.questionBox( ...
          'Title', 'Install Helpers', ...
          'Prompt', 'Install helper files? This will also add the files to your path.', ...
          'Options', {'Yes', 'No'}, ...
          'Default', 'Yes' ...
          );
        if strcmp(pt.response,'No'), return; end
        installLocation = '';
        
      else
        oldDir = pwd();
        cd(sourceRootPath);
        newVersion = IrisDVA.VERSION;
        cd(oldDir);
        
        % f should be "...\@IrisDVA\IrisDVA.m"
        f = which('IrisDVA.m');
        if ~isempty(f)
          % we expect to enter this condition.
          installLocation = fileparts(fileparts(f));
          
          cd(installLocation);
          installedVersion = IrisDVA.VERSION;
          cd(oldDir);
          
          if newVersion == installedVersion
            fprintf("Current IrisDVA class is up-to-date!\n");
            app.options.HelpersDirectory = installLocation;
            return
          end
          qString = sprintf( ...
            "Would you like to update the IrisDVA V%s class to V%s?", ...
            installedVersion, newVersion ...
            );
          pt = iris.ui.questionBox( ...
            'Title', 'Update Helpers', ...
            'Prompt', qString, ...
            'Options', {'Yes', 'Cancel'}, ...
            'Default', 'Yes' ...
            );
          if strcmp(pt.response,'Cancel'), return; end
        else
          % we have an helpers directory but it isn't added to the path
          % let's verify we have the right docs there
          try
            cd(hDir);
            installedVersion = IrisDVA.VERSION;
            cd(oldDir);
            
            if newVersion == installedVersion
              fprintf("Current IrisDVA class is up-to-date!\n");
              app.options.HelpersDirectory = hDir;
              return
            end
            qString = sprintf( ...
              "Would you like to update the IrisDVA V%s class to V%s?", ...
              installedVersion, newVersion ...
              );
            pt = iris.ui.questionBox( ...
              'Title', 'Update Helpers', ...
              'Prompt', qString, ...
              'Options', {'Yes', 'Cancel'}, ...
              'Default', 'Yes' ...
              );
            if strcmp(pt.response,'Cancel'), return; end
            
            installLocation = hDir;
            
          catch
            % if any of those fail, we assume the hDir is wrong for some reason.
            cd(oldDir);
            installLocation = '';
          end
          
        end
        
      end
      
      if isempty(installLocation)
        installLocation = iris.app.Info.getFolder( ...
          'Select Install Location', ...
          app.options.UserDirectory ...
          );
        if isempty(installLocation), return; end
      end

      % copy to the new location
      copyfile(sourcePath,fullfile(installLocation,'@IrisDVA'),'f');
      
      pdef = strsplit(pathdef,';');
      pdef(cellfun(@isempty,pdef,'uniformoutput', true)) = [];
      
      currentPath = strsplit(path,';');
      currentPath(cellfun(@isempty,currentPath,'uniformoutput', true)) = [];
      
      pathsToRestore = strjoin(currentPath(~ismember(currentPath,pdef)),pathsep);
      rmpath(pathsToRestore);
      pause(0.01);
      addpath(installLocation);
      savepath();
      pause(0.05);
      addpath(pathsToRestore);
      % store the install location
      app.options.HelpersDirectory = installLocation;
      % report
      fprintf('Operation completed successfully!\n');
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
      % 
      
      % Make the app visible
      app.visualize();
    end
    
    function postRun(app)
      postRun@iris.app.Container(app);
      app.loadShow = iris.ui.loadShow();
    end
    
    function preStop(app)
      import iris.infra.eventData;
      preStop@iris.app.Container(app);
      cT = now;
      app.sessionInfo.sessionEnd = cT;
      % reset stored prefs for toggles to false
      for tID = {'Filter', 'Scale', 'Baseline'}
        Iris.setTogglePref(eventData(struct('source',tID{1},'value',false)));
      end
      try %#ok<TRYNC>
        app.options.save();
      end
      
    end
    
    function postStop(app)
      postStop@iris.app.Container(app);
      startTime = app.sessionInfo.sessionStart;
      endTime = app.sessionInfo.sessionEnd;
      duration = datestr(endTime - startTime,'hh:MM:ss');
      dtime = @(t)sprintf('%s (%s)',datestr(t,'mmm DD, YYYY'),strtrim(datestr(t,'hh:MM:ssPM')));
      
      displayStruct = utilities.fastrmField(app.sessionInfo, {'sessionStart','sessionEnd'});
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
        fprintf('postStop caught\n')
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
      % clean modules
      Iris.cleanModules();
    end
    
    function bind(app)
      bind@iris.app.Container(app);
      import iris.infra.eventData;
      
      %shorthands
      v = app.ui;
      s = app.services;
      h = app.handler;
      
      % listen to the didStop
      app.addListener(app, 'didStop', @app.onAppStopped);
      
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
      app.addListener(v, 'DeviceViewChanged',     @app.onDeviceViewChange);
      app.addListener(v, 'TickerChanged',         @app.onTickerUpdated);
      app.addListener(v, 'NavigateData',          @app.onButtonNav);
      app.addListener(v, 'DatumToggled',          @app.onToggleDatum);
      app.addListener(v, 'SwitchToggled',         @app.onToggleSwitch);
      app.addListener(v, 'SendToCmd',             @app.onSendToCmd);
      app.addListener(v, 'ImportAnalysis',        @app.onAnalysisImport);
      app.addListener(v, 'lastDataPoint', 'PostSet', @app.onLastDataPointSet);
      app.addListener(v, 'RequestRedraw',         @app.onRedrawRequest);
      app.addListener(v, 'SessionConversionCalled', @app.openSessionConverter);
      app.addListener(v, 'FixLayoutRequest',        @app.onFixLayoutRequest);
      app.addListener(v, 'RevertView',            @app.onRevertRequest);
      app.addListener(v, 'InstallHelpersRequest', @app.onInstallHelpersRequested);
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
      %struct('Direction','Increment', 'Amount', 'Small', 'Type', 'Data') ...
      if strcmpi(ed.Type, 'Data')
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
        return
      end
      app.draw();
      app.updateLoadPercent([],struct('Data','Updating Menus...'));
      CU = onCleanup(@()killload(app.loadShow));
      app.updateMenus();
      app.services.setGroups(app.handler.getAllGroupingFields);
      app.ui.toggleDataDependentUI('on');
      function killload(ls)
        ls.shutdown();
      end
    end
    %
    function onToggleDatum(app,~,event)
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
      if ~app.handler.isready
        doSave.response = 'Empty'; 
      else
        % collect current data from handler then send to module.
        doSave = iris.ui.questionBox( ...
          'Prompt', 'Send data from the current view, entire session, or without any inputs?', ...
          'Title', 'Open Module', ...
          'Options', {'Current','Session','Empty','Cancel'}, ...
          'Default', 'Current' ...
          );
      end

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
      % check if previously opened modules are now closed
      wasClosed = cellfun(@(m)~isvalid(m), app.openedModules,'UniformOutput',true);
      app.openedModules(wasClosed) = [];
      
      % called module name
      moduleName = sprintf('iris.modules.%s',event.Data);
      % check opened modules for requested module.
      isOpen = cellfun( ...
        @(m) isa(m,moduleName), ...
        app.openedModules, ...
        'UniformOutput', true ...
        );
      
      if any(isOpen)
        % if the module is already open and valid, let's try to access the
        % setData() method in order to update the data object.
        m = app.openedModules{isOpen};
        try
          m.setData(iData);
        catch x
          iris.app.Info.throwError( ...
            sprintf( ...
            ['Could not update module data with reason:\n"%s"\n(%s)\n(%s)\n', ...
            'Implement a public setData() method to allow Iris to update data.'],...
            x.message, ...
            sprintf('line %d : %s',x.stack(1).line,x.stack(1).name), ...
            sprintf('line %d : %s',x.stack(end).line,x.stack(end).name) ...
            ) ...
            );
        end
      else
        try
          m = feval(moduleName,iData);
        catch x
          iris.app.Info.throwError( ...
            sprintf( ...
            'Could not open module with reason:\n"%s"\n(%s)\n(%s)\n', ...
            x.message, ...
            sprintf('line %d : %s',x.stack(1).line,x.stack(1).name), ...
            sprintf('line %d : %s',x.stack(end).line,x.stack(end).name) ...
            ) ...
            );
        end
        app.openedModules{end+1} = m;
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
    
    function onRedrawRequest(app,~,~)
      if ~app.handler.isready, return; end
      % future: when stats switch is implemented
      app.draw();
    end
    
    function openSessionConverter(app,~,~)
      app.ui.hide();
      files = utilities.ReadToSession();
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
      import iris.infra.eventData;
      hasData = app.handler.isready;
      if hasData
        currentState = app.handler.currentSelection.selected;
        tmpData = [tempname,'.isf'];
        session = app.handler.saveobj();
        save(tmpData,'session','-v7.3');
        pause(0.01);
        for tID = {'Filter', 'Scale', 'Baseline'}
          Iris.setTogglePref(eventData(struct('source',tID{1},'value',false)));
        end
      end  
      
      app.unbind();
      
      app.ui.shutdown();
      app.ui.reset();
      pause(0.01);
      
      app.ui.rebuild();
      pause(0.01);
      
      app.bind();
      if hasData
        app.handler.new(tmpData);
        app.handler.currentSelection = currentState;
        app.ui.toggleDataDependentUI('on');
      else
        app.ui.toggleDataDependentUI('off');
      end
      app.show();
    end
    
    function onAppStopped(app,~,~) %#ok<INUSD>
      % do anything?
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
    
    varargout = getModules(forceReload)
    [installedModules,status] = cleanModules()
    
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
      if ~prevVer.isKey('CurrentVersion')
        prevVer = '0';
      else
        prevVer = prevVer('CurrentVersion');
      end
      
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

