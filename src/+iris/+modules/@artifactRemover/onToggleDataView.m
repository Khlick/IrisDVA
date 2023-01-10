function onToggleDataView(app,src,evt)
  if evt.Value
    src.Text = char(9682);
    app.DataLayout.RowHeight = {34,28,'1x',28};
    app.ControlLayout.RowHeight = {'fit','fit','fit'};
  else
    src.Text = char(9681);
    app.DataLayout.RowHeight = {34,0,0,0};
    app.ControlLayout.RowHeight = {'fit','fit','fit'};
  end
end
