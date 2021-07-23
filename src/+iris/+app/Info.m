classdef Info < handle

  methods (Static)

    function n = name()
      n = 'Iris';
    end

    function n = extendedName()
      n = 'Data Visualization and Analysis';
    end

    function d = description()
      d = [...
          'Designed for MATLAB, Iris DVA is a tool for visualizing and ', ...
          'analyzing electrophysiological data.' ...
          ];
    end

    function s = site()
      s = 'https://sampathlab.gitbook.io/iris-dva';
    end

    function v = version(sub)

      if ~nargin
        sub = 'public';
      end
      status = {2,0,132};
      switch sub
        case 'major'
          v = sprintf('%d', status{1});
        case 'minor'
          v = sprintf('%02d', status{2});
        case 'short'
          v = sprintf('%d.%d', status{[1, 2]});
        case 'development'
          v = sprintf('%d.%02d.%03d', status{:});
        case 'public'
          v = sprintf('%d.%02d', status{1:2});
        otherwise
          v = sprintf('%d.%02d', status{1:3});
      end

    end

    function o = owner()
      o = 'Sampath Lab, UCLA';
    end

    function a = author()
      a = 'Khris Griffis';
    end

    function y = year()
      y = '2016-2021';
    end

    function loc = getResourcePath()
      loc = fullfile(...
        fileparts(...
        fileparts(...
        fileparts(...
        fileparts(...
        mfilename('fullpath') ...
        ) ...
        ) ...
        ) ...
        ), ...
        'resources');
    end

    function loc = getAppPath()
      loc = ...
        fileparts(...
        fileparts(...
        fileparts(...
        fileparts(...
        mfilename('fullpath') ...
        ) ...
        ) ...
        ) ...
        );
    end

    function loc = getUserPath()

      if ispc
        loc = [getenv('HOMEDRIVE'), getenv('HOMEPATH')];
      else
        loc = getenv('HOME');
      end

    end

    %Get file
    function [p, varargout] = getFile(title, filter, defaultName, varargin)
      %%GETFILE box title, filterSpec, startDefault
      if nargin < 2
        filter = '*';
      end

      if nargin < 3
        defaultName = '';
      end

      [filename, pathname, fdx] = uigetfile(filter, title, defaultName, varargin{:});

      try
        filename = cellstr(filename);
      catch
        p = [];
        [varargout{1:(nargout - 1)}] = deal([]);
        return;
      end

      p = strcat(pathname, filename);
      nOut = nargout - 1;
      [varargout{1:2}] = deal(fdx, pathname);
      varargout(nOut + 1:end) = [];
    end

    %Put file
    function [p, varargout] = putFile(title, filter, defaultName)
      %%GETFILE box title, filterSpec, startDefault
      if nargin < 2
        filter = '*.*';
      end

      if nargin < 3
        defaultName = '';
      end

      [filename, pathname, fdx] = uiputfile(filter, title, defaultName);
      % check for cancel
      if isequal(filename, 0) || isequal(pathname, 0)
        p = [];
        [varargout{1:(nargout - 1)}] = deal([]);
        return;
      end

      p = fullfile(pathname, filename);
      nOut = nargout - 1;
      [varargout{1:3}] = deal(filename, pathname, fdx);
      varargout(nOut + 1:end) = [];
    end

    %Get folder
    function p = getFolder(Title, StartLocation)

      if nargin < 2
        StartLocation = iris.app.Info.getUserPath;
      end

      p = uigetdir(StartLocation, Title);

      if ~ischar(p)
        p = '';
        return
      end

    end

    %
    function s = checkDir(pathname)
      [s, mg, ~] = mkdir(pathname);

      if ~s &&~nargout
        iris.app.Info.throwError(mg);
      end

      % add this directory to the path
      addpath(pathname);
    end

    function t = Summary()
      import iris.app.Info;

      t = {...
          Info.name, ...
          Info.year, ...
          Info.extendedName, ...
          Info.description, ...
          Info.version('public'), ...
          Info.owner, ...
          Info.author, ...
          Info.site
        };

    end

    function AStruct = getAvailableAnalyses()
      builtinDir = fullfile(iris.app.Info.getResourcePath, 'Analyses');
      extended = iris.pref.analysis.getDefault().AnalysisDirectory;
      
      if ispc
        builtins = cellstr(ls(builtinDir));
        extendeds = cellstr(ls(extended));
      else
        builtins = strtrim(regexp(ls(builtinDir),'(?<!.m)[\w\s]+\.m', 'match')).';
        extendeds = strtrim(regexp(ls(extended),'(?<!.m)[\w\s]+\.m', 'match')).';
      end

      Analyses = [builtins; extendeds];
      Analyses(ismember(Analyses, {'.', '..'})) = [];
      Analyses = Analyses(~cellfun(@isempty, Analyses, 'UniformOutput', 1));
      Analyses = Analyses(endsWith(Analyses, '.m'));
      Analyses = regexprep(Analyses, '\.m$', '');
      % build output struct
      AStruct = struct();
      AStruct.Names = Analyses;
      % prefer user made names over builtin
      ex = [utilities.rep({extended}, length(extendeds)), extendeds];
      bt = [utilities.rep({builtinDir}, length(builtins)), builtins];
      wRoots = [ex; bt];
      wRoots = wRoots(endsWith(wRoots(:, 2), '.m', 'IgnoreCase', true), :);
      wRoots(cellfun(@isempty, wRoots(:, 2), 'UniformOutput', 1), :) = [];
      [~, id] = unique(wRoots(:, 2), 'stable');
      wRoots = wRoots(id, :);
      AStruct.Full = wRoots;
    end

    function showWarning(msg)
      st = dbstack('-completenames', 1);
      id = upper(strrep(st(1).name, '.', ':'));
      warnCall = sprintf(...
        'warning(''%s:%s'',''%s'');', ...
        upper(iris.app.Info.name), ...
        id, ...
        regexprep(msg, '''', '''''') ...
        );
      evalin('caller', warnCall);
    end

    function throwError(msg)
      st = dbstack('-completenames', 1);
      id = upper(strrep(st(1).name, '.', ':'));
      warnCall = MException(...
        sprintf("%s:%s", upper(iris.app.Info.name), id), ...
        msg ...
        );
      throwAsCaller(warnCall);
    end

    function [totalBytes, varargout] = getBytes(file)
      file = string(file);
      eachBytes = zeros(length(file), 1);

      for f = 1:length(file)

        try %#ok<TRYNC>
          d = dir(file{f});
          eachBytes(f) = double(d.bytes);
        end

      end

      totalBytes = sum(eachBytes);

      if nargout > 1
        varargout{1} = eachBytes;
      end

    end

  end

end
