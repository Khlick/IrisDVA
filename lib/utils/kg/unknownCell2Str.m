function outputString = unknownCell2Str(cellAr,sep)
if nargin < 2, sep = ';'; end
caClass = cellfun(@class, cellAr, 'uniformoutput', false);

% loop through each cell and determine string representation
strRepresentation = cell(length(caClass),1);
for I = 1:length(caClass)
  switch caClass{I}
    case 'char'
      strNow = cellAr{I};%strjoin(cellAr{I}, ', ');
    case {'numeric','int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', ...
        'int64', 'uint64', 'double', 'single'}
      uAr = unique(cellAr{I},'stable');
      uAr = num2cell(uAr);
      strNow = strjoin( ...
        cellfun( ...
          @(x) sprintf('%-.5g',x), ...
          uAr, ...
          'uniformoutput', false ...
          ), ...
        ', ' ...
        );
    case 'logical'
      tmpvec = {'false','true'};
      strNow = strjoin(cellfun(@(x)tmpvec(x+1),cellAr{I}, ...
        'uniformoutput', false), ', ');
    case 'cell'
      strNow = unknownCell2Str(cellAr{I});
  end
  strRepresentation{I} = strNow;
end
outputString = strjoin(unique(strRepresentation,'stable'),[sep,' ']);
end