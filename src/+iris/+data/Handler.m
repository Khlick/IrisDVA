classdef Handler < matlab.mixin.Copyable
  %HANDLER Wrapper to maintain control over different data related operations
  events
    fileLoadStatus
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
      obj.destroy();
      obj.import(files,reader);
    end
    
    function import(obj,files,reader)
      if nargin < 2, reader = ''; end
      [d,f,m,n] = obj.read(files,reader);
      obj.append(d,f,m,n);
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
    
    function cur = getCurrent(obj)
      cur = obj(obj.Tracker.currentDatum.selected);
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
      obj.Tracker.currentIndex = inds;
    end
    
    %% Retreive data for plotting
    
    function [data,layout] = getJSON(obj)
      current = obj.currentSelection;
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INDEV
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
    
    function [d,fl,m,n] = read(obj,files,reader)
      if ~iscell(files)
        files = cellstr(files);
      end
      if ~iscell(reader)
        reader = cellstr(reader);
      end
      if length(reader) ~= length(files)
        reader = rep(reader,length(files));
      end
      % verify files provided aren't already loaded.
      % if the file is already loaded, prompt to overwrite or skip
      
      %
      nf = length(files);
      m = cell(nf,1);
      n = cell(nf,1);
      d = cell(nf,1);
      
      for f = 1:nf
        if ~validFiles.isReadable(files{f}), continue; end
        if isempty(reader{f})
          reader{f} = validFiles.getReadFxnFromFile(files{f});
        end
        try %#ok
          [d{f},m{f},n{f}] = feval(reader{f},files{f});
        end
        notify(obj, 'fileLoadStatus', iris.infra.eventData(f/nf));
      end
      emptySlots = cellfun(@isempty,d,'unif',1);
      d = d(~emptySlots);
      m = m(~emptySlots);
      n = n(~emptySlots);
      fl = files(~emptySlots);
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
    %{
    %dev
    function s = saveobj(obj)
      % implementing a save process to create session files
      % no loadobj method will be implemented as we want to import the
      % saved objects through a separate reader.
      s = struct('Meta', cell(0), 'Tracker', );
    end
    %}
  end
  
  
end%eoc

