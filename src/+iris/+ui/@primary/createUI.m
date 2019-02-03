function createUI(obj)
%createUI Creates the primary window view
%% Initialize
import iris.ui.*;
import iris.app.*;
import iris.infra.*;

pos = obj.position;
if isempty(pos)
  initW = 1610;
  initH = 931;
  pos = centerFigPos(initW,initH);
end
if pos(3) ~= 1610
  pos(3) = 1610;
end
if pos(4) ~= 931
  pos(4) = 931;
end
obj.position = pos; %sets container too

set(obj.container, ...
  'Name', [Info.name,' ',Info.year], ...
  'Alphamap', linspace(0,1,2^8));


% Create FileMenu
obj.FileMenu = uimenu(obj.container);
obj.FileMenu.Text = 'File';

% Create NewMenu
obj.NewMenu = uimenu(obj.FileMenu);
obj.NewMenu.Text = 'New';

% Create NewMenu
obj.DataMenu = uimenu(obj.NewMenu);
obj.DataMenu.MenuSelectedFcn = @(s,e)notify(obj,'LoadData');
obj.DataMenu.Accelerator = 'n';
obj.DataMenu.Text = 'Data...';

% Create SessionMenu
obj.SessionMenu = uimenu(obj.NewMenu);
obj.SessionMenu.MenuSelectedFcn = @(s,e)notify(obj,'LoadSession');
obj.SessionMenu.Accelerator = 'o';
obj.SessionMenu.Text = 'Session...';

% Create ImportMenuD
obj.ImportMenuD = uimenu(obj.FileMenu);
obj.ImportMenuD.Text = 'Import';

% Create FromDataMenuD
obj.FromDataMenuD = uimenu(obj.ImportMenuD);
obj.FromDataMenuD.MenuSelectedFcn = @(s,e)notify(obj,'ImportData');
obj.FromDataMenuD.Text = 'From Data...';

% Create FromSessionMenuD
obj.FromSessionMenuD = uimenu(obj.ImportMenuD);
obj.FromSessionMenuD.MenuSelectedFcn = @(s,e)notify(obj,'ImportSession');
obj.FromSessionMenuD.Text = 'From Session...';

% Create SaveMenu
obj.SaveMenuD = uimenu(obj.FileMenu);
obj.SaveMenuD.MenuSelectedFcn = @(s,e)notify(obj,'SaveSession');
obj.SaveMenuD.Enable = 'off';
obj.SaveMenuD.Accelerator = 's';
obj.SaveMenuD.Text = 'Save';

% Create QuitMenu
obj.QuitMenu = uimenu(obj.FileMenu);
obj.QuitMenu.MenuSelectedFcn = @(s,e)notify(obj,'Close');
obj.QuitMenu.Separator = 'on';
obj.QuitMenu.Accelerator = 'q';
obj.QuitMenu.Text = 'Quit';

% Create ViewMenu
obj.ViewMenu = uimenu(obj.container);
obj.ViewMenu.Text = 'View';

% Create FileInfoMenuD
obj.FileInfoMenuD = uimenu(obj.ViewMenu);
obj.FileInfoMenuD.MenuSelectedFcn = @(s,e)notify(obj,'MenuCalled',eventData('FileInfo'));
obj.FileInfoMenuD.Enable = 'off';
obj.FileInfoMenuD.Accelerator = 'i';
obj.FileInfoMenuD.Text = 'File Info...';

% Create NotesMenuD
obj.NotesMenuD = uimenu(obj.ViewMenu);
obj.NotesMenuD.MenuSelectedFcn = @(s,e)notify(obj,'MenuCalled',eventData('Notes'));
obj.NotesMenuD.Enable = 'off';
obj.NotesMenuD.Accelerator = 'n';
obj.NotesMenuD.Text = 'Notes...';

% Create ProtocolsMenuD
obj.ProtocolsMenuD = uimenu(obj.ViewMenu);
obj.ProtocolsMenuD.MenuSelectedFcn = @(s,e)notify(obj,'MenuCalled',eventData('Protocols'));
obj.ProtocolsMenuD.Enable = 'off';
obj.ProtocolsMenuD.Accelerator = 'p';
obj.ProtocolsMenuD.Text = 'Protocols...';

