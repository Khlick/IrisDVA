function app = main(varargin)
if ispc
  [~,netResult] = system('ping -n 2 8.8.8.8');
  isConnected = ~str2double(netResult(strfind(netResult,'Lost =')+7));
elseif isunix
  [~,netResult] = system('ping -c 2 8.8.8.8');
  isConnected = str2double(netResult(strfind(netResult,'received')-2))>0;
elseif ismac
  [~,netResult] = system('ping -c 2 8.8.8.8');
  isConnected = str2double(netResult(strfind(netResult,'packets received')-2))>0;
else
  isConnected = false;
end

if ~isConnected
  error('Iris DVA 2019 requires an internet connection to operate.');
end

% add the app to the matlab path
addAppToPath();

% Show the busy presenter and app splash while the rest of the app loads
splash = iris.ui.busyShow();
splash.start(sprintf('Iris DVA (c)%s', iris.app.Info.year));

tStart = tic;
minDelay = 5; %seconds

% options
opts = iris.pref.analysis.getDefault();
iris.app.Info.checkDir(opts.OutputDirectory);
iris.app.Info.checkDir(opts.AnalysisDirectory);

% setup data model
dataHandler = iris.data.Handler(varargin{:});

% Build UIs
menuServices = iris.infra.menuServices();
primaryView = iris.ui.primary();

%load views and settings into the applicaiton obj (all listeners in Iris)
app = Iris(dataHandler,primaryView,menuServices);


% delay if nto enough time has elapsed on splash
while toc(tStart) < minDelay, end

% App is all ready, kill the splash screen.
splash.stop('Welcome!', 1);
delete(splash);

%launch
app.run();

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