function createUI(obj)
%createUI Creates the primary window view
%% Initialize
import iris.ui.*;
import iris.app.*;
import iris.infra.*;

obj.layout = iris.data.encode.layout('X','Y');

%% Menus

% Create FileMenu
obj.FileMenu = uimenu(obj.container);
obj.FileMenu.Text = 'File';

% Create NewMenu
obj.NewMenu = uimenu(obj.FileMenu);
obj.NewMenu.Text = 'Load';

% Create NewMenu
obj.DataMenu = uimenu(obj.NewMenu);
obj.DataMenu.Tag = 'newFile';
obj.DataMenu.Text = 'Data...';

% Create SessionMenu
obj.SessionMenu = uimenu(obj.NewMenu);
obj.SessionMenu.Tag = 'newSession';
obj.SessionMenu.Text = 'Session...';

% Create ImportMenuD
obj.ImportMenuD = uimenu(obj.FileMenu);
obj.ImportMenuD.Text = 'Import';

% Create FromDataMenuD
obj.FromDataMenuD = uimenu(obj.ImportMenuD);
obj.FromDataMenuD.Tag = 'importData';
obj.FromDataMenuD.Text = 'From Data...';

% Create FromSessionMenuD
obj.FromSessionMenuD = uimenu(obj.ImportMenuD);
obj.FromSessionMenuD.Tag = 'importSession';
obj.FromSessionMenuD.Text = 'From Session...';

% Create SaveMenu
obj.SaveMenuD = uimenu(obj.FileMenu);
obj.SaveMenuD.Enable = 'off';
obj.SaveMenuD.Text = 'Save';

% Create QuitMenu
obj.QuitMenu = uimenu(obj.FileMenu);
obj.QuitMenu.Separator = 'on';
obj.QuitMenu.Text = 'Quit';

% Create ViewMenu
obj.ViewMenu = uimenu(obj.container);
obj.ViewMenu.Text = 'View';

% Create FileInfoMenuD
obj.FileInfoMenuD = uimenu(obj.ViewMenu);
obj.FileInfoMenuD.Enable = 'off';
obj.FileInfoMenuD.Text = 'File Info...';

% Create NotesMenuD
obj.NotesMenuD = uimenu(obj.ViewMenu);
obj.NotesMenuD.Enable = 'off';
obj.NotesMenuD.Text = 'Notes...';

% Create ProtocolsMenuD
obj.ProtocolsMenuD = uimenu(obj.ViewMenu);
obj.ProtocolsMenuD.Enable = 'off';
obj.ProtocolsMenuD.Text = 'Datum Properties...';

% Create OverviewMenuD
obj.OverviewMenuD = uimenu(obj.ViewMenu);
obj.OverviewMenuD.Enable = 'off';
obj.OverviewMenuD.Text = 'Data Overview...';

% Create PreferencesMenu
obj.PreferencesMenu = uimenu(obj.ViewMenu);
obj.PreferencesMenu.Separator = 'on';
obj.PreferencesMenu.Text = 'Preferences...';

% Create AnalysisMenu
obj.AnalysisMenu = uimenu(obj.container);
obj.AnalysisMenu.Text = 'Analysis';

% Create AnalyzeMenuD
obj.AnalyzeMenuD = uimenu(obj.AnalysisMenu);
obj.AnalyzeMenuD.Enable = 'off';
obj.AnalyzeMenuD.Text = 'Analyze...';

% Create ImportAnalysisMenu
obj.ImportAnalysisMenu = uimenu(obj.AnalysisMenu);
obj.ImportAnalysisMenu.Text = 'Import Analysis...';

% Create CreateNewMenu
obj.CreateNewMenu = uimenu(obj.AnalysisMenu);
obj.CreateNewMenu.Text = 'Create New...';

% Create ExportFigureMenuD
obj.ExportFigureMenuD = uimenu(obj.AnalysisMenu);
obj.ExportFigureMenuD.Enable = 'off';
obj.ExportFigureMenuD.Separator = 'on';
obj.ExportFigureMenuD.Text = 'Export...';

% Create SendtoCmdMenuD
obj.SendtoCmdMenuD = uimenu(obj.AnalysisMenu);
obj.SendtoCmdMenuD.Enable = 'off';
obj.SendtoCmdMenuD.Text = 'Send to Cmd';

