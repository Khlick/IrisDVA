function [tf,value] = r_isFielda(S,classType)
%R_ISFIELDA Recursively search a Struct
%   Detailed explanation goes here
value = [];
tf = isa(S,classType);
if ~tf
  if isstruct(S)
    fields = fieldnames(S);
    contents = struct2cell(S);
    for i = 1:numel(fields)
      [tf,value] = utilities.r_isFielda(contents{i},classType);
      if tf, return; end
    end
  end
else
  value = S;
end

end

