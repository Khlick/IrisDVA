classdef IrisData
  %IRISDATA Data class for Iris DVA export.
  %   IrisData is a data class object which should not undergo any modification.
  %   See description of properties and methods for help working with this data
  %   class.

  properties (SetAccess=private)

    % Meta- A `struct` object, holds the metainformation about the files from
    % which the data were extracted.
    Meta

    % Notes- An Nx2 cell array of the pattern {timestamp,note}.
    %   The property will have all supplied notes concatenated from 1xA cell array
    %   input. Thus the input 'Notes' paramter in the object constructor should be
    %     `{ {file 1: Nx2 cell}, {file A: Nx2 cell} }`.
    Notes

    % Data- A struct array contianing the collected data.
    Data

    % Files- A string vector containing the names of the most recent files
    % associated with the contained data.
    Files

    % Membership- A map containing the file name and associated data and notes
    % indices.
    Membership

    % UserData- A struct containing any extra parameters supplied at construction.
    % This will always contain a map of the original file indices.
    UserData

    % IndexMap- A map object with keys which correspond to original index numbers.
    IndexMap

    % DeviceMap- A map object with keys which correspond to available devices.
    %   Values returned correspond to indices of each datum where the device is found.
    %   If the device is not found on a particular datum, the index returned is -1.
    %   The returned vector has length of obj.nDatums.
    %   Usage: indices = IrisData.DeviceMap('Axopatch200B');
    DeviceMap

    % FileHistory- A string array of file names associated with this data file.
    FileHistory
  end

  properties (Dependent = true)
    % Specs- A struct hold table and datum properties. Used in groupBy commands.
    Specs
    % nDatums- The number of available data.
    nDatums
    % MaxDeviceCount- The maximum counted devices for all data.
    MaxDeviceCount
    % InclusionList- The list of inclusions as set during object construction.
    InclusionList
    % AvailableDevices- A list of the available devices from all data.
    AvailableDevices
  end

  properties (Constant,Hidden = true)
    BASELINE_TYPES = {'Start','End','None','Asym','Sym','Beginning'}
  end

  methods

    function obj = IrisData(varargin)
      %IRISDATA Construct instance of Iris DVA data class.
      %   IrisData expects either a struct with fields, or name value pairs for,
      %   at least the following arguments. Any unmatched fields, or name value
      %   pairs, will be stored in the IrisData object's UserData property.
      %
      %  @param Data: cell containing a struct array as specified by Iris
      %  readers (see <a
      %  href="matlab:iris.app.Aes.printStrLib('readerReadme')">here</a>). Note
      %  that the struct array must be a column array, thus Nx1 dimensions.
      %
      %  @param Meta: cell, Each Meta cell must contain a struct where each
      %  field represents some property of the file, e.g. the files storage
      %  location, the rig used, a description of the experiment, the
      %  acquisition software version and any device information.
      %  Each field should be a either a character array or a struct. Any field
      %  containing a struct will be parsed as a sub-node in the File Info dialog.
      %
      %  @param Notes: cell, Each Notes cell must contain a Nx2 cell array (cell
      %  string)
      %
      %  @param Files: string or cell array, Each element must contain a
      %  string/char representing a data source file (can be arbitrary) but must
      %  contain something. These elements will be mapped to the corresponding
      %  elements in the cell arrays for all the above parameters.
      %
      %  @param Membership: containers.Map object. This map object will soon
      %  become optional. Until then, the map object must contain Files elements
      %  as keys and each value must be a struct with fields, 'data', and
      %  'notes'. Each field should contain a vector of index numbers to which
      %  each datum in each Data cell corresponds.
      %
      %  @param FileHistory: optional string array. A string array of files
      %  associated with the data. This will be automatically populated when
      %  passing data from IrisData to IrisData objects.

      ip = inputParser();
      ip.KeepUnmatched = true;
      ip.addParameter('Data', {}, @(v)validateattributes(v,{'cell'},{'nonempty'}));
      ip.addParameter('Meta', {}, @(v)validateattributes(v,{'cell'},{'nonempty'}));
      ip.addParameter('Notes',{}, @(v)validateattributes(v,{'cell'},{'nonempty'}));
      ip.addParameter('Files', {}, @(v)validateattributes(v,{'cell','string'},{'nonempty'}));
      ip.addParameter('Membership', containers.Map(), @(v)isa(v, 'containers.Map'));
      ip.addParameter('FileHistory',[], @(v)isempty(v) || isstring(v));

      ip.parse(varargin{:});

      obj.Meta = ip.Results.Meta; %cell array
      obj.Files = string(ip.Results.Files(:)); %string list
      fh = arrayfun(@(f)strsplit(f,";"),obj.Files,'UniformOutput',false);
      obj.FileHistory = unique([fh{:},ip.Results.FileHistory],'stable');
      obj.Notes = cat(1,ip.Results.Notes{:}); %cell array of Nx2 cells

      % Membership Map using filenames as keys. make a copy of the input map to
      % prevent issues from passing containers.Map handles around
      obj.Membership = containers.Map( ...
        ip.Results.Membership.keys(), ...
        ip.Results.Membership.values() ...
        );
      % Data is a nFiles cell array of struct arrays
      obj.Data = cat(1,ip.Results.Data{:});
      % anything unrecognized gets stored as a struct in UserData
      obj.UserData = ip.Unmatched;

      %buld index map
      ogInds = obj.getOriginalIndex(1:obj.nDatums);
      obj.IndexMap = containers.Map((1:obj.nDatums)',ogInds(:));
      % build the indexmap. Note this could be a 1:1 map
      %{
      if iscell(ogInds) %ie one datum represents multiple ogInds
        sizes = cellfun(@numel,ogInds,'UniformOutput',true);
        %repInds = IrisData.rep((1:obj.nDatums)',1,sizes(:));
        obj.IndexMap = containers.Map((1:obj.nDatums)',ogInds);
      else
        obj.IndexMap = containers.Map((1:obj.nDatums)',ogInds);
      end
      %}

      % Build device map
      aDevs = obj.AvailableDevices;
      nDevs = length(aDevs);

      devList = obj.getDeviceList();

      devVals = cell(size(aDevs));

      for i = 1:nDevs
        inds = -ones(obj.nDatums,1);
        for d = 1:obj.nDatums
          isFound = ismember(devList(d,:), aDevs(i));
          if ~any(isFound), continue; end
          inds(d) = find(isFound,1);
        end
        devVals{i} = inds;
      end
      obj.DeviceMap = containers.Map(aDevs,devVals);
    end

    function iData = Aggregate(obj,varargin)
      % AGGREGATE   Compute statistical aggregation on data.
      %   Usage:
      %     aggs = AGGREGATE(IrisData, Name, Value); Where Name,Value pairs
      %     can be...
      %   @param 'groupBy': A valid filter name cellstr, string array, 'none',
      %     or 'all'. Using 'none' will apply 'statistic' to individual datums
      %     without aggregation. Using 'all' will aggregate all epochs into one.
      %   @param 'customGrouping': Provide a iData.nDatums length grouping
      %     vector for custom grouping.
      %   @param 'devices': A valid device name or 'all' (see property:
      %     AvailableDevices)
      %   @param 'baselineFirst': A boolean specifying if baseline subtraction should
      %   occur before any aggregation (*true) or after all aggregations (false).
      %   @param 'baselineRegion': Any one of 'None', 'Start', 'End', 'Asym', 'Sym'.
      %     Parameter values of 'Asym' or 'Sym' will fit a linear model to the
      %     @numBaselinePoints of the beginning or beginning and end, respectively.
      %   @param 'numBaselinePoints': A numeric value for the number of points to use
      %     from @baselineRegion location. Set to 0 to use maximum number of points
      %     (i.e.the whole trace).
      %   @param 'baselineOffsetPoints': A scalar int specifying how far to offset
      %     the start or end of the baseline calculation region (i.e.
      %     @baselineRegion).
      %   @param 'statistic': A scalar string or function handle to your
      %     desired aggregation function. The statistic MUST operate on columns.
      %   @param 'scaleFactor': a scalar value multiplied to all data selected
      %     for aggregate.
      %   @param 'inclusionOverride': Must be either empty array or logical vector
      %   the same length as the current data.
      %   @param 'xAggregator': aggregator function for x values.
      %   @param 'plot': boolean indicating whether there should be a plot made
      %     (true) or not (false).
      %
      % Future:
      %   Current, the aggregation algorithm first gets the data matrix and uses
      %   MATLAB's vectorization to combine columns of the matrix. That is, each
      %   group is determined and then the corresponding columns are sliced and
      %   the statistic is applied across the rows. In the future, either this
      %   method or a new method will allow the calculation to result in a any
      %   sized output from the groups. Also, being able to apply statistics
      %   across devices is desirable.

      % local constants
      validGroups = obj.getPropertyNames();

      % input parser
      p = inputParser();

      p.addParameter('groupBy', 'none', ...
        @(v)IrisData.ValidStrings(v,[{'none';'all'};validGroups(:)]) ...
        );

      p.addParameter('customGrouping', [], ...
        @(x) ...
        isempty(x) || (numel(x) == obj.nDatums) ...
        );

      p.addParameter('devices', 'all', ...
        @(v)IrisData.ValidStrings(v,['all';obj.AvailableDevices]) ...
        );

      p.addParameter('baselineFirst', true, @(v)islogical(v)&&isscalar(v));

      p.addParameter('baselineRegion', 'start', ...
        @(v)IrisData.ValidStrings(v,obj.BASELINE_TYPES) ...
        );

      p.addParameter( ...
        'baselineReference', 0, ...
        @(v) isscalar(v) && isnumeric(v) && (v >=0) ...
        );

      p.addParameter('numBaselinePoints', 1000, @isnumeric);

      p.addParameter('baselineOffsetPoints', 0, ...
        @(v)validateattributes(v,{'numeric'},{'nonnegative','scalar'}) ...
        );

      p.addParameter('statistic', @(x)mean(x,1,'omitnan'), ...
        @(v)validateattributes(v, ...
        {'char','string','function_handle','cell'}, ... %'cell'
        {'nonempty'} ...
        ) ...
        );

      p.addParameter('xAggregator', @(x)mean(x,1,'omitnan'), ...
        @(v)validateattributes(v, ...
        {'char','string','function_handle','cell'}, ... %'cell'
        {'nonempty'} ...
        ) ...
        );

      p.addParameter('scaleFactor', 1, @(x)isscalar(x) && isnumeric(x));

      p.addParameter('inclusionOverride', [], ...
        @(v)validateattributes(v,{'logical', 'numeric'},{'nonnegative'}) ...
        );

      p.addParameter('plot', false, @islogical);

      p.addParameter('noFitWarning', false, @(x)isscalar(x) && islogical(x));

      p.addParameter('truncate', false, @islogical);

      p.PartialMatching = true;
      p.CaseSensitive = false;
      p.KeepUnmatched = false;
      % Parse input parameters
      p.parse(varargin{:});

      % validate input strings
      [~,groupBy] = IrisData.ValidStrings( ...
        p.Results.groupBy, ...
        [{'none';'all'};validGroups(:)] ...
        );
      [~,baseLoc] = IrisData.ValidStrings( ...
        p.Results.baselineRegion, ...
        obj.BASELINE_TYPES ...
        );
      [~,devices] = IrisData.ValidStrings( ...
        p.Results.devices, ...
        ['all';obj.AvailableDevices] ...
        );

      % Create inclusions vector
      isOverride = ~isempty(p.Results.inclusionOverride);
      overrideLength = length(p.Results.inclusionOverride);
      if isOverride && overrideLength == obj.nDatums
        inclusions = p.Results.inclusionOverride;
      else
        inclusions = obj.InclusionList;
      end

      %Determine the grouping vector
      filterTable = obj.Specs.Table;
      isCustom = false;
      if ~isempty(p.Results.customGrouping)
        customGroup = p.Results.customGrouping;
        groupBy = {'customGrouping'};
        if istable(customGroup)
          tabNames = customGroup.Properties.VariableNames;
          for w = 1:width(customGroup)
            customGroup.(tabNames{w}) = string(customGroup.(tabNames{w}));
          end
          customTab = rowfun( ...
            @(varargin) strjoin([varargin{:}],'_'), ...
            customGroup, ...
            'InputVariables', tabNames ...
            );
          customGroup = customTab.Var1(:);%string array
        else
          customGroup = customGroup(:); %column vector
          % expect something like [1;2;3;1;2;3] numeric
          isCustom = true;
        end
        filterTable.customGrouping = customGroup;
      elseif any(strcmpi('none',groupBy))
        groupBy = {'none'};
        filterTable.none = string((1:height(filterTable))');
      elseif any(strcmpi('all',groupBy))
        groupBy = {'all'};
        filterTable.all = num2str(ones(height(filterTable),1));
      end

      % determine the grouping
      groupingTable = filterTable(:,groupBy);
      groups = IrisData.determineGroups(groupingTable,inclusions,true,isCustom);
      nGroups = height(groups.Table);

      % Copy included datums
      data = obj.copyData(inclusions);
      nData = sum(inclusions);
      subs = find(inclusions);

      baselineValues = cell(obj.nDatums,1);

      % baseline (if First)
      if p.Results.baselineFirst && ~strcmp(baseLoc,'None')
        [data,baselineValues] = IrisData.subtractBaseline( ...
          data, ...
          char(baseLoc), ...
          p.Results.numBaselinePoints, ...
          p.Results.baselineOffsetPoints, ...
          p.Results.noFitWarning, ...
          devices, ...
          p.Results.baselineReference ...
          );
      end

      %%% Compute Group Statistics

      % determine device locations within data
      if contains({'all'},devices)
        devices = obj.AvailableDevices;
      end

      % count number of requested devices
      nDevOut = length(devices);

      % Parse the aggregate function
      fx = determineStat(p.Results.statistic);
      xFx = determineStat(p.Results.xAggregator);
      nFx = numel(fx);
      multipleFx = nFx > 1;

      if multipleFx && (numel(xFx) == 1)
        xFx = IrisData.rep(xFx,nFx,1);
      elseif multipleFx && (numel(xFx) ~= nFx)
        error( ...
          ['"xAggregator" argument must be scalar or the ', ...
          'same length as "statistic" argument.'] ...
          );
      end

      % grouping vector
      groupVector = groups.Singular;
      groupMap = groups.Table.SingularMap;

      % init output
      statMap = cell(nDevOut,1);

      % Gather data by device
      for d = 1:nDevOut
        % determine the datums that have this device
        thisInds = obj.DeviceMap(devices{d});
        thisInds = thisInds(inclusions);

        % get the lengths of data
        dataLengths(1:nData,1) = struct('x',[],'y',[]);
        sampleRates = zeros(length(thisInds),1);
        for i = 1:length(thisInds)
          if thisInds(i) < 0, continue; end
          dataLengths(i).x = size(data(i).x{thisInds(i)},1);
          dataLengths(i).y = size(data(i).y{thisInds(i)},1);
          % collect sample rates for expansion to multiple statistics
          sampleRates(i) = data(i).sampleRate{thisInds(i)};
        end

        % preallocate maximum sized vector for this device.
        maxLen = max([dataLengths.y]);
        [xvals,yvals] = deal(nan(maxLen,nData));

        % gather data
        for i = 1:length(thisInds)
          % if datum has no device, thisInds(i) == -1
          if thisInds(i) < 0, continue;end
          thisX = data(i).x{thisInds(i)};
          thisY = data(i).y{thisInds(i)}.*p.Results.scaleFactor;

          xvals(1:dataLengths(i).x,i) = thisX(:);
          yvals(1:dataLengths(i).y,i) = thisY(:);
        end

        %%% compute groups statistics

        % Create cell array for each fx
        xStats = cell(nGroups,nFx);
        yAggs = cell(nGroups,nFx);

        groupedDataLengths = zeros(1,nGroups);
        for g = 1:nGroups
          thisGrpNum = groupMap(g);
          thisGrpInd = groupVector == thisGrpNum;
          thisDataSubset = yvals(:,thisGrpInd);
          thisXSub = xvals(:,thisGrpInd);
          for f = 1:nFx
            thisAgg = fx{f}(thisDataSubset')';
            yAggs{g,f} = thisAgg(:);% force column
            thisXAgg = xFx{f}(thisXSub')';
            xStats{g,f} = thisXAgg(:); %force column
          end

          % Get the minimum grouped data length from X Values if truncating
          if p.Results.truncate
            groupedDataLengths(g) = min([dataLengths(thisGrpInd).x],[],'omitnan');
          else
            groupedDataLengths(g) = max([dataLengths(thisGrpInd).x],[],'omitnan');
          end
        end
        % each aggregate should be a new device, the first stat gets the device
        % name. The rest will get Agg# appended
        yStats = arrayfun( ...
          @(CIDX) horzcat(yAggs{:,CIDX}), ...
          1:nFx, ...
          'UniformOutput', false ...
          );
        xStats = arrayfun( ...
          @(CIDX) horzcat(xStats{:,CIDX}), ...
          1:nFx, ...
          'UniformOutput', false ...
          );

        % store in map
        thisStruct = struct();
        thisStruct.devices = [ ...
          devices(d), ...
          sprintfc(sprintf('%s-Agg%%d',devices{d}),1:(nFx-1)) ...
          ];
        thisStruct.x = xStats;
        thisStruct.y = yStats;
        thisStruct.groupsWithDevice = IrisData.rep( ...
          {unique(groups.Singular(thisInds > 0))}, ...
          nFx, ...
          1, ...
          'dims', {1,[]} ...
          );
        thisStruct.groupLengths = IrisData.rep( ...
          {groupedDataLengths}, ...
          nFx, ...
          1, ...
          'dims', {1,[]} ...
          );
        thisStruct.sampleRate = IrisData.rep( ...
          {unique(sampleRates)}, ...
          nFx, ...
          1, ...
          'dims', {1,[]} ...
          );
        statMap{d} = thisStruct;
      end

      % convert the statistic map to a struct representing
      % IrisData.getDataMatrix();
      statStrc = cat(1,statMap{:});

      mat = statStrc(1);
      if numel(statStrc) > 1
        fn = fieldnames(mat);
        for fidx = 1:numel(fn)
          mat.(fn{fidx}) = [statStrc.(fn{fidx})];
        end
      end

      % update nDevOut
      nDevOut = numel(mat.devices);

      % Need to expand matrices to individual data entries and merge grouped
      % parameters from original data and then perform baseline (first == 0).
      % Finally, the data need to be structed for a new instance of IrisData.

      %%% TODO: Truncate device units if they're not included.
      %%% TODO: Allow unit changed expresssion, e.g. for stat == 'var', units
      %%% for that device shoule be converted to %s^2. If a custom function is
      %%% used, or if the user wants to force a unit change, we should allow a
      %%% unit expression, maybe something like 'unitExpression',
      %%% '.^2\lambda^{-1}' where '.' is replaced by given unit. We could also
      %%% allow complete conversion, e.g. 'R^* s^{-1}', or simply removing the
      %%% units, ''. This way, units could be written as latex or tex. Perhaps
      %%% we would need to update the plot method to search for $ inside the
      %%% unit values and set interpreter to latex accordingly.

      aggs(1:nGroups,1) = data(1); % copy structure layout
      % keep track of groups for building new maps
      oldMbr = obj.getFileFromIndex(subs);
      newMbr = cell(nGroups,2);
      for g = 1:nGroups
        thisGroupNum = groupMap(g);
        thisGroupLog = groupVector == thisGroupNum;
        thisGroupedInfo = IrisData.flattenStructs(data(thisGroupLog));
        % reduce certain fields to unique values
        if iscellstr(thisGroupedInfo.id)
          % is cell string, e.g., {'a','b'}
          thisGroupedInfo.id = strjoin(thisGroupedInfo.id{:}, ',');
        elseif iscell(thisGroupedInfo.id)
          % is cell array of strings?
          thisGroupedInfo.id = strjoin(cat(2,thisGroupedInfo.id{:}),',');
        end
        unitStructs = IrisData.uniqueContents( ...
          thisGroupedInfo.units ...
          );
        thisGroupedInfo.units = IrisData.rep( ...
          mat2cell(unitStructs,1,ones(1,numel(unitStructs))), ...
          1, nFx, ...
          'dims', {1,[]} ...
          );%#ok
        thisGroupedInfo.stimulusConfiguration = IrisData.uniqueContents( ...
          thisGroupedInfo.stimulusConfiguration ...
          );
        thisGroupedInfo.deviceConfiguration = IrisData.uniqueContents( ...
          thisGroupedInfo.deviceConfiguration ...
          );
        % append x, y and devices and sample rates
        thisGroupedInfo.devices = cell(0,nDevOut);
        thisGroupedInfo.x = cell(0,nDevOut);
        thisGroupedInfo.y = cell(0,nDevOut);
        thisGroupedInfo.sampleRate = cell(0,nDevOut);
        for d = 1:nDevOut
          if ismember(g,mat.groupsWithDevice{d})
            thisGroupedInfo.devices{end+1} = mat.devices{d};
            thisGroupedInfo.x{end+1} = ...
              mat.x{d}( ...
              1:mat.groupLengths{d}(g), ...
              g ...
              );
            thisGroupedInfo.y{end+1} = ...
              mat.y{d}( ...
              1:mat.groupLengths{d}(g), ...
              g ...
              );
            thisGroupedInfo.sampleRate{end+1} = mat.sampleRate{d};
          end
        end
        % overried a few parameters
        thisGroupedInfo.nDevices = length(thisGroupedInfo.devices);
        thisGroupedInfo.inclusion = 1;
        % Merge protocols
        mergedProts = ...
          IrisData.collapseUnique( ...
          cat(1,thisGroupedInfo.protocols{:}), ...
          1, ...
          false, ...
          false ...
          );
        mergedProts(:,2) = cellfun( ...
          @IrisData.uniqueContents, ...
          mergedProts(:,2), ...
          'UniformOutput', false ...
          );
        thisGroupedInfo.protocols = mergedProts;
        % Merge displayProperties
        mergedDP = ...
          IrisData.collapseUnique( ...
          cat(1,thisGroupedInfo.displayProperties{:}), ...
          1, ...
          false, ...
          false ...
          );
        mergedDP(:,2) = cellfun( ...
          @IrisData.uniqueContents, ...
          mergedDP(:,2), ...
          'UniformOutput', false ...
          );
        thisGroupedInfo.displayProperties = mergedDP;
        % store
        aggs(g) = thisGroupedInfo;
        newMbr{g,1} = find(thisGroupLog);
        newMbr{g,2} = oldMbr(thisGroupLog);
      end

      % baseline (if ~First)
      if ~p.Results.baselineFirst && ~strcmp(baseLoc,'None')
        % if we are  doing this after, find the merged location of the indicated
        % ref. We are assuming the reference number is with respect to the
        % output groups and not an input group if baselineFirst == false
        if ~p.Results.baselineReference
          refNum = 0;
        else
          refNum = groupVector(p.Results.baselineReference);
        end
        [aggs,baselineValues] = IrisData.subtractBaseline( ...
          aggs, ...
          char(baseLoc), ...
          p.Results.numBaselinePoints, ...
          p.Results.baselineOffsetPoints, ...
          p.Results.noFitWarning, ...
          'all', ...
          refNum ...
          );
      end

      % finally, produce a new IrisData object for the aggs variable

      % membership map files to new indices
      % notes subset only notes to used files
      mbrMap = containers.Map();
      newNotes = cell(0,2);
      newMeta = cell(0,2);

      files = unique(oldMbr);
      gInds = 1:nGroups;
      for f = 1:length(files)
        % get index info for this file
        mpS = obj.Membership(files(f));
        % update data inds
        mpS.data = gInds( ...
          cellfun( ...
          @(x) ismember(files(f),x), ...
          newMbr(:,2), ...
          'UniformOutput', true ...
          ) ...
          );
        % collect notes
        theseNotes = obj.Notes(mpS.notes,:);
        %update notes
        mpS.notes = mpS.notes + size(newNotes,1);
        % append notes
        newNotes = [newNotes;theseNotes]; %#ok<AGROW>
        % append Meta
        newMeta{end+1} = obj.subsref(substruct('.','Meta','()',files(f))); %#ok<AGROW>
        %update map.
        mbrMap(files(f)) = mpS;
      end

      % userData (add preprocessed data here)
      fn = fieldnames(obj.UserData);
      fv = struct2cell(obj.UserData);
      %check if OriginalData exists and update it or append it
      OGDataIdx = ismember(fn,'OriginalData');
      if any(OGDataIdx)
        fv{OGDataIdx} = data;
      else
        fn{end+1} = 'OriginalData';
        fv{end+1} = data;
      end
      % check if baseline value exist, then override
      bvIdx = ismember(fn,'BaselineValues');
      if any(bvIdx)
        fv{bvIdx} = baselineValues;
      else
        fn{end+1} = 'BaselineValues';
        fv{end+1} = baselineValues;
      end
      % check if grouping data exists, then override
      bvIdx = ismember(fn,'GroupingInfo');
      if any(bvIdx)
        fv{bvIdx} = groups;
      else
        fn{end+1} = 'GroupingInfo';
        fv{end+1} = groups;
      end
      % flatten userdata field
      newUD = [fn(:),fv(:)]';
      newUD = newUD(:);%single vector

      % set new indices
      for d = 1:numel(aggs)
        aggs(d).index = d;
      end
      % Create IrisData object
      iData = IrisData( ...
        'meta',   newMeta, ...
        'notes',  {newNotes}, ...
        'data',   {aggs}, ...
        'files', files, ...
        'member', mbrMap, ...
        'filehistory', obj.FileHistory, ...
        newUD{:} ...
        );

      % plot if requested
      if p.Results.plot
        plot(iData);
      end
      % helper
      function fcn = determineStat(theStat)
        switch class(theStat)
          case {'char','string'}
            % need convert builtin functions to explicit column calls
            switch lower(theStat)
              case {'max','min','nanmax','nanmin'}
                fxString = sprintf('@(x)%s(x,[],1)',lower(theStat));
              case {'std','var','nanstd','nanvar','mad','zscore'}
                fxString = sprintf('@(x)%s(x,0,1)',lower(theStat));
              case {'kurtosis','skewness'}
                fxString = sprintf('@(x)%s(x,1,1)',lower(theStat));
              otherwise
                if startsWith(lower(theStat),'@')
                  % stat is a custom stat string
                  fxString = theStat;
                else
                  a = which(theStat);
                  if ~contains(a,matlabroot)
                    % not a builtin. just copy it over
                    fxString = theStat;
                  else
                    % is another builtin type, mean, nanmean, etc.
                    [~,theStat,~] = fileparts(a);
                    fxString = sprintf('@(x)%s(x,1)',theStat);
                  end
                end
            end
            fcn = {str2func(fxString)};
          case 'function_handle'
            fcn = {theStat};
          case 'cell'
            fcn = cell(numel(theStat),1);
            for ii = 1:numel(theStat)
              fcn(ii) = determineStat(theStat{ii});
            end

        end
      end
    end

    function iData = Filter(obj,varargin)
      % FILTER   Apply a digital butterworth filter with specified inputs using a
      % bidirectional filter design with zero phase offset.
      %   Usage:
      %     flts = FILTER(IrisData, Name, Value); Where Name,Value pairs
      %     can be...
      %   @param 'type': A valid filter method of: {'lowpass','bandpass','highpass'}.
      %   @param 'frequencies': A 1 or 2 length array of frequencies (Hz) to filter at.
      %   @param 'order': The filter order, typically somewhere between 4 and 11.
      %   @param 'subs': Filter only a subset of the data, returned object will only
      %                  have indexes provided in subs.
      %   @param 'devices': Name of device to have filtering applied or 'all'. All
      %   devices will be returned in either case, only supplied devices will have
      %   their datums processed.
      %
      %   Returns: IrisData object

      % parse inputs
      p = inputParser();

      p.addParameter('type', 'lowpass',...
        @(v)IrisData.ValidStrings(v,{'lowpass','bandpass','highpass'}) ...
        );
      p.addParameter('frequencies', 50, ...
        @(f)validateattributes(f,{'double'},{'vector','>',0}) ...
        );
      p.addParameter('order', 4, ...
        @(o)validateattributes(o,{'numeric'},{'integer','scalar'}) ...
        );
      p.addParameter('subs', [], @(x) isempty(x) || isnumeric(x));

      p.addParameter('devices', 'all', ...
        @(v)IrisData.ValidStrings(v,['all';obj.AvailableDevices]) ...
        );
      p.addParameter('scaleFactor', 1, @(x)isscalar(x) && isnumeric(x));

      p.parse(varargin{:});

      % validate filter prefs
      [~,fltType] = IrisData.ValidStrings( ...
        p.Results.type, ...
        {'lowpass','bandpass','highpass'} ...
        );
      fltType = char(fltType);

      % determine the subs indexes. If subs not provided, we will filter excluded
      % datums as well as included.
      hasSubs = ~isempty(p.Results.subs);
      if hasSubs
        subs = p.Results.subs;
        inclusions = ismember(1:obj.nDatums,subs);
      else
        inclusions = true(obj.nDatums,1);
      end

      % determine device names
      [~,devices] = IrisData.ValidStrings( ...
        p.Results.devices, ...
        ['all';obj.AvailableDevices] ...
        );
      if ismember({'all'},devices)
        devices = obj.AvailableDevices;
      end

      % Collect data and apply filtering
      data = obj.copyData(inclusions);

      % apply the filter
      data = IrisData.butterFilter( ...
        data, ...
        fltType, ...
        p.Results.frequencies, ...
        p.Results.order, ...
        devices ...
        );

      % If subs given, subset obj
      if hasSubs
        newObj = obj(subs);
      else
        newObj = obj;
      end

      % create new IrisData object
      iData = newObj.UpdateData(data).AppendUserData('FilterParameters',p.Results);

    end

    function iData = Scale(obj,varargin)
      % SCALE   Apply Scaling to data
      %   Usage:
      %     iData = SCALE(IrisData, Name, Value); Where Name,Value pairs
      %     can be...
      %   @param 'type': Any one of 'multiply', 'divide', 'add' or 'subtract'.
      %   @param 'scaleFactor': Scalar or IrisData.MaxDeviceCount length of
      %   double precision scaling values. A scalar value will be applied to all
      %   devices listed in the 'devices' parameter.
      %   @param 'devices': Name of device to have filtering applied or 'all'. All
      %   devices will be returned in either case, only supplied devices will have
      %   their datums processed.
      %
      %   Note: Scaling is applied to supplied devices and devices not supplied
      %   will NOT be dropped from the returned object. Further, datum
      %   inclusion status is unaffected and scaling will be applied regardless
      %   of flag status.
      %
      %   Returns: IrisData object

      p = inputParser();

      p.addOptional('scaleFactor', 1, ...
        @(x) isnumeric(x) && (isscalar(x) || (numel(x) == obj.MaxDeviceCount)) ...
        );

      p.addParameter('type', 'multiply', ...
        @(v) ...
        IrisData.ValidStrings( ...
        lower(v), ...
        {'multiply', 'divide', 'add', 'subtract'} ...
        ) ...
        );

      p.addParameter('devices', 'all', ...
        @(v)IrisData.ValidStrings(v,['all';obj.AvailableDevices]) ...
        );

      p.parse(varargin{:});

      % parse inputs
      [~,devices] = IrisData.ValidStrings( ...
        p.Results.devices, ...
        ['all';obj.AvailableDevices] ...
        );
      [~,type] = IrisData.ValidStrings( ...
        lower(p.Results.type), ...
        {'multiply', 'divide', 'add', 'subtract'} ...
        );
      S = obj.copyData(true(obj.nDatums,1));

      S = IrisData.scaleData(S,p.Results.scaleFactor,devices,type{1});
      % create output IrisData
      iData = obj.UpdateData(S);
      iData.AppendUserData('ScaleValues',p.Results.scaleFactor);
    end

    function iData = Baseline(obj,varargin)
      % BASELINE   Apply Baseline Subtraction to data.
      %   Usage:
      %     zeroed = BASELINE(IrisData, Name, Value); Where Name,Value pairs
      %     can be...
      %   @param 'baselineRegion': Any one of 'None', 'Start', 'End', 'Asym', 'Sym'.
      %     Parameter values of 'Asym' or 'Sym' will fit a linear model to the
      %     @numBaselinePoints of the beginning or beginning and end, respectively.
      %   @param 'numBaselinePoints': A numeric value for the number of points to use
      %     from @baselineRegion location. Set to 0 to use maximum number of points
      %     (i.e.the whole trace).
      %   @param 'baselineOffsetPoints': A scalar int specifying how far to offset
      %     the start or end of the baseline calculation region (i.e.
      %     @baselineRegion).
      %   @param 'devices': Name of device to have filtering applied or 'all'. All
      %   devices will be returned in either case, only supplied devices will have
      %   their datums processed.
      %
      %   Returns: IrisData object

      p = inputParser();

      p.addParameter('baselineRegion', 'start', ...
        @(v)IrisData.ValidStrings(v,obj.BASELINE_TYPES) ...
        );

      p.addParameter('numBaselinePoints', 1000, @isnumeric);

      p.addParameter('baselineOffsetPoints', 0, ...
        @(v)validateattributes(v,{'numeric'},{'nonnegative','scalar'}) ...
        );

      p.addParameter('subs', [], @(x) isempty(x) || isnumeric(x));

      p.addParameter('noFitWarning', false, @(x)isscalar(x) && islogical(x));

      p.addParameter('devices', 'all', ...
        @(v)IrisData.ValidStrings(v,['all';obj.AvailableDevices]) ...
        );
      p.addParameter( ...
        'baselineReference', 0, ...
        @(v) isscalar(v) && isnumeric(v) && (v >=0) ...
        );

      p.parse(varargin{:});

      % validate input strings
      [~,baseLoc] = IrisData.ValidStrings( ...
        p.Results.baselineRegion, ...
        obj.BASELINE_TYPES ...
        );
      if strcmp('None',baseLoc)
        iData = obj;
        return
      end
      [~,devices] = IrisData.ValidStrings( ...
        p.Results.devices, ...
        ['all';obj.AvailableDevices] ...
        );

      % determine the subs indexes. If subs not provided, we will filter excluded
      % datums as well as included.
      hasSubs = ~isempty(p.Results.subs);
      if hasSubs
        subs = p.Results.subs;
        inclusions = ismember(1:obj.nDatums,subs);
      else
        inclusions = true(obj.nDatums,1);
      end

      % Collect data and apply filtering
      data = obj.copyData(inclusions);

      % apply the subtraction
      [data,baselineValues] = IrisData.subtractBaseline( ...
        data, ...
        char(baseLoc), ...
        p.Results.numBaselinePoints, ...
        p.Results.baselineOffsetPoints, ...
        p.Results.noFitWarning, ...
        devices, ...
        p.Results.baselineReference ...
        );

      % If subs given, subset obj
      if hasSubs
        newObj = obj(subs);
        baselineValues = baselineValues(subs);
      else
        newObj = obj;
      end

      % create new IrisData object
      iData = newObj.UpdateData(data);
      iData = iData.AppendUserData('BaselineValues',baselineValues);
    end

    function iData = Reorder(obj,newOrder)
      % REORDER Reorder data entries, excluded numbers will be dropped (not implemented)
      error("Not yet implemented");
    end

    function iData = UpdateData(obj,S)
      % UPDATEDATA Designed for use following edits to IrisData.copyData();

      % validate input Struct
      assert(isstruct(S),numel(S) == obj.nDatums);

      % get the saveObject
      sObj = obj.saveobj();

      % map input data to saveobj Data field
      nFiles = length(sObj.Files);
      for F = 1:nFiles
        fname = sObj.Files(F);
        dataIdx = sObj.Membership(fname).data;
        sObj.Data{F} = S(dataIdx);
      end

      % create new IrisData object
      iData = IrisData( ...
        IrisData.fastrmField(sObj,'UserData'), ...
        sObj.UserData{:} ...
        );
    end

    function iData = UpdateFileList(obj,FileList)
      % UPDATEFILELIST Updates the file list and associate index map
      % TODO: Update files in ud.oginds

      FileList = string(FileList);
      nFiles = numel(obj.Files);
      if numel(FileList) ~= nFiles
        error("FileList must contain %d files.",nFiles);
      end
      % get the saveObj
      sObj = obj.saveobj();

      % update membership map
      for f = 1:nFiles
        sObj.Membership(FileList(f)) = obj.Membership(obj.Files(f));
        remove(sObj.Membership,obj.Files(f));
      end

      % update files
      sObj.Files = FileList(:)';

      % new object
      iData = IrisData( ...
        IrisData.fastrmField(sObj,'UserData'), ...
        sObj.UserData{:} ...
        );

    end

    function iData = AppendDevices(obj,varargin)
      % APPENDDEVICES Append new data as devices to each datum.
      %   Inputs are name~value pairs or a struct with the following fields.
      %   Data (2D-cell): each cell must contain struct array of obj.nDatums
      %     with x and y fields.
      %   Name (2D-cell or 2D-string): each element must contain a "device" name
      %     corresponding to each data cell
      %   Units (2D-cell): each cell must contain struct with fields x, y with
      %     corresponding units.
      %   SampleRate (2D-cell): [OPTIONAL] each cell must contain double
      %     precision sampling rate (1/dx). If none is provided, sample rate will
      %     be calculated automatically from each Data{m}(i).x
      %   Subset (vector): an array of indices to copy. By default all indices
      %     are used, regardless of inclusion status. If Subset is used, the
      %     input Data struct arrays must have numel(Subset) length.
      %   RespectInclusion (scalara:bool): a boolean indicating whether the datum
      %     inclusion status should be respected, i.e. excluded datums should be
      %     dropped. Same stipulation as 'Subset', if datums are excluded, input
      %     'Data' struct arrays must have `sum(IrisData.InclusionList)`.
      %  ForceOverwrite (scalar:bool): A boolean indicating how to handle
      %     the preservation of an existing device.
      %
      %  * Any unmatched Name~Value pairs are appended to protocol parameters of
      %  each datum.
      p = inputParser();

      p.addParameter('Data', {struct()}, ...
        @(v) iscell(v) && all(cellfun(@isstruct,v,'unif',1)) ...
        );
      p.addParameter('Name',"", ...
        @(v) (iscell(v) && all(cellfun(@ischar,v,'unif',1))) || isstring(v) ...
        );
      p.addParameter('Units', {struct()}, ...
        @(v) iscell(v) && all(cellfun(@isstruct,v,'unif',1)) ...
        );
      p.addParameter('SampleRate',{[]},@iscell);
      p.addParameter('Subset', [], @(v)isempty(v) || isvector(v));
      p.addParameter('RespectInclusion', false, @isscalar);
      p.addParameter('ForceOverwrite', false, @isscalar);

      p.PartialMatching = true;
      p.CaseSensitive = false;
      p.KeepUnmatched = true;
      % Parse input parameters
      p.parse(varargin{:});

      % validate input lengths
      nNew = numel(p.Results.Data);
      if ~isequaln(nNew,numel(p.Results.Name),numel(p.Results.Units))
        error('Data, Name and Units input cell arrays must contain the same number of elements.');
      end

      % parse indices
      if p.Results.RespectInclusion
        inclusions = obj.InclusionList;
      else
        inclusions = true(obj.nDatums,1);
      end
      if ~isempty(p.Results.Subset)
        inclusions = ~( ...
          ~inclusions | ...
          ~ismember((1:obj.nDatums)',p.Results.Subset(:)) ...
          );
      end
      n = sum(inclusions);

      % validate units and datums structs
      isValidDataStruct = all(cellfun( ...
        @(d) all(ismember({'x','y'},fieldnames(d(1)))), ...
        p.Results.Data, ...
        'UniformOutput', true ...
        ));
      isValidDataStruct = isValidDataStruct && ...
        all(cellfun(@(v)numel(v) == n, p.Results.Data, 'unif',1));
      if ~isValidDataStruct
        error('Data structs must have "x" and "y" fields.');
      end
      isValidUnitStruct = all(cellfun( ...
        @(d) all(ismember({'x','y'},fieldnames(d(1)))), ...
        p.Results.Units, ...
        'UniformOutput', true ...
        ));
      if ~isValidUnitStruct
        error('Units structs must have "x" and "y" fields.');
      end

      % compute sampling rates
      sampleRate = p.Results.SampleRate;
      indsToCompute = cellfun(@isempty,sampleRate,'unif',1);
      for i = 1:nNew
        if ~indsToCompute(i), continue; end
        x = p.Results.Data{i}(1).x;
        sampleRate{i} = 1/mean(diff(x));
      end

      % store ForceOverwrite in a mutable variable
      ForceOverwrite = p.Results.ForceOverwrite;
      keepOriginal = false; % start false to force prompt

      % Collect any extra information
      protocolParams = IrisData.recurseStruct(p.Unmatched,false);

      % determine if we are overriding a device
      devs = obj.AvailableDevices;
      deviceExists = ismember(p.Results.Name,devs);
      if any(deviceExists) && ~ForceOverwrite
        overrideDevice = questdlg( ...
          sprintf('"%s" already exists, overwrite it?', strjoin(devs(deviceExists),' & ')), ...
          'Overwrite Device?', ...
          'Yes', 'No', 'Cancel','Yes' ...
          );

        overrideDevice = strcmpi(overrideDevice,'Yes');
      elseif ~any(deviceExists) && ~ForceOverwrite
        overrideDevice = false;
      end

      % collect data
      d = obj.copyData(inclusions);

      % loop through data structs and append new info
      for i = 1:n
        this = d(i);
        % skip if device is matched but not overrided
        thisDeviceOverwrite = ismember(this.devices,p.Results.Name);
        if any(thisDeviceOverwrite) && ~overrideDevice
          continue;
        end
        % create device index vector
        devIndex = [ ...
          find(thisDeviceOverwrite), ...
          numel(this.devices)+(1:(nNew-sum(thisDeviceOverwrite))) ...
          ];

        % append new params
        protocols = this.protocols;
        paramCopy = protocolParams;
        [~,isx,isy] = intersect(protocols(:,1),protocolParams(:,1));
        if ~isempty(isx) && ~ForceOverwrite && ~keepOriginal
          % clicking once or closeing the window will update this iteration
          % only.
          overwriteParam = questdlg( ...
            'Some properties exist. How should we handle duplicates?', ...
            'Overwrite properties?', ...
            'Update', 'Ignore', 'Once', 'Update' ...
            );
          keepOriginal = strcmp(overwriteParam,'Ignore');
          ForceOverwrite = strcmp(overwriteParam,'Update');
        end
        if keepOriginal
          % drop dups
          paramCopy(isy,:) = [];
        end
        if ForceOverwrite
          % overwrite the protocols
          protocols(isx,:) = paramCopy(isy,:);
          paramCopy(isy,:) = [];
        end
        % merge new protocols
        this.protocols = [protocols;paramCopy];

        % append new Units
        this.units(devIndex) = p.Results.Units;

        % append new Names
        this.devices(devIndex) = p.Results.Name;

        % append new sampleRate
        this.sampleRate(devIndex) = sampleRate;

        % append new Data
        this.x(devIndex) = cellfun(@(v)v(i).x,p.Results.Data,'unif',0);
        this.y(devIndex) = cellfun(@(v)v(i).y,p.Results.Data,'unif',0);

        % update device count
        this.nDevices = numel(this.devices);

        d(i) = this;
      end

      % create a new IrisData object
      iData = obj.subsref(substruct('()',{find(inclusions)}));
      iData = iData.UpdateData(d);
    end

    function iData = GetDevice(obj,deviceName)
      % GETDEVICE Returns IrisData object with data specified by deviceName.

      % validate device name
      [isDev,device] = IrisData.ValidStrings(deviceName,obj.AvailableDevices);
      if ~isDev
        error("Device '%s' not found.",deviceName);
      end

      % locate the device index to select
      devIdx = obj.DeviceMap(string(device));

      n = obj.nDatums;
      data = obj.copyData(true(n,1));

      % loop and gather the device data
      for dx = 1:n
        this = data(dx);
        this.devices = this.devices(devIdx);
        this.sampleRate = this.sampleRate(devIdx);
        this.units = this.units(devIdx);
        this.x = this.x(devIdx);
        this.y = this.y(devIdx);
        this.nDevices = numel(this.devices);
        data(dx) = this;
      end

      % build new object
      iData = obj.UpdateData(data);
    end

    function iData = RemoveDevice(obj,deviceName)
      % REMOVEDEVICE Returns IrisData object after dropping device specified.

      % validate device name
      [isDev,device] = IrisData.ValidStrings(deviceName,obj.AvailableDevices);
      if ~isDev
        error("Device '%s' not found.",deviceName);
      end

      % locate the device index to drop
      devIdx = obj.DeviceMap(string(device));

      n = obj.nDatums;
      data = obj.copyData(true(n,1));

      % loop and drop the device from each datum
      for dx = 1:n
        if devIdx(dx) < 1, continue; end
        this = data(dx);
        this.devices(devIdx(dx)) = [];
        this.sampleRate(devIdx(dx)) = [];
        this.units(devIdx(dx)) = [];
        this.x(devIdx(dx)) = [];
        this.y(devIdx(dx)) = [];
        this.nDevices = numel(this.devices);
        data(dx) = this;
      end

      % build new object
      iData = obj.UpdateData(data);
    end

    function iData = Concat(obj,varargin)
      % CONCAT Concatenate inputs onto end of calling data object. Returns new
      % object.
      % Get saveobj for each varargin.
      % Need to modify sobj.data.index:
      %   Loop through first and set index to 1:n_first
      %   track index iterator as ofst, setting index to each of subsequent datums
      %   accordingly.
      %   this will allow for saving to session to not have a ordering issue Iris
      %
      % Idea: go through and concat data first, then, 1 by 1, rebuild the membership
      % map to point to the correct values.
      % Notes need to be merged, if the input files are the same, then no need to
      % update, but if multiple files appear, Notes need to be kept separate but
      % notes Indices in the membership file need to be updated, just like datums

      %error('Concat is under development for a future release.');

      % check vargs for IrisData classes
      datArgs = cellfun(@(input)isa(input,'IrisData'),varargin,'UniformOutput',true);
      dats = varargin(datArgs);

      sObj = obj.saveobj();
      vObjs = cellfun(@(o)o.saveobj(),dats,'UniformOutput',false);

      % copy base membership container
      baseMembership = containers.Map(sObj.Membership.keys(),sObj.Membership.values());
      baseKeys = baseMembership.keys();
      baseValues = baseMembership.values();

      dOfst = obj.nDatums;
      nOfst = max(cellfun(@(m)max(m.notes),baseValues,'UniformOutput',true));
      for d = 1:numel(vObjs)
        this = vObjs{d};
        % memberships
        thisMmbr = this.Membership;
        thisKeys = thisMmbr.keys();
        for k = 1:numel(thisKeys)
          % TODO:
          % This is a mess right now. We expect that concatenating multiple
          % IrisData objects will come from different files. Though they may
          % originally come from the same source file, i.e. they have the same
          % meta information. If this is true, how should we manage the merge?
          % That is, should we simply merge by source file and keep the most
          % updated file names in the file history list? Or should we merge
          % with a pointer in the membership entry for the new files? The
          % latter will require some changes made to the subsref method to rely
          % on the membership struct to contain all the relevant indexing
          % locations.
          kthKey = string(thisKeys{k});
          % update the baseMap with the new indices
          fIdx = find(strcmp(kthKey,this.Files),1,'first');
          thisM = thisMmbr(kthKey);
          if ~isfield(thisM,"Meta")
            mIdx = fIdx;
          else
            mIdx = thisM.Meta;
          end

          % meta
          mMatch = cellfun(@(m)isequal(m,this.Meta{mIdx}),sObj.Meta,'UniformOutput',true);
          if ~any(mMatch)
            sObj.Meta{end+1} = this.Meta{mIdx};
            newMetaIdx = numel(sObj.Meta);
          else
            newMetaIdx = find(mMatch);
          end
          thisM.Meta = newMetaIdx;

          % notes
          noteMatch = cellfun(@(n)isequal(n,this.Notes{fIdx}),sObj.Notes,'UniformOutput',true);
          if ~any(mMatch)
            sObj.Notes{end+1} = this.Notes{fIdx};
            newNoteIdx = nOfst + (1:size(this.Notes{fIdx},1));
          else
            newNoteIdx = baseValues{find(noteMatch,1,'first')}.notes;
          end
          thisM.notes = newNoteIdx;

          % files
          fileMatch = sObj.Files == kthKey;
          if ~any(fileMatch)
            sObj.Files(end+1) = kthKey;
            fileIndex = numel(sObj.Files);
          else
            fileIndex = find(fileMatch,1,'first');
          end
          thisM.File = fileIndex;

          sObj.FileHistory = unique([sObj.FileHistory,this.FileHistory],'stable');

          % get new data
          thisD = this.Data{fIdx};
          if ismember(kthKey,string(baseKeys))
            % this key is also present in the growing baseKeys, so let's append
            % the data to the list and update that map
            dataLoc = ismember(sObj.Files,kthKey);
            % merge
            thisDfn = fieldnames(thisD);
            % base
            baseD = sObj.Data{dataLoc};
            baseDfn = fieldnames(baseD);
            % check names
            [extraFn,ibase,ithis] = setxor(baseDfn,thisDfn,'stable');
            if ~isempty(extraFn)
              % difference in names
              if isempty(ibase) && ~isempty(ithis)
                % only names thisD
                for ex = 1:numel(extraFn)
                  [baseD(1:numel(baseD)).(extraFn{ex})] = deal({});
                end
              elseif isempty(ithis) && ~isempty(ibase)
                % only names baseD
                for ex = 1:numel(extraFn)
                  [thisD(1:numel(thisD)).(extraFn{ex})] = deal({});
                end
              else %both have values
                % locate
                for ex = 1:numel(extraFn)
                  thisEx = extraFn{ex};
                  if ismember(thisEx,thisD)
                    % in thisD but not baseD
                    [baseD(1:numel(baseD)).(extraFn{ex})] = deal({});
                  else
                    % in baseD but not thisD
                    [thisD(1:numel(thisD)).(extraFn{ex})] = deal({});
                  end
                end
              end
            end
            % merge
            sObj.Data{dataLoc} = [baseD;thisD];
            % update data map since note map isn't altered.
            existM = baseMembership(kthKey);
            newDsubs = thisM.data - thisM.data(1) + 1 + existM.data(end);
            existM.data =  [existM.data,newDsubs];
            baseMembership(kthKey) = existM;
            % update dOfst
            dOfst = dOfst + numel(thisD);
          else
            % this key is not part of the base map, so lets append the data and
            % the membership key
            sObj.Data{end+1} = thisD;
            thisM.data = thisM.data - thisM.data(1) + 1 + dOfst;
            % update keys
            baseMembership(kthKey) = thisM;
            baseKeys{end+1} = kthKey; %#ok

            % update offsets
            dOfst = dOfst + numel(thisD);
          end

        end

        %user data
        oldUD = reshape(sObj.UserData,2,[]);
        newUD = reshape(this.UserData,2,[]);

        % give priority to newUD
        mergedUD = [newUD,oldUD];
        [~,idx,~] = unique(mergedUD(1,:),'stable');

        mergedUD = mergedUD(:,idx);
        % flatten
        sObj.UserData = mergedUD(:);
      end

      % organize the membership contianer in case ordering got off.
      dataIDs = 1:dOfst;
      for n = 1:numel(sObj.Files)
        newKey = sObj.Files(n);
        mbrS = baseMembership(newKey);

        thisDlen = numel(sObj.Data{n});
        dSubs = 1:thisDlen;

        % update the membership struct
        mbrS.data = dataIDs(dSubs);

        % drop the used indices from the the ID vectors
        dataIDs(dSubs) = [];

        % update membership struct
        if ~isfield(mbrS,"Meta")
          mbrS.Meta = n;
        end
        if ~isfield(mbrS,"File")
          mbrS.File = n;
        end

        % update base membership
        baseMembership(newKey) = mbrS;
      end

      sObj.Membership = containers.Map(baseMembership.keys(),baseMembership.values());

      % create the new iData
      iData = IrisData( ...
        IrisData.fastrmField(sObj,'UserData'), ...
        sObj.UserData{:} ...
        );
    end

    function iData = CleanInclusions(obj,inclusionOverride)
      % CleanInclusions Drop datums flagged as excluded.
      if nargin < 2
        inclusionOverride = obj.InclusionList;
      end
      assert( ...
        numel(inclusionOverride) == obj.nDatums, ...
        "Inclusion override must be %d elements in length.", ...
        obj.nDatums ...
        );
      assert( ...
        ~all(~inclusionOverride), ...
        "Cannot clear all datums." ...
        );
      if all(inclusionOverride)
        iData = obj;
        return
      end
      s = obj.saveobj();
      mbr = s.Membership;
      keys = mbr.keys();
      for d = 1:mbr.Count
        this = mbr(keys{d});
        incs = inclusionOverride(this.data);
        if ~any(~incs), continue; end
        if all(~incs)
          % drop the whole file
          s.Meta(this.Meta) = [];
          s.Data(d) = [];
          s.Notes(d) = [];
          s.Files(this.File) = [];
          remove(mbr,keys{d});
          continue
        end
        % only removing a subset of datums
        % gather the desired data
        for datidx = 1:numel(s.Data)
          dat = s.Data{datidx};
          if isequal(double([dat.index]),this.data)
            break
          end
        end
        % collect inclusions
        dat = dat(incs);
        this.data = this.data(incs);
        % reorganize indices
        s.Data{datidx} = dat;
        mbr(keys{d}) = this;
      end
      % loop through data and reorganize datum indices
      ofst = 0;
      for d = 1:mbr.Count
        dat = s.Data{d};
        n = numel(dat);

        for keyidx = 1:mbr.Count
          this = mbr(keys{keyidx});
          if isequal(double([dat.index]),this.data)
            break
          end
        end
        newI = ofst + (1:n);
        newInds = num2cell(uint64(newI));
        [dat.index] = deal(newInds{:});
        this.data = newI;
        mbr(keys{keyidx}) = this;
        ofst = ofst + n;
      end

      % create new idata object
      iData = IrisData( ...
        IrisData.fastrmField(s,'UserData'), ...
        s.UserData{:} ...
        );
    end

    function iData = AppendUserData(obj,varargin)
      if mod(numel(varargin),2)
        error('UserData must be entered in Name~Value pairs.');
      end

      sObj = obj.saveobj();

      % merge userData
      oldUD = reshape(sObj.UserData,2,[]);
      newUD = reshape(varargin,2,[]);

      % give priority to newUD
      mergedUD = [newUD,oldUD];
      [~,idx,~] = unique(mergedUD(1,:),'stable');

      mergedUD = mergedUD(:,idx);
      % flatten
      mergedUD = mergedUD(:);

      % create new IrisData object
      iData = IrisData( ...
        IrisData.fastrmField(sObj,'UserData'), ...
        mergedUD{:} ...
        );
    end

    function varargout = Split(obj,varargin)
      % SPLIT Split the data by a valid filter array, 'none' or 'devices'. See
      % obj.getPropertyNames();
      % Supplying 'none' here works differently than in Aggregate method. Here,
      % supplying 'groupBy', parameter as 'none' will split each datum into its
      % own IrisData object.

      % local constants
      validGroups = obj.getPropertyNames();

      % input parser
      p = inputParser();

      p.addOptional('groupBy', 'all', ...
        @(v)IrisData.ValidStrings(v,[{'none';'all';'devices'};validGroups(:)]) ...
        );

      p.addParameter('customGrouping', [], ...
        @(x) ...
        isempty(x) || (numel(x) == obj.nDatums) ...
        );

      p.addParameter('inclusionOverride', [], ...
        @(v)validateattributes(v,{'logical', 'numeric'},{'nonnegative'}) ...
        );

      p.PartialMatching = true;
      p.CaseSensitive = false;
      p.KeepUnmatched = false;
      % Parse input parameters
      p.parse(varargin{:});

      % validate input strings
      [~,groupBy] = IrisData.ValidStrings( ...
        p.Results.groupBy, ...
        [{'none';'all';'devices'};validGroups(:)] ...
        );

      requestedDeviceSplit = ismember(groupBy,'devices');
      if requestedDeviceSplit
        devSplit = true;
        groupBy(requestedDeviceSplit) = [];
        if isempty(groupBy)
          groupBy = {'all'};
        end
      else
        devSplit = false;
      end

      % Create inclusions vector
      isOverride = ~isempty(p.Results.inclusionOverride);
      overrideLength = length(p.Results.inclusionOverride);
      if isOverride && overrideLength == obj.nDatums
        inclusions = p.Results.inclusionOverride;
      else
        inclusions = obj.InclusionList();
      end

      %Determine the grouping vector
      filterTable = obj.Specs.Table;

      if ~isempty(p.Results.customGrouping)
        customGroup = p.Results.customGrouping;
        groupBy = {'customGrouping'};
        if istable(customGroup)
          tabNames = customGroup.Properties.VariableNames;
          for w = 1:width(customGroup)
            customGroup.(tabNames{w}) = string(customGroup.(tabNames{w}));
          end
          customTab = rowfun( ...
            @(varargin) strjoin([varargin{:}],'_'), ...
            customGroup, ...
            'InputVariables', tabNames ...
            );
          customGroup = customTab.Var1(:);%string array
        else
          customGroup = customGroup(:); %column vector
        end
        filterTable.customGrouping = customGroup;
      elseif any(strcmpi('none',groupBy))
        groupBy = {'none'};
        filterTable.none = num2str((1:height(filterTable))');
      elseif any(strcmpi('all',groupBy))
        groupBy = {'all'};
        filterTable.all = num2str(ones(height(filterTable),1));
        %{
      elseif any(strcmpi('files',groupBy))
        % append a files column to the filter table
        keys = obj.Membership.keys();
        for k = 1:obj.Membership.Count
           s = obj.Membership(keys{k});
           
        end
        %}
      end

      % determine the grouping
      groupingTable = filterTable(:,groupBy);
      % in this case, we split ignoring inclusions and then apply them after split
      groups = IrisData.determineGroups(groupingTable);
      nGroups = height(groups.Table);

      % loop over groups and collect the data using singular mapping
      dataCells = cell(nGroups,1);
      for c = 1:nGroups
        g = groups.Table.SingularMap(c);
        subsIndex = find(groups.Singular == g);
        % irisdata.subsref() to get data(inds) -> irisdata
        dataCells{c} = obj.subsref( ...
          substruct( '()', {subsIndex} ) ...
          );
        % apply inclusions changes
        dataCells{c}.InclusionList = inclusions(subsIndex);
      end

      % split each dataCell by device if requested
      if devSplit
        nd = numel(dataCells);
        nSplits = cellfun(@(x)x.MaxDeviceCount,dataCells,'UniformOutput',1);
        outputCells = cell(max(nSplits),2);
        for col = 1:nd
          this = dataCells{col};
          devs = this.AvailableDevices;
          for row = 1:nSplits(col)
            % populate rows of this column
            outputCells{row,col} = this.GetDevice(devs{row});
          end
        end
        % for device splits let's use a different output scheme
        nO = nargout;
        emptyOuts = cellfun(@isempty,outputCells,'UniformOutput',1);
        if nO == nd
          varargout = cell(1,nd);
          for o = 1:nd
            varargout{o} = outputCells(:,o);
          end
        elseif nO >= sum(~emptyOuts,'all')
          [varargout{(1:sum(~emptyOuts,'all'))',1}] = deal(outputCells{~emptyOuts});
        else
          % only output supplied inputs
          [varargout{1:nO,1}] = deal(outputCells{1:nO});
        end
        return
      end

      % determine if we are unpacking the data objects
      if nargout <= 1
        if nGroups == 1
          varargout{1} = dataCells{1};
        else
          varargout{1} = dataCells;
        end
      else
        [varargout{1:nGroups}] = deal(dataCells{:});
      end
    end

    function iData = EditDatumProperties(obj)
      % EDITDATUMPROPERTIES Use graphical interface to edit per datum properties.
      % This method works ok, but is under development. It is a mess right now and
      % needs some cleaning up.
      D = obj.copyData();
      dS = IrisData.fastrmField(obj.copyData(),{'x','y'});
      S = dS;

      IS_EDITED = false;

      % Create Figure
      %
      width = 800;
      height = 450;

      fig = uifigure('Name', 'Datum Editor', 'Visible', 'off');

      fig.Position = obj.centerFigPos(width,height);
      fig.CloseRequestFcn = @onCloseRequest;

      hTree = buildUI(fig);


      fprintf('Collecting data metadata...\n');
      pause(0.01);
      recurseDatums(dS,'Data',hTree);
      drawnow('limitrate');
      %hTree.expand();
      firstNode = struct('SelectedNodes',hTree.Children(1));
      firstNode.PreviousSelectedNodes = [];
      hTree.SelectedNodes = firstNode.SelectedNodes;
      pause(0.05);

      fig.Visible = 'on';

      getSelectedInfo(hTree,firstNode);

      uiwait(fig);

      if ~IS_EDITED
        iData = obj;
        return;
      end

      [S(1:end).x] = D.x;
      [S(1:end).y] = D.y;

      iData = obj.UpdateData(S);

      %%% Helper Functions
      function hTree = buildUI(fig)
        tGrid = uigridlayout(fig,[1,2]);
        tGrid.ColumnWidth = {'3x','5x'};
        tGrid.Padding = [10,5,10,5];

        hTree = uitree(tGrid);
        hTree.FontName = 'Times New Roman';
        hTree.FontSize = 16;
        hTree.Multiselect = 'off';
        hTree.SelectionChangedFcn = @(s,e)getSelectedInfo(hTree,e);

        pTab = uitable(tGrid);
        pTab.ColumnName = {'Property', 'Value', 'Type'};
        pTab.ColumnWidth = {150, 'auto', 40};
        pTab.RowName = {};
        pTab.CellEditCallback = @updateEditStatus;
      end

      function updateEditStatus(src,evt)
        if ~isequal(evt.NewData,evt.PreviousData)
          IS_EDITED = true;
          f = ancestor(src,'figure');
          tH = f.Children(1).Children( ...
            arrayfun(@(c)isa(c,'matlab.ui.container.Tree'), f.Children.Children) ...
            );
          nodeData = tH.SelectedNodes.NodeData;
          nodeStrings = arrayfun(@IrisData.unknownCell2Str,nodeData(:,2),'UniformOutput',false);
          tabData = src.Data;
          isChanged = ~arrayfun( ...
            @(a,b) isequal(a,b), ...
            tabData(:,2), ...
            nodeStrings, ...
            'UniformOutput', true ...
            );
          if any(isChanged)
            nodeData(isChanged,2) = IrisData.cast( ...
              src.Data(isChanged,2), ...
              src.Data(isChanged,3) ...
              );
            tH.SelectedNodes.NodeData = nodeData;
          end
        end
      end

      function getSelectedInfo(src,evt)
        f = ancestor(src,'figure');
        if ~isempty(evt.SelectedNodes)
          d = evt.SelectedNodes.NodeData;
        else
          d = {[],[],[]};
        end
        % get table handle
        tab = f.Children(1).Children( ...
          arrayfun(@(c)isa(c,'matlab.ui.control.Table'), f.Children.Children) ...
          );
        % store the table data into the previous node data.
        if ~isempty(evt.PreviousSelectedNodes)
          nodeData = evt.PreviousSelectedNodes.NodeData;
          nodeStrings = arrayfun(@IrisData.unknownCell2Str,nodeData(:,2),'UniformOutput',false);
          tabData = tab.Data;
          isChanged = ~arrayfun( ...
            @(a,b) isequal(a,b), ...
            tabData(:,2), ...
            nodeStrings, ...
            'UniformOutput', true ...
            );
          if any(isChanged)
            nodeData(isChanged,2) = IrisData.cast( ...
              tab.Data(isChanged,2), ...
              tab.Data(isChanged,3) ...
              );
            evt.PreviousSelectedNodes.NodeData = nodeData;
          end
        end


        % process data for display
        d(:,2) = arrayfun(@IrisData.unknownCell2Str,d(:,2),'UniformOutput',false);
        tab.Data = d;
        % correct column widths for data
        l = cellfun(@length,d(:,2),'UniformOutput',true);
        tw = tab.Position(3)-127;
        tab.ColumnWidth = {150, max([tw,max(l)*6.55]), 40};
        tab.ColumnEditable = [false,true,false];
        drawnow('limitrate');
      end

      % create nodes (recursive over structs)
      function recurseDatums(S, name, parentNode)
        for f = 1:length(S)
          if iscell(S)
            this = S{f};
          else
            this = S(f);
          end
          % Convert protocols and displayProperties to structs so the recurser will
          % create proper nodes
          if isfield(this,'protocols')
            this.protocols = cell2struct( ...
              this.protocols(:,2), ...
              this.protocols(:,1) ...
              );
          end
          if isfield(this,'displayProperties')
            this.displayProperties = cell2struct( ...
              this.displayProperties(:,2), ...
              this.displayProperties(:,1) ...
              );
          end
          % convert struct to property~value pairs
          props = fieldnames(this);
          vals = struct2cell(this);

          %find nests
          notNested = cellfun(@(v) ~isstruct(v),vals,'unif',1);
          if ~isfield(this,'id')
            hasName = contains(lower(props),'name');
            hasID = contains(lower(props),'id');
            if any(hasName)
              nodeName = sprintf('%s (%s)',vals{hasName},name);
            elseif any(hasID)
              nodeName = sprintf('%s (%s)',vals{hasID},name);
            else
              nodeName = sprintf('(%s) %d', name, f);
            end
          else
            nodeName = this.id;
          end
          thisNode = uitreenode(parentNode, ...
            'Text', nodeName );
          if any(notNested)
            [~,valClass] = arrayfun(@IrisData.unknownCell2Str,vals(notNested),'UniformOutput',false);
            valClass = arrayfun(@(c)IrisData.unknownCell2Str(c,' <'),valClass,'UniformOutput',false);
            thisNode.NodeData = [ ...
              props(notNested), ...
              vals(notNested), ...
              valClass ...
              ];
          else
            thisNode.NodeData = [{},{},{}];
          end
          %gen nodes
          if ~any(~notNested), continue; end
          isNested = find(~notNested);
          for n = 1:length(isNested)
            nestedVals = vals{isNested(n)};
            % if the nested values is an empty struct, don't create a node.
            areAllEmpty = all( ...
              arrayfun( ...
              @(sss)all( ...
              cellfun( ...
              @isempty, ...
              struct2cell(sss), ...
              'UniformOutput', 1 ...
              ) ...
              ), ...
              nestedVals, ...
              'UniformOutput', true ...
              ) ...
              );
            if areAllEmpty, continue; end
            recurseDatums(nestedVals,props{isNested(n)},thisNode);
          end
        end
      end
      % reconstruct dataStructs
      function S = reconstructData(fig)
        h = fig.Children(1).Children( ...
          arrayfun(@(c)isa(c,'matlab.ui.container.Tree'), fig.Children(1).Children) ...
          );


        S = cell(numel(h.Children),1);
        for c = 1:numel(h.Children)
          node = h.Children(c);
          % each child node represents a struct, except displayProperties and protocols
          % which need to be converted to Nx2 cell arrays
          cTexts = regexp({node.Children.Text},'(?<=\()[^)]*(?=\))','match','once');
          [cTexts,~,uIdx] = unique(cTexts,'stable');
          nodeData = cell(max(uIdx),2);
          nodeData(:,1) = cTexts(:);
          for n = 1:max(uIdx)
            group = node.Children(uIdx == n);
            groupData = cell(numel(group),2);
            for g = 1:numel(group)
              groupData(g,:) = recurseNode(group(g));
            end
            nodeData{n,2} = cat(2,groupData{:,2});
          end
          S{c} = cell2struct( ...
            [node.NodeData(:,2);nodeData(:,2)], ...
            [node.NodeData(:,1);nodeData(:,1)] ...
            );
        end
        S = cat(1,S{:});
      end


      function dataCell = recurseNode(Node)
        name = regexp(Node.Text,'(?<=\()[^)]*(?=\))','match','once');
        if any(strcmpi(name,{'protocols','displayProperties'}))
          % leave as a cell and expect no children
          dataCell = {name,Node.NodeData(:,1:2)};
        else
          % convert to struct
          dataCell = {name,cell2struct(Node.NodeData(:,2),Node.NodeData(:,1))};
        end
        if isempty(Node.Children), return; end
        % manage children
        childData = cell(numel(Node.Children),2);
        for g = 1:numel(Node.Children)
          childData(g,:) = recurseNode(Node.Children(g));
        end
        % flatten children with unique texts
        [newFields,~,uIdx] = unique(childData(:,1),'stable');
        for i = 1:max(uIdx)
          mergeInds = uIdx == i;
          cellsToMerge = childData(mergeInds,2);
          mergedData = cat(2,cellsToMerge{:});
          dataCell{2}.(newFields{i}) = mergedData;
        end
      end

      % save on close request
      function onCloseRequest(src,~)
        fig = ancestor(src,'figure');
        % set the current table data into the current selection in case changes were
        % made. Then reconstruct the data structs.
        if IS_EDITED
          fprintf('Collecting changes...\n');
          S = reconstructData(fig);
        end
        uiresume(fig);
        delete(fig);
      end
    end

    function obj = uiSetInclusionList(obj)
      devices = obj.AvailableDevices{1};
      [cList,nList] = deal(obj.InclusionList);
      dataTable = table( ...
        (1:obj.nDatums).', ...
        cList, ...
        nList, ...
        VariableNames=["Datum","Current","New"] ...
        );
      
      % container to build the app
      app = struct();
      ui = uifigure(Name="Inclusion Editor",Visible="on");
      p = IrisData.FigureParameters();
      set(ui,p{:});
      ui.Position = IrisData.centerFigPos(582,540);
      ui.CloseRequestFcn = @(s,e)uiresume(ancestor(s,'figure'));

      clup = onCleanup(@()delete(ui));

      % Create MainLayout
      app.MainLayout = uigridlayout(ui);
      app.MainLayout.ColumnWidth = {'1x'};%, 220};
      app.MainLayout.RowHeight = {'1x',30};
      app.MainLayout.RowSpacing = 5;
      app.MainLayout.ColumnSpacing = 5;
      app.MainLayout.Scrollable = 'on';
      app.MainLayout.BackgroundColor = [1 1 1];

      % Create DataTable
      app.DataTable = uitable(app.MainLayout);
      app.DataTable.Layout.Row = 1;
      app.DataTable.Layout.Column = 1;
      app.DataTable.Data = dataTable;
      app.DataTable.ColumnWidth = {'auto',100,100};
      app.DataTable.ColumnEditable = [false(1,2),true];
      
      % Create ButtonLayout
      app.ButtonLayout = uigridlayout(app.MainLayout);
      app.ButtonLayout.ColumnWidth = {'1x', 85, '1x'};
      app.ButtonLayout.RowHeight = {'1x'};
      app.ButtonLayout.ColumnSpacing = 0;
      app.ButtonLayout.RowSpacing = 0;
      app.ButtonLayout.Padding = [0 0 0 0];
      app.ButtonLayout.Layout.Row = 2;
      app.ButtonLayout.Layout.Column = 1;
      app.ButtonLayout.BackgroundColor = [1 1 1];

      % Create DoneButton
      app.DoneButton = uibutton(app.ButtonLayout, 'push');
      app.DoneButton.Layout.Row = 1;
      app.DoneButton.Layout.Column = 2;
      app.DoneButton.Text = "Done";
      app.DoneButton.ButtonPushedFcn = @(s,e)close(ancestor(s,'figure'));
      

      % Check if sparklines are supported
      % sparkline
      sparkpath = "";
      try %#ok<TRYNC> 
        sparkpath = fullfile(iris.app.Info.getResourcePath(),"scripts","spark.html");
      end
      if sparkpath ~= ""
        
        N = obj.nDatums;

        % adjust grids, add grid and loop through data
        app.MainLayout.ColumnWidth = {'1x', 250};
        % Create SparkLayout
        app.SparkLayout = uigridlayout(app.MainLayout);
        app.SparkLayout.ColumnWidth = {'1x',30, 190,'1x'};
        app.SparkLayout.RowHeight = [{20},repmat({34},1,N)];
        app.SparkLayout.ColumnSpacing = 0;
        app.SparkLayout.RowSpacing = 0;
        app.SparkLayout.Padding = [0 0 0 0];
        app.SparkLayout.Layout.Row = 1;
        app.SparkLayout.Layout.Column = 2;
        app.SparkLayout.Scrollable = 'on';
        app.SparkLayout.BackgroundColor = [1 1 1];
  
        % Create DataTracesLabel
        app.DataTracesLabel = uilabel(app.SparkLayout);
        app.DataTracesLabel.HorizontalAlignment = 'center';
        app.DataTracesLabel.VerticalAlignment = 'bottom';
        app.DataTracesLabel.Layout.Row = 1;
        app.DataTracesLabel.Layout.Column = [1 4];
        app.DataTracesLabel.Text = 'Data Traces';

        % collect trace data
        m = obj.Filter('freq',100).getDataMatrix('devices',devices,'respectInclusion',false);
        
        traceData(1,1:N) = struct(width=190,height=29,Values=[]);
        app.SparkLabels = gobjects(N,1);
        app.SparkLines = gobjects(N,1);
        for d = 1:N
          thisY = m.y{1}(:,d)-mean(m.y{1}(1:100,d),'omitnan');
          thisY(isnan(thisY)) = [];
          traceData(d).Values = decimate( ...
            smoothdata( ...
              thisY, ...
              'movmean', 15, ...
              'omitnan' ...
              ), ...
            200, ...
            5 ...
            );
          % draw datum index
          app.SparkLabels(d) = uilabel(app.SparkLayout);
          app.SparkLabels(d).HorizontalAlignment = 'center';
          app.SparkLabels(d).FontName = 'Courier';
          app.SparkLabels(d).FontSize = 10;
          app.SparkLabels(d).Layout.Row = d+1;
          app.SparkLabels(d).Layout.Column = 2;
          app.SparkLabels(d).Text = string(d);

          % draw the sparkline
          app.SparkLines(d) = uihtml(app.SparkLayout);
          app.SparkLines(d).Layout.Row = d+1;
          app.SparkLines(d).Layout.Column = 3;
          app.SparkLines(d).HTMLSource = sparkpath;
          app.SparkLines(d).Data = traceData(d);
        end
      end

      % wait for the figure to close
      uiwait(ui);
      
      % update inclusion list
      obj.InclusionList = app.DataTable.Data.New;      
    end

  end

  %% Access Methods

  methods

    function n = get.nDatums(obj)
      n = length(obj.Data);
    end

    function lst = get.InclusionList(obj)
      lst = false(obj.nDatums,1);
      for i = 1:obj.nDatums
        lst(i) = obj.Data(i).inclusion;
      end
    end

    function obj = set.InclusionList(obj,lst)
      if numel(lst) ~= obj.nDatums
        error('New inclusion list must be a logical vector of %d length.',obj.nDatums);
      end
      if isequal(lst,obj.InclusionList), return; end
      d = obj.copyData();
      for idx = 1:obj.nDatums
        d(idx).inclusion = lst(idx);
      end
      obj = obj.UpdateData(d);
    end

    function n = get.MaxDeviceCount(obj)
      counts = [obj.Data.nDevices];
      n = max(counts);
    end

    function lst = get.AvailableDevices(obj)
      fullList = obj.getDeviceList();
      % reshape to column vector
      fullList = fullList(:);
      % drop empty cells
      fullList(cellfun(@isempty,fullList,'UniformOutput',1)) = [];
      lst = unique(fullList,'stable');
    end

    function flt = get.Specs(obj)
      % Specs Collect protocol and display properties into table object.
      %   Specs returns a struct containing a unified table (Table) of strings where
      %   variable name correspond to all possible protoco/display properties and a
      %   cell array (Datums) containing the individual datum properties.

      % initialize containers
      propCell = cell(obj.nDatums,1);
      % initialize container to store all possible property names
      aggPropNames = {};

      %loop
      for i = 1:obj.nDatums
        % this data entry
        d = obj.Data(i);
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
          if iscell(thisStimulus),thisStimulus = [thisStimulus{:}]; end
          fNames = fieldnames(thisStimulus);
          sDname = thisStimulus.(fNames{contains(fNames,'Name')});
          configs = thisStimulus.(fNames{find(~contains(fNames,'Name'),1)});
          nCfg = numel(configs);
          if ~nCfg, continue; end

          % loop and gather configs
          % we assume that if there are configs, they will be structs with fields:
          % name, and value. otherwise this will fail.
          cfgFlat = IrisData.flattenStructs(configs);
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
          cfgFlat = IrisData.flattenStructs(configs);
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
            ]; %#ok<AGROW>
        end

        % Get unique fields giving priority to listed then protocols
        [thisNames,uqInds] = unique(thisProps(:,1),'stable');
        % update the prop names for output table
        aggPropNames = union(aggPropNames,thisNames);
        % store the cell with actual values
        thisProps = thisProps(uqInds,:);
        propCell{i} = thisProps;
      end

      % now that we have all possible prop names, let's build a table
      propsCell4Table = cell(obj.nDatums,length(aggPropNames));

      for i = 1:obj.nDatums
        thisProps = propCell{i};
        % find indices in aggnames that correspond to current props
        [~,iAggs,iProps] = intersect(aggPropNames,thisProps(:,1),'stable');
        % copy and convert to chars
        propsCell4Table(i,iAggs) = arrayfun( ...
          @(a)IrisData.unknownCell2Str(a,';',true), ...
          thisProps(iProps,2), ...
          'UniformOutput', false ...
          );
        % correct empty cells with empty strings
        propsCell4Table(i,cellfun(@isempty,propsCell4Table(i,:),'unif',1)) = {''};
      end

      flt = struct( ...
        'Table', cell2table(propsCell4Table,'VariableNames', aggPropNames'), ...
        'Datums', {propCell} ...
        );
    end

    function fn = getFileFromIndex(obj,index)
      % GETFILEFROMINDEX Locate the filename for a given index or indices vector.
      if length(index) > 1
        fArray = arrayfun(@obj.getFileFromIndex, index, 'unif', 0);
        emptySlots = cellfun(@isempty,fArray,'unif',1);
        [fArray{emptySlots}] = deal("");
        fn = [fArray{:}]';
        return
      end
      keys = obj.Membership.keys();
      vals = obj.Membership.values();
      keyIndex = false(size(keys));
      for k = 1:length(keys)
        checkValue = ismember(index,vals{k}.data);
        if checkValue
          keyIndex(k) = true;
          break;
        end
      end
      fn = string(keys(keyIndex));
    end

    function props = getPropertyNames(obj)
      %  GETPROPERTYNAMES Collect properties from data display, protocol and base
      %  information.
      d = IrisData.fastrmField(obj.copyData(),{'x','y'});
      propNames = cell(numel(d),1);
      for i = 1:numel(d)
        this = d(i);
        % extract protocol and display properties
        protocols = this.protocols;
        display = this.displayProperties;
        % stim configs
        stims = this.stimulusConfiguration;
        stimIds = cell(numel(stims),1);
        for s = 1:numel(stims)
          stim = stims(s);
          name = matlab.lang.makeValidName(sprintf("stimulus_%s_",stim.deviceName));
          cfgs = IrisData.recurseStruct(stim.configSettings);
          stimIds{s} = strcat(name,cfgs(contains(cfgs(:,1),'name'),2));
        end
        % device configs
        devs = this.deviceConfiguration;
        devIds = cell(numel(devs),1);
        for s = 1:numel(devs)
          dev = devs(s);
          name = matlab.lang.makeValidName(sprintf("device_%s_",dev.deviceName));
          cfgs = IrisData.recurseStruct(dev.configSettings);
          devIds{s} = strcat(name,cfgs(contains(cfgs(:,1),'name'),2));
        end
        % collect the overview names
        this = IrisData.fastrmField( ...
          this, ...
          { ...
          'protocols', ...
          'displayProperties', ...
          'stimulusConfiguration', ...
          'deviceConfiguration' ...
          } ...
          );
        %concat
        thisProps = [ ...
          string(fieldnames(this));
          string(protocols(:,1)); ...
          string(display(:,1)); ...
          cat(1,stimIds{:}); ...
          cat(1,devIds{:})
          ];
        % uniquefy
        propNames{i} = unique(thisProps,'stable');
      end
      props = unique(cat(1,propNames{:}));
    end

    function varargout = isProperty(obj,varargin)
      props = obj.getPropertyNames();
      inputs = cellfun(@string,varargin,'UniformOutput',false);
      inputs = cat(2,inputs{:});
      tf = false(numel(inputs),1);
      names = cell(numel(inputs),1);
      for i = 1:numel(inputs)
        [tf(i),names(i)] = IrisData.ValidStrings(inputs{i},props);
      end
      varargout{1} = tf;
      if nargout > 1
        varargout{2} = string(names);
      end
    end

    function ogIndex = getOriginalIndex(obj,index)
      % GETORIGINALINDEX Returns the original datum index given the input index or
      % indices.

      if nargin < 2, index = 1:obj.nDatums; end

      values = cell(obj.nDatums,1);
      for i = 1:obj.nDatums
        values{i} = obj.Data(i).index(:); %make columns in case multiple
      end

      % map index(i) to values(i)
      ogIndex = cell(length(index),1);
      for i = 1:length(index)
        thisIdx = IrisData.uniqueContents(values(index(i)));
        while iscell(thisIdx)
          thisIdx = [thisIdx{:}];
        end
        ogIndex{i} = thisIdx;
      end

      % if all mapped values are scalar, return a numeric vector
      if all(cellfun(@(v)numel(v)==1,ogIndex,'UniformOutput',true))
        ogIndex = cat(1,ogIndex{:});
      end
    end

    function data = copyData(obj,inclusions)
      % COPYDATA Returns the data struct array from the desired inclusions (logical).
      %   Inclusions vector must be boolean and nDatums in length. This method copies
      %   the data structure into a MATLAB struct array allowing manipulation to the
      %   data, or individual datums. This method is usually followed by the
      %   UpdateData() method to create a new IrisData instance of modified data.
      %   E.g. a user may want to modify a property of each datum in a systematic
      %   way, say correcting an errorneous input (like an ND amount) or perhaps
      %   adding a property to each datum based on a calculation.
      if nargin < 2, inclusions = true(obj.nDatums,1); end
      if length(inclusions) ~= obj.nDatums
        inclusions = obj.InclusionList;
        warning('IrisData:copyData:InclusionLengthError', ...
          'Inclusions input must be the same length as nDatums. Using defaults.' ...
          );
      end

      subs = find(inclusions);

      data = obj.Data(subs);

      % if any x or y is a function handle, evaluate it now.
      nCopies = length(data);
      for e = 1:nCopies
        nDevs = data(e).nDevices;
        for d = 1:nDevs
          if isa(data(e).x{d},'function_handle')
            data(e).x{d} = data(e).x{d}();
          end
          if isa(data(e).y{d},'function_handle')
            data(e).y{d} = data(e).y{d}();
          end
        end
      end
    end

    function lst = getDeviceList(obj)
      % GETDEVICELIST Return a cell array (nDatums x nMaxDevices) of device names.
      lst = cell(obj.nDatums,obj.MaxDeviceCount);
      for i = 1:obj.nDatums
        d = obj.Data(i).devices;
        lst(i,1:length(d)) = d;
      end
      emptys = cellfun(@isempty,lst,'UniformOutput',true);
      lst(emptys) = {''}; % make empty slots chars
    end

    function mat = getDataMatrix(obj,varargin)
      % GETDATAMATRIX Returns a struct containing X and Y data matrices.
      %   Usage:
      %     mat = GETDATAMATRIX(IrisData, Name, Value); Where Name,Value pairs
      %     can be...
      %   @param 'devices': Name of device to have filtering applied or 'all'. All
      %     devices will be returned in either case, only supplied devices will have
      %     their datums processed.
      %   @param 'subs': Filter only a subset of the data, returned object will only
      %     have indexes provided in subs.
      %   @param 'respectInclusion': Boolean to respect inclusion list, i.e.
      %     drop any datums marked as excluded from Iris. If subs vector is
      %     provided and this is true, then both lists are used.
      %
      %   Returns: Struct contianing

      deviceOpts = ['all';obj.AvailableDevices];
      p = inputParser();

      p.addParameter('devices', 'all', ...
        @(v)IrisData.ValidStrings(v,deviceOpts) ...
        );

      p.addParameter('subs', 1:obj.nDatums, ...
        @(v)validateattributes(v,{'numeric','logical'},{'nonnegative'}) ...
        );

      p.addParameter('respectInclusion', true, @islogical);

      p.parse(varargin{:});

      % validate subs
      subs = p.Results.subs;
      % test subs vector
      if any(subs > obj.nDatums)
        warning('IRISDATA:GETDATAMATRIX:SUBSERROR', ...
          'Indices outside of data range are ignored.' ...
          );
        subs(subs > obj.nDatums) = [];
      end
      % create inclusions list
      suppliedInclusions = ismember((1:obj.nDatums)',subs);
      if p.Results.respectInclusion
        % exclude if not in inclusion list or not in supplied list
        % maybe: ~any(~[obj.InclusionList,suppliedInclusions],2);?
        inclusions = ~(~obj.InclusionList | ~suppliedInclusions);
      else
        inclusions = suppliedInclusions;
      end
      % sort order for outputs
      [~,sortOrder] = sort(subs(inclusions));

      % copy requested data
      data = obj.copyData(inclusions);
      data = data(sortOrder);

      nData = sum(inclusions);

      % determine device locations within data
      [~,devices] = IrisData.ValidStrings(p.Results.devices, deviceOpts);
      if contains({'all'},devices)
        devices = obj.AvailableDevices;
      end

      % count number of requested devices
      nDevOut = length(devices);
      % init output
      mat = struct( ...
        'device', {cell(1,nDevOut)}, ...
        'units', {cell(1,nDevOut)}, ...
        'x', {cell(1,nDevOut)}, ...
        'y', {cell(1,nDevOut)} ...
        );

      % Gather data by device
      for d = 1:nDevOut
        thisInds = obj.DeviceMap(devices{d});
        thisInds = thisInds(inclusions);
        thisInds = thisInds(sortOrder);

        % get the lengths of data
        dataLengths(1:nData,1) = struct('x',[],'y',[],'units',struct());
        for i = 1:length(thisInds)
          if thisInds(i) < 0, continue; end
          xlen = numel(data(i).x{thisInds(i)});
          ylen = numel(data(i).y{thisInds(i)});
          units = data(i).units{thisInds(i)};
          dataLengths(i) = struct('x',xlen,'y',ylen,'units',units);
        end

        units = [dataLengths.units].';
        [~,idx] = unique(string({units.x}.'),'rows','stable');
        [~,idy] = unique(string({units.y}.'),'rows','stable');
        units = units(find(idx == idy,1,'first'));
        % preallocate maximum sized vector for this device.
        maxLen = max([dataLengths.x,dataLengths.y]);
        [xvals,yvals] = deal(nan(maxLen,nData));

        % gather data
        for i = 1:length(thisInds)
          if thisInds(i) < 0, continue; end
          thisX = data(i).x{thisInds(i)};
          thisY = data(i).y{thisInds(i)};

          xvals(1:dataLengths(i).x,i) = thisX(:);
          yvals(1:dataLengths(i).y,i) = thisY(:);
        end
        % store for output
        mat.device{d} = devices{d};
        mat.x{d} = xvals;
        mat.y{d} = yvals;
        mat.units{d} = units;
      end

    end

    function groups = getGroupBy(obj,varargin)
      % GETGROUPBY collects the grouping table and vectors from inputs.
      %   Supplying a vector, or vectors, of nDatum length will create a custom
      %   grouping vector. These are expected to be arrays coercable to valid
      %   strings.
      % Usage:
      %   (1) groups = Data.getGroupBy('lightAmplitude','protocolStartTime', ...);
      %   (2) groups = Data.getGroupBy(customGroupVector1, ..., customGroupVectorN)

      % local constants
      validGroups = obj.getPropertyNames();

      % validtate inputs
      if nargin < 2
        groupings = {'none'};
      else
        % flatten the input groups
        groupings = varargin;
        while any(cellfun(@iscell,groupings))
          cIn = [groupings{cellfun(@iscell,groupings)}];
          nIn = groupings(~cellfun(@iscell,groupings));
          groupings = [cIn(:);nIn(:)];
        end
      end

      % validate inputs, either scalar string
      validInputs = cellfun( ...
        @(c) ...
        ( ...
        ischar(c) || isStringScalar(c) ...
        ) || ...
        ( ...
        ~ischar(c) && (numel(c) == obj.nDatums) ...
        ), ...
        groupings, ...
        'UniformOutput', true ...
        );
      groupings(~validInputs) = [];
      if isempty(groupings), error('Invalid grouping.'); end

      % convert inputs to strings
      groupings = cellfun(@string,groupings,'UniformOutput',false);

      % Create a table from inputs
      groupTable = table();
      %ids
      groupsAsIds = cellfun(@isscalar,groupings);
      ids = groupings(groupsAsIds);
      if ~isempty(ids)
        [~,groupBy] = IrisData.ValidStrings( ...
          ids, ...
          [{'none'};validGroups(:)] ...
          );
        % valid matches will be chars
        groupBy(~cellfun(@ischar,groupBy)) = [];

        % collect the filter table
        filterTable = obj.Specs.Table;
        if any(strcmpi('none',groupBy))
          groupBy = {'none'};
          filterTable.none = num2str(ones(height(filterTable),1));
        end
        groupTable = [groupTable,filterTable(:,groupBy)];
      end

      % vectors
      vectors = groupings(~groupsAsIds);
      if ~isempty(vectors)
        groupTable = [groupTable,table(vectors{:})];
      end

      % determine groups
      groups = IrisData.determineGroups(groupTable,true(obj.nDatums,1));

    end

    function domains = getDomains(obj,devices)
      % GETDOMAINS Gets the data ranges for each provided device (optional).
      if nargin < 2, devices = 'all'; end
      [~,devices] = IrisData.ValidStrings( ...
        devices, ...
        ['all';obj.AvailableDevices] ...
        );
      mat = obj.getDataMatrix('devices', devices);
      nDevs = numel(mat.device);
      domains(1:nDevs) = struct( ...
        'id', '', ...
        'X', [0;1], ...
        'Y', [0;1] ...
        );
      for d = 1:nDevs
        domains(d).id = mat.device{d};
        domains(d).X = IrisData.domain(mat.x{d});
        domains(d).Y = IrisData.domain(mat.y{d});
      end
    end

    function propTable = view(obj, type)
      % VIEW Show a window containing 'properties', 'notes', or 'info'.
      %   propTable output will be a table object if only one of 'properties' or
      %   'notes'. If multiple cases are show, then the output will be a cell array
      %   of the corresponding tables. If 'info' is entered, the corresponding output
      %   will contain the Meta struct, the same as if IrisData.Meta was accessed.
      
      arguments
        obj IrisData        
      end
      arguments (Repeating)
        type (1,1) string {mustBeMember(type,{'properties','notes','info','data'})}
      end

      if nargin < 2
        propTable = table();
        return;
      end

      % validate input
      [s,views] = IrisData.ValidStrings(type,{'properties','notes','info','data'});

      if ~s
        fprintf( ...
          'Invalid entry, must be one of: %s\n', ...
          strjoin({'properties','notes','info','data'},', ') ...
          );
        propTable = table();
        return;
      end

      propTable = cell(numel(views),1);

      figs = gobjects(numel(views),1);
      for v = 1:numel(views)
        figs(v) = uifigure('Name', views{v}, 'Visible', 'off');% is resizable

        switch views{v}
          case 'properties'
            specs = obj.Specs;
            propCell = IrisData.collapseUnique(cat(1,specs.Datums{:}),1,true);
            labels = ["Property", "Values"];
          case 'notes'
            propCell = obj.Notes;
            labels = ["Timestamp","Notes"];
          case {'info','data'}
            isdatum = strcmpi(views{v},'data');
            % create a window with a tree navigator
            if isdatum
              dS = obj.copyData();
              dS = IrisData.fastrmField(dS,{'x','y'});
              propTable{v} = obj.Specs.Table;
            else
              dS = obj.Meta;
              propTable{v} = dS;
            end
            % Create the UI
            w = 800;
            h = 450;
            figs(v).Position = IrisData.centerFigPos(w,h);
            % make a grid
            tGrid = uigridlayout(figs(v),[1,2]);
            tGrid.ColumnWidth = {'3x','5x'};

            hTree = uitree(tGrid);
            hTree.FontName = 'Times New Roman';
            hTree.FontSize = 16;
            hTree.Multiselect = 'off';
            hTree.SelectionChangedFcn = @getSelectedInfo;

            pTab = uitable(tGrid);
            pTab.ColumnName = {'Property'; 'Value'};
            pTab.ColumnWidth = {130, 'auto'};
            pTab.RowName = {};
            pTab.CellSelectionCallback = @doCopyUITableCell;

            % Populate ui tree
            fprintf('Collecting %s metadata...\n',views{v});
            pause(0.01);
            if isdatum
              recurseDatums(dS,'Data',hTree);
            else
              recurseInfo(dS,'File',hTree);
            end

            hTree.expand();
            firstNode = struct('SelectedNodes',hTree.Children(1));
            hTree.SelectedNodes = firstNode.SelectedNodes;
            pause(0.5);

            figs(v).Visible = 'on';

            getSelectedInfo(hTree,firstNode);
            continue
        end
        % grid for automatic resize
        tGrid = uigridlayout(figs(v), [1,1]);
        % proptable
        propTable{v} = cell2table( ...
          propCell, ...
          'VariableNames', labels ...
          );
        % create the ui table
        pTab = uitable( ...
          tGrid, ...
          'ColumnName', labels ...
          );
        pTab.Data = propCell;
        pause(0.01);
        % reshape table columns according to character lengths
        lens = cellfun(@length,propCell(:,2),'UniformOutput',true);
        tWidth = pTab.Position(3)-150;
        pTab.ColumnWidth = {150, max([tWidth,max(lens)*6.56])};
        pTab.CellSelectionCallback = @doCopyUITableCell;
        figs(v).Visible = 'on';
        drawnow();
        pause(0.05);
      end

      if numel(views) == 1
        propTable = propTable{:};
      end
      %%% helpers
      function getSelectedInfo(src,evt)
        f = ancestor(src,'figure');
        if ~isempty(evt.SelectedNodes)
          d = evt.SelectedNodes.NodeData;
        else
          d = {[],[]};
        end
        % process data for display
        d(:,2) = arrayfun( ...
          @(a)IrisData.unknownCell2Str(a,';',true), ...
          d(:,2), ...
          'UniformOutput', false ...
          );
        % set into the table
        tab = f.Children(1).Children( ...
          arrayfun(@(c)isa(c,'matlab.ui.control.Table'), f.Children.Children) ...
          );
        tab.Data = d;
        % correct column widths for data
        l = cellfun(@length,d(:,2),'UniformOutput',true);
        tw = tab.Position(3)-127;
        tab.ColumnWidth = {150, max([tw,max(l)*6.55])};
        drawnow();
      end
      % info recursion
      function recurseInfo(S, name, parentNode)
        for f = 1:length(S)
          if iscell(S)
            this = S{f};
          else
            this = S(f);
          end
          props = fieldnames(this);
          vals = struct2cell(this);
          %find nests
          notNested = cellfun(@(v) ~isstruct(v),vals,'unif',1);
          if ~isfield(this,'File')
            hasName = contains(lower(props),'name');
            if any(hasName)
              nodeName = sprintf('%s (%s)',vals{hasName},name);
            else
              nodeName = sprintf('%s %d', name, f);
            end
          else
            nodeName = this.File;
          end
          thisNode = uitreenode(parentNode, ...
            'Text', nodeName );
          if any(notNested)
            thisNode.NodeData = [props(notNested),vals(notNested)];
          else
            thisNode.NodeData = [{},{}];
          end
          %gen nodes
          if ~any(~notNested), continue; end
          isNested = find(~notNested);
          for n = 1:length(isNested)
            nestedVals = vals{isNested(n)};
            % if the nested values is an empty struct, don't create a node.
            areAllEmpty = all( ...
              arrayfun( ...
              @(sss)all( ...
              cellfun( ...
              @isempty, ...
              struct2cell(sss), ...
              'UniformOutput', 1 ...
              ) ...
              ), ...
              nestedVals, ...
              'UniformOutput', true ...
              ) ...
              );
            if areAllEmpty, continue; end
            recurseInfo(nestedVals,props{isNested(n)},thisNode);
          end
        end
      end
      % datum recursion
      function recurseDatums(S, name, parentNode)
        for f = 1:length(S)
          if iscell(S)
            this = S{f};
          else
            this = S(f);
          end
          % remove protocols from the
          if isfield(this,'protocols')
            protProps = this.protocols;
            this = IrisData.fastrmField(this,"protocols");
          else
            protProps = cell(0,2);
          end
          props = [fieldnames(this);protProps(:,1)];
          vals = [struct2cell(this);protProps(:,2)];
          %find nests
          notNested = cellfun(@(v) ~isstruct(v),vals,'unif',1);
          if ~isfield(this,'id')
            hasName = contains(lower(props),'name');
            if any(hasName)
              nodeName = sprintf('%s (%s)',vals{hasName},name);
            else
              nodeName = sprintf('%s %d', name, f);
            end
          else
            nodeName = this.id;
          end
          thisNode = uitreenode(parentNode, ...
            'Text', nodeName );
          if any(notNested)
            thisNode.NodeData = [props(notNested),vals(notNested)];
          else
            thisNode.NodeData = [{},{}];
          end
          %gen nodes
          if ~any(~notNested), continue; end
          isNested = find(~notNested);
          for n = 1:length(isNested)
            nestedVals = vals{isNested(n)};
            % if the nested values is an empty struct, don't create a node.
            areAllEmpty = all( ...
              arrayfun( ...
              @(sss)all( ...
              cellfun( ...
              @isempty, ...
              struct2cell(sss), ...
              'UniformOutput', 1 ...
              ) ...
              ), ...
              nestedVals, ...
              'UniformOutput', true ...
              ) ...
              );
            if areAllEmpty, continue; end
            recurseDatums(nestedVals,props{isNested(n)},thisNode);
          end
        end
      end
      % copy cell contents callback
      function doCopyUITableCell(source,event)
        try
          ids = event.Indices;
          nSelections = size(ids,1);
          merged = cell(nSelections,1);
          for sel = 1:nSelections
            merged{sel} = source.Data{ids(sel,1),ids(sel,2)};
          end
          stringified = IrisData.unknownCell2Str(merged,';',false);
          clipboard('copy',stringified);
        catch x
          fprintf('Copy failed for reason:\n "%s"\n',x.message);
        end
      end
    end %view

    function handles = plot(obj,varargin)
      % PLOT Quickly plot the contianed data (or subs) on a new figure.
      % TODO: device units are mixed when dev. index 1 not plotted.

      limitByParams = {'Data','Axes','None'};

      p = inputParser();
      p.KeepUnmatched = true;

      p.addParameter('subs', 1:obj.nDatums, ...
        @(v)validateattributes(v,{'numeric','logical'},{'nonnegative'}) ...
        );

      p.addParameter('respectInclusion', true, @islogical);

      p.addParameter('legend', false, @islogical);

      p.addParameter('colorized', true, @islogical);

      p.addParameter('opacity', 1, ...
        @(x)validateattributes(x,{'numeric'},{'scalar','>=',0,'<=',1}) ...
        );

      p.addParameter('devices', 'all', ...
        @(v)IrisData.ValidStrings(v,['all';obj.AvailableDevices]) ...
        );

      p.addParameter('axes', [], ...
        @(x) ...
        isempty(x) || ...
        isa(x,'matlab.ui.control.UIAxes') || ...
        isa(x,'matlab.graphics.axis.Axes') ...
        );

      p.addParameter('baselineRegion', 'None', ...
        @(v)IrisData.ValidStrings(v,obj.BASELINE_TYPES) ...
        );

      p.addParameter( ...
        'baselineReference', 0, ...
        @(v) isscalar(v) && isnumeric(v) && (v >=0) ...
        );

      p.addParameter('numBaselinePoints', 1000, @isnumeric);

      p.addParameter('baselineOffsetPoints', 0, ...
        @(v)validateattributes(v,{'numeric'},{'nonnegative','scalar'}) ...
        );

      p.addParameter('scaleFactor', 1, @isnumeric);

      p.addParameter('interactive', true, @(x)isscalar(x) && islogical(x));

      p.addParameter('lineParameters', {}, @iscell);

      p.addParameter('axesLabels', true, @(x)isscalar(x) && islogical(x));

      p.addParameter('computeYLimitBy', 'Data', ...
        @(v)IrisData.ValidStrings(v,limitByParams) ...
        );
      p.addParameter('computeXLimitBy', 'Data', ...
        @(v)IrisData.ValidStrings(v,limitByParams) ...
        );

      p.parse(varargin{:});

      % validate subs
      subs = p.Results.subs;
      % test subs vector
      if any(subs > obj.nDatums)
        warning('IRISDATA:PLOT:SUBSERROR', ...
          'Indices outside of data range are ignored.' ...
          );
        subs(subs > obj.nDatums) = [];
      end
      % create inclusions list
      suppliedInclusions = ismember((1:obj.nDatums)',subs);
      if p.Results.respectInclusion
        % exclude if not in inclusion list or not in supplied list
        inclusions = ~(~obj.InclusionList | ~suppliedInclusions);
      else
        inclusions = suppliedInclusions;
      end
      % redefine subs
      subs = find(inclusions);

      allDevs = obj.AvailableDevices;

      [~,devices] = IrisData.ValidStrings( ...
        p.Results.devices, ...
        ['all';allDevs] ...
        );
      % determine device locations within data
      if ismember({'all'},devices)
        devices = allDevs;
      end

      nDevices = numel(devices);

      %validate baseline props
      [~,baseLoc] = IrisData.ValidStrings( ...
        p.Results.baselineRegion, ...
        obj.BASELINE_TYPES ...
        );

      %get the data
      data = obj.copyData(inclusions);

      % perform baseline:
      if ~strcmp(baseLoc,'None')
        data = IrisData.subtractBaseline( ...
          data, ...
          char(baseLoc), ...
          p.Results.numBaselinePoints, ...
          p.Results.baselineOffsetPoints, ...
          true, ...
          devices, ...
          p.Results.baselineReference ...
          );
      end

      % validate limit calculations
      [~,yLimBy] = IrisData.ValidStrings(p.Results.computeYLimitBy,limitByParams);
      [~,xLimBy] = IrisData.ValidStrings(p.Results.computeXLimitBy,limitByParams);

      % fig params
      fn = fieldnames(p.Unmatched);
      fv = struct2cell(p.Unmatched);
      fPar = [fn(:),fv(:)]';

      defaultFigParams = reshape( ...
        [{'Name', 'IrisData Plot'}, IrisData.FigureParameters], ...
        2,[] ...
        );
      for ipar = 1:size(fPar,2)
        overrideIdx = strcmpi(fPar{1,ipar},defaultFigParams(1,:));
        if ~any(overrideIdx), continue; end
        defaultFigParams{2,overrideIdx} = fPar{2,ipar};
      end

      createAxes = isempty(p.Results.axes);

      if createAxes
        %%% axes constants
        MIN_AX_WIDTH = 350;
        MIN_AX_HEIGHT = 230;
        MAX_COLS = 3;

        s0 = get(groot,'MonitorPositions');
        s0 = s0(s0(:,1) == 1,3:4);

        nRows = fix((nDevices-1)/MAX_COLS)+1;

        dims = [ ...
          MAX_COLS*MIN_AX_WIDTH, ... %width is constant
          MIN_AX_HEIGHT * nRows ... % height is dependent
          ];
        if nRows == 1
          dims(2) = 1.2*MIN_AX_HEIGHT;
        end
        dPos = [(s0-dims)./2,dims];
        % make the figure
        fig = figure(defaultFigParams{:},'Visible', 'off');
        fig.Position = dPos;

        axs = gobjects(1,nDevices);
        %%% axes
        % determine positions
        xSize = dims(1)/nDevices;
        ySize = dims(2)/nRows;
        xBounds = xSize .* ((1:nDevices)-1);
        yBounds = ySize .* ((1:nRows)-1);
        padding = [24,10,40,40]; %t,r,b,l
        % draw them
        for a = 1:nDevices
          colIdx = mod(a-1,nDevices)+1;
          rowIdx = fix((a-1)/MAX_COLS)+1;

          aa = axes(fig, ...
            'units', 'pixels', ...
            'box', 'off', ...
            'FontName', 'Times New Roman', ...
            'FontSize', 12 ...
            );

          aa.ActivePositionProperty = 'outerposition';
          aa.Position = [ ...
            xBounds(colIdx)+padding(4), ...
            yBounds(rowIdx)+padding(3), ...
            xSize-sum(padding([2,4])), ...
            ySize-sum(padding([1,3])) ...
            ];

          aa.Title.String = devices{a};

          aa.YLabel.String = '';
          aa.YLabel.Units = 'pixels';
          aa.YLabel.Rotation = -90;
          aa.YLabel.VerticalAlignment = 'bottom';
          aa.YLabel.HorizontalAlignment = 'left';
          aa.YLabel.Position(1) = 5; %x
          aa.YLabel.Position(2) = ySize-sum(padding([1,3]))-5; %y
          aa.YLabel.Position(3) = 1000;

          aa.XLabel.String = '';
          aa.XLabel.Units = 'pixels';
          aa.XLabel.VerticalAlignment = 'bottom';
          aa.XLabel.HorizontalAlignment = 'left';
          aa.XLabel.Position(1) = 25; %x
          aa.XLabel.Position(2) = 5; %y
          aa.XLabel.Position(3) = 1000;

          % draw the base lines
          aa.YBaseline.Visible = 'on';
          aa.YBaseline.LineWidth = 1.5;
          aa.YBaseline.LineStyle = '-';
          aa.YBaseline.Color = [aa.YBaseline.Color.*2,0.25];

          aa.XBaseline.Visible = 'on';
          aa.XBaseline.LineWidth = 1.5;
          aa.XBaseline.LineStyle = '-';
          aa.XBaseline.Color = [aa.XBaseline.Color.*2,0.25];

          % kill the axles
          aa.YAxis.Axle.Visible = 'off';
          aa.XAxis.Axle.Visible = 'off';

          %store
          axs(a) = handle(aa);
        end

      else
        axs = handle(p.Results.axes);
        fig = ancestor(axs,'figure', 'toplevel');
      end

      hLines = gobjects(numel(data),nDevices);

      if p.Results.colorized
        colors = IrisData.IrisColorMap(numel(data));
      else
        colors = IrisData.rep([1,2,3]+0.014,numel(data),1,'dims',{[],3});
      end

      if ~isempty(p.Results.lineParameters)
        lp = p.Results.lineParameters;
      else
        lp = {'linewidth', 2};
      end

      % create a scale factor vector for all devices
      % we assume the user entered a factor for the devices in the order that
      % obj.AvailableDevices returns

      if isscalar(p.Results.scaleFactor)
        scaleFactor = IrisData.rep(p.Results.scaleFactor,nDevices);
      elseif numel(p.Results.scaleFactor) < nDevices
        scaleFactor = [ ...
          p.Results.scaleFactor(:); ...
          IrisData.rep( ...
          p.Results.scaleFactor(end), ...
          nDevices - numel(p.Results.scaleFactor), ...
          1, ...
          'dims', {[],1} ...
          ) ...
          ];
      else
        % should be == nDevices in length.
        scaleFactor = p.Results.scaleFactor(1:nDevices);
      end

      for i = 1:numel(data)
        thisDevCount = data(i).nDevices;
        thisIdx = subs(i);
        indStrings = obj.getOriginalIndex(thisIdx);
        if iscell(indStrings)
          indStrings = strsplit(sprintf('%d|',indStrings{:}),'|');
          indStrings(end) = [];
          indStrings = strjoin(indStrings,'.');
        else
          indStrings = strjoin(string(indStrings),'.');
        end
        for d = 1:thisDevCount
          thisDevName = data(i).devices{d};
          if ~ismember(thisDevName,devices), continue; end
          thisDvIdx = ismember(devices,thisDevName);
          if createAxes
            ax = axs(thisDvIdx);
          else
            ax = axs(1);
          end

          thisScale = scaleFactor(thisDvIdx);

          hLines(i,thisDvIdx) = line(ax, ...
            'Xdata',data(i).x{d}, ...
            'Ydata',data(i).y{d}.*thisScale, ...
            'DisplayName', sprintf('%s-%s',indStrings,thisDevName), ...
            'hittest', 'on', ...
            lp{:} ...
            );
          if p.Results.interactive
            hLines(i,thisDvIdx).ButtonDownFcn = @lineClicked;
          end
          hLines(i,thisDvIdx).Color = [ ...
            brighten(colors(i,:),(d-1)/(2*thisDevCount)), ...
            p.Results.opacity ...
            ];
          % check if the length is 1, then make markers too
          if numel(data(i).y{d}) == 1
            hLines(i,thisDvIdx).Marker = '.';
            hLines(i,thisDvIdx).MarkerSize = 28;
            hLines(i,thisDvIdx).MarkerFaceColor = hLines(i,thisDvIdx).Color;
          end
        end
      end


      for a = 1:nDevices
        % set the x and y limits
        doms = struct();
        switch xLimBy{1}
          case 'Data'
            d = get(hLines,'XData');
            if iscell(d)
              d = cat(2,d{:})';
            end
            doms.x = IrisData.domain(d(:)).';
          case 'Axes'
            nChilds = numel(axs(a).Children);
            doms.x = nan(1,2);
            for axChild = 1:nChilds
              try %#ok<TRYNC>
                doms.x = IrisData.domain([doms.x,axs(a).Children(axChild).XData]).';
              end
            end
            if any(isnan(doms.x))
              warning("X-Limits could not be determined from axes, using Data.");
              d = obj.getDomains(devices{a});
              doms.x = d.X;
            end
          otherwise
            % do nothing
        end
        switch yLimBy{1}
          case 'Data'
            d = get(hLines,'YData');
            if iscell(d)
              d = cat(2,d{:})';
            end
            doms.y = IrisData.domain(d(:)).';
          case 'Axes'
            nChilds = numel(axs(a).Children);
            doms.y = nan(1,2);
            for axChild = 1:nChilds
              try %#ok<TRYNC>
                doms.y = IrisData.domain([doms.y,axs(a).Children(axChild).YData]).';
              end
            end
            if any(isnan(doms.y))
              warning("Y-Limits could not be determined from axes, using Data.");
              d = obj.getDomains(devices{a});
              doms.y = d.Y;
            end
          otherwise
            % do nothing
        end

        % set the x limits hard
        if isfield(doms,'x')
          axs(a).XLim = doms.x;
        end

        % set a soft limit (padded) for y
        if isfield(doms,'y')
          axs(a).YLim = sort(doms.y + 0.025*diff(doms.y).*[-1,1]);
        end

        if p.Results.axesLabels
          % add the units to the axes, assum units are the same for each datum
          % but different for each device
          axs(a).XLabel.String = data(1).units{a}.x;
          axs(a).YLabel.String = data(1).units{a}.y;
        end
        % Normalize the axes units to make resizing possible
        if ~isa(axs(a),'matlab.ui.control.UIAxes')
          axs(a).Units = 'normalized';
          axs(a).YLabel.Units = 'normalized';
          axs(a).XLabel.Units = 'normalized';
        end
      end

      if p.Results.legend
        for a = 1:numel(axs)
          legend(axs(a),'location','southeast');
        end
      end

      % if this method created the axes, then turn the figure visible, otherwise
      % let the caller handle the figure visibility
      if createAxes
        fig.Visible = 'on';
      end
      drawnow();

      handles = struct('Figure', handle(fig), 'Axes', handle(axs), 'Lines', hLines);

      function lineClicked(src,~)
        parentAx = ancestor(src,'axes');
        lineHandles = parentAx.Children( ...
          arrayfun( ...
          @(c)isa(c,'matlab.graphics.primitive.Line'), ...
          parentAx.Children, ...
          'UniformOutput', true ...
          ) ...
          );

        set(lineHandles,'linewidth',1.5);
        src.LineWidth = 2.5;
        uistack(src,'top');
        disp(src.DisplayName);
      end

    end

    function help(obj,method)
      % HELP Opens the help documentation for IrisData class or (optionally) method.
      if nargin < 2, method = ''; end
      docName = class(obj);
      if ~isempty(method)
        docName = strjoin({docName,method},'.');
      end
      try
        doc(docName);
      catch
        doc(class(obj));
      end
    end

    function explore(obj,method)
      % EXPLORE Loads IrisData into the editor and (optional) navigates to method
      % definition.
      if nargin < 2, method = ''; end
      docName = class(obj);
      if ~isempty(method)
        docName = strjoin({docName,method},'.');
      end
      try
        edit(docName);
      catch
        edit(class(obj));
      end
    end

  end

  %% Assignment, Save and Load operations

  methods

    function varargout = subsref(obj,s)
      % SUBSREF   Subscript reference override for IrisData.
      %   SUBSREF will allow a key~map like behavior so we can do things like:
      %   obj.Notes(1) or obj.Notes('file1') -> notes associated with file index 1.
      %   obj.Notes or obj.Notes{r,c} will index to whole set of notes.
      %   We also control the ouput behavior of Meta and Data accordingly
      %   Note that subsref only applies to access from outside of the classdef.
      %   It appears that MATLAB will skip the overridden subsref method if
      %   called from within a method. To use this custom indexing option, we
      %   must then call obj.subsref(substruct(...)); To see an example, explore
      %   the saveobj method.

      switch s(1).type
        case '.'
          % is obj.
          % determine if calling a method or a property
          mets = methods(obj);
          isMethod = strcmpi(s(1).subs,mets);
          if any(isMethod)
            theMethodBeingCalled = mets{isMethod};
            if ~nargout(sprintf('%s>%s.%s',class(obj),class(obj),theMethodBeingCalled))
              builtin('subsref', obj, s);
              return
            end
          end
          % not a zero-output method: continue
          % Notes
          if strcmp(s(1).subs, 'Notes') && length(s) > 1
            switch s(2).type
              case '()'
                % ignore any more inputs after s(2)
                switch class(s(2).subs{1}) %look only at first entry
                  case {'string', 'char'}
                    inds = obj.Membership(s(2).subs{1});
                    varargout = {obj.Notes(inds.notes,:)};
                    return
                end

            end
          end
          % Meta
          if strcmp(s(1).subs, 'Meta') && length(s) > 1
            switch s(2).type
              case '()'
                % ignore any more inputs after s(2)
                switch class(s(2).subs{1}) %look only at first entry
                  case {'string', 'char'}
                    inds = ismember(obj.Files, s(2).subs{1});
                    varargout = obj.Meta(inds);
                    return
                end

            end
          end
          % IndexMap
          if strcmp(s(1).subs,'IndexMap') && length(s) > 1
            subs = unique(squeeze([s(2).subs{:}]));
            if length(subs) > 1
              varargout{1} = arrayfun(@(v)obj.IndexMap(v),subs,'unif',1);
              return
            end
          end
          % Data
          if strcmp(s(1).subs,'Data')
            if numel(s) == 2
              switch s(2).type
                case '.'
                  % obj.Data.prop[s]
                  if ~iscell(s(2).subs)
                    subs = cellstr(s(2).subs);
                  else
                    subs = s(2).subs;
                  end
                  subS(1:length(subs)) = s(2);
                  outputVals = cell(1,length(subs));
                  d = obj.copyData(true(obj.nDatums,1));
                  for i = 1:numel(subS)
                    subS(i).subs = subs{i};
                    thisVals = arrayfun( ...
                      @(da)builtin('subsref', da, subS(i)), ...
                      d, ...
                      'UniformOutput', false ...
                      );
                    if all(cellfun(@isnumeric,thisVals,'unif',1)) || ...
                        all(cellfun(@iscell,thisVals,'unif',1))
                      thisVals = [thisVals{:}];
                    end
                    outputVals{i} = thisVals(:);
                  end
                  [varargout{1:nargout}] = outputVals{:};
                  return
                case '()'
                  if iscell(s(2).subs)
                    subs = s(2).subs{1};
                  else
                    subs = s(2).subs;
                  end
                  if isa(subs,'numeric')
                    incs = ismember((1:obj.nDatums)',subs);
                    varargout = {obj.copyData(incs)};
                  else
                    inds = obj.Membership(subs);
                    varargout = {obj.Data(inds.data)};
                  end
                  return
              end
            elseif numel(s) == 3
              subs = [s(2).subs{:}];
              incs = ismember((1:obj.nDatums)',subs);
              d = obj.copyData(incs);
              varargout{1} = cat(1,d.(s(3).subs));
              return
            end

          end
          % UserData
          if strcmp(s(1).subs,'UserData') && numel(s) > 1
            if ~strcmpi(s(2).type,'.')
              error("IRISDATA:SUBSREF:USERDATA","Must be a field.");
            end
            ud = obj.UserData;
            if ~isfield(ud,s(2).subs)
              error("IRISDATA:SUBSREF:USERDATA","'%s' is not a property of UserData",char(s(2).subs));
            end
            [varargout{1:nargout}] = builtin('subsref',ud,s(2:end));
          end
        case '()'
          % first need to verify that obj is not an array. If it is, we will try
          % to return obj(subs) instead of proceeding

          if ~isscalar(obj)
            [varargout{1:nargout}] = builtin('subsref', obj, s);
            return
          end

          % In this case, IrisData(subs,[...]) was presented. We will return a new
          % instace of irisdata containing only the provided subs.
          % In the case that the call looks like IrisData(1:n,1:m,...), we will
          % return 1 output for each the requested n, m, etc.. Thus, we could
          % make multiple subsets in one call like:
          %   [subs1,subs2] = IrisData(1:10, 22:50);
          varargout = cell(1,length(s(1).subs));
          for ss = 1:length(s(1).subs)
            % grab a copy of the original object
            newObj = obj.saveobj();

            % determine the subs wanted
            subs = unique([s(1).subs{ss}]);
            indexFile = obj.getFileFromIndex(subs);

            [subFiles,ix,ic] = unique(indexFile,'stable');
            subFilesBool = ismember(newObj.Files,subFiles);
            dropFiles = newObj.Files(~subFilesBool);
            % first keep only the files associated with the provided indices
            splitDrops = arrayfun(@(v)strsplit(v,";"),dropFiles,'UniformOutput',false);
            splitDrops = [splitDrops{:}];
            if ~isempty(splitDrops)
              histDrop = contains(newObj.FileHistory,splitDrops);
            else
              histDrop = false(1,numel(newObj.FileHistory));
            end
            newObj.FileHistory(histDrop) = [];
            newObj.Membership(newObj.Files(subFilesBool));
            newObj.Meta = newObj.Meta(subFilesBool);
            newObj.Data(~subFilesBool) = [];
            newObj.Notes = newObj.Notes(subFilesBool);
            newObj.Files(~subFilesBool) = [];
            for i = 1:sum(~subFilesBool)
              dropThis = dropFiles(i);
              remove(newObj.Membership,dropThis);
            end
            % now run down the files and gather only the correct data
            ofst = 0;
            for i = 1:length(subFiles)
              theseSubs = subs(ic == i);
              nSubs = length(theseSubs);
              thisFile = indexFile{ix(i)};
              thisMembership = newObj.Membership(thisFile);
              % determine where in the data the desired subs are
              keepIndices = ismember(thisMembership.data,theseSubs);
              % redefine our membership mapping
              thisMembership.data = ofst + (1:nSubs);
              newObj.Membership(thisFile) = thisMembership;
              % subset data
              thisData = newObj.Data{i};
              thisData(~keepIndices) = [];
              newObj.Data{i} = thisData;
              % update the offset tracker
              ofst = ofst+nSubs;
            end
            % prepare a new instance
            ud = newObj.UserData;
            newObj = IrisData.fastrmField(newObj,{'UserData'});
            varargout{ss} = IrisData(newObj,ud{:});
          end
          return
      end

      [varargout{1:nargout}] = builtin('subsref', obj, s);
    end

    function obj = subsasgn(obj,s,varargin)
      % SUBSASGN Current uses default method.
      obj = builtin('subsasgn',obj,s,varargin{:});
    end

    function s = saveobj(obj)
      % SAVEOBJ Returns a `struct` version of the IrisData object for saving/loading.

      nFiles = length(obj.Files);
      s = struct();
      s.Meta = cell(1,nFiles);
      s.Data = cell(1,nFiles); %empty
      s.Notes = cell(1,nFiles);%empty
      for F = 1:nFiles
        fname = obj.Files(F);
        s.Data{F} = obj.subsref(substruct('.','Data','()',fname));
        %s.Data{F} = obj.Data(fname); %see subsref
        s.Notes{F} = obj.subsref(substruct('.','Notes','()',fname));
        %s.Notes{F} = obj.Notes(fname); %see subsref
        s.Meta{F} = obj.subsref(substruct('.','Meta','()',fname));
      end
      s.Files = obj.Files;
      s.FileHistory = obj.FileHistory;
      % containers.Map are handle objects, so we need to copy them to prevent
      % mutations from affecting originating objects.
      s.Membership = containers.Map( ...
        obj.Membership.keys(), ...
        obj.Membership.values() ...
        );
      fn = fieldnames(obj.UserData);
      fcontents = struct2cell(obj.UserData);
      fv = cell(size(fcontents));
      for f = 1:numel(fv)
        % check for container.map so we can break references
        if isa(fcontents{f},'containers.Map')
          fv{f} = containers.Map(fcontents{f}.keys(),fcontents{f}.values());
        else
          fv{f} = fcontents{f};
        end
      end

      C = [fn,fv]';% matrix{
      C = C(:);%single vector
      s.UserData = C;
    end

    function session = saveAsIrisSession(obj,pathname)
      % SAVEASIRISSESSION Saves or returns an Iris Session.

      vf = iris.data.validFiles();
      fInfo = vf.getIDFromLabel('Session');

      if nargin < 2
        % No pathname was provided, prompt user
        filterText = { ...
          strjoin(strcat('*.',fInfo.exts),';'), ...
          fInfo.label ...
          };
        fn = fullfile( ...
          iris.pref.Iris.getDefault().UserDirectory, ...
          string(datetime('now','format','HHmmss'))+fInfo.exts{1} ...
          );
        pathname = iris.app.Info.putFile( ...
          'Save Iris Session', ...
          filterText, ...
          fn ...
          );
      end
      % create a session struct for saving
      session = IrisData.fastrmField(obj.saveobj(),{'UserData','Membership','FileHistory'});
      % make modifications for session requirements
      session.Files = string(session.Files);
      fileLabs = {'filePath','fileName','fileExtension'};
      for F = 1:length(session.Files)
        pathInfo = cell(1,3);
        [pathInfo{:}] = fileparts(session.Files{F});
        % get the data associated with this file
        thisData = session.Data{F};
        nData = numel(thisData);
        thisTemplate = IrisData.fastKeepField( ...
          thisData, ...
          {'protocols','displayProperties','id','inclusion'} ...
          );
        rData = IrisData.fastKeepField( ...
          thisData, ...
          { 'sampleRate', 'units', 'x', 'y', 'devices', ...
          'stimulusConfiguration','deviceConfiguration' ...
          } ...
          );
        [rData.duration] = deal(0);
        % helper fxn to compute duration
        calcDur = @(y,fs)arrayfun(@(v,s)size(v{1},1)/s{1},y,fs,'UniformOutput',false);
        % populate the template
        for ep = 1:nData
          % duration
          rData(ep).duration = calcDur(rData(ep).y,rData(ep).sampleRate);
          % store in template
          thisTemplate(ep).responses = rData(ep);
          % append/update file name to displayProperties
          fileProps = cellfun( ...
            @(p) ismember(thisTemplate(ep).displayProperties(:,1), p), ...
            fileLabs, ...
            'UniformOutput', false ...
            );
          fileProps = cat(2,fileProps{:});
          for ff = 1:3
            if ~any(fileProps(:,ff))
              thisTemplate(ep).displayProperties(end+1,:) = [fileLabs(ff),pathInfo(ff)];
            else
              thisTemplate(ep).displayProperties{fileProps(:,1),2} = pathInfo{ff};
            end
          end
        end

        % store
        session.Data{F} = thisTemplate;
      end

      % save the session
      % if an empty path name was provided, return the session without saving to disk
      % We can use this method to load IrisData objects into Iris as sessions.
      if isempty(pathname), return; end
      [rt,nm,ext] = fileparts(pathname);
      if ~contains(lower(ext),lower(fInfo.exts))
        fprintf(2,'File must have extension: ".isf". Modifying file name.\n');
        pathname = fullfile(rt,nm,fInfo.exts{1});
      end
      fprintf('Saving...');
      try
        save(pathname,'session', '-mat','-v7.3');
      catch e
        % catch error so that the session struct can be saved by user.
        fprintf('Could not save session for the following reason:\n\n');
        fprintf('  "%s"\n',e.message);
        return
      end
      fprintf('  Success!\nFile saved at:\n"%s"\n',pathname);
    end

    function obj = set(obj,fn,val)
      test = ismember(fn,'InclusionList');
      if ~any(test), error("Set can only be used on 'InclusionList'"); end
      if iscell(val), val = val{test}; end
      obj.InclusionList = val;
    end

  end

  %% Helper Methods

  methods (Access = protected)
    %protected methods allow user to access these if they decide to create a custom
    %subclass. They are then also overridable.

  end

  %% Static Methods

  methods (Static = true)
    % Methods that don't require object properties but should be included
    % to prevent excessive library additions to the user path.

    function groupInfo = determineGroups(inputArray,inclusions,dropExcluded,isCustom)
      % DETERMINEGROUPS Create a grouping vector from a table or array input.
      %

      if nargin < 4, isCustom = false; end % override algorithm if numeric input
      if nargin < 3, dropExcluded = true; end %work just as prior to 2021 release
      if nargin < 2, inclusions = true(size(inputArray,1),1); end
      if numel(inclusions) ~= size(inputArray,1)
        error( ...
          [ ...
          'Inclusion vector must be logical array ', ...
          'with the same length as the input array.' ...
          ] ...
          );
      end
      idNames = sprintfc('ID%d', 1:size(inputArray,2));
      nIDs = length(idNames);
      if istable(inputArray)
        inputTable = inputArray;
        inputArray = table2cell(inputArray);
      elseif iscell(inputArray)
        inputTable = cell2table( ...
          inputArray, ...
          'VariableNames', sprintfc('Input%d', 1:size(inputArray,2)) ...
          );
      elseif ismatrix(inputArray)
        inputTable = array2table( ...
          inputArray, ...
          'VariableNames', sprintfc('Input%d', 1:size(inputArray,2)) ...
          );
        inputArray = table2cell(inputTable);
      else
        error("IRISDATA:DETERMINEGROUPS:INPUTUNKNOWN","Incorrect input type.");
      end

      idNames = matlab.lang.makeValidName(idNames);

      theEmpty = cellfun(@isempty, inputArray);
      if any(theEmpty)
        inputArray(theEmpty) = {'empty'};
      end


      % loop and create individual grouping vectors
      groupVec = zeros(size(inputArray));
      for col = 1:size(inputArray,2)
        if isCustom
          % here we assume inputArray is numeric group numbers
          % so we unpack the cell array we created above
          groupVec(:,col) = [inputArray{:,col}];
        else
          groupVec(:,col) = createGroupVector(inputArray(:,col));
        end
      end

      % Drop exclusions
      if dropExcluded
        vecLen = sum(inclusions);
        groupVec(~inclusions,:) = [];
        inputTable(~inclusions,:) = [];
      else
        vecLen = height(inputTable);
        groupVec(~inclusions,:) = 0;
      end



      % get the group mapping
      [uGroups,groupIdx,Singular] = unique(groupVec,'rows');
      nGroups = size(uGroups,1);

      groupTable = [array2table(uGroups,'VariableNames',idNames),inputTable(groupIdx,:)];
      groupTable.Combined = rowfun( ...
        @(x)join(string(x),'::'), ...
        inputTable(groupIdx,:), ...
        'SeparateInputs', false, ...
        'OutputFormat', 'uniform' ...
        );
      % get counts
      if any(~uGroups)
        % ensure 0 if exclusions are present
        Singular = Singular - 1;
      end

      % Produce summary table for group map
      % *Singular is an integer index array
      groupTable.Counts = histcounts(sort(Singular),nGroups).';% tblt(:,2);
      groupTable.SingularMap = unique(Singular,'stable');% tblt(:,1);
      groupTable.Frequency = groupTable.Counts./sum(groupTable.Counts).*100; % percent

      %output
      groupInfo = struct();
      groupInfo.Singular = Singular;
      % Setup group vector for use with grpstats in the Statistics and machine
      % learning toolbox.
      groupInfo.Vectors = mat2cell(groupVec, ...
        vecLen,...
        ones(1,nIDs) ...
        );

      % Reorganize table
      groupInfo.Table = movevars( ...
        groupTable, ...
        {'SingularMap','Counts'}, ...
        'After', ...
        idNames{end} ...
        );


      %%% Helper Functions
      function vec = createGroupVector(factorInput)
        nFactors = numel(factorInput);
        factorVec = 1:nFactors;
        grpID = 1; %start at group == 1
        vec = zeros(nFactors,1);
        for iter = factorVec
          thisValue = factorInput(iter);
          didAsgn = false(nFactors,1);
          for idx = factorVec
            if vec(idx), continue; end %already labelled
            if isequal(thisValue,factorInput(idx))
              didAsgn(idx) = true;
              vec(idx) = grpID;
            end
          end
          if ~any(didAsgn), continue; end
          grpID = grpID + 1;
        end
      end

    end

    function varargout = ValidStrings(testString,varargin)
      % VALIDSTRINGS A modified version of matlab's validstring. VALIDSTRINGS accepts
      % a cellstr and returns up to 2 outputs, a boolean indicated if all strings in
      % testString passed validation (by best partial matching) in allowedStrings and
      % a cellstr containing the validated strings.

      allowedStrings = "";
      nVargs = length(varargin);
      for v = 1:nVargs
        thisInput = varargin{v};
        switch class(thisInput)
          case 'char'
            allowedStrings = union(allowedStrings,string(thisInput));
          case 'string'
            allowedStrings = union(allowedStrings,thisInput);
          case 'cell'
            cStr = cellfun(@string,thisInput,'UniformOutput',false);
            allowedStrings = union(allowedStrings,[cStr{:}]);
          otherwise
            error('VALIDSTRINGS:UNSUPPORTEDTYPE','Unsuported input type, "%s".',class(thisInput));
        end
      end

      % clear the empty
      allowedStrings(allowedStrings=="") = [];

      if ~isstring(testString), testString = string(testString); end

      % check if we want to ignore case by searching for the flag
      hasFlag = strcmpi("-any",allowedStrings);
      anywhere = any(hasFlag);
      allowedStrings(hasFlag) = [];

      % loop and check each input string
      tf = false(length(testString),1);
      idx = nan(length(testString),1);
      for i = 1:length(testString)
        if anywhere
          for a = 1:numel(allowedStrings)
            if regexpi(allowedStrings(a), testString(i), 'once')
              tf(i) = true;
              idx(i) = a;
              testString(i) = allowedStrings(a);
              break
            end
          end
        else
          try %#ok<TRYNC>
            % MATLAB validatestrings will find uppercase from lowercase but not vice versa
            testString(i) = validatestring(testString(i), allowedStrings);
            idx(i) = find(strcmpi(testString(i),allowedStrings),1,'first');
            tf(i) = true;
          end
        end
      end
      tf = all(tf);
      varargout{1} = tf;
      varargout{2} = cellstr(testString);
      varargout{3} = idx;
    end

    function [outputString,varargout] = unknownCell2Str(cellAr,sep,uniquify)
      % UNKNOWNCELL2STR Convert a cell's contents to a string (char array)
      if nargin < 3, uniquify = false; end
      if nargin < 2, sep = ';'; end
      caClass = cellfun(@class, cellAr, 'uniformoutput', false);
      % loop through each cell and determine string representation
      strRepresentation = cell(length(caClass),1);
      for I = 1:length(caClass)
        % convert each element to a string
        switch caClass{I}
          case {'char','string'}
            strNow = char(cellAr{I});%strjoin(cellAr{I}, ', ');
          case {'numeric','int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', ...
              'int64', 'uint64', 'double', 'single'}
            uAr = num2cell(cellAr{I});
            strNow = strjoin( ...
              cellfun( ...
              @(x) sprintf('%-.5g',x), ...
              uAr, ...
              'uniformoutput', false ...
              ), ...
              ', ' ...
              );
          case 'logical'
            tmpvec = {'false','true'};
            logStrings = cell(1,length(cellAr{I}));
            for ind = 1:length(cellAr{I})
              logStrings{ind} = tmpvec{double(cellAr{I}(ind))+1};
            end
            strNow = strjoin(logStrings, ',');
          case 'cell'
            [strNow,insideClass] = IrisData.unknownCell2Str(cellAr{I},sep,uniquify);
            caClass{I} = cat(2,caClass(I),insideClass{:});
          case 'struct'
            thisS = cellAr{I};
            nStructs = numel(thisS);

            fields = fieldnames(thisS);
            vals = struct2cell(thisS);

            [valStrings,insideClass] = arrayfun( ...
              @(e)IrisData.unknownCell2Str(e,sep,false), ...
              vals, ...
              'UniformOutput', false ...
              );

            insideStrings = cellfun(@(c)strjoin(c,', '), insideClass, 'UniformOutput',false);
            insideClasses = cell(nStructs,1);
            for i = 1:nStructs
              insideClasses{i} = strjoin(squeeze(insideStrings(:,:,i)),',');
            end

            caClass{I} = cat(2, ...
              join(IrisData.rep(caClass(I),nStructs),sep), ...
              join(insideClasses,'; ') ...
              );
            strNow = join(join([ ...
              IrisData.rep(fields(:),nStructs,1,'dims',{[],1}), ...
              valStrings(:)],':',2),sep);
          otherwise
            error('"%s" Cannot be dealt with currently.', caClass{I});
        end
        strRepresentation{I} = char(strNow);
      end
      % join all the strings using the input sep.
      if uniquify
        strRepresentation = unique(strRepresentation,'stable');
      end
      outputString = strjoin(strRepresentation,[sep,' ']);
      if nargout > 1
        varargout{1} = caClass;
      end
    end

    function newValue = cast(value,classList)
      %CAST Cast a character value to a specified class
      % Cast is different from the MATLAB base cast() function. This function expects
      % to cast booleans from 'true'/'false' to true/false. Further, cast will accept
      % nested classes from the classList using the following syntax: 'parent <
      % child'.


      classes = cellfun(@(l)strsplit(l,'<'),classList,'UniformOutput',false);
      nClass = numel(classes);
      nVal = numel(value);
      if nVal ~= nClass
        error('Class list must contain the same number of elements as the value list.');
      end

      newValue = value;

      for cl = 1:nClass
        this = strtrim(classes{cl});
        isNested = logical(numel(this)-1);
        thisClass = this{isNested + 1};
        switch thisClass
          case 'logical'
            arrayData = strtrim(strsplit(value{cl},';'));
            castedData = false(1,numel(arrayData));
            for a = 1:numel(arrayData)
              if strcmpi(arrayData{a},'true')
                castedData(a) = true;
              end
            end
            newValue{cl} = castedData;
          case 'struct'
            % For values, fields are separated by commmas, name~values separated by :'s
            % If the original struct was an array, we will have array indices
            % separated by ;'s.
            % casted values will be the next index down the line
            subClass = strsplit(this{isNested + 2},',');
            arrayData = strtrim(strsplit(value{cl},';'));
            castedData = cell(1,numel(arrayData));
            for a = 1:numel(arrayData)
              fieldData = strtrim(strsplit(arrayData{a},','));
              fieldData = cellfun(@(p)strsplit(p,':'),fieldData,'UniformOutput',false);
              fieldData = cat(1,fieldData{:});
              fieldData(:,2) = IrisData.cast(fieldData(:,2),subClass(:));
              castedData{a} = cell2struct(fieldData(:,2),fieldData(:,1));
            end
            newValue{cl} = castedData;
            isNested = false;
          case 'char'
            % if there is an array, we expect that we have a cellstr row array
            arrayData = strtrim(strsplit(value{cl},';'));
            castedData = cell(1,numel(arrayData));
            for a = 1:numel(arrayData)
              castedData{a} = char(arrayData{a});
            end
            if numel(arrayData) > 1
              newValue{cl} = castedData;
            else
              newValue{cl} = castedData{1};
            end
            % override nested behavior to prevent sticking a cellstr in another cell.
            isNested = false;
          case {'numeric','int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', ...
              'int64', 'uint64', 'double', 'single'}
            newValue{cl} = cast(str2num(value{cl}),thisClass);%#ok
          otherwise
            disp(thisClass);
        end

        if isNested
          nestClass = this{1};
          switch nestClass
            case 'cell'
              newValue{cl} = newValue(cl);
            otherwise
              disp(nestClass);
          end
        end
      end

    end

    function tableDat = collapseUnique(d,columnAnchor,stringify,uniquify)
      % COLLAPSEUNIQUE Collapse repeated cell entries as determined by columnAnchor.
      if nargin < 4, uniquify = true; end
      if nargin < 3, stringify = false; end
      keyNames = unique(d(:,columnAnchor),'stable');
      others = ~ismember(1:size(d,2), columnAnchor);
      % collect repeated values in cell arrays
      keyData = cellfun( ...
        @(x)d(ismember(d(:,columnAnchor),x),others), ...
        keyNames, ...
        'UniformOutput', false ...
        );
      tableDat = [ ...
        keyNames(:), ...
        keyData(:) ...
        ];
      % set all values column to strings
      if stringify
        tableDat(:,2) = arrayfun( ...
          @(a)IrisData.unknownCell2Str(a,';',uniquify), ...
          tableDat(:,2), ...
          'UniformOutput', false ...
          );
        % unknowncell2str will handle uniquifying cells, so we can exit here
        return
      end
      % if uniquify is true but items were not stringified, gather the unique contents
      if uniquify
        tableDat(:,2) = cellfun( ...
          @(v) IrisData.uniqueContents(v), ...
          tableDat(:,2), ...
          'UniformOutput', false ...
          );
      end

    end

    function flat = flattenStructs(varargin)
      % FLATTENSTRUCT Flattens a struct array.

      %extract structs
      structInds = cellfun(@isstruct,varargin,'unif',1);

      S = varargin(structInds);
      varargin(structInds) = [];

      p = inputParser();
      p.StructExpand = false;
      p.KeepUnmatched = true;

      p.addParameter('stringify', false, @islogical);
      p.parse(varargin{:});


      [fields,values] = deal(cell(length(S),1));
      for i = 1:length(S)
        fields{i} = fieldnames(S{i});
        values{i} = squeeze(struct2cell(S{i}));
      end
      fields = cat(1,fields{:});
      values = cat(1,values{:});

      flatCell = IrisData.collapseUnique([fields,values],1,p.Results.stringify,false);

      flatCell(:,1) = matlab.lang.makeValidName(flatCell(:,1));

      flat = struct();
      for n = 1:size(flatCell,1)
        flat.(flatCell{n,1}) = flatCell{n,2};
      end
    end

    function [S,varargout] = subtractBaseline(S,type,npts,ofst,nowarn,devices,reference)
      % SUBTRACTBASELINE Calculate a constant (or fit) value to subtract from each
      % "y" value in the data struct array, S.
      %   S is modified in place and returned
      if nargin < 7, reference = 0; end
      if nargin < 6, devices = {'all'}; end
      if nargin < 5, nowarn = false; end

      if ~iscellstr(devices), devices = cellstr(devices); end
      nData = numel(S);
      doFit = contains(lower(type),'sym');
      if doFit && ~nowarn,checkFitWarn(); end
      baselineValues = cell(nData,1);
      refBaselines = containers.Map();
      isSweep = false;% TODO: strcmpi(type,'sweep');
      isRef = false;% TODO: reference > 0 || isSweep;
      if isRef
        if isSweep %#ok<UNRCH> 
          % compute the sweep from the references
          if numel(reference) < 2
            init = 1;
          else
            init = reference(1);
          end
          fin = reference(end);
          % grab initial datum for collecting basic parameters
          firstDatum = S(init);
          ndevs = firstDatum.nDevices;
          for r = 1:ndevs
            %
          end
        else
          % find the reference trace and create subtraction vector
          refIdx = ismember(1:nData,reference(1));
          if ~any(refIdx), error('Cannot find reference in %d elements.',nData); end
          refDatum = S(refIdx);
          refDevs = refDatum.devices;
          ndevs = numel(refDevs);
          for r = 1:ndevs
            % init
            device = refDevs{r};
            rY = refDatum.y{r};
            rX = refDatum.x{r};
            if isrow(rX) || iscolumn(rX)
              rX = rX(:);
              rX = rX(:,ones(1,size(rY,2)));
            end

            % get baseline indices for this device
            rLen = size(rY,1);
            rInds = IrisData.getBaselineIndices(rLen,type,npts,ofst);

            % compute baseline parameters
            if doFit
              % fit a line to the <x(inds),y(inds)> and store the parameters
              refBaselines(device) = [ones(length(rInds),1),rX(rInds,:)]\rY(rInds,:);
            else
              vals = mean(rY(rInds,:),1,'omitnan');
              vals(isnan(vals)) = 0;
              refBaselines(device) = vals;
            end
          end
        end

      end %isRef

      for d = 1:nData
        this = S(d);
        ndevs = this.nDevices;
        thisX = []; %#ok
        inds = []; %#ok
        theseBaselines = cell(1,ndevs);
        for v = 1:ndevs
          thisY = this.y{v};
          thisX = this.x{v};

          % check if this device should be baselined, if not, just return the
          % original data and set baselineValues to nans
          thisDev = this.devices{v};
          if ~ismember('all',devices) && ~ismember(thisDev,devices)
            theseBaselines{v} = nan(1,size(thisY,2));
            continue
          end
          % if subtracting from a reference, use that reference device map
          % We assume that REFY is the same size as THISY
          if isRef
            betas = refBaselines(thisDev);%#ok
            if doFit
              % get the fit parameters and construct the column-wise lines
              % from thisX and subtract the reconstructed lines from thisY cols
              % i.e. the reconstructed lines need to be a matrix the shape of
              % thisY
              if isrow(thisX) || iscolumn(thisX)
                thisX = thisX(:);
                thisX = thisX(:,ones(1,size(thisY,2)));
              end

              baselines = betas(1,:) + betas(2,:).*thisX;
            else
              % get the values computed from column-wise refY and sobtract them
              % from the columns of thisY.
              baselines = betas(ones(size(thisY,1),1),:);
            end
            % update values
            this.y{v} = thisY - baselines;
            theseBaselines{v} = baselines;
            continue
          end

          % collect indices for subtraction
          thisLen = size(thisY,1);
          inds = IrisData.getBaselineIndices(thisLen,type,npts,ofst);

          if doFit
            % create fit based on inds for each line in the matrix
            bVal = zeros(size(thisY));
            if isrow(thisX) || iscolumn(thisX)
              thisX = thisX(:);
              thisX = thisX(:,ones(1,size(thisY,2)));
            end
            % construct a matrix of line data for all Xs\Ys
            for i = 1:size(thisY,2)
              xfit = [ones(length(inds),1), thisX(inds,i)];
              yfit = thisY(inds,i);
              % fit to a smoothed data vector to prevent the line from being wierd
              betas = xfit\yfit;
              % y = b0 + b1*x;
              bVal(:,i) = betas(1) + betas(2).*thisX(:,i);
            end
            baselines = bVal;
          else
            bVal = mean(thisY(inds,:),1,'omitnan');
            % make any nans into 0 so we don't cause all pts to be nans
            bVal(isnan(bVal)) = 0;
            baselines = bVal;
            % create matrix
            bVal = bVal(ones(thisLen,1),:);
          end

          % update values
          this.y{v} = thisY - bVal;
          theseBaselines{v} = baselines;
        end
        % reassign
        baselineValues{d} = theseBaselines;
        S(d) = this;
      end
      if nargout > 1
        varargout{1} = baselineValues;
      end
      % local function which detects and throws warning if it hasn't been encountered
      % before
      function checkFitWarn()
        [~,wID] = lastwarn();
        if ~strcmpi(wID,'IRISDATA:SUBTRACTBASELINE:FIT')
          warning('IRISDATA:SUBTRACTBASELINE:FIT', ...
            'Sym and Asym methods can be very slow, be patient.' ...
            );
        end
      end
    end

    function inds = getBaselineIndices(thisLen,type,npts,ofst)
      switch lower(type)
        case {'start','beginning'}
          inds = (1:npts)+ofst;
        case 'end'
          inds = thisLen-ofst-((npts:-1:1)-1);
        case {'asym','sym'}
          % start
          inds = (1:npts)+ofst;
          if strcmpi(type,'sym')
            % is symetrical, append end
            inds = [inds,thisLen-ofst-((npts:-1:1)-1)];
          end
        otherwise
          error('Cannot recognize type, "%s".',type);
      end
      % validate inds
      inds(inds <= 0) = [];
      inds(inds > thisLen) = [];
      % make sure inds are unique
      inds = unique(inds); %sorted
    end

    function S = butterFilter(S,type,freqs,ord,devs)
      % butterFilter Perform digital butterworth filtering of the data
      % 'y' value in structs in filtered in place
      % input struct S is expected to be of type returned by IrisData.copyData();

      %determine filter parameters
      switch lower(type)
        case 'lowpass'
          ftype = 'low';
          flt = 2*freqs(1);
        case 'bandpass'
          ftype = 'bandpass';
          flt = sort(2 .* freqs);
        case 'highpass'
          ftype = 'high';
          flt = 2*max(freqs);
      end
      try
        ButterParam('save');
      catch e
        fprintf(2,'ButterParam.mat not accessible: "%s"\n',e.message);
      end
      % loop and filter
      nDatums = numel(S);
      for d = 1:nDatums
        % collect this entry
        this = S(d);
        % how many devices does this datum have?
        ndevs = this.nDevices;
        % loop through devices
        for v = 1:ndevs
          % determine this device index is in our list
          if ~ismember('all',devs) && ~ismember(this.devices{v},devs), continue; end
          if iscell(this.sampleRate)
            Fs = this.sampleRate{v};
          else
            Fs = this.sampleRate(v);
          end

          if any(flt./Fs >= 1)
            error("Filter frequencies must be less than the Nyquist frequency (%0.2fHz)",Fs/2);
          end

          thisY = this.y{v};
          yLen = size(thisY,1);

          % get column means for reducing the zero offset artifacts from filtering.
          mu = mean(thisY,1,'omitnan');

          % find and replace nans with mu
          [rowNans,colNans] = find(isnan(thisY));
          for rc = 1:length(rowNans)
            thisY(rowNans(rc),colNans(rc)) = mu(colNans(rc));
          end

          % pad the array with a few hundred samples of the local means
          npts = max(ceil([0.01*yLen;10]));
          preVals = mean(thisY(1:npts,:),1,'omitnan');
          postVals = mean(thisY((end-(npts-1)):end,:), 1, 'omitnan');

          thisY = [preVals(ones(npts,1),:);thisY;postVals(ones(npts,1),:)]; %#ok

          % subtract the colmeans
          thisY = thisY-mu;
          % build filter
          [b,a] = ButterParam(ord,flt./Fs,ftype);
          % pad and filter
          thisY = FiltFiltM(b, a, thisY);
          % add Mu back in
          thisY = thisY(npts+(1:yLen),:) + mu;
          % replace nan positions with nan
          for rc = 1:length(rowNans)
            thisY(rowNans(rc),colNans(rc)) = nan;
          end
          this.y{v} = thisY;
        end
        % reassign
        S(d) = this;
      end
    end

    function S = scaleData(S,scaleFactor,devices,type)
      % SCALEDATA method to scale y data by a scalar value (per device).
      %   If scaleFactor is scalar, the same factor will be applied to all
      %   devices, otherwise scaleFactor must be as  long as the largest
      %   nDevices.
      if nargin < 4, type = 'multiply'; end
      % type = IrisData.ValidStrings(type,{'multiply','add','subtract','divide'});
      maxDeviceCount = max([S.nDevices]);
      if isscalar(scaleFactor)
        scaleFactor = scaleFactor(ones(1,maxDeviceCount));
      elseif (numel(scaleFactor) ~= maxDeviceCount)
        error('Scale factor must be scalar or have length %d',maxDeviceCount);
      end
      nDatums = numel(S);
      for d = 1:nDatums
        % collect
        this = S(d);
        % loop through devices and apply the scaleFactor
        for v = 1:this.nDevices
          % determine if this device is in our list
          if ~ismember('all',devices) && ~ismember(this.devices{v},devices), continue; end
          % apply the scaling factor
          switch type
            case 'multiply'
              this.y{v} = this.y{v} .* scaleFactor(v);
            case 'divide'
              this.y{v} = this.y{v} ./ scaleFactor(v);
            case 'add'
              this.y{v} = this.y{v} + scaleFactor(v);
            case 'subtract'
              this.y{v} = this.y{v} - scaleFactor(v);
            otherwise
              % multiply
              this.y{v} = this.y{v} .* scaleFactor(v);
          end
        end
        % store
        S(d) = this;
      end
    end

    function A = fastrmField(S, fname)
      % FASTRMFIELD Removes supplied fieldnames from struct and returns struct of same size.
      fn = fieldnames(S);
      fname = string(fname);
      % which names to keep
      %fKeep = cellfun(@isempty, regexpi(fn,strjoin(fname,'|')));
      fKeep = true(numel(fn),1);
      for i = 1:numel(fn)
        if IrisData.ValidStrings(fn{i},fname)
          fKeep(i) = false;
        end
      end
      % build the last struct in the array
      sz = size(S);
      fdat = struct2cell(S(end,end));
      A(sz(1),sz(2)) = cell2struct(fdat(fKeep), fn(fKeep),1);

      % If input is longer than 1 in any dimension, fill in all the values
      if any(sz > 1)
        for i = 1:sz(1)
          for j = 1:sz(2)
            fdat = struct2cell(S(i,j));
            A(i,j) = cell2struct(fdat(fKeep), fn(fKeep),1);
          end
        end
      end

    end

    function A = fastKeepField(S, fname)

      fn = fieldnames(S);
      % which names to keep
      %fKeep = ~cellfun(@isempty, regexpi(fn,strjoin(fname,'|')));
      fKeep = false(numel(fn),1);
      for i = 1:numel(fn)
        if IrisData.ValidStrings(fn{i},fname)
          fKeep(i) = true;
        end
      end
      % build the last struct in the array
      sz = size(S);
      fdat = struct2cell(S(end,end));
      A(sz(1),sz(2)) = cell2struct(fdat(fKeep), fn(fKeep),1);

      % If input is longer than 1 in any dimension, fill in all the values
      if any(sz > 1)

        for i = 1:sz(1)
          for j = 1:sz(2)
            fdat = struct2cell(S(i,j));
            A(i,j) = cell2struct(fdat(fKeep), fn(fKeep),1);
          end
        end

      end

    end


    function C = uniqueContents(cellAr)
      % UNIQUECONTENTS Validate cell contents for multiple cells.
      contents = cell(1,numel(cellAr));
      for i = 1:numel(cellAr)
        this = cellAr{i};
        while iscell(this) && (numel(this) == 1 || ~iscellstr(this))%#ok
          this = [this{:}];
        end
        contents{i} = this;
      end
      % if all equal return first
      if numel(contents) == 1 || isequal(contents{:})
        C = contents{1};
        return
      end

      % if only 2 elements, return them
      n = length(contents);
      if n == 2
        C = contents;
        return
      end

      % if more than 2, reduce to only unique values
      inds = 1:n;
      keep = ones(n,1);
      for i = inds
        replicates = false(1,n);
        thisRep = cellfun( ...
          @(cnt) isequal(contents{i},cnt), ...
          contents(inds ~= i), ...
          'UniformOutput', true ...
          );
        replicates(inds ~= i) = thisRep;
        keep(i) = min([i,find(replicates)]);
      end

      %return
      C = contents(unique(keep));
    end

    function varargout = domain(inputData)
      %DOMAIN min,max array for each input argument provided, operates col-wise on matrix.
      arguments (Repeating)
        inputData (:,:) {mustBeNumeric(inputData)}
      end
      nIn = length(inputData);
      varargout = cell(1,min([nargout,nIn]));
      for I = 1:min([max([1,nargout]),nIn])
        thisRange = inputData{I};
        sz = size(thisRange);
        nanLoc = isnan(thisRange);
        % convert to column matrix and replace nans with mean value
        if any(nanLoc(:)) && all(sz > 1) % is matrix with nan, operate on columns
          colMeans = mean(thisRange,1,'omitnan');
          for col = 1:size(thisRange,2)
            thisRange(nanLoc(:,col),col) = colMeans(col);
          end
        elseif any(nanLoc(:)) && ~all(sz > 1) % is vector with nan, reshape to column replace
          thisRange = thisRange(:);
          thisRange(nanLoc) = mean(thisRange,'omitnan');
        elseif ~all(sz > 1) % is vector, no nan, reshape only
          thisRange = thisRange(:);
        end
        % sort
        thisRange = sort(thisRange); %col-wise
        % retrieve first and last
        varargout{I} = thisRange([1,end],:);
      end
    end

    function p = centerFigPos(w, h)
      s = get(0, 'ScreenSize');
      if any([w<=1 && w>0,h<=1 && h>0])
        if ~all([w<=1 && w>0,h<=1 && h>0])
          error('If w & h are normalized, must be (0,1].');
        end
        w = w*s(3);
        h = h*s(4);
      end

      p = ...
        [...
        (s(3) - w) / 2, ...
        (s(4) - h) / 2, ...
        w, ...
        h...
        ];
    end

    function outvec = rep( X, N, each, varargin )
      % REP  Repeat an element or vector N times with individual elements repeated each.
      %   REP willl repeat scalar, vector, or matrix N times. If 'each' is a scalar,
      %   then all elements in X will be repeated N.*['each'] times. If 'each' is a
      %   vector, then numel(each) must equal numel(X). Optionally, dimension
      %   args can be passed to the name, value pair, 'dims'. A vector as long as
      %   the desired dimensions is required. For a 2-D output, input 'dims',
      %   {r,c}. Setting any elements of the 'dims' argument to [], will let the
      %   reshape function automatically determine that dimension's count based
      %   on other provided data. REP returns a column organized vector unless
      %   'dims' argument is provided. If no 'dims' argument is '[]', rep
      %   will assume the dimension after the last provided will handle overflow.
      %
      %  Usage:
      %   repMat = rep(inputMatrix, numRepeatsAll, numRepeatsEach, 'dims',
      %   {numRow,numCols,...});
      %  Example:
      %   % NOTE: output 'dims' can be a transpose of the input matrix, or any other
      %   %   reshaped form.
      %   m = rep([1;2], 1, [1;2],'dims',{1,[]})
      %   >>m =
      %        1     2     2
      %

      %%% Parse
      if nargin < 3 || strcmpi(each, 'dims')
        each = 1;
        if nargin > 3
          varargin = ['dims', varargin(:)'];
        end
      end

      p = inputParser;

      addRequired(p, 'X', @(x) true);
      addOptional(p, 'N', 1, @(x)validateattributes(x,{'numeric'}, {'nonempty'}));
      addOptional(p, 'each', 1, ...
        @(x)validateattributes(x, {'numeric'}, {'nonempty'}));
      addParameter(p, 'dims', {[]}, ...
        @(x)validateattributes(x, {'numeric', 'cell'}, {}));
      addParameter(p, 'byRow', false, ...
        @(x)validateattributes(x,{'logical','numeric'},{'nonempty'}));
      addParameter(p, 'squeeze', false, ...
        @(x)validateattributes(x,{'logical','numeric'},{'nonempty'}));

      parse(p, X, N, each, varargin{:});

      in = p.Results;

      %%% Create Each vector

      if numel(in.each) == 1
        in.each = each(ones(size(in.X)));
      else
        if numel(in.each) ~= numel(in.X)
          error('REP:EACHERROR', ...
            'Length of ''each'' must have %d elements (as in X)', numel(in.X));
        end
      end

      if in.byRow
        in.X = in.X.';
        in.each = in.each';
      end

      %%% Handle Rep input
      if in.N > 1
        sz = size(in.X);
        if ~any(sz == 1), sz = [sz,1]; end
        sz(sz~=1) = 0;
        sindx = find(logical(sz),1); %find the first singleton for repeating.
        sz(sindx) = in.N;
        sz(setdiff(1:end,sindx)) = 1;
        sz = num2cell(sz);
        in.X = repmat(in.X,sz{:});
        in.each = repmat(in.each,sz{:});
      end

      %%% Runlength decode

      outvec = in.X; %if only N was supplied and all each are 1

      if ~all(each == 1)
        in.RepVec = in.each;
        rr = in.RepVec > 0;
        a = cumsum(in.RepVec(rr));
        b = zeros(a(end),1);
        b(a-in.RepVec(rr)+1) = 1;
        tmp = in.X(rr);
        outvec = tmp(cumsum(b)); %an each argument was supplied
      end

      %%% Reshape

      if all(cellfun(@isempty,in.dims,'unif',1))
        outvec = outvec(:);
        return;
      end
      if ~any(cellfun(@isempty, in.dims,'unif',1))
        in.dims = [in.dims{:}, {[]}];
      end

      outvec = reshape(outvec, in.dims{:});

      if in.squeeze
        outvec = squeeze(outvec);
      end

    end

    function cm = IrisColorMap(n)
      colorMatrix = [ ...
        72,94,97; ...
        181,219,69; ...
        139,70,204; ...
        90,112,208; ...
        108,202,92; ...
        189,136,212; ...
        210,80,48; ...
        132,215,209; ...
        205,145,63; ...
        142,83,54; ...
        137,164,205; ...
        197,75,99; ...
        87,148,120
        ] / 255;
      nMat = size(colorMatrix,1);
      cm = interp1( ...
        1:nMat, ...
        colorMatrix, ...
        linspace(1,nMat,n), ...
        'pchip' ...
        );
      cm(cm > 1) = 1; %correct interp
      cm(cm < 0) = 0; %correct interp
    end

    function tf = isWithinRange(values,extents,inclusive)
      % ISWITHINRANGE Validates if a value is within a given range [inclusive by default]
      %  Set inclusive (3rd arg) to false if the value must be between but not
      %  matching provided extents. Inclusive argument may be a length 2 boolean to
      %  indicate if [start,end] should be inclusive. Default behavior is [true,true].

      if nargin < 3, inclusive = [true,true]; end
      if numel(inclusive) < 2, inclusive = inclusive([1,1]); end

      if inclusive(1)
        lComparitor = @ge;
      else
        lComparitor = @gt;
      end
      if inclusive(2)
        rComparitor = @le;
      else
        rComparitor = @lt;
      end

      nVal= numel(values);

      tf = false(nVal,2);

      for i = 1:nVal
        tf(i,1) = lComparitor(values(i), extents(1));
        tf(i,2) = rComparitor(values(i), extents(2));
      end

      tf = all(tf,2);


    end

    function cellFields = recurseStruct(S,stringify,parentName,sep)
      % RECURSESTRUCT Turn structs into N by 2 cells.
      % Fields that are structs will be merged into a nx2 cells while appending parentName
      if nargin < 4, sep = ' > '; end
      if nargin < 3, parentName = ''; end
      if nargin < 2, stringify = false; end
      cellFields = cell(0,2);
      for i = 1:length(S)
        s = S(i);
        fields = fieldnames(s);
        values = struct2cell(s);
        structInds = cellfun(@isstruct, values, 'UniformOutput',1);

        cellFields(end+(1:sum(~structInds)),:) = [fields(~structInds),values(~structInds)];

        if any(structInds)
          structLoc = find(structInds);
          flatSubs = cell(0,2);
          for j = 1:length(structLoc)
            % determine if struct is the terminal depth
            if ~IrisData.determineDepth(values{structLoc(j)})
              % convert struct arrays to cell arrays in case of stringy
              conts = values{structLoc(j)};
              conts = mat2cell(conts(:),ones(size(conts(:))),1); %#ok
              contNames = cellfun(@fieldnames,conts,'unif',0);
              contNames = cat(1,contNames{:});

              structContents = cellfun(@struct2cell,conts,'unif',0);
              structContents = cat(1,structContents{:});
              out = [ ...
                strcat( ...
                fields{structLoc(j)}, ...
                {sep}, ...
                contNames ...
                ), ...
                structContents ...
                ];

            else
              out = IrisData.recurseStruct(values{structLoc(j)});
              out(:,1) = strcat(fields{structLoc(j)},{sep},out(:,1));
            end
            flatSubs(end+(1:size(out,1)),:) = out;
          end
          cellFields(end+(1:size(flatSubs,1)),:) = flatSubs;
        end
      end

      if ~isempty(parentName)
        cellFields(:,1) = strcat(parentName,{sep},cellFields(:,1));
      end

      if stringify
        cellFields(:,2) = arrayfun(@IrisData.unknownCell2Str,cellFields(:,2),'UniformOutput',false);
      end

    end

    function lvl = determineDepth(s)
      % DETERMINEDEPTH Determine the depth of nested structs.
      lvl = 0;
      nStructs = length(s);
      counts = zeros(nStructs,1);
      for i = 1:nStructs
        vals = struct2cell(s(i));
        structLoc = cellfun(@isstruct,vals,'UniformOutput',true);
        if any(structLoc)
          counts(i) = counts(i)+1;% for this level
          depths = cellfun(@IrisData.determineDepth, vals(structLoc), 'unif', 1);
          counts(i) = counts(i) + max(depths); % for subsequent levels
        end
      end

      lvl = lvl + max(counts);
    end

    function values = findParamCell(params,expression,anchor,returnIndex,exact,asStruct,first)
      %FINDPARAMCELL
      if nargin < 7, first = true; end
      if nargin < 6, asStruct = false; end
      if nargin < 5, exact = false; end
      fields = params(:,anchor);
      vals = params(:,returnIndex);

      if ~iscell(expression), expression = cellstr(expression); end
      if exact
        idx = ismember(fields,expression);
      else
        nExp = length(expression);
        nFld = numel(fields);
        idx = false(nFld,nExp);
        for z = 1:nExp
          matched = regexpi(fields,expression{z},'once');
          if first
            bestMatch = min(cat(2,matched{:}));
          else
            bestMatch = cat(2,matched{:});
          end
          if isempty(bestMatch), continue; end
          idx(:,z) = cellfun( ...
            @(i) ~isempty(i) && any(i == bestMatch), ...
            matched, ...
            'UniformOutput', true ...
            );
        end
        idx = any(idx,2);
      end

      if ~asStruct
        values = [fields(idx),vals(idx)];
      else
        values = cell2struct(vals(idx),fields(idx));
      end

    end

    function params = FigureParameters()
      params = { ...
        'Visible', 'off', ...
        'NumberTitle', 'off', ...
        'Color', [1,1,1], ...
        'Units','pixels', ...
        'DefaultUicontrolFontName', 'Times New Roman', ...
        'DefaultAxesColor', [1,1,1], ...
        'DefaultAxesFontName', 'Times New Roman', ...
        'DefaultTextFontName', 'Times New Roman', ...
        'DefaultAxesFontSize', 16, ...
        'DefaultTextFontSize', 18, ...
        'DefaultUipanelUnits', 'pixels', ...
        'DefaultUipanelBordertype', 'line', ...
        'DefaultUipanelFontname', 'Times New Roman',...
        'DefaultUipanelFontunits', 'pixels', ...
        'DefaultUipanelFontsize', 12, ...
        'DefaultUipanelAutoresizechildren', 'off', ...
        'DefaultUitabgroupUnits', 'pixels', ...
        'DefaultUitabgroupAutoresizechildren', 'off', ...
        'DefaultUitabUnits', 'pixels', ...
        'DefaultUitabAutoresizechildren', 'off', ...
        'DefaultUibuttongroupUnits', 'pixels', ...
        'DefaultUibuttongroupBordertype', 'line', ...
        'DefaultUibuttongroupFontname', 'Times New Roman',...
        'DefaultUibuttongroupFontunits', 'pixels', ...
        'DefaultUibuttongroupFontsize', 12, ...
        'DefaultUibuttongroupAutoresizechildren', 'off', ...
        'DefaultUitableFontname', 'Times New Roman', ...
        'DefaultUitableFontunits', 'pixels', ...
        'DefaultUitableFontsize', 12 ...
        };
    end

    function obj = loadobj(s)
      % LOADOBJ Load helper to construct IrisData from saved instance.
      if isstruct(s)
        if isfield(s,'UserData')
          ud = s.UserData;
          s = rmfield(s,'UserData');
        else
          ud = {};
        end
        if ~isfield(s,'FileHistory')
          s.FileHistory = [];
        else
          s.FileHistory(ismember(s.FileHistory,s.Files)) = [];
        end
        obj = IrisData(s,ud{:});
      else
        obj = s;
      end
    end

  end
end

