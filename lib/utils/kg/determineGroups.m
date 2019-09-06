function groupInfo = determineGroups(cellArray,inclusions)
% DETERMINEGROUPS Create a grouping vector from cell array input.
%   DETERMINEGROUPS Expects the input table, or 2-D cell array, to contain only
%   strings (char arrays) in order to determine grouping vectors. 
if nargin < 2, inclusions = true(size(cellArray,1),1); end
if numel(inclusions) ~= size(cellArray,1)
  error( ...
    [ ...
      'Inclusion vector must be logical array ', ...
      'with the same length as the input table.' ...
    ] ...
    );
end
idNames = sprintfc('ID%d', 1:size(cellArray,2));
nIDs = length(idNames);
if istable(cellArray)
  inputTable = cellArray;
  cellArray = table2cell(cellArray);
else
  inputTable = cell2table( ...
    cellArray, ...
    'VariableNames', sprintfc('Input%d', 1:size(cellArray,2)) ...
    );
end

idNames = matlab.lang.makeValidName(idNames);

theEmpty = cellfun(@isempty, cellArray);
if any(theEmpty)
  cellArray(theEmpty) = {'empty'};
end
%get classes of each element
caClass = cellfun(@class, cellArray, 'unif', 0);
groupVec = zeros(size(cellArray));
for col = 1:size(cellArray,2)
  [classes,~,groupVec(:,col)] = unique(caClass(:,col), 'stable');
  if length(classes) == 1
    switch classes{1}
      case 'char'
        iterDat = cellArray(:,col);
      otherwise
        iterDat = [cellArray{:,col}];
    end
    [~,~,groupVec(:,col)] = unique(cat(1,iterDat),'stable');
    %simple case, skip to next iteration or end
    continue
  end
  groupVec(theEmpty,col) = 0;
  for c = classes(:)'
    cin = ismember(caClass(:,col), c);
    switch c{1}
      case 'char'
        iterDat = cellArray(cin);
      otherwise
        iterDat = [cellArray{cin}];
    end
    [~,~,g] = unique(iterDat, 'stable');
    groupVec(cin) = groupVec(cin) + g;
  end
end
% subset the grouping vector
groupVec(~inclusions) = [];

% Turn Group Vector into table
groupTable = table();
for g = 1:length(idNames)
  groupTable.(idNames{g}) = groupVec(:,g);
end
groupTable.Properties.VariableNames = idNames;
[groupTable,iSort] = unique(groupTable,'rows','stable');
groupTable = [groupTable,inputTable(iSort,:)];
groupTable.Combined = rowfun( ...
  @(x)join(x,'::'), ...
  inputTable(iSort,:), ...
  'SeparateInputs', false, ...
  'OutputFormat', 'uniform' ...
  );


vecLen = size(groupVec,1);
nGroups = height(groupTable);

Singular = zeros(vecLen,1);
posMap = containers.Map(1,false(size(groupVec)));
for row = 1:height(groupTable)
  % go down each row the table and find where groupVec matches
  tf = false(size(groupVec));
  mapCombs = zeros(1,size(groupVec,2));
  for c = 1:nIDs
    % loop through table columns and find locations of matches to this row
    thisRowColVal = groupTable.(idNames{c})(row);
    tf(:,c) = groupVec(:,c) == thisRowColVal;
    mapCombs(c) = thisRowColVal;
  end
  merged = splitapply(@all,tf,(1:vecLen)');
  Singular(merged) = row;
  posMap(row) = mapCombs;
end

% Get the counts from the singular vector and append to groupsInfo.Table
groupTable.Counts = zeros(nGroups,1);
groupTable.SingularMap = zeros(nGroups,1);
tblt = tabulate(Singular);
% tblt appears to arrive sorted, so we have to backwards map the counts to the
% original location in the table. If everything came in sorted alright, then
% this is a little bit overkill.
tabComps = groupTable{:,idNames};
for i = 1:size(tblt,1)
  matches = splitapply( ...
    @all, ...
    tabComps == posMap(tblt(i,1)), ...
    (1:size(tabComps,1))' ...
    );
  groupTable.Counts(matches) = tblt(i,2);
  groupTable.SingularMap(matches) = tblt(i,1);
end
%output
groupInfo = struct();
groupInfo.Table = groupTable;
groupInfo.Singular = Singular;
% Setup group vector for use with grpstats in the Statistics and machine
% learning toolbox. 
groupInfo.Vectors = mat2cell(groupVec, ...
  vecLen,...
  ones(1,size(groupVec,2)) ...
  );
% Reorganize table
groupInfo.Table = movevars( ...
  groupInfo.Table, ...
  {'SingularMap','Counts'}, ...
  'After', ...
  idNames{end} ...
  );
end