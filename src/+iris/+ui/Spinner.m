classdef Spinner < iris.ui.UIContainer
  % Spinner is a modal dialog with the ability to display a message.
  events
    shuttingDown
  end
  
  properties (Access = private)
    SpinBox matlab.ui.control.HTML
    Label   matlab.ui.control.Label
  end
  
  properties (Dependent)
    isHidden
  end
  
  %% Public
  methods
    
    function updatePercent(obj,frac,preText)
      if nargin < 3, preText = 'Loading...'; end
      if obj.isClosed
        obj.rebuild();
        pause(0.01);
      end
      if obj.isHidden
        obj.show();
      else
        obj.focus();
      end
      switch class(frac)
        case 'double'
          if frac > 1
            frac = 1;
          end
          
          obj.Label.Text = sprintf('%s (%d%%)',preText,fix(frac*100));
          if frac < 1
            drawnow('update');
            return;
          else
            obj.Label.Text = 'Done!';
            drawnow('update');
            pause(1.3);
          end
        case {'char','string'}
          obj.focus();
          obj.Label.Text = frac;
          drawnow('update');
          return
      end
      obj.shutdown;
    end %updatePercent
    
    %override shutdown
    function shutdown(obj)
      if obj.isClosed, return; end
      obj.reset; % always show in the center of the screen
      notify(obj,'shuttingDown');
      shutdown@iris.ui.UIContainer(obj);
    end %shutdown
    
    function tf = get.isHidden(obj)
      if obj.isClosed, tf = true; return; end
      tf = strcmpi(obj.container.Visible,'off') && ~obj.window.isVisible;
    end % isHidden
    
    function selfDestruct(obj)
      % required for integration with menuservices
      obj.shutdown;
    end %selfDestruct
    
  end %eom-public
  
  
  %% Construction
  methods (Access=protected)
    
    function startupFcn(obj,varargin) %#ok<INUSD>
      
    end
    
    function createUI(obj)
      %CREATEUI Create the user interface
      
      % import
      import iris.app.Aes
      import iris.app.Info
      import utilities.centerFigPos
      
      % build
      w = 350;
      h = 125;
      pos = obj.position;
      if isempty(pos)
        pos = centerFigPos(w,h);
      end
      
      obj.position = pos;
      
      obj.container.Name = sprintf( ...
        '%s v%s', ...
        Info.name, ...
        Info.version('short') ...
        );
      obj.container.Resize = 'on';
      gridLayout = uigridlayout(obj.container,[3,2]);
      gridLayout.BackgroundColor = obj.container.Color;
      gridLayout.RowHeight = {'1x',64,'1x'};
      gridLayout.ColumnWidth = {64,'fit'};
      gridLayout.ColumnSpacing = 10;
      gridLayout.RowSpacing = 0;
      gridLayout.Padding = [15,10,15,5];
      
      obj.SpinBox = uihtml(gridLayout);
      obj.SpinBox.Layout.Row = 2;
      obj.SpinBox.Layout.Column = 1;
      obj.SpinBox.HTMLSource = fullfile(Info.getResourcePath,"scripts","spin.html");
      
      % Create Label
      obj.Label = uilabel(gridLayout);
      obj.Label.Layout.Column = 2;
      obj.Label.Layout.Row = [1,3];
      obj.Label.FontName = Aes.uiFontName;
      obj.Label.FontSize = 28;
      obj.Label.HorizontalAlignment = "left";
      obj.Label.VerticalAlignment = "center";
      obj.Label.WordWrap = 'on';
      obj.Label.Text = 'Loading...';
      
    end
    
  end %eom-protected
  
end %eoc