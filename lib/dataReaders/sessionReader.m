function session = sessionReader(fileName)
%SESSIONREADER Read Iris Session Files
%  
import utilities.uniqueContents
try
  s = matfile(fileName);
  fn = who(s);
  if numel(fn) == 1 && strcmpi(fn{1},'session')
    session = s.(fn{1});
  else
    session = struct();
    for fd = 1:numel(fn)
      session.(fn{fd}) = s.(fn{fd});
    end
  end
  
  if ~all(ismember({'Meta','Data','Notes'},fieldnames(session)))
    throw( ...
      MException( ...
        'SessionReader:ImportSession', ...
        'File does not contain correct fields' ...
        ) ...
      );
  end
catch e
  er = MException( ...
    'SessionReader:ImportSession', ...
    'Session reader failed with message: "%s".', e.message ...
    );
  throw(er);
end
% Merge contents and update to single file name
N = numel(session.Meta);
if N > 1
  newM = cell(0,2);
  newD = cell(1,N);
  newN = cell(1,N);
  for d = 1:N
    f = session.Files{d};
    met = session.Meta{d};
    newM = cat(1,newM,[fieldnames(met),struct2cell(met)]);
    data = session.Data{d};
    for ii = 1:numel(data)
      data(ii).id = sprintf('%s-%s',f,data(ii).id);
    end
    newD{d} = data;
    nt = session.Notes{d};
    nt(contains(nt(:,1),'File:'),:) = [];
    newN{d} = nt;
  end
  newM = utilities.collapseUnique(newM,1,false,true);
  newM(:,2) = arrayfun(@(v) utilities.uniqueContents(v),newM(:,2),'UniformOutput',false);
  stLoc = cellfun(@isstruct,newM(:,2),'unif',1);
  newM(~stLoc,:) = utilities.collapseUnique(newM(~stLoc,:),1,true,true);
  session.Meta = {cell2struct(newM(:,2),newM(:,1))};
  session.Data = {cat(1,newD{:})};
  session.Notes = {cat(1,newN{:})};  
end

session.Files = {char(fileName)};
end

