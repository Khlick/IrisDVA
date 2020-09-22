function isValidParamList(arg,options)
%ISVALIDPARAMLIST Errors if the paramList is not multiple of 2 and contained in options.

import utilities.ValidStrings;

if nargin < 2
  options = "";
else
  options = string(options);
end

if mod(numel(arg),2)
  % not valid
  error("Parameter list length is expected to be a multiple of 2.");
end

params = string(arg(1:2:end));
for p = params(:)'
  tf = ValidStrings(p,options);
  if ~tf
    error("Parameter, %s, is not allowed.",p);
  end
end

end

