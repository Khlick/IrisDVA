function varargout = domain(varargin)
%DOMAIN min,max array for each input argument provided
%   Detailed explanation goes here
nIn = length(varargin);
varargout = cell(1,min([nargout,nIn]));
for I = 1:min([nargout,nIn])
  varargout{I} = quantile(varargin{I},[0,1]);
end
end

