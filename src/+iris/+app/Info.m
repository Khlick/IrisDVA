classdef Info < handle
  methods (Static)
    
    function n = name()
      n = 'Iris';
    end
    
    function n = extendedName()
      n = 'Data Visualization and Analysis';
    end

    function d = description()
      d = [ ...
          'Designed for MATLAB, Iris DVA is a tool for visualizing and ', ...
          'analyzing electrophysiological data.' ...
        ];
    end
    
    function s = site()
      s = 'https://github.com/Khlick/IrisDVA';
    end

    function v = version(sub)
      if ~nargin
        sub = 'public';
      end
      status = {2,0,1,'a'};
      switch sub
        case 'major'
          v = sprintf('%d',status{1});
        case 'minor'
          v = sprintf('%02d',status{2});
        case 'development'
          v = sprintf('%d.%02d.%03d%s',status{:});
        otherwise
          v = sprintf('%d.%02d%s',status{1},status{2},status{4});
      end
    end

    function o = owner()
      o = 'Sampath Lab, UCLA';
    end
    
    function a = author()
      a = 'Khris Griffis';
    end
    
    function y = year()
      y = '2016-2019';
    end
    
    function loc = getResourcePath()
      loc  = fullfile(...
        fileparts(...
          fileparts(...
            fileparts(...
              fileparts(...
                mfilename('fullpath')...
              )...
            )...
          )...
        ),...
        'resources');
    end
    
    function loc = getAppPath()
      loc  = ...
        fileparts(...
          fileparts(...
            fileparts(...
              fileparts(...
                mfilename('fullpath')...
              )...
            )...
          )...
        );
    end
    
    function loc = getUserPath()
      if ispc
        loc = [getenv('HOMEDRIVE'),getenv('HOMEPATH')];
      else
        loc = getenv('HOME');
      end
    end
    
    %Get file
    function [p,varargout] = getFile(title,filter,defaultName,varargin)
      %%GETFILE box title, filterSpec, startDefault
      if nargin < 2
        filter = '*';
      end
      if nargin < 3
        defaultName = '';
      end
      [filename, pathname,fdx] = uigetfile(filter,title,defaultName,varargin{:});
      try
        filename = cellstr(filename);
      catch
        p = [];
        [varargout{1:(nargout-1)}] = deal([]);
        return;
      end
      p = strcat(pathname, filename);
      nOut = nargout-1;
      [varargout{1:2}] = deal(fdx,pathname);
      varargout(nOut+1:end) = [];
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
      [s,mg,~] = mkdir(pathname);
      if ~s && ~nargout
        iris.app.Info.showWarning(mg);
      end
    end
    
    function t = Summary()
      import iris.app.Info;
      
      t = { ...
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
    
    function Analyses = getAvailableAnalyses()
      builtinDir = fullfile(iris.app.Info.getResourcePath,'Analyses');
      extended = iris.pref.analysis.getDefault().AnalysisDirectory;
      Analyses = [cellstr(ls(builtinDir));cellstr(ls(extended))];
      Analyses(ismember(Analyses, {'.','..'})) = [];
      Analyses = Analyses(~cellfun(@isempty,Analyses,'UniformOutput',1));
    end
    
    function showWarning(msg)
      st = dbstack('-completenames',1);
      id = upper(strrep(st(1).name,'.', ':'));
      warnCall = sprintf( ...
        'warning(''%s:%s'',''%s'');', ...
        upper(MetaVision.app.Info.name), ...
        id, ...
        msg ...
        );
      eval(warnCall);
    end
    
  end
end

