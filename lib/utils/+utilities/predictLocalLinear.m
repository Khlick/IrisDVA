function predictions = predictLocalLinear(targetX,Xs,Ys,rangeWidth)

arguments
  targetX (1,:) double {mustBeNumeric}
  Xs (:,1) double {mustBeNumeric}
  Ys (:,1) double {mustBeNumeric}
  rangeWidth (1,1) uint32 {mustBeNonzero,mustBeInteger} = 2
end

% determine radius step size for finding local range
steprange = min(diff(Xs))/numel(Xs);
if rangeWidth < 2
  warning('PREDICTLOCALLINEAR:PREDICTIONRANGE','RangeWidth must be at least 2.');
  rangeWidth = 2;
end

% get local ranges near targets
nTargets = numel(targetX);
ranges = cell(nTargets,1);
[ranges{:}] = utilities.getNearestRange(targetX,Xs,rangeWidth,steprange);

ranges = cat(1,ranges{:});

% compute linear fits to each range and evaluate the fit at the targetX
warnState = warning('off','MATLAB:polyfit:RepeatedPointsOrRescale');
predictions = zeros(1,nTargets,'like',Ys);
for r = 1:nTargets
  thisX = ranges(r).value;
  thisY = Ys(ranges(r).index);
  thisModel = polyfit(thisX,thisY,1);
  predictions(r) = polyval(thisModel,targetX(r));
end
warning(warnState);
end