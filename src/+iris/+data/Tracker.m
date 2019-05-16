classdef Tracker < handle
%% TRACKER Keep track of currently selected epochs.
% Having index and currentIndex separate allows a forward facing index to
% be different from the internal index.
  events
    statusChange
  end
  
  properties
    currentIndex
  end
  
  properties (Hidden = true, Access = private, SetObservable = true)
    index
    inclusions
  end
  
  properties (Dependent = true)
    currentDatum
    total
    isready
  end
  
  properties (Hidden=true, Access= private)
    indexListener
    previousChange
  end
  
  methods
    
    function obj = Tracker(inclusions)
      if nargin < 1
        inclusions = [];
      end
      obj.previousChange = struct( ...
        'total', [], ...
        'selected', [], ...
        'inclusions', [] ...
        );
      obj.indexListener = addlistener(obj, ...
        'index', ...
        'PreSet', ...
        @obj.totalChanging ...
        );
      if isempty(inclusions)
        obj.index = [];
        obj.inclusions = [];
        obj.currentIndex = 0;
      else
        obj.index = 1:length(inclusions);
        obj.inclusions = inclusions;
        obj.currentIndex = 1;
      end
    end
    
    function setInclusion(obj,inclusionStruct)
      obj.inclusions(inclusionStruct.selected) = inclusionStruct.inclusion;
      notify(obj,'statusChange', iris.infra.eventData('Inclusions'));
    end
    
    function status = getStatus(obj)
      status = struct( ...
        'total', obj.total, ...
        'current', obj.currentDatum, ...
        'inclusions', obj.inclusions ...
        );
    end
    
    function reset(obj,val)
      if nargin < 2 
        val = [];
      end
      obj.total = val;
      obj.inclusions = true(1,val);
      if isempty(val)
        obj.currentIndex = 0;
      end
    end
       
    function append(obj,numToAppend)
      obj.total = obj.total + numToAppend;
    end
    
    function dropped = cleanup(obj)
      dropped = obj.index(~obj.inclusions);
      obj.total = sum(obj.inclusions);
      obj.inclusions = true(1,obj.total);
    end
    
    %% get/set
    function set.currentIndex(obj,value)
      value = obj.validateIndex(value);
      obj.currentIndex = value;
      notify(obj,'statusChange',iris.infra.eventData('CurrentIndex'));
    end
    
    function tf = get.isready(obj)
      tf = ~~obj.total && ~isempty(obj.inclusions);
    end
    
    function len = get.total(obj)
      len = length(obj.index);
    end
    
    function set.total(obj,newMax)
      % method will shrink or grow index property
      obj.index = 1:newMax;
      if ~obj.currentIndex
        obj.currentIndex = 1;
      else
        curTest = obj.currentIndex <= obj.total;
        obj.currentIndex = obj.currentIndex(curTest);
      end
      obj.inclusions = true(1,obj.total);
      if ~isempty(obj.previousChange.inclusions)
        prev = obj.previousChange;
        obj.inclusions(1:prev.total) = prev.inclusions;
      end
    end
    
    function d = get.currentDatum(obj)
      if ~obj.isready
        error('Tracker not ready.'); 
      end
      d = struct( ...
        'total', obj.total, ...
        'selected', obj.index(obj.currentIndex), ...
        'inclusion', obj.inclusions(obj.currentIndex) ...
        );
    end
    
    
  end
  
  %% callbacks
  methods (Access = private)
    function totalChanging(obj,~,~)
      obj.previousChange = struct( ...
        'total', obj.total, ...
        'selected', obj.currentIndex, ...
        'inclusions', obj.inclusions ...
        );
    end
    
    function ind = validateIndex(obj,value)
      if ~obj.isready
        ind = 0;
        return
      end
      ind = value( ...
        value <= obj.total & value > 0 ...
        );
      if isempty(ind)
        if max(value) > obj.total
          ind = obj.total;
        else
          ind = 1;
        end
      end
    end
  end
  
  %% Handle Overrides
  methods
    
    function varargout = subsref(obj,s)
      switch s(1).type
        case '()'
          if length(s) == 1
            % Implement obj(indices)
            obj.currentIndex = [s.subs{:}];
            varargout{1} = obj.currentDatum;
            return;
          end  
      end
      % Use built-in for any other expression
      [varargout{1:nargout}] = builtin('subsref',obj,s);
      
    end
    
    function obj = subsasgn(obj,s,varargin)
      switch s(1).type
        case '()'
          if length(s) == 1
            % Implement obj(indices) = varargin{:};
            inds = [s.subs{:}];
            
            obj.inclusions(inds) = logical([varargin{:}]);
            return;
         end       
      end
      % Use built-in for any other expression
      obj = builtin('subsasgn',obj,s,varargin{:});
    end
          
    function s = saveobj(obj)
      s = struct();
      s.inclusions = obj.inclusions;
    end
    
  end
end

