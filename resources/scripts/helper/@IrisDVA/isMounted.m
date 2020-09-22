function tf = isMounted()
% ISMOUNTED (Private) Determine if app is imported
appInfo = IrisDVA.info();
p = strsplit(path,pathsep);
tf = any(contains(p,appInfo.location));

end