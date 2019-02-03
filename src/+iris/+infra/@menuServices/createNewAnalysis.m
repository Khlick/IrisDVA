function createNewAnalysis(obj,~,evt)
disp(evt)

params = evt.Data;

oo = strjoin(params.output,', ');
ii = strjoin(params.input(:,1), ', ');

inputsWithDefault = params.input( ...
  ~cellfun(@isempty,params.input(:,2),'unif',1), : ...
  );

defs  = cell(size(inputsWithDefault,1),1);
for d = 1:size(inputsWithDefault,1)
  defs{d} = strjoin(inputsWithDefault(d,:), ':=');
end

readmeText = iris.app.Aes.strLib('analysisReadme');

analysisText = [ ...
    {sprintf('function [%s] = %s(%s)',oo,params.name,ii)}; ...
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

addpath(fileparts(filename));

edit(filename);
end