% Create ModulesMenu
obj.ModulesMenu = uimenu(obj.container);
obj.ModulesMenu.Text = 'Modules';

% Create SessionConverterMenu
obj.SessionConverterMenu = uimenu(obj.ModulesMenu);
obj.SessionConverterMenu.Text = 'Session Converter';

% Create ModulesRefresh
obj.ModulesRefresh = uimenu(obj.ModulesMenu);
obj.ModulesRefresh.Text = 'Refresh';
obj.ModulesRefresh.Separator = 'on';
obj.ModulesRefresh.Enable = 'on';

% Create HelpMenu
obj.HelpMenu = uimenu(obj.container);
obj.HelpMenu.Text = 'Help';

% Create AboutMenu
obj.AboutMenu = uimenu(obj.HelpMenu);
obj.AboutMenu.Text = 'About Iris';

% Create DocumentationMenu
obj.DocumentationMenu = uimenu(obj.HelpMenu);
obj.DocumentationMenu.Text = 'Documentation';

% Create Install Helpers
obj.InstallHelpersMenu = uimenu(obj.HelpMenu);
obj.InstallHelpersMenu.Text = 'Install Helpers';

% Create FixLayoutMenu
obj.FixLayoutMenu = uimenu(obj.HelpMenu);
obj.FixLayoutMenu.Text = 'Fix Layout!';


%% MAIN UI

% set the position
initW = obj.WIDTH;
initH = obj.HEIGHT;

pos = utilities.centerFigPos(initW,initH);

set(obj.container, ...
  'Name', [Info.name,' ',Info.year], ...
  'Alphamap', linspace(0,1,2^8), ...
  'Position', pos, ...
  'Tag', iris.app.Info.name ...
  );

% Create containerGrid
obj.containerGrid = uigridlayout(obj.container);
obj.containerGrid.ColumnWidth = {'1x', 350};
obj.containerGrid.RowHeight = {190, '1x'};
obj.containerGrid.ColumnSpacing = 5;
obj.containerGrid.RowSpacing = 5;
obj.containerGrid.BackgroundColor = [1,1,1,0];

% Create PlotControlTools
obj.PlotControlTools = uipanel(obj.containerGrid);
obj.PlotControlTools.BackgroundColor = [1 1 1];
obj.PlotControlTools.FontWeight = 'bold';
obj.PlotControlTools.FontName = Aes.uiFontName;
obj.PlotControlTools.Layout.Row = 1;
obj.PlotControlTools.Layout.Column = 1;


% Create PlotControlGrid
obj.PlotControlGrid = uigridlayout(obj.PlotControlTools);
obj.PlotControlGrid.ColumnWidth = {'1.3x', '1.5x', '0.8x', '1x'};
obj.PlotControlGrid.RowHeight = {'2x', 60, '1x'};
obj.PlotControlGrid.Padding = [5 5 5 10];
obj.PlotControlGrid.ColumnSpacing = 25;
obj.PlotControlGrid.RowSpacing = 5;

%%% Create the switch panel

% Create SwitchPanel
obj.SwitchPanel = uipanel(obj.PlotControlGrid);
obj.SwitchPanel.BorderType = 'none';
obj.SwitchPanel.BackgroundColor = [0.502 0.502 0.502];
obj.SwitchPanel.FontName = Aes.uiFontName;
obj.SwitchPanel.Layout.Row = [1 3];
obj.SwitchPanel.Layout.Column = 1;


% Create SwitchGrid
obj.SwitchGrid = uigridlayout(obj.SwitchPanel);
obj.SwitchGrid.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};
obj.SwitchGrid.RowHeight = {16, '1x', 22};
obj.SwitchGrid.Padding = [2 8 2 8];
obj.SwitchGrid.ColumnSpacing = 5;
obj.SwitchGrid.RowSpacing = 2;

