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
    Analysis iris.ui.analysis
    NewAnalysis iris.ui.newAnalysis
    Preferences iris.ui.preferences
    FileInfo iris.ui.fileInfo
    DataOverview iris.ui.dataOverview
    Notes iris.ui.notes
    Protocols iris.ui.protocols
    About iris.ui.about
    Help %empty
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

    function tf = isOpen(obj, menuName)
      props = metaclass(obj);
      props = props.PropertyList;
      props = string({props.Name}');
      mName = validatestring(menuName, props);
      tf = ~isempty(obj.(mName)) && ~obj.(mName).isClosed;
    end

    function openList = getOpenMenus(obj)
      openList = string.empty(1,0);
      props = metaclass(obj);
      props = props.PropertyList;
      props = string({props.Name}');

      for p = props(:)
        if ~obj.isOpen(p{1}), continue; end
        openList(1, end + 1) = p; %#ok<AGROW>
      end

    end
    
    function props = getProps(obj)
      props = metaclass(obj);
      propsList = props.PropertyList;
      props = string({props.Name}');
    end

    function tf = isVisible(obj, menuNames)
      props = metaclass(obj);
      props = props.PropertyList;
      props = string({props.Name}');

      if nargin < 2
        menuNames = 'all';
      end

      if ~iscellstr(menuNames)
        menuNames = cellstr(menuNames);
      end

      if any(strcmp(menuNames, 'all'))
        menuNames = props;
      else
        menuNames = cellfun( ...
          @(s)validatestring(s, props), ...
          menuNames, ...
          'UniformOutput', false ...
        );
      end

      % get the isVisible return from each menu
      tf = zeros(length(menuNames), 1);

      for I = 1:length(menuNames)
        tf(I) = obj.isOpen(menuNames{I}) && obj.(menuNames{I}).isVisible;
      end

    end

    function pref = getPref(obj, prefName)
      pref = obj.Preferences.getPreference(prefName);
    end

    function setPref(obj, prefName, pref)
      obj.Preferences.setPreference(prefName, pref);
    end

    function setGroups(obj, groupings)
      stats = obj.getPref('statistics');
      hPref = obj.Preferences.GroupBySelect;
      % Get the previous set selection (either here or by user interaction)
      selection = stats.GroupBy;
      % Collect the grouping fields
      groupField = ["None"; sort(string(groupings(:)))]';
      % If there is any update, update the groupby list
      if ~isequal(groupField, string(hPref.Items))
        hPref.Items = groupField;
      end

      % Make sure our selection contains members of groupField
      selectionKeepers = ismember(selection, groupField);

      if ~any(selectionKeepers)
        selection = groupField{1};
      else
        selection = selection(selectionKeepers);
      end

      % update the selection if we need to
      obj.setGroupBy(selection);
    end

    function groupings = getGroups(obj)
      hPref = obj.Preferences.GroupBySelect;
      groupings = hPref.Items;
    end

    function setGroupBy(obj, selection)
      stats = obj.getPref('statistics');
      hPref = obj.Preferences.GroupBySelect;

      if ~isequal(hPref.Value, selection)
        hPref.Value = selection;
        stats.GroupBy = selection;
        % for now, we'll update the group fields just in case we want them elsewhere.
        stats.GroupFields = groupField;
        obj.setPref('statistics', stats);
      end

    end

    function groupby = getGroupBy(obj)
      hPref = obj.Preferences.GroupBySelect;
      groupby = hPref.Value;
    end

    function bind(obj, menuName)
      import iris.infra.eventData;
      props = metaclass(obj);
      props = props.PropertyList;
      props = string({props.Name}');

      if nargin < 2, error('Provide valid menu name.'); end
      menuName = validatestring(lower(menuName), props);
      if obj.(menuName).isBound, return; end

      switch menuName
        case 'Analysis'
          az = obj.Analysis;
          obj.addListener(az, 'Close', @obj.destroyWindow);
          obj.addListener(az, 'createNewAnalysis', @(s, e)obj.build('NewAnalysis'));
        case 'NewAnalysis'
          na = obj.NewAnalysis;
          obj.addListener(na, 'Close', @obj.destroyWindow);
          obj.addListener(na, 'createFunction', @obj.createNewAnalysis);
        case 'Preferences'
          pr = obj.Preferences;
          obj.addListener(pr, 'Close', @obj.destroyWindow);
          obj.addListener(pr, 'NewReaderCreated', ...
            @(s, e)notify(obj, 'onReaderAdded', eventData(e.Data)) ...
          );
          obj.addListener(pr, 'DisplayChanged', ...
            @(s, e) obj.displayChangedEvent('Display', e.Data) ...
          );
          obj.addListener(pr, 'StatisticsChanged', ...
            @(s, e) obj.displayChangedEvent('Statistics', e.Data) ...
          );
          obj.addListener(pr, 'FilterChanged', ...
            @(s, e) obj.displayChangedEvent('Filter', e.Data) ...
          );
          obj.addListener(pr, 'ScalingChanged', ...
            @(s, e) obj.displayChangedEvent('Scaling', e.Data) ...
          );

        case 'FileInfo'
          fi = obj.FileInfo;
          obj.addListener(fi, 'Close', @obj.destroyWindow);
        case 'DataOverview'
          ov = obj.DataOverview;
          obj.addListener(ov, 'Close', @obj.destroyWindow);
        case 'Notes'
          nt = obj.Notes;
          obj.addListener(nt, 'Close', @obj.destroyWindow);
        case 'Protocols'
          ps = obj.Protocols;
          obj.addListener(ps, 'Close', @obj.destroyWindow);
        case 'About'
          ab = obj.About;
          obj.addListener(ab, 'Close', @obj.destroyWindow);
        case 'Help'
          return
      end

      obj.(menuName).isBound = true;
    end

    function l = dispLis(obj)
      l = cellfun(@(l)l.EventName, obj.listeners, 'unif', 0);
    end

    function l = addListener(obj, varargin)
      l = addlistener(varargin{:});
      obj.listeners{end + 1} = l;
    end

    function removeListener(obj, listener)
      loc = ismember( ...
        cellfun(@(l)l.EventName, obj.listeners, 'unif', 0), ...
        listener.EventName);
      if ~any(loc), disp('Listener non-existent'); end
      delete(listener);
      obj.listeners(loc) = [];
    end

    function build(obj, menuName, varargin)
      props = metaclass(obj);
      props = props.PropertyList;
      props = string({props.Name}');
      if nargin < 2, error('Provide valid menu name.'); end
      menuName = validatestring(lower(menuName), props);

      % TODO: move isClosed check to use the rebuild method
      % Once rebuild() is implemented on all objects
      switch menuName
        case 'Analysis'

          if isempty(obj.Analysis) || ~obj.isOpen('Analysis')
            obj.Analysis = iris.ui.analysis(varargin{:}); % new release
          else
            obj.Analysis.buildUI(varargin{:});
          end

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
              ['Protocols  requires a Nx2 cell of experiment', ...
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

    function shutdown(obj, menuName)
      if nargin < 2, menuName = 'all'; end
      props = metaclass(obj);
      props = props.PropertyList;
      uis = string({props.Name}');
      propIdx = ~ismember({props.SetAccess},'public');
      uis(propIdx) = []; % drop non-public property names
      if strcmpi(menuName, 'all'), menuName = uis; end

      menuName = string(menuName);

      for m = 1:numel(menuName)
        menuName(m) = validatestring(menuName(m), uis);
      end

      uis = uis(ismember(uis, menuName));
      uis(contains(uis, 'Help')) = [];

      for p = 1:length(uis)

        if ~obj.isOpen(uis{p})
          continue;
        end

        obj.(uis{p}).shutdown();
      end

    end

    function savePrefs(obj, menuName)
      if nargin < 2, menuName = ''; end
      props = metaclass(obj);
      props = props.PropertyList;
      uis = string({props.Name}');

      if ~isempty(menuName)
        menuName = validatestring(menuName, uis);
        uis = uis(ismember(uis, menuName));
      end

      for p = 1:length(uis)

        if isempty(obj.(uis{p})) || obj.(uis{p}).isClosed()
          continue;
        end

        obj.(uis{p}).save();
        obj.(uis{p}).update();
      end

    end

    function resetPrefs(obj, menuName)
      if nargin < 2, menuName = ''; end
      props = metaclass(obj);
      props = props.PropertyList;
      uis = string({props.Name}');

      if ~isempty(menuName)
        menuName = validatestring(menuName, uis);
        uis = uis(ismember(uis, menuName));
      end

      for p = 1:length(uis)

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
      loc = ismember( ...
        cellfun(@(l)l.EventName, obj.listeners, 'unif', 0), ...
        listener.EventName);
      if ~any(loc), disp('Listener non-existent'); end
      obj.listeners{loc}.Enabled = true;
    end

    function disableListener(obj, listener)
      loc = ismember( ...
        cellfun(@(l)l.EventName, obj.listeners, 'unif', 0), ...
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
      % if obj.Analysis is open, update the dropdown list.
      if obj.isOpen('Analysis')
        obj.Analysis.refresh();
      end

    end

  end

  methods (Access = private)
    % listener callback definitions
    %eg. doCallback(obj,src,evt)
    createNewAnalysis(obj, src, evt)

    function destroyWindow(obj, src, ~)
      srcClass = class(src);
      src.isBound = false;

      try
        src.selfDestruct();
      catch x
        warning([x.message, ' Deleting object...']);
        delete(src);
      end

      obj.cleanListeners(srcClass);
    end

    % clear up listneers
    function cleanListeners(obj, varargin)

      if ~isempty(varargin)
        % varargin{1}: class name
        % varargin{2}: event names for class
        % gather listeners associated with provided class
        listenerInds = cellfun( ...
        @(l) ...
          strcmpi(class(l.Source{1}), varargin{1}), ...
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
          eventMatches = ismember(listenerEvents, eventsToDelete);

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

      emptyInds = cellfun( ...
        @(l)isempty(l) || ~l.isvalid, obj.listeners, ...
        'UniformOutput', true ...
      );

      if any(emptyInds)
        obj.listeners(emptyInds) = [];
        return;
      end

    end

    % custom notify for display change
    function displayChangedEvent(obj, src, evt)
      import iris.infra.eventData;

      evData = struct();
      evData.id = src;
      evData.type = evt{1};
      evData.event = evt{2};

      notify(obj, 'onDisplayChanged', eventData(evData));
    end

  end

end
