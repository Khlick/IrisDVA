classdef loadShow < iris.ui.UIContainer
  %LOADSHOW A dialog box for displaying while long processes load.
  % Properties that correspond to app components
  events
    shuttingDown
  end
  
  properties (Access = public)
    Spinner      matlab.ui.container.Panel
    LoadingText  matlab.ui.control.Label
  end
  
  properties (Dependent)
    isHidden
  end
  
  %% Public Functions
  methods
    function updatePercent(obj,frac,preText)
      if nargin < 3, preText = 'Loading...'; end
      if obj.isClosed
        obj.rebuild;
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
          
          obj.LoadingText.Text = sprintf('%s (%d%%)',preText,fix(frac*100));
          if frac < 1
            drawnow('update');
            return
          else
            obj.LoadingText.Text = 'Done!';
            drawnow('update');
            pause(1.3);
          end
        case {'char','string'}
          obj.LoadingText.Text = frac;
          obj.focus();
          drawnow('update');
          return
      end
      obj.shutdown;
    end
    
    %override shutdown
    function shutdown(obj)
      if obj.isClosed, return; end
      obj.reset; % always show in the center of the screen
      notify(obj,'shuttingDown');
      shutdown@iris.ui.UIContainer(obj);
    end
    
    function tf = get.isHidden(obj)
      if obj.isClosed, tf = true; return; end
      tf = strcmpi(obj.container.Visible,'off') && ~obj.window.isVisible;
    end
    
    function selfDestruct(obj)
      % required for integration with menuservices
      obj.shutdown;
    end
    
  end
  %% Startup and Callback Methods
  methods (Access = protected)
    % Startup
    function startupFcn(obj,varargin)
      % check version
      v = ver('matlab');
      v = strsplit(v.Version,'.');
      
      % add css to figure
      cssFile = utilities.scriptRead(...
        fullfile( ...
          iris.app.Info.getResourcePath, ...
          'scripts', ...
          {'IrisStyles_0.css','spinner.css'} ...
          ), ...
        false, false, '''');
      cssFile = strjoin(cssFile,' ');
      obj.window.executeJS('var css,spinner,panelNode,panel,pChilds,text;',1);
      iter = 0;
      while true
        try
          
          obj.window.executeJS( ...
            [ ...
            'if (typeof css === ''undefined'') {',...
            'css = document.createElement("style");', ...
            'document.head.appendChild(css);', ...
            '}' ...
            ]);
          obj.window.executeJS(['css.innerHTML = `',cssFile,'`;']);
          
          % add the spinner
          obj.window.executeJS(...
            sprintf(...
            [ ...
            'spinner = document.createElement("div");', ...
            'spinner.id = "gear";', ...
            'spinner.innerHTML = `%s`;' ...
            ], ...
            fileread( ...
            fullfile( ...
            iris.app.Info.getResourcePath, 'icn', 'cog-solid.svg' ...
            ) ...
            )) ...
            );
          [~,id] = mlapptools.getWebElements(obj.Spinner);
          if str2double(v{1}) >= 9 && str2double(v{2}) == 8
            obj.window.executeJS( ...
              sprintf( ...
              [ ...
              'panelNode = dojo.query("[%s = ''%s'']");', ...
              'panelNode.forEach((n,i,a)=>{dojo.style(n,{display: "flex"});});', ...
              'pChilds = dojo.query("> *",panelNode[0]);', ...
              'pChilds.forEach((n,i,a)=>{dojo.style(n,{display: "flex"});});', ...
              '[panel] = pChilds.slice(-1);', ...
              'panel.appendChild(spinner);' ...
              ], ...
              id.ID_attr, id.ID_val ...
              ));
          elseif str2double(v{1}) >= 9 && str2double(v{2}) < 8
            % worked before v2020a
            obj.window.executeJS( ...
              sprintf( ...
              [ ...
              'panel = dojo.query("[%s = ''%s'']")[0].lastChild;', ...
              'panel.appendChild(spinner);' ...
              ], ...
              id.ID_attr, id.ID_val ...
              ));
          else
            obj.window.executeJS( ...
              sprintf( ...
              [ ...
              'panelNode = dojo.query("[%s = ''%s'']");', ...
              'panel = dojo.query(".gbtPanelContent",panelNode[0]);', ...
              'panel[0].appendChild(spinner);' ...
              ], ...
              id.ID_attr, id.ID_val ...
              ) ...
              );
          end
        catch x
          %log this
          iter = iter+1;
          if iter > 20, rethrow(x); end
          pause(0.2);
          continue
        end
        break;
      end
      % setup the typing animation
      try
        [~,labID] = mlapptools.getWebElements(obj.LoadingText);
      catch x
        disp(x.message);
      end
      textQuery = sprintf( ...
        'text = dojo.query("[%s = ''%s'']")[0];', ...
        labID.ID_attr, labID.ID_val ...
        );
      iter = 0;
      while true
        try
          obj.window.executeJS(textQuery);
          obj.window.executeJS('text.classList.add("funtext","reflow");');
        catch x
          %log x?
          iter = iter+1;
          if iter > 20, iris.app.Info.throwError(x.message); end
          pause(0.25);
          continue
        end
        %success
        break
      end
    end
    % Construct view
    function createUI(obj)
      import iris.app.Info;
      %% Initialize
      initW = 350;
      initH = 125;
      pos = obj.position;
      if isempty(pos)
        pos = utilities.centerFigPos(initW,initH);
      end
      
      pos(3:4) = [initW,initH];
      
      obj.position = pos; %sets container too
      
      % Setup container
      obj.container.Name = sprintf('%s v%s',Info.name,Info.version('short'));
      
      gridLayout = uigridlayout(obj.container,[5,4]);
      gridLayout.RowHeight = {'1x','1x',64,'1x','1x'};
      % 2x padding on right than on left
      gridLayout.ColumnWidth = {15,64,'fit',15};
      
      % Create Spinner
      obj.Spinner = uipanel(gridLayout);
      obj.Spinner.Layout.Row = 3;
      obj.Spinner.Layout.Column = 2;
      obj.Spinner.AutoResizeChildren = 'off';
      obj.Spinner.BorderType = 'none';
      obj.Spinner.BackgroundColor = [1 1 1];
      
      % Create LoadingText
      obj.LoadingText = uilabel(gridLayout);
      obj.LoadingText.Layout.Row = [2,4];
      obj.LoadingText.Layout.Column = 3;
      obj.LoadingText.FontName = iris.app.Aes.uiFontName;
      obj.LoadingText.FontSize = 28;
      obj.LoadingText.Text = 'Loading...';
      
      drawnow('limitrate');
    end
    
  end
end
