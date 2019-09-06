function onServiceDisplayUpdate(app,source,event)
% onServiceDisplayUpdate catch changes that affect currently drawn 
% This method could be used to intercept changes made to certain preferences before
% redrawing the data.
if ~app.handler.isready, return; end

% Prevent redraw if the service display update isnt needed
% Typically this will be to prevent a redraw when changing statistics parameters
% while the ui switch is not active
switch event.Data.id
  case 'Statistics'
    if ~app.ui.isAggregated || ~app.ui.isBaselined, return; end
  case 'Filter'
    if ~app.ui.isFiltered, return; end
  case 'Scaling'
    if ~app.ui.isScaled, return; end
  otherwise
    %Display settings should pass through
end

app.draw();
end