function [mags,freqs,ci,varargout] = windowedPSD(Y,fs,windowParams,fftParams,ciParams)

arguments
  Y (:,1) double
  fs (1,1) double
  windowParams.windowDuration (1,1) double = fix(length(Y)/5)/fs;
  windowParams.windowOverlap (1,1) double  = fix(length(Y)/5)/fs / 2;
  windowParams.windowFx (1,1) string {isValidWindow(windowParams.windowFx)} = "hann"
  windowParams.deMeanWindows (1,1) logical = false
  fftParams.NFFT (1,1) double = 2^nextpow2(length(Y))
  fftParams.TruncateFrequency (1,1) uint64 = 0
  ciParams.returnCI (1,1) logical = true
  ciParams.confidenceType (1,1) string = "BCa"
end

if windowParams.windowOverlap >= windowParams.windowDuration
  error("Overlap duration must be shorter than the window duration.");
end

import utilities.bootstrap

doAngle = nargout > 3;

% K = (N-ovl) / (L-ovl)

N = length(Y);
L = fix(windowParams.windowDuration * fs);
overlap = fix(windowParams.windowOverlap * fs);
K = (N-overlap) /  (L-overlap);

if rem(K,floor(K))
  % update the overall length by padding with zeros
  K = floor(K)+1;
  newLength = K*L - K*overlap + overlap;
  nAppend = newLength - N;
  Y(end+(1:nAppend)) = 0;
  N = newLength;
end

columnInds = (0:(K-1))*(L-overlap);
rowInds = (1:L)';


% window
wFx = str2func(windowParams.windowFx);
h = wFx(L);
if ~iscolumn(h)
  h = h(:);
end


% fourier parameters
if ~fftParams.NFFT
  fftParams.NFFT = 2^nextpow2(N);
end

Y = hilbert(Y); %analytical signal.

dT = 1/fs;
nyquistFreq = fs/2;
nFreqs = fix(fftParams.NFFT/2) + 1;
freqs = linspace(0,1,nFreqs)' * nyquistFreq;
factor = dT/sum(h.^2); % for psd

x = ((1:L)' - 1) / fs;

if fftParams.TruncateFrequency
  stopIndex = find(freqs <= fftParams.TruncateFrequency,1,'last');
else
  stopIndex = nFreqs;
end

mags = nan(stopIndex,K);

parfor k = 1:K
  ix = rowInds + columnInds(k);
  sig = Y(ix); %#ok<*PFBNS>
  % Handle missing data
  sig(isnan(sig)) = mean(sig,'omitnan');
  if windowParams.deMeanWindows
    % remove linear
    cfs = polyfit(x,sig,1);
    sig = sig - polyval(cfs,x);
  end
  sig = sig .* h;
  % center the signal and compute nfft size fourier
  fSig = fft(sig,fftParams.NFFT);
  m = abs(fSig) .^ 2;
  mags(:,k) = m(1:stopIndex);
end

% average and correct for windowing
if ciParams.returnCI
  B = 10000;
  ci = zeros(size(mags,1),2);
  for b = 1:size(mags,1)
    boots = bootstrap.getBootstraps( ...
      factor * mags(b,:)', ...
      @(x)mean(x,'omitnan'), ...
      B ...
      );
    if strcmpi(ciParams.confidenceType,"bca")
      knives = bootstrap.getJackknife(factor * mags(b,:)',@(x)mean(x,'omitnan'));
    else
      knives = [];
    end
    ci(b,:) = bootstrap.genCiFromBoots( ...
      boots, ...
      0.95, ...
      ciParams.confidenceType, ...
      'actual', mean(factor * mags(b,:)','omitnan'), ...
      'knives', knives ...
      );
  end
else
  ci = nan(0,2);
end
mags = factor * mean(mags,2);
freqs = freqs(1:stopIndex);
if doAngle
  angs = mod(angle(fft(Y,fftParams.NFFT)),2*pi);
  varargout{1} = angs(1:stopIndex);
end
end



function isValidWindow(fxName)

h = str2func(fxName);
try
  out = h(2);
catch me
  error("Window function mast take a scalar length arg.");
end

if numel(out) ~= 2
  error("Window function mast take a scalar length arg.");
end

end