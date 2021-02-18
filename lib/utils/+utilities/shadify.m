function colormatrix = shadify(color, nShades, shadeDepth, method)
%% SHADIFY Create shades symmetrically around input color matrix.
arguments
  color (:,3) double {mustBeInRange(color,0,1,'inclusive')}
  nShades (1,1) double = 5
  shadeDepth (1,1) double {mustBeInRange(shadeDepth,0,1,'inclusive')} = 0.67
  method (1,1) string {isValidMethod(method)}="linear"
end

method = isValidMethod(method);

nColors = size(color,1);

colormatrix = zeros(nShades,3,nColors);
for c = 1:nColors
  thisColor = color(c,:);
  % dim and brighten
  thisColorRange = [brighten(color,-shadeDepth);thisColor;brighten(color,shadeDepth)];
  if nShades == 3
    colormatrix(:,:,c) = thisColorRange;
    continue
  end
  colormatrix(:,:,c) = interp1( ...
    1:3, ...
    thisColorRange, ...
    linspace(1,3,nShades), ...
    method ...
    );
  
end




end


function varargout = isValidMethod(method)

allowed = [ ...
  "linear", "nearest", "next", ...
  "previous", "pchip", "cubic", ...
  "v5cubic", "makima", "spline" ...
  ];

method = validatestring(method,allowed);
if nargout
  varargout{1} = string(method);
end
end