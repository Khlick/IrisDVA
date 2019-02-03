classdef questionBox < iris.ui.JContainer
  
  properties
    response    
    title
    buttonOptions
    question
    default
  end
  
  properties (Hidden = true, Access = protected)
    prompt
    buttons
  end
  
  methods (Access = protected)
    
    function startupFcn(obj,varargin)
      
      addlistener(obj,'Close', @obj.onCloseRequest);
      
      
      obj.show;
      
      defaultMember = ismember( ...
        cellfun(@(x)x.String, ...
          obj.buttons, ...
          'UniformOutput',0 ...
        ), ...
        obj.default ...
        );
      obj.setWindowStyle('modal');
      uicontrol(obj.buttons{defaultMember});
    end
    
    function createUI(obj,varargin)
      import iris.app.Info;
      import iris.infra.*;
      
      ip = inputParser;
      ip.addParameter('Title', 'Question Box', @ischar);
      ip.addParameter('Options', {'Yes', 'No'}, ...
        @(x)validateattributes(x, ...
          {'cell'}, ...
          {'vector'} ...
          ) ...
        );
      ip.addParameter('Prompt', 'Question box prompt.', ...
        @(x)validateattributes(x, ...
          {'char', 'cell'}, ...
          {'nonempty'} ...
          ) ...
        );
      ip.addParameter('Default', '', @ischar);
      
      ip.parse(varargin{:});
      
      opts = unique(ip.Results.Options,'stable');
      nButtons = length(opts);
      if (nButtons < 2) || (nButtons > 5)
        error('Prompt must have between 2 and 5 buttons.');
      end
      
      obj.response = ip.Results.Default;
      
      %%% TODO
      % determine if width needs to be longer.
      %promptSize = length(ip.Results.Prompt);
      
      % always init with the same size
      w = 265;
      h = 115;
      pos = centerFigPos(w,h);
      obj.position = pos;
      set(obj.container, ...
        'Name', ip.Results.Title, ...
        'Units', 'pixels', ...
        'resize', 'off' ...
        );
      
      obj.prompt = uicontrol(obj.container, ...
        'Style', 'text', ...
        'Units', 'pixels', ...
        'Position', [15,h/3*2-7,(w-30),15], ...
        'String', ip.Results.Prompt,  ...
        'FontSize', 10, ...
        'BackgroundColor', [1 1 1] ...
        );
      
      obj.buttons = cell(nButtons,1);
      buttonBounds = (0:nButtons).* (w-30)/nButtons + 15;
      buttonSpace = min(diff(buttonBounds));
      buttonCenters = diff(buttonBounds)./2 + buttonBounds(1:end-1);
      buttonWidth = 0.9*buttonSpace;
      buttonStarts = buttonCenters - buttonWidth/2;
      
      
      for b = 1:nButtons
        button = uicontrol(obj.container, ...
          'Units', 'pixels', ...
          'Position', [buttonStarts(b), 15, buttonWidth, 20], ...
          'String', opts{b}, ...
          'Callback', ...
          @(s,e)obj.onSelectedOption(s,eventData(opts{b})) ...
          );
        obj.buttons{b} = button;
      end
      
      obj.title = ip.Results.Title;
      obj.buttonOptions = opts;
      obj.question = ip.Results.Prompt;
      obj.default = ip.Results.Default;
    end
    
    function onSelectedOption(obj,~,evt)
      obj.response = evt.Data;
      obj.onCloseRequest([],[]);
    end
    
    function onCloseRequest(obj,~,~)
      if isempty(obj.response)
        obj.response = false;
      end
      obj.setWindowStyle('normal');
      obj.reset;
      obj.shutdown;
    end
    
  end
  
end