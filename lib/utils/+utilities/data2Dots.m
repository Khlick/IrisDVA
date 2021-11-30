function [values,densities,boundaryLine,sortOrder] = data2Dots(data,type,histArgs,kdeArgs,options)
% data2Dots Create dot strip values for univariate data.
% Histogram arguments are used for both discrete and continuous type. Setting
% type to continuous will use the histogram to create bins and then fit the
% points inside the kernel density estiamte.

%% Validate
arguments
  data (:,1) double
  type (1,1) string {mustBeMember(type,["discrete","continuous"])} = "discrete"
  histArgs.nbins {isValidBinCount} = []
  histArgs.BinMethod (1,1) string {isValidBinMethod} = "fd"
  histArgs.BinWidth (1,:) double = []
  histArgs.BinLimits (1,2) double = nan(1,2)
  kdeArgs.Bandwidth {isValidBandwidth} = 0.5
  kdeArgs.Kernel {isValidKernel} = "epanechnikov"
  kdeArgs.NumPoints (1,1) double = 200
  options.DensityRange {isValidRange} = []
  options.DensityOffset (1,1) double = 0.5
  options.RandomOffsets (1,1) logical = false
  options.BaselineOffset (1,1) double = 0.5
  options.Stack (1,1) double = true
end

import utilities.fastrmField
import utilities.rep
import utilities.domain

[isValidEnv,miss] = checkPoductAvailable();
if ~isValidEnv
  error( ...
    "IRIS:UTILITIES:DATA2DOTS", ...
    "Required Products missing: '%s'", strjoin(miss,", ") ...
    );
end

hArgs = histArgs;
hArgs.Normalization = 'count';

nbins = hArgs.nbins;
if ~isempty(nbins)
  hArgs = fastrmField(hArgs,["BinWidth","BinMethod","nbins"]);
else
  if isempty(hArgs.BinWidth)
    hArgs = fastrmField(hArgs,["BinWidth","nbins"]);
  else
    hArgs = fastrmField(hArgs,["BinMethod","nbins"]);
  end
end  

if any(isnan(hArgs.BinLimits))
  hArgs = rmfield(hArgs,'BinLimits');
end

hArgCell = namedargs2cell(hArgs);


%% Calculate Densities

% sort incoming data
[sortedData,sortOrder] = sort(data(:));
N = numel(sortedData);

% Determine the best histogram

if isempty(nbins)
  [counts,edges,bins] = histcounts(sortedData,hArgCell{:});
else
  [counts,edges,bins] = histcounts(sortedData,nbins,hArgCell{:});
end
nBins = numel(counts);
% get bin centers
binCenters = diff(edges)/2 + edges(1:(end-1));
if ~options.Stack
  binHalf = mean(diff(edges))/2.0;
