function varargout = getNearestRange(target,Values,nReturn,radiusStep)
% GETNEARESTPOINTS Return N points from Values that are closest to a target.

arguments
  target (1,:) {mustBeNumeric}
  Values (:,1) {mustBeNumeric}
  nReturn (1,1) {mustBeNumeric,mustBeNonzero} = 2
  radiusStep (1,1) double {mustBeNumeric,mustBeNonzero} = 0.01
end

assert(nargout == numel(target), 'The number outputs must be the same is target length.');

nVals = numel(Values);
if mod(nReturn,2)
  % odd
  rVector = int64((1:nReturn) - median([1,nReturn]));
else
  % even
  rVector = int64((1:nReturn) - median([1,nReturn])-0.5);
end
varargout = cell(1,nargout);
for n = 1:nargout
  % locate the closest index to target in x
  xFirst = find(Values >= target(n),1,'first');
  % determine the sampling distance
  xDiff = min(mean(1./diff(Values,1)));
  % iterate
  xValue = [];
  xIndex = [];
  searchRadius = 0;
  while isempty(xValue)
    searchRadius = searchRadius + radiusStep;
    low = uint32(max(1, xFirst - ceil(searchRadius * xDiff)));
    high = uint32(min(nVals, xFirst + ceil(searchRadius * xDiff)));
    if high <= low, continue; end
    range = low:high;
    [~,loc] = min(abs(target(n) - Values(range)));
    pos = int64(range(loc));
    if ~isempty(Values(pos))
      % build vector
      pos = pos + rVector;
      while any(pos < 1)
        pos = pos + 1;
        if any(pos > nVals)
          % truncate
          pos(pos > nVals) = [];
          if isempty(pos), break; end
        end
      end
      while any(pos > nVals)
        pos = pos - 1;
        if any(pos < 1)
          pos(pos < 1) = [];
        end
        if isempty(pos), break; end
      end
    end
    xIndex = pos;
    xValue = Values(pos);
  end
  % store
  varargout{n} = struct('index',xIndex,'value',xValue);
end

end