% Create StatsLabel
obj.StatsLabel = uilabel(obj.SwitchGrid);
obj.StatsLabel.HorizontalAlignment = 'center';
obj.StatsLabel.FontColor = [0.9412 0.9412 0.9412];
obj.StatsLabel.FontName = Aes.uiFontName;
obj.StatsLabel.FontSize = Aes.uiFontSize('custom',2);
obj.StatsLabel.Text = 'Stats';
obj.StatsLabel.Layout.Row = 3;
obj.StatsLabel.Layout.Column = 1;

% Create StatsLamp
obj.StatsLamp = uilamp(obj.SwitchGrid);
obj.StatsLamp.Layout.Row = 1;
obj.StatsLamp.Layout.Column = 1;
obj.StatsLamp.Color = Aes.appColor(1,'red');

% Create StatsSwitch
obj.StatsSwitch = uiswitch(obj.SwitchGrid, 'toggle');
obj.StatsSwitch.Items = {'', ''};
obj.StatsSwitch.ItemsData = {'0', '1'};
obj.StatsSwitch.FontName = Aes.uiFontName;
obj.StatsSwitch.Interruptible = 'off';
obj.StatsSwitch.Value = '0';
obj.StatsSwitch.Tag = 'Stats';
obj.StatsSwitch.Layout.Row = 2;
obj.StatsSwitch.Layout.Column = 1;

% Create ScaleLabel
obj.ScaleLabel = uilabel(obj.SwitchGrid);
obj.ScaleLabel.HorizontalAlignment = 'center';
obj.ScaleLabel.FontColor = [0.9412 0.9412 0.9412];
obj.ScaleLabel.Text = 'Scale';
obj.ScaleLabel.FontName = Aes.uiFontName;
obj.ScaleLabel.FontSize = Aes.uiFontSize('custom',2);
obj.ScaleLabel.Layout.Row = 3;
obj.ScaleLabel.Layout.Column = 2;

% Create ScaleLamp
obj.ScaleLamp = uilamp(obj.SwitchGrid);
obj.ScaleLamp.Layout.Row = 1;
obj.ScaleLamp.Layout.Column = 2;
obj.ScaleLamp.Color = Aes.appColor(1,'red');

% Create ScaleSwitch
obj.ScaleSwitch = uiswitch(obj.SwitchGrid, 'toggle');
obj.ScaleSwitch.Items = {'', ''};
obj.ScaleSwitch.ItemsData = {'0', '1'};
obj.ScaleSwitch.FontName = Aes.uiFontName;
obj.ScaleSwitch.Interruptible = 'off';
obj.ScaleSwitch.Value = '0';
obj.ScaleSwitch.Tag = 'Scale';
obj.ScaleSwitch.Layout.Row = 2;
obj.ScaleSwitch.Layout.Column = 2;

% Create BaselineLabel
obj.BaselineLabel = uilabel(obj.SwitchGrid);
obj.BaselineLabel.HorizontalAlignment = 'center';
obj.BaselineLabel.FontColor = [0.9412 0.9412 0.9412];
obj.BaselineLabel.FontName = Aes.uiFontName;
obj.BaselineLabel.FontSize = Aes.uiFontSize('custom',2);
obj.BaselineLabel.Text = 'Baseline';
obj.BaselineLabel.Layout.Row = 3;
obj.BaselineLabel.Layout.Column = 3;

% Create BaselineLamp
obj.BaselineLamp = uilamp(obj.SwitchGrid);
obj.BaselineLamp.Layout.Row = 1;
obj.BaselineLamp.Layout.Column = 3;
obj.BaselineLamp.Color = Aes.appColor(1,'red');

% Create BaselineSwitch
obj.BaselineSwitch = uiswitch(obj.SwitchGrid, 'toggle');
obj.BaselineSwitch.Items = {'', ''};
obj.BaselineSwitch.ItemsData = {'0', '1'};
obj.BaselineSwitch.FontName = Aes.uiFontName;
obj.BaselineSwitch.Value = '0';
obj.BaselineSwitch.Interruptible = 'off';
obj.BaselineSwitch.Tag = 'Baseline';
obj.BaselineSwitch.Layout.Row = 2;
obj.BaselineSwitch.Layout.Column = 3;


