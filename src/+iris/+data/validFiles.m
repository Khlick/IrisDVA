classdef validFiles < handle
%%%%%
% Iris DVA uses this object to import data or session files. To add new
% support for a data file, add an entry to the supportedFiles list and
% make sure the 'reader', function is on the matlab path. 
%
% Iris DVA's data handler expects reader functions to return a struct with
% a generallized structure. See the documentation.
%%%%%
  properties (SetAccess = private, Hidden = true)
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
    %%%
    function labels = getLabels(obj)
      labels = cellfun( ...
        @(s)s.label, ...
        obj.options.Supported.values, ...
        'UniformOutput', false ...
        )';
    end
    %%%
    function extensions = getExtensions(obj)
      extensions = cellfun( ...
        @(s)s.exts, ...
        obj.options.Supported.values, ...
        'UniformOutput', false ...
        )';
    end
    %%%
    function id = getIDFromLabel(obj,desc)
      key = obj.getKeyFromLabel(desc);
      id = obj.options.Supported(key);
    end
    function id = getKeyFromLabel(obj,desc)
      labs = obj.getLabels();
      keys = obj.options.Supported.keys();
      id = keys{contains(lower(labs),lower(desc))};
    end
    %%%
    function  filtStr = getFilterText(obj,includeCombined)
      if nargin < 2, includeCombined = true; end
      exts = obj.getExtensions();
      extID = cellfun(@(e) strjoin(strcat('*.', e),';'), exts, 'unif', 0);
      % create a string for each type
      extLab = obj.getLabels();
      % Create a supported files combining all filters
      if includeCombined
        extID{end+1} = strjoin(extID(1:end),';');
        extLab{end+1} = 'All Supported Files';
      end
      filtStr = [extID,extLab];
    end
    %%% RETRIEVE READERS
    function rf = getReadFxnByLabel(obj,lab)
      key = obj.getKeyFromLabel(lab);
      rf = obj.options.Supported(key).reader;
    end
    %
    function rf = getReadFxnByID(obj,readerID)
      rf = obj.options.Supported(readerID);
    end
    %
    function rf = getReadFxnFromFile(obj,fileName)
      [~,~,ext] = fileparts(fileName);
      % support any case
      ext = strrep(lower(ext),'.','');
      list = cellfun(@(s)s,obj.options.Supported.values,'UniformOutput',1);
      loc = 0;
      for L = 1:numel(list)
        if ismember(ext,list(L).exts)
          loc = L;
          break; 
        end
      end
      if ~loc, iris.app.Info.throwError("Unsupported file type."); end
      rf = list(L).reader;
    end
    
  end
end

