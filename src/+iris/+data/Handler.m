classdef Handler < matlab.mixin.Copyable
  %HANDLER Wrapper to maintain control over different data related operations
  events
    fileLoadStatus
    onCompletedLoad
    onSelectionUpdated
  end
  
  properties (SetAccess = private)
    Meta      cell
    Data      
    Notes     cell
    Tracker   iris.data.Tracker
  end
  
  properties (Hidden=true,Access=private)
    fileList  cell
  end
  
  properties (Hidden = true, SetAccess = private)
    membership cell
  end
  
  properties (Dependent)
    currentSelection
    nFiles
    nDatum
    isready
  end
  
  methods
    
    function obj = Handler(files,reader)
      if nargin < 1, return; end
      if nargin < 2, reader = ''; end
      obj.import(files,reader);
    end
    
    function new(obj,files,reader)
      if nargin < 3, reader = ''; end
      if all(ismember(files,obj.fileList)), return; end
      obj.destroy();
      obj.import(files,reader);
    end
    
    function import(obj,files,reader)
      if nargin < 2, reader = ''; end
      [d,f,m,n] = obj.readData(files,reader);
      obj.append(d,f,m,n);
      if obj.Tracker.currentIndex == 0
        obj.Tracker.currentIndex = 1;
      end
      notify(obj, 'onCompletedLoad');
    end
    
    function cleanup(obj)
      drop = obj.Tracker.cleanup();
      obj.Data(drop).delete;% clean from memory first
      obj.Data(drop) = [];
      filesToDrop = cellfun( ...
        @(m) all(ismember(m.data,drop)), ...
        obj.membership, ...
        'UniformOutput', 1 ...
        );
      for d = 1:length(obj.Data)
        obj.Data(d).index = d;
      end
      ofst=0;
      for m = 1:obj.nFiles
        nKept = sum(~ismember(obj.membership{m}.data,drop));
        obj.membership{m}.data = ofst + (1:nKept);
        ofst = nKept;
      end
      
      if any(filesToDrop)
        obj.Meta(filesToDrop) = [];
        noteInds = [obj.membership{filesToDrop}.notes];
        obj.Notes(noteInds,:) = [];
        obj.membership(filesToDrop) = [];
        obj.fileList(filesToDrop) = [];
      end
      
    end
    
    function append(obj,data,files,meta,notes)
      assert( ...
        iscell(data) && iscell(meta) && iscell(notes) && iscell(files), ...
        'data, meta and notes arguments must be cells or cell arrays.' ...
        );
      assert( ...
        (length(data) == length(meta)) && ...
          (length(meta) == length(notes)) && ...
          (length(notes) == length(files)), ...
        'All inputs must be equal length.' ...
        );
      obj.Meta = meta(:);
      for f = 1:length(files)
        ofst = length(obj.Data);
        if ~isempty(obj.Data)
          obj.Data(ofst+(1:length(data{f}))) = iris.data.Datum(data{f},ofst);
        else
          obj.Data = iris.data.Datum(data{f},ofst);
        end
        
        obj.membership{f} = struct( ...
          'data', ofst + (1:length(data{f})), ...
          'notes',size(obj.Notes,1) + (1:size(notes{f},1)) ...
          );
        obj.Notes = cat(1,obj.Notes,notes{f});
        obj.fileList(obj.nFiles+1) = files(f);
      end
      obj.Tracker = iris.data.Tracker();
      obj.Tracker.total = length(obj.Data);
    end
    
    function obj = subset(obj,subs)
      currentInclusions = obj.Tracker.getStatus().inclusions;
      obj.Tracker(:) = 0;
      obj.Tracker(subs) = 1;
      obj.cleanup;
      obj.Tracker(:) = currentInclusions(subs);
      obj.Tracker.currentIndex = 1;
    end
    
    function popped = pop(obj)
      if ~obj.isready, popped = []; return; end
      %pops an entire file
      popped = struct( ...
        'file', obj.fileList{end}, ...
        'Meta', obj.Meta{end}, ...
        'dataIndex', obj.membership{end}.data, ...
        'noteIndex', obj.membership{end}.notes ...
        );
      popped.data = obj(poppped.dataIndex);
      popped.notes = obj.Notes(popped.noteIndex,:);
      popped.tracker = obj.Tracker.getStatus().inclusions(popped.dataIndex);
      % now drop
      obj.fileList(end) = [];
      obj.Meta(end) = [];
      obj.Notes(popped.noteIndex,:) = [];
      obj.membership(end) = [];
    end
    
    function h = copySubs(obj,subs)
      h = copy(obj); % Data property is blank
      % use subset method to reduce the new handler
      h.subset(subs);
      % copy the actual data to the handler copy.
      h.Data = copy(obj.Data(subs));
    end
    
    function cur = getCurrentData(obj)
      selection = obj.currentSelection;
      cur = obj.Data(selection.selected);
    end
    
    function devs = getCurrentDevices(obj)
      d = obj.getCurrentData();
      devs = unique(cat(2,d.devices));
    end
    
    function toggleInclusion(obj,inds)
      status = obj.Tracker.getStatus;
      obj.Tracker.setInclusion( ...
        struct('selected', inds, 'inclusion',~status.inclusions(inds)) ...
        );
    end
    
    function setInclusion(obj, inds, vals)
      obj.Tracker.setInclusion( ...
        struct('selected', inds, 'inclusion', logical(vals)) ...
        );
    end
    
    function sts = status(obj)
      sts = obj.Tracker.getStatus;
    end
    
    function v = getScale(obj,scaleType,device)
      if nargin < 3, device = ''; end
      % create function to compute scalar scale
      switch scaleType
        case 'Absolute Max'
          func = @(matx)max(abs(matx),[],'all','omitnan');
        case 'Max'
          func = @(matx)max(matx,[],'all','omitnan');
        case 'Min'
          func = @(matx)min(matx,[],'all','omitnan');
        case 'Select'
          disp('Select feature coming soon');
          v = [];
          return;
        otherwise
          v = [];
          return;
      end
      % devices
      if isempty(device)
        device = obj.getCurrentDevices();
        device = string(device(1));
      else
        device = string(validatestring(device, obj.getCurrentDevices));
      end
      % data
      dat = obj.getCurrentData();
      sizes = dat.getDataLengths(device);
      dataMat = nan(max(cat(2,sizes{:})),length(dat));
      ds = dat.getDataByDeviceName(device);
      for I = 1:length(dat)
        dataMat(1:sizes{I},I) = ds(I).y(:);
      end
      v = func(dataMat);
    end
    
    function fields = getGroupingFields(obj)
      dat = obj.getCurrentData();
      pCell = dat.getPropsAsCell;
      fields = [{'DataFile'};pCell(:,1)];
    end
    
    function fileName = getParentFile(obj,index)
      loc = cellfun(@(dd)any(ismember(index,dd.data)),obj.membership,'UniformOutput',1);
      fileName = string(obj.fileList(loc));
    end
    
    function tab = getCurrentPropTable(obj)
      dat = obj.getCurrentData();
      tab = dat.getPropTable();
    end
    
    function dat = getSummarizedData(obj)
      prefs = iris.pref.statistics.getDefault();
      % calculate summarized data and create Datum array from the results
    end
    
    function iData = exportCurrent(obj)
      % This method returns an irisData class object
      % This will be used to send data to analysis scripts
    end
    
  end
  
  methods
    %% GET/SET
    function tf = get.isready(obj)
      tf = ~isempty(obj.Data) && ~isempty(obj.fileList) && obj.Tracker.isready;
    end
    function n = get.nFiles(obj)
      n = length(obj.fileList);
    end
    function n = get.nDatum(obj)
      n = length(obj.Data);
    end
    function sel = get.currentSelection(obj)
      sel = obj.Tracker.currentDatum;
    end
    function set.currentSelection(obj,inds)
      if isequal(obj.Tracker.currentIndex(:),inds(:))
        return;
      end
      obj.Tracker.currentIndex = inds;
      notify(obj,'onSelectionUpdated');
    end
        
    %% Handle Overrides
    function varargout = subsref(obj,s)
      switch s(1).type
        case '()'
          if length(s) == 1
            % Implement obj(indices)
            [varargout{1:nargout}] = builtin('subsref',obj.Data,s);
            return;
          elseif length(s) == 2 && strcmp(s(2).type,'.')
            % Implement obj(ind).PropertyName
            
            inds = s(1).subs{1};
            if strcmpi(inds, ':')
              inds = 1:obj.nDatum;
            end
            
            n = length(inds);
            
            vals = cell(1,n);
            for k = 1:n
              vals{k} = obj.Data(inds(k)).(s(2).subs);
            end
            [varargout{1:n}] = vals{:};
            return;
          else
            %expecting to get properties of data, let's collect it first
            d = builtin('subsref',obj.Data,s(1));
            [varargout{1:nargout}] = builtin('subsref',d,s(2:end));
            return;
          end
          
      end
      % Use built-in for any other expression
      [varargout{1:nargout}] = builtin('subsref',obj,s);
    end
    
  end
  
  %% Private methods
  methods (Access = private)
    
    function destroy(obj)
      try %#ok
        obj.Data.delete();
      end
      obj.Data = [];
      obj.Meta = {};
      obj.fileList = {};
      obj.Tracker = iris.data.Tracker();
      obj.Notes = {};
      obj.membership = {};
    end
    
    function [d,fl,m,n] = readData(obj,files,reader)
      if ~iscell(files)
        files = cellstr(files);
      end
      if ~iscell(reader)
        reader = cellstr(reader);
      end
      if length(reader) ~= length(files)
        reader = rep(reader,length(files));
      end
      
      
      validFiles = iris.data.validFiles;
      %
      nf = length(files);
      m = cell(nf,1);
      n = cell(nf,1);
      d = cell(nf,1);
      % track skipped
      skipped = cell(nf,2);
      for f = 1:nf
        notify(obj, 'fileLoadStatus', iris.infra.eventData((f-1)/nf));
        if isempty(reader{f})
          reader{f} = validFiles.getReadFxnFromFile(files{f});
        end
        try 
          [d{f},m{f},n{f}] = feval(reader{f},files{f});
        catch er
          skipped{f,1} = files{f};
          skipped{f,2} = er.message;
        end
      end
      notify(obj, 'fileLoadStatus', iris.infra.eventData(f/nf));
      
      emptySlots = cellfun(@isempty,d,'unif',1);
      skipped = skipped(emptySlots,:);
      if ~isempty(skipped)
        fprintf('\nThe Following files were skipped:\n');
        for ss = 1:size(skipped,1)
          fprintf('  File: "%s"\n    For reason: "%s".\n', skipped{ss,:});
        end
      end
      d = d(~emptySlots);
      m = m(~emptySlots);
      n = n(~emptySlots);
      fl = files(~emptySlots);
    end
    
  end
  
  methods (Access = protected)
    
    function d = copyElement(obj)
      % copy handler using blank datum
      d = iris.data.Handler();
      d.Meta = obj.Meta;
      d.Tracker = obj.Tracker;
      blankData = iris.data.Datum();
      d.Data = repmat(copy(blankData),obj.nDatum,1);
      d.fileList = obj.fileList;
      d.Notes = obj.Notes;
      d.membership = obj.membership;
    end
    
  end
  
  methods
    
    function s = saveobj(obj)
      % implementing a save process to create session files
      % no loadobj method will be implemented as we want to import the
      % saved objects through a separate reader.
      s = struct();
      s.Meta = obj.Meta;
      s.Data = cell(obj.nFiles,1);
      s.Notes = cell(obj.nFiles,1);
      for F = 1:obj.nFiles
        mbrs = obj.membership{F};
        s.Data{F} = obj.Data(mbrs.data).saveobj;
        s.Notes{F} = obj.Notes(mbrs.noes,:);
      end
      s.Files = obj.fileList;
      
    end
    
  end
  
  
end%eoc

