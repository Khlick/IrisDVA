classdef menuServices < handle
  
  events
    % listened to by main application
    preferenceUpdated
    onDisplayChanged
    dataUpdated
    analyzeCurrent
    onReaderAdded
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
    Help            %empty
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
    
    function tf = isOpen(obj,menuName)
      mName = validatestring(menuName,properties(obj));
      tf = ~isempty(obj.(mName)) && ~(~obj.(mName).isvalid || ~obj.(mName).isready);
    end
    
    function openList = getOpenMenus(obj)
      openList = {};
      for p = properties(obj)'
        if ~obj.isOpen(p{1}), continue; end
        openList(1,end+1) = p; %#ok<AGROW>
      end
    end
    
    function tf = isVisible(obj,menuNames)
      if nargin < 2
        menuNames = 'all';
      end
      if ~iscellstr(menuNames)
        menuNames = cellstr(menuNames);
      end
      
      if any(strcmp(menuNames,'all'))
        menuNames = properties(obj)';
      else
        menuNames = cellfun( ...
          @(s)validatestring(s,properties(obj)), ...
          menuNames, ...
          'UniformOutput', false ...
          );
      end
      % get the isVisible return from each menu
      tf = zeros(length(menuNames),1);
      for I = 1:length(menuNames)
        tf(I) = obj.isOpen(menuNames{I}) && obj.(menuNames{I}).isVisible;
      end
      
    end
    
    function pref = getPref(obj,prefName)
      pref = obj.Preferences.getPreference(prefName);
    end
    
    function bind(obj,menuName)
      import iris.infra.eventData;
      
      if nargin < 2, error('Provide valid menu name.'); end
      menuName = validatestring(lower(menuName),properties(obj));
      if obj.(menuName).isBound, return; end
      switch menuName
        case 'Analyze'
          az = obj.Analyze;
          obj.addListener(az, 'Close', @obj.destroyWindow);
        case 'NewAnalysis'
          na = obj.NewAnalysis;
          obj.addListener(na, 'Close', @obj.destroyWindow);
          obj.addListener(na, 'createFunction', @obj.createNewAnalysis);
        case 'Preferences'
          pr = obj.Preferences;
          obj.addListener(pr, 'Close', @obj.destroyWindow);
          obj.addListener(pr, 'NewReaderCreated', ...
            @(s,e)notify(obj, 'onReaderAdded', eventData(e.Data)) ...
            );
          obj.addListener(pr, 'DisplayChanged', ...
            @(s,e) obj.displayChangedEvent('Display',e.Data) ...
            );
          obj.addListener(pr, 'StatisticsChanged', ...
            @(s,e) obj.displayChangedEvent('Statistics',e.Data) ...
            );
          obj.addListener(pr, 'FilterChanged', ...
            @(s,e) obj.displayChangedEvent('Filter',e.Data) ...
            );
          obj.addListener(pr, 'ScalingChanged', ...
            @(s,e) obj.displayChangedEvent('Scaling',e.Data) ...
            );
            
        case 'FileInfo'
          fi = obj.FileInfo;
          obj.addListener(fi,'Close', @obj.destroyWindow);
        case 'DataOverview'
          ov = obj.DataOverview;
          obj.addListener(ov,'Close', @obj.destroyWindow);
        case 'Notes'
          nt = obj.Notes;
          obj.addListener(nt,'Close', @obj.destroyWindow);
        case 'Protocols'
          ps = obj.Protocols;
          obj.addListener(ps,'Close', @obj.destroyWindow);
        case 'About'
          ab = obj.About;
          obj.addListener(ab,'Close',@obj.destroyWindow);
        case 'Help'
          return
      end
      obj.(menuName).isBound = true;
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
      delete(listener);
      obj.listeners(loc) = [];
    end
    
    function build(obj,menuName,varargin)
      if nargin < 2, error('Provide valid menu name.'); end
      menuName = validatestring(lower(menuName),properties(obj));
      
      % TODO: move isClosed check to use the rebuild method
      % Once rebuild() is implemented on all objects
      switch menuName
        case 'Analyze'
          if isempty(obj.Analyze) || ~obj.isOpen('Analyze')
            obj.Analyze = iris.ui.analyze();
          end
          if nargin < 3
            error('DataOverview Requires Handler object as input.');
          end
          % varargin should contain data Handler
          obj.Analyze.buildUI(varargin{:});
        case 'NewAnalysis'
          if isempty(obj.NewAnalysis) || ~obj.isOpen('NewAnalysis')
            obj.NewAnalysis = iris.ui.newAnalysis;
          end
        case 'Preferences'
          if isempty(obj.Preferences) || ~obj.isOpen('Preferences')
            obj.Preferences = iris.ui.preferences();
          end
        case 'FileInfo'
          if isempty(obj.FileInfo) || ~obj.isOpen('FileInfo')
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
          if isempty(obj.DataOverview) || ~obj.isOpen('DataOverview')
            obj.DataOverview = iris.ui.dataOverview(); 
          end
          if nargin < 3
            error('DataOverview Requires Handler object as input.');
          end
          % varargin should contain data Handler
          obj.DataOverview.buildUI(varargin{:});
        case 'Notes'
          if isempty(obj.Notes) || ~obj.isOpen('Notes')
            obj.Notes = iris.ui.notes(); 
          end
          if nargin < 3
            error('Notes requires a Nx2 Cell of Notes');
          end
          obj.Notes.buildUI(varargin{:});
        case 'Protocols'
          if isempty(obj.Protocols) || ~obj.isOpen('Protocols')
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
          if isempty(obj.About) || ~obj.isOpen('About')
            obj.About = iris.ui.about();
          end
        case 'Help'
          web(iris.app.Info.site(), '-browser');
          return;
      end
      % bind the appropriate listeners
      obj.bind(menuName);
      % show the gui
      obj.(menuName).show();
      
    end
    
    function shutdown(obj,menuName)
      if nargin < 2, menuName = 'all'; end
      uis = properties(obj);
      if strcmpi(menuName,'all'), menuName = uis; end
      
      if ischar(menuName), menuName = cellstr(menuName); end
      for m = 1:numel(menuName)
        menuName{m} = validatestring(menuName{m},uis);
      end
      uis = uis(ismember(uis,menuName));
      uis(contains(uis,'Help')) = [];
      
      for p = 1:length(uis)
        if ~obj.isOpen(uis{p})
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
        obj.(uis{p}).update();
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
    
    function updateAnalysesList(obj)
      % if obj.Analyze is open, update the dropdown list.
      if obj.isOpen('Analyze')
        obj.Analyze.refresh();
      end
    end
    
  end
  
  methods (Access = private)
    % listener callback definitions
    %eg. doCallback(obj,src,evt)
    createNewAnalysis(obj,src,evt)
    
    function destroyWindow(obj,src,~)
      srcClass = class(src);
      src.isBound = false;
      try
        src.selfDestruct();
      catch x
        warning([x.message,' Deleting object...']);
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
    
    % custom notify for display change
    function displayChangedEvent(obj,src,evt)
      import iris.infra.eventData;
      
      evData = struct();
      evData.id = src;
      evData.type = evt{1};
      evData.event = evt{2};
      
      notify(obj, 'onDisplayChanged', eventData(evData)); 
    end
  end
  
end

