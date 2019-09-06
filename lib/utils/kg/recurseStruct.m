function cellFields = recurseStruct(S,stringify,parentName,sep)
% RECURSESTRUCT Turn structs into N by 2 cells.
% Fields that are structs will be merged into a nx2 cells while appending parentName
if nargin < 4, sep = '> '; end
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
      % determine if struct is the last line
      if ~determineDepth(values{structLoc(j)})
        % loop array and get 
        conts = values{structLoc(j)};
        conts = mat2cell(conts(:),ones(size(conts(:))),1); %#ok
        structStrings = arrayfun( ...
          @unknownCell2Str, ...
          conts, ...
          'UniformOutput', false ...
          );
        out = [ ...
          strcat( ...
            fields{structLoc(j)}, ...
            {sep}, ...
            sprintfc('- (%d)', (1:length(structStrings))') ...
            ), ...
            structStrings ...
            ];
          
      else
        out = recurseStruct(values{structLoc(j)});
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
  cellFields(:,2) = arrayfun(@unknownCell2Str,cellFields(:,2),'UniformOutput',false);
end

end