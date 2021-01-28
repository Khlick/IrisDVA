function values = findParamCell(params,expression,anchor,returnIndex,exact,asStruct,first)
%FINDPARAMCELL 
if nargin < 7, first = true; end
if nargin < 6, asStruct = false; end
if nargin < 5, exact = false; end
fields = params(:,anchor);
vals = params(:,returnIndex);

if ~iscell(expression), expression = cellstr(expression); end
if exact
  idx = ismember(fields,expression);
else
  nExp = length(expression);
  nFld = numel(fields);
  idx = false(nFld,nExp);
  for z = 1:nExp
    matched = regexpi(fields,expression{z},'once');
    if first
      bestMatch = min(cat(2,matched{:}));
    else
      bestMatch = cat(2,matched{:});
    end
    if isempty(bestMatch), continue; end
    idx(:,z) = cellfun( ...
      @(i) ~isempty(i) && any(i == bestMatch), ...
      matched, ...
      'UniformOutput', true ...
      );
  end
  idx = any(idx,2);
end

if ~asStruct
  values = [fields(idx),vals(idx)];
else
  values = cell2struct(vals(idx),fields(idx));
end

end