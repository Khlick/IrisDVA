function appinstalldir = detach()
%DETACH Remove iris from path

appInfo = IrisDVA.info();

if isempty(appInfo)
  fprintf(2,'IrisDVA is not installed!\n');
  return;
end

% get the install directory
appinstalldir = appInfo.location;

% generate the file path
apppath = java.io.File(appinstalldir);

resourcesfolder = matlab.internal.ResourcesFolderUtils.FolderName; 
canonicalpathtocodedir = fullfile(char(apppath.getCanonicalPath()));
allpaths = matlab.internal.apputil.AppUtil.genpath(canonicalpathtocodedir);
% do not allow resources or metadata folders to be added to the path
pathsToRm = strrep( ...
  strrep( ...
    allpaths, ...
    fullfile(canonicalpathtocodedir,[resourcesfolder,pathsep]), ...
    '' ...
    ), ...
  fullfile(canonicalpathtocodedir,'metadata;'), ...
  '' ...
  );
% remove from MATLAB path
rmpath(pathsToRm);
end