function S = butterFilter(Y,Fs,f)
% butterFilter Perform digital butterworth filtering of the data
% 'y' value in structs in filtered in place
% input struct S is expected to be of type returned by IrisData.copyData();

arguments
  Y (:,:) double
  Fs (1,1) double
  f.type (1,1) string {mustBeMember(f.type,["lowpass","bandpass","highpass"])} = "lowpass"
  f.freq (1,:) double = 100
  f.ord (1,1) double = 4
end


%determine filter parameters
switch lower(f.type)
  case "bandpass"
    ftype = 'bandpass';
    flt = sort(2 .* f.freq);
  case "highpass"
    ftype = 'high';
    flt = 2*max(f.freq);
  otherwise
    ftype = 'low';
    flt = 2*f.freq(1);% use low
end
if any(flt./Fs >= 1)
  error("Filter frequencies must be less than the Nyquist frequency (%0.2fHz)",Fs/2);
end
    
try
  ButterParam('save');
catch e
  fprintf(2,'ButterParam.mat not accessible: "%s"\n',e.message);
end

% build filter
[b,a] = ButterParam(f.ord,flt./Fs,ftype);

% filter as matrix?
yLen = size(Y,1);
% get column means for reducing the zero offset artifacts from filtering.
mu = mean(Y,1,'omitnan');
  
% find and replace nans with mu
[rowNans,colNans] = find(isnan(Y));
for rc = 1:length(rowNans)
  Y(rowNans(rc),colNans(rc)) = mu(colNans(rc));
end

% pad the array with a few hundred samples of the local means
npts = max(ceil([0.01*yLen;10]));
preVals = mean(Y(1:npts,:),1,'omitnan');
postVals = mean(Y((end-(npts-1)):end,:), 1, 'omitnan');

Y = [preVals(ones(npts,1),:);Y;postVals(ones(npts,1),:)];

% subtract the colmeans
Y = Y-mu;

% pad and filter
S = FiltFiltM(b, a, Y);
% add Mu back in
S = S(npts+(1:yLen),:) + mu;
% replace nan positions with nan
for rc = 1:length(rowNans)
  S(rowNans(rc),colNans(rc)) = nan;
end
% return
end