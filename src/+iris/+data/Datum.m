classdef Datum < matlab.mixin.Copyable
  
  properties (SetAccess = private)
    id  = '' %name
    devices
    sampleRate
    x
    y
    units
    protocols
    displayProperties
    responseConfiguration
    deviceConfiguration
    inclusion
  end
  
  properties (Transient = true)
    index
  end
  properties (Dependent)
    nDevices
  end
  properties (Transient=true, Dependent=true, Hidden=true)
    plotData
  end
  
  methods
    function obj = Datum(dataStruct,offset)
      if nargin < 1, return; end
      if nargin < 2, offset = 0; end
      validateattributes(dataStruct, {'struct'}, {'2d'});
      N = length(dataStruct);
      %{
      dataStruct should be a Nx1 array of structs of the form:
      dataStruct
        - protocols: Nx2 cell
        - displayProperties: Nx2 cell
        - inclusion: scalar logical (optional)
        - responses: struct
        -- sampleRate: cell, in Hz e.g. {10000, 10000}
        -- duration: cell, in sec e.g. {3, 3} %unused
        -- units: cell, char, e.g. {'mV', 'V'}
        -- devices: cell, char, e.g. {'Axopatch 200b','Temperature Monitor'}
        -- x: cell, vectors e.g {[3000x1 double],[3000x1 double]}
        -- y: cell, vectors e.g {[3000x1 double],[3000x1 double]}
        -- responseConfiguration: struct array
        -- deviceConfiguration: struct array
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
        obj(ix).responseConfiguration = d.responseConfiguration;
        obj(ix).deviceConfiguration = d.deviceConfiguration;
        try 
          obj(ix).sampleRate = d.sampleRate;
        catch
          obj(ix).sampleRate = {1};
        end
      end
      
    end
    
    %%SET/GET
    function set.index(obj,value)
      obj.index = uint64(value);
      if ~regexpi(obj.id, '^Ep[0-9]{1,4}')
        return
      end
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
    
    function n = get.nDevices(obj)
      n = zeros(1,length(obj));
      for I = 1:length(obj)
        n(I) = length(obj(I).devices);
      end
    end
    
    function dat = get.plotData(obj)
      dPrefs = iris.pref.display.getDefault();
      % plotData() cycles through data and creates an object for each device
      dat = iris.data.encode.plotData(obj,dPrefs);
    end
    
    function propC = getProps(obj)
      propC = cell(length(obj),1);
      for o = 1:length(obj)
        propC{o} = [ ...
          { ...
            'id', obj(o).id; ...
            'index', obj(o).index; ...
            'nDevices', obj(o).nDevices; ...
            'devices', sprintf('(%s)',strjoin(obj(o).devices,'|')) ...
          }; ...
          obj(o).protocols ...
          ];
      end
    end
    
    function pCell = getPropsAsCell(obj)
      propC = obj.getProps();
      propC = cat(1,propC{:});
      %uniqueify
      pCell = collapseUnique(propC,1);
    end
    
    function tab = getPropTable(obj)
      % getPropTable 
      % Collect properties for all datums into a table.
      % Each row in the output table will represent 1 datum with the
      % variable names representing all available properties. Empty entries
      % in the table will indicate either an empty value or an unused
      % value. This will allow the table to hold all possible properties
      % while keeping those datums that don't contain a particular
      % property.
      props = obj.getPropsAsCell(); % all possible props
      epochProps = obj.getProps(); % each epoch's props
      propCells = cell(length(obj),size(props,1));
      for I = 1:length(epochProps)
        % find the intersection between the current datum's properties and
        % all properties in the data.
        currentProps = epochProps{I};
        [~,iP,iE] = intersect(props(:,1),currentProps(:,1),'stable');
        % Convert everything to char arrays to prevent differences in the
        % rows from raising errors.
        propCells(I,iP) = arrayfun( ...
          @unknownCell2Str, ...
          currentProps(iE,2), ...
          'UniformOutput', false ...
          )';
        propCells(I,cellfun(@isempty,propCells(I,:),'unif',1)) = {''};
      end
      tab = cell2table(propCells, 'VariableNames', props(:,1)');
    end
    
    function lengths = getDataLengths(obj,device)
      lengths = cell(length(obj),1);
      keeps = boolean(ones(1,length(obj)));
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
    
    function S = getDataByDeviceName(obj,deviceName)
      % preallocate maximum length
      S(length(obj),1) = struct('device', '', 'y', 0.0); 
      keepInds = boolean(ones(1,length(obj)));
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
    
  end
  
  methods (Access = protected)
    
    function d = copyElement(obj)
      d = iris.data.Datum();
      d.id = obj.id;
      d.devices = obj.devices;
      d.sampleRate = obj.sampleRate;
      d.x = obj.x;
      d.y = obj.y;
      d.units = obj.units;
      d.protocols = obj.protocols;
      d.displayProperties = obj.displayProperties;
      d.responseConfiguration = obj.responseConfiguration;
      d.deviceConfiguration = obj.deviceConfiguration;
      d.index = obj.index;
      d.inclusion = obj.inclusion;
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

        r = struct();
        r.sampleRate = o.sampleRate; % cell, in Hz e.g. {10000, 10000}
        r.duration = arrayfun( ...
          @(d,fs) length(d{1})/fs{1}, ...
          o.x,o.sampleRate, ...
          'UniformOutput', false ...
          );% cell, in sec e.g. {3, 3}
        r.units = o.units;% cell, char, e.g. {'mV', 'V'}
        r.devices = o.devices;% cell, char, e.g. {'Axopatch 200b','Temperature Monitor'}
        r.x =  o.x;% cell, vectors e.g {[3000x1 double],[3000x1 double]}
        r.y = o.y;% cell, vectors e.g {[3000x1 double],[3000x1 double]}
        r.responseConfiguration = o.responseConfiguration;% struct array
        r.deviceConfiguration = o.deviceConfiguration;% struct array

        s(d).responses = r;
      end
    end
    
    function d = subsetDevice(obj,include)
      keepIndex = ismember(obj.devices,include);
      if all(keepIndex)
        % send the handle to make it quick and memory efficient
        d = obj;
        return;
      end
      d = iris.data.Datum();
      d.id = obj.id;
      d.devices = obj.devices(keepIndex);
      d.sampleRate = obj.sampleRate(keepIndex);
      d.x = obj.x(keepIndex);
      d.y = obj.y(keepIndex);
      d.units = obj.units(keepIndex);
      d.protocols = obj.protocols;
      d.displayProperties = obj.displayProperties;
      d.responseConfiguration = obj.responseConfiguration;
      d.deviceConfiguration = obj.deviceConfiguration(keepIndex);
      d.index = obj.index;
      d.inclusion = obj.inclusion;
    end
    
    function dat = getPlotArray(obj, varargin)
      p = inputParser;
      p.addParameter('color',[0,0,0], ...
        @(x)validateattributes(x,{'numeric'},{'size',[NaN,3],'>=',0,'<=',1}) ...
        );
      p.parse(varargin{:});
      
      dat = obj.plotData;
      %for I = 1:length(dat)
      %  % Set colors and linewidth?
      %end
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

