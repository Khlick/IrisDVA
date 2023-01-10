function onWindowMotionCapture(app,src,evt)
  if ~app.hasdata, return; end
  % check if motion is over EditAxes
  if ~isequal(ancestor(evt.HitObject,'axes'),app.EditAxes)
    if app.didClickROI && app.isMouseDown
      % not on edit axes, use clickDrag to determine if more action is needed
      app.onDataClickDrag(src,evt);
    end
    if strcmp(src.Pointer,'cross')
      src.Pointer = 'arrow';
    end
    return
  end
  % Over axes, check if axes interaction active
  isInteractive = app.EditAxes.InteractionContainer.CurrentMode ~= "none";
  % check if over clickable region of axes
  if ~isa(evt.HitPrimitive,'matlab.graphics.primitive.world.Quadrilateral')
    % if interactive mode on, leave the pointer alone
    if isInteractive, return; end
    % if over a ruler, set back to arrow
    if isa(evt.HitPrimitive,'matlab.graphics.primitive.world.RulerPrimitive')
      % otherwise return the pointer to arrow (prevents cross pointer on rulers)
      src.Pointer = 'arrow';
      return
    end
    %'matlab.graphics.primitive.world.LineStrip' is a line child
  end
  % Over clickable region, update the x and y labels
  app.xLabel.Text = sprintf( ...
    "x: %.*f", ...
    app.setting_Precision, ...
    evt.IntersectionPoint(1) ...
    );
  app.yLabel.Text = sprintf( ...
    "y: %.*f", ...
    app.setting_Precision, ...
    evt.IntersectionPoint(2) ...
    );
  % if interactive, simply return
  if isInteractive, return; end
  % set pointer as cross to allow point plotter
  src.Pointer = 'cross';
end

