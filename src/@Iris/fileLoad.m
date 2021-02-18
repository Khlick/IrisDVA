function fileLoad(app,~,event)

opts = app.options;

% split camel case from senders message
[prefix,~] = regexp(event.Data, '^[a-zA-z]{1}[a-z]*(?=[A-Z]?)','match','split','once');
[~,type] = regexp( ...
  event.EventName, ...
  '^[a-zA-z]{1}[a-z]*(?=[A-Z]?)', ...
  'match', ...
  'split', ...
  'once' ....
  );
type = type{end};
% type will be 1x2 cell array with type{end} having the split leftover
filterText = app.validFiles.getFilterText;
allSupport = filterText(end,:);
filterText(end,:) = [];
sesExt = strcat('*.',app.validFiles.getIDFromLabel('session').exts);


% order the filterText for the previously selected file type
fltReorder = cellfun( ...
  @(ex) ...
    all(ismember(ex, opts.PreviousExtension)), ...
  filterText(:,1), ...
  'UniformOutput', true ...
  );
filterText = [filterText(fltReorder,:);filterText(~fltReorder,:)];

%
switch type
  case 'Session'
    % if loading a session, filter out non-session options
    filterText = filterText(ismember(filterText(:,1), sesExt),:);
  case 'Data'
    % otherwise use previous unless previous was a session file, then reorder to
    % first non-session file
    if ~ispc
      filterText = allSupport;
    else
      while ismember(filterText(1,1),sesExt)
        filterText = circshift(filterText,-1);
      end
      % append all supported back
      filterText(end+1,:) = allSupport;
    end
end

if iris.app.Info.checkDir(opts.UserDirectory)
  openDir = opts.UserDirectory;
else
  openDir = iris.app.Info.getUserPath();
end

% prompt for files
[files,fltIdx,root] = iris.app.Info.getFile( ...
  'Load Data Files', ...
  filterText, ...
  openDir, ...
  'MultiSelect', 'on' ...
  );

% check if files were selected
if isempty(fltIdx)
  app.ui.focus();
  return; 
end

% update the working directory
app.options.UserDirectory = root;

% update the previous extension
selectedExt = filterText{fltIdx,1};
selectedExt = strsplit(selectedExt,';');
app.options.PreviousExtension = selectedExt;

%
app.options.save();
app.ui.toggleSwitches('off');



% get the reader function name
label = filterText{fltIdx,2};
if startsWith(label,'All')
  reader = app.validFiles.getReadFxnFromFile(files);
else
  reader = app.validFiles.getReadFxnByLabel(label);
end

% kill dataOverview if it is open
app.services.shutdown( ...
  { ...
    'Analyze', 'NewAnalysis', 'FileInfo', 'DataOverview', 'Notes', 'Protocols' ...
  } ...
  );

pause(0.05);

% send the files and reader to the data handler
app.handler.(lower(prefix))(files,reader);

% bring the window to the front
app.ui.focus();

end