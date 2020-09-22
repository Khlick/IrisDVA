function cellFields = recurseStruct(S,stringify,parentName,sep)
% RECURSESTRUCT Turn structs into N by 2 cells.
% Fields that are structs will be merged into a nx2 cells while appending parentName
if nargin < 4, sep = ' > '; end
if nargin < 3, parentName = ''; end
if nargin < 2, stringify = false; end
cellFields = cell(0,2);
for i = 1:length(S)
  s = S(i);
  fields = fieldnames(s);
  values = struct2cell(s);
  structInds = cellfun(@isstruct, values, 'UniformOutput',1);
  
  cellFields(end+(1:sum(~structInds)),:) = [fields(~structInds),values(~structInds)];
  
  if any(structInds)
    structLoc = find(structInds);
    flatSubs = cell(0,2);
    for j = 1:length(structLoc)
      % determine if struct is the terminal depth
      if ~utilities.determineDepth(values{structLoc(j)})
        % convert struct arrays to cell arrays in case of stringy
        conts = values{structLoc(j)};
        conts = mat2cell(conts(:),ones(size(conts(:))),1); %#ok
        contNames = cellfun(@fieldnames,conts,'unif',0);
        contNames = cat(1,contNames{:});

        structContents = cellfun(@struct2cell,conts,'unif',0);
        structContents = cat(1,structContents{:});
        out = [ ...
          strcat( ...
            fields{structLoc(j)}, ...
            {sep}, ...
            contNames ...
            ), ...
            structContents ...
            ];

      else
        out = utilities.recurseStruct(values{structLoc(j)});
        out(:,1) = strcat(fields{structLoc(j)},{sep},out(:,1));
      end
      flatSubs(end+(1:size(out,1)),:) = out;
    end
    cellFields(end+(1:size(flatSubs,1)),:) = flatSubs;
  end
end

if ~isempty(parentName)
  cellFields(:,1) = strcat(parentName,{sep},cellFields(:,1));
end

if stringify
  cellFields(:,2) = arrayfun(@utilities.unknownCell2Str,cellFields(:,2),'UniformOutput',false);
end

end