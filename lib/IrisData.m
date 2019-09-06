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
    
    % Files- A string vector containing the names of files associated with this
    % object.
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
    DeviceMap
  end
  
  properties (Dependent = true)
    % Specs- A struct hold table and datum properties. Used in groupBy commands.
    Specs
    % nDatums- The number of available data.
    nDatums
    % MaxDeviceCount- The maximum counted devices for all data.
    MaxDeviceCount
    % InclusionList- The list of inclusions as set from Iris before sending here.
    InclusionList
    % AvailableDevices- A list of the available devices from all data.
    AvailableDevices
  end
  
  methods
    
    function obj = IrisData(varargin)
      %IRISDATA Construct instance of Iris DVA data class.
      %   IrisData expects an 
      ip = inputParser();
      ip.KeepUnmatched = true;
      ip.addParameter('Data', {}, @(v)validateattributes(v,{'cell'},{'nonempty'}));
      ip.addParameter('Meta', {}, @(v)validateattributes(v,{'cell'},{'nonempty'}));
      ip.addParameter('Notes',{}, @(v)validateattributes(v,{'cell'},{'nonempty'}));
      ip.addParameter('Files', {}, @(v)validateattributes(v,{'cell','string'},{'nonempty'}));
      ip.addParameter('Membership', containers.Map(), @(v)isa(v, 'containers.Map'));
      
      ip.parse(varargin{:});
      
      obj.Meta = ip.Results.Meta; %cell array
      obj.Files = string(ip.Results.Files(:)); %string list
      obj.Notes = cat(1,ip.Results.Notes{:}); %split up Nx2 cells
      obj.Membership = containers.Map( ...
        ip.Results.Membership.keys(), ...
        ip.Results.Membership.values() ...
        ); % containers Map using filenames as keys.
      obj.Data = cat(1,ip.Results.Data{:});
      obj.UserData = ip.Unmatched;
      
      %buld index map
      ogInds = obj.getOriginalIndex(1:obj.nDatums);
      % build the indexmap. Note this could be a 1:1 map
      if iscell(ogInds) %ie one datum represents multiple ogInds
        sizes = cellfun(@numel,ogInds,'UniformOutput',true);
        repInds = IrisData.rep((1:obj.nDatums)',1,sizes(:));
        obj.IndexMap = containers.Map([ogInds{:}],repInds);
      else
        obj.IndexMap = containers.Map(ogInds,(1:obj.nDatums)');
      end
      
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
    
  end
  
  methods (Access = public)
    % always public facing.
    
    function iData = Aggregate(obj,varargin)
      % AGGREGATE   Compute statistical aggregation on data.
      %   Usage: 
      %     aggs = AGGREGATE(IrisData, Name, Value); Where Name,Value pairs
      %     can be...
      %   @param 'groupBy': A valid filter name cellstr or 'none'.
      %   @param 'devices': A valid device name or 'all'.
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
      
      % TODO:
      %   Allow a custom table or grouping vector for groupBy (maybe override
      %   parameter).
      
      % constants
      validGroups = obj.getAllPossibleProps();
      
      % input parser
      p = inputParser();
      
      p.addParameter('groupBy', 'none', ...
        @(v)IrisData.ValidStrings(v,[{'none'};validGroups(:)]) ...
        );
      
      p.addParameter('devices', 'all', ...
        @(v)IrisData.ValidStrings(v,['all';obj.AvailableDevices]) ...
        );
      
      p.addParameter('baselineFirst', true, @(v)islogical(v)&&isscalar(v));
      
      p.addParameter('baselineRegion', 'start', ...
        @(v)IrisData.ValidStrings(v,{'Start','End','None','Asym','Sym'}) ...
        );
      
      p.addParameter('numBaselinePoints', 1000, @isnumeric);
      
      p.addParameter('baselineOffsetPoints', 0, ...
        @(v)validateattributes(v,{'numeric'},{'nonnegative','scalar'}) ...
        );
      
      p.addParameter('statistic', @(x)nanmean(x,1), ...
        @(v)validateattributes(v, ...
          {'char','string','function_handle'}, ... %'cell'
          {'nonempty'} ...
          ) ...
        );
      
      p.addParameter('scaleFactor', 1, @(x)isscalar(x) && isnumeric(x));
      
      p.addParameter('inclusionOverride', [], ...
        @(v)validateattributes(v,{'logical', 'numeric'},{'nonnegative'}) ...
        );
      
      p.addParameter('plot', false, @islogical);
      
      p.PartialMatching = true;
      p.CaseSensitive = false;
      p.KeepUnmatched = false;
      % Parse input parameters
      p.parse(varargin{:});
      
      % validate input strings
      [~,groupBy] = IrisData.ValidStrings( ...
        p.Results.groupBy, ...
        [{'none'};validGroups(:)] ...
        );
      [~,baseLoc] = IrisData.ValidStrings( ...
        p.Results.baselineRegion, ...
        {'Start','End','None','Asym','Sym'} ...
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
        inclusions = obj.InclusionList();
      end
      
      %Determine the grouping vector
      filterTable = obj.Specs.Table;
      
      if any(strcmpi('none',groupBy))
        filterTable.none = num2str(ones(height(filterTable),1));
      end
      
      % determine the grouping 
      groupingTable = filterTable(:,groupBy);
      groups = IrisData.determineGroups(groupingTable,inclusions);
      nGroups = height(groups.Table);
      
      % Copy included datums
      data = obj.copyData(inclusions);
      nData = sum(inclusions);
      subs = find(inclusions);
      
      
      % baseline (if First)
      if p.Results.baselineFirst && ~strcmp(baseLoc,'None')
        data = IrisData.subtractBaseline( ...
          data, ...
          char(baseLoc), ...
          p.Results.numBaselinePoints, ...
          p.Results.baselineOffsetPoints ...
          );
      end
      
      %%% Compute Group Statistics
      
      % determine device locations within data
      if contains({'all'},devices)
        devices = obj.AvailableDevices;
      end
      
      % count number of requested devices
      nDevOut = length(devices);
      
      % init output
      mat = struct( ...
        'devices', {cell(1,nDevOut)}, ...
        'groupsWithDevice',{cell(1,nDevOut)}, ...
        'x', {cell(1,nDevOut)}, ...
        'y', {cell(1,nDevOut)} ...
        );
      
      % Gather data by device
      for d = 1:nDevOut
        thisInds = obj.DeviceMap(devices{d});
        thisInds = thisInds(inclusions);
                
        % get the lengths of data
        dataLengths(1:nData,1) = struct('x',[],'y',[]);
        for i = 1:length(thisInds)
          if thisInds(i) < 0, continue; end
          xlen = numel(data(i).x{thisInds(i)});
          ylen = numel(data(i).y{thisInds(i)});
          dataLengths(i) = struct('x',xlen,'y',ylen);
        end
        
        % preallocate maximum sized vector for this device.
        [maxLen,maxIdx] = max([dataLengths.y]);
        [xvals,yvals] = deal(nan(maxLen,nData));
        
        % gather data
        for i = 1:length(thisInds)
          if thisInds(i) < 0,continue;end
          thisX = data(i).x{thisInds(i)};
          thisY = data(i).y{thisInds(i)}.*p.Results.scaleFactor;
          
          xvals(1:dataLengths(i).x,i) = thisX(:);
          yvals(1:dataLengths(i).y,i) = thisY(:);
        end
        
        %%% compute groups statistics
        % grpstats fails if any group has only 1 entry for some reason. So we need to
        % first extract entries whose group count is 1 and then reinsert them into
        % the grpstats matrix afterwards.
        
        % grouping vector
        %groupVectors = groups.Vectors;
        groupVector = groups.Singular;
        groupMap = groups.Table.SingularMap;

        % Detect any groups with single entries
        singleGroups = groups.Table.SingularMap(groups.Table.Counts == 1);
        hasSingles = ~isempty(singleGroups);
        if hasSingles
          warning('IRISDATA:AGGREGATE:SINGULARGROUPSDETECTED', ...
            'Aggregation may not be as expected due to groups with 1 entry.' ...
            );
          fprintf( ...
            'To prevent unexpected results, ''statistic'' should explicitly operate on columns.\n' ...
            );
        end
        %{
        % subset data that has only 1 occurence
        
        if hasSingles
          singleGrpInds = ismember(groups.Singular, singleGroups);
          ySingles = yvals(:,singleGrpInds);
          yvals(:,singleGrpInds) = [];
          %groupVectors = cellfun(@(x)x(~singleGrpInds), groupVectors, 'unif',0);
          groupVector = groups.Singular(~singleGrpInds);
        end
        %}

        %{
        % send to grpstats
        yStats = grpstats(yvals',groupVectors,p.Results.statistic)';
        %}

        % Parse the aggregate function
        multipleFx = false;
        theStat = p.Results.statistic;
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
                  if isempty(a(~contains(a,matlabroot)))
                    % not a builtin. just copy it over
                    fxString = theStat;
                  else
                    % is another builtin type, mean, nanmean, etc.
                    fxString = sprintf('@(x)%s(x,1)',lower(theStat));
                  end
                end
            end
            fx = str2func(fxString);
          case 'function_handle'
            fx = p.Results.statistic;
          case 'cell'
            fx = cell(numel(p.Results.statistic),1);
            for i = 1:numel(p.Results.statistic)
              switch p.Results.statistic{i}
                case {'char','string'}
                  fx{i} = str2func(p.Results.statistic{i});
                case 'function_handle'
                  fx{i} = p.Results.statistic{i};
              end
            end
            multipleFx = true;
        end
        
        % Create X matrix from the longest datum
        xStats = repmat(xvals(:,maxIdx),1,nGroups);
        % loop through each group and compute the aggregates
        yAggs = cell(nGroups,numel(fx));
        groupedDataLengths = zeros(1,nGroups);
        for g = 1:nGroups
          thisGrpNum = groupMap(g);
          thisGrpInd = groupVector == thisGrpNum;
          % multipleFx should be false until I have time to work on how to save % it into the data property. Possibly, I can replace/create 
          % devices with names like, 'device::stat' or 'stat (device)'.
          % consider this for release 2.0.3a
          if multipleFx
            for f = 1:numel(fx)
              yAggs{g,f} = fx{f}(yvals(:,thisGrpInd)')';
            end
          else
            thisDataSubset = yvals(:,thisGrpInd);
            thisAgg = fx(thisDataSubset');
            yAggs{g} = thisAgg(:);
          end

          % Get the minimum grouped data length from X Values
          groupedDataLengths(g) = min([dataLengths(thisGrpInd).x],[],'omitnan');
        end
        % for now we assume that input length == output length
        yStats = cat(2,yAggs{:});
        
        
        %{
        % reinsert the singles if needed
        if hasSingles
          yStatsCopy = yStats;
          yStats = nan(size(yStatsCopy,1),nGroups);
          singlesInsertionInds = ismember(groups.Table.SingularMap,singleGroups);
          yStats(:,~singlesInsertionInds) = yStatsCopy;
          yStats(:,singlesInsertionInds) = ySingles;
        end
        %}

        %{
        % create a variable that contains the lengths of each grouped data
        groupedDataLengths = zeros(1,nGroups);
        for i = 1:nGroups
          g = groups.Table.SingularMap(i);
          gInds = groups.Singular == g;
          groupedDataLengths(i) = min([dataLengths(gInds).x],[],'omitnan');
        end
        %}

        % store
        mat.devices{d} = devices{d};
        mat.x{d} = xStats;
        mat.y{d} = yStats;
        mat.groupsWithDevice{d} = unique(groups.Singular(thisInds > 0));
      end
      
      % Need to expand matrices to individual data entries and merge grouped
      % parameters from original data and then perform baseline (first == 0).
      % Finally, the data need to be structed for a new instance of IrisData.
      
      aggs(1:nGroups,1) = data(1); % copy structure layout
      % keep track of groups for building new maps
      oldMbr = obj.getFileFromIndex(subs);%#ok
      newMbr = cell(nGroups,2);
      for g = 1:nGroups
        thisGroupNum = groups.Table.SingularMap(g);
        thisGroupLog = groups.Singular == thisGroupNum;
        thisGroupedInfo = IrisData.flattenStructs(data(thisGroupLog));
        % reduce certain fields to unique values
        if iscell(thisGroupedInfo.id)
          thisGroupedInfo.id = strjoin(thisGroupedInfo.id, ',');
        end
        thisGroupedInfo.sampleRate = {IrisData.uniqueContents( ...
          thisGroupedInfo.sampleRate ...
          )};
        unitStructs = IrisData.uniqueContents( ...
          thisGroupedInfo.units ...
          );
        thisGroupedInfo.units = mat2cell(unitStructs,1,ones(1,numel(unitStructs)));%#ok
        thisGroupedInfo.stimulusConfiguration = IrisData.uniqueContents( ...
          thisGroupedInfo.stimulusConfiguration ...
          );
        thisGroupedInfo.deviceConfiguration = IrisData.uniqueContents( ...
          thisGroupedInfo.deviceConfiguration ...
          );
        % append x, y and devices
        thisGroupedInfo.devices = cell(0,nDevOut);
        thisGroupedInfo.x = cell(0,nDevOut);
        thisGroupedInfo.y = cell(0,nDevOut);
        for d = 1:nDevOut
          if ismember(g,mat.groupsWithDevice{d})
            thisGroupedInfo.devices{end+1} = mat.devices{d};
            thisGroupedInfo.x{end+1} = mat.x{d}(1:groupedDataLengths(g),g);
            thisGroupedInfo.y{end+1} = mat.y{d}(1:groupedDataLengths(g),g);
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
        aggs = IrisData.subtractBaseline( ...
          aggs, ...
          char(baseLoc), ...
          p.Results.numBaselinePoints, ...
          p.Results.baselineOffsetPoints ...
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
      % flatten userdata field
      newUD = [fn(:),fv(:)]';
      newUD = newUD(:);%single vector
      
      % Create IrisData object
      iData = IrisData( ...
        'meta',   newMeta, ...
        'notes',  {newNotes}, ...
        'data',   {aggs}, ...
        'files', files, ...
        'member', mbrMap, ...
        newUD{:} ...
        );
      
      % plot if requested
      if p.Results.plot
        plot(iData);
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
      
      p.parse(varargin{:});
      
      % validate filter prefs
      [~,fltType] = IrisData.ValidStrings( ...
        p.Results.type, ...
        {'lowpass','bandpass','highpass'} ...
        );
      fltType = char(fltType);
      if length(p.Results.frequencies) > 1 && ~startsWith(fltType,'band')
        warning( ...
          'IRISDATA:FILTER:INCORRECTFREQLENGTH', ...
          'More than 1 frequency cutoff provided, but only 1 was needed for %s.', ...
          fltType ...
          );
      end
      
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
      iData = newObj.UpdateData(data);
      
    end
    
    function iData = UpdateData(obj,S)
      % UPDATEDATA Design for use following edits to IrisData.copyData();
      
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
        'meta', sObj.Meta, ...
        'notes', sObj.Notes, ...
        'data', sObj.Data, ...
        'files', sObj.Files, ...
        'member', sObj.Membership, ...
        sObj.UserData{:} ...
        );
    end
    
    function iData = Concat(obj,varargin)
      % CONCAT Concatenate inputs onto end of calling data object. Returns new
      % object.
      error('Concat is under development for a future release.');
    end
    
    function handles = plot(obj,varargin)
      % PLOT Quickly plot the contianed data (or subs) on a new figure.
      import iris.app.*;
      p = inputParser();
      p.KeepUnmatched = true;
      
      p.addParameter('subs', 1:obj.nDatums, ...
        @(v)validateattributes(v,{'numeric','logical'},{'nonnegative'}) ...
        );
      
      p.addParameter('respectInclusion', true, @islogical);
      
      p.addParameter('legend', false, @islogical);
      
      p.addParameter('colorized', true, @islogical);
      
      p.addParameter('devices', 'all', ...
        @(v)IrisData.ValidStrings(v,['all';obj.AvailableDevices]) ...
        );
      
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
        inclusions = ~(~obj.InclusionList | ~suppliedInclusions);
      else
        inclusions = suppliedInclusions;
      end
      % redefine subs
      subs = find(inclusions);
      
      [~,devices] = IrisData.ValidStrings( ...
        p.Results.devices, ...
        ['all';obj.AvailableDevices] ...
        );
      % determine device locations within data
      if contains({'all'},devices)
        devices = obj.AvailableDevices;
      end
      
      %get the data
      data = obj.copyData(inclusions);
      
      % fig params
      fn = fieldnames(p.Unmatched);
      fv = struct2cell(p.Unmatched);
      fPar = [fn(:),fv(:)]';
            
      defaultFigParams = reshape({ ...
        'Name', 'IrisData Plot', ...
        'NumberTitle', 'off', ...
        'Color', [1,1,1], ...
        'DefaultUicontrolFontName', Aes.uiFontName, ...
        'DefaultAxesColor', [1,1,1], ...
        'DefaultAxesFontName', Aes.uiFontName, ...
        'DefaultTextFontName', Aes.uiFontName, ...
        'DefaultUibuttongroupFontname', Aes.uiFontName,...
        'DefaultUitableFontname', Aes.uiFontName, ...
        'DefaultUipanelUnits', 'pixels', ...
        'DefaultUipanelPosition', [20,20, 260, 221],...
        'DefaultUipanelBordertype', 'line', ...
        'DefaultUipanelFontname', Aes.uiFontName,...
        'DefaultUipanelFontunits', 'pixels', ...
        'DefaultUipanelFontsize', Aes.uiFontSize('label'),...
        'DefaultUipanelAutoresizechildren', 'off', ...
        'DefaultUitabgroupUnits', 'pixels', ...
        'DefaultUitabgroupPosition', [20,20, 250, 210],...
        'DefaultUitabgroupAutoresizechildren', 'off', ...
        'DefaultUitabUnits', 'pixels', ...
        'DefaultUitabAutoresizechildren', 'off', ...
        'DefaultUibuttongroupUnits', 'pixels', ...
        'DefaultUibuttongroupPosition', [20,20, 260, 210],...
        'DefaultUibuttongroupBordertype', 'line', ...
        'DefaultUibuttongroupFontname', Aes.uiFontName,...
        'DefaultUibuttongroupFontunits', 'pixels', ...
        'DefaultUibuttongroupFontsize', Aes.uiFontSize('custom',2),...
        'DefaultUibuttongroupAutoresizechildren', 'off', ...
        'DefaultUitableFontname', Aes.uiFontName, ...
        'DefaultUitableFontunits', 'pixels',...
        'DefaultUitableFontsize', Aes.uiFontSize ...
        }, ...
        2,[] ...
        );
      for ipar = 1:size(fPar,2)
        overrideIdx = strcmpi(fPar{1,ipar},defaultFigParams(1,:));
        if ~any(overrideIdx), continue; end
        defaultFigParams{2,overrideIdx} = fPar{2,ipar};
      end
      
      
      fig = figure(defaultFigParams{:},'Visible', 'off');
      ax = axes(fig);
      hLines = gobjects(numel(data),obj.MaxDeviceCount);
      
      if p.Results.colorized
        colors = parula(numel(data));
      else
        colors = gray(fix(numel(data)*1.35));
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
          hLines(i,d) = line(ax, ...
            'Xdata',data(i).x{d}, ...
            'Ydata',data(i).y{d}, ...
            'DisplayName', sprintf('%s-%s',indStrings,thisDevName), ...
            'color', brighten(colors(i,:),(d-1)/(2*thisDevCount)), ...
            'linewidth', 1.5, ...
            'hittest', 'on', ...
            'ButtonDownFcn', @lineClicked ...
            );
        end
      end
      
      if p.Results.legend
        legend(ax);
      end
      
      fig.Visible = 'on';
      %drawnow;
      
      handles = struct('Figure', handle(fig), 'Axes', handle(ax), 'Lines', hLines);
      
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
    
  end
  
  %% GET Methods
  
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
          @IrisData.unknownCell2Str, ...
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
        fn = string(arrayfun(@obj.getFileFromIndex, index, 'unif', 0));
        return
      end
      keys = obj.Membership.keys();
      vals = obj.Membership.values(keys);
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
    
    function grps = getAllPossibleProps(obj)
      %  GETALLPOSSIBLEPROPS Collect properties from data display, protocol and base
      %  information.
      grps = obj.Specs.Table.Properties.VariableNames; 
    end
    
    function ogIndex = getOriginalIndex(obj,index)
      % GETORIGINALINDEX Returns the original epoch index given the input index or
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
      if nargin < 2, inclusions = true(obj.nDatums,1); end
      if length(inclusions) ~= obj.nDatums
        inclusions = obj.InclusionList;
        warning('IrisData:copyData:InclusionLengthError', ...
          'Inclusions input must be the same length as nDatums. Using defaults.' ...
          );
      end
      
      subs = find(inclusions);
      
      data = obj.Data(subs); %#ok
      
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
      % GETDATAMATRIX Collect a nan-padded matrix of all the data vectors for
      % provided devices and subindices.
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
        'x', {cell(1,nDevOut)}, ...
        'y', {cell(1,nDevOut)} ...
        );
      
      % Gather data by device
      for d = 1:nDevOut
        thisInds = obj.DeviceMap(devices{d});
        thisInds = thisInds(inclusions);
        thisInds = thisInds(sortOrder);
        
        % get the lengths of data
        dataLengths(1:nData,1) = struct('x',[],'y',[]);
        for i = 1:length(thisInds)
          if thisInds(i) < 0, continue; end
          xlen = numel(data(i).x{thisInds(i)});
          ylen = numel(data(i).y{thisInds(i)});
          dataLengths(i) = struct('x',xlen,'y',ylen);
        end
        
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
      end
      
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
    
    function groupInfo = determineGroups(cellArray,inclusions)
      % DETERMINEGROUPS Create a grouping vector from cell array input.
      %   DETERMINEGROUPS Expects the input table, or 2-D cell array, to contain only
      %   strings (char arrays) in order to determine grouping vectors. 
      
      if nargin < 2, inclusions = true(size(cellArray,1),1); end
      if numel(inclusions) ~= size(cellArray,1)
        error( ...
          [ ...
            'Inclusion vector must be logical array ', ...
            'with the same length as the input table.' ...
          ] ...
          );
      end
      idNames = sprintfc('ID%d', 1:size(cellArray,2));
      nIDs = length(idNames);
      if istable(cellArray)
        inputTable = cellArray;
        cellArray = table2cell(cellArray);
      else
        inputTable = cell2table( ...
          cellArray, ...
          'VariableNames', sprintfc('Input%d', 1:size(cellArray,2)) ...
          );
      end
      
      idNames = matlab.lang.makeValidName(idNames);
      
      theEmpty = cellfun(@isempty, cellArray);
      if any(theEmpty)
        cellArray(theEmpty) = {'empty'};
      end
      %get classes of each element
      caClass = cellfun(@class, cellArray, 'unif', 0);
      groupVec = zeros(size(cellArray));
      for col = 1:size(cellArray,2)
        [classes,~,groupVec(:,col)] = unique(caClass(:,col), 'stable');
        if length(classes) == 1
          switch classes{1}
            case 'char'
              iterDat = cellArray(:,col);
            otherwise
              iterDat = [cellArray{:,col}];
          end
          [~,~,groupVec(:,col)] = unique(cat(1,iterDat),'stable');
          %simple case, skip to next iteration or end
          continue
        end
        groupVec(theEmpty,col) = 0;
        for c = classes(:)'
          cin = ismember(caClass(:,col), c);
          switch c{1}
            case 'char'
              iterDat = cellArray(cin);
            otherwise
              iterDat = [cellArray{cin}];
          end
          [~,~,g] = unique(iterDat, 'stable');
          groupVec(cin) = groupVec(cin) + g;
        end
      end
      % subset the grouping vector
      groupVec(~inclusions) = [];
      
      % Turn Group Vector into table
      groupTable = table();
      for g = 1:length(idNames)
        groupTable.(idNames{g}) = groupVec(:,g);
      end
      groupTable.Properties.VariableNames = idNames;
      [groupTable,iSort] = unique(groupTable,'rows','stable');
      groupTable = [groupTable,inputTable(iSort,:)];
      groupTable.Combined = rowfun( ...
        @(x)join(x,'::'), ...
        inputTable(iSort,:), ...
        'SeparateInputs', false, ...
        'OutputFormat', 'uniform' ...
        );
      
      
      vecLen = size(groupVec,1);
      nGroups = height(groupTable);
      
      Singular = zeros(vecLen,1);
      posMap = containers.Map(1,false(size(groupVec)));
      for row = 1:height(groupTable)
        % go down each row the table and find where groupVec matches
        tf = false(size(groupVec));
        mapCombs = zeros(1,size(groupVec,2));
        for c = 1:nIDs
          % loop through table columns and find locations of matches to this row
          thisRowColVal = groupTable.(idNames{c})(row);
          tf(:,c) = groupVec(:,c) == thisRowColVal;
          mapCombs(c) = thisRowColVal;
        end
        merged = splitapply(@all,tf,(1:vecLen)');
        Singular(merged) = row;
        posMap(row) = mapCombs;
      end
      
      % Get the counts from the singular vector and append to groupsInfo.Table
      groupTable.Counts = zeros(nGroups,1);
      groupTable.SingularMap = zeros(nGroups,1);
      tblt = tabulate(Singular);
      % tblt appears to arrive sorted, so we have to backwards map the counts to the
      % original location in the table. If everything came in sorted alright, then
      % this is a little bit overkill.
      tabComps = groupTable{:,idNames};
      for i = 1:size(tblt,1)
        matches = splitapply( ...
          @all, ...
          tabComps == posMap(tblt(i,1)), ...
          (1:size(tabComps,1))' ...
          );
        groupTable.Counts(matches) = tblt(i,2);
        groupTable.SingularMap(matches) = tblt(i,1);
      end
      %output
      groupInfo = struct();
      groupInfo.Table = groupTable;
      groupInfo.Singular = Singular;
      % Setup group vector for use with grpstats in the Statistics and machine
      % learning toolbox. 
      groupInfo.Vectors = mat2cell(groupVec, ...
        vecLen,...
        ones(1,size(groupVec,2)) ...
        );
      % Reorganize table
      groupInfo.Table = movevars( ...
        groupInfo.Table, ...
        {'SingularMap','Counts'}, ...
        'After', ...
        idNames{end} ...
        );
    end
    
    function varargout = ValidStrings(testString,allowedStrings)
      % VALIDSTRINGS A modified version of matlab's validstring. VALIDSTRINGS accepts
      % a cellstr and returns up to 2 outputs, a boolean indicated if all strings in
      % testString passed validation (by best partial matching) in allowedStrings and
      % a cellstr containing the validated strings.
      if nargin < 2, allowedStrings = {'none'}; end
      if ~iscell(testString), testString = cellstr(testString); end
      tf = false(length(testString),1);
      for i = 1:length(testString)
        try
          testString{i} = validatestring(testString{i}, allowedStrings);
          tf(i) = true;
        catch
          tf(i) = false;
        end
      end
      tf = all(tf);
      varargout{1} = tf;
      varargout{2} = testString;
    end
    
    function outputString = unknownCell2Str(cellAr,sep)
      % UNKNOWNCELL2STR Convert a cell's contents to a string (char array)
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
            % decided unique here was not preserving the str version of the props.
            % Instead, we will rely on the unique call at the end of the function.
            %uAr = unique(cellAr{I},'stable');
            %uAr = num2cell(uAr);
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
            strNow = IrisData.unknownCell2Str(cellAr{I});
          case 'struct'
            if length(cellAr{I}) > 1
              error('Structs must be scalar.');
            else
              fields = fieldnames(cellAr{I});
              vals = struct2cell(cellAr{I});
              valStrings = arrayfun( ...
                @IrisData.unknownCell2Str, ...
                vals, ...
                'UniformOutput', false ...
                );
              strNow = join(join([fields(:),valStrings(:)],':',2),', ');
            end
          otherwise
            error('"%s" Cannot be dealt with currently.', caClass{I});
        end
        strRepresentation{I} = char(strNow);
      end
      % join all the unique strings using the input sep.
      outputString = strjoin(unique(strRepresentation,'stable'),[sep,' ']);
    end
    
    function tableDat = collapseUnique(d,columnAnchor,stringify)
      % COLLAPSEUNIQUE Collapse repeated cell entries as determined by columnAnchor.
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
        tableDat(:,2) = arrayfun(@IrisData.unknownCell2Str,tableDat(:,2),'unif',0);
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
      
      flatCell = IrisData.collapseUnique([fields,values],1,false);
      
      flatCell(:,1) = matlab.lang.makeValidName(flatCell(:,1));
      
      flat = struct();
      for n = 1:size(flatCell,1)
        flat.(flatCell{n,1}) = flatCell{n,2};
      end
    end
    
    function S = subtractBaseline(S,type,npts,ofst)
      % SUBTRACTBASELINE Calculate a constant (or fit) value to subtract from each
      % "y" value in the data struct array, S.
      %   S is modified in place and returned
      
      nData = numel(S);
      doFit = contains(lower(type),'sym');
      [S(1:nData).baselineValues] = deal({});
      if doFit,checkFitWarn(); end
      % check for an existing parpool but don't create one.
      nLiveWorkers = getNumWorkers();
      parfor (d = 1:nData,nLiveWorkers)
        this = S(d);
        ndevs = this.nDevices;
        thisX = [];
        inds=[];
        for v = 1:ndevs
          thisY = this.y{v};
          thisLen = size(thisY,1);
          switch lower(type)
            case 'start'
              inds = (1:npts)+ofst;
            case 'end'
              inds = thisLen-ofst-((npts:-1:1)-1);
            case {'asym','sym'}
              % only collect thisX if needed for fit
              thisX = this.x{v};
              % start
              inds = (1:npts)+ofst;
              if strcmpi(type,'sym')
                % is symetrical, append end
                inds = [inds,thisLen-ofst-((npts:-1:1)-1)]; 
              end
          end
          % validate inds
          inds(inds <= 0) = [];
          inds(inds > thisLen) = [];
          % make sure inds are unique
          inds = unique(inds); %sorted
          
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
              %betas = xfit\smooth(yfit,0.9,'rlowess'); %smooth is super slow here
              betas = xfit\smooth(yfit,50);
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
          this.baselineValues{v} = baselines;
        end
        % reassign
        S(d) = this;
      end
      
      % local function to handle parpool generation
      % In the future, I may have Iris force open the default pool... for now, only
      % use a parpool if it already exists
      function N = getNumWorkers()
        p = gcp('nocreate');
        if isempty(p)
          N=0;
        else
          N=p.NumWorkers;
        end
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
    
    function S = butterFilter(S,type,freqs,ord,devs)
      % butterFilter Perform digital butterworth filtering of the data
      % 'y' value in structs in filtered in place
      % input struct S is expected to be of type returned by IrisData.copyData();
      
      %determine filter parameters
      switch lower(type)
        case 'lowpass'
          ftype = 'low';
          flt = 2*freqs(1);
        case 'landpass'
          ftype = 'bandpass';
          flt = sort(2 .* freqs);
        case 'highpass'
          ftype = 'high';
          flt = 2*max(freqs);
      end
      ButterParam('save');
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
          
          thisY = this.y{v};
          yLen = size(thisY,1);
          
          % get column means for reducing the zero offset artifacts from filtering.
          mu = nanmean(thisY,1);
          
          % find and replace nans with mu
          [rowNans,colNans] = find(isnan(thisY));
          for rc = 1:length(rowNans)
            thisY(rowNans(rc),colNans(rc)) = mu(colNans(rc));
          end
          
          % determine start and end values
          preVal = mean(thisY(1:100,:)-mu(ones(100,1),:));
          postVal = mean(thisY(end-(99:-1:0),:)-mu(ones(100,1),:));
          % subtract the colmeans
          thisY = thisY-mu(ones(yLen,1),:);
          % build filter
          [b,a] = ButterParam(ord,flt./Fs,ftype);
          % pad and filter
          thisY = FiltFiltM(b,a, ...
            [ ...
              preVal(ones(2000,1),:); ... %prepend
              thisY; ... %mu substracted data
              postVal(ones(2000,1),:) ... %append
            ]);
          % add Mu back in
          thisY = thisY(2000 + (1:yLen),:) + mu(ones(yLen,1),:);
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
    
    function A = fastrmField(S, fname)
      % FASTRMFIELD Removes supplied fieldnames from struct and returns struct of same size.
      fn = fieldnames(S);
      % which names to keep
      fKeep = cellfun(@isempty, regexpi(fn,strjoin(fname,'|')));

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
          if strcmp(s(1).subs,'IndexMap')
            subs = unique(squeeze([s(2).subs{:}]));
            if length(subs) > 1
              varargout{1} = arrayfun(@(v)obj.IndexMap(v),subs,'unif',1);
              return
            end
          end
          if strcmp(s(1).subs,'Data') && length(s) > 1
            switch s(2).type
              case '.'
                % obj.Data.prop[s]
                if ~iscell(s(2).subs)
                  subs = cellstr(s(2).subs); 
                else
                  subs = s(2).subs;
                end
                subS(length(subs)) = s(2);
                outputVals = cell(1,length(subs));
                for i = 1:length(subs)
                  subS(i).type = s(2).type;
                  subS(i).subs = subs{i};
                  thisVals = arrayfun( ...
                    @(d)builtin('subsref', d, subS(i)), ...
                    obj.Data, ...
                    'UniformOutput', false ...
                    );
                  if all(cellfun(@isnumeric,thisVals,'unif',1))
                    thisVals = [thisVals{:}];
                  end
                  outputVals{i} = thisVals(:);
                end
                varargout = [outputVals{:}];
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
            
          end
        case '()'
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
            newObj.Meta(~subFilesBool) = [];
            newObj.Data(~subFilesBool) = [];
            newObj.Notes(~subFilesBool) = [];
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
            newObj = fastrmField(newObj,{'UserData'});
            varargout{ss} = IrisData(newObj,ud{:});
          end
          return
      end
      
      varargout = {builtin('subsref', obj, s)};
    end
    
    function obj = subsasgn(obj,s,varargin)
      containsID = cellfun(@(v)isa(v,'IrisData'),varargin,'UniformOutput',true);
      if any(containsID)
        inputObj = varargin(containsID);
        obj = cat(1,obj,inputObj{:});
        return
      end
      % This is a value class so we expect an error here:
      obj = builtin('subsassign',obj,s,varargin{:});
    end
    
    function s = saveobj(obj)
      % SAVEOBJ Save IrisData. 
      %   Make sure you have the class definition on your path before loading the
      %   object.
      
      nFiles = length(obj.Files);
      s = struct();
      s.Meta = obj.Meta;% cell array
      s.Data = cell(1,nFiles); %empty
      s.Notes = cell(1,nFiles);%empty
      for F = 1:nFiles
        fname = obj.Files(F);
        s.Data{F} = obj.subsref(substruct('.','Data','()',fname));
        %s.Data{F} = obj.Data(fname); %see subsref
        s.Notes{F} = obj.subsref(substruct('.','Notes','()',fname));
        %s.Notes{F} = obj.Notes(fname); %see subsref
      end
      s.Files = obj.Files;
      % containers.Map are handle objects, so we need to copy them to prevent
      % mutations from affecting originating objects.
      s.Membership = containers.Map( ...
        obj.Membership.keys(), ...
        obj.Membership.values() ...
        );
      fn = fieldnames(obj.UserData);
      fv = struct2cell(obj.UserData);
      C = [fn,fv]';% matrix{
      C = C(:);%single vector
      s.UserData = C;
    end
    
    function session = saveAsIrisSession(obj,pathname)
      if nargin < 2
        % No pathname was provided, prompt user
        vf = iris.data.validFiles();
        fInfo = vf.getIDFromLabel('Session');
        filterText = { ...
          strjoin(strcat('*.',fInfo.exts),';'), ...
          fInfo.label ...
          };
        fn = fullfile( ...
          iris.pref.Iris.getDefault().UserDirectory, ...
          [datestr(now,'HHMMSS'),fInfo.exts{1}] ...
          );
        pathname = iris.app.Info.putFile( ...
          'Save Iris Session', ...
          filterText, ...
          fn ...
          );
        if isempty(pathname), pathname = fn; end        
      end
      % create a session struct for saving
      session = fastrmField(obj.saveobj(),{'UserData','Membership'});
      % make modifications for session requirements
      session.Files = cellstr(session.Files);
      
      for F = 1:length(session.Files)
        thisData = session.Data{F};
        nEpochs = numel(thisData);
        thisTemplate(nEpochs,1) = struct( ...
          'protocols', {{}}, ...
          'displayProperties', {{}}, ...
          'id', '', ...
          'inclusion', 1, ...
          'responses', struct() ...
          );%#ok
        % populate the template
        responseData = struct();
        for ep = 1:nEpochs
          thisD = thisData(ep);
          
          %populate main props
          thisTemplate(ep).inclusion = 1;
          thisTemplate(ep).id = thisD.id;
          thisTemplate(ep).protocols = thisD.protocols;
          thisTemplate(ep).displayProperties = thisD.displayProperties;
          
          % helper fxn to compute duration
          calcDur = @(y,fs)size(y{:},1)/fs{:};
          % build the response data struct
          responseData.sampleRate = thisD.sampleRate;
          responseData.duration = arrayfun( ...
            calcDur, ...
            thisD.y, ...
            thisD.sampleRate, ...
            'UniformOutput', false ...
            );
          responseData.units = thisD.units;
          responseData.devices = thisD.devices;
          responseData.x = thisD.x;
          responseData.y = thisD.y;
          responseData.stimulusConfiguration = thisD.stimulusConfiguration;
          responseData.deviceConfiguration = thisD.deviceConfiguration;
          % store in template
          thisTemplate(ep).responses = responseData;
        end
        % store and clear the temporary variable
        session.Data{F} = thisTemplate;
        clearvars('thisTemplate');
      end
      
      % save the session
      fprintf('Saving...');
      try
        save(pathname,'session', '-mat','-v7.3');
      catch e
        % catch error so that the session struct can be saved by user.
        fprintf('Could not save session for the following reason:\n\n');
        fprintf('  "%s"\n',e.message);
        return
      end
      fprintf('  Success!\nFile saved at: %s\n',pathname);
    end
    
  end
  
  methods (Static = true)
    
    function obj = loadobj(s)
      % LOADOBJ Load helper to construct IrisData from saved instance.
      if isstruct(s)
        if isfield(s,'UserData')
          ud = s.UserData;
          s = rmfield(s,'UserData');
        else
          ud = {};
        end
        obj = IrisData(s,ud{:});
      else
        obj = s;
      end
    end
    
  end
  
end

