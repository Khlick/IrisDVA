function [ outvec ] = rep( X, N, each, varargin )
%REP  Repeat an element or vector N times with individual elements repeated
%each times. 
%   REP willl repeat scalar, vector, or matrix N times. If 'each' is a scalar,
%   then all elements in X will be repeated N.*['each'] times. If 'each' is a
%   vector, then numel(each) must equal numel(X). Optionally, dimension
%   args can be passed to the name, value pair, 'dims'. A vector as long as
%   the desired dimensions is required. For a 2-D output, input 'dims',
%   {r,c}. Setting any elements of the 'dims' argument to [], will let the
%   reshape function automatically determine that dimension's count based
%   on other provided data. REP returns a column organized vector unless
%   'dims' argument is provided. If no 'dims' argument is '[]', rep
%   will assume the dimension after the last provided will handle overflow.
%
%  Usage:
%   repMat = rep(inputMatrix, numRepeatsAll, numRepeatsEach, 'dims',
%   {numRow,numCols,...});
%  Example:
%   % NOTE: output 'dims' can be a transpose of the input matrix, or any other
%   %   reshaped form.
%   m = rep([1;2], 1, [1;2],'dims',{1,[]}) 
%   >>m = 
%        1     2     2
%


%% Parse
if nargin < 3 || strcmpi(each, 'dims')
  each = 1;
  if nargin > 3
    varargin = ['dims', varargin(:)'];
  end
end

p = inputParser;

addRequired(p, 'X', @(x) true);
addOptional(p, 'N', 1, @(x)validateattributes(x,{'numeric'}, {'nonempty'}));
addOptional(p, 'each', 1, ...
  @(x)validateattributes(x, {'numeric'}, {'nonempty'}));
addParameter(p, 'dims', {[]}, ...
  @(x)validateattributes(x, {'numeric', 'cell'}, {}));
addParameter(p, 'byRow', false, ...
  @(x)validateattributes(x,{'logical','numeric'},{'nonempty'}));
addParameter(p, 'squeeze', false, ...
  @(x)validateattributes(x,{'logical','numeric'},{'nonempty'}));

parse(p, X, N, each, varargin{:});

in = p.Results;

%% Create Each vector

if numel(in.each) == 1
  in.each = each(ones(size(in.X)));
else
  if numel(in.each) ~= numel(in.X)
    error('REP:EACHERROR', ...
      'Length of ''each'' must have %d elements (as in X)', numel(in.X));
  end
end

if in.byRow
  in.X = in.X.';
  in.each = in.each';
end

%% Handle Rep input
if in.N > 1
  sz = size(in.X);
  if ~any(sz == 1), sz = [sz,1]; end
  sz(sz~=1) = 0;
  sindx = find(logical(sz),1); %find the first singleton for repeating.
  sz(sindx) = in.N;
  sz(setdiff(1:end,sindx)) = 1;
  sz = num2cell(sz);
  in.X = repmat(in.X,sz{:});
  in.each = repmat(in.each,sz{:});
end

%% Runlength decode

outvec = in.X; %if only N was supplied and all each are 1

if ~all(each == 1)
  in.RepVec = in.each;
  rr = in.RepVec > 0;
  a = cumsum(in.RepVec(rr));
  b = zeros(a(end),1);
  b(a-in.RepVec(rr)+1) = 1;
  tmp = in.X(rr);
  outvec = tmp(cumsum(b)); %an each argument was supplied
end 

%% Reshape

if all(cellfun(@isempty,in.dims,'unif',1))
  outvec = outvec(:);
  return;
end
if ~any(cellfun(@isempty, in.dims,'unif',1))
  in.dims = [in.dims{:}, {[]}];
end

outvec = reshape(outvec, in.dims{:});

if in.squeeze
  outvec = squeeze(outvec);
end

end
