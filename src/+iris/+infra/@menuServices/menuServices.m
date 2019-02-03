classdef menuServices < handle
  
  events
    % listened to by main application
    preferenceUpdated
    dataUpdated
    analyzeCurrent
    dataRequest
  end
  
  properties
    Analyze         iris.ui.analyze
    NewAnalysis     iris.ui.newAnalysis
    Preferences     iris.ui.preferences
    FileInfo        iris.ui.fileInfo
    DataOverview    iris.ui.dataOverview
    Notes           iris.ui.notes
    Protocols       iris.ui.protocols
    About           iris.ui.about
    %Help            iris.ui.help
  end
  
  properties (Access = private)
    listeners = cell(0)
  end
  
  methods
    
    function obj = menuServices()
      % Let's init prefereences since we can modify prefs without data
      % being loaded.
      obj.Preferences = iris.ui.preferences();
      obj.bind('Preferences');
    end
    
    function bind(obj,menuName)
      if nargin < 2, error('Provide valid menu name.'); end
      menuName = validatestring(lower(menuName),properties(obj));
      switch menuName
        case 'Analyze'
          az = obj.Analyze;
          obj.addListener(az, 'Close', @obj.destroyWindow);
          obj.addListener(az, 'requestData', @obj.dataRequested);
        case 'NewAnalysis'
          na = obj.NewAnalysis;
          obj.addListener(na, 'Close', @obj.destroyWindow);
          obj.addListener(na, 'createFunction', @obj.createNewAnalysis);
        case 'Preferences'
          pr = obj.Preferences;
          obj.addListener(pr, 'Close', @obj.destroyWindow);
        case 'FileInfo'
        case 'DataOverview'
        case 'Notes'
        case 'Protocols'
        case 'About'
        case 'Help'
      end
    end
    
    function l = dispLis(obj)
      l = cellfun(@(l)l.EventName,obj.listeners,'unif',0);
    end
    
    function l = addListener(obj, varargin)
      l = addlistener(varargin{:});
      obj.listeners{end+1} = l;
    end
    
    function removeListener(obj,listener)
      loc = ismember(...
        cellfun(@(l)l.EventName, obj.listeners,'unif',0),...
        listener.EventName);
      if ~any(loc), disp('Listener non-existent'); end
      delete(listener)
      obj.listeners(loc) = [];
    end
    
    function build(obj,menuName,varargin)
      if nargin < 2, error('Provide valid menu name.'); end
      menuName = validatestring(lower(menuName),properties(obj));
      
      % TODO: move isClosed check to use the rebuild method
      % Once rebuild() is implemented on all objects
      switch menuName
        case 'Analyze'
          if isempty(obj.Analyze) || obj.Analyze.isClosed
            obj.Analyze = iris.ui.analyze();
          end
          if nargin > 2
            % varargin{1} will be an array of epoch numbers
            obj.Analyze.EpochNumbers = varargin{1};
          end
        case 'NewAnalysis'
          if isempty(obj.NewAnalysis) || obj.NewAnalysis.isClosed
            obj.NewAnalysis = iris.ui.newAnalysis;
          end
        case 'Preferences'
          if isempty(obj.Preferences) || obj.Preferences.isClosed
            obj.Preferences = iris.ui.preferences();
          end
        case 'FileInfo'
          if isempty(obj.FileInfo) || obj.FileInfo.isClosed
            obj.FileInfo = iris.ui.fileInfo(); 
          end
          if nargin < 3
            error( ...
              'File Info requires cell array of structs for each file' ...
              );
          end
          % varargin should be cell array of structs
          obj.FileInfo.buildUI(varargin{:});
        case 'DataOverview'
          if isempty(obj.DataOverview) || obj.DataOverview.isClosed
            obj.DataOverview = iris.ui.dataOverview(); 
          end
          if nargin < 3
            error('DataOverview Requires Handler object as input.');
          end
          % varargin should contain data Handler
          obj.DataOverview.buildUI(varargin{:});
        case 'Notes'
          if isempty(obj.Notes) || obj.Notes.isClosed
            obj.Notes = iris.ui.notes(); 
          end
          if nargin < 3
            error('Notes requires a Nx2 Cell of Notes');
          end
          obj.Notes.buildUI(varargin{:});
        case 'Protocols'
          if isempty(obj.Protocols) || obj.Protocols.isClosed
            obj.Protocols = iris.ui.protocols();
          end
          if nargin < 3
            error( ...
              ['Protocols  requires a Nx2 cell of experiment',...
              'parameters/protocols.'] ...
              );
          end
          obj.Protocols.buildUI(varargin{:});
        case 'About'
          if isempty(obj.About) || obj.About.isClosed
            obj.About = iris.ui.about();
          end
      end
      % bind the appropriate listeners
      obj.bind(menuName);
      % show the gui
      obj.(menuName).show();
      
    end
    
    function shutdown(obj,menuName)
      if nargin < 2, menuName = ''; end
      uis = properties(obj);
      if ~isempty(menuName)
        menuName = validatestring(menuName,uis);
        uis = uis(ismember(uis,menuName));
      end
      for p = 1:length(uis)
        if isempty(obj.(uis{p})) || obj.(uis{p}).isClosed()
          continue;
        end
        obj.(uis{p}).shutdown();
        delete(obj.(uis{p}));
      end
    end
    
    function savePrefs(obj,menuName)
      if nargin < 2, menuName = ''; end
      uis = properties(obj);
      if ~isempty(menuName)
        menuName = validatestring(menuName,uis);
        uis = uis(ismember(uis,menuName));
      end
      for p =1:length(uis)
        if isempty(obj.(uis{p})) || obj.(uis{p}).isClosed()
          continue;
        end
        obj.(uis{p}).save();
      end
    end
    
    function resetPrefs(obj,menuName)
      if nargin < 2, menuName = ''; end
      uis = properties(obj);
      if ~isempty(menuName)
        menuName = validatestring(menuName,uis);
        uis = uis(ismember(uis,menuName));
      end
      for p =1:length(uis)
        if isempty(obj.(uis{p})) || obj.(uis{p}).isClosed()
          continue;
        end
      obj.(uis{p}).reset();
      end
    end
    function removeAllListeners(obj)
      while ~isempty(obj.listeners)
        delete(obj.listeners{1});
        obj.listeners(1) = [];
      end
    end
    
    function enableListener(obj, listener)
      loc = ismember(...
        cellfun(@(l)l.EventName, obj.listeners, 'unif',0),...
        listener.EventName);
      if ~any(loc), disp('Listener non-existent'); end
      obj.listeners{loc}.Enabled = true;
    end
    
    function disableListener(obj,listener)
      loc = ismember(...
        cellfun(@(l)l.EventName, obj.listeners,'unif',0),...
        listener.EventName);
      if ~any(loc), disp('Listener non-existent'); end
      obj.listeners{loc}.Enabled = false;
    end
    
    function enableAllListeners(obj)
      for o = 1:length(obj.listeners)
        obj.listeners{o}.Enabled = true;
      end
    end
    
    function disableAllListeners(obj)
      for o = 1:length(obj.listeners)
        obj.listeners{o}.Enabled = false;
      end
    end
    
    
  end
  
  methods (Access = private)
    % listener callback definitions
    %eg. doCallback(obj,src,evt)
    createNewAnalysis(obj,src,evt)
    
    function destroyWindow(obj,src,~)
      srcClass = class(src);
      try
        src.selfDestruct();
      catch x
        warning([x.message,'\nDeleting object...']);
        delete(src);
      end
      obj.cleanListeners(srcClass);
    end
    
    % clear up listneers
    function cleanListeners(obj,varargin)
      if ~isempty(varargin)
        % varargin{1}: class name
        % varargin{2}: event names for class
        % gather listeners associated with provided class
        listenerInds = cellfun( ...
          @(l) ...
            strcmpi(class(l.Source{1}),varargin{1}), ...
          obj.listeners, ...
          'uniformOutput', true ...
          );
        if length(varargin) > 1
          % delete supplied event names
          listenerEvents = cellfun( ...
            @(l) l.EventName, ...
            obj.listeners, ...
            'UniformOutput', false ...
            );
          eventsToDelete = [varargin{2:end}];
          eventMatches = ismember(listenerEvents,eventsToDelete);
          
          for e = 1:length(obj.listeners)
            delete( ...
              obj.listeners{ ...
                eventMatches(e) && ...
                listenerInds(e) ...
              });
          end
        else
          % delete all listeners for class
          cellfun(@delete, ...
            obj.listeners(listenerInds), ...
            'unif', false ...
            );
        end
      end
      emptyInds = cellfun(...
        @(l)isempty(l) || ~l.isvalid,obj.listeners, ...
        'UniformOutput',true ...
        );
      if any(emptyInds)
        obj.listeners(emptyInds) = [];
        return;
      end
      
    end
  end
  
end

