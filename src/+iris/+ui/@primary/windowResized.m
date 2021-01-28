function windowResized(obj,source,event)
%WINDOWRESIZED Update the positions of everything.

% because updating elements is slow, let's build in a callback reentry catch
s = dbstack();
names = {s(:).name};
if sum(ismember(names,'iris.ui.primary.windowResized')) > 1
  disp('not resizing');
  return
end

% original position
initW = 1610;
initH = 931;
pos = utilities.centerFigPos(initW,initH);

%drawnow('limitrate');



end

