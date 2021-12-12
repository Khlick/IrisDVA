function tf = isWithinRange(values,extents,inclusive)
%% ISWITHINRANGE Validates if a value is within a given range [inclusive by default]
%  Set inclusive (3rd arg) to false if the value must be between but not
%  matching provided extents. Inclusive argument may be a length 2 boolean to
%  indicate if [start,end] should be inclusive. Default behavior is [true,true].

arguments
  values (:,1) double
  extents (1,2) double = [0,1]
  inclusive (1,2) logical = [true,true]
end

comps = utilities.ternary(inclusive,{@ge,@le},{@gt,@lt});

nVal= numel(values);
tf = false(nVal,2);

for v = 1:nVal
  for t = 1:2
    tf(v,t) = comps{t}(values(v),extents(t));
  end  
end

tf = all(tf,2);


end
