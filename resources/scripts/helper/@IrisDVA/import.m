function appinstalldir = import()
%IMPORTIRIS Add iris to matlab path
appInfo = IrisDVA.info();

if isempty(appInfo)
  fprintf(2,'IrisDVA is not installed!\n');
  return;
end

% app location string
appinstalldir = appInfo.location;

% generate the file path
apppath = java.io.File(appinstalldir);

resourcesfolder = matlab.internal.ResourcesFolderUtils.FolderName; 
canonicalpathtocodedir = fullfile(char(apppath.getCanonicalPath()));
allpaths = matlab.internal.apputil.AppUtil.genpath(canonicalpathtocodedir);

% do not allow resources or metadata folders to be added to the path
pathsToAdd = strrep( ...
  strrep( ...
    allpaths, ...
    fullfile(canonicalpathtocodedir,[resourcesfolder,pathsep]), ...
    '' ...
    ), ...
  fullfile(canonicalpathtocodedir,'metadata;'), ...
  '' ...
  );
% add the app to the MATLAB path
addpath(pathsToAdd);
end

