function [sortedData,counts] = hist2dots(H,varargin)
% HIST2DOTS Create vectors for plotting points uniformly distributed in a historgram.
%  Input, H, must be either a pointer to the handle object returned from matlab's
%  histogram() function or  H is the counts (as 'n' from histcounts()) and a
%  second argument is then required as the data (can be unsorted).
%  It should be of class: 'matlab.graphics.chart.primitive.Histogram'
%
% Example Usage:
%   > D = randn(1000,1);
%   > fig = figure;
%   > H = histogram(D,'DisplayStyle','stairs','FaceColor','none','linewidth',2);
%   > [x,y] = hist2dots(H);
%   > L = line(x,y,'marker','.','markersize',1,'linestyle','none');
%   > uistack(L,'bottom');
%
% A horizontal histogram is also possible.
%   > ... 
%   > H = ...
%     histogram(D, 'Displaystyle', 'stairs', 'FaceColor', 'none', 'linewidth', 2, ...
%     'Orientation', 'horizontal');
%   > [sortedData,counts] = hist2dots(H);
%   > L = line(counts, sortedData, 'linestyle', 'none', 'marker', '.');
%   > uistack(L,'bottom');

% parse
if isa(H,'matlab.graphics.chart.primitive.Histogram')
  sortedData = sort(H.Data); % values
  counts = H.Values; % counts
elseif isnumeric(H) && isvector(H)
  sortedData = sort(H);
  counts = varargin{1};
  varargin(1) = [];
else
  error("Inputs must be either Histogram object or Data,Counts (2 vars).");
end

% look for Yoffset value
ip = inputParser();
ip.addOptional('yOffset', -0.5, @(x) isscalar(x) && isnumeric(x));
ip.parse(varargin{:});

counts = arrayfun(@(v)randperm(v)',counts,'UniformOutput',false);
% allow offset to the Y data to keep points at the uppermost extreme from
% floating outside the box.
counts = cat(1,counts{:}) + ip.Results.yOffset;
end