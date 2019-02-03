classdef loadShow < iris.ui.UIContainer
  %LOADSHOW A dialog box for displaying while long processes load.
  % Properties that correspond to app components
  properties (Access = public)
    Spinner      matlab.ui.container.Panel
    LoadingText  matlab.ui.control.Label
  end
  
  %% Public Functions
  methods (Access = public)
    
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
      obj.window.executeJS('var css,spinner,panel;');
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
          %obj.window.executeJS('document.head.appendChild(css);');
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
          
      
    end
    % Construct view
    function createUI(obj)
      %% Initialize
      pos = obj.position;
      if isempty(pos)
        initW = 250;
        initH = 125;
        pos = centerFigPos(initW,initH);
      end
      obj.position = pos; %sets container too

      % Setup container
      obj.container.Name = 'Loading...';

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
      obj.LoadingText.Position = [105 45 120 35];
      obj.LoadingText.Text = 'Loading...';
    end
  end
end