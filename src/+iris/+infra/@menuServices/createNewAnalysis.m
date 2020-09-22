function createNewAnalysis(obj,~,evt)
params = evt.Data;

oo = strjoin(params.output.Name,', ');
ii = strjoin(params.input.Name(:,1), ', ');

inputsWithDefault = params.input( ...
  ~cellfun(@isempty,params.input.("Default Value"),'unif',1), : ...
  );

defs  = cell(size(inputsWithDefault,1),1);
for d = 1:size(inputsWithDefault,1)
  defs{d} = strjoin([inputsWithDefault{d,:}], ':=');
end

readmeText = iris.app.Aes.strLib('analysisReadme');

analysisText = [ ...
    {sprintf('function [%s] = %s(%s)',oo,params.name,ii)}; ...
    {sprintf('%%%s ENTER SHORT DESCRIPTION HERE',upper(params.name))}; ...
    readmeText{1}; ...
    defs(:); ...
    readmeText{2}; ...
    readmeText{3} ...
  ];

% create the file
filename = fullfile( ....
  iris.pref.analysis.getDefault().AnalysisDirectory, ...
  [params.name,'.m'] ...
  );

fid = fopen(filename,'w');
if fid < 0
  error('Unable to create connection to: "%s".', filename);
end

fprintf(fid,'%s\n',analysisText{:});

fclose(fid);

% open in editor
edit(filename);

% update the analyze menu
obj.updateAnalysesList(); 
end