% Create FilterLabel
obj.FilterLabel = uilabel(obj.SwitchGrid);
obj.FilterLabel.HorizontalAlignment = 'center';
obj.FilterLabel.FontColor = [0.9412 0.9412 0.9412];
obj.FilterLabel.FontName = Aes.uiFontName;
obj.FilterLabel.FontSize = Aes.uiFontSize('custom',2);
obj.FilterLabel.Text = 'Filter';
obj.FilterLabel.Layout.Row = 3;
obj.FilterLabel.Layout.Column = 4;

% Create FilterLamp
obj.FilterLamp = uilamp(obj.SwitchGrid);
obj.FilterLamp.Layout.Row = 1;
obj.FilterLamp.Layout.Column = 4;
obj.FilterLamp.Color = Aes.appColor(1,'red');

% Create FilterSwitch
obj.FilterSwitch = uiswitch(obj.SwitchGrid, 'toggle');
obj.FilterSwitch.Interruptible = 'off';
obj.FilterSwitch.Items = {'', ''};
obj.FilterSwitch.ItemsData = {'0', '1'};
obj.FilterSwitch.FontName = Aes.uiFontName;
obj.FilterSwitch.Value = '0';
obj.FilterSwitch.Tag = 'Filter';
obj.FilterSwitch.Layout.Row = 2;
obj.FilterSwitch.Layout.Column = 4;

% Create DatumLabel
obj.DataLabel = uilabel(obj.SwitchGrid);
obj.DataLabel.HorizontalAlignment = 'center';
obj.DataLabel.FontColor = [0.9412 0.9412 0.9412];
obj.DataLabel.FontName = Aes.uiFontName;
obj.DataLabel.FontSize = Aes.uiFontSize('custom',2);
obj.DataLabel.Text = 'Data';
obj.DataLabel.Layout.Row = 3;
obj.DataLabel.Layout.Column = 5;

% Create DataLamp
obj.DataLamp = uilamp(obj.SwitchGrid);
obj.DataLamp.Layout.Row = 1;
obj.DataLamp.Layout.Column = 5;
obj.DataLamp.Color = Aes.appColor(1,'green');

% Create DatumSwitch
obj.DatumSwitch = uiswitch(obj.SwitchGrid, 'toggle');
obj.DatumSwitch.Items = {'', ''};
obj.DatumSwitch.ItemsData = {'0', '1'};
obj.DatumSwitch.FontName = Aes.uiFontName;
obj.DatumSwitch.Interruptible = 'off';
obj.DatumSwitch.Value = '1';
obj.DatumSwitch.Tag = 'Data';
obj.DatumSwitch.Layout.Row = 2;
obj.DatumSwitch.Layout.Column = 5;

%%% Create the data ticker / navigator region

% Create CurrentDataLabel
obj.CurrentDataLabel = uilabel(obj.PlotControlGrid);
obj.CurrentDataLabel.HorizontalAlignment = 'center';
obj.CurrentDataLabel.VerticalAlignment = 'bottom';
obj.CurrentDataLabel.FontName = Aes.uiFontName;
obj.CurrentDataLabel.FontSize = Aes.uiFontSize('custom',8);
obj.CurrentDataLabel.FontWeight = 'bold';
obj.CurrentDataLabel.Text = ':::::  Current Data  :::::';
obj.CurrentDataLabel.Layout.Row = 1;
obj.CurrentDataLabel.Layout.Column = 2;

% Create the navigator and ticker grid
% Create NavigatorGrid
obj.NavigatorGrid = uigridlayout(obj.PlotControlGrid);
obj.NavigatorGrid.ColumnWidth = {'1.2x', '1x', '4x', '1x', '1.2x'};
obj.NavigatorGrid.RowHeight = {'1x'};
obj.NavigatorGrid.ColumnSpacing = 5;
obj.NavigatorGrid.Padding = [0 5 0 5];
obj.NavigatorGrid.Layout.Row = 2;
obj.NavigatorGrid.Layout.Column = 2;

% big steps
% Create CurrentDatumIncBig
obj.CurrentDatumIncBig = uibutton(obj.NavigatorGrid, 'push');
obj.CurrentDatumIncBig.FontName = 'Courier New';
obj.CurrentDatumIncBig.FontSize = Aes.uiFontSize('custom');
obj.CurrentDatumIncBig.FontWeight = 'bold';
obj.CurrentDatumIncBig.Text = '>>';
obj.CurrentDatumIncBig.Layout.Row = 1;
obj.CurrentDatumIncBig.Layout.Column = 5;