% Create PreferencesMenu
obj.PreferencesMenu = uimenu(obj.ViewMenu);
obj.PreferencesMenu.MenuSelectedFcn = @(s,e)notify(obj,'MenuCalled',eventData('Preferences'));
obj.PreferencesMenu.Separator = 'on';
obj.PreferencesMenu.Text = 'Preferences...';

% Create AnalysisMenu
obj.AnalysisMenu = uimenu(obj.container);
obj.AnalysisMenu.Text = 'Analysis';

% Create ImportAnalysisMenu
obj.ImportAnalysisMenu = uimenu(obj.AnalysisMenu);
obj.ImportAnalysisMenu.MenuSelectedFcn = @(s,e)notify(obj,'ImportAnalysis');
obj.ImportAnalysisMenu.Text = 'Import...';

% Create AnalyzeMenuD
obj.AnalyzeMenuD = uimenu(obj.AnalysisMenu);
obj.AnalyzeMenuD.MenuSelectedFcn = @(s,e)notify(obj,'DoAnalysis');
obj.AnalyzeMenuD.Enable = 'off';
obj.AnalyzeMenuD.Accelerator = 'd';
obj.AnalyzeMenuD.Text = 'Analyze...';

% Create AnalyzeMenuD
obj.OverviewMenuD = uimenu(obj.AnalysisMenu);
obj.OverviewMenuD.MenuSelectedFcn = @(s,e)notify(obj,'ShowOverview');
obj.OverviewMenuD.Enable = 'off';
obj.OverviewMenuD.Text = 'Data Overview...';


% Create CreateNewMenu
obj.CreateNewMenu = uimenu(obj.AnalysisMenu);
obj.CreateNewMenu.MenuSelectedFcn = @(s,e)notify(obj,'CreateNewAnalysis');
obj.CreateNewMenu.Text = 'Create New...';

% Create ExportFigureMenuD
obj.ExportFigureMenuD = uimenu(obj.AnalysisMenu);
obj.ExportFigureMenuD.MenuSelectedFcn = @(s,e)notify(obj,'ExportDataView');
obj.ExportFigureMenuD.Enable = 'off';
obj.ExportFigureMenuD.Separator = 'on';
obj.ExportFigureMenuD.Text = 'Export Figure...';

% Create SendtoCmdMenuD
obj.SendtoCmdMenuD = uimenu(obj.AnalysisMenu);
obj.SendtoCmdMenuD.MenuSelectedFcn = @(s,e)notify(obj,'SendToCmd');
obj.SendtoCmdMenuD.Enable = 'off';
obj.SendtoCmdMenuD.Accelerator = 'm';
obj.SendtoCmdMenuD.Text = 'Send to Cmd';

% Create HelpMenu
obj.HelpMenu = uimenu(obj.container);
obj.HelpMenu.Text = 'Help';

% Create AboutMenu
obj.AboutMenu = uimenu(obj.HelpMenu);
obj.AboutMenu.MenuSelectedFcn = @(s,e)notify(obj,'MenuCalled',eventData('About'));
obj.AboutMenu.Text = 'About Iris';

% Create DocumentationMenu
obj.DocumentationMenu = uimenu(obj.HelpMenu);
obj.DocumentationMenu.MenuSelectedFcn = @(s,e)notify(obj,'ShowHelpDocs');
obj.DocumentationMenu.Accelerator = 'h';
obj.DocumentationMenu.Text = 'Documentation';

% Create Start Panel
obj.StartPanel = uipanel(obj.container);
obj.StartPanel.AutoResizeChildren = 'off';
obj.StartPanel.BackgroundColor = [1 1 1];
obj.StartPanel.Position = [16 16 1240 726];
obj.StartPanel.BorderType = 'none';
obj.StartPanel.FontName = Aes.uiFontName;

