function updateView(obj, newSelection, newDisplay, newData, newUnits)
  %% Update UI elemets
  % Use data to update all the data-dependent UI elements and call the plot

  % update the selection (and tickers)
  if ~isequal(newSelection, obj.selection)
    % if we are changing something, we need to update the tickers
    % We can do this by simply relying on the onSelectionUpdate method
    obj.selection = newSelection;
  end

  % update the display data
  obj.setDisplayData(newDisplay);

  % use the layout update to grab any aesthetic changes (i.e. from preferences)
  obj.layout.update;
  % update units
  obj.layout.setTitle('x', utilities.unknownCell2Str(newUnits.x, ' |'));
  obj.layout.setTitle('y', utilities.unknownCell2Str(newUnits.y, ' |'));

  % plot the data
  dPrefs = iris.pref.display.getDefault();

  try
    obj.Axes.update(newData, obj.layout);

    if length(newSelection.selected) > 1
      obj.Axes.setHighlighted(newSelection.highlighted, dPrefs.LineWidth);
    end

  catch exc
    iris.app.Info.showWarning(exc.message);
    notify(obj, 'RevertView');
  end

end
