function varargout = getModules(forceReload)
% getModules Locate and install external and builtin modules
%  Use @param forceRelaod = true to reload from builtin and user modules
if nargin < 1, forceReload = true; end
% module package location
modulePkgDir = fullfile( ...
  iris.app.Info.getAppPath(),'src','+iris','+modules' ...
  );
[s,~,~] = mkdir(modulePkgDir);
if ~s, iris.app.Info.throwError('Could not merge Modules.'); end
installedModules = cellstr(ls(modulePkgDir));
installedModules( ...
  ~endsWith(installedModules,'.mlapp','IgnoreCase',true) & ...
  ~startsWith(installedModules,'@') ...
  ) = [];
installedModules = regexp( ...
  installedModules, ...
  '(?<=@|^)(\w+)(?=\.mlapp|$)', ...
  'tokens', 'emptymatch' ...
  );
while ~isempty(installedModules) && ~ischar(installedModules{1})
  installedModules = cat(1,installedModules{:});
end
% camelize names
installedModules = cellfun(@utilities.camelizer,installedModules,'UniformOutput',false);
% reload from builtin and user directories?
if forceReload
  %Builtin modules will be stored in a resource folder, which isn't added to
  %path.
  builtinDir = fullfile( ...
    iris.app.Info.getResourcePath, ...
    'Modules' ...
    );
  if ~exist(builtinDir,'dir')
    mkdir(builtinDir);
  end
  builtinModules = cellstr(ls(builtinDir));
  builtinModules( ...
    ~endsWith(builtinModules,'.mlapp','IgnoreCase',true) & ...
    ~startsWith(builtinModules,'@') ...
    ) = [];
  % get custom from preferences Module directory.
  wsVars = iris.pref.analysis.getDefault();
  externalModules = cellstr(ls(wsVars.ExternalModulesDirectory));
  externalModules( ...
    ~endsWith(externalModules,'.mlapp','IgnoreCase',true) & ...
    ~startsWith(externalModules,'@') ...
    ) = [];
  % make absolute paths
  modules = [ ...
    fullfile(builtinDir,builtinModules(:)); ...
    fullfile(wsVars.ExternalModulesDirectory,externalModules(:)) ...
    ];
  % copy to a package folder to prevent overloading any functions. This method
  % will always search the user and builtin directories and replace/clear missing
  % modules in the package folder +modules. This let's us make changes to module
  % code and refresh
  moduleDestinationName = [builtinModules(:);externalModules(:)];
  modNames = regexp( ...
    moduleDestinationName, ...
    '(?<=@|^)(\w+)(?=\.mlapp|$)', ...
    'tokens', 'emptymatch' ...
    );
  if ~isempty(modNames)
    while ~ischar(modNames{1})
      modNames = cat(1,modNames{:});
    end
  end
  % camelize names
  modNames = cellfun(@utilities.camelizer,modNames,'UniformOutput',false);
  % gen paths
  newPaths = fullfile(modulePkgDir,moduleDestinationName);
  % clear modules package
  if ispc
    rmCmd = sprintf( ...
      [ ...
      'powershell.exe -inputformat none -Command ', ...
      '"Remove-Item -path ''%s\\*'' -ErrorAction Ignore -recurse -force"' ...
      ], ...
      modulePkgDir ...
      );
  else
    rmCmd = sprintf('rm -rf "%s/"*',modulePkgDir);
  end
  [s,m] = system(rmCmd);
  
  % copy files to package
  msgs = cell(length(modules),1);
  for m = 1:length(modules)
    [status,msg] = copyfile(modules{m},newPaths{m},'f');
    if ~status
      msgs{m} = msg;
    end
  end
else
  msgs = {};
  modNames = installedModules(:);
end

%outputs
if ~nargout, return; end
varargout{1} = modNames;
varargout{2} = msgs;
end