function newValue = cast(value,classList)
%CAST Cast a character value to a specified class
% Cast is different from the MATLAB base cast() function. This function expects
% to cast booleans from 'true'/'false' to true/false. Further, cast will accept
% nested classes from the classList using the following syntax: 'parent <
% child'.


classes = cellfun(@(l)strsplit(l,'<'),classList,'UniformOutput',false);
nClass = numel(classes);
nVal = numel(value);
if nVal ~= nClass
  error('Class list must contain the same number of elements as the value list.');
end

newValue = value;

for cl = 1:nClass
  this = strtrim(classes{cl});
  isNested = logical(numel(this)-1);
  thisClass = this{isNested + 1};
  switch thisClass
    case 'logical'
      arrayData = strtrim(strsplit(value{cl},';'));
      castedData = false(1,numel(arrayData));
      for a = 1:numel(arrayData)
        if strcmpi(arrayData{a},'true')
          castedData(a) = true;
        end
      end
      newValue{cl} = castedData;
    case 'struct'
      % For values, fields are separated by commmas, name~values separated by :'s
      % If the original struct was an array, we will have array indices
      % separated by ;'s.
      % casted values will be the next index down the line
      subClass = strsplit(this{isNested + 2},',');
      arrayData = strtrim(strsplit(value{cl},';'));
      castedData = cell(1,numel(arrayData));
      for a = 1:numel(arrayData)
        fieldData = strtrim(strsplit(arrayData{a},','));
        fieldData = cellfun(@(p)strsplit(p,':'),fieldData,'UniformOutput',false);
        fieldData = cat(1,fieldData{:});
        fieldData(:,2) = utilities.cast(fieldData(:,2),subClass(:));
        castedData{a} = cell2struct(fieldData(:,2),fieldData(:,1));
      end
      newValue{cl} = castedData;
      isNested = false;
    case 'char'
      % if there is an array, we expect that we have a cellstr row array
      arrayData = strtrim(strsplit(value{cl},';'));
      castedData = cell(1,numel(arrayData));
      for a = 1:numel(arrayData)
        castedData{a} = char(arrayData{a});
      end
      if numel(arrayData) > 1
        newValue{cl} = castedData;
      else
        newValue{cl} = castedData{1};
      end
      % override nested behavior to prevent sticking a cellstr in another cell.
      isNested = false;
    case {'numeric','int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', ...
        'int64', 'uint64', 'double', 'single'}
      newValue{cl} = cast(str2num(value{cl}),thisClass);%#ok
    otherwise
      disp(thisClass);      
  end
  
  if isNested
    nestClass = this{1};
    switch nestClass
      case 'cell'
        newValue{cl} = newValue(cl);
      otherwise
        disp(nestClass);
    end
  end
end

end

