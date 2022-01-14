function status = update(appfilename)
if nargin < 1, return; end

if IrisDVA.isMounted() && IrisDVA.isRunning()
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

% update CLI
IrisDVA.import();

% update this package
installedLocation = fileparts(fileparts(mfilename('fullpath')));%..\root\@IrisDVA\update.m
% location in iris of the newer version
sourceRootPath = fullfile(iris.app.Info.getResourcePath(),'scripts','helper');
sourcePath = fullfile(sourceRootPath,'@IrisDVA');

% get the source version
here = pwd();
cd(sourceRootPath);
pause(0.001);
installerVersion = IrisDVA.VERSION;
cd(installedLocation);
pause(0.001);
currentVersion = IrisDVA.VERSION;
cd(here);
pause(0.001);

if installerVersion == currentVersion
  %up to date
  if ~importStatus
    IrisDVA.detach();
  end
  return
end

options = iris.pref.Iris.getDefault();
onClean = onCleanup(@()installOnExit(options,sourcePath,installedLocation));



  function installOnExit(opt,src,dst)
    copyfile(src,fullfile(dst,'@IrisDVA'), 'f');
    pdef = strsplit(pathdef,';');
    pdef(cellfun(@isempty,pdef,'uniformoutput', true)) = [];
    currentPath = strsplit(path,';');
    currentPath(cellfun(@isempty,currentPath,'uniformoutput', true)) = [];
    pathsToRestore = strjoin(currentPath(~ismember(currentPath,pdef)),pathsep);
    rmpath(pathsToRestore);
    pause(0.01);
    addpath(dst);
    savepath();
    pause(0.05);
    addpath(pathsToRestore);
    opt.HelpersDirectory = dst;
    opt.save();
    % report
    fprintf('Operation completed successfully!\n');
  end


end
