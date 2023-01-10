function editSelectedDatum(self,~,~)

  if strcmpi(self.SelectedLineLabel.Text,'')
    return
  end
  % SETTINGS
  TYPE = "spline"; % "quad"
  PRECISION = 4;

  
  % GLOBAL
  


  device = self.selectedDevice;
  rmDevs = self.Data.AvailableDevices(~ismember(self.Data.AvailableDevices,device));
  data = self.Data.RemoveDevice(rmDevs).CleanInclusions(); % no filtering

  dataLabel = str2double( ...
    string(regexp(self.SelectedLineLabel.Text,"(?<=#)\d+","match")) ...
    );

  map = data.IndexMap;
  keys = map.keys;
  keys = [keys{:}];
  vals = map.values;
  vals = [vals{:}];
  dataIndex = keys(vals == dataLabel);
  
  
  app = struct();
  app.container = utilities.createIrisUiFigure("Edit Datum",800,600,true);
  
  app.layout = uigridlayout(app.container,[3,2],BackgroundColor=[1,1,1]);
  app.layout.ColumnWidth = {'1x','3x'};
  app.layout.RowHeight = {'2x',26,'1x'};
  app.layout.Padding = 10;
  app.layout.RowSpacing = 5;
  app.layout.ColumnSpacing = 5;
  
  app.table = uitable(app.layout);
  app.table.Layout.Row = 1;
  app.table.Layout.Column = 1;
  app.table.ColumnName = ["Property","Value"];
  
  app.buttonLayout = uigridlayout( ...
    app.layout, ...
    [1,3], ...
    BackgroundColor=[1,1,1], ...
    Padding=0, ...
    ColumnWidth={'1x','1x',60}, ...
    ColumnSpacing=5 ...
    );
  app.buttonLayout.Layout.Row = 2;
  app.buttonLayout.Layout.Column = 1;
  
  app.xCoor = uilabel(app.buttonLayout);
  app.xCoor.Layout.Row = 1;
  app.xCoor.Layout.Column = 1;
  app.xCoor.Text = "x:";
  app.xCoor.HorizontalAlignment = 'left';
  app.xCoor.VerticalAlignment = 'bottom';
  app.xCoor.FontName = 'Courier';
  app.xCoor.FontSize = 11;
  
  app.yCoor = uilabel(app.buttonLayout);
  app.yCoor.Layout.Row = 1;
  app.yCoor.Layout.Column = 2;
  app.yCoor.Text = "y:";
  app.yCoor.HorizontalAlignment = 'left';
  app.yCoor.VerticalAlignment = 'bottom';
  app.yCoor.FontName = 'Courier';
  app.yCoor.FontSize = 11;

  app.doneButton = uibutton(app.buttonLayout);
  app.doneButton.Text = "Done";
  app.doneButton.Layout.Column = 3;
  app.doneButton.Layout.Row = 1;
  
  app.axes = uiaxes(app.layout);
  app.axes.Layout.Column = 2;
  app.axes.Layout.Row = [1,2];

  app.container.WindowButtonDownFcn = @(s,e)onClick(app,s,e);

  % listen for mouse motion on figure
  addlistener(app.container,'WindowMouseMotion',@(s,e)onMotion(app,s,e));

  



  %% internal callbacks
  function onMotion(app,src,evt)
    % check if over axes
    if ~isequal(evt.HitObject,app.axes)
      src.Pointer = 'arrow';
      return
    end
    % Over axes, check if axes interaction active
    isInteractive = app.axes.InteractionContainer.CurrentMode ~= "none";
    % check if over clickable region of axes
    if ~isa(evt.HitPrimitive,'matlab.graphics.primitive.world.Quadrilateral')
      % if interactive mode on, leave the pointer alone
      if isInteractive, return; end
      % otherwise returnt the pointer to arrow (prevents cross pointer on rulers)
      src.Pointer = 'arrow';
      return
    end
    % Over clickable region, update the x and y labels
    app.xCoor.Text = sprintf("x: %.*g", PRECISION, evt.IntersectionPoint(1));
    app.yCoor.Text = sprintf("y: %.*g", PRECISION, evt.IntersectionPoint(2));
    % if interactive, simply return
    if isInteractive, return; end
    % set pointer as cross to allow point plotter
    src.Pointer = 'cross';
    
  end
  function onClick(app,src,evt)
    % check if the axes is in interaction mode

    disp(src.SelectionType)
  end
end
