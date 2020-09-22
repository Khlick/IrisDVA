function varargout = subtractBaseline(S,type,npts,ofst,dataField)
% SUBTRACTBASELINE Calculate a constant (or fit) value to subtract from each
% "y" value in the data struct array, S.
%   S is modified in place and returned

if nargin < 5, dataField = 'y'; end
nData = numel(S);
doFit = contains(lower(type),'sym');
[baselineValues(1:nData)] = deal(struct('devices',{{}},'baselines',{[]}));

if doFit, checkFitWarn(); end

% check for an existing parpool but don't create one.
nLiveWorkers = getNumWorkers();
parfor (d = 1:nData,nLiveWorkers)
  this = S(d);
  ndevs = this.nDevices;
  thisX = [];
  inds = [];
  theseBaselines = struct('devices',{{}},'baselines',{[]});
  for v = 1:ndevs
    thisY = this.(dataField){v};
    thisLen = size(thisY,1);
    
    switch lower(type)
      case 'beginning'
        inds = (1:npts)+ofst;
      case 'end'
        inds = thisLen-ofst-((npts:-1:1)-1);
      case {'asym','sym'}
        % only collect thisX if needed for fit
        thisX = this.x{v};
        % start
        inds = (1:npts)+ofst;
        if strcmpi(type,'sym')
          % is symetrical, append end
          inds = [inds,thisLen-ofst-((npts:-1:1)-1)]; 
        end
    end
    % validate inds
    inds(inds <= 0) = [];
    inds(inds > thisLen) = [];
    % make sure inds are unique
    inds = unique(inds); %sorted

    if doFit
      % create fit based on inds for each line in the matrix
      bVal = zeros(size(thisY));
      if isa(thisX,'function_handle')
        thisX = thisX();
      end
      if isrow(thisX) || iscolumn(thisX)
        thisX = thisX(:);
        thisX = thisX(:,ones(1,size(thisY,2)));
      end
      % construct a matrix of line data for all Xs\Ys
      for i = 1:size(thisY,2)
        xfit = [ones(length(inds),1), thisX(inds,i)];
        yfit = thisY(inds,i);
        % fit to a smoothed data vector to prevent the line from being wierd
        %betas = xfit\smooth(yfit,0.9,'rlowess'); %smooth is super slow here
        betas = xfit\smooth(yfit,50);
        % y = b0 + b1*x;
        bVal(:,i) = betas(1) + betas(2).*thisX(:,i);
      end
      baselines = bVal;
    else
      bVal = mean(thisY(inds,:),1,'omitnan');
      % make any nans into 0 so we don't cause all pts to be nans
      bVal(isnan(bVal)) = 0;
      baselines = bVal;
      % create matrix
      bVal = bVal(ones(thisLen,1),:);
    end

    % update values
    this.(dataField){v} = thisY - bVal;
    theseBaselines.devices{v} = this.devices{v};
    theseBaselines.baselines{v} = baselines;
  end
  % reassign
  baselineValues(d) = theseBaselines;
  S(d) = this;
end

varargout{1} = S;
varargout{2} = baselineValues;

% local function to handle parpool generation
% In the future, I may have Iris force open the default pool... for now, only
% use a parpool if it already exists
function N = getNumWorkers()
  p = gcp('nocreate');
  if isempty(p)
    N=0;
  else
    N=p.NumWorkers;
  end
end
% local function which detects and throws warning if it hasn't been encountered
% before
function checkFitWarn()
  [~,wID] = lastwarn();
  if ~strcmpi(wID,'IRIS:SUBTRACTBASELINE:FIT')
    warning('IRIS:SUBTRACTBASELINE:FIT', ...
      'Sym and Asym methods can be very slow, be patient.' ...
      );
  end
end
end