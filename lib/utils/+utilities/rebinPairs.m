function [X,Y,bins] = rebinPairs(x,y,n,mode,statistic,conf,doSort)
% returns X,Y as Nx3 matrix where X,Y(n,1) = stat() and  X,Y(n,2:3) = [low,high] conf

arguments
  x (:,:) double {mustBeVector}
  y (:,:) double {mustBeEqualSize(y,x)}
  n (1,1) uint32 {mustBeShorterThan(n,x)}
  mode (1,1) string {mustBeMember(mode,{'linear','log','log2','log10'})} = "linear"
  statistic (1,1) function_handle {mustReturnScalar(statistic)} = @mean
  conf (1,1) double {mustBeInRange(conf,0,1,"exclude-lower","exclude-upper")} = 0.95
  doSort (1,1) logical = true
end

import utilities.bootstrap;


switch mode
  case "linear"
    fx = @(v) v;
  case "log"
    fx = @(v) log(v);
  case "log2"
    fx = @(v) log2(v);
  case "log10"
    fx = @(v) log10(v);
end

% force column
x = x(:);
y = y(:);

% sort
if doSort
  [x,order] = sort(x);
  y = y(order);
end

% Binning may result in some bins having 0 values, e.g. the final bin names of a
% 5 bins discretization may only have bins, 1,2,4,5. So we need to account for
% this by discriminating between desired bins and final bin count
bins = discretize(fx(x),n);
[~,~,bins] = unique(bins,'stable');
binNames = unique(bins,'stable');

nBins = numel(binNames);

X = zeros(nBins,3);
Y = zeros(nBins,3);
for i = 1:nBins
  b = binNames(i);
  locs = bins == b;
  thisX = statistic(x(locs));
  thisY = statistic(y(locs));
  if sum(locs) <= 2
    ciType = "Percentile";
  else
    ciType = "BCa";
  end
  [~,xCi] = bootstrap.getConfidenceIntervals(x(locs),statistic,conf,10000,ciType);
  [~,yCi] = bootstrap.getConfidenceIntervals(y(locs),statistic,conf,10000,ciType);
  % store
  X(i,:) = [thisX,xCi];
  Y(i,:) = [thisY,yCi];
end

end


function mustBeEqualSize(a,b)
if ~isequal(size(a),size(b))
  throwAsCaller(MException("SIZE:NOTEQUAL","Inputs must be the same size."));
end
end

function mustBeShorterThan(v,a)

len = uint32(numel(a));
if v >= len
  throwAsCaller(MException("COUNT:TOOLONG","Bins must be less than length of Input."));
end

end

function mustReturnScalar(stat)

r = randn(5,1);
if numel(stat(r)) ~= 1
  throwAsCaller(MException("FXRETURN:NOTSCALAR","Function must return scalar."));
end

end