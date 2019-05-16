function fileLoad(app,~,event)

opts = app.options;

% split camel case
[prefix,type] = regexp(event.Data, '^[a-zA-z]{1}[a-z]*(?=[A-Z]?)','match','split');
% type will be 1x2 cell array with type{end} having the split leftover
filterText = app.validFiles.getFilterText;

% order the filterText for the previously selected file type
fltReorder = contains(filterText(:,1), opts.PreviousExtension);
filterText = [filterText(fltReorder,:);filterText(~fltReorder,:)];

if strcmpi(type{end},'Session')
  filterText = filterText(ismember(filterText(:,1), '*.isf'),:);
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
  app.show();
  return; 
end

% update the working directory
app.options.UserDirectory = root;

% update the previous extension
selectedExt = filterText{fltIdx,1};
selectedExt = strsplit(selectedExt,';');
selectedExt = selectedExt{1};
app.options.PreviousExtension = selectedExt;

%
app.options.save();

% get the reader function name
label = regexprep(filterText{fltIdx,2}, '\s\(.*\)', '');
reader = app.validFiles.getReadFxnByLabel(label);

% send the files and reader to the data handler
app.handler.(lower(char(prefix)))(files,reader);

% bring the window to the front
app.ui.focus();

end