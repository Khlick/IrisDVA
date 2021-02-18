function ci = bootstrapAlong(data,dim,stat,level,B,method)
arguments
  data (:,:) double
  dim (1,1) uint8 {mustBePositive} = 2 %along columns i.e. agg rows
  stat (1,1) function_handle = @mean
  level (1,1) double {mustBeInRange(level,0,1,"exclude-lower","exclude-upper")} = 0.95
  B (1,1) uint64 {mustBePositive} = 10000
  method (1,1) string {mustBeMember(method,["BCa","Percentile"])} = "BCa"
end
import utilities.bootstrap;


switch dim
  case 1
    % along rows, i.e. aggregate each column
    N = size(data,2);
    s = @(i)substruct('()',{':',i});
    ci = zeros(2,N);
  case 2
    % along columns, i.e. aggregate each row
    N = size(data,1);
    s = @(i)substruct('()',{i,':'});
    ci = zeros(N,2);
  otherwise
    error("BOOTSTRAPALONG:UNSOPPORTEDDIM","Dimension arguemnt unsupported.");
end


for n = 1:N
  [~,thisci] = bootstrap.getConfidenceIntervals(subsref(data,s(n)),stat,level,B,method);
  ci = subsasgn(ci,s(n),thisci);
end

end