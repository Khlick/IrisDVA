function createReader(obj)
% Prompt User to make sure they want to create a new reader.
verifyPrompt = iris.ui.questionBox( ...
  'Prompt', 'Are you sure you want to create a new data reader?', ...
  'Title', 'Reader Creation', ...
  'Options', {'Yes', 'Cancel'}, ...
  'Default', 'Cancel' ...
  );
% wait for the object to close

if ~strcmpi(verifyPrompt.response, 'Yes'), return; end

% prompt for reader name
nameBox = iris.ui.promptBox( ...
  'Title', 'Reader Name', ...
  'Prompts', ...
    { ...
      'Enter a name for the reader (eg. "readSymphony"):'; ...
      'List extensions (eg. "h5, h4"):'; ...
      'Provide a short description for file types (eg. "Symphony Data File"):'; ...
      'Provide a one word name for reader type (eg. "symphony"):' ...
    }, ...
  'Labels', {'reader'; 'exts'; 'label'; 'name'}, ...
  'Camelize', [true false false true], ...
  'Defaults', {''; ''; ''; ''}, ...
  'Width', 510 ...
  );
% wait for the object to close
%waitfor(nameBox, 'isready');

if isempty(nameBox.response) 
  return; 
end

aprops = obj.options.AnalysisProps;

saveLocation = aprops.ExternalReadersDirectory;
% make sure the location is available
if ~iris.app.Info.checkDir(saveLocation)
  % notify user that they need to select a folder to store created Reader
  notifyPrompt = iris.ui.questionBox( ...
    'Prompt', 'In the following dialog, select a location for the new reader.', ...
    'Title', 'Reader Creation', ...
    'Options', {'Ok', 'Cancel'}, ...
    'Default', 'Ok' ...
    );
  
  if ~strcmpi(notifyPrompt.response, 'Yes'), return; end
  saveLocation = iris.app.Info.getFolder('Select Reader Location');
  if isempty(saveLocation), return; end
  obj.options.AnalysisProps = struct('ExternalReadersDirectory', saveLocation);
end

% Make sure the saveLocation is on the MATLAB path
pathCell = regexp(path,pathsep,'split');
if (ispc && ~any(strcmpi(saveLocation,pathCell))) || (~ispc && ~any(strcmp(saveLocation,pathCell)))
  % not on path
  oldPath = path;
  path(oldPath,saveLocation);
end

if any(strcmpi([nameBox.response.reader,'.m'],ls(saveLocation)))
  existsBox = iris.ui.questionBox( ...
    'Prompt', sprintf('"%s" exists, would you like to edit it?', nameBox.response.reader), ...
    'Title', 'Reader Already Exists', ...
    'Options', {'Yes', 'No'}, ...
    'Default', 'No' ...
    );
  if strcmpi(existsBox, 'Yes')
    edit([nameBox.response.reader,'.m']);
  end
  return;
end

%%% Parse the information for the validFiles class
R = nameBox.response;
R.exts = strsplit(regexprep(R.exts,'\s',''),',');
label = strsplit(lower(R.label),' ');
for L = 1:length(label)
  ll = label{L};
  ll(1) = upper(ll(1));
  label{L} = ll;
end
R.label = strjoin(label,' ');


%%% Create the Function and send it to the command window
fxStr = [ ...
  {sprintf('function DATA = %s(fileName)',R.reader)}; ...
  {sprintf('%%%s for %s', upper(R.reader), R.label)}; ...
  iris.app.Aes.strLib('readerReadme'); ...
  {'end'} ...
  ];

fileName = fullfile(saveLocation, [R.reader,'.m']);

fid = fopen(fileName,'w');
if fid < 0
  error('Unable to create connection to: "%s".', fileName);
end

fprintf(fid,'%s\n',fxStr{:});

fclose(fid);

% open in editor
edit(fileName);

% Now we have the reader file created. let the app know how to add it to
% the reader list (iris.pref.validFiles
notify(obj,'NewReaderCreated', iris.infra.eventData(R));
end

