function callMenu(app, ~, event)
  s = app.services;
  switch lower(event.Data)
    case {'about', 'help', 'newanalysis', 'preferences'}
      s.build(event.Data);
    case 'fileinfo'
      s.build(event.Data, app.handler.Meta);
    case 'notes'
      s.build(event.Data, app.handler.Notes);
    case 'protocols'
      % send datum array to protocols where
      d = app.handler.getCurrentData;
      s.build(event.Data, d.getPropsAsCell);
    case {'dataoverview', 'analysis'}
      s.build(event.Data, handle(app.handler));
  end

end
