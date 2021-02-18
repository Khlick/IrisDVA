function [absmax,varargout] = AbsMax(matx,dim)
%ABSMAX Get the absolute max, corrected by the original sign
if nargin < 2, dim = 1; end

if isvector(matx)
  matx = matx(:);
end

[~,ind] = max(abs(matx),[],dim,'linear','omitnan');
absmax = matx(ind);

[ind,~] = ind2sub(size(matx),ind);

if nargout > 1, varargout{1} = ind; end
end