% Create StartLabel
obj.StartLabel = uilabel(obj.StartPanel);
obj.StartLabel.FontName = Aes.uiFontName;
obj.StartLabel.FontSize = 28;
obj.StartLabel.HorizontalAlignment = 'center';
obj.StartLabel.Position = [1240/2-200, 726/2-25 400 50];
obj.StartLabel.Text = 'Load Data or Session to get started.';

% Create Axes
obj.AxesPanel = uipanel(obj.container);
obj.AxesPanel.AutoResizeChildren = 'off';
obj.AxesPanel.BackgroundColor = [1 1 1];
obj.AxesPanel.Position = [16 16 1240 726];
obj.AxesPanel.BorderType = 'none';
obj.AxesPanel.FontName = Aes.uiFontName;

%{
obj.Axes = uiaxes(obj.container);
obj.Axes.BackgroundColor = [1 1 1];
obj.Axes.FontName = Aes.uiFontName;
xlabel(obj.Axes, 'X');
ylabel(obj.Axes, 'Y');

obj.Axes.XLimMode = 'auto';
obj.Axes.XLimMode = 'auto';
obj.Axes.XLabel.Units = 'normalized';
obj.Axes.XLabel.FontWeight = 'bold';          
obj.Axes.YLabel.Units = 'normalized';
obj.Axes.YLabel.FontWeight = 'bold';
obj.Axes.Position = [20 17 1226 717];
%}

% Create CurrentInfo
obj.CurrentInfo = uipanel(obj.container);
obj.CurrentInfo.AutoResizeChildren = 'off';
obj.CurrentInfo.Title = '    Current Info';
obj.CurrentInfo.FontWeight = 'bold';
obj.CurrentInfo.BackgroundColor = [1 1 1];
obj.CurrentInfo.FontName = Aes.uiFontName;
obj.CurrentInfo.Position = [1263 16 332 891];

% Create CurrentInfoTable
obj.CurrentInfoTable = uitable(obj.CurrentInfo);
obj.CurrentInfoTable.ColumnName = {'Property'; 'Value'};
obj.CurrentInfoTable.RowName = {};
obj.CurrentInfoTable.FontName = Aes.uiFontName;
obj.CurrentInfoTable.FontSize = 14;
obj.CurrentInfoTable.Position = ...
  [ ...
    6, 150, ...
    obj.CurrentInfo.Position(3) - 11, ...
    obj.CurrentInfo.Position(4) - (155+20) ...
  ];

% Create ExtendedInfo
obj.ExtendedInfo = uipanel(obj.CurrentInfo);
obj.ExtendedInfo.AutoResizeChildren = 'off';
obj.ExtendedInfo.BackgroundColor = [0.9412 0.9412 0.9412];
obj.ExtendedInfo.Position = [1 1 331 145];

% Create ShowingLabel
obj.ShowingLabel = uilabel(obj.ExtendedInfo);
obj.ShowingLabel.FontName = Aes.uiFontName;
obj.ShowingLabel.FontSize = 12;
obj.ShowingLabel.HorizontalAlignment = 'right';
obj.ShowingLabel.FontWeight = 'bold';
obj.ShowingLabel.Position = [5 145-22 55 22];
obj.ShowingLabel.Text = 'Showing:';

% Create ShowingValueString
obj.ShowingValueString = uilabel(obj.ExtendedInfo);
obj.ShowingValueString.FontName = 'Courier New';
obj.ShowingValueString.FontSize = 12;
obj.ShowingValueString.FontWeight = 'bold';
obj.ShowingValueString.HorizontalAlignment = 'center';
obj.ShowingValueString.Position = [60 145-25 331-60-5 22];
obj.ShowingValueString.Text = '0 of 0';

% Create DevicesLabel
obj.DevicesLabel = uilabel(obj.ExtendedInfo);
obj.DevicesLabel.FontName = Aes.uiFontName;
obj.DevicesLabel.FontSize = 12;
obj.DevicesLabel.HorizontalAlignment = 'right';
obj.DevicesLabel.Position = [5 145-45 48 22];
obj.DevicesLabel.Text = 'Devices:';

