function groupInfo = determineGroups(cellArray,inclusions,dropExcluded)
% DETERMINEGROUPS Create a grouping vector from cell array input.
%   DETERMINEGROUPS Expects the input table, or 2-D cell array, to contain only
%   strings (char arrays) in order to determine grouping vectors. 

if nargin < 3, dropExcluded = true; end %work just as prior to 2021 release
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
elseif iscell(cellArray)
  inputTable = cell2table( ...
    cellArray, ...
    'VariableNames', sprintfc('Input%d', 1:size(cellArray,2)) ...
    );
elseif ismatrix(cellArray)
  inputTable = array2table( ...
    cellArray, ...
    'VariableNames', sprintfc('Input%d', 1:size(cellArray,2)) ...
    );
  cellArray = table2cell(inputTable);
else
  error("IRISDATA:DETERMINEGROUPS:INPUTUNKNOWN","Incorrect input type.");
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
  if numel(classes) == 1
    % this is the simple case where the input was likely a table
    switch classes{1}
      case 'char'
        iterDat = cellArray(:,col);
      case 'string'
        iterDat = [cellArray{:,col}]';
      case { ...
          'double','single','int8','int16','int32','int64', ...
          'uint8','uint16','uint32','uint64' ...
          }
        iterDat = cat(1,cellArray{:,col});
      otherwise
        % TODO: expand to other classes!
        error('Cannot group on %s type.',classes{1});
    end

    % get the unique indices for this column
    [~,~,groupVec(:,col)] = unique(iterDat,'stable');
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

% Drop exclusions
if dropExcluded
  vecLen = sum(inclusions);
  groupVec(~inclusions,:) = [];
  inputTable(~inclusions,:) = [];
else
  vecLen = height(inputTable);
  groupVec(~inclusions) = 0;
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