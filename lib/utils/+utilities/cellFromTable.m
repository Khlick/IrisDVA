function cl = cellFromTable(cellInfo,tabInfo)
  props = tabInfo.Properties.VariableNames';
  vals = table2cell(tabInfo);
  cl = cell(length(props), 2);
  cl(:,1) = props;
  for v = 1:size(vals,2)
    cl{v,2} = strjoin(utilities.unknown2CellStr(vals(:,v)), ', ');
  end
end