end
% perform counts/densities
switch type
  case "discrete"
    values = rep(binCenters,1,counts);
    % get the offset for each value in the bin
    % calculate a linear spacing with options.DensityOffset from extremes
    % the following only works because we sorted the data
    densities = zeros(size(sortedData));
    for b = 1:nBins
      c = counts(b);
      if ~c, continue; end
      locs = bins == b;
      if options.RandomOffsets
        offsets = rescale(rand(1,c),options.BaselineOffset,c-options.DensityOffset);
      else
        offsets = linspace(options.BaselineOffset,c-options.DensityOffset,c);
      end
      densities(locs) = offsets;
      % stack or stagger values
      if ~options.Stack
        values(locs) = rescale(rand(1,c),binCenters(b)-binHalf*0.95,binCenters(b)+binHalf*0.95);
      end
    end
    % create the boundary
    boundaryLine.values = rep(edges,1,2);
    boundaryLine.densities = [0;rep(counts,1,2);0];
  case "continuous"
    values = sortedData;
    % supply calculation support as 10% increase in domain range
    vDom = domain(values);
    support = vDom + [-0.1,0.1].*diff(vDom);
    if isempty(kdeArgs.Bandwidth)
      kArgCell = namedargs2cell(fastrmField(kdeArgs,'Bandwidth'));
    else
      kArgCell = namedargs2cell(kdeArgs);
    end
    [pd,xi] = ksdensity(sortedData,'Function','pdf','Support',support,kArgCell{:});
    % scale pd to count density
    pd = mean(diff(edges)) * N * pd;
    % interpolate pd at bin centers (use linear because it should be close with
    % numPoints >> nBins (assumption)
    % We will use this as the max height for each data point
    pd_i = interp1(xi,pd,binCenters,'linear');
    pd_i(isnan(pd_i)) = 0;
    % calculate density offsets
    densities = zeros(size(sortedData));
    for b = 1:nBins
      c = counts(b);
      if ~c, continue; end
      locs = bins == b;
      offsets = linspace( ...
        options.BaselineOffset, ...
        max([pd_i(b) - options.DensityOffset,pd_i(b)]), ...
        c ...
        );
      
      % randomly assign density to this group
      densities(locs) = offsets(randperm(length(offsets)));
    end
    % interpolate pd at data points and correct any points outside of own
    % density
    pd_d = interp1(xi,pd,values,'linear');
    correctionRange = max( ...
      [zeros(N,1),rep(options.DensityOffset,N),pd_d-options.DensityOffset], ...
      [], ...
      2 ...
      );
    densities(densities > pd_d) = correctionRange(densities > pd_d);
    % create the boundary
    boundaryLine.values = xi;
    boundaryLine.densities = pd;
end

if ~isempty(options.DensityRange)
  % rescale the densities to new range.
  totalDomain = domain([boundaryLine.densities(:);densities(:)]);
  dRes = linRescale( ...
    [densities(:);totalDomain(:)], ...
    options.DensityRange, ...
    options.DensityOffset ...
    );
  densities(:) = dRes(1:(end-2));
  dDen = linRescale( ...
    [boundaryLine.densities,totalDomain], ...
    options.DensityRange, ...
    options.DensityOffset ...
    );
  boundaryLine.densities(1:end) = dDen(1:(end-2));
  % correct density shifts outside of range
  dOff = linRescale( ...
    [options.DensityOffset,totalDomain], ...
    options.DensityRange, ...
    options.DensityOffset ...
    );
  pd_d = interp1(xi,boundaryLine.densities,values,'linear');
  correctionRange = max( ...
    [zeros(N,1),rep(dOff(1),N),pd_d-dOff(1)], ...
    [], ...
    2 ...
    );
  densities(densities > pd_d) = correctionRange(densities > pd_d);
end



end


function v = linRescale(d,newRange,offset)
oldRange = [0,max(d)+offset];
v = ( ...
  ( ...
    (d - oldRange(1)) * (newRange(2) - newRange(1)) ...
  ) / ...
  (oldRange(2) - oldRange(1)) ...
  ) + newRange(1);
end

function [tf,missing] = checkPoductAvailable()
v = ver();
[~,pList] = matlab.codetools.requiredFilesAndProducts(mfilename('fullpath'));
requirements = string({pList.Name}');
isInstalled = ismember(requirements,{v.Name}');
tf = all(isInstalled);
missing = requirements(~isInstalled);
end

function isValidBinCount(nBins)
if isempty(nBins), return; end
if ~isscalar(nBins), error("nBins must be scalar or empty."); end
if mod(nBins,fix(nBins)), error("nBins must be quantized to integar values."); end
end

function isValidBandwidth(bw)
if isempty(bw), return; end
if ~isscalar(bw), error("Kernel BandWdith must be empty or scalar."); end
end

function isValidBinMethod(bm)
defB = ["auto","scott","fd","integers","sturges","sqrt"];
if ~ismember(lower(bm),defB)
  error("Bin Method must be one of '%s'",strjoin(defB,", "));
end
end

function isValidKernel(krn)
if isa(krn,'function_handle'), return; end
dK = ["normal","box","triangle","epanechnikov"];
if ismember(lower(krn),dK), return; end
% otherwise
error("Kernel must be a function handle or one of '%s'.",strjoin(dK,", "));
end

function isValidRange(rg)
if isempty(rg), return; end
if numel(rg) == 2 && issorted(rg), return; end
error("DensityRange must be empty or sorted 2-element vector.");
end
