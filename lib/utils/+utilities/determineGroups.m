function groupInfo = determineGroups(inputArray,inclusions,dropExcluded,isCustom)
% DETERMINEGROUPS Create a grouping vector from a table or array input.
% 

if nargin < 4, isCustom = false; end
if nargin < 3, dropExcluded = true; end %work just as prior to 2021 release
if nargin < 2, inclusions = true(size(inputArray,1),1); end
if numel(inclusions) ~= size(inputArray,1)
  error( ...
    [ ...
    'Inclusion vector must be logical array ', ...
    'with the same length as the input array.' ...
    ] ...
    );
end
idNames = sprintfc('ID%d', 1:size(inputArray,2));
nIDs = length(idNames);
if istable(inputArray)
  inputTable = inputArray;
  inputArray = table2cell(inputArray);
elseif iscell(inputArray)
  inputTable = cell2table( ...
    inputArray, ...
    'VariableNames', sprintfc('Input%d', 1:size(inputArray,2)) ...
    );
elseif ismatrix(inputArray)
  inputTable = array2table( ...
    inputArray, ...
    'VariableNames', sprintfc('Input%d', 1:size(inputArray,2)) ...
    );
  inputArray = table2cell(inputTable);
else
  error("IRISDATA:DETERMINEGROUPS:INPUTUNKNOWN","Incorrect input type.");
end

idNames = matlab.lang.makeValidName(idNames);

theEmpty = cellfun(@isempty, inputArray);
if any(theEmpty)
  inputArray(theEmpty) = {'empty'};
end


% loop and create individual grouping vectors
groupVec = zeros(size(inputArray));
for col = 1:size(inputArray,2)
  if isCustom
    % here we assume inputArray is numeric group numbers
    % so we unpack the cell array we created above
    groupVec(:,col) = [inputArray{:,col}];
  else
    groupVec(:,col) = createGroupVector(inputArray(:,col));
  end
end

% Drop exclusions
if dropExcluded
  vecLen = sum(inclusions);
  groupVec(~inclusions,:) = [];
  inputTable(~inclusions,:) = [];
else
  vecLen = height(inputTable);
  groupVec(~inclusions,:) = 0;
end



% get the group mapping
[uGroups,groupIdx,Singular] = unique(groupVec,'rows');
groupTable = [array2table(uGroups,'VariableNames',idNames),inputTable(groupIdx,:)];
groupTable.Combined = rowfun( ...
  @(x)join(string(x),'::'), ...
  inputTable(groupIdx,:), ...
  'SeparateInputs', false, ...
  'OutputFormat', 'uniform' ...
  );
% get counts
if any(~uGroups)
  % ensure 0 if exclusions are present
  Singular = Singular - 1;
end
  
tblt = tabulate(Singular);

% tblt arrives sorted because we let unique(groupVec) sort Singular. So we
% can map value and counts to rows of the groupTable
groupTable.Counts = tblt(:,2);
groupTable.SingularMap = tblt(:,1);
groupTable.Frequency = tblt(:,3);

%output
groupInfo = struct();
groupInfo.Singular = Singular;
% Setup group vector for use with grpstats in the Statistics and machine
% learning toolbox.
groupInfo.Vectors = mat2cell(groupVec, ...
  vecLen,...
  ones(1,nIDs) ...
  );

% Reorganize table
groupInfo.Table = movevars( ...
  groupTable, ...
  {'SingularMap','Counts'}, ...
  'After', ...
  idNames{end} ...
  );
end


%% Helper Functions
function vec = createGroupVector(factorInput)
nFactors = numel(factorInput);
factorVec = 1:nFactors;
grpID = 1; %start at group == 1
vec = zeros(nFactors,1);
for iter = factorVec
  thisValue = factorInput(iter);
  didAsgn = false(nFactors,1);
  for idx = factorVec
    if vec(idx), continue; end %already labelled
    if isequal(thisValue,factorInput(idx))
      didAsgn(idx) = true;
      vec(idx) = grpID;
    end
  end
  if ~any(didAsgn), continue; end
  grpID = grpID + 1;
end

%{
% try new algorithm above
checkPattern = nchoosek(1:nFactors,2);
tests = false(nFactors);
for iter = 1:size(checkPattern,1)
  idx = checkPattern(iter,:);
  check = isequal(factorInput(idx(1)),factorInput(idx(2)));
  tests(idx(1),idx(2)) = check;
  tests(idx(2),idx(1)) = check;
end
[r,c] = find(tests);
inds = zeros(numel(r),2);
for iter = 1:numel(r)
  inds(iter,:) = sort([r(iter),c(iter)]);
end

inds = unique(inds,'rows','stable');
indVals = unique(inds(:,1),'stable');
nGrouped = size(indVals,1);
groupCounter = 1;
vec = zeros(nFactors,1);
for iter = 1:nGrouped
  thisIdx = inds(inds(:,1) == indVals(iter),:);
  thisIdx = unique(thisIdx(:));
  skips = false(numel(thisIdx),1);
  for jter = 1:numel(thisIdx)
    if vec(thisIdx(jter)) 
      skips(jter) = true;
      continue
    end
    vec(thisIdx(jter)) = groupCounter;
  end
  if all(skips), continue; end
  groupCounter = groupCounter + 1;
end

leftOvers = vec == 0;
vec(leftOvers) = groupCounter + ((1:sum(leftOvers))' - 1);
%}
end
