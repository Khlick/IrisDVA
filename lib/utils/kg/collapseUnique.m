function tableDat = collapseUnique(d,columnAnchor,stringify)
% COLLAPSEUNIQUE Collapse repeated cell entries as determined by columnAnchor.
if nargin < 3, stringify = false; end
keyNames = unique(d(:,columnAnchor),'stable');
others = ~ismember(1:size(d,2), columnAnchor);
% collect repeated values in cell arrays
keyData = cellfun( ...
  @(x)d(ismember(d(:,columnAnchor),x),others), ...
  keyNames, ...
  'UniformOutput', false ...
  );
tableDat = [ ...
  keyNames(:), ...
  keyData(:) ...
  ];
% set all values column to strings
if stringify
  tableDat(:,2) = arrayfun(@unknownCell2Str,tableDat(:,2),'unif',0);
end
end

