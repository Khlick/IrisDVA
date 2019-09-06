classdef busyShow < iris.ui.JContainer
  %BUSYSHOW Display a borderless splash screen, typically used for opening the app.
  properties (SetAccess = protected,Hidden)
    iAx
    bp
    logo
  end
  
  properties (Access=protected)
    isWaiting@logical = true;
  end
  
  properties (SetObservable=true)
    backgroundColor@cell = {0,0,0};
    logoDim = [100,100];
  end
  
  methods (Access = protected)
    
    function startupFcn(obj)%#ok
    end
    function createUI(obj)
      import iris.ui.*;
      import iris.infra.*;
      import iris.app.*;
      
      obj.position = centerFigPos(170-16,215-39);
      
      set(obj.container, ...
        'Name', 'Loading...',...
        'Units', 'pixels',...
        'resize', 'off',...
        'color', cell2mat(obj.backgroundColor));
      
      %busy presenter
      ic = javaMethodEDT('values', ...
        'com.mathworks.widgets.BusyAffordance$AffordanceSize');
      obj.iAx = com.mathworks.widgets.BusyAffordance(ic(2), 'Loading...');
      obj.iAx.setPaintsWhenStopped(true);
      
      [obj.bp.j, obj.bp.c] = javacomponent(obj.iAx.getComponent, ...
        [0,0,170,80], obj.container);
      obj.bp.j.setBackground(java.awt.Color(obj.backgroundColor{:}));
      
      logoData = imread(fullfile(Info.getResourcePath,'img','Iris100px.png'));
      obj.logoDim = size(logoData);
      
      obj.logo = axes(obj.container,...
        'units', 'pixels',...
        'box', 'off',...
        'visible', 'off');
      obj.logo.YAxis.Direction = 'reverse';
      obj.logo.Position = obj.centerLogo(obj.logoDim);
      obj.logo.XLim = [0,obj.logoDim(1)];
      obj.logo.YLim = [0,obj.logoDim(2)];
      obj.logo.DataAspectRatio = [1,1,1];
      image(obj.logo,...
        'CData', logoData ...
        );
      %imread(fullfile(Info.getResourcePath,'img','logo.jpg'))
      addlistener(obj, 'Close', @obj.doClose);
      addlistener(obj, 'logoDim', 'PostSet', @obj.setLogoPos);
      addlistener(obj, 'backgroundColor', 'PostSet', @obj.setColor);
    end
  end
  
  methods (Access = public)
    
    function start(obj,txt)
      if nargin < 2, txt = 'Loading...'; end
      persistent iter
      if isempty(iter), iter = 0; end
      iter = iter+1;
      import iris.app.*;
      obj.iAx.setBusyText(txt);
      obj.iAx.start;
      drawnow;
      obj.show;
    end
    
    function stop(obj,txt,del)
      if nargin < 2, txt = 'Done!';end
      if nargin < 3, del = 1; end
      obj.iAx.stop;
      obj.iAx.setBusyText(txt);
      pause(del)
      obj.hide;
    end
    
    function setText(obj,txt)
      obj.iAx.setBusyText(txt);
      %drawnow();
    end
    
    function show(obj)
      show@iris.ui.JContainer(obj);
      undecorateFig(obj.container);
      obj.isWaiting = false;
    end
    function hide(obj)
      redecorateFig(obj.container);
      hide@iris.ui.JContainer(obj);
      obj.setText('');
      obj.isWaiting = true;
    end
    function doClose(obj,~,~)
      if ~obj.isWaiting
        obj.stop;
      end
      delete(obj);
    end
    function selfDestruct(obj)
      % required for integration with menuservices
      obj.doClose([],[]);
    end
  end
  
  methods (Access = private)
    function setLogoPos(obj, ~,~)
      obj.logo.Position = obj.centerLogo(obj.logoDim);
      obj.setMany({'logo'}, ...
        {'XLim', 'YLim'}, ...
        {[0,obj.logoDim(1)],[0,obj.logoDim(2)]});
    end
    function setColor(obj,~,~)
      obj.bp.j.setBackground(java.awt.Color(obj.backgroundColor{:}));
      set(obj.container, 'color', cell2mat(obj.backgroundColor));
    end
  end
  
  methods (Hidden)
    function pos = centerLogo(obj,dim)
      figDim = obj.position(3:4);
      x = [(figDim(1)-dim(1))/2+8, dim(1)];
      y = [obj.bp.c.Position(4),dim(2)];
      pos = reshape([x;y],1,4);
    end
  end
end
