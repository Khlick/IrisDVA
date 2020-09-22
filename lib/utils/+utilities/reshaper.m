function [datout, varargout] = reshaper(dat, winlen, overlap, expand)
%reshaper Reshapes input vector into winlen rows with overlap in common. If data
%input in a matrix, datout will be [winlen, Kl, ncols]. If expand is set to
%true, the function assumes dat is a time vector and will infer Fs from the
%samples. DO NOT SET expand TO TRUE UNLESS dat IS A TIME VECTOR.
%
%[rseg, Kl] = reshaper(dat, winlen, ovlp, expand);
%K = (M-overlap)/(L-overlap)
%     K           -  # of segments
%     M           -  Length of input data (dat)
%     overlap     -  #of samples to overlap
%     L           -  Length of window segments
%%%-------------------------------------------%%%
if nargin < 4
  expand = false;
end
  
[m,n]=size(dat);

%organize
if m==1
    datin = dat(:);
else
    datin = dat;
end


for ii = 1:n
  [datout(:,:,ii), Kl] = reshaperfxn(datin(:,ii), winlen, overlap);
end

if expand
  fs = 1/mean(diff(datin(:,1)));
  for ii = 1:n
    datout(:,:,ii) = vecfix(datout(:,:,ii), fs);
  end
end

switch nargout
  case 1
    return
  case 2
    varargout{1} = Kl;
end

end


function [datout, Kl] = reshaperfxn(datin, L, overlap)

%Pad if shorter than window
dl = length(datin)-L;
if dl<0
    datin = [datin; zeros(-dl, 1)];
end

%Get info on number of output cols
M = length(datin);
K = (M-overlap)./(L-overlap);
Kl = fix(K);
if Kl ~= K
    Kl = Kl+1;
    %syms Ml;
    %Mnew = solve((Ml-overlap)./(L-overlap) == Kl, Ml);
    Mnew = Kl*L - Kl*overlap + overlap;
    diffs = double(Mnew)-M;
    datin = [datin; nan(diffs,1)];
end

%put data into windowed columns with overlap
coli = 1 + [0:(Kl-1)]*(L-overlap);
rowi = [1:L]';
%make empty
datout = nan(L, Kl, class(datin));
datout(:) = datin(rowi(:,ones(1,Kl))+coli(ones(L,1),:)-1);

end

% ----- Fill zeros of timevector in
function vfxd = vecfix(dat, Fs)
[rs, cs] = find(isnan(dat));
if isempty(rs)
    vfxd = dat;
    return
end
rs = unique(rs);
cs = unique(cs);
if length(cs) > 1
    if cs(1) == 1 && rs(1) == 1
        cs(1) = [];
        rs(1) = [];
    else
        return
    end
elseif rs(1) == 1 && length(cs) == 1
    vfxd = dat;
    return
end

tstart = dat(rs(1)-1,cs)+1/Fs;
dat(rs, cs) = (tstart:1/Fs:length(rs)/Fs+tstart-1/Fs);
vfxd = dat;
end