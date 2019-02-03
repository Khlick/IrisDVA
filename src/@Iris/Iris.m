classdef Iris < iris.app.Container
  %IRIS Main application to visualize and analyze electrophysiological data
  %   Written By Khris Griffis, for Sampath lab 2016-2019
  %   Contact khrisgriffis@ucla.edu
  
  properties (Access = private)
    sessionInfo %contains a log of current session actions
  end
  
  
  methods (Access = private)
    %% The Startup Function

    function startupFcn(app)
      % need to initialize 
      disp('startup fcn');
    end
    
  end
    
  methods
     
  end
  
  methods (Access=protected)
    
    function bind(app)
      bind@iris.app.Container(app);
      import iris.infra.eventData;
      
      %shorthands
      v = app.ui;
      s = app.services;
      h = app.handler;
      
      % Listen to the UI      
      app.addListener(v, 'KeyPress',                  @app.keyedInput);
      app.addListener(v, 'LoadData',                  @app.fileLoad);
      app.addListener(v, 'LoadSession',               @app.fileLoad);
      app.addListener(v, 'ImportData',                @app.fileLoad);
      app.addListener(v, 'ImportSession',             @app.fileLoad);
      app.addListener(v, 'MenuCalled',                @app.callMenu);
      app.addListener(v, 'Close',                     @app.shutdownApp);
      
      % Listen to menu server
      app.addListener(s, 'dataRequest',               @app.supplyData);
      
    end
    
    function preRun(app) 
      preRun@iris.app.Container(app);
      % Make the app visible
      if app.handler.isready
        app.ui.toggleDataDependentUI('on');
        app.ui.updateView(app.handler(1));
      else
        app.ui.toggleDataDependentUI('off');
      end
    end
    
  end
%% CALLBACKS  
  methods (Access = protected)
    % external files
    keyedInput          ( app,  src,	event )
    fileLoad            ( app,  src,	event )
    callMenu            ( app,  src,	event )
    supplyData          ( app,  src,	event )
    %%%
    function shutdownApp(app,~,~)
      % prompt if you would like to save the session
      doSave = iris.ui.questionBox( ...
        'Prompt', 'Would you like to save the current session?', ...
        'Title', 'Quit Iris', ...
        'Options', {'Yes','No'}, ...
        'Default', 'No' ...
        );
      if doSave
        % save in the current output directory
        fprintf('Not saved, functionality coming soon.\n');
      end
      % shutdown the application
      app.stop;
    end
  end
end

