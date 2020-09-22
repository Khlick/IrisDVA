function s = camelizer(inputString,reverseFlag)
if nargin < 2, reverseFlag = false; end
% check if the first char is a number and not an "i" or "j"
if ~isnan(str2double(inputString(1))) && ~strcmp(inputString(1),'i') && ~strcmp(inputString(1),'j')
  inputString = ['A ',inputString];
end
% collect the class
inputClass = class(inputString);

% split the string on spaces and/or camel.
splits = strsplit(char(inputString), ' ');

[splits,camels]=regexp(splits,'(?<=[a-z]+)[A-Z]\w*', 'split', 'match');
% splits has blanks where the camels are, remerge them
for I = 1:length(splits)
  splits{I} = cat(1,splits{I}(:),camels{I}(:));
  splits{I}(cellfun(@isempty,splits{I},'unif',1)) = [];
end
splits = cat(1,splits{:});
if length(splits) > 1
  for idx = 2:length(splits)
    word = lower(splits{idx});
    word(1) = upper(word(1));
    splits{idx} = word;
  end
end

if reverseFlag
  splits{1}(1) = upper(splits{1}(1));
  joiner = ' ';
else
  joiner = '';
end

s = strjoin(splits,joiner);

if strcmp(inputClass,'string')
  s = string(s);
end

end

