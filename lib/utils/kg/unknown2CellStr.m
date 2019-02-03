function strNow = unknown2CellStr(cellIn)
  cellAr = cellIn(~cellfun(@isempty,cellIn));
  caClass = cellfun(@class, cellAr, 'uniformoutput', false);
  testClass = unique(caClass);
  switch testClass{1}
    case 'char'
      strNow = unique(cellAr(:));
    case {'numeric','int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', ...
        'int64', 'uint64', 'double', 'single'}
      uAr = unique([cellAr{:}]);
      cellAr = num2cell(uAr)';
      strNow = cellfun(@(x)sprintf('%-.5g',x),cellAr, ...
        'uniformoutput', false);
    case 'logical'
      tmpvec = {'false','true'};
      strNow = cellfun(@(x)tmpvec(double(x)+1),cellAr, ...
        'uniformoutput', false);
  end    

end