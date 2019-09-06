function values = findParamCell(params,expression,anchor,returnIndex)
%FINDPARAMCELL

fields = params(:,anchor);
vals = params(:,returnIndex);

if ~iscell(expression), expression = cellstr(expression); end
values = [fields(ismember(fields,expression)),vals(ismember(fields,expression))];
end

