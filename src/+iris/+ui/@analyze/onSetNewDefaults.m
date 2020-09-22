function onSetNewDefaults(obj,~,~)

% get the full path of the current function
avails = iris.app.Info.getAvailableAnalyses().Full;
fxString = obj.selectAnalysis.String{obj.selectAnalysis.Value};
idx = ismember(avails(:,2), [fxString,'.m']);
aFile = fullfile(avails{idx,:});

% get the argument data
inputs = obj.Args.Input;
% use " for all char arrays
inputs(:,2) = regexprep(inputs(:,2),'''','"');
% new definitions
newDefs = strcat(inputs(:,1),':=',inputs(:,2));

% get the current contents of the analysis file
fid = fopen(aFile,'r');
if fid < 0
  iris.app.Info.throwError(sprintf("Cannot open file '%s'.",fxString));
end
allText = textscan(fid,'%s','delimiter','\n','whitespace','');
fclose(fid);

%unpack
allText = allText{1};

% find defaults in the file
defLocs = find( ...
    ~cellfun(@isempty, ...
      strfind(allText,':=','ForceCellOutput',true), ...
      'unif',1 ...
    ) ...
  );

% make sure we have only deflocs that pertain to the arguments
defText = cellfun(@(x)strsplit(x,':='),allText(defLocs),'UniformOutput',false);
defLocs(~cellfun(@(x)contains(x{1},inputs(:,1)),defText,'UniformOutput',true)) = [];

if isempty(defLocs)
  % going to append them on the end
  insertAfter = numel(allText);
  allText{end+1} = '';
else
  insertAfter = min(defLocs) - 1;
  %TODO: maybe prompt to alert user that the file will be permanently changed?
end

% remove the existing definitions so we can replace them
allText(defLocs) = [];

% determine if we removed defaults from a defaults block
defBlockRow = find( ...
  ~cellfun( ...
    @isempty, ...
    regexp(allText,'^DEFAULTS','once'), ...
    'UniformOutput',true ...
    ), ...
  1 ...
  );
if isempty(defBlockRow)
  newDefs = [ ...
    { ...
      '% --- SET YOUR DEFAULTS BELOW --- %';
      '%{';
      'DEFAULTS';
    }; ...
    newDefs; ...
    { ...
      '%}';...
      '%' ...
    } ...
    ];
else
  %TODO: check that insertAfter == defblockRow?
end

% insert the new definitions
newText = [ ...
  allText(1:insertAfter);
  newDefs;
  allText((insertAfter+1):end) ...
  ];

% open the file to replace all content
fid = fopen(aFile,'w');
for c = 1:numel(newText)
  fprintf(fid,'%s\r\n',newText{c});
end
fclose(fid);

% reload the object
obj.loadObj(fxString);
end