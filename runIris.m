function app = runIris(varargin)
fprintf('Starting Iris\n');
% add the app to the matlab path
addAppToPath();
pause(0.01);

if isIrisOpen()
  error('Iris is already open.');
end

% Show the busy presenter and app splash while the rest of the app loads
%splash = iris.ui.busyShow();
splash = iris.ui.about();
while ~splash.isready
  pause(0.001);
end
splash.container.Name = "Starting...";

cu = onCleanup(@()onLoaded(splash));


% Warn if version is < 9.5 (2018b) as 2018a will have keyboard issues.
v = ver('matlab');
if str2double(v.Version) < 9.5
  error('Iris DVA requires matlab version 9.5 (2018b) or newer.');
end

%splash.start(sprintf('Iris DVA %s %s', char(hex2dec('00a9')), iris.app.Info.year));
splash.show();

tStart = tic;
minDelay = 5; %seconds

% options
opts = iris.pref.analysis.getDefault();

% check directories
iris.app.Info.checkDir(opts.OutputDirectory);
iris.app.Info.checkDir(opts.AnalysisDirectory);
iris.app.Info.checkDir(opts.ExternalReadersDirectory);
iris.app.Info.checkDir(opts.ExternalModulesDirectory);

try
  % setup data model
  dataHandler = iris.data.Handler(varargin{:});
  
  % Build UIs
  menuServices = iris.infra.menuServices();
  primaryView = iris.ui.primary();
  
  %load views and settings into the applicaiton obj (all listeners in Iris)
  app = Iris(dataHandler,primaryView,menuServices);
catch startupError
  delete(findall(groot,'Tag', iris.app.Info.name));
  delete(findall(groot,'Tag', [iris.app.Info.name,'UI']));
  rethrow(startupError);
end

% delay if not enough time has elapsed on splash
while toc(tStart) < minDelay, end

%launch
try
  app.run();
catch runError
  app.stop;
  delete(app);
  rethrow(runError);
end

splash.show();
splash.container.Name = "Loaded!";
pause(1);

app.show();


% check the helper directory (omit for now)
%{
% first check for helpers
hDir = app.options.HelpersDirectory;
if (isempty(hDir) || strcmp(hDir,""))
  app.onInstallHelpersRequested([],[]);
  app.show();
end
%}

% cleanup fuction
  function onLoaded(S)
    S.shutdown();
    delete(S);
  end

end

%% helper functions
function addAppToPath()

paths =                            ...
  strsplit(                        ...
  genpath(                       ...
  fileparts(mfilename('fullpath'))   ...
  ),                             ...
  ';'                            ...
  );
paths = paths(~cellfun(@(x)strcmp(x,''),paths,'unif',1));
paths = paths(~contains(paths,'\.'));
paths = paths(~contains(paths,'\_'));

% do not add resources path for 1) matlab has an internal issue with
% directories named "resources" (see
% matlab.internal.ResourcesFolderUtils.FolderName) and 2) we use the resources
% directory explicitly from the iris.app.Info class in all cases, letting us
% include files/directories that are not accessible through the global
% workspace.
paths = paths(~contains(paths,'resources'));

%add the appropriate paths for the session
addpath(strjoin(paths,';'));
end

function tf = isIrisOpen()
% primary window will have Iris as tag. All other windows will default to IrisUI
tf =  ~isempty( ...
  findall(groot,'Tag', iris.app.Info.name) ...
  );
end
