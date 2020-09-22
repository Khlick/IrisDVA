function A = fastKeepField(S, fname)
      
fn = fieldnames(S);
% which names to keep
%fKeep = ~cellfun(@isempty, regexpi(fn,strjoin(fname,'|')));
fKeep = false(numel(fn),1);
for i = 1:numel(fn)
  if utilities.ValidStrings(fn{i},fname)
    fKeep(i) = true;
  end
end
% build the last struct in the array
sz = size(S);
fdat = struct2cell(S(end,end));
A(sz(1),sz(2)) = cell2struct(fdat(fKeep), fn(fKeep),1);

% If input is longer than 1 in any dimension, fill in all the values
if any(sz > 1)
  
  for i = 1:sz(1)
    for j = 1:sz(2)
      fdat = struct2cell(S(i,j));
      A(i,j) = cell2struct(fdat(fKeep), fn(fKeep),1);
    end
  end
  
end

end
