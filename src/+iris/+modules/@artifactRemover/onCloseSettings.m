function onCloseSettings(app,src,~)
  sFig = ancestor(src,'figure');
  d = getappdata(sFig);
  oldSettings = d.DATA;
  newSettings = d.table.Data;
  delete(sFig);
  % check if a difference was made
  if isequal(oldSettings,newSettings), return; end
  % settings have changed, update and save
  keys = strcat("setting_",newSettings.Key);
  for k = 1:numel(keys)
    switch newSettings.Type(k)
      case "string"
        val = newSettings.Value(k);
      case "logical"
        val = str2num(newSettings.Value(k)); %#ok<ST2NM>
      otherwise
        val = cast(newSettings.Value(k),newSettings.Type(k));
    end
    % check for allowed CorrectionMethod
    if (keys(k) == "setting_CorrectionMethod") && ~ismember(val,["spline","linear","quad"])
      IrisModule.showWarning( ...
        sprintf( ...
        "Correction Method must be one of: [%s]", ...
        strjoin(["spline","linear","quad"],", ") ...
        ) ...
        );
      val = oldSettings.Value(k);
    end
    app.(keys(k)) = val;
  end
  app.savePreferences();
  % check if a redraw is required
  checkParams = ["FilterBandwidth"];
  nChecks = numel(checkParams);
  visUpdate = false(nChecks,1);
  for c = 1:nChecks
    visUpdate(c) = ...
      oldSettings.Value(oldSettings.Key == checkParams(c)) ~= ...
      newSettings.Value(newSettings.Key == checkParams(c));
  end
  if any(visUpdate)
    app.initialize();
  end
end

