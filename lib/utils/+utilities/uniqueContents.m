function C = uniqueContents(cellAr)
% UNIQUECONTENTS Validate cell contents for multiple cells. 
if ~iscell(cellAr)
  C = cellAr;
  return;
end
contents = cell(1,numel(cellAr));
for i = 1:numel(cellAr)
  this = cellAr{i};
  while iscell(this) && (numel(this) == 1 || ~iscellstr(this))%#ok
    this = [this{:}];
  end
  contents{i} = this;
end
% if all equal return first
if numel(contents) == 1 || isequal(contents{:})
  C = contents{1};
  return
end

% if only 2 elements, return them
n = length(contents);
if n == 2
  C = contents;
  return
end

% if more than 2, reduce to only unique values
inds = 1:n;
keep = ones(n,1);
for i = inds
  replicates = false(1,n);
  thisRep = cellfun( ...
    @(cnt) isequal(contents{i},cnt), ...
    contents(inds ~= i), ...
    'UniformOutput', true ...
    );
  replicates(inds ~= i) = thisRep;
  keep(i) = min([i,find(replicates)]);
end

%return
C = contents(unique(keep));
end