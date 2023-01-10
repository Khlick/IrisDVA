function s = getUniqueStructs(S,fieldName)
  if nargin < 2, fieldName = ''; end

  N = numel(S);
  % seed output with first struct
  s = S(1);
  % pop
  S(1) = [];
  while ~isempty(S)
    % compare S to current struct
    matches = structCompare(s(end),S,fieldName);
    % compress matches
    matchStruct = S(matches);
    matchNames = fieldnames(matchStruct);
    matchVals = struct2cell([s(end),matchStruct]);
    matchUq = cell(size(matchNames));
    for m = 1:size(matchVals,1)
      if isstruct(matchVals{m,1,1})
        matchUq{m} = utilities.getUniqueStructs([matchVals{m,1,:}]);
      else
        matchUq{m} = utilities.unknownCell2Str(matchVals(m,1,:));
      end
    end
    % override stored value
    s(end) = cell2struct(matchUq,matchNames);
    % drop matches
    S(matches) = [];
    % pop
    if numel(S) > 0
      s(end+1) = S(1); %#ok<AGROW>
      S(1) = [];
    end
  end
end

%%% comparator
function tf = structCompare(A,B,f)
  nB = numel(B);
  tf = false(size(B));
  for b = 1:nB
    if isempty(f)
      tf(b) = isequal(A,B(b));
    else
      tf(b) = isequal(A.(f),B(b).(f));
    end
  end
end
