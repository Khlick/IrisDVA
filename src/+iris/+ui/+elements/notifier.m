classdef notifier < matlab.ui.componentcontainer.ComponentContainer
  
  properties (Constant=true)
    SCRIPT_ID = "notifier"
    MIN_HEIGHT = 64;
  end

  properties
    Text (1,1) string = "Text"
    TextColor (1,3) double = [0 0 0]
    TextHeight (1,1) double = 125
    Monospaced (1,1) logical = false
    Animate (1,1) logical = false
  end
  
  properties (Dependent)
    Data
  end
  
  properties (Access=private)
    PreviousData
  end

  properties (Access = private, Transient, NonCopyable)
    Frame matlab.ui.control.HTML
    GridLayout matlab.ui.container.GridLayout
  end

  properties (Dependent,Access=private)
    HTMLSource
    TextColorSpec
    BackgroundColorSpec
  end

  %% Set / Get
  methods

    % colors
    function set.TextColor(obj,val)
      obj.TextColor = validatecolor(val);
    end
    function col = get.TextColorSpec(obj)
      col = sprintf("rgb(%s)",strjoin(string(uint64(obj.TextColor.*255)),","));
    end

    function col = get.BackgroundColorSpec(obj)
      val = obj.BackgroundColor;
      opacity = utilities.ternary(numel(val) >= 4,val(end),1);
      col = sprintf( ...
        "rgba(%s)", ...
        strjoin([string(uint64(val(1:3).*255)),string(opacity)],",") ...
        );
    end

    % text height
    function set.TextHeight(obj,h)
      arguments
        obj
        h (1,1) double {mustBeGreaterThan(h,0)}
      end
      obj.TextHeight = max([obj.MIN_HEIGHT,h]);
    end

    % html source
    function src = get.HTMLSource(obj)
      src = fullfile( ...
        iris.app.Info.getResourcePath(), ...
        "scripts", ...
        obj.SCRIPT_ID, ...
        sprintf("%s.html",obj.SCRIPT_ID) ...
        );
    end
    
    % Data
    function set.Data(obj,paramStruct)
      % use this method to set multiple parameters at once
      % Best use as: get method, modification, then set 
      % using set() will trigger a single obj.update() call regardless of the
      % parameters being sent.
      arguments
        obj
        paramStruct (1,1) struct
      end
      paramCell = namedargs2cell(paramStruct);
      set(obj,paramCell{:});
      
    end

    function d = get.Data(obj)
      d = struct( ...
        'Monospaced', obj.Monospaced, ...
        'Text',       obj.Text, ...
        'TextColor', obj.TextColorSpec, ...
        'TextHeight', obj.TextHeight, ...
        'BackgroundColor', obj.BackgroundColorSpec, ...
        'Animate', obj.Animate ...
        );
    end
    
    function refreshSource(obj)
      obj.Frame.HTMLSource = '';
      drawnow();
      obj.Frame.HTMLSource = obj.HTMLSource;
      drawnow();
    end
  end

  %% Super Methods
  methods (Access = protected)

    function setup(obj)
      
      % Grid container
      obj.GridLayout = uigridlayout(obj);
      obj.GridLayout.RowHeight = {'1x'};
      obj.GridLayout.ColumnWidth = {'1x'};
      obj.GridLayout.Padding = 2;
      obj.GridLayout.BackgroundColor = [1,1,1,0]; % grid is transparent

      % uihtml container
      obj.Frame = uihtml(obj.GridLayout);
      obj.Frame.Layout.Row = 1;
      obj.Frame.Layout.Column = 1;
      obj.Frame.HTMLSource = obj.HTMLSource;
    end

    function update(obj)
      import utilities.fastrmField;
      % called when property is updated by MATLAB
      D = obj.Data;
      P = obj.PreviousData;
      checks = "Animate";
      if ~isempty(P) && isequal(fastrmField(D,checks),fastrmField(P,checks)), return; end
      obj.Frame.Data = D;
      obj.PreviousData = D; % update tracker
      drawnow();
      pause(0.01);% 10ms delay to allow change
    end

  end
end

