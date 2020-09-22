function tf = isWithinRange(values,extents,inclusive)
%% ISWITHINRANGE Validates if a value is within a given range [inclusive by default]
%  Set inclusive (3rd arg) to false if the value must be between but not
%  matching provided extents. Inclusive argument may be a length 2 boolean to
%  indicate if [start,end] should be inclusive. Default behavior is [true,true].

if nargin < 3, inclusive = [true,true]; end
if numel(inclusive) < 2, inclusive = inclusive([end,end]); end
inclusive = logical(inclusive);

if inclusive(1)
  lComparitor = @ge;
else
  lComparitor = @gt;
end
if inclusive(2)
  rComparitor = @le;
else
  rComparitor = @lt;
end

nVal= numel(values);

tf = false(nVal,2);

for i = 1:nVal
  tf(i,1) = lComparitor(values(i), extents(1));
  tf(i,2) = rComparitor(values(i), extents(2));
end

tf = all(tf,2);


end