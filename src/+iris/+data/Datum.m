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
  end
  
  properties (Transient = true)
    index
    nDevices
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
          ndevs = length(devices);
        else
          if isvector(dataStruct(ix).responses.y)
            ndevs = 1;
            devices = {'Device 1'};
          elseif istable(dataStruct(ix).responses.y)
            ndevs = size(dataStruct(ix).responses.y,2);
            devices = dataStruct(ix).responses.y.Properties.VariableNames;
          elseif ismatrix(dataStruct(ix).responses.y)
            ndevs = size(dataStruct(ix).responses.y,2);
            devices = sprintfc('Device %d', 1:ndevs);
          end
        end
        obj(ix).devices = devices;
        obj(ix).nDevices = ndevs;
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
    
    function pCell = getPropsAsCell(obj)
      pCell = [ ...
        {'id', obj.id; 'index', obj.index; 'nDevices', obj.nDevices}; ...
        obj.protocols ...
        ];
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
      d.nDevices = obj.nDevices;
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

