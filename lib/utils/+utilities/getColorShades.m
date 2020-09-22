function colormatrix = getColorShades(nshades,ncolors,interpolate)
% GETSHADES Get a color array nshades x (rgb) x ncolors
if nargin < 3
  interpolate = false;
end
if nargin < 2
  ncolors = 1;
end

assert(nshades > 0);

cnames = [ ... %light orange
  "7E3704"; ...
  "ED930B"; ...
  "F8C94A"; ...
  ... %teals
  "2D4344"; ...
  "779FA1"; ...
  "B7DBDC"; ....
  ... %browns
  "3C210F"; ...
  "6F5829"; ...
  "C9BE8B"; ...
  ... %blues
  "182163"; ...
  "3F57A1"; ...
  "ACBDDC"; ...
  ... %purples
  "4A1B51"; ...
  "88498F"; ...
  "D2ACD5"; ...
  ... %reds
  "9F2D0E"; ... % -67%
  "F35A1C"; ... % 0%
  "FCB26F"; ... % +67%
  ... %dark purples
  "352132"; ...
  "564154"; ...
  "C0B3BF" ...
  ];

nMax = length(cnames)/3;
interpolate  = interpolate && (ncolors > nMax);

% rgbvalues from hex
cvals = zeros(numel(cnames),3);
for i = 1:numel(cnames)
  cvals(i,:) = sscanf(cnames(i),'%2x%2x%2x',[1 3])/255;
end

% convert to put columns as rows as rgb, cols and colors and dim 3 as shades for
% interp if needed
cvals = permute(reshape(cvals',3,3,[]),[3,1,2]);

if interpolate
  % interpolate between colors get cvals(:,:,3) to ncolors size
  cvals = interp1( ...
    1:nMax, ...
    cvals, ...
    linspace(1,nMax,ncolors), ...
    'pchip' ...
    );
  % clip anything that exceeds color bounds
  cvals(cvals > 1) = 1;
  cvals(cvals < 0) = 0;
end

% permute again to get the colors in 3 dims and
cvals = permute(cvals,[3,2,1]);

% build the final color matrix
colormatrix = zeros(nshades,3,ncolors);
for c = 1:ncolors
  cIdx = mod(c-1,nMax)+1;
  if nshades <= 3
    colormatrix(:,:,c) = cvals(1:nshades,:,cIdx);
  else
    thismat = cvals(:,:,cIdx);
    h = size(thismat,1);
    colormatrix(:,:,c) = interp1( ...
      1:h, ...
      thismat, ...
      linspace(1,h,nshades), ...
      'pchip' ...
      );
    
  end
end

colormatrix(colormatrix > 1) = 1;
colormatrix(colormatrix < 0) = 0;
end