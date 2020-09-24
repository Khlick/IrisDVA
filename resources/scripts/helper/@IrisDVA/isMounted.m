function tf = isMounted()
% ISMOUNTED (Private) Determine if app is imported
appInfo = IrisDVA.info();
if isempty(appInfo)
  tf = false;
  return
end

p = strsplit(path,pathsep);
tf = any(contains(p,appInfo.location));

end