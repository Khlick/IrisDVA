function onLoadData(app,~,~)
  filePath = IrisModule.getFile( ...
    "Load IrisData", ...
    {'*.idata;*.mat','IrisData Object'}, ...
    app.lastLoadDirectory ...% last directly loaded from in Iris
    );
  filePath = string(filePath);
  if isempty(filePath), return; end
  try
    s = load(filePath,'-mat');
    dcell = struct2cell(s);
    test = cellfun(@(c)isa(c,'IrisData'),dcell,'unif',1);
    data = dcell{find(test,1)};
  catch ME
    msg = strings(numel(ME.stack),1);
    for s = 1:numel(ME.stack)
      [~,fn,~] = fileparts(ME.stack(s).file);
      msg(s) = sprintf("%s(line:%d|%s)",ME.stack(s).name,ME.stack(s).line,fn);
    end
    msg = strjoin(msg," < ");
    IrisModule.showWarning(sprintf("[%s]%s.\\n%s",ME.identifier,ME.message,msg));
    return
  end
  % store last loaded directory
  
  [loadDir,~,~] = fileparts(filePath);
  app.lastLoadDirectory = string(loadDir);

  % set the new data
  app.setData(data);
end

