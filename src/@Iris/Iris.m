classdef Iris < iris.app.Container
  %IRIS Main application to visualize and analyze electrophysiological data
  %   Written By Khris Griffis, for Sampath lab 2016-2019
  %   Contact khrisgriffis@ucla.edu
  
  properties (Access = private)
    sessionInfo %contains a log of current session actions
    validFiles iris.data.validFiles
    loadShow
    keyMap
    navMap
  end
  
  
  methods (Access = private)
    %% The Startup Function

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
      % Make the app visible
      app.visualize();
    end
    
    function postRun(app)
      postRun@iris.app.Container(app);
      app.loadShow = iris.ui.loadShow();
    end
    
    function preStop(app)
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
          app.saveSession([],[]);
        end
      end
      % reset stored prefs for toggles to false
      import iris.infra.eventData;
      for tID = {'Filter', 'Scale', 'Baseline'}
        app.onToggleSwitch([],eventData(struct('source',tID{1},'value',false)));
      end
    end
    
    function postStop(app)
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
      app.addListener(v, 'Close',                 @app.shutdownApp);
      app.addListener(v, 'DeviceViewChanged',     @app.onDeviceViewChange);
      app.addListener(v, 'TickerChanged',         @app.onTickerUpdated);
      app.addListener(v, 'NavigateData',          @app.onButtonNav);
      app.addListener(v, 'EpochToggled',          @app.onToggleEpoch);
      app.addListener(v, 'SwitchToggled',         @app.onToggleSwitch);
      app.addListener(v, 'ShowStatistics',        @app.onShowStats);
      app.addListener(v, 'SendToCmd',             @app.onSendToCmd);
      
      % Listen to menu server
      app.addListener(s, 'dataRequest',       @app.supplyData);
      app.addListener(s, 'onReaderAdded',     @app.updateReaders);
      app.addListener(s, 'onDisplayChanged',  @app.onServiceDisplayUpdate);
      
      % Listen to the data handler
      app.addListener(h, 'fileLoadStatus',  @app.updateLoadPercent);
      app.addListener(h, 'onCompletedLoad', @(s,e)app.visualize);
      app.addListener(h, 'onSelectionUpdated', @(s,e)app.visualize);
      
    end
    
  end
%% CALLBACKS  
  methods (Access = protected)
    % external files
    keyedInput          ( app,  src,	event )
    fileLoad            ( app,  src,	event )
    callMenu            ( app,  src,	event )
    supplyData          ( app,  src,	event )
    onTickerUpdated     ( app,  src,  event ) 
    navigate            ( app, event )
    onExportDataView    ( app,  src,  event )
    keyedAction         ( app, action )
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
    function onServiceDisplayUpdate(app,~,~)
      % onServiceDisplayUpdate catch changes that affect currently drawn 
      % This method could be used to intercept changes made to preferences before
      % redrawing the 
      app.draw();
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
    function updateReaders(app,src,event)
      %%% TODO: update app.validFiles
      disp(event);
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
      app.draw();
    end
    %
    function onToggleEpoch(app,~,evt)
      % sel toggle selection
      app.handler.setInclusion(evt.Data.index,evt.Data.value);
      app.draw();
    end
    %
    function onToggleSwitch(app,~,evt)
      prefName = [upper(evt.Data.source(1)),lower(evt.Data.source(2:end))];
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
          disp('Iris.onToggleSwitch');
          disp(prefName);
          return;
      end
      prefs.(['is',prefName,sx]) = evt.Data.value;
      prefs.save();
      % update view
      if ~app.isStopped
        app.draw();
      end
    end
    %
    function onShowStats(app,~,~)
      disp('Show Stats window coming soon.')
    end
    %
    function onSendToCmd(app,~,~)
      disp('"Send current view to command" operation coming soon.');
    end
    
    %%%
    function saveSession(app,~,~)
      saveLocation = app.options.UserDirectory;
      disp(saveLocation)
    end
    
    function shutdownApp(app,~,~)
      % shutdown the application
      app.stop;
    end
    
  end
  
%% Convenience
  methods (Access = private)
    function draw(app)
      % Update any open menus.
      app.services.updateMenus();
      app.ui.updateView(app.handler);
      % TODO::
      % Rather than sending the handler, let's send only the plot data
      % along with relevant things needed for the UI to update the view.
      % Send the selection, display information and plot data.
    end
  end
end

