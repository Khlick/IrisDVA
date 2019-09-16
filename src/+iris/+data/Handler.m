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
    
  end
  %% Manipulation of datafiles
  methods (Access = public)
    
    function new(obj,files,reader)
      % NEW Flush currently open files and load data from new file(s).
      if nargin < 3, reader = ''; end
      if all(ismember(files,obj.fileList)), return; end
      obj.destroy();
      obj.import(files,reader);
    end
    
    function import(obj,files,reader)
      % IMPORT Read new files and append them onto the current data object.
      if nargin < 2, reader = ''; end
      % read data always output data,filter,meta,n?
      [d,f,m,n] = obj.readData(files,reader);
      obj.append(d,f,m,n);
      if obj.Tracker.currentIndex == 0
        obj.Tracker.currentIndex = 1;
      end
      notify(obj, 'onCompletedLoad');
    end
    
    function cleanup(obj)
      % CLEANUP Remove any datums marked as "not included".
      drop = obj.Tracker.cleanup();
      delete(obj.Data(drop));% clean from memory first
      obj.Data(drop) = [];
      
      filesToDrop = cellfun( ...
        @(m) all(ismember(m.data,drop)), ...
        obj.membership, ...
        'UniformOutput', 1 ...
        );
      
      % reevaluate indices
      for d = 1:length(obj.Data)
        obj.Data(d).index = d;
      end
      % reevaluate membership
      ofst=0;
      nOfst = 0;
      for m = 1:obj.nFiles
        nKept = sum(~ismember(obj.membership{m}.data,drop));
        obj.membership{m}.data = ofst + (1:nKept);
        ofst = nKept;
        % if keeping any datums, reassign notes based on offset
        % otherwise, the next step will remove notes from the data
        if nKept > 0
          nNotes = numel(obj.membership{m}.notes);
          obj.membership{m}.notes = nOfst + (1:nNotes);
          nOfst = nOfst + nNotes;
        end
      end
      % reevaluate Meta, Notes and Files
      if any(filesToDrop)
        obj.Meta(filesToDrop) = [];
        % notes
        noteInds = [obj.membership{filesToDrop}];
        noteInds = [noteInds.notes];
        obj.Notes(noteInds,:) = [];
        obj.membership(filesToDrop) = [];
        obj.fileList(filesToDrop) = [];
      end
      
    end
    
    function append(obj,data,files,meta,notes)
      % APPEND Append parsed data onto existing object.
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
      for f = 1:length(files)
        
        % Metainformation
        thisMeta = meta{f}; %first unpack in case nested
        if iscell(thisMeta)
          %wrap meta into cell
          thisMeta = [thisMeta{:}];
        end
        obj.Meta{end+1} = thisMeta;
        
        % Data
        ofst = length(obj.Data);
        newDataLength = length(data{f});
        if isempty(obj.Data)
          obj.Data = iris.data.Datum(data{f},ofst);
        else
          obj.Data(ofst+(1:newDataLength)) = iris.data.Datum(data{f},ofst);
        end
        
        % Notes
        thisNote = notes{f};
        % make sure we didn't get some nested note (possibley sv1 reader issue)
        if size(thisNote,2) ~= 2
          thisNote = cat(1,thisNote{:});
        end
        % append file for clarity
        if ~any(contains(thisNote(:,2), files(f)))
          thisNote = [[{'File:'},files(f)];thisNote];%#ok
        end
        % clear empty rows
        thisNote(cellfun(@isempty,thisNote(:,1),'unif',1),:) = [];
        
        prevNoteLength = size(obj.Notes,1);
        thisNoteLength = size(thisNote,1);
        % append
        obj.Notes = cat(1,obj.Notes,thisNote);
        
        % append file to list, which will update obj.nFiles
        obj.fileList(obj.nFiles+1) = files(f); 
        
        % Finally, update the membership information
        % Membership
        obj.membership{obj.nFiles} = struct( ...
          'data', ofst + (1:newDataLength), ...
          'notes', prevNoteLength + (1:thisNoteLength) ...
          );
      end
      obj.Tracker = iris.data.Tracker();
      obj.Tracker.total = length(obj.Data);
    end
    
    function obj = subset(obj,subs)
      % SUBSET Reduce the current data object to desired subset indices.
      currentInclusions = obj.Tracker.getStatus().inclusions;
      obj.Tracker(:) = 0;
      obj.Tracker(subs) = 1;
      obj.cleanup();
      obj.Tracker(:) = currentInclusions(subs);
      obj.Tracker.currentIndex = 1;
    end
    
    function popped = pop(obj)
      % POP Remove and return a struct of the end-most file on record.
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
    
    function shutdown(obj)
      if obj.isready
        obj.destroy();
      end
      delete(obj);
    end
    
  end
  %% Collect meta for current selections
  methods (Access = public)
    % each method here has an All counterpart in the next section
    
    function cur = getCurrentData(obj)
      selection = obj.currentSelection;
      cur = obj.Data(selection.selected);
    end
    
    function devs = getCurrentDevices(obj)
      d = obj.getCurrentData();
      devs = d.getDeviceNames();
    end
    
    function sts = status(obj)
      % STATUS Return the current datum tracker status.
      sts = obj.Tracker.getStatus;
    end
    
    function fields = getCurrentGroupingFields(obj)
      dat = obj.getCurrentData();
      pCell = dat.getPropsAsCell;
      fields = [{'DataFile'};pCell(:,1)];
    end
    
    function tab = getCurrentPropTable(obj)
      dat = obj.getCurrentData();
      tab = dat.getPropTable();
    end
    
    function fileName = getParentFile(obj,index)
      loc = cellfun(@(dd)any(ismember(index,dd.data)),obj.membership,'UniformOutput',1);
      fileName = string(obj.fileList(loc));
    end
    
    function map = getParentMap(obj,indices)
      if nargin < 2
        indices = 1:obj.nDatum;
      end
      subsParents = obj.getParentFile(indices);
      map = containers.Map();
      for i = 1:length(subsParents)
        pos = ismember(obj.fileList, subsParents(i));
        mbr = obj.membership{pos};
        mbr.data = intersect(mbr.data,indices);
        map(subsParents(i)) = mbr;
      end
    end
    
    function props = getCurrentDisplayProps(obj,collapse)
      if nargin < 2, collapse = true; end
      d = obj.getCurrentData();
      props = d.getDisplayProps(collapse);
    end
    
  end
  
  %% Collect meta for all data
  methods (Access = public)
    
    function devs = getAllDevices(obj)
      d = obj.Data;
      devs = unique(cat(2,d.devices));%sorted
    end
    
    function fields = getAllGroupingFields(obj)
      dat = obj.Data;
      pCell = dat.getPropsAsCell;
      fields = [{'DataFile'};pCell(:,1)];
    end
    
    function tab = getAllPropTable(obj)
      dat = obj.Data;
      tab = dat.getPropTable();
    end
    
  end
  
  %% Summary of Datums
  methods (Access = public)
    
    function v = getScale(obj,scaleType,device)
      if nargin < 3, device = ''; end
      % create function to compute scalar scale
      switch scaleType
        case 'Absolute Max'
          func = @(matx)AbsMax(matx);
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
    
    %%% Methods for exporting data to IrisData objects
    function iData = export(obj)
      subs = 1:obj.nDatum;
      iData = obj.exportSubs(subs);
    end
    
    function iData = exportCurrent(obj)
      % EXPORTCURRENT Export IrisData of the currently selected epochs.
      % This method returns an irisData class object
      % This will be used to send data to analysis scripts
      subs = obj.currentSelection.selected;
      iData = obj.exportSubs(subs);
    end
    
    function iData = exportSubs(obj,subs)
      % exportSubs Export IrisData object of input subscripts.
      %   Though similar to the saveobj, the Data field here is not designed
      %   for import with session reader. The data field here is more like the Datum
      %   class converted directly to a struct. The iData (IrisData) object returned is
      %   constructed from a subset of the handler, thus we first copy the handler,
      %   then subset the copy
      h = obj.copySubs(subs);
      % reassign datums their original indices
      for i = 1:length(subs)
        h.Data(i).index = subs(i);
      end
      % create a struct from the handler copy
      s = struct();
      s.Meta = h.Meta;% cell array
      s.Data = cell(1,h.nFiles); %empty
      s.Notes = cell(1,h.nFiles);%empty
      for F = 1:h.nFiles
        mbrs = h.membership{F};
        s.Data{F} = h.Data(mbrs.data).getDatumsAsStructs();
        s.Notes{F} = h.Notes(mbrs.notes,:);
      end
      s.Files = h.fileList;
      s.Membership = h.getParentMap();
      s.OrignalIndices = obj.getParentMap(subs);
            
      % create the IrisData Object
      iData = IrisData(s);
    end
    
  end
  
  %% GET/SET
  methods
    
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
    
    function toggleInclusion(obj,inds)
      if nargin < 2
        inds = obj.currentSelection.selected(1);
      end
      status = obj.Tracker.getStatus;
      obj.Tracker.setInclusion( ...
        struct('selected', inds, 'inclusion',~status.inclusions(inds)) ...
        );
      obj.Data(inds).setInclusion(~status.inclusions(inds));
      notify(obj,'onSelectionUpdated');
    end
    
    function setInclusion(obj, inds, vals)
      obj.Tracker.setInclusion( ...
        struct('selected', inds, 'inclusion', logical(vals)) ...
        );
      obj.Data(inds).setInclusion(logical(vals));
      notify(obj,'onSelectionUpdated');
    end
    
    function revertToLastView(obj)
      obj.Tracker.revert();
    end
    
  end
  
  %% Handle operations
  methods
    
    function varargout = subsref(obj,s)
      switch s(1).type
        case '()'
          if length(s) == 1
            % Implement obj(indices)
            [varargout{1:nargout}] = builtin('subsref',obj.Data,s);
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
          else
            %implement obj(inds1).PropertyName(inds2)
            % this could fail if obj.Data(inds).Prop aren't all arrays of >= inds1
            % length.
            % get data
            d = cell(length(s(1).subs{1}),1);
            [d{:}] = obj.subsref(s(1:2));
            varargout = cell(size(d));
            for i = 1:length(d)
              varargout{i} = builtin('subsref', d{i}, s(end));
            end
          end
        otherwise
          % Use built-in for any other expression
          [varargout{1:nargout}] = builtin('subsref',obj,s);
      end
      % spit out all the values
      if length(varargout) >= nargout+1
        varargout{(nargout+1):end} %#ok
      end
    end
    
    function s = saveobj(obj)
      % implementing a save process to create session files
      % no loadobj method will be implemented as we want to import the
      % saved objects through a separate reader.
      s = struct();
      s.Meta = obj.Meta;% cell array
      s.Data = cell(1,obj.nFiles); %empty
      s.Notes = cell(1,obj.nFiles);%empty
      for F = 1:obj.nFiles
        mbrs = obj.membership{F};
        s.Data{F} = obj.Data(mbrs.data).saveobj;
        s.Notes{F} = obj.Notes(mbrs.notes,:);
      end
      s.Files = obj.fileList;
    end
    
    function h = copySubs(obj,subs)
      % make a direct copy of the handler
      h = copy(obj);
      % use subset method to reduce the new handler
      h.subset(subs);
    end
    
  end
  
  methods (Access = protected)
    
    function d = copyElement(obj)
      % copy handler using blank datum
      S = obj.saveobj();
      d = iris.data.Handler();
      d.append(S.Data,S.Files,S.Meta,S.Notes);
      if d.Tracker.currentIndex == 0
        d.Tracker.currentIndex = 1;
      end
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
        % assume reader was a scalar string or cellstr
        reader = rep(reader,length(files));
      end
      
      validFiles = iris.data.validFiles;
      %
      nf = length(files);
      m = cell(nf,1);
      n = cell(nf,1);
      d = cell(nf,1);
      fl = cell(nf,1);
      % track skipped
      [totalDataSize,eachFileSize] = iris.app.Info.getBytes(files);
      accDataRead = 0;
      skipped = cell(nf,2);
      for f = 1:nf
        notify( ...
          obj, 'fileLoadStatus', ...
          iris.infra.eventData(accDataRead/totalDataSize) ...
          );
        if isempty(reader{f})
          reader{f} = validFiles.getReadFxnFromFile(files{f});
        end
        try 
          contents = feval(reader{f},files{f});
          d{f}= contents.Data; % should be cell array of struct array
          m{f}= contents.Meta;
          n{f}= contents.Notes;
          try
            fl{f} = contents.Files;
          catch
            fl{f} = files(f);
          end
        catch er
          skipped{f,1} = files{f};
          skipped{f,2} = er.message;
        end
        % accumulate data size, even if skipped
        accDataRead = accDataRead + eachFileSize(f);
      end
      notify( ...
        obj, 'fileLoadStatus', ...
        iris.infra.eventData(accDataRead/totalDataSize) ...
        );
      
      emptySlots = cellfun(@isempty,d,'unif',1);
      skipped = skipped(emptySlots,:);
      if ~isempty(skipped)
        fprintf('\nThe Following files were skipped:\n');
        for ss = 1:size(skipped,1)
          fprintf('  File: "%s"\n    For reason: "%s".\n', skipped{ss,:});
        end
      end
      % drop skips
      d = d(~emptySlots);
      m = m(~emptySlots);
      n = n(~emptySlots);
      fl = fl(~emptySlots);
      % unpack
      d = [d{:}];
      m = [m{:}];
      n = [n{:}];
      fl = [fl{:}];
    end
    
  end
  methods (Static= true)
    function obj = loadobj(s)
      e = MException('Iris:Data:Handler:Load', 'Use ISF reader.');
      throw(e);
    end
  end
end%eoc

