function outputString = unknownCell2Str(cellAr,sep)
% UNKNOWNCELL2STR Convert a cell's contents to a string (char array)
if nargin < 2, sep = ';'; end
caClass = cellfun(@class, cellAr, 'uniformoutput', false);
% loop through each cell and determine string representation
strRepresentation = cell(length(caClass),1);
for I = 1:length(caClass)
  % convert each element to a string
  switch caClass{I}
    case {'char','string'}
      strNow = char(cellAr{I});%strjoin(cellAr{I}, ', ');
    case {'numeric','int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', ...
        'int64', 'uint64', 'double', 'single'}
      uAr = num2cell(cellAr{I});
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
      logStrings = cell(1,length(cellAr{I}));
      for ind = 1:length(cellAr{I})
        logStrings{ind} = tmpvec{double(cellAr{I}(ind))+1};
      end
      strNow = strjoin(logStrings, ',');
    case 'cell'
      strNow = unknownCell2Str(cellAr{I},sep);
    case 'struct'
      if length(cellAr{I}) > 1
        error('Structs must be scalar.');
      else
        fields = fieldnames(cellAr{I});
        vals = struct2cell(cellAr{I});
        valStrings = arrayfun( ...
          @(e)unknownCell2Str(e,sep), ...
          vals, ...
          'UniformOutput', false ...
          );
        strNow = join(join([fields(:),valStrings(:)],':',2),', ');
      end
    otherwise
      error('"%s" Cannot be dealt with currently.', caClass{I});
  end
  strRepresentation{I} = char(strNow);
end
% join all the strings using the input sep.
outputString = strjoin(unique(strRepresentation,'stable'),[sep,' ']);
end