function value = ternary(condition,whenTrue,whenFalse)
  %% TERNARY An inline if-else that is 'vectorized'
  % force logical;
  condition = ~~condition;
  shape = size(condition);
  n = numel(condition);
  % use cell array for now, later switch depending on true/false types
  % if types are the same size and type, convert condition to [1,2]
  value = cell(shape);
  for idx = 1:n
    if condition(idx)
      value{idx} = whenTrue(min([idx,end]));
    else
      value{idx} = whenFalse(min([idx,end]));
    end
  end
  if isscalar(condition)
    while iscell(value)
      value = value{1};
    end
    return
  end
  % convert to inner class if all the same
  if all(cellfun(@(v)string(class(v)),value) == string(class(value{1})),"all")
    value = reshape(cat(1,value{:}),shape);
  end
end

