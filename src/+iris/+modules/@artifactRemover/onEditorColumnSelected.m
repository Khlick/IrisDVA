function onEditorColumnSelected(app,~,evt)
  if isempty(evt.Selection)
    idx = 0;
  else
    idx = evt.Selection(1,2);
  end
  app.setActiveCorrectionIndex(idx);
end

