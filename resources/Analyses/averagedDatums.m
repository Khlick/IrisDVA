function [AggregatesData,AggregatesMatrix] = averagedDatums(Data,groupBy,baselineLength,baselineType,doFilter,lowpassCutoff,devices,showPlot)
%% averagedDatums
%{
DEFAULTS
groupBy:='all'
baselineLength:='preTime'
baselineType:='Start'
doFilter:=true
lowpassCutoff:=30
devices:='all'
showPlot:=true
%}

if ~isnumeric(baselineLength)
  specs = Data.Specs.Datums{1};
  props = Data.getPropertyNames;
  [tf,baselineLengthName] = utilities.ValidStrings(baselineLength,props);
  if ~tf
    error("baselineLength parameter not found or in wrong format.");
  end
  baselineLength = utilities.findParamCell(specs,[string(baselineLengthName),"sampleRate"],1,2,false,true,true);
  % assuming the value is in milliseconds
  baselineLength = baselineLength.(string(baselineLengthName)) * 1e-3 * baselineLength.sampleRate{1};
end

%% Begin Analysis
% aggregate data based on input groups
AggregatesData = Data.Aggregate( ...
    'groupby', groupBy, ...
    'numBaseline', baselineLength, ...
    'baselineRegion', baselineType, ...
    'statistic', 'mean' ...
  );

if doFilter
  AggregatesData = AggregatesData.Filter( ...
    'type','lowpass', ...
    'freq',lowpassCutoff ...
  );
end

AggregatesMatrix = AggregatesData.getDataMatrix('devices',devices);
% Collect the data matrix for the supplied device
if showPlot
  % plot the aggregates in a new window.
  plot(AggregatesData, 'legend', true, 'colorize',false);
end
% end of analysis
end