function tf = arrayContains(arr, ands, ors, without, ignoreCase)
% Check if an array contains all values within AND not those without, configureable case sensitivity.

arguments
  arr (:,:) string {mustBeNonempty,mustBeVector(arr)}
  ands (:,:) string {mustBeVector(ands)}
  ors (:,:) string {mustBeVector(ors)} = []
  without (:,:) string {mustBeVector(without)} = []
  ignoreCase (1,1) logical = false
end

% get the input shape to store the output
sz = size(arr);
arr = arr(:);
% make a matrix for all of the conditions
nWithin = numel(ands);
nOr = numel(ors);
nWithout = numel(without);

nAny = nWithin + nOr;

tf = false(numel(arr), nAny + nWithout);
% within
for w = 1:nWithin
  tf(:,w) = contains(arr,ands(w),'IgnoreCase',ignoreCase);
end
% or
for w = nWithin + (1:nOr)
  idx = w-nWithin;
  tf(:,w) = contains(arr,ors(idx),'IgnoreCase',ignoreCase);
end
% without
for w = nAny + (1:nWithout)
  idx = w-nAny;
  tf(:,w) = ~contains(arr,without(idx),'IgnoreCase',ignoreCase);
end

%output
tf = reshape( ...
  ( ...
    all(tf(:,1:nWithin),2) | ...
    all(tf(:,nWithin+(1:nOr)),2) ...
  ) & ...
  all(tf(:,nAny+(1:nWithout)),2), ...
  sz ...
  );
end

function mustBeVector(arr)
if isempty(arr), return; end
if isscalar(arr), return; end
if ~isvector(arr), error("Array must be a vector."); end
end