classdef IrisDVAObj < IrisDVAApp
  
  properties
    InputArgList = {'-1'};
  end
  
  methods
    
    function obj = IrisDVAObj(varargin)
      obj = obj@IrisDVAApp();
      obj.InputArgList = varargin;
      obj.startApp();
    end
    
    % override application startup
    function startApp(obj)
      if numel(obj.InputArgList) && strcmpi(obj.InputArgList{1},'-1')
        return
      else
        obj.startApp_catch();
      end
    end
    
    function startApp_catch(obj)
      % Increment the reference count by one and lock the file
      mlock;
      IrisDVAObj.refcount(obj.Increment);
      
      % Verify we are about to execute the correct function - if not we
      % should error and exit now.  We need to make sure the paths are
      % equal using canonical paths.
      existVal = exist(fullfile(pwd,'runIris')); %#ok<EXIST>
      doesShadowExist = existVal >= 2 && existVal <= 6;
      
      pathOne = java.io.File(pwd);
      pathOne = pathOne.getCanonicalPath();
      pathTwo = java.io.File(obj.AppPath{1});
      pathTwo = pathTwo.getCanonicalPath();
      
      if (doesShadowExist && ~pathOne.equals(pathTwo))
        % We are trying to execute the wrong runIris
        errordlg(message('MATLAB:apps:runapp:WrongEntryPoint', 'runIris').getString, ...
          message('MATLAB:apps:runapp:WrongEntryPointTitle').getString);
        appinstall.internal.stopapp([],[],obj)
        return;
      end
      
      % Run the app
      obj.AppHandle = runIris(obj.InputArgList{:});
      
      % add a cleanup object to the application
      obj.attachOncleanupToFigure(obj.AppHandle);
      
    end %startApp_catch
    
    function attachOncleanupToFigure(obj, fig)
      % Setup cleanup code on figure handle using onCleanup object
      cleanupObj = onCleanup(@()appinstall.internal.stopapp([],[],obj));
      appdata = getappdata(fig);
      appfields = fields(appdata);
      found = cellfun(@(x) strcmp(x,'AppCleanupCode'), appfields);
      if(~any(found))
        setappdata(fig, 'AppCleanupCode', cleanupObj);
      end
    end %attachOnCleanupToFigure
    
  end
  
end