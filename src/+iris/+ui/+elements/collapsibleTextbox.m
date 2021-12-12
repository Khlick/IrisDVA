classdef collapsibleTextbox < matlab.ui.componentcontainer.ComponentContainer
  events (HasCallbackProperty, NotifyAccess = protected)
    StatusChanged
    HeightChanged
  end
  
  properties (Constant=true)
    SCRIPT_ID = "collapsibleTextbox"
    MIN_HEIGHT = 22;
  end

  properties
    Label (1,1) string = "Label"
    Text (1,1) string = "Contents"
    Monospaced (1,1) logical = true
    FontSize (1,1) double = 12 %pt
    % aesthetics for the content
    TextColor = [0 0 0]
    TextBackgroundColor = [1,1,1,1]
    LabelColor = [0 0 0]
    LabelBackgroundColor = [[1,1,1]*0.901,1]
    isOpen = true % init as open
  end
  
  properties (SetAccess=private)
    Height
  end

  properties (Access=private)
    PreviousData
    MaxHeight = 85
  end

  properties (Access = private, Transient, NonCopyable)
    Frame matlab.ui.control.HTML
    GridLayout matlab.ui.container.GridLayout
  end
  
  properties (Dependent)
    Data
  end

  properties (Dependent,Access=private)
    HTMLSource
    TextColorSpec
    TextBackgroundColorSpec
    LabelColorSpec
    LabelBackgroundColorSpec
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
    
    function set.TextBackgroundColor(obj,val)
      if isnumeric(val)
        opacity = utilities.ternary(numel(val) >= 4,val(end),1); 
        val = val(1:3); % truncate for validation
      else
        opacity = 1;
      end
      obj.TextBackgroundColor = [validatecolor(val),opacity];
    end
    function col = get.TextBackgroundColorSpec(obj)
      val = obj.TextBackgroundColor;
      opacity = utilities.ternary(numel(val) >= 4,val(end),1);
      col = sprintf( ...
        "rgba(%s)", ...
        strjoin([string(uint64(val(1:3).*255)),string(opacity)],",") ...
        );
    end

    function set.LabelColor(obj,val)
      obj.LabelColor = validatecolor(val);
    end
    function col = get.LabelColorSpec(obj)
      col = sprintf("rgb(%s)",strjoin(string(uint64(obj.LabelColor.*255)),","));
    end

    function set.LabelBackgroundColor(obj,val)
      if isnumeric(val)
        opacity = utilities.ternary(numel(val) == 4,val(end),1); 
        val = val(1:3); % truncate for validation
      else
        opacity = 1;
      end
      obj.LabelBackgroundColor = [validatecolor(val),opacity];
    end
    function col = get.LabelBackgroundColorSpec(obj)
      val = obj.LabelBackgroundColor;
      opacity = utilities.ternary(numel(val) >= 4,val(end),1);
      col = sprintf( ...
        "rgba(%s)", ...
        strjoin([string(uint64(val(1:3).*255)),string(opacity)],",") ...
        );
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
    
    % data
    function set.Data(obj,s)
      % html element does not update observed properties
      obj.isOpen = s.isOpen;
      obj.Height = s.Height;
    end
    function d = get.Data(obj)
      d = struct( ...
        'FontSize', obj.FontSize, ...
        'Monospaced', obj.Monospaced, ...
        'isOpen', obj.isOpen, ...
        'Label',      obj.Label, ...
        'Text',       obj.Text, ...
        'TextColor', obj.TextColorSpec, ...
        'TextBackgroundColor', obj.TextBackgroundColorSpec, ...
        'LabelColor', obj.LabelColorSpec, ...
        'LabelBackgroundColor', obj.LabelBackgroundColorSpec, ...
        'Height', obj.Height ...
        );
    end
    
    % height
    function h = get.Height(obj)
      if isempty(obj.Height)
        h = struct('label',obj.MIN_HEIGHT,'contents',0,'max',obj.MaxHeight);
      else
        h = obj.Height;
      end
    end
    function set.MaxHeight(obj,val)
      obj.MaxHeight = val;
    end
    function adjustMaxHeight(obj,val)
      if val <= obj.MIN_HEIGHT
        iris.app.Info.throwError( ...
          sprintf("Cannot set Max Height <= %fpx.",obj.MIN_HEIGHT) ...
          );
      end
      obj.MaxHeight = val;
    end
  end

  %% Super Methods
  methods (Access = protected)

    function setup(obj)
      
      % do we need to set a position?
      %obj.Position = [100,100,200,60];

      % Grid container
      obj.GridLayout = uigridlayout(obj);
      obj.GridLayout.RowHeight = {'1x'};
      obj.GridLayout.ColumnWidth = {'1x'};
      obj.GridLayout.Padding = 0;
      obj.GridLayout.BackgroundColor = [1,1,1,0]; % grid is transparent

      % uihtml container
      obj.Frame = uihtml(obj.GridLayout);
      obj.Frame.Layout.Row = 1;
      obj.Frame.Layout.Column = 1;
      obj.Frame.HTMLSource = obj.HTMLSource;
      obj.Frame.DataChangedFcn = @obj.onJSUpdate;
    end

    function update(obj)
      % called when property is updated by MATLAB
      import utilities.fastrmField;
      drops = "Height";
      D = obj.Data;
      P = obj.PreviousData;
      if ~isempty(P) && isequal(fastrmField(D,drops),fastrmField(P,drops)), return; end
      % only update if data property was changed that also wasn't a "read-only" js
      % property.
      obj.Frame.Data = D;
      obj.PreviousData = D; % update tracker
    end

  end

  %% Callbacks
  methods (Access = protected)
    
    function onJSUpdate(obj,~,evt)
      % Called when updated by js
      import iris.infra.eventData;
      newData = obj.Frame.Data;
      prevData = obj.PreviousData;
      if isequal(newData,prevData), return; end
      
      % update properties
      obj.Data = newData;
      obj.PreviousData = newData;

      if newData.isOpen ~= prevData.isOpen
        notify(obj,'StatusChanged',eventData(newData.isOpen,evt));
      end
      
      if ~isequal(newData.Height,prevData.Height)
        notify(obj,'HeightChanged',eventData(newData.Height,evt));
      end
      
    end

  end

end
