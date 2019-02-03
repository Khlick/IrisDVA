function S = fastrmField(S, fname)
      
fn = fieldnames(S);
fKeep = cellfun(@isempty, regexpi(fn,strjoin(fname,'|')));
fdat = struct2cell(S);
S = cell2struct(fdat(fKeep), fn(fKeep),1);
      
end