% Create CurrentDatumDecBig
obj.CurrentDatumDecBig = uibutton(obj.NavigatorGrid, 'push');
obj.CurrentDatumDecBig.FontName = 'Courier New';
obj.CurrentDatumDecBig.FontSize = Aes.uiFontSize('custom');
obj.CurrentDatumDecBig.FontWeight = 'bold';
obj.CurrentDatumDecBig.Text = '<<';
obj.CurrentDatumDecBig.Layout.Row = 1;
obj.CurrentDatumDecBig.Layout.Column = 1;

% small steps
% Create CurrentDatumIncSmall
obj.CurrentDatumIncSmall = uibutton(obj.NavigatorGrid, 'push');
obj.CurrentDatumIncSmall.FontName = 'Courier New';
obj.CurrentDatumIncSmall.FontSize = Aes.uiFontSize('custom',24);
obj.CurrentDatumIncSmall.FontWeight = 'bold';
obj.CurrentDatumIncSmall.Text = '>';
obj.CurrentDatumIncSmall.Layout.Row = 1;
obj.CurrentDatumIncSmall.Layout.Column = 4;

% Create CurrentDatumDecSmall
obj.CurrentDatumDecSmall = uibutton(obj.NavigatorGrid, 'push');
obj.CurrentDatumDecSmall.FontName = 'Courier New';
obj.CurrentDatumDecSmall.FontSize = Aes.uiFontSize('custom',24);
obj.CurrentDatumDecSmall.FontWeight = 'bold';
obj.CurrentDatumDecSmall.Text = '<';
obj.CurrentDatumDecSmall.Layout.Row = 1;
obj.CurrentDatumDecSmall.Layout.Column = 2;

% ticker
% Create CurrentDataTicker
obj.CurrentDataTicker = uieditfield(obj.NavigatorGrid, 'text');
obj.CurrentDataTicker.HorizontalAlignment = 'center';
obj.CurrentDataTicker.FontName = 'Courier New';
obj.CurrentDataTicker.FontSize = Aes.uiFontSize('custom',22);
obj.CurrentDataTicker.FontWeight = 'bold';
obj.CurrentDataTicker.Value = '1';
obj.CurrentDataTicker.Tag = 'CurrentDatum';
obj.CurrentDataTicker.Layout.Row = 1;
obj.CurrentDataTicker.Layout.Column = 3;



%%% Create the Overlap ticker /navigator

% Create OverlapGrid
obj.OverlapGrid = uigridlayout(obj.PlotControlGrid);
obj.OverlapGrid.ColumnWidth = {'1x', '3x', '1x'};
obj.OverlapGrid.RowHeight = {'1x'};
obj.OverlapGrid.ColumnSpacing = 3;
obj.OverlapGrid.RowSpacing = 3;
obj.OverlapGrid.Padding = [0 8 0 8];
obj.OverlapGrid.Layout.Row = 2;
obj.OverlapGrid.Layout.Column = 3;

% Create OverlapLabel
obj.OverlapLabel = uilabel(obj.PlotControlGrid);
obj.OverlapLabel.HorizontalAlignment = 'center';
obj.OverlapLabel.VerticalAlignment = 'bottom';
obj.OverlapLabel.FontName = Aes.uiFontName;
obj.OverlapLabel.FontSize = Aes.uiFontSize('custom',2);
obj.OverlapLabel.FontWeight = 'bold';
obj.OverlapLabel.Layout.Row = 1;
obj.OverlapLabel.Layout.Column = 3;
obj.OverlapLabel.Text = 'Number of Overlayed';

% Create OverlapDec
obj.OverlapDec = uibutton(obj.OverlapGrid, 'push');
obj.OverlapDec.IconAlignment = 'center';
obj.OverlapDec.Icon = fullfile(Info.getResourcePath, 'icn', 'DecrementIcon.png');
obj.OverlapDec.Text = '';
obj.OverlapDec.Layout.Row = 1;
obj.OverlapDec.Layout.Column = 1;

