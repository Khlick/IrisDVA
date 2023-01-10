function createUI(app)
  % set the app size
  app.Position = IrisModule.getCenteredPosition(900,600);

  % Create MenuFile
  app.FileMenu= uimenu(app.container);
  app.FileMenu.Text = 'File';

  % Create MenuImport
  app.LoadMenu = uimenu(app.FileMenu);
  app.LoadMenu.Text = 'Load';

  % Create SaveMenu
  app.SaveMenu= uimenu(app.FileMenu);
  app.SaveMenu.Enable = false;
  app.SaveMenu.Accelerator = 's';
  app.SaveMenu.Text = "Save Changes";

  % Create RevertMenu
  app.RevertMenu= uimenu(app.FileMenu);
  app.RevertMenu.Enable = false;
  app.RevertMenu.Text = "Revert Changes";

  % Create MenuExport
  app.ExportMenu = uimenu(app.FileMenu);
  app.ExportMenu.Text = "Export";

  % Create CloseMenu
  app.CloseMenu = uimenu(app.FileMenu);
  app.CloseMenu.Separator = true;
  app.CloseMenu.Accelerator = 'q';
  app.CloseMenu.Text = "Exit";

  % Create MenuView
  app.ViewMenu = uimenu(app.container);
  app.ViewMenu.Text = 'View';

  % Create MenuDataProp
  app.DataPropMenu = uimenu(app.ViewMenu);
  app.DataPropMenu.Enable = false;
  app.DataPropMenu.Text = 'Data Properties';

  % Create InclusionsMenu
  app.InclusionsMenu = uimenu(app.ViewMenu);
  app.InclusionsMenu.Enable = false;
  app.InclusionsMenu.Text = 'Data Inclusions';

  % Create SettingsMenu
  app.SettingsMenu = uimenu(app.ViewMenu);
  app.SettingsMenu.Enable = true;
  app.SettingsMenu.Separator = 'on';
  app.SettingsMenu.Text = "Settings";

  % Create MainLayout
  app.MainLayout = uigridlayout(app.container);
  app.MainLayout.ColumnWidth = {'1x'};
  app.MainLayout.RowHeight = {'1x', 'fit', 'fit'};
  app.MainLayout.ColumnSpacing = 5;
  app.MainLayout.RowSpacing = 5;
  app.MainLayout.Padding = [10 10 10 5];
  app.MainLayout.BackgroundColor = [1 1 1];

  % Create DataLayout
  app.DataLayout = uigridlayout(app.MainLayout);
  app.DataLayout.ColumnWidth = {60, '1x'};
  app.DataLayout.RowHeight = {34, 28, '1x', 28};
  app.DataLayout.ColumnSpacing = 2;
  app.DataLayout.RowSpacing = 5;
  app.DataLayout.Padding = [0,0,0,0];
  app.DataLayout.Layout.Row = 2;
  app.DataLayout.Layout.Column = 1;
  app.DataLayout.BackgroundColor = [1,1,1];

  % Create ViewAxes
  app.ViewAxes = uiaxes(app.DataLayout);
  app.ViewAxes.XLabel.String = 'X';
  app.ViewAxes.YLabel.String = 'Y';
  app.ViewAxes.NextPlot = 'add';
  app.ViewAxes.Layout.Row = [2 4];
  app.ViewAxes.Layout.Column = 2;
  app.ViewAxes.XLimMode = 'auto';
  app.ViewAxes.YLimMode = 'auto';
  disableDefaultInteractivity(app.ViewAxes);
  app.ViewAxes.Interactions = [];
  app.ViewAxes.Tag = 'ViewAxes';

  % Create ToggleLayout
  app.ToggleLayout = uigridlayout(app.DataLayout);
  app.ToggleLayout.ColumnWidth = {28, '1x'};
  app.ToggleLayout.RowHeight = {29};
  app.ToggleLayout.ColumnSpacing = 0;
  app.ToggleLayout.RowSpacing = 0;
  app.ToggleLayout.Padding = [2,2,2,2];
  app.ToggleLayout.Layout.Row = 1;
  app.ToggleLayout.Layout.Column = 1:2;
  app.ToggleLayout.BackgroundColor = [0.2588 0.3843 0.4706];

  % Create ToggleDataButton
  app.ToggleDataButton = uibutton(app.ToggleLayout, 'state');
  app.ToggleDataButton.Text = char(9682);
  app.ToggleDataButton.FontSize = 16;
  app.ToggleDataButton.BackgroundColor = [0.749 0.902 1];
  app.ToggleDataButton.Layout.Row = 1;
  app.ToggleDataButton.Layout.Column = 1;
  app.ToggleDataButton.Value = true;

  % Create CurrentIndexLabel
  app.CurrentIndexLabel = uilabel(app.ToggleLayout);
  app.CurrentIndexLabel.HorizontalAlignment = 'center';
  app.CurrentIndexLabel.FontColor = [1 1 1];
  app.CurrentIndexLabel.Layout.Row = 1;
  app.CurrentIndexLabel.Layout.Column = 2;
  app.CurrentIndexLabel.Text = 'Showing X of N';

  % Create IncrementDataButton
  app.IncrementDataButton = uibutton(app.DataLayout, 'push');
  app.IncrementDataButton.Layout.Row = 2;
  app.IncrementDataButton.Layout.Column = 1;
  app.IncrementDataButton.Text = char(9650);
  app.IncrementDataButton.Tag = 'increment';

  % Create DatumIndexField
  app.DatumIndexField = uieditfield(app.DataLayout, 'numeric');
  app.DatumIndexField.Limits = [1 Inf];
  app.DatumIndexField.RoundFractionalValues = 'on';
  app.DatumIndexField.ValueDisplayFormat = '%.0f';
  app.DatumIndexField.HorizontalAlignment = 'center';
  app.DatumIndexField.FontName = 'Courier New';
  app.DatumIndexField.FontSize = 14;
  app.DatumIndexField.Layout.Row = 3;
  app.DatumIndexField.Layout.Column = 1;
  app.DatumIndexField.Value = 1;
  app.DatumIndexField.Tag = 'edit';

  % Create DecrementDataButton
  app.DecrementDataButton = uibutton(app.DataLayout, 'push');
  app.DecrementDataButton.Layout.Row = 4;
  app.DecrementDataButton.Layout.Column = 1;
  app.DecrementDataButton.Text = char(9660);
  app.DecrementDataButton.Tag = 'decrement';

  % Create EditorLayout
  app.EditorLayout = uigridlayout(app.MainLayout);
  app.EditorLayout.ColumnWidth = {'1x', '3x'};
  app.EditorLayout.RowHeight = {'1x', 32};
  app.EditorLayout.ColumnSpacing = 5;
  app.EditorLayout.RowSpacing = 7;
  app.EditorLayout.Padding = [0 0 0 0];
  app.EditorLayout.Layout.Row = 1;
  app.EditorLayout.Layout.Column = 1;
  app.EditorLayout.BackgroundColor = [1 1 1];

  % Create EditAxes
  app.EditAxes = uiaxes(app.EditorLayout);
  app.EditAxes.Layout.Row = [1,2];
  app.EditAxes.Layout.Column = 2;
  app.EditAxes.Tag = 'EditAxes';
  app.EditAxes.XLimMode = 'auto';
  app.EditAxes.YLimMode = 'auto';
  disableDefaultInteractivity(app.EditAxes);

  % Create EditControlLayout
  app.EditControlLayout = uigridlayout(app.EditorLayout);
  app.EditControlLayout.ColumnWidth = {30, 30, 30, '1x', 64};
  app.EditControlLayout.RowHeight = {'1x'};
  app.EditControlLayout.ColumnSpacing = 5;
  app.EditControlLayout.RowSpacing = 5;
  app.EditControlLayout.Padding = [2 2 2 2];
  app.EditControlLayout.Layout.Row = 2;
  app.EditControlLayout.Layout.Column = 1;
  app.EditControlLayout.BackgroundColor = [1,1,1];

  % Create ApplyButton
  app.ApplyButton = uibutton(app.EditControlLayout, 'push');
  app.ApplyButton.Layout.Row = 1;
  app.ApplyButton.Layout.Column = 5;
  app.ApplyButton.Text = 'Apply';

  % Create UndoButton
  app.UndoButton = uibutton(app.EditControlLayout, 'push');
  app.UndoButton.FontSize = 16;
  app.UndoButton.Layout.Row = 1;
  app.UndoButton.Layout.Column = 1;
  app.UndoButton.Text = char(8634);

  % Create AddButton
  app.AddButton = uibutton(app.EditControlLayout, 'push');
  app.AddButton.FontSize = 16;
  app.AddButton.Layout.Row = 1;
  app.AddButton.Layout.Column = 2;
  app.AddButton.Text = "+";

  % Create RemoveButton
  app.RemoveButton = uibutton(app.EditControlLayout, 'push');
  app.RemoveButton.FontSize = 16;
  app.RemoveButton.Layout.Row = 1;
  app.RemoveButton.Layout.Column = 3;
  app.RemoveButton.Text = "-";

  % Create EditorTable
  app.EditorTable = uitable(app.EditorLayout);
  app.EditorTable.ColumnName = {};
  app.EditorTable.RowName = {};
  app.EditorTable.Layout.Row = 1;
  app.EditorTable.Layout.Column = 1;
  app.EditorTable.Data = table();

  % Create ControlLayout
  app.ControlLayout = uigridlayout(app.MainLayout);
  app.ControlLayout.ColumnWidth = {90, 90, '2x', '2x', '3x'};
  app.ControlLayout.RowHeight = {'fit', 'fit', 'fit'};
  app.ControlLayout.ColumnSpacing = 5;
  app.ControlLayout.RowSpacing = 5;
  app.ControlLayout.Padding = [2 2 2 2];
  app.ControlLayout.Layout.Row = 3;
  app.ControlLayout.Layout.Column = 1;
  app.ControlLayout.BackgroundColor = [1 1 1];

  % Create DeviceDropDownLabel
  app.DeviceDropDownLabel = uilabel(app.ControlLayout);
  app.DeviceDropDownLabel.Layout.Row = 2;
  app.DeviceDropDownLabel.Layout.Column = 5;
  app.DeviceDropDownLabel.Text = 'Device:';

  % Create DeviceDropDown
  app.DeviceDropDown = uidropdown(app.ControlLayout);
  app.DeviceDropDown.Layout.Row = 3;
  app.DeviceDropDown.Layout.Column = 5;

  % Create yLabel
  app.yLabel = uilabel(app.ControlLayout);
  app.yLabel.Layout.Row = 3;
  app.yLabel.Layout.Column = 4;
  app.yLabel.Text = 'y:';

  % Create xLabel
  app.xLabel = uilabel(app.ControlLayout);
  app.xLabel.Layout.Row = 3;
  app.xLabel.Layout.Column = 3;
  app.xLabel.Text = 'x:';

  % Create EndSpinnerLabel
  app.EndSpinnerLabel = uilabel(app.ControlLayout);
  app.EndSpinnerLabel.Layout.Row = 2;
  app.EndSpinnerLabel.Layout.Column = 2;
  app.EndSpinnerLabel.Text = 'End:';

  % Create EndSpinner
  app.EndSpinner = uispinner(app.ControlLayout);
  app.EndSpinner.Layout.Row = 3;
  app.EndSpinner.Layout.Column = 2;
  app.EndSpinner.RoundFractionalValues = 'off';
  %app.EndSpinner.Step = 10^(-app.setting_Precision);
  app.EndSpinner.Tag = "CLOSE";

  % Create StartSpinnerLabel
  app.StartSpinnerLabel = uilabel(app.ControlLayout);
  app.StartSpinnerLabel.Layout.Row = 2;
  app.StartSpinnerLabel.Layout.Column = 1;
  app.StartSpinnerLabel.Text = 'Start:';

  % Create StartSpinner
  app.StartSpinner = uispinner(app.ControlLayout);
  app.StartSpinner.Layout.Row = 3;
  app.StartSpinner.Layout.Column = 1;
  app.StartSpinner.RoundFractionalValues = 'off';
  %app.StartSpinner.Step = 10^(-app.setting_Precision);
  app.StartSpinner.Tag = "OPEN";

end
