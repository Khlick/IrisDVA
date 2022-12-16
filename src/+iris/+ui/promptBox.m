classdef promptBox < iris.ui.JContainer
  
  properties
    inputs
    title
    prompts
    promptTitles
    defaults
    validClose=false
  end
  
  properties (Hidden = true, Access = protected)
    nPrompts
    input
    label
    button
    allowDefaults
  end
  
  properties (Dependent)
    halt
    response
  end
  
  methods
    
    function h = get.halt(obj)
      if obj.allowDefaults
        h=false;
        return
      end
      tests = false(1,obj.nPrompts);
      for i = 1:obj.nPrompts
        tests(i) = strcmpi(obj.inputs{i},obj.defaults{i});
      end
      h = any(tests);
    end
    
    function r = get.response(obj)
      if obj.halt || ~obj.validClose, r = []; return; end
      r = struct();
      for i = 1:obj.nPrompts
        r.(obj.promptTitles{i}) = obj.inputs{i};
      end
    end
    
    function selfDestruct(obj)
    % required for integration with menuservices
    obj.onCloseRequest([],[]);
  end
  
    
  end
  
  methods (Access = protected)
    
    function startupFcn(obj,varargin)
      addlistener(obj,'Close', @obj.onCloseRequest);
      obj.show;
      obj.wait();
    end
    
    function createUI(obj,varargin)
      import iris.app.Info;
      import iris.infra.*;
      
      ip = inputParser;
      ip.addParameter('Title', 'Prompt Box', @ischar);
      ip.addParameter('Prompts', {'Input Text:'}, ...
        @(x)validateattributes(x, ...
          {'char', 'cell'}, ...
          {'nonempty','column'} ...
          ) ...
        );
      ip.addParameter('Defaults', {'EnterText'}, ...
        @(x)validateattributes(x, ...
          {'char', 'cell'}, ...
          {'nonempty','column'} ...
          ) ...
        );
      ip.addParameter('Labels', {'Input'}, ...
        @(x)validateattributes(x, ...
          {'char', 'cell'}, ...
          {'nonempty','column'} ...
          ) ...
        );
      ip.addParameter('Camelize', true, @islogical);
      ip.addParameter('Width', 265, ...
        @(v) validateattributes(v,{'numeric'},{'numel',1}) ...
        );
      ip.addParameter('ButtonLabel', 'Go', @ischar);
      ip.addParameter('AllowDefaults',false,@islogical);
      
      
      ip.KeepUnmatched = true;
      ip.parse(varargin{:});

      obj.allowDefaults = ip.Results.AllowDefaults;
      
      w = max([265,ip.Results.Width]);
      
      % determine the number of inputs requested
      nInputs = length(ip.Results.Prompts);
      % 57px for prompt edit and label + padding (5px top/bottom)
      pH = 57;
      promptHeight = pH * nInputs;
      % button height is 15+20+5
      buttonOffset = 40;
      h = buttonOffset + promptHeight + 5; %add 5 for top margin
      
      %
      pos = utilities.centerFigPos(w,h);
      obj.position = pos;
      
      set(obj.container, ...
        'Name', ip.Results.Title, ...
        'Units', 'pixels', ...
        'resize', 'off' ...
        );
      % set any extra props unmatched in the input parser
      set(obj.container, ip.Unmatched);
      
      % Calculate positions
      editOfst = 5;
      labOfst = 32;
      
      promptBounds = (0:nInputs-1).*pH + buttonOffset;
      
      if length(ip.Results.Camelize) == nInputs
        cam = ip.Results.Camelize;
      else
        cam = utilities.rep(ip.Results.Camelize(1),nInputs);
      end
      % Build UIs
      [obj.label,obj.input] = deal(cell(nInputs,1));
      
      location = 0;
      for I = nInputs:-1:1
        location = location+1;
        % Create the label
        l = uicontrol(obj.container, ...
          'Style', 'text', ...
          'Units', 'pixels', ...
          'Position', [15, promptBounds(I)+labOfst, w-30, 20], ...
          'HorizontalAlignment', 'left', ...
          'String', ip.Results.Prompts{location}, ...
          'FontSize', 12, ...
          'BackgroundColor', [1 1 1] ...
          );

        % Create the edit field
        e = uicontrol(obj.container, ...
          'Style', 'edit', ...
          'Units', 'pixels', ...
          'Position', [20,promptBounds(I)+editOfst,w-40,25], ...
          'String', ip.Results.Defaults{location}, ...
          'FontSize', 10, ...
          'BackgroundColor', [1 1 1], ...
          'UserData', location ...
          );
        if cam(location)
          e.Callback = @obj.validateInput;
        else
          e.Callback = @obj.assignInput;
        end
        obj.label{I} = l;
        obj.input{I} = e;
      end
      % Create the button
      obj.button = uicontrol(obj.container, ...
        'Style', 'pushbutton', ...
        'Units', 'pixels', ...
        'Position', [w/2-40, 15, 80, 20], ...
        'String', ip.Results.ButtonLabel, ...
        'Callback', @obj.onGo ...
        );
      
      %%% Set obj props
      obj.title = ip.Results.Title;
      obj.prompts = ip.Results.Prompts;
      obj.promptTitles = ip.Results.Labels;
      obj.inputs = ip.Results.Defaults;
      obj.defaults = ip.Results.Defaults;
      obj.nPrompts = nInputs;
    end
    
  end
  
  methods (Access = private)
    
    function validateInput(obj,src,~)
      src.String = utilities.camelizer(src.String);
      obj.inputs{src.UserData} = src.String;
    end
    
    function assignInput(obj,src,~)
      obj.inputs{src.UserData} = src.String;
    end
    
    function onGo(obj,~,~)
      if obj.halt
        warndlg('Please enter valid input[s].');
        return;
      end
      obj.validClose = true;
      obj.onCloseRequest([],[]);
    end
    
    function onCloseRequest(obj,~,~)
      obj.setWindowStyle('normal');
      obj.shutdown;
      obj.reset;
    end
    
    
    
  end
end

