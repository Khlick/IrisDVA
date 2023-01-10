classdef Handler < matlab.mixin.Copyable
  %HANDLER Wrapper to maintain control over different data related operations
  events
    fileLoadStatus
    onCompletedLoad
    onSelectionUpdated
    handlerModified
  end

  properties (SetAccess = private)
    Meta cell
    Data
    Notes cell
    Tracker iris.data.Tracker
  end

  properties (Hidden = true, Access = private)
    fileList string
    rootList string
  end

  properties (Hidden = true, SetAccess = private)
    membership cell
    fileMap
  end

  properties (Dependent)
    currentSelection
    FileNames
    nFiles
    nDatum
    isready
  end

  methods

    function obj = Handler(files, reader)
      if nargin < 1, return; end
      if nargin < 2, reader = ''; end
      obj.import(files, reader);
    end

  end

  %% Manipulation of datafiles
  methods (Access = public)

    function new(obj, files, reader)
      % NEW Flush currently open files and load data from new file(s).
      if nargin < 3, reader = ''; end
      if all(ismember(files, obj.fileList)), return; end
      obj.destroy();
      obj.import(files, reader);
    end

    function import(obj, files, reader)
      % IMPORT Read new files and append them onto the current data object.
      if nargin < 2, reader = ''; end
      [d, f, m, n] = obj.readData(files, reader);
      obj.append(d, f, m, n);

      if obj.Tracker.currentIndex == 0
        obj.Tracker.currentIndex = 1;
      end

      notify(obj, 'onCompletedLoad');
    end

    function cleanup(obj)
      % CLEANUP Remove any datums marked as "not included".
      % TODO: Reevaluation of membership causes issue with Notes indices
      drop = obj.Tracker.cleanup();
      if isempty(drop), return; end
      obj.Data(drop) = [];

      filesToDrop = cellfun( ...
        @(m) all(ismember(m.data, drop)), ...
        obj.membership, ...
        'UniformOutput', 1 ...
        );

      % reevaluate indices
      for d = 1:length(obj.Data)
        obj.Data(d).index = d;
      end

      % reevaluate membership
      ofst = 0;
      nOfst = 0;

      for m = 1:obj.nFiles
        nKept = sum(~ismember(obj.membership{m}.data, drop));
        obj.membership{m}.data = ofst + (1:nKept);
        ofst = nKept;
        % if keeping any datums, reassign notes based on offset
        % otherwise, the next step will remove notes from the data
        if nKept > 0
          nNotes = numel(obj.membership{m}.notes);
          obj.membership{m}.notes = nOfst + (1:nNotes);
          nOfst = nOfst + nNotes;
        end

        obj.fileMap(obj.fileList{obj.membership{m}.File}) = obj.membership{m};
      end

      % reevaluate Meta, Notes and Files
      if any(filesToDrop)
        fl = obj.fileList;
        fl = cellstr(fl);
        remove(obj.fileMap, fl(filesToDrop));
        obj.Meta(filesToDrop) = [];
        noteInds = [obj.membership{filesToDrop}];
        noteInds = [noteInds.notes];
        obj.Notes(noteInds, :) = [];
        obj.membership(filesToDrop) = [];
        obj.fileList(filesToDrop) = [];
      end

    end

    function append(obj, data, files, meta, notes)
      % APPEND Append parsed data onto existing object.
      assert( ...
        iscell(data) && iscell(meta) && iscell(notes) && (iscell(files) || isstring(files)), ...
        'data, meta and notes arguments must be cells or cell arrays.' ...
        );
      assert( ...
        (length(data) == length(meta)) && ...
        (length(meta) == length(notes)) && ...
        (length(notes) == length(files)), ...
        'All inputs must be equal length.' ...
        );

      % once we are good, begin parsing contents
      import utilities.*; % utility library

      % setup memberships
      fmap = containers.Map('KeyType', 'char', 'ValueType', 'any');

      % merge duplicate file entries, in the event that a single caller loaded
      % multiple arrays.

      for f = 1:length(files)
        IDX = obj.nFiles + 1;

        thisMembership = struct();

        % Metainformation
        thisMeta = meta{f}; %first unpack in case nested

        if iscell(thisMeta)
          %unpack
          thisMeta = [thisMeta{:}];
        end

        if isempty(obj.Meta)
          combinedMeta = {uniqueContents({thisMeta})};
        else
          combinedMeta = uniqueContents([obj.Meta, thisMeta]);
          if ~iscell(combinedMeta), combinedMeta = {combinedMeta}; end
        end

        obj.Meta = combinedMeta;
        thisMembership.Meta = numel(obj.Meta);

        % Data
        ofst = length(obj.Data);
        newDataLength = length(data{f});

        if isempty(obj.Data)
          obj.Data = iris.data.Datum(data{f}, ofst);
        else
          obj.Data(ofst + (1:newDataLength)) = iris.data.Datum(data{f}, ofst);
        end

        thisMembership.data = ofst + (1:newDataLength);

        % Notes
        thisNote = notes{f};
        % make sure we didn't get some nested note (possibley sv1 reader issue)
        if size(thisNote, 2) ~= 2
          thisNote = cat(1, thisNote{:});
        end

        % clear empty rows
        thisNote(cellfun(@isempty, thisNote(:, 1), 'unif', 1), :) = [];
        % replace file contents
        if ~any(contains(thisNote(:, 2), files(f)))
          hasFile = contains(thisNote(:, 1), 'File:');
          thisNote(hasFile, :) = [];
          thisNote = [[{'File:'}, files(f)]; thisNote]; %#ok
        end

        if isempty(obj.Notes)
          obj.Notes = thisNote;
          thisMembership.notes = 1:size(thisNote, 1);
        else
          existingNotes = obj.Notes;
          newNoteFileIdx = contains(thisNote(:, 1), 'File:');
          newNoteContent = thisNote(~newNoteFileIdx, :);
          % intersect the notes
          [a, b] = ismember(existingNotes(:, 1), newNoteContent(:, 1));
          newNoteContent(b(b ~= 0), :) = [];

          if isempty(newNoteContent) && any(a)
            % has overlapping notes, append this file name to the existing file name
            fileLoc = find(a, 1, 'first') - 1;
            existingNotes{fileLoc, 2} = strjoin([existingNotes(fileLoc, 2), files{f}], ';');
            thisMembership.notes = [fileLoc, find(a)'];
            obj.Notes = existingNotes;
          elseif isempty(newNoteContent)
            % new notes are simply empty
            existingNotes(end+1, 1:2) = thisNote(1,:); %#ok<AGROW>
            thisMembership.notes = size(existingNotes);
            obj.Notes = existingNotes;
          else
            newNote = [thisNote(newNoteFileIdx, :); newNoteContent];
            newNoteLen = size(newNote, 1);
            obj.Notes = [existingNotes; newNote];
            thisMembership.notes = (1:newNoteLen) + size(existingNotes, 1);
          end

        end

        % append file to list, which will update obj.nFiles
        [thisRoot, thisFile, thisExt] = fileparts(char(files(f)));

        obj.fileList{IDX} = [thisFile, thisExt];
        obj.rootList{IDX} = thisRoot;
        thisMembership.File = IDX;

        % Membership
        obj.membership{IDX} = thisMembership;
        fmap([thisFile, thisExt]) = thisMembership;
        pause(0.001);
      end

      obj.Tracker = iris.data.Tracker(obj.Data.getInclusion);
      obj.fileMap = [obj.fileMap; fmap];
    end

    function obj = subset(obj, subs)
      % SUBSET Reduce the current data object to desired subset indices.
      subs = unique(subs);
      if numel(subs) == obj.nDatum
        return
      end
      currentInclusions = obj.Tracker.getStatus().inclusions;
      obj.Tracker(:) = 0;
      obj.Tracker(subs) = 1;
      obj.cleanup();
      obj.Tracker(:) = currentInclusions(subs);
      obj.Tracker.currentIndex = 1;
      notify(obj, 'handlerModified');
    end

    function popped = pop(obj)
      % POP Remove and return a struct of the end-most file on record.
      if ~obj.isready, popped = []; return; end
      %pops an entire file
      popped = struct( ...
        'file', obj.fileList{end}, ...
        'Meta', obj.Meta{end}, ...
        'dataIndex', obj.membership{end}.data, ...
        'noteIndex', obj.membership{end}.Notes ...
        );
      popped.data = obj(poppped.dataIndex);
      popped.notes = obj.Notes(popped.noteIndex, :);
      popped.tracker = obj.Tracker.getStatus().inclusions(popped.dataIndex);
      % now drop
      obj.fileList(end) = [];
      obj.Meta(end) = [];
      obj.Notes(popped.noteIndex, :) = [];
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
      fields = [{'DataFile'}; pCell(:, 1)];
    end

    function tab = getCurrentPropTable(obj)
      dat = obj.getCurrentData();
      tab = dat.getPropTable();
    end

    function fileName = getParentFile(obj, index)
      loc = cellfun(@(dd)any(ismember(index, dd.data)), obj.membership, 'UniformOutput', 1);
      fileName = string(obj.fileList(loc));
    end

    function map = getParentMap(obj, indices)

      if nargin < 2
        indices = 1:obj.nDatum;
      end

      subsParents = obj.getParentFile(indices);
      map = containers.Map();

      for i = 1:length(subsParents)
        pos = ismember(obj.fileList, subsParents(i));
        mbr = obj.membership{pos};
        mbr.data = intersect(mbr.data, indices);
        map(subsParents(i)) = mbr;
      end

    end

    function props = getCurrentDisplayProps(obj, collapse)
      if nargin < 2, collapse = true; end
      d = obj.getCurrentData();
      props = d.getDisplayProps(collapse);
    end

  end

  %% Collect meta for all data
  methods (Access = public)

    function devs = getAllDevices(obj)
      d = obj.Data;
      devs = unique(cat(2, d.devices)); %sorted
    end

    function fields = getAllGroupingFields(obj)
      dat = obj.Data;
      pCell = dat.getPropsAsCell;
      fields = [{'DataFile'}; pCell(:, 1)];
    end

    function tab = getAllPropTable(obj)
      dat = obj.Data;
      tab = dat.getPropTable();
    end

  end

  %% Summary of Datums
  methods (Access = public)

    function v = getScale(obj, scaleType, device)
      if nargin < 3, device = ''; end
      % create function to compute scalar scale
      switch scaleType
        case 'Absolute Max'
          func = @(matx)utilities.AbsMax(matx, 'all');
        case 'Max'
          func = @(matx)max(matx, [], 'all', 'omitnan');
        case 'Min'
          func = @(matx)min(matx, [], 'all', 'omitnan');
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
      dataMat = nan(max(cat(2, sizes{:})), numel(sizes));
      ds = dat.getDataByDeviceName(device);

      for I = 1:numel(sizes)
        dataMat(1:sizes{I}, I) = ds(I).y(:);
      end

      v = func(dataMat);
    end

    %%% Methods for exporting data to IrisData objects
    function iData = export(obj)
      subs = 1:obj.nDatum;
      iData = obj.exportSubs(subs);
    end

    function iData = exportCurrent(obj)
      % EXPORTCURRENT Export IrisData of the currently selected Datums.
      % This method returns an irisData class object
      % This will be used to send data to analysis scripts
      subs = obj.currentSelection.selected;
      iData = obj.exportSubs(subs);
    end

    function iData = exportSubs(obj, subs)
      % exportSubs Export IrisData object of input subscripts.
      %   Though similar to the saveobj, the Data field here is not designed
      %   for import with session reader. The data field here is more like the Datum
      %   class converted directly to a struct. The iData (IrisData) object returned is
      %   constructed from a subset of the handler, thus we first copy the handler,
      %   then subset the copy

      %h = obj.copySubs(subs);
      h = copy(obj);
      h = h.subset(subs);
      % gather saveobj and merge fields into single
      d = h.Data.getDatumsAsStructs();
      d = utilities.fastKeepField(d, ...
        [ ...
        "id","devices","sampleRate","units", ...
        "protocols","displayProperties","stimulusConfiguration", ...
        "deviceConfiguration","inclusion","x","y","index","nDevices" ...
        ] ...
        );
      for idx = 1:numel(d)
        d(idx).id = sprintf("Datum%03d",idx);
      end
      s = h.saveobj();

      % meta
      m = utilities.flattenStructs(s.Meta{:},uniquify=false);
      if isfield(m,'Devices')
        devs = cat(2,m.Devices{:});
        m.Devices = {utilities.getUniqueStructs(devs,'Name')};
      end
      if isfield(m,'Sources')
        src = cat(2,m.Sources{:});
        m.Sources = {utilities.getUniqueStructs(src)};
      end
      fn = fieldnames(m);
      for f = string(fn).'
        if isstruct(m.(f){1})
          ss = cat(2,m.(f){:});
          m.(f) = utilities.getUniqueStructs(ss);
          continue
        end
        if ( ...
            iscell(m.(f)) && ~iscellstr(m.(f){1}) ...
            ) && ~( ...
              any(cellfun(@ischar,m.(f))) || ...
              any(cellfun(@isstring,m.(f))) ...
            )
          m.(f) = [m.(f){:}];
        end
        if isempty(m.(f))
          m.(f) = {''};
        end
        m.(f) = utilities.unknownCell2Str(m.(f),' |',false);
      end
      s.Meta = {m};
      s.Data = {d};
      s.Notes = {cat(1,s.Notes{:})};
      s.Files = strjoin(s.Files," | ");
      
      s.Membership = containers.Map();
      s.Membership(s.Files) = struct( ...
        Meta= 1, ...
        data= 1:numel(d), ...
        notes= 1:size(s.Notes{1},1), ...
        File= 1 ...
        );
      
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

    function list = get.FileNames(obj)
      list = string(obj.fileList);
    end

    function n = get.nDatum(obj)
      n = length(obj.Data);
    end

    function sel = get.currentSelection(obj)
      sel = obj.Tracker.currentDatum;
    end

    function set.currentSelection(obj, inds)

      if isequal(obj.Tracker.currentIndex(:), inds(:))
        return
      end

      obj.Tracker.currentIndex = inds;
      notify(obj, 'onSelectionUpdated');
    end

    function toggleInclusion(obj, inds)

      if nargin < 2
        inds = obj.currentSelection.selected(1);
      end

      status = obj.Tracker.getStatus;
      obj.Tracker.setInclusion( ...
        struct('selected', inds, 'inclusion', ~status.inclusions(inds)) ...
        );
      obj.Data(inds).setInclusion(~status.inclusions(inds));
      notify(obj, 'onSelectionUpdated');
    end

    function setInclusion(obj, inds, vals)
      obj.Tracker.setInclusion( ...
        struct('selected', inds, 'inclusion', logical(vals)) ...
        );
      obj.Data(inds).setInclusion(logical(vals));
      notify(obj, 'onSelectionUpdated');
    end

    function revertToLastView(obj)
      obj.Tracker.revert();
    end

  end

  %% Handle operations
  methods

    function varargout = subsref(obj, s)

      switch s(1).type
        case '()'

          if length(s) == 1
            % Implement obj(indices)
            [varargout{1:nargout}] = builtin('subsref', obj.Data, s);
          elseif length(s) == 2 && strcmp(s(2).type, '.')
            % Implement obj(ind).PropertyName

            inds = s(1).subs{1};

            if strcmpi(inds, ':')
              inds = 1:obj.nDatum;
            end

            n = length(inds);

            vals = cell(1, n);

            for k = 1:n
              vals{k} = obj.Data(inds(k)).(s(2).subs);
            end

            [varargout{1:n}] = vals{:};
          else
            %implement obj(inds1).PropertyName(inds2)
            % this could fail if obj.Data(inds).Prop aren't all arrays of >= inds1
            % length.
            % get data
            d = cell(length(s(1).subs{1}), 1);
            [d{:}] = obj.subsref(s(1:2));
            varargout = cell(size(d));

            for i = 1:length(d)
              varargout{i} = builtin('subsref', d{i}, s(end));
            end

          end

        otherwise
          % Use built-in for any other expression
          [varargout{1:nargout}] = builtin('subsref', obj, s);
      end

    end

    function s = saveobj(obj)
      % implementing a save process to create session files
      % no loadobj method will be implemented as we want to import the
      % saved objects through a separate reader.
      s = struct();
      s.Meta = cell(1, obj.nFiles);
      s.Data = cell(1, obj.nFiles);
      s.Notes = cell(1, obj.nFiles);

      for F = 1:obj.nFiles
        thisFile = obj.fileList{F};
        mbrs = obj.fileMap(thisFile);
        s.Data{F} = obj.Data(mbrs.data).saveobj();
        thisNote = obj.Notes(mbrs.notes, :);
        if contains(thisNote{1,1},'File')
          thisNote{1,2} = char(thisFile);
        end
        s.Notes{F} = thisNote;
        s.Meta{F} = obj.Meta{mbrs.Meta};
      end

      s.Files = obj.fileList;
    end

    function h = copySubs(obj, subs)
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
      d.append(S.Data, S.Files, S.Meta, S.Notes);

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
      obj.fileMap = [];
    end

    function [d, fl, m, n] = readData(obj, files, reader)

      if ~iscell(files)
        files = cellstr(files);
      end

      if ~iscell(reader)
        reader = cellstr(reader);
      end

      if length(reader) ~= length(files)
        % assume reader was a scalar string or cellstr
        reader = utilities.rep(reader, length(files));
      end

      validFiles = iris.data.validFiles;
      %
      nf = length(files);
      m = cell(nf, 1);
      n = cell(nf, 1);
      d = cell(nf, 1);
      fl = cell(nf, 1);
      % track skipped
      [totalDataSize, eachFileSize] = iris.app.Info.getBytes(files);
      accDataRead = 0;
      skipped = cell(nf, 2);
      cu = onCleanup(@()cleanupFx(obj));

      for f = 1:nf
        notify( ...
          obj, 'fileLoadStatus', ...
          iris.infra.eventData(accDataRead / totalDataSize) ...
          );

        if isempty(reader{f})
          reader{f} = validFiles.getReadFxnFromFile(files{f});
        end

        try
          contents = feval(reader{f}, files{f});
          d{f} = contents.Data; % should be cell array of struct array
          m{f} = contents.Meta;
          n{f} = contents.Notes;
          fl{f} = files(f);
        catch er
          skipped{f, 1} = files{f};
          skipped{f, 2} = er.message;
        end

        % accumulate data size, even if skipped
        accDataRead = accDataRead + eachFileSize(f);
      end

      notify( ...
        obj, 'fileLoadStatus', ...
        iris.infra.eventData(accDataRead / totalDataSize) ...
        );

      emptySlots = cellfun(@isempty, d, 'unif', 1);
      skipped = skipped(emptySlots, :);

      if ~isempty(skipped)
        fprintf('\nThe Following files were skipped:\n');

        for ss = 1:size(skipped, 1)
          fprintf('  File: "%s"\n    For reason: "%s".\n', skipped{ss, :});
        end

      end

      % drop skips
      d = d(~emptySlots);
      m = m(~emptySlots);
      n = n(~emptySlots);
      fl = fl(~emptySlots);
      % unpack
      % if d or m or n have multiple entries, let's merge
      internalCounts = cellfun(@numel,d,'UniformOutput',true);
      if sum(internalCounts) > nf
        dIdx = find(internalCounts > 1);
        for dx = dIdx
          d{dx} = cat(2,d{dx}{:});
        end
      end
      d = [d{:}];
      m = [m{:}];
      n = [n{:}];
      fl = [fl{:}];
      % cleanup function
      function cleanupFx(par)
        notify(par, 'fileLoadStatus', iris.infra.eventData('!'));
      end

    end

  end

  methods (Static = true)

    function obj = loadobj(s) %#ok
      e = MException('Iris:Data:Handler:Load', 'Use ISF reader.');
      throw(e);
    end

  end

end %eoc
