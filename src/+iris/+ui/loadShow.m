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
        pause(0.1);
      end
      if obj.isHidden
        obj.show();
      else
        obj.focus();
      end
      
      switch class(frac)
        case 'double'      
          if frac > 1
            exponent = 0;
            fStart = frac;
            while frac > 1
              exponent = exponent-1;
              frac = fStart * 10^exponent;
            end
          end

          obj.LoadingText.Text = sprintf('%s (%d%%)',preText,fix(frac*100));
          if frac < 1
            drawnow('update');
            return;
          else
            obj.LoadingText.Text = 'Done!';
            drawnow('update');
            pause(1.3);
          end
        case 'char'
          obj.LoadingText.Text = frac;
          drawnow('update');
          obj.focus();
          return;
      end
      obj.shutdown;
    end
    
    %override shutdown
    function shutdown(obj)
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
      % add css to figure
      cssFile = scriptRead(...
        {fullfile(iris.app.Info.getResourcePath, ...
          'scripts', 'spinner.css')}, ...
        false, false, '''');
      obj.window.executeJS('var css,spinner,panel,text;',1);
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
          obj.window.executeJS(['css.innerHTML = `',cssFile{1},'`;']);
          
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
          obj.window.executeJS( ...
            sprintf( ...
              [ ...
                'panel = dojo.query("[%s = ''%s'']")[0].lastChild;', ...
                'panel.appendChild(spinner);' ...
              ], ...
              id.ID_attr, id.ID_val ...
            ));
        catch x
          %log this
          iter = iter+1;
          if iter > 20, rethrow(x); end
          pause(0.2);
          continue
        end
        break;
      end
      % setup the ducktyped animation
      [~,labID] = mlapptools.getWebElements(obj.LoadingText);
      textQuery = sprintf( ...
        'text = dojo.query("[%s = ''%s'']")[0];', ...
        labID.ID_attr, labID.ID_val ...
        );
      iter = 0;
      while true
        try
          obj.window.executeJS(textQuery);
          obj.window.executeJS('text.classList.add("funtext");');
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
        pos = centerFigPos(initW,initH);
      end
      
      pos(3:4) = [initW,initH];
      
      obj.position = pos; %sets container too

      % Setup container
      obj.container.Name = sprintf('%s v%s',Info.name,Info.version('short'));

      % Create Spinner
      obj.Spinner = uipanel(obj.container);
      obj.Spinner.AutoResizeChildren = 'off';
      obj.Spinner.BorderType = 'none';
      obj.Spinner.BackgroundColor = [1 1 1];
      obj.Spinner.Position = [25 25 75 75];

      % Create LoadingText
      obj.LoadingText = uilabel(obj.container);
      obj.LoadingText.FontName = iris.app.Aes.uiFontName;
      obj.LoadingText.FontSize = 28;
      obj.LoadingText.Position = [105 45 initW-10-105 35];
      obj.LoadingText.Text = 'Loading...';
    end
    
  end
end