% Create DevicesSelection
obj.DevicesSelection = uilistbox(obj.ExtendedInfo);
obj.DevicesSelection.Items = {'Device 1', 'Device 2'};
obj.DevicesSelection.Multiselect = 'on';
obj.DevicesSelection.FontName = Aes.uiFontName;
obj.DevicesSelection.Position = [20 52 331-40 145-(75+22)];
obj.DevicesSelection.Value = {'Device 1', 'Device 2'};
obj.DevicesSelection.ValueChangedFcn = @(s,e)...
  notify(obj,'DeviceViewChanged',eventData(e));

% Create ViewNotesButton
obj.ViewNotesButton = uibutton(obj.ExtendedInfo, 'push');
obj.ViewNotesButton.ButtonPushedFcn = @(s,e)notify(obj,'MenuCalled',eventData('Notes'));
obj.ViewNotesButton.FontName = Aes.uiFontName;
obj.ViewNotesButton.Text = 'View Notes';
obj.ViewNotesButton.Position = [45 7 100 38];

% Create ExtendedInfoButton
obj.ExtendedInfoButton = uibutton(obj.ExtendedInfo, 'push');
obj.ExtendedInfoButton.ButtonPushedFcn = @(s,e)notify(obj,'MenuCalled',eventData('Protocols'));
obj.ExtendedInfoButton.FontName = Aes.uiFontName;
obj.ExtendedInfoButton.Text = 'Extended Info';
obj.ExtendedInfoButton.Position = [190 7 100 38];

% Create PlotControlTools
obj.PlotControlTools = uipanel(obj.container);
obj.PlotControlTools.AutoResizeChildren = 'off';
obj.PlotControlTools.Title = '    Plot Control';
obj.PlotControlTools.FontWeight = 'bold';
obj.PlotControlTools.BackgroundColor = [1 1 1];
obj.PlotControlTools.FontName = Aes.uiFontName;
obj.PlotControlTools.Position = [16 749 1240 157];

% Create OverlapLabel
obj.OverlapLabel = uilabel(obj.PlotControlTools);
obj.OverlapLabel.HorizontalAlignment = 'center';
obj.OverlapLabel.FontName = Aes.uiFontName;
obj.OverlapLabel.FontSize = 14;
obj.OverlapLabel.FontWeight = 'bold';
obj.OverlapLabel.Position = [767 90 136 22];
obj.OverlapLabel.Text = 'Number of Overlayed';

% Create OverlapTicker
obj.OverlapTicker = uieditfield(obj.PlotControlTools, 'text');
obj.OverlapTicker.ValueChangedFcn = @(s,e)obj.ValidateTicker(s.Tag,e);
obj.OverlapTicker.HorizontalAlignment = 'center';
obj.OverlapTicker.FontName = 'Courier New';
obj.OverlapTicker.FontSize = 28;
obj.OverlapTicker.FontWeight = 'bold';
obj.OverlapTicker.Position = [786 34 98 41];
obj.OverlapTicker.Value = '1';
obj.OverlapTicker.Tag = 'Overlap';

% Create CurrentDataLabel
obj.CurrentDataLabel = uilabel(obj.PlotControlTools);
obj.CurrentDataLabel.HorizontalAlignment = 'center';
obj.CurrentDataLabel.VerticalAlignment = 'bottom';
obj.CurrentDataLabel.FontName = Aes.uiFontName;
obj.CurrentDataLabel.FontSize = 20;
obj.CurrentDataLabel.FontWeight = 'bold';
obj.CurrentDataLabel.Position = [398 94 209 25];
obj.CurrentDataLabel.Text = ':::::  Current Data  :::::';

% Create CurrentEpochTicker
obj.CurrentEpochTicker = uieditfield(obj.PlotControlTools, 'text');
obj.CurrentEpochTicker.ValueChangedFcn = @(s,e)obj.ValidateTicker(s.Tag,e);
obj.CurrentEpochTicker.HorizontalAlignment = 'center';
obj.CurrentEpochTicker.FontName = 'Courier New';
obj.CurrentEpochTicker.FontSize = 36;
obj.CurrentEpochTicker.FontWeight = 'bold';
obj.CurrentEpochTicker.Position = [429 28 145 51];
obj.CurrentEpochTicker.Value = '1';
obj.CurrentEpochTicker.Tag = 'CurrentEpoch';

% Create CurrentEpochSlider
obj.CurrentEpochSlider = uislider(obj.PlotControlTools);
obj.CurrentEpochSlider.Limits = [0.5, 1.49];
obj.CurrentEpochSlider.ValueChangedFcn = @(s,e)obj.ValidateTicker(s.Tag,e);
obj.CurrentEpochSlider.ValueChangingFcn = @obj.SliderChanging;
obj.CurrentEpochSlider.FontName = Aes.uiFontName;
obj.CurrentEpochSlider.Position = [992 64 218 3];

obj.CurrentEpochSlider.Value = 1;
obj.CurrentEpochSlider.Tag = 'Slider';

% Create CurrentEpochDecSmall
obj.CurrentEpochDecSmall = uibutton(obj.PlotControlTools, 'push');
obj.CurrentEpochDecSmall.ButtonPushedFcn = @(s,e) ...
  notify(obj,'NavigateData', ...
  eventData( ...
    struct('Direction','Decrement', 'Amount', 'Small', 'Type', 'Epoch') ...
  ) ...
  );
obj.CurrentEpochDecSmall.FontName = 'Courier New';
obj.CurrentEpochDecSmall.FontSize = 36;
obj.CurrentEpochDecSmall.FontWeight = 'bold';
obj.CurrentEpochDecSmall.Position = [379 27 40 53];
obj.CurrentEpochDecSmall.Text = '<';

% Create CurrentEpochIncSmall
obj.CurrentEpochIncSmall = uibutton(obj.PlotControlTools, 'push');
obj.CurrentEpochIncSmall.ButtonPushedFcn = @(s,e) ...
  notify(obj,'NavigateData', ...
  eventData( ...
    struct('Direction','Increment', 'Amount', 'Small', 'Type', 'Epoch') ...
  ) ...
  );
obj.CurrentEpochIncSmall.FontName = 'Courier New';
obj.CurrentEpochIncSmall.FontSize = 36;
obj.CurrentEpochIncSmall.FontWeight = 'bold';
obj.CurrentEpochIncSmall.Position = [584 27 40 53];
obj.CurrentEpochIncSmall.Text = '>';

% Create OverlapInc
obj.OverlapInc = uibutton(obj.PlotControlTools, 'push');
obj.OverlapInc.ButtonPushedFcn = @(s,e) ...
  notify(obj,'NavigateData', ...
  eventData( ...
    struct('Direction','Increment', 'Amount', 'Small', 'Type', 'Overlay') ...
  ) ...
  );
obj.OverlapInc.VerticalAlignment = 'top';
obj.OverlapInc.FontName = 'Courier New';
obj.OverlapInc.FontSize = 28;
obj.OverlapInc.FontWeight = 'bold';
obj.OverlapInc.Position = [894 34 37 42];
obj.OverlapInc.Text = '}';

% Create OverlapDec
obj.OverlapDec = uibutton(obj.PlotControlTools, 'push');
obj.OverlapDec.ButtonPushedFcn = @(s,e) ...
  notify(obj,'NavigateData', ...
  eventData( ...
    struct('Direction','Decrement', 'Amount', 'Small', 'Type', 'Overlay') ...
  ) ...
  );
obj.OverlapDec.VerticalAlignment = 'top';
obj.OverlapDec.FontName = 'Courier New';
obj.OverlapDec.FontSize = 28;
obj.OverlapDec.FontWeight = 'bold';
obj.OverlapDec.Position = [739 34 37 42];
obj.OverlapDec.Text = '{';

% Create CurrentEpochIncBig
obj.CurrentEpochIncBig = uibutton(obj.PlotControlTools, 'push');
obj.CurrentEpochIncBig.ButtonPushedFcn = @(s,e) ...
  notify(obj,'NavigateData', ...
  eventData( ...
    struct('Direction','Increment', 'Amount', 'Big', 'Type', 'Epoch') ...
  ) ...
  );
obj.CurrentEpochIncBig.FontName = 'Courier New';
obj.CurrentEpochIncBig.FontSize = 28;
obj.CurrentEpochIncBig.FontWeight = 'bold';
obj.CurrentEpochIncBig.Position = [634 29 50 50];
obj.CurrentEpochIncBig.Text = '>>';

% Create CurrentEpochDecBig
obj.CurrentEpochDecBig = uibutton(obj.PlotControlTools, 'push');
obj.CurrentEpochDecBig.ButtonPushedFcn = @(s,e) ...
  notify(obj,'NavigateData', ...
  eventData( ...
    struct('Direction','Decrement', 'Amount', 'Big', 'Type', 'Epoch') ...
  ) ...
  );
obj.CurrentEpochDecBig.FontName = 'Courier New';
obj.CurrentEpochDecBig.FontSize = 28;
obj.CurrentEpochDecBig.FontWeight = 'bold';
obj.CurrentEpochDecBig.Position = [319 29 50 50];
obj.CurrentEpochDecBig.Text = '<<';

% Create SelectionNavigatorLabel
obj.SelectionNavigatorLabel = uilabel(obj.PlotControlTools);
obj.SelectionNavigatorLabel.HorizontalAlignment = 'center';
obj.SelectionNavigatorLabel.FontName = Aes.uiFontName;
obj.SelectionNavigatorLabel.FontSize = 14;
obj.SelectionNavigatorLabel.FontWeight = 'bold';
obj.SelectionNavigatorLabel.Position = [1040 90 123 22];
obj.SelectionNavigatorLabel.Text = 'Selection Navigator';

% Create SwitchPanel
obj.SwitchPanel = uipanel(obj.PlotControlTools);
obj.SwitchPanel.AutoResizeChildren = 'off';
obj.SwitchPanel.BorderType = 'none';
obj.SwitchPanel.BackgroundColor = [0.502 0.502 0.502];
obj.SwitchPanel.FontName = Aes.uiFontName;
obj.SwitchPanel.Position = [18 8 246 123];

% Create ScaleLabel
obj.ScaleLabel = uilabel(obj.SwitchPanel);
obj.ScaleLabel.HandleVisibility = 'off';
obj.ScaleLabel.HorizontalAlignment = 'center';
obj.ScaleLabel.FontName = Aes.uiFontName;
obj.ScaleLabel.FontSize = 14;
obj.ScaleLabel.FontColor = [1 1 1];
obj.ScaleLabel.Position = [35 12 36 22];
obj.ScaleLabel.Text = 'Scale';

% Create ScaleLamp
obj.ScaleLamp = uilamp(obj.SwitchPanel);
obj.ScaleLamp.Position = [46 97 14 14];
obj.ScaleLamp.Color = Aes.appColor(1,'red');

% Create ScaleSwitch
obj.ScaleSwitch = uiswitch(obj.SwitchPanel, 'toggle');
obj.ScaleSwitch.Items = {'', ''};
obj.ScaleSwitch.ItemsData = {'0', '1'};
obj.ScaleSwitch.ValueChangedFcn = @obj.SwitchFlipped;
obj.ScaleSwitch.HandleVisibility = 'off';
obj.ScaleSwitch.FontName = Aes.uiFontName;
obj.ScaleSwitch.Position = [41 36 22 50];
obj.ScaleSwitch.Value = '0';
obj.ScaleSwitch.Tag = 'Scale';

% Create BaselineLabel
obj.BaselineLabel = uilabel(obj.SwitchPanel);
obj.BaselineLabel.HandleVisibility = 'off';
obj.BaselineLabel.HorizontalAlignment = 'center';
obj.BaselineLabel.FontName = Aes.uiFontName;
obj.BaselineLabel.FontSize = 14;
obj.BaselineLabel.FontColor = [1 1 1];
obj.BaselineLabel.Position = [72 12 54 22];
obj.BaselineLabel.Text = 'Baseline';

% Create BaselineLamp
obj.BaselineLamp = uilamp(obj.SwitchPanel);
obj.BaselineLamp.Position = [92 97 14 14];
obj.BaselineLamp.Color = Aes.appColor(1,'red');

% Create BaselineSwitch
obj.BaselineSwitch = uiswitch(obj.SwitchPanel, 'toggle');
obj.BaselineSwitch.Items = {'', ''};
obj.BaselineSwitch.ItemsData = {'0', '1'};
obj.BaselineSwitch.ValueChangedFcn = @obj.SwitchFlipped;
obj.BaselineSwitch.HandleVisibility = 'off';
obj.BaselineSwitch.FontName = Aes.uiFontName;
obj.BaselineSwitch.Position = [87 36 22 50];
obj.BaselineSwitch.Value = '0';
obj.BaselineSwitch.Tag = 'Baseline';

% Create FilterLabel
obj.FilterLabel = uilabel(obj.SwitchPanel);
obj.FilterLabel.HandleVisibility = 'off';
obj.FilterLabel.HorizontalAlignment = 'center';
obj.FilterLabel.FontName = Aes.uiFontName;
obj.FilterLabel.FontSize = 14;
obj.FilterLabel.FontColor = [1 1 1];
obj.FilterLabel.Position = [127 12 36 22];
obj.FilterLabel.Text = 'Filter';

% Create FilterLamp
obj.FilterLamp = uilamp(obj.SwitchPanel);
obj.FilterLamp.Position = [138 97 14 14];
obj.FilterLamp.Color = Aes.appColor(1,'red');

% Create FilterSwitch
obj.FilterSwitch = uiswitch(obj.SwitchPanel, 'toggle');
obj.FilterSwitch.Items = {'', ''};
obj.FilterSwitch.ItemsData = {'0', '1'};
obj.FilterSwitch.ValueChangedFcn = @obj.SwitchFlipped;
obj.FilterSwitch.HandleVisibility = 'off';
obj.FilterSwitch.FontName = Aes.uiFontName;
obj.FilterSwitch.Position = [133 36 22 50];
obj.FilterSwitch.Value = '0';
obj.FilterSwitch.Tag = 'Filter';

% Create EpochLabel
obj.EpochLabel = uilabel(obj.SwitchPanel);
obj.EpochLabel.HandleVisibility = 'off';
obj.EpochLabel.HorizontalAlignment = 'center';
obj.EpochLabel.FontName = Aes.uiFontName;
obj.EpochLabel.FontSize = 14;
obj.EpochLabel.FontColor = [1 1 1];
obj.EpochLabel.Position = [170 12 41 22];
obj.EpochLabel.Text = 'Epoch';

% Create EpochLamp
obj.EpochLamp = uilamp(obj.SwitchPanel);
obj.EpochLamp.Position = [184 97 14 14];
obj.EpochLamp.Color = Aes.appColor(1,'green');

% Create EpochSwitch
obj.EpochSwitch = uiswitch(obj.SwitchPanel, 'toggle');
obj.EpochSwitch.Items = {'', ''};
obj.EpochSwitch.ItemsData = {'0', '1'};
obj.EpochSwitch.ValueChangedFcn = @obj.SwitchFlipped;
obj.EpochSwitch.HandleVisibility = 'off';
obj.EpochSwitch.FontName = Aes.uiFontName;
obj.EpochSwitch.Position = [179 36 22 50];
obj.EpochSwitch.Value = '1';
obj.EpochSwitch.Tag = 'Epoch';

% Create KeyboardButton
obj.KeyboardButton = uibutton(obj.container, 'push');
obj.KeyboardButton.ButtonPushedFcn = @obj.KeypressCapture;
obj.KeyboardButton.HandleVisibility = 'callback';
obj.KeyboardButton.Visible = 'off';
obj.KeyboardButton.Position = [1587 42 0 0];
obj.KeyboardButton.Text = '';
end