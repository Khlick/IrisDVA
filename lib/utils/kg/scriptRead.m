function varargout = scriptRead(scriptFiles,prepForSprintf,killCntrl,quotes)
%% scriptRead  Prepares script files for use in MATLAB uifigure tweaks
%   Usage:
%     Strings = scriptRead('filename.css', false, false,'"');
%   Arguments:
%     scriptFiles: str|cellstr, file names of script files or 'select'
%     prepForSprintf: bool[true], will replace special characters so that
%      sprintf can be used aferward. e.g. line ends will be converted to
%      '\\n' in the output text.
%     killCntrl: bool[true], Replace control chars with empty str
%     quotes: char[''''|'"'|''], Supply a quote character to standardize
%     the loaded scripts quoting character.
%   Output:
%     1st arg: cell array of stringified scripts
%     2nd arg: [optional] cell array of error messages
%
%   Note: 
%     scriptRead can be called without inputs and user will be prompted to
%       select the desired script files.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Khris Griffis 2018

%%
if nargin < 4, quotes = ''; end
if nargin < 3, killCntrl = true; end
if nargin < 2, prepForSprintf = true; end
if nargin < 1
  scriptFiles = 'select';
end
% Validate files list
if ~iscell(scriptFiles)
  % allow call to empty args
  if strcmpi(scriptFiles, 'select')
    [scriptFiles,root] = uigetfile(...
      fullfile(pwd,'*.*'), ...
      'Select Script Files', ...
      'MultiSelect', 'on');
    if ~iscell(scriptFiles) && ~scriptFiles
      error('No files selected.')
    end
    scriptFiles = fullfile(root,scriptFiles);
  else
    % if a single file was supplied, make it callstr
    scriptFiles = {scriptFiles}; 
  end
end
%validate quote character
quotes = validatestring(quotes, {'''', '"', ''});
% initialize text holders
nFiles = length(scriptFiles);
erMsg = cell(nFiles,1);
stringified = cell(nFiles,1);

for fi = 1:nFiles
  fn = scriptFiles{fi};
  fid = fopen(fn, 'r');
  if fid < 0
    erMsg{fi} = sprintf('Unable to create connection to: "%s".', fn);
    fprintf(2, '%s\n', erMsg{fi});
    continue
  end
  stringified{fi} = fread(fid, [1, inf], '*char');
  fclose(fid);
  % insert '9~' for all control characters
  stringified{fi} = regexprep(stringified{fi}, ['[',char(0:20),']'], '9~');
  if prepForSprintf
    % Find backslash and percent sign, special characters and prepare them
    % for sprintf() use by doubling them up. i.e. \ -> \\ or % -> %%
    stringified{fi} = regexprep(stringified{fi}, '(\\|\%)', '$0$0');
    % Find former control chars, now '9~', and replace groups of them by a
    % newline character, sprintf() ready style. e.g. '9~9~' -> '\\n'
    stringified{fi} = regexprep(stringified{fi}, '(9~)+', '\\n');
  elseif killCntrl
    % In this case, we do not want any \n or control chars, thus everything
    % will become a single line char array. I.e. remove all groups of '9~'
    stringified{fi} = regexprep(stringified{fi}, '(9~)+', '');
  else
    % Use both flags as false if you want to have the string contain
    % newline characters in place of control but will not be preparing it
    % for sprintf() use. This use case would be if your script will go in
    % as-is. This might be best for CSS injection into the DOM <head>
    stringified{fi} = regexprep(stringified{fi}, '(9~)+', '\\n');
  end
  % modify all the quote symbols to be those specified in quotes arg
  if strcmp(quotes, '''')
    %convert to single quote
    stringified{fi} = regexprep(stringified{fi}, '"', quotes);
  elseif strcmp(quotes,'"')
    %convert to double quote
    stringified{fi} = regexprep(stringified{fi}, '''', quotes);
  end
end

% assign outputs

varargout{1} = stringified(~cellfun(@isempty, stringified, 'unif',1));
if nargout > 1
  varargout{2} = erMsg;
end