classdef (Abstract) validFiles
 %%%%%
 % Iris DVA uses this object to import data or session files. To add new
 % support for a data file, add an entry to the supportedFiles list and
 % make sure the 'reader', function is on the matlab path. 
 %
 % Iris DVA's data handler expects reader functions to return a struct with
 % a generallized structure. See the documentation.
 %%%%%
 
  methods (Access = public, Static = true)
    
    function list = supported(num)
      % Add new array entry when supported file reader becomes available
      list(1) = struct( ...
        'type', 'symphony', ...
        'label', 'Symphony Data File', ...
        'exts', {{'h5'}}, ...
        'reader', 'readSymphonyFile');
      list(2) = struct( ...
        'type', 'session', ...
        'label', 'Iris Session File', ...
        'exts', {{'isf'}}, ...
        'reader', 'sessionReader');
      if nargin < 1
        return
      end
      list = list(num);
    end
    
  end
  
  %% Convenience methods
  methods (Access = public, Static = true)
    
    function tf = isReadable(fileName)
      list = validFiles.supported();
      supportedExtensions = [list.exts];
      
      [~,~,ext] = fileparts(fileName);
      
      tf = ismember(ext, strcat('.',supportedExtensions));
    end
    
    function labels = getLabels()
      labels = {validFiles.supported().label}';
    end
    
    function extensions = getExtensions()
      extensions = {validFiles.supported().exts}';
    end
    
    function  filtStr = getFilterText()
      exts = validFiles.getExtensions();
      extID = cellfun(@(e) strjoin(strcat('*.', e),';'), exts, 'unif', 0);
      extLab = strcat( ...
        validFiles.getLabels(), ...
        ' (', ...
        cellfun(@(e) strjoin(strcat('*.', e),','), exts, 'unif', 0), ...
        ')' ...
        );
      filtStr = [extID,extLab];
    end
    
    function rf = getReadFxnFromFile(fileName)
      [~,~,ext] = fileparts(fileName);
      list = validFiles.supported();
      supportedExtensions = [list.exts];
      loc = find(ismember(strcat('.',supportedExtensions),ext),1,'first');
      rf = list(loc).reader;
    end
    
  end
end

