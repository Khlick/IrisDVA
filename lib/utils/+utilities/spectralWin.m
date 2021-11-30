function coefs = spectralWin(winType,L)
%SPECTRALWIN Compute a windowing vector, returned as a column vector.(NOT WORKING)

arguments
  winType (1,1) string {validWindow(winType)} = "rect"
  L (1,1) int64 {mustBeGreaterThan(L,0)} = 100
end


[~,winType] = utilities.ValidStrings(winType, wins());
winType = string(winType);

N = double(L-1);


x = 0:N;

switch winType
  case "rect"
    coefs = ones(L,1);
  case "hann"
    
  case "hamming"
    
  case "barthann"
    
  case "bartlett"
    
  case "blackman"
    
  case "chebwin"
    
  case "gauss"
    x = x - fix(L/2);
    s = std(x,1)/2;
    alpha = N/(2*s);
    coefs = exp( -1/2*(alpha*x/(N/2)).^2 );
  case "tukey"
    
  case "triang"
    
  case "taylor"
    
end

end

%% Validation
function validWindow(w)
import utilities.ValidStrings

winFxs = wins();

[tf,~] = ValidStrings(lower(w),winFxs);
if ~tf
  error("Window function expected to be one of: {%s}.",strjoin(winFxs,", "));
end

end


function winFxs = wins()

winFxs = [ ...
    "rect", ...
    "hann", ...
    "hamming", ...
    "barthann", ...
    "bartlett", ...
    "blackman", ...
    "chebwin", ...
    "gauss", ...
    "tukey", ...
    "triang", ...
    "taylor" ...
  ];

end
