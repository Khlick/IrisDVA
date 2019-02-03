function s = camelizer(inputString)
  if ~isnan(str2double(inputString(1))) && ~strcmpi(inputString(1),'i')
    inputString = ['A ',inputString];
  end
  splits = strsplit(inputString, ' ');
  if length(splits) > 1
    for idx = 2:length(splits)
      word = lower(splits{idx});
      word(1) = upper(word(1));
      splits{idx} = word;
    end
  end
  s = strjoin(splits,'');
end

