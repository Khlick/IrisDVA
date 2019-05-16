function app = main(varargin)
% add the app to the matlab path
addAppToPath();

% Show the busy presenter and app splash while the rest of the app loads
splash = iris.ui.busyShow();

% Warn if version is < 9.5 (2018b) as 2018a will have keyboard issues.
v = ver('matlab');
if str2double(v.Version) < 9.5
  error('Iris DVA 2019 requires matlab version 9.5 (2018b) or newer.');
end

splash.start(sprintf('Iris DVA (c) %s', iris.app.Info.year));

tStart = tic;
minDelay = 5; %seconds

% options
opts = iris.pref.analysis.getDefault();

%
iris.app.Info.checkDir(opts.OutputDirectory);
iris.app.Info.checkDir(opts.AnalysisDirectory);
iris.app.Info.checkDir(opts.ExternalReadersDirectory);

try
  % setup data model
  dataHandler = iris.data.Handler(varargin{:});

  % Build UIs
  menuServices = iris.infra.menuServices();
  primaryView = iris.ui.primary();

  %load views and settings into the applicaiton obj (all listeners in Iris)
  app = Iris(dataHandler,primaryView,menuServices);
catch startupError
  splash.stop('Startup Error!', 2);
  delete(splash);
  rethrow(startupError);
end

% delay if not enough time has elapsed on splash
while toc(tStart) < minDelay, end

% App is all ready, kill the splash screen.
splash.stop('Welcome!', 1);
delete(splash);

%launch
try
  app.run();
catch runError
  app.stop;
  delete(app);
  rethrow(runError);
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
  
  %add the appropriate paths for the session
  addpath(strjoin(paths,';'));
end