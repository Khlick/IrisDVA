function strNow = unknownCell2Str(cellAr)

caClass = cellfun(@class, cellAr, 'uniformoutput', false);
testClass = unique(caClass);

if length(testClass) > 1
  warning('EXTRACTSYMPHONYV1:PLOTEPOCH:TABLECAST',...
    'Table data may not be accurate.');
  strNow = strjoin(cellfun(@char, cellAr,'uniformoutput', false),'; ');
  return
end

switch testClass{1}
  case 'char'
    strNow = strjoin(cellAr, '; ');
  case {'numeric','int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', ...
      'int64', 'uint64', 'double', 'single'}
    uAr = unique([cellAr{:}]);
    cellAr = num2cell(uAr);
    strNow = strjoin(cellfun(@(x)sprintf('%-.5g',x),cellAr, ...
      'uniformoutput', false), '; ');
  case 'logical'
    tmpvec = {'false','true'};
    strNow = strjoin(cellfun(@(x)tmpvec(x+1),cellAr, ...
      'uniformoutput', false), '; ');
  case 'cell'
    strNow = unknownCell2Str([cellAr{:}]);
end    

end