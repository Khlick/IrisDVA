classdef validFiles < handle
%%%%%
% Iris DVA uses this object to import data or session files. To add new
% support for a data file, add an entry to the supportedFiles list and
% make sure the 'reader', function is on the matlab path. 
%
% Iris DVA's data handler expects reader functions to return a struct with
% a generallized structure. See the documentation.
%%%%%
  properties (SetAccess = private)
    options
  end
  
  methods
    
    function obj = validFiles()
      obj.options = iris.pref.validFiles.getDefault();
    end
    
  end
  
%% Convenience methods
  methods
    
    %%%
    
    function appendReader(obj,s)
      obj.options.Supported = s;
    end
    function removeReader(obj,readerID)
      R = obj.options.Supported;
      if ~ismember(readerID,R.keys()), return; end
      % remove method works in-place
      R.remove(readerID);
      
      % set the object into the pref.
      s = cellfun(@(r) r, R.values, 'UniformOutput',1);%to struct array
      names = R.keys();
      [s.name] = names{:};
      % call set
      obj.options.Suppported = s;
    end
    %%%
    function tf = isReadable(obj,fileName)
      list = cellfun(@(s)s,obj.options.Supported.values,'UniformOutput',1);
      
      [~,~,ext] = fileparts(fileName);
      
      tf = ismember(ext, strcat('.',[list.exts]));
    end
    
    function labels = getLabels(obj)
      labels = cellfun( ...
        @(s)s.label, ...
        obj.options.Supported.values, ...
        'UniformOutput', false ...
        )';
    end
    
    function extensions = getExtensions(obj)
      extensions = cellfun( ...
        @(s)s.exts, ...
        obj.options.Supported.values, ...
        'UniformOutput', false ...
        )';
    end
    
    function id = getIDFromLabel(obj,desc)
      labs = obj.getLabels();
      keys = obj.options.Supported.keys();
      id = keys{ismember(labs,desc)};
    end
    
    function  filtStr = getFilterText(obj)
      exts = obj.getExtensions();
      extID = cellfun(@(e) strjoin(strcat('*.', e),';'), exts, 'unif', 0);
      extLab = strcat( ...
        obj.getLabels(), ...
        ' (', ...
        cellfun(@(e) strjoin(strcat('*.', e),','), exts, 'unif', 0), ...
        ')' ...
        );
      filtStr = [extID,extLab];
    end
    %%% RETRIEVE READERS
    function rf = getReadFxnByLabel(obj,lab)
      id = obj.getIDFromLabel(lab);
      rf = obj.options.Supported(id).reader;
    end
    function rf = getReadFxnByID(obj,readerID)
      rf = obj.options.Supported(readerID);
    end
    function rf = getReadFxnFromFile(obj,fileName)
      [~,~,ext] = fileparts(fileName);
      list = cellfun(@(s)s,obj.options.Supported.values,'UniformOutput',1);
      supportedExtensions = [list.exts];
      loc = find(ismember(strcat('.',supportedExtensions),ext),1,'first');
      rf = list(loc).reader;
    end
    
  end
end