% Create OverlapInc
obj.OverlapInc = uibutton(obj.OverlapGrid, 'push');
obj.OverlapInc.IconAlignment = 'center';
obj.OverlapInc.Icon = fullfile(Info.getResourcePath, 'icn', 'IncrementIcon.png');
obj.OverlapInc.Layout.Row = 1;
obj.OverlapInc.Layout.Column = 3;
obj.OverlapInc.Text = '';

% Create OverlapTicker
obj.OverlapTicker = uieditfield(obj.OverlapGrid, 'text');
obj.OverlapTicker.HorizontalAlignment = 'center';
obj.OverlapTicker.FontName = 'Courier New';
obj.OverlapTicker.FontSize = Aes.uiFontSize('custom');
obj.OverlapTicker.FontWeight = 'bold';
obj.OverlapTicker.Layout.Row = 1;
obj.OverlapTicker.Layout.Column = 2;
obj.OverlapTicker.Value = '1';
obj.OverlapTicker.Tag = 'Overlap';


%%% Create the Selection Navigator

% Create SelectionNavigatorLabel
obj.SelectionNavigatorLabel = uilabel(obj.PlotControlGrid);
obj.SelectionNavigatorLabel.HorizontalAlignment = 'center';
obj.SelectionNavigatorLabel.VerticalAlignment = 'bottom';
obj.SelectionNavigatorLabel.FontName = Aes.uiFontName;
obj.SelectionNavigatorLabel.FontSize = Aes.uiFontSize('custom',2);
obj.SelectionNavigatorLabel.FontWeight = 'bold';
obj.SelectionNavigatorLabel.Text = 'Selection Navigator';
obj.SelectionNavigatorLabel.Layout.Row = 1;
obj.SelectionNavigatorLabel.Layout.Column = 4;

% Create SelectionNavigatorSlider
obj.SelectionNavigatorSlider = uislider(obj.PlotControlGrid);
obj.SelectionNavigatorSlider.Value = 1;
obj.SelectionNavigatorSlider.MinorTicksMode = 'manual';
obj.SelectionNavigatorSlider.MinorTicks = [];
obj.SelectionNavigatorSlider.MajorTicks = 1;
obj.SelectionNavigatorSlider.MajorTicksMode = 'manual';
obj.SelectionNavigatorSlider.Limits = [0.5, 1.49];
obj.SelectionNavigatorSlider.FontName = Aes.uiFontName;
obj.SelectionNavigatorSlider.Layout.Row = 2;
obj.SelectionNavigatorSlider.Layout.Column = 4;
obj.SelectionNavigatorSlider.Tag = 'Slider';

%%% Create the Axes object

% Create AxesPanel
obj.AxesPanel = uipanel(obj.containerGrid);
obj.AxesPanel.BackgroundColor = [1 1 1];
obj.AxesPanel.Layout.Row = 2;
obj.AxesPanel.Layout.Column = 1;
obj.AxesPanel.BorderType = 'none';
obj.AxesPanel.FontName = Aes.uiFontName;

% Create Axes
obj.Axes = iris.ui.elements.AxesPanel( ...
  obj.AxesPanel, ...
  'margins', ...
    [ ...
      obj.layout.margin.l, ...
      obj.layout.margin.t, ...
      obj.layout.margin.r, ...
      obj.layout.margin.b ...
    ], ...
  'FontWeight', 'bold', ...
  'FontName', Aes.uiFontName ...
  );

%%% Create Extended Info panel

% Create ExtendedInfoPanel
obj.ExtendedInfoPanel = uipanel(obj.containerGrid);
obj.ExtendedInfoPanel.AutoResizeChildren = 'off';
obj.ExtendedInfoPanel.BackgroundColor = [0.9412 0.9412 0.9412];
obj.ExtendedInfoPanel.Layout.Row = [1 2];
obj.ExtendedInfoPanel.Layout.Column = 2;

% Create ExtendedInfoGrid
obj.ExtendedInfoGrid = uigridlayout(obj.ExtendedInfoPanel);
obj.ExtendedInfoGrid.ColumnWidth = {80, '1x'};
obj.ExtendedInfoGrid.RowHeight = {'8x', 22, 22, '1x'};
obj.ExtendedInfoGrid.ColumnSpacing = 5;
obj.ExtendedInfoGrid.RowSpacing = 5;
obj.ExtendedInfoGrid.Padding = [3 5 3 0];

