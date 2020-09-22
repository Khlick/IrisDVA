function N = getNumWorkers()
% local function to handle parpool generation
% In the future, I may have Iris force open the default pool... for now, only
% use a parpool if it already exists
try
  p = gcp('nocreate');
catch x
  p = [];
  fprintf('\nParallel Computing Toolbox not installed!\n');
end
if isempty(p)
  N=0;
else
  N=p.NumWorkers;
end
end