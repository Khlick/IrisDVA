function ci = bootstrapCI(data,stat,level,B)
if nargin < 4, B=10000; end
if nargin < 3, level = 0.95; end
if nargin < 2 || isempty(stat), stat = 'mean'; end




N = length(data);
samps = data(randi(N,N,B));

if ~isa(stat,'function_handle')
  stat = str2func(stat);
end

boots = stat(samps);
probs = sort((1-level)/2 + [level,0]);

ci = quantile(boots,probs);

end