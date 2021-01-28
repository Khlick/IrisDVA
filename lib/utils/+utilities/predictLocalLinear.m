function varargout = predictLocalLinear(targetX,Xs,Ys,rangeWidth)

arguments
  targetX (1,:) double {mustBeNumeric}
  Xs (:,1) double {mustBeNumeric}
  Ys (:,1) double {mustBeNumeric}
  rangeWidth (1,1) uint32 {mustBeNonzero,mustBeInteger} = 2
end

% determine radius step size for finding local range
steprange = min(diff(Xs))/numel(Xs);
jumprange = min(diff(Ys))/numel(Ys);
if rangeWidth < 2
  warning('PREDICTLOCALLINEAR:PREDICTIONRANGE','RangeWidth must be at least 2.');
  rangeWidth = 2;
end

% get local ranges near targets
nTargets = numel(targetX);
ranges = cell(nTargets,1);
[ranges{:}] = utilities.getNearestRange(targetX,Xs,rangeWidth,steprange);

ranges = cat(1,ranges{:});

% clear any nans
keep = ~arrayfun(@(a)isnan(a.index(1)),ranges,'UniformOutput',true);
if any(~keep)
  warning("IRIS:UTILITIES:PREDICTLOCALLINEAR", ...
    ['Some targets outside of range will be dropped.', ...
    'Use second output to retrieve new targets.'] ...
    );
end
nTargets = sum(keep);
ranges(~keep) = [];
targetX(~keep) = [];

% compute linear fits to each range and evaluate the fit at the targetX
warnState = warning('off','MATLAB:polyfit:RepeatedPointsOrRescale');
predictions = zeros(1,nTargets,'like',Ys);
for r = 1:nTargets
  thisX = ranges(r).value;
  if sum(thisX == Xs(1)) > 1
    thisX(1) = thisX(1) - steprange;
  end
  if sum(thisX == Xs(end)) > 1
    thisX = thisX - steprange;
    thisX(end) = thisX(end) + steprange;
  end
  thisY = Ys(ranges(r).index);
  if sum(thisY == Ys(1)) > 1
    thisY(1) = thisY(1) - jumprange;
  end
  if sum(thisY == Ys(end)) > 1
    thisY = thisY - jumprange;
    thisY(end) = thisY(end) + jumprange;
  end
  thisModel = polyfit(thisX,thisY,1);
  predictions(r) = polyval(thisModel,targetX(r));
end
warning(warnState);
varargout{1} = predictions;
if nargout > 1
  varargout{2} = targetX;
end
end