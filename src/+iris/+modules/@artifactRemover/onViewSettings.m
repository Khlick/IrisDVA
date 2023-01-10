function onViewSettings(app,~,~)
  % gather settings property names from metaclass
  m = metaclass(app);
  p = string({m.PropertyList.Name});
  p(~startsWith(p,"setting_")) = [];
  sKeys = regexprep(p,"setting_","");
  N = numel(sKeys);
  [sVals,sTypes] = deal(strings(N,1));
  for n = 1:N
    sVals(n) = string(app.(p(n)));
    sTypes(n) = string(class(app.(p(n))));
  end
  settingTable = table( ...
    sKeys(:), sVals(:), sTypes(:), ...
    VariableNames=["Key","Value","Type"] ...
    );
  sFig = app.createContainerFigure("Settings",460,32*(N+1)+40+5*N,false);
  layout = uigridlayout( ...
    sFig, ...
    [2,3], ...
    Padding=[5,10,5,10], ...
    RowSpacing = 5, ...
    BackgroundColor=[1,1,1], ...
    ColumnWidth={'1x',60,'1x'}, ...
    RowHeight={'1x',26} ...
    );
  tab = uitable(layout);
  tab.Layout.Row = 1;
  tab.Layout.Column = [1,3];

  tab.Data = settingTable;
  drawnow();
  tab.ColumnEditable = [false,true,false];

  btn = uibutton(layout);
  btn.Layout.Row = 2;
  btn.Layout.Column = 2;
  btn.Text = "Done";

  % turn figure on
  sFig.Visible = true;


  % store the settings data
  setappdata(sFig,"DATA",settingTable);
  setappdata(sFig,"table",tab);
  % hookup callbacks
  sFig.CloseRequestFcn = @app.onCloseSettings;
  btn.ButtonPushedFcn = @app.onCloseSettings;
  % set modal windowstyle and wait for window deletion
  sFig.WindowStyle = 'modal';
  uiwait(sFig);
end

