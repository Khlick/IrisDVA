classdef (Abstract) IrisDVA
  %IRISDVA Helper static class for manipulating IrisDVA
  properties (Constant = true)
    VERSION = "1.0";
  end
  
  properties (Access = public, Constant = true)
    OBJECT_ID = 'Obj';
    APP_ID = 'App';
    APP_NAME = 'IrisDVA';
  end
  
  properties (Access = private, Constant = true)
    ALLOW_UPDATE = false; % remove this flag when
  end
  
  methods (Access = public, Static = true)
    
    varargout = start(varargin)
    
    status = update(mlappFile)
    
    appinstalldir = import()
    
    appinstalldir = detach()
    
    v = installedVersion()
    
    tf = isRunning()
    
    tf = isMounted()
    
  end
  
  methods (Access = private, Static = true)
    
    appInfo = info()
    
  end
  
end

