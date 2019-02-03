function [avgs,ofsts] = averagedEpochs(Data,groupBy,doBaseline)
%% averagedEpochs
%{
DEFAULTS
groupBy:='lightAmplitude'
doBaseline:=true
%}

%% Begin Analysis
[AvEp,ofsts] = Data.Aggregate( ...
  'Y', ...
  'groupby', groupBy, ...
  'baseline', doBaseline, ...
  'baselineRegion', 'start', ...
  'stats', {'mean'} ...
  );
avgs = struct( ...
  'x', struct( ...
    'units', Data.X.units, ...
    'data', Data.X.data ...
  ), ...
  'y', struct( ...
    'units', Data.Y.units, ...
    'data', AvEp ...
  ) ...
  );
% end of analysis
end