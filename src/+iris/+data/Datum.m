classdef Datum < matlab.mixin.Copyable
  
  properties (SetAccess = private)
    id  = '' %name
    devices
    sampleRate
    units
    protocols
    displayProperties
    stimulusConfiguration
    deviceConfiguration
    inclusion
  end
  properties
    x
    y
  end
  properties (Transient = true)
    index
  end
  properties (Dependent)
    nDevices
  end
  properties (Transient=true, Dependent=true, Hidden=true)
    plotData
    dataLength
  end
  properties (Transient=true, Hidden=true)
    displayPrefs = iris.pref.display.getDefault();
    statsPrefs = iris.pref.statistics.getDefault();
    scalePrefs = iris.pref.scales.getDefault();
    filterPrefs = iris.pref.dsp.getDefault();
    color = []
    opacity = 0.95
  end
  properties (Transient=true,Hidden=true,SetAccess=private)
    allowInteraction
  end
  
  methods
    
    function obj = Datum(dataStruct,offset)
      if nargin < 1
        obj.inclusion = 1;
        return
      end
      if nargin < 2, offset = 0; end
      validateattributes(dataStruct, {'struct'}, {'2d'});
      N = numel(dataStruct);
      %{
%       dataStruct should be a Nx1 array of structs of the form:
%       dataStruct
%         - protocols: Nx2 cell
%         - displayProperties: Nx2 cell
%         - inclusion: scalar logical (optional)
%         - responses: struct
%         -- sampleRate: cell, in Hz e.g. {10000, 10000}
%         -- duration: cell, in sec e.g. {3, 3} %unused
%         -- units: struct, array, e.g. 
%              [struct('x','sec','y','mV'),struct('x','sec','y', 'V')]
%         -- devices: cell, char, e.g. {'Axopatch 200b','Temperature Monitor'}
%         -- x: cell, vectors e.g {[3000x1 double],[3000x1 double]}
%         -- y: cell, vectors e.g {[3000x1 double],[3000x1 double]}
%         -- stimulusConfiguration: struct array
%         -- deviceConfiguration: struct array
      %}
      %make array of structs into array of obj
      obj(N,1) = iris.data.Datum();
      for ix = 1:N
        obj(ix).index = ix+offset;
        % gather input fields
        fns = fieldnames(dataStruct(ix));
        %ID
        idLoc = ismember(lower(fns), {'id', 'name'});
        idLoc = find(idLoc,1,'first');
        if ~isempty(idLoc) && ~isempty(dataStruct(ix).(fns{idLoc}))
          obj(ix).id = dataStruct(ix).(fns{idLoc});
        end
        % inclusion status
        if ismember('inclusion',fns)
          obj(ix).inclusion = dataStruct(ix).inclusion;
        else
          obj(ix).inclusion = true;
        end
        
        % data
        d = dataStruct(ix).responses;
        obj(ix).units = d.units;
        
        responseFields = fieldnames(d);
        % devices
        devLoc = contains(lower(responseFields), 'devices');
        devLoc = find(devLoc, 1, 'first');%in case of multiple matches
        if ~isempty(devLoc)
          devices = dataStruct(ix).responses.(responseFields{devLoc});
          if ~iscell(devices)
            devices = cellstr(devices);
          end
        else
          if isvector(dataStruct(ix).responses.y)
            devices = {'Device 1'};
          elseif istable(dataStruct(ix).responses.y)
            devices = dataStruct(ix).responses.y.Properties.VariableNames;
          elseif ismatrix(dataStruct(ix).responses.y)
            ndevs = size(dataStruct(ix).responses.y,2);
            devices = sprintfc('Device %d', 1:ndevs);
          end
        end
        obj(ix).devices = devices;
        obj(ix).x = d.x;
        obj(ix).y = d.y;
        obj(ix).protocols = dataStruct(ix).protocols;
        obj(ix).displayProperties = dataStruct(ix).displayProperties;
        obj(ix).stimulusConfiguration = d.stimulusConfiguration;
        obj(ix).deviceConfiguration = d.deviceConfiguration;
        try 
          obj(ix).sampleRate = d.sampleRate;
        catch
          obj(ix).sampleRate = {1};
        end
        % check if this datum is allowed to be interactive
        if isfield(dataStruct(ix),'interactive')
          obj(ix).allowInteraction = dataStruct(ix).interactive;
        else
          obj(ix).allowInteraction = true;
        end
      end
    end
    
    %%SET/GET
    function set.index(obj,value)
      obj.index = uint64(value);
      isGeneric = regexpi(obj.id, '^Ep[0-9]{1,4}');
      if ~isempty(obj.id) && ~isempty(isGeneric), return; end
      obj.id = sprintf('Ep%04d', uint64(value));
    end
    
    function setInclusion(obj,value)
      % expected to be scalar value to set only the first datum in the
      % array. If not a scalar value, then it must be as long as the whole
      % array.
      n = length(obj);
      validateattributes(value,{'logical','numeric'},{'binary'});
      if ~isscalar(value) && (length(value) ~= n)
        iris.app.Info.showWarning( ...
          sprintf( ...
            'Setting Inclusions require scalar logical or %d values.', ...
            n ...
            ) ...
          );
        return
      end
      for I = 1:length(value)
        obj(I).inclusion = value(I);
      end
    end
    
    function set.displayPrefs(obj,dp)
      obj.displayPrefs = dp;
    end
    
    function set.filterPrefs(obj,dp)
      obj.filterPrefs = dp;
    end
    
    function set.statsPrefs(obj,dp)
      obj.statsPrefs = dp;
    end
    
    function set.scalePrefs(obj,dp)
      obj.scalePrefs = dp;
    end
    
    function set.color(obj,cmat)
      validateattributes(cmat,{'double'},{'size',[NaN,3],'>=',0,'<=',1});
      ncolors = size(cmat,1);
      if ncolors < obj.nDevices
        if ncolors == 1
          cmat = iris.app.Aes.shadifyColors(cmat,obj.nDevices);
        else
          cmat(end+(1:(obj.nDevices-ncolors)),:) = cmat(end,:);
        end
      elseif ncolors > obj.nDevices
        cmat = cmat(1:obj.nDevices,:);
      end
      obj.color = cmat;
    end
    
    function set.opacity(obj,val)
      validateattributes(val,{'double'},{'>=',0,'<=',1});
      obj.opacity = val;
    end
    
    function tf = getInclusion(obj)
      tf = false(numel(obj),1);
      for o = 1:numel(obj)
        tf(o) = logical(obj(o).inclusion);
      end
    end
    
    function n = get.nDevices(obj)
      n = numel(obj.devices);
    end
    
    function n = get.dataLength(obj)
      n = max(cellfun(@numel,obj.y,'UniformOutput',true));
    end
    
    function devs = getDeviceNames(obj)
      devs = cell(length(obj),1);
      for o = 1:numel(obj)
        devs{o} = obj(o).devices;
      end
      devs = unique(cat(2,devs{:}),'stable');
    end
    
    function dat = get.plotData(obj)
      % plotData() cycles through data and creates an object for each device
      props = { ...
        obj.displayPrefs, ...
        'interactive',obj.allowInteraction, ...
        'filterPrefs',obj.filterPrefs, ...
        'statsPrefs',obj.statsPrefs, ...
        'scalePrefs',obj.scalePrefs ...
        };
      
      if ~obj.inclusion
        [props{end+(1:2)}] = deal('lineOpacity',0.5); %change the line and marker opacity values
        [props{end+(1:2)}] = deal('markerOpacity',0.5); %change the line and marker opacity values
        [props{end+(1:2)}] = deal('color',iris.app.Aes.appColor(1,'red'));
      else
        [props{end+(1:2)}] = deal('color',obj.color);
        [props{end+(1:2)}] = deal('lineOpacity',obj.opacity); %change the line and marker opacity values
        [props{end+(1:2)}] = deal('markerOpacity',obj.opacity); %change the line and marker opacity values
      end
      
      dat = iris.data.encode.plotData(obj, props{:});
    end
    
    function prev = setInteraction(obj,status)
      prev = obj.allowInteraction;
      obj.allowInteraction = status;
    end
    
    function propCell = getDisplayProps(obj,collapse,sorted)
      if nargin < 3, sorted = false; end
      if nargin < 2, collapse = true; end
      propCell = cell(length(obj),1);
      for o = 1:length(obj)
        thisProps = [ ...
          obj(o).displayProperties; ...
          { ...
            'id', obj(o).id; ...
            'index', obj(o).index; ...
          } ...
          ];
        [~,uqInds] = unique(thisProps(:,1),'stable');
        
        % store the cell with actual values
        thisProps = thisProps(uqInds,:);
        propCell{o} = thisProps;
      end
      if collapse
        propCell = utilities.collapseUnique(cat(1,propCell{:}),1,true,true);
      end
      if sorted
        [~,sIdx] = sort(lower(propCell(:,1)));
        propCell = propCell(sIdx,:);
      end
    end
    
    function propCell = getProps(obj)
      propCell = cell(numel(obj),1);
      for o = 1:length(obj)
        d = obj(o);
         % select names expected in data objects from Iris
        overviewNames = { ...
          'id';
          'devices';
          'units';
          'sampleRate';
          'inclusion';
          'index';
          'nDevices' ...
          };
        % collapse into a Nx2 cell.
        thisProps = cat(1, ...
          [ ...
            overviewNames, ...
            cellfun(@(n)d.(n),overviewNames,'unif',0), ...
          ], ...
          d.protocols, ...
          d.displayProperties ...
          );
        % determine stimulus settings
        nStimDev = numel(d.stimulusConfiguration);
        for si = 1:nStimDev
          thisStimulus = d.stimulusConfiguration(si);
          fNames = fieldnames(thisStimulus);
          sDname = thisStimulus.(fNames{contains(fNames,'Name')});
          configs = thisStimulus.(fNames{find(~contains(fNames,'Name'),1)});
          nCfg = numel(configs);
          if ~nCfg, continue; end
          
          % loop and gather configs
          % we assume that if there are configs, they will be structs with fields:
          % name, and value. otherwise this will fail.
          cfgFlat = utilities.flattenStructs(configs);
          % give the names a stimulus:stimName:name pattern:
          cfgFlat.name = matlab.lang.makeValidName( ...
            strcat( ...
              ['stimulus:',sDname,':'], ...
              cfgFlat.name ...
              ) ...
            );
          thisProps = [ ...
            thisProps; ...
            [cfgFlat.name(:),cfgFlat.value(:)] ...
            ]; %#ok<AGROW>
        end
        
        % determine device configuration settings
        nDevConfigs = numel(d.deviceConfiguration);
        for si = 1:nDevConfigs
          thisConfig = d.deviceConfiguration(si);
          if iscell(thisConfig)
            thisConfig = [thisConfig{:}];
          end
          fNames = fieldnames(thisConfig);
          sDname = thisConfig.(fNames{contains(fNames,'Name')});
          configs = thisConfig.(fNames{find(~contains(fNames,'Name'),1)});
          nCfg = numel(configs);
          if ~nCfg, continue; end
          
          % loop and gather configs
          % we assume that if there are configs, they will be structs with fields:
          % name, and value. otherwise this will fail.
          cfgFlat = utilities.flattenStructs(configs);
          % give the names a stimulus:stimName:name pattern:
          cfgFlat.name = matlab.lang.makeValidName( ...
            strcat( ...
              ['device:',sDname,':'], ...
              cfgFlat.name ...
              ) ...
            );
          thisProps = [ ...
            thisProps; ...
            [cfgFlat.name(:),cfgFlat.value(:)] ...
            ];  %#ok<AGROW>
        end
        
        
        thisProps(:,2) = arrayfun(@utilities.uniqueContents,thisProps(:,2),'unif',false);
        % Get unique fields giving priority to listed then protocols
        %[~,uqInds] = unique(thisProps(:,1),'stable');
        
        % store the cell with actual values
        %thisProps = thisProps(uqInds,:);
        propCell{o} = thisProps;
      end
      
    end
    
    function pCell = getPropsAsCell(obj)
      propC = obj.getProps();
      propC = cat(1,propC{:});
      %uniqueify
      pCell = utilities.collapseUnique(propC,1,true,true);
    end
    
    function tab = getPropTable(obj)
      % GETPROPTABLE Collect properties for all datums into a table.
      %   Each row in the output table will represent 1 datum with the
      %   variable names representing all available properties. Empty entries
      %   in the table will indicate either an empty value or an unused
      %   value. This will allow the table to hold all possible properties
      %   while keeping those datums that don't contain a particular
      %   property.
      % This should be moved to iris.data.handler class in future
      
      props = obj.getPropsAsCell(); % all possible props
      datumProps = obj.getProps(); % each datum's props
      propCells = cell(length(obj),size(props,1));
      for I = 1:length(datumProps)
        % find the intersection between the current datum's properties and
        % all properties in the data.
        currentProps = datumProps{I};
        [~,iP,iE] = intersect(props(:,1),currentProps(:,1),'stable');
        % Convert everything to char arrays to prevent differences in the
        % rows from raising errors.
        propCells(I,iP) = arrayfun( ...
          @utilities.unknownCell2Str, ...
          currentProps(iE,2), ...
          'UniformOutput', false ...
          )';
        propCells(I,cellfun(@isempty,propCells(I,:),'unif',1)) = {''};
      end
      tab = cell2table(propCells, 'VariableNames', props(:,1)');
    end
    
    function lengths = getDataLengths(obj,device)
      lengths = cell(length(obj),1);
      keeps = true(1,length(obj));
      for I = 1:length(obj)
        deviceIndex = strcmp(obj(I).devices,device);
        if ~any(deviceIndex)
          keeps(I) = false;
          continue;
        end
        % get matrix size
        lengths{I} = cellfun( ...
          @(d) size(d,1)*size(d,2), ...
          obj(I).y(deviceIndex), ...
          'UniformOutput', true ...
          );
      end
      lengths = lengths(keeps);
    end
    
    function inds = getDeviceIndex(obj,dev)
      inds = zeros(numel(obj),1);
      for o = 1:numel(obj)
        inds(o) = find(ismember(obj(o).devices,dev),1);
      end
    end
    
    function S = getDataByDeviceName(obj,deviceName)
      % preallocate maximum length
      S(length(obj),1) = struct('device', '', 'y', 0.0); 
      keepInds = true(1,length(obj));
      for I = 1:length(obj)
        deviceIndex = strcmp(obj(I).devices,deviceName);
        if ~any(deviceIndex)
          keepInds(I) = false;
          continue;
        end
        S(I).device = deviceName;
        S(I).y = obj(I).y{deviceIndex};
      end
      S = S(keepInds);
    end
    
    function cfgs = getResponseConfigs(obj,flatten)
      if nargin < 2, flatten = false; end
      %cfgs will be 1xN cell array of nx2 cells, 1 for each datum, unless 
      % flatten == true, then it will be a Nx2 cell of all configs
      %%% TODO
      % flatten response structs for each datum
      cfgs = {};
    end
    
    function cfgs = getDeviceConfigs(obj,flatten)
      if nargin < 2, flatten = false; end
      %cfgs will be 1xN cell array of nx2 cells, 1 for each datum, unless 
      % flatten == true, then it will be a Nx2 cell of all configs
      %%% TODO
      % flatten device structs for each datum
      cfgs = {};
    end
    
    function D = getDatumsAsStructs(obj)
      props = properties(obj);
      nDatums = numel(obj);
      D(nDatums,1) = struct();
      for d = 1:numel(props)
        [D(1:nDatums).(props{d})] = obj.(props{d});
        if strcmp(props{d},'x')
          for o = 1:numel(D)
            for j = 1:length(D(o).x)
              if isa(D(o).x{j}, 'function_handle')
                D(o).x{j} = D(o).x{j}();
              end
            end
          end
        end
      end
      %{
      % build a template of the correct properties
      templateStruct = struct();
      templateStruct.responses = struct();
      for p = props(:)'
        switch p{1}
          case {'protocols','displayProperties','inclusion','id','index','nDevices'}
            templateStruct.(p{1}) = obj(1).(p{1});
          case { ...
              'devices','sampleRate','stimulusConfiguration','deviceConfiguration', ...
              'units' ...
              }
            templateStruct.responses.(p{1}) = obj(1).(p{1});
          otherwise
            continue;
        end
      end
      D(length(obj),1) = templateStruct();
      for i = 1:length(obj)
        for p = props(:)'
          switch p{1}
            case {'protocols','displayProperties','inclusion','id','index','nDevices'}
              templateStruct.(p{1}) = obj(i).(p{1});
            case { ...
                'devices','sampleRate','stimulusConfiguration','deviceConfiguration', ...
                'units','x','y' ...
                }
              templateStruct.responses.(p{1}) = obj(i).(p{1});
            otherwise
              continue;
          end
        end
        D(i) = templateStruct;
      end
      %}
    end
    
    function u = getDatumUnits(obj,collapse)
      if nargin < 2, collapse = true; end
      u = cell(numel(obj),1);
      for o = 1:numel(obj)
        u{o} = [obj(o).units{:}];
      end
      u = [u{:}];
      if collapse
        u = utilities.flattenStructs(u);
        u.x = unique(u.x,'stable');
        u.y = unique(u.y,'stable');
      end
    end
    
  end
  
  methods (Access = protected)
    
    function d = copyElement(obj)
      d = copyElement@matlab.mixin.Copyable(obj);
    end
    
  end
  
  
  methods
    
    function s = saveobj(obj)
      % reconstruct data struct from obj.
      
      s(length(obj),1) = struct( ...
        'protocols', {{}}, ...
        'displayProperties', {{}}, ...
        'responses', struct() ...
        );
      for d = 1:length(obj)
        o = obj(d);
        s(d).protocols = o.protocols;
        s(d).displayProperties = o.displayProperties;
        s(d).inclusion = o.inclusion;
        s(d).id = o.id;

        r = struct();
        r.sampleRate = o.sampleRate; % cell, in Hz e.g. {10000, 10000}
        r.units = o.units;% cell, char, e.g. {'mV', 'V'}
        r.devices = o.devices;% cell, char, e.g. {'Axopatch 200b','Temperature Monitor'}
        r.x =  o.x;% cell, vectors e.g {[3000x1 double],[3000x1 double]}
        r.y = o.y;% cell, vectors e.g {[3000x1 double],[3000x1 double]}
        r.stimulusConfiguration = o.stimulusConfiguration;% struct array
        r.deviceConfiguration = o.deviceConfiguration;% struct array

        s(d).responses = r;
      end
    end
    
    function d = subsetDevice(obj,includes)
      %SUBSETDEVICE Returns a copy of the obj. Primarily we will use this for
      %plotting and for creating aggregates
      d = obj.copy();
      for i = 1:numel(d)
        keepIndex = ismember(d(i).devices,includes);
        if all(keepIndex), continue; end
        d(i).devices(~keepIndex) = [];
        d(i).sampleRate(~keepIndex) = [];
        d(i).x(~keepIndex) = [];
        d(i).y(~keepIndex) = [];
        d(i).units(~keepIndex) = [];
      end
    end
    
    function d = duplicate(obj)
      d = iris.data.Datum(obj.saveobj());
    end
    
    function [aggregates,varargout] = Aggregate(obj,varargin)
      %AGGREGATE Allows input from other methods for aggreation.
      % Typical usage will be based on iris.pref.Statistics.
      
      propTable = obj.getPropTable();
      
      p = inputParser();
      p.addParameter('groupBy', 'none', ...
        @(s) utilities.ValidStrings(s,'none',propTable.Properties.VariableNames) ...
        );
      p.addParameter('customGrouping',[], ...
        @(v) isempty(v) || (isvector(v) && numel(v) == numel(obj) && isnumeric(v)) ...
        );
      p.addParameter('statistic', 'nanmean', ...
        @(v)validateattributes(v, ...
          {'char','string','cell','function_handle'}, ...
          {'nonempty'} ...
          ) ...
        );
      p.addParameter('interactive',true, ...
        @(v)validateattributes(v,{'logical','numeric'},{'scalar','binary'}) ...
        );
      
      p.PartialMatching = true;
      p.CaseSensitive = false;
      p.KeepUnmatched = false;
      p.parse(varargin{:});
      
      % validate strings
      if isempty(p.Results.customGrouping)
        [~,groupBy] = utilities.ValidStrings( ...
          p.Results.groupBy, ...
          'none', ...
          propTable.Properties.VariableNames{:}, ...
          '-any' ...
          );
        groupBy = string(groupBy);
        if any(strcmpi(groupBy,"none"))
          propTable.none = num2str(ones(height(propTable),1));
        end
      else
        groupBy = "customGrouping";
        propTable.customGrouping = num2str(p.Results.customGrouping);
      end
      % get inclusion list
      inclusions = obj.getInclusion();
      
      % determine groups
      grpTable = propTable(:,groupBy);
      groups = utilities.determineGroups(grpTable,inclusions);
      nGroups = height(groups.Table);
      
      
      % copy the data
      data = obj.duplicate();
      data = data(inclusions);
      datStructs = data.saveobj();
      nData = sum(inclusions);
      
      % get devices
      devs = data.getDeviceNames();
      
      % count number of requested devices
      nDevOut = length(devs);
      
      % init output
      mat = struct( ...
        'devices', {cell(1,nDevOut)}, ...
        'groupsWithDevice',{cell(1,nDevOut)}, ...
        'x', {cell(1,nDevOut)}, ...
        'y', {cell(1,nDevOut)} ...
        );
      
      % Gather data by device
      for d = 1:nDevOut
        thisDevice = devs{d};
        
        % locate the location of the device in each datum
        deviceIndex = data.getDeviceIndex(thisDevice);
        
        % preallocate maximum sized vector for this device.
        dataLengths = [data.dataLength];
        [maxLen,maxIdx] = max(dataLengths);
        [xvals,yvals] = deal(nan(maxLen,nData));
        
        % gather data
        for i = 1:length(deviceIndex)
          if ~deviceIndex(i),continue;end
          % collect X and test for function handle
          thisX = data(i).x{deviceIndex(i)};
          if isa(thisX,'function_handle')
            thisX = thisX();
          end
          % collect Y
          thisY = data(i).y{deviceIndex(i)};
          
          xvals(1:dataLengths(i),i) = thisX(:);
          yvals(1:dataLengths(i),i) = thisY(:);
        end
        
        %%% compute groups statistics
        % grpstats fails if any group has only 1 entry for some reason. So we need to
        % first extract entries whose group count is 1 and then reinsert them into
        % the grpstats matrix afterwards.
        
        % grouping vector
        %groupVectors = groups.Vectors;
        singularGrps = groups.Singular;
        
        % subset data that has only 1 occurence
        singleGroups = groups.Table.SingularMap(groups.Table.Counts == 1);
        hasSingles = ~isempty(singleGroups);
        if hasSingles
          singleGrpInds = ismember(groups.Singular, singleGroups);
          ySingles = yvals(:,singleGrpInds);
          yvals(:,singleGrpInds) = [];
          %groupVectors = cellfun(@(x)x(~singleGrpInds), groupVectors, 'unif',0);
          singularGrps = groups.Singular(~singleGrpInds);
        end
        
        % send to grpstats
        %yStats = grpstats(yvals',groupVectors,p.Results.statistic)';
        statGrpNums = unique(singularGrps);
        nStatGrps = length(statGrpNums);
        yStats = nan(size(yvals,1),nStatGrps);
        switch class(p.Results.statistic)
          case {'char','string'}
            fx = str2func(p.Results.statistic);
          case 'function_handle'
            fx = p.Results.statistic;
        end
        for g = 1:nStatGrps
          thisGrpNum = statGrpNums(g);
          thisIndex = singularGrps == thisGrpNum;
          yStats(:,g) = fx(yvals(:,thisIndex)')';
        end
        
        
        % reinsert the singles if needed
        if hasSingles
          yStatsCopy = yStats;
          yStats = nan(size(yStatsCopy,1),nGroups);
          singlesInsertionInds = ismember(groups.Table.SingularMap,singleGroups);
          yStats(:,~singlesInsertionInds) = yStatsCopy;
          yStats(:,singlesInsertionInds) = ySingles;
        end
        
        % Create X matrix from the longest datum
        xStats = repmat(xvals(:,maxIdx),1,nGroups);
        % create a variable that contains the lengths of each grouped data
        groupedDataLengths = zeros(1,nGroups);
        for i = 1:nGroups
          g = groups.Table.SingularMap(i);
          gInds = groups.Singular == g;
          groupedDataLengths(i) = min(dataLengths(gInds),[],'omitnan');
        end
        % store
        mat.devices{d} = devs{d};
        mat.x{d} = xStats;
        mat.y{d} = yStats;
        mat.groupsWithDevice{d} = unique(groups.Singular(deviceIndex > 0));
      end
      
      % Need to expand matrices to individual data entries and merge grouped
      % parameters from original data
      
      aggs(1:nGroups,1) = datStructs(1); % copy structure layout
      for g = 1:nGroups
        thisGroupNum = groups.Table.SingularMap(g);
        thisGroupLog = groups.Singular == thisGroupNum;
        
        % override x and y to make flattening easy;
        for gi = 1:numel(datStructs)
          datStructs(gi).responses.x = cell(1,nDevOut);
          datStructs(gi).responses.y = cell(1,nDevOut);
        end
        
        thisGroupedInfo = utilities.flattenStructs(datStructs(thisGroupLog));
        
        % reduce certain fields to unique values
        if iscell(thisGroupedInfo.id)
          thisGroupedInfo.id = strjoin(thisGroupedInfo.id, ',');
        end
        thisGroupedInfo.id = ['(',thisGroupedInfo.id,')'];
        
        thisGroupedInfo.responses = utilities.uniqueContents( ...
          thisGroupedInfo.responses ...
          );
        
        % append x and y
        for d = 1:nDevOut
          if ismember(g,mat.groupsWithDevice{d})
            thisDevIdx = find(strcmpi(thisGroupedInfo.responses.devices,mat.devices{d}));
            % store the computed index
            thisGroupedInfo.responses.x{thisDevIdx} = mat.x{d}(1:groupedDataLengths(g),g);
            thisGroupedInfo.responses.y{thisDevIdx} = mat.y{d}(1:groupedDataLengths(g),g);
          end
        end
        
        thisGroupedInfo.inclusion = 1;
        
        % merge protocols
        mergedProts = ...
          utilities.collapseUnique( ...
            cat(1,thisGroupedInfo.protocols{:}), ...
            1, ...
            false, ...
            true ...
          );
        mergedProts(:,2) = cellfun( ...
          @utilities.uniqueContents, ...
          mergedProts(:,2), ...
          'UniformOutput', false ...
          );
        thisGroupedInfo.protocols = mergedProts;
        % Merge displayProperties
        mergedDP = ...
          utilities.collapseUnique( ...
            cat(1,thisGroupedInfo.displayProperties{:}), ...
            1, ...
            false, ...
            true ...
          );
        mergedDP(:,2) = cellfun( ...
          @utilities.uniqueContents, ...
          mergedDP(:,2), ...
          'UniformOutput', false ...
          );
        thisGroupedInfo.displayProperties = mergedDP;
        aggs(g) = thisGroupedInfo;
      end
      % create a new datum vector for output
      [aggs.interactive] = deal(p.Results.interactive);
      aggregates = iris.data.Datum(aggs,0);
      varargout{1}= utilities.determineGroups(propTable(:,groupBy));
      varargout{2} = groups; % subs groups
    end
    
  end
  
  methods (Static)
    
    function obj = loadobj(s)
      if isstruct(s)
        obj = iris.data.Datum(s);
      else
        obj = s;
      end
    end
    
  end
end

