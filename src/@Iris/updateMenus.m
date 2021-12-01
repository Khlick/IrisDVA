function updateMenus(app)
  if ~app.handler.isready, return; end

  %% Preferences

  % not sure why we need to save preferences on updates. This seems like a bad
  % idea.
  %app.services.savePrefs('Preferences');

  % Scale value preference, if set to min, max, absolute max, will changed depending on
  % current data

  % scale value
  pref = app.services.getPref('scale');

  if ~strcmpi(pref.Method, 'custom')
    currentDevices = app.handler.getAllDevices();
    allDevices = unique([pref.Value(:, 1); currentDevices(:)]);
    deviceTable = [allDevices, num2cell(ones(length(allDevices), 1))];

    for d = 1:length(pref.Value(:, 1))
      deviceTable(ismember(allDevices, pref.Value(d, 1)), 2) = pref.Value(d, 2);
    end

    % subset to current data devices
    [~, ix] = intersect(allDevices, currentDevices);
    deviceTable = deviceTable(ix, :);
    dvs = string(deviceTable(:, 1));
    % get values for shown devices

    displayDevices = app.handler.getCurrentDevices();

    for dev = string(displayDevices(:)')

      if contains(pref.Method, {'Max', 'Min'})
        sVal = app.handler.getScale(pref.Method, dev);
      else
        sVal = 1;
      end

      deviceTable(dvs == dev, 2) = {sVal};
    end

    % save
    pref.Value = deviceTable;
    app.services.setPref('scale', pref);
  end

  %% Protocols
  stats = app.services.getPref('statistics');
  selection = stats.GroupBy;
  % Collect the grouping fields
  groupField = app.services.getGroups();
  % Make sure our selection contains members of groupField
  selectionKeepers = ismember(selection, groupField);

  if ~any(selectionKeepers)
    selection = groupField{1};
  else
    selection = selection(selectionKeepers);
  end

  % update the selection if we need to
  app.services.setGroupBy(selection);

end
