function status = update(appfilename)
if nargin < 1, return; end

if IrisDVA.isRunning()
  error("Please close Iris before updating.");
end
appfilename = char(appfilename);

newFileInfo = mlappinfo(appfilename);
currentVersion = IrisDVA.installedVersion();

if string(newFileInfo.version) == currentVersion
  response = questdlg( ...
    sprintf('Version %s is already installed. Proceed anyway?',currentVersion), ...
    'Overwrite?', ...
    'Yes', 'Cancel', 'Cancel' ...
    );
  if strcmp(response, 'Cancel'), return; end
end


importStatus = IrisDVA.isMounted();
if importStatus
  IrisDVA.detach();
end

s = matlab.apputil.install(appfilename);

status = s.status;

if importStatus
  IrisDVA.import();
end

end