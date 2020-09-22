function v = installedVersion()
%INSTALLEDVERSION returns the installed version based on the app metadata

% app info
appInfo = IrisDVA.info();
if isempty(appInfo)
  v = "";
  return
end
% parse the installed metainfo
m = com.mathworks.appmanagement.MlappinstallUtil.getAppMetadataByGuid(appInfo.GUID);
% return the version as a string.
v = string(m.getVersion());

end

