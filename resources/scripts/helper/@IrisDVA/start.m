function varargout = start(varargin)
%STARTIRIS Run Iris from the MATLAB command line.

% import the app install directory
appinstalldir = IrisDVA.import();

% call the helper class
wrapperfile = [ ...
  matlab.internal.apputil.AppUtil.genwrapperfilename(appinstalldir), ...
  IrisDVA.OBJECT_ID ...
  ];

% run the app
APP = feval(wrapperfile,varargin{:});

if nargout
  varargout{1} = APP.AppHandle;
end
if nargout > 1
  varargout{2} = APP;
end

end

