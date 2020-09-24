function session = sessionReader(fileName)
%SESSIONREADER Read Iris Session Files
%   
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

end