% Create CurrentInfoPanel
obj.CurrentInfoPanel = uipanel(obj.ExtendedInfoGrid);
obj.CurrentInfoPanel.TitlePosition = 'centertop';
obj.CurrentInfoPanel.Title = 'Selected Info';
obj.CurrentInfoPanel.FontWeight = 'bold';
obj.CurrentInfoPanel.BackgroundColor = [1 1 1];
obj.CurrentInfoPanel.FontName = Aes.uiFontName;
obj.CurrentInfoPanel.Layout.Row = 1;
obj.CurrentInfoPanel.Layout.Column = [1 2];

% Create CurrentInfoGrid
obj.CurrentInfoGrid = uigridlayout(obj.CurrentInfoPanel);
obj.CurrentInfoGrid.ColumnWidth = {'1x'};
obj.CurrentInfoGrid.RowHeight = {'1x'};
obj.CurrentInfoGrid.Padding = [2 0 2 0];

% Create CurrentInfoTable
obj.CurrentInfoTable = uitable(obj.CurrentInfoGrid);
obj.CurrentInfoTable.ColumnName = {'Property'; 'Value'};
obj.CurrentInfoTable.ColumnSortable = [true false];
obj.CurrentInfoTable.RowName = {};
obj.CurrentInfoTable.FontName = Aes.uiFontName;
obj.CurrentInfoTable.FontSize = Aes.uiFontSize('custom',2);
obj.CurrentInfoTable.Layout.Row = 1;
obj.CurrentInfoTable.Layout.Column = 1;
obj.CurrentInfoTable.CellSelectionCallback = @obj.doCopyUITableCell;

% Create ShowingLabel
obj.ShowingLabel = uilabel(obj.ExtendedInfoGrid);
obj.ShowingLabel.FontName = Aes.uiFontName;
obj.ShowingLabel.FontSize = 12;
obj.ShowingLabel.HorizontalAlignment = 'right';
obj.ShowingLabel.FontWeight = 'bold';
obj.ShowingLabel.Layout.Row = 2;
obj.ShowingLabel.Layout.Column = 1;
obj.ShowingLabel.Text = 'Showing:';


% Create ShowingValueLabel
obj.ShowingValueLabel = uilabel(obj.ExtendedInfoGrid);
obj.ShowingValueLabel.FontName = 'Courier New';
obj.ShowingValueLabel.FontSize = 12;
obj.ShowingValueLabel.FontWeight = 'bold';
obj.ShowingValueLabel.HorizontalAlignment = 'center';
obj.ShowingValueLabel.Layout.Row = 2;
obj.ShowingValueLabel.Layout.Column = 2;
obj.ShowingValueLabel.Text = '0 of 0';

% Create DevicesLabel
obj.DevicesLabel = uilabel(obj.ExtendedInfoGrid);
obj.DevicesLabel.FontName = Aes.uiFontName;
obj.DevicesLabel.FontSize = 12;
obj.DevicesLabel.HorizontalAlignment = 'right';
obj.DevicesLabel.Layout.Row = 3;
obj.DevicesLabel.Layout.Column = 1;
obj.DevicesLabel.Text = 'Devices:';

% Create DevicesSelection
obj.DevicesSelection = uilistbox(obj.ExtendedInfoGrid);
obj.DevicesSelection.Items = {'Device 1', 'Device 2', 'Device 3'};
obj.DevicesSelection.Multiselect = 'on';
obj.DevicesSelection.FontName = Aes.uiFontName;
obj.DevicesSelection.FontSize = Aes.uiFontSize('shrink');
obj.DevicesSelection.Layout.Row = 4;
obj.DevicesSelection.Layout.Column = [1 2];
obj.DevicesSelection.Value = {'Device 1', 'Device 2'};


% draw
drawnow;

% now that we've drawn the figure, let's reposition it by first getting the
% stored value
obj.container.Resize = 'on';

storedPosition = obj.position;

if isempty(storedPosition)  
  obj.position = obj.container.Position;
else
  obj.position = storedPosition;
end

end