function tf = isRunning()
% ISRUNNING Determine if an instance of Iris is already running


tf =  ~isempty( ...
  findall(groot,'Tag', iris.app.Info.name) ...
  );

end