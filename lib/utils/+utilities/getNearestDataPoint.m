function [xValue,yValue] = getNearestDataPoint(target,Xs,Ys,radiusStep)
% locate the nearest x value first and use that position to locate the y value
% Xs and Ys size must match
arguments
  target (1,2) {mustBeNumeric}
  Xs (:,1) {mustBeNumeric}
  Ys (:,1) {mustBeNumeric}
  radiusStep (1,1) {mustBeNumeric,mustBeNonzero} = 0.01
end
assert( ...
  isequal(size(Xs),size(Ys)), ...
  'Xs and Ys must be the same size.' ...
  );
% reshape into column vectors
Xs = reshape(Xs,numel(Xs),[]);
Ys = reshape(Ys,numel(Ys),[]);

% locate the closes index to target.x
xFirst = find(Xs >= target(1),1,'first');
% determine a smallest sampling frequency of the X values
xDiff = min(mean(1./diff(Xs,1)));
% iterate until we are close enough to a data point
xValue = [];
yValue = [];
searchRadius = 0; 
while isempty(xValue)
  searchRadius = searchRadius + radiusStep;
  
  low = uint32(max(1, xFirst - ceil(searchRadius * xDiff)));
  high = uint32(min(size(Xs,1), xFirst + ceil(searchRadius * xDiff)));
  
  if high <= low, continue; end
  
  range = low:high;
  
  %[yDists,xLoc] = min(abs(target(2) - Ys(range,:)));
  [~,xLoc] = min(abs(target(2) - Ys(range,:)));
  %get which column vector is the closest
  %[~,colIndex] = min(yDists);
  
  colIndex = 1;
  
  yValue = Ys(range(xLoc(colIndex)),colIndex);
  xValue = Xs(range(xLoc(colIndex)),colIndex); % could be empty
end

end