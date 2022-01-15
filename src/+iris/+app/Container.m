classdef (Abstract) Container < handle
  
  events
    didStop
  end
  
  properties (SetAccess = protected)
    handler   iris.data.Handler
    ui        iris.ui.primary
    services  iris.infra.menuServices
    options
    appData struct = struct()
    isStopped
  end
  
  properties (Access = private)
    listeners
  end
  
  methods
    
    %Constructor
    function obj = Container(dataHandler, primaryView, menuService)
      obj.isStopped = false;
      obj.ui = primaryView;
      obj.handler = dataHandler;
      obj.services = menuService;
      obj.listeners = cell(0);
      cName = regexp(class(obj), '(?<=\.?)\w*$', 'match', 'once');
      try
        options = iris.pref.(cName).getDefault();
        
      catch
        options = [];
      end
      obj.options = options;
    end
    
    function delete(obj)
      obj.stop();
    end
    
    function run(obj)
      obj.preRun;
      obj.bind;
      obj.postRun;
    end
    
    function stop(obj)
      if obj.isStopped, return; end
      obj.isStopped = true;
      obj.preStop;
      obj.unbind;
      obj.close;
      obj.postStop;
      notify(obj,'didStop');
    end
    
    function show(obj)
      obj.ui.show();
      obj.ui.focus();
    end
    
    function setappdata(obj,name,val)
      name = matlab.lang.makeValidName(name);
      obj.appData.(name) = val;
    end
    
    function vals = getappdata(obj,varargin)
      names = string(varargin);
      if numel(names) == 0
        vals = obj.appData;
        return
      elseif numel(names) == 1
        try
          vals = obj.appData.(names);
        catch x
          iris.app.Info.showWarning(x.message);
        end
        return
      end
      
      % is array
      vals = arrayfun(@obj.getappdata,names,'UniformOutput',0);
    end
    
    function tf = isAppData(obj,name)
      d = obj.appData;
      tf = isfield(d,name);
    end
    
    function tf = ishandle(obj)
      tf = ~obj.isStopped;
    end
    
  end
  
  methods (Access = protected)
    
    function preRun(obj) %#ok
    end
    
    function postRun(obj) %#ok
    end
    
    function preStop(obj) %#ok
    end
    
    function postStop(obj) %#ok
    end
    
    function close(obj)
      obj.services.shutdown();
      obj.handler.shutdown();
      obj.ui.shutdown();
    end
    
    function bind(obj)
      L = obj.ui;
      obj.addListener(L,'Close',@obj.onUIClose);
    end
    
    function unbind(obj)
      obj.removeAllListeners();
    end
    
    function l = addListener(obj, varargin)
      l = addlistener(varargin{:});
      obj.listeners{end+1} = l;
    end
    
    function removeListener(obj,listener)
      loc = ismember(...
        cellfun(@(l)l.EventName, obj.listeners,'unif',0),...
        listener.EventName);
      if ~any(loc), disp('Listener non-existent'); end
      delete(listener)
      obj.listeners(loc) = [];
    end
    
    function removeAllListeners(obj)
      while ~isempty(obj.listeners)
        delete(obj.listeners{1});
        obj.listeners(1) = [];
      end
    end
    
    function enableListener(obj, listener)
      loc = ismember(...
        cellfun(@(l)l.EventName, obj.listeners, 'UniformOutput',false), ...
        listener ...
        );
      if ~any(loc), disp('Listener non-existent'); end
      obj.listeners{loc}.Enabled = true;
    end
    
    function disableListener(obj,listener)
      loc = ismember(...
        cellfun(@(l)l.EventName, obj.listeners,'UniformOutput',false), ...
        listener ...
        );
      if ~any(loc), disp('Listener non-existent'); end
      obj.listeners{loc}.Enabled = false;
    end
    
    function enableAllListeners(obj)
      for o = 1:length(obj.listeners)
        obj.listeners{o}.Enabled = true;
      end
    end
    
    function disableAllListeners(obj)
      for o = 1:length(obj.listeners)
        obj.listeners{o}.Enabled = false;
      end
    end
    
    function evt = eventsListened(obj)
      evt = cellfun(@(l)l.EventName, obj.listeners,'unif',0);
    end
    
    function lsnr = getListenerByEvent(obj,evt)
      evts = obj.eventsListened;
      evt = validatestring(evt,evts);
      lsnr = obj.listeners(ismember(evts,evt));
    end
    
    function lsnr = getListenersBySource(obj,src)
      srcs = cellfun(@(l)class(l.Source{1}), obj.listeners,'unif',0);
      src = validatestring(src,srcs);
      lsnr = obj.listeners(ismember(srcs,src));
    end
    
    function onUIClose(obj,~,~)
      obj.stop();
      pause(0.1);
    end
    
  end
  
end

