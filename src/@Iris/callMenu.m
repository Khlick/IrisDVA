function callMenu(app,~,event)
s = app.services;
switch event.Data
  case {'About','Help','Analyze','NewAnalysis', 'Preferences'}
    s.build(event.Data);
  case 'FileInfo'
    s.build(event.Data,app.handler.Meta);
  case 'Notes'
    s.build(event.Data,app.handler.Notes);
  case 'Protocols'
    % send datum array to protocols where 
    d = app.handler.getCurrent;
    s.build(event.Data,d.getPropsAsCell);
  case 'DataOverview'
    s.build(event.Data, app.handler);
end
    
end