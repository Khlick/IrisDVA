function result = computeCorrection(pts,data,target)
  % computeCorrection Compute the correction vector

  %method input unused

  nZ = 5;

  nPts = size(pts,1);
  nData = size(data,1);
  
  cutoff = ceil(nData*0.0075);

  % get num elements above and below limits
  rLen = sum(data(:,1) > pts(end,1));
  edgeCases = false(1,2);
  if rLen < cutoff
    rightEdge = data(end,1);
    edgeCases(2) = true;
  else
    rightEdge = pts(end,1);
  end
  lLen = sum(data(:,1) < pts(1,1));
  if lLen < cutoff
    leftEdge = data(1,1);
    edgeCases(1) = true;
  else
    leftEdge = pts(1,1);
  end

  inds = data(:,1) >= leftEdge & data(:,1) <= rightEdge;

  % gather data
  Y = data(inds,2);
  X = data(inds,1);
  N = sum(inds);
  % subtract line from front to end

  b_0 = [ones(2*nZ,1),X([1:nZ,end-((nZ:-1:1)-1)])] \ Y([1:nZ,end-((nZ:-1:1)-1)]);
  LTrend = ([ones(N,1),X(:)] * b_0);
  Y_flat = Y - LTrend;

  if nPts > 2
    brk = pts(2:(end-1),1);
    Y_flat = detrend(Y_flat,7,brk,'SamplePoints',X);
  else
    Y_flat = detrend(Y_flat,7);
  end

  if all(edgeCases) || all(~edgeCases) % not both the same
    % simply add the linear trendback
    Y_flat = Y_flat + LTrend;
  elseif edgeCases(1)
    % left edge is at boundary: set aligned to right edge
    Y_flat = Y_flat + LTrend(end);
  elseif edgeCases(2)
    % right edge is at boundary: set aligned to left edge
    Y_flat = Y_flat + LTrend(1);
  end
  % store the result array
  result = struct();
  result.XData = X;
  result.YData = Y_flat;
  result.target = target;  
end

