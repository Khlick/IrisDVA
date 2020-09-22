function varargout = ValidStrings(testString,varargin)
% VALIDSTRINGS A modified version of matlab's validstring. VALIDSTRINGS accepts
% a cellstr and returns up to 2 outputs, a boolean indicated if all strings in
% testString passed validation (by best partial matching) in allowedStrings and
% a cellstr containing the validated strings.

allowedStrings = "";
nVargs = length(varargin);
for v = 1:nVargs
  thisInput = varargin{v};
  switch class(thisInput)
    case 'char'
      allowedStrings = union(allowedStrings,string(thisInput));
    case 'string'
      allowedStrings = union(allowedStrings,thisInput);
    case 'cell'
      cStr = cellfun(@string,thisInput,'UniformOutput',false);
      allowedStrings = union(allowedStrings,[cStr{:}]);
    otherwise
      error('VALIDSTRINGS:UNSUPPORTEDTYPE','Unsuported input type, "%s".',class(thisInput));
  end
end

% clear the empty
allowedStrings(allowedStrings=="") = [];

if ~isstring(testString), testString = string(testString); end

% check if we want to ignore case by searching for the flag
hasFlag = strcmpi("-any",allowedStrings);
anywhere = any(hasFlag);
allowedStrings(hasFlag) = [];

% loop and check each input string
tf = false(length(testString),1);
idx = nan(length(testString),1);
for i = 1:length(testString)
  if anywhere
    for a = 1:numel(allowedStrings)
      if regexpi(allowedStrings(a), testString(i), 'once')
        tf(i) = true;
        idx(i) = a;
        testString(i) = allowedStrings(a);
        break
      end
    end
  else
    try %#ok<TRYNC>
      % MATLAB validatestrings will find uppercase from lowercase but not vice versa
      testString(i) = validatestring(testString(i), allowedStrings);
      idx(i) = find(strcmpi(testString(i),allowedStrings),1,'first');
      tf(i) = true;
    end
  end
end
tf = all(tf);
varargout{1} = tf;
varargout{2} = cellstr(testString);
varargout{3} = idx;
end