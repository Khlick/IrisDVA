function createUI(obj)
%% CREATEUI method draws the UI for the preferences window
%% Initialize
import iris.ui.*;
import iris.app.*;
import iris.infra.*;

obj.options.save();

pos = obj.position;
if isempty(pos)
  initW = 616;
  initH = 366;
  pos = centerFigPos(initW,initH);
end
obj.position = pos; %sets container too

obj.container.Name = [Info.name,' Preferences'];

% Create PreferencesLabel
obj.PreferencesLabel = uilabel(obj.container);
obj.PreferencesLabel.FontName = Aes.uiFontName;
obj.PreferencesLabel.FontSize = 22;
obj.PreferencesLabel.Position = [20 327 108 28];
obj.PreferencesLabel.Text = 'Preferences';

% Create PreferencesTree
obj.PreferencesTree = uitree(obj.container);
obj.PreferencesTree.SelectionChangedFcn = @obj.PageActivation;
obj.PreferencesTree.FontName = Aes.uiFontName;
obj.PreferencesTree.FontSize = 18;
obj.PreferencesTree.Position = [15 42 159 277];%[15 15 159 304];

% Create NavigationNode
obj.NavigationNode = uitreenode(obj.PreferencesTree);
obj.NavigationNode.Text = 'Navigation';

% Create KeyboardNode
obj.KeyboardNode = uitreenode(obj.NavigationNode);
obj.KeyboardNode.Icon = fullfile(iris.app.Info.getResourcePath, 'icn', 'icons8-keyboard-64.png');
obj.KeyboardNode.Text = 'Keyboard';

% Create ControlNode
obj.ControlNode = uitreenode(obj.NavigationNode);
obj.ControlNode.Icon = fullfile(iris.app.Info.getResourcePath, 'icn', 'icons8-adjust-100.png');
obj.ControlNode.Text = 'Control';

% Create WorkspaceNode
obj.WorkspaceNode = uitreenode(obj.PreferencesTree);
obj.WorkspaceNode.Text = 'Workspace';

% Create VariablesNode
obj.VariablesNode = uitreenode(obj.WorkspaceNode);
obj.VariablesNode.Icon = fullfile(iris.app.Info.getResourcePath, 'icn', 'icons8-outline-100.png');
obj.VariablesNode.Text = 'Variables';

% Create DisplayNode
obj.DisplayNode = uitreenode(obj.WorkspaceNode);
obj.DisplayNode.Icon = fullfile(iris.app.Info.getResourcePath, 'icn', 'icons8-workspace-96.png');
obj.DisplayNode.Text = 'Display';

% Create DataNode
obj.DataNode = uitreenode(obj.PreferencesTree);
obj.DataNode.Text = 'Data';

% Create FilterNode
obj.FilterNode = uitreenode(obj.DataNode);
obj.FilterNode.Icon = fullfile(iris.app.Info.getResourcePath, 'icn', 'Filter_icon_100px.png');
obj.FilterNode.Text = 'Filter';

% Create StatisticsNode
obj.StatisticsNode = uitreenode(obj.DataNode);
obj.StatisticsNode.Icon = fullfile(iris.app.Info.getResourcePath, 'icn', 'icons8-mu-filled-100.png');
obj.StatisticsNode.Text = 'Statistics';

% Create ScalingNode
obj.ScalingNode = uitreenode(obj.DataNode);
obj.ScalingNode.Icon = fullfile(iris.app.Info.getResourcePath, 'icn', 'icons8-ratio-100.png');
obj.ScalingNode.Text = 'Scaling';

% Create SelectSubsetPanel
obj.SelectSubsetPanel = uipanel(obj.container);
obj.SelectSubsetPanel.AutoResizeChildren = 'off';
obj.SelectSubsetPanel.BackgroundColor = [1 1 1];
obj.SelectSubsetPanel.FontName = Aes.uiFontName;
obj.SelectSubsetPanel.Position = [184 15 415 339];

% Create SelectSubsetLabel
obj.SelectSubsetLabel = uilabel(obj.SelectSubsetPanel);
obj.SelectSubsetLabel.HorizontalAlignment = 'center';
obj.SelectSubsetLabel.FontName = Aes.uiFontName;
obj.SelectSubsetLabel.FontSize = 20;
obj.SelectSubsetLabel.Position = [114 163 174 25];
obj.SelectSubsetLabel.Text = 'Select Setting Subset';

% Create KeyboardPanel
obj.KeyboardPanel = uipanel(obj.container);
obj.KeyboardPanel.AutoResizeChildren = 'off';
obj.KeyboardPanel.Visible = 'off';
obj.KeyboardPanel.BackgroundColor = [1 1 1];
obj.KeyboardPanel.FontName = Aes.uiFontName;
obj.KeyboardPanel.Position = [184 15 415 339];

% Create KeyboardConfig
obj.KeyboardConfig = uipanel(obj.KeyboardPanel);
obj.KeyboardConfig.AutoResizeChildren = 'off';
obj.KeyboardConfig.BorderType = 'none';
obj.KeyboardConfig.Title = 'Keyboard Configuration';
obj.KeyboardConfig.BackgroundColor = [1 1 1];
obj.KeyboardConfig.FontName = Aes.uiFontName;
obj.KeyboardConfig.FontSize = 16;
obj.KeyboardConfig.Position = [5 5 405 320];

% Create ControlPanel
obj.ControlPanel = uipanel(obj.container);
obj.ControlPanel.AutoResizeChildren = 'off';
obj.ControlPanel.Visible = 'off';
obj.ControlPanel.BackgroundColor = [1 1 1];
obj.ControlPanel.FontName = Aes.uiFontName;
obj.ControlPanel.Position = [184 15 415 339];

% Create EpochStepSmallLabel
obj.EpochStepSmallLabel = uilabel(obj.ControlPanel);
obj.EpochStepSmallLabel.HorizontalAlignment = 'right';
obj.EpochStepSmallLabel.FontName = Aes.uiFontName;
obj.EpochStepSmallLabel.FontSize = 20;
obj.EpochStepSmallLabel.Position = [19 223 228 25];
obj.EpochStepSmallLabel.Text = 'Epoch Step Small:';

% Create EpochStepSmallInput
obj.EpochStepSmallInput = uieditfield(obj.ControlPanel, 'numeric');
obj.EpochStepSmallInput.Limits = [1 100];
obj.EpochStepSmallInput.RoundFractionalValues = 'on';
obj.EpochStepSmallInput.ValueDisplayFormat = '%.0f';
obj.EpochStepSmallInput.FontName = 'Courier New';
obj.EpochStepSmallInput.FontSize = 16;
obj.EpochStepSmallInput.Position = [331 226 53 22];
obj.EpochStepSmallInput.Value = 1;
obj.EpochStepSmallInput.ValueChangedFcn = @obj.validateStepSize;

% Create EpochStepBigLabel
obj.EpochStepBigLabel = uilabel(obj.ControlPanel);
obj.EpochStepBigLabel.HorizontalAlignment = 'right';
obj.EpochStepBigLabel.FontName = Aes.uiFontName;
obj.EpochStepBigLabel.FontSize = 20;
obj.EpochStepBigLabel.Position = [19 176 228 25];
obj.EpochStepBigLabel.Text = 'Epoch Step Big:';

% Create EpochStepBigInput
obj.EpochStepBigInput = uieditfield(obj.ControlPanel, 'numeric');
obj.EpochStepBigInput.Limits = [1 100];
obj.EpochStepBigInput.RoundFractionalValues = 'on';
obj.EpochStepBigInput.ValueDisplayFormat = '%.0f';
obj.EpochStepBigInput.FontName = 'Courier New';
obj.EpochStepBigInput.FontSize = 16;
obj.EpochStepBigInput.Position = [331 179 53 22];
obj.EpochStepBigInput.Value = 10;
obj.EpochStepBigInput.ValueChangedFcn = @obj.validateStepSize;

% Create OverlaySmallLabel
obj.OverlaySmallLabel = uilabel(obj.ControlPanel);
obj.OverlaySmallLabel.HorizontalAlignment = 'right';
obj.OverlaySmallLabel.FontName = Aes.uiFontName;
obj.OverlaySmallLabel.FontSize = 20;
obj.OverlaySmallLabel.Position = [19 129 228 25];
obj.OverlaySmallLabel.Text = 'Overlay Small:';

% Create OverlaySmallInput
obj.OverlaySmallInput = uieditfield(obj.ControlPanel, 'numeric');
obj.OverlaySmallInput.Limits = [1 100];
obj.OverlaySmallInput.RoundFractionalValues = 'on';
obj.OverlaySmallInput.ValueDisplayFormat = '%.0f';
obj.OverlaySmallInput.FontName = 'Courier New';
obj.OverlaySmallInput.FontSize = 16;
obj.OverlaySmallInput.Position = [331 132 53 22];
obj.OverlaySmallInput.Value = 1;
obj.OverlaySmallInput.ValueChangedFcn = @obj.validateStepSize;

% Create OverlayBigLabel
obj.OverlayBigLabel = uilabel(obj.ControlPanel);
obj.OverlayBigLabel.HorizontalAlignment = 'right';
obj.OverlayBigLabel.FontName = Aes.uiFontName;
obj.OverlayBigLabel.FontSize = 20;
obj.OverlayBigLabel.Position = [19 82 228 25];
obj.OverlayBigLabel.Text = 'Overlay Big:';

% Create OverlayBigInput
obj.OverlayBigInput = uieditfield(obj.ControlPanel, 'numeric');
obj.OverlayBigInput.Limits = [1 100];
obj.OverlayBigInput.RoundFractionalValues = 'on';
obj.OverlayBigInput.ValueDisplayFormat = '%.0f';
obj.OverlayBigInput.FontName = 'Courier New';
obj.OverlayBigInput.FontSize = 16;
obj.OverlayBigInput.Position = [331 85 53 22];
obj.OverlayBigInput.Value = 5;
obj.OverlayBigInput.ValueChangedFcn = @obj.validateStepSize;

% Create ControlValuesLabel
obj.ControlValuesLabel = uilabel(obj.ControlPanel);
obj.ControlValuesLabel.FontName = Aes.uiFontName;
obj.ControlValuesLabel.FontSize = 16;
obj.ControlValuesLabel.Position = [19 304 101 22];
obj.ControlValuesLabel.Text = 'Control Values';

% Create WorkspacePanel -------------------------------------------------%%
obj.WorkspacePanel = uipanel(obj.container);
obj.WorkspacePanel.AutoResizeChildren = 'off';
obj.WorkspacePanel.Visible = 'on';
obj.WorkspacePanel.BackgroundColor = [1 1 1];
obj.WorkspacePanel.FontName = Aes.uiFontName;
obj.WorkspacePanel.Position = [184 15 415 339];

% File Reader creation button
obj.FileReaderButton = uibutton(obj.WorkspacePanel,'push');
obj.FileReaderButton.Icon = fullfile( ...
  iris.app.Info.getResourcePath, 'icn', 'icons8-plus-208.png' ...
  );
obj.FileReaderButton.VerticalAlignment = 'center';
obj.FileReaderButton.BackgroundColor = [0.9412 0.9412 0.9412];
obj.FileReaderButton.FontName = Aes.uiFontName;
obj.FileReaderButton.FontSize = 14;
obj.FileReaderButton.Position = [367 300 21 22];
obj.FileReaderButton.Text = '';
obj.FileReaderButton.ButtonPushedFcn = @(s,e)obj.createReader;

%{
% Create WorkspaceVariablesLabel
obj.WorkspaceVariablesLabel = uilabel(obj.WorkspacePanel);
obj.WorkspaceVariablesLabel.FontName = Aes.uiFontName;
obj.WorkspaceVariablesLabel.FontSize = 16;
obj.WorkspaceVariablesLabel.Position = [14 304 140 22];
obj.WorkspaceVariablesLabel.Text = 'Workspace Variables';
%}

xO = [23,58,23];
yO = [31, 1, 0];
dims = [ ...
  [208,22]; ...
  [335,22]; ...
  [26,25] ...
  ];
getPos = @(idx,yS)[xO(idx),yO(idx)+yS,dims(idx,:)];

getY = @(n)266-n*62;

% Create OutputDirectoryLabel
obj.OutputDirectoryLabel = uilabel(obj.WorkspacePanel);
obj.OutputDirectoryLabel.FontName = Aes.uiFontName;
obj.OutputDirectoryLabel.FontSize = 18;
obj.OutputDirectoryLabel.Position = getPos(1,getY(0));
obj.OutputDirectoryLabel.Text = 'Output Location:';

% Create OutputDirectoryInput
obj.OutputDirectoryInput = uieditfield(obj.WorkspacePanel, 'text');
obj.OutputDirectoryInput.Editable = 'off';
obj.OutputDirectoryInput.FontName = Aes.uiFontName;
obj.OutputDirectoryInput.BackgroundColor = [0.9412 0.9412 0.9412];
obj.OutputDirectoryInput.Position = getPos(2,getY(0));%[58 244 335 22];

% Create OutputLocationButton
obj.OutputLocationButton = uibutton(obj.WorkspacePanel, 'push');
obj.OutputLocationButton.ButtonPushedFcn = @(s,e)obj.updateDirectory(s,eventData('Output'));
obj.OutputLocationButton.Icon = fullfile(iris.app.Info.getResourcePath, 'icn', 'icons8-folder-128.png');
obj.OutputLocationButton.VerticalAlignment = 'bottom';
obj.OutputLocationButton.BackgroundColor = [0.9412 0.9412 0.9412];
obj.OutputLocationButton.FontName = Aes.uiFontName;
obj.OutputLocationButton.FontSize = 14;
obj.OutputLocationButton.Position = getPos(3,getY(0));%[23 243 26 25];
obj.OutputLocationButton.Text = '';

%{
  ModulesDirectoryLabel           matlab.ui.control.Label
  ModulesDirectoryInput           matlab.ui.control.EditField
  ModulesLocationButton           matlab.ui.control.Button
  ReaderDirectoryLabel           matlab.ui.control.Label
  ReaderDirectoryInput           matlab.ui.control.EditField
  ReaderLocationButton           matlab.ui.control.Button
%}

% Create ModulesDirectoryLabel
obj.ModulesDirectoryLabel = uilabel(obj.WorkspacePanel);
obj.ModulesDirectoryLabel.FontName = Aes.uiFontName;
obj.ModulesDirectoryLabel.FontSize = 18;
obj.ModulesDirectoryLabel.Position = getPos(1,getY(1));
obj.ModulesDirectoryLabel.Text = 'Modules Location:';

% Create ModulesDirectoryInput
obj.ModulesDirectoryInput = uieditfield(obj.WorkspacePanel, 'text');
obj.ModulesDirectoryInput.Editable = 'off';
obj.ModulesDirectoryInput.FontName = Aes.uiFontName;
obj.ModulesDirectoryInput.BackgroundColor = [0.9412 0.9412 0.9412];
obj.ModulesDirectoryInput.Position = getPos(2,getY(1));%[58 244 335 22];

% Create ModulesLocationButton
obj.ModulesLocationButton = uibutton(obj.WorkspacePanel, 'push');
obj.ModulesLocationButton.ButtonPushedFcn = @(s,e)obj.updateDirectory(s,eventData('Modules'));
obj.ModulesLocationButton.Icon = fullfile(iris.app.Info.getResourcePath, 'icn', 'icons8-folder-128.png');
obj.ModulesLocationButton.VerticalAlignment = 'bottom';
obj.ModulesLocationButton.BackgroundColor = [0.9412 0.9412 0.9412];
obj.ModulesLocationButton.FontName = Aes.uiFontName;
obj.ModulesLocationButton.FontSize = 14;
obj.ModulesLocationButton.Position = getPos(3,getY(1));%[23 243 26 25];
obj.ModulesLocationButton.Text = '';


% Create ReaderDirectoryLabel
obj.ReaderDirectoryLabel = uilabel(obj.WorkspacePanel);
obj.ReaderDirectoryLabel.FontName = Aes.uiFontName;
obj.ReaderDirectoryLabel.FontSize = 18;
obj.ReaderDirectoryLabel.Position = getPos(1,getY(2));
obj.ReaderDirectoryLabel.Text = 'Readers Location:';

% Create ReaderDirectoryInput
obj.ReaderDirectoryInput = uieditfield(obj.WorkspacePanel, 'text');
obj.ReaderDirectoryInput.Editable = 'off';
obj.ReaderDirectoryInput.FontName = Aes.uiFontName;
obj.ReaderDirectoryInput.BackgroundColor = [0.9412 0.9412 0.9412];
obj.ReaderDirectoryInput.Position = getPos(2,getY(2));%[58 244 335 22];

% Create ReaderLocationButton
obj.ReaderLocationButton = uibutton(obj.WorkspacePanel, 'push');
obj.ReaderLocationButton.ButtonPushedFcn = @(s,e)obj.updateDirectory(s,eventData('Reader'));
obj.ReaderLocationButton.Icon = fullfile(iris.app.Info.getResourcePath, 'icn', 'icons8-folder-128.png');
obj.ReaderLocationButton.VerticalAlignment = 'bottom';
obj.ReaderLocationButton.BackgroundColor = [0.9412 0.9412 0.9412];
obj.ReaderLocationButton.FontName = Aes.uiFontName;
obj.ReaderLocationButton.FontSize = 14;
obj.ReaderLocationButton.Position = getPos(3,getY(2));%[23 243 26 25];
obj.ReaderLocationButton.Text = '';


% Create AnalysisDirectoryButton
obj.AnalysisDirectoryButton = uibutton(obj.WorkspacePanel, 'push');
obj.AnalysisDirectoryButton.ButtonPushedFcn = @(s,e)obj.updateDirectory(s,eventData('Analysis'));
obj.AnalysisDirectoryButton.Icon = fullfile(iris.app.Info.getResourcePath, 'icn', 'icons8-folder-128.png');
obj.AnalysisDirectoryButton.VerticalAlignment = 'bottom';
obj.AnalysisDirectoryButton.BackgroundColor = [0.9412 0.9412 0.9412];
obj.AnalysisDirectoryButton.FontName = Aes.uiFontName;
obj.AnalysisDirectoryButton.FontSize = 14;
obj.AnalysisDirectoryButton.Position = getPos(3,getY(3));%[23 152 26 25];
obj.AnalysisDirectoryButton.Text = '';

% Create AnalysisDirectoryLabel
obj.AnalysisDirectoryLabel = uilabel(obj.WorkspacePanel);
obj.AnalysisDirectoryLabel.FontName = Aes.uiFontName;
obj.AnalysisDirectoryLabel.FontSize = 18;
obj.AnalysisDirectoryLabel.Position = getPos(1,getY(3));%[23 187 208 22];
obj.AnalysisDirectoryLabel.Text = 'Custom Analysis Directory:';

% Create AnalysisDirectoryInput
obj.AnalysisDirectoryInput = uieditfield(obj.WorkspacePanel, 'text');
obj.AnalysisDirectoryInput.Editable = 'off';
obj.AnalysisDirectoryInput.FontName = Aes.uiFontName;
obj.AnalysisDirectoryInput.BackgroundColor = [0.9412 0.9412 0.9412];
obj.AnalysisDirectoryInput.Position = getPos(2,getY(3));%[58 153 335 22];


% Create AnalysisPrefixLabel
obj.AnalysisPrefixLabel = uilabel(obj.WorkspacePanel);
obj.AnalysisPrefixLabel.FontName = Aes.uiFontName;
obj.AnalysisPrefixLabel.FontSize = 16;
obj.AnalysisPrefixLabel.Position = [23 52 46 22];
obj.AnalysisPrefixLabel.Text = 'Prefix:';

% Create AnalysisPrefixInput
obj.AnalysisPrefixInput = uieditfield(obj.WorkspacePanel, 'text');
obj.AnalysisPrefixInput.HorizontalAlignment = 'center';
obj.AnalysisPrefixInput.FontName = Aes.uiFontName;
obj.AnalysisPrefixInput.FontSize = 14;
obj.AnalysisPrefixInput.Position = [74 52 319 22];
obj.AnalysisPrefixInput.Value = '@()datestr(now, ''YYYYmmmDD'')';
obj.AnalysisPrefixInput.ValueChangedFcn = @obj.validatePrefix;

%{
% Create AnalysisPrefixPreviewLabel
obj.AnalysisPrefixPreviewLabel = uilabel(obj.WorkspacePanel);
obj.AnalysisPrefixPreviewLabel.FontName = Aes.uiFontName;
obj.AnalysisPrefixPreviewLabel.FontSize = 12;
obj.AnalysisPrefixPreviewLabel.FontWeight = 'bold';
obj.AnalysisPrefixPreviewLabel.Position = [23 30 52 18];
obj.AnalysisPrefixPreviewLabel.Text = 'Preview:';
obj.AnalysisPrefixPreviewLabel.BackgroundColor = [1 1 1] - 0.1;
%}

% Create AnalysisPrefixPreviewString
obj.AnalysisPrefixPreviewString = uilabel(obj.WorkspacePanel);
obj.AnalysisPrefixPreviewString.FontName = Aes.uiFontName;
obj.AnalysisPrefixPreviewString.FontSize = 12;
obj.AnalysisPrefixPreviewString.FontAngle = 'italic';
obj.AnalysisPrefixPreviewString.HorizontalAlignment = 'center';
obj.AnalysisPrefixPreviewString.Position = [23 20 370 22];
obj.AnalysisPrefixPreviewString.Text = 'preview';

drawnow;

obj.WorkspacePanel.Visible = 'off';


%%%----------------------------------------------------------------------%%

% Create FilterPanel
obj.FilterPanel = uipanel(obj.container);
obj.FilterPanel.AutoResizeChildren = 'off';
obj.FilterPanel.Visible = 'off';
obj.FilterPanel.BackgroundColor = [1 1 1];
obj.FilterPanel.FontName = Aes.uiFontName;
obj.FilterPanel.Position = [184 15 415 339];

% Create FilterSettingsLabel
obj.FilterSettingsLabel = uilabel(obj.FilterPanel);
obj.FilterSettingsLabel.FontName = Aes.uiFontName;
obj.FilterSettingsLabel.FontSize = 16;
obj.FilterSettingsLabel.Position = [14 304 96 22];
obj.FilterSettingsLabel.Text = 'Filter Settings';

% Create FilterOrderLabel
obj.FilterOrderLabel = uilabel(obj.FilterPanel);
obj.FilterOrderLabel.FontName = Aes.uiFontName;
obj.FilterOrderLabel.FontSize = 18;
obj.FilterOrderLabel.Position = [16 237 193 22];
obj.FilterOrderLabel.Text = 'Butterworth Filter Order: ';

% Create FilterOrderSelect
obj.FilterOrderSelect = uidropdown(obj.FilterPanel);
obj.FilterOrderSelect.Items = {'4', '5', '6', '7', '8', '9', '10', '11'};
obj.FilterOrderSelect.ValueChangedFcn = @(s,e)obj.Notify('FilterChanged', eventData('FilterOrder'));
obj.FilterOrderSelect.FontName = Aes.uiFontName;
obj.FilterOrderSelect.FontSize = 18;
obj.FilterOrderSelect.Position = [294 235 100 24];
obj.FilterOrderSelect.Value = '7';

% Create FilterFrequencyLowLabel
obj.FilterFrequencyLowLabel = uilabel(obj.FilterPanel);
obj.FilterFrequencyLowLabel.FontName = Aes.uiFontName;
obj.FilterFrequencyLowLabel.FontSize = 18;
obj.FilterFrequencyLowLabel.Position = [16 187 222 22];
obj.FilterFrequencyLowLabel.Text = 'Low Pass Frequency [Hertz]: ';

% Create FilterFrequencyLowSelect
obj.FilterFrequencyLowSelect = uidropdown(obj.FilterPanel);
obj.FilterFrequencyLowSelect.Items = {'50', '70', '100', '150', '200', '250', '300', '500', '1000'};
obj.FilterFrequencyLowSelect.ValueChangedFcn = @(s,e)obj.Notify('FilterChanged', eventData('FilterFrequency'));
obj.FilterFrequencyLowSelect.FontName = Aes.uiFontName;
obj.FilterFrequencyLowSelect.FontSize = 18;
obj.FilterFrequencyLowSelect.Position = [294 185 100 24];
obj.FilterFrequencyLowSelect.Value = '100';

% Create FilterFrequencyHighLabel
obj.FilterFrequencyHighLabel = uilabel(obj.FilterPanel);
obj.FilterFrequencyHighLabel.FontName = Aes.uiFontName;
obj.FilterFrequencyHighLabel.FontSize = 18;
obj.FilterFrequencyHighLabel.Position = [16 137 221 22];
obj.FilterFrequencyHighLabel.Text = 'High Pass Frequency [Hertz]:';

% Create FilterFrequencyHighSelect
obj.FilterFrequencyHighSelect = uidropdown(obj.FilterPanel);
obj.FilterFrequencyHighSelect.Items = {'5', '10', '20', '50', '70', '100', '150', '200'};
obj.FilterFrequencyHighSelect.ValueChangedFcn = @(s,e)obj.Notify('FilterChanged', eventData('FilterFrequency'));
obj.FilterFrequencyHighSelect.FontName = Aes.uiFontName;
obj.FilterFrequencyHighSelect.FontSize = 18;
obj.FilterFrequencyHighSelect.Position = [294 135 100 24];
obj.FilterFrequencyHighSelect.Value = '10';

% Create FilterTypeLabel
obj.FilterTypeLabel = uilabel(obj.FilterPanel);
obj.FilterTypeLabel.FontName = Aes.uiFontName;
obj.FilterTypeLabel.FontSize = 18;
obj.FilterTypeLabel.Position = [16 88 90 22];
obj.FilterTypeLabel.Text = 'Filter Type:';

% Create FilterTypeSelect
obj.FilterTypeSelect = uidropdown(obj.FilterPanel);
obj.FilterTypeSelect.Items = {'Lowpass', 'Bandpass', 'Highpass'};
obj.FilterTypeSelect.ValueChangedFcn = @(s,e)obj.Notify('FilterChanged', eventData('FilterType'));
obj.FilterTypeSelect.FontName = Aes.uiFontName;
obj.FilterTypeSelect.FontSize = 18;
obj.FilterTypeSelect.Position = [269 86 125 24];
obj.FilterTypeSelect.Value = 'Lowpass';

%--------------------------------------------------------------------- STATISTICS --%

% Create StatisticsPanel
obj.StatisticsPanel = uipanel(obj.container);
obj.StatisticsPanel.AutoResizeChildren = 'off';
obj.StatisticsPanel.Visible = 'off';
obj.StatisticsPanel.BackgroundColor = [1 1 1];
obj.StatisticsPanel.FontName = Aes.uiFontName;
obj.StatisticsPanel.Position = [184 15 415 339];

% Create StatisticsLabel
obj.StatisticsLabel = uilabel(obj.StatisticsPanel);
obj.StatisticsLabel.FontName = Aes.uiFontName;
obj.StatisticsLabel.FontSize = 16;
obj.StatisticsLabel.Position = [14 304 63 22];
obj.StatisticsLabel.Text = 'Statistics';

% Create GroupByLabel
obj.GroupByLabel = uilabel(obj.StatisticsPanel);
obj.GroupByLabel.FontName = Aes.uiFontName;
obj.GroupByLabel.Position = [25 278 56 22];
obj.GroupByLabel.Text = 'Group By:';

% Create GroupBySelect
obj.GroupBySelect = uilistbox(obj.StatisticsPanel);
obj.GroupBySelect.Items = {'None'};
obj.GroupBySelect.Multiselect = 'on';
obj.GroupBySelect.ValueChangedFcn = @(s,e)obj.Notify('StatisticsChanged', eventData({'GroupBy',s.Value}));
obj.GroupBySelect.FontName = Aes.uiFontName;
obj.GroupBySelect.Position = [25 178 374 101];
obj.GroupBySelect.Value = {'None'};

% Create AggregationStatisticLabel
obj.AggregationStatisticLabel = uilabel(obj.StatisticsPanel);
obj.AggregationStatisticLabel.FontName = Aes.uiFontName;
obj.AggregationStatisticLabel.FontSize = 16;
obj.AggregationStatisticLabel.Position = [25 140 145 22];
obj.AggregationStatisticLabel.Text = 'Aggregation Statistic:';

% Create AggregationStatisticSelect
obj.AggregationStatisticSelect = uidropdown(obj.StatisticsPanel);
obj.AggregationStatisticSelect.Items = {'Mean', 'Median', 'Variance', 'Sum'};
obj.AggregationStatisticSelect.ValueChangedFcn = @(s,e)obj.Notify('StatisticsChanged', eventData({'AggregationStatistic',s.Value}));
obj.AggregationStatisticSelect.FontName = Aes.uiFontName;
obj.AggregationStatisticSelect.FontSize = 16;
obj.AggregationStatisticSelect.BackgroundColor = [1 1 1];
obj.AggregationStatisticSelect.Position = [252 140 129 22];
obj.AggregationStatisticSelect.Value = 'Mean';

% Create ShowAll
obj.ShowAll = uicheckbox(obj.StatisticsPanel);
obj.ShowAll.ValueChangedFcn = @(s,e)obj.Notify('StatisticsChanged', eventData({'ShowAll',s.Value}));
obj.ShowAll.Text = 'Show original traces';
obj.ShowAll.FontName = Aes.uiFontName;
obj.ShowAll.FontSize = 16;
obj.ShowAll.Position = [25 42 154 22];

% Create ZeroBaseline
obj.ZeroBaseline = uicheckbox(obj.StatisticsPanel);
obj.ZeroBaseline.ValueChangedFcn = @(s,e)obj.Notify('StatisticsChanged', eventData({'ZeroBaseline',s.Value}));
obj.ZeroBaseline.Text = 'Baseline zeroing';
obj.ZeroBaseline.FontName = Aes.uiFontName;
obj.ZeroBaseline.FontSize = 16;
obj.ZeroBaseline.Position = [252 42 129 22];
obj.ZeroBaseline.Value = true;

% Create BaselineRegionLabel
obj.BaselineRegionLabel = uilabel(obj.StatisticsPanel);
obj.BaselineRegionLabel.FontName = Aes.uiFontName;
obj.BaselineRegionLabel.FontSize = 16;
obj.BaselineRegionLabel.Position = [25 92 115 22];
obj.BaselineRegionLabel.Text = 'Baseline Region:';

% Create BaselineRegionSelect
obj.BaselineRegionSelect = uidropdown(obj.StatisticsPanel);
obj.BaselineRegionSelect.Items = {'Beginning', 'End', 'Protocol'};
obj.BaselineRegionSelect.ValueChangedFcn = @(s,e)obj.Notify('StatisticsChanged', eventData({'BaselineRegion', s.Value}));
obj.BaselineRegionSelect.FontName = Aes.uiFontName;
obj.BaselineRegionSelect.FontSize = 16;
obj.BaselineRegionSelect.BackgroundColor = [1 1 1];
obj.BaselineRegionSelect.Position = [252 92 129 22];
obj.BaselineRegionSelect.Value = 'Beginning';

% Create PTSEditFieldLabel
obj.PTSEditFieldLabel = uilabel(obj.StatisticsPanel);
obj.PTSEditFieldLabel.VerticalAlignment = 'bottom';
obj.PTSEditFieldLabel.FontName = Aes.uiFontName;
obj.PTSEditFieldLabel.Position = [206 92 26 22];
obj.PTSEditFieldLabel.Text = 'PTS';

% Create BaselinePoints
obj.BaselinePoints = uieditfield(obj.StatisticsPanel, 'numeric');
obj.BaselinePoints.Limits = [1 Inf];
obj.BaselinePoints.RoundFractionalValues = 'on';
obj.BaselinePoints.ValueChangedFcn = @(s,e)obj.Notify('StatisticsChanged', eventData({'BaselinePoints',s.Value}));
obj.BaselinePoints.Position = [160 92 41 22];
obj.BaselinePoints.Value = 100;

%------------------------------------------------------------------------ SCALING --%

% Create ScalingPanel
obj.ScalingPanel = uipanel(obj.container);
obj.ScalingPanel.AutoResizeChildren = 'off';
obj.ScalingPanel.Visible = 'off';
obj.ScalingPanel.BackgroundColor = [1 1 1];
obj.ScalingPanel.FontName = Aes.uiFontName;
obj.ScalingPanel.Position = [184 15 415 339];

% Create ScalingLabel
obj.ScalingLabel = uilabel(obj.ScalingPanel);
obj.ScalingLabel.FontName = Aes.uiFontName;
obj.ScalingLabel.FontSize = 16;
obj.ScalingLabel.Position = [14 304 53 22];
obj.ScalingLabel.Text = 'Scaling';

% Create ScalingmethodSelectLabel
obj.ScalingmethodSelectLabel = uilabel(obj.ScalingPanel);
obj.ScalingmethodSelectLabel.HorizontalAlignment = 'right';
obj.ScalingmethodSelectLabel.FontName = Aes.uiFontName;
obj.ScalingmethodSelectLabel.FontSize = 20;
obj.ScalingmethodSelectLabel.Position = [39 254 136 25];
obj.ScalingmethodSelectLabel.Text = 'Scaling method:';

% Create ScaleMethodSelect
obj.ScaleMethodSelect = uidropdown(obj.ScalingPanel);
obj.ScaleMethodSelect.Items = {'Absolute Max', 'Max', 'Min', 'Custom', 'Select'};
obj.ScaleMethodSelect.ValueChangedFcn = @obj.ScaleMethodChanged;
obj.ScaleMethodSelect.FontName = Aes.uiFontName;
obj.ScaleMethodSelect.FontSize = 20;
obj.ScaleMethodSelect.BackgroundColor = [1 1 1];
obj.ScaleMethodSelect.Position = [230 253 156 26];
obj.ScaleMethodSelect.Value = 'Absolute Max';

% Create ScaleValueLabel
obj.ScaleValueLabel = uilabel(obj.ScalingPanel);
obj.ScaleValueLabel.HorizontalAlignment = 'right';
obj.ScaleValueLabel.FontName = Aes.uiFontName;
obj.ScaleValueLabel.FontSize = 20;
obj.ScaleValueLabel.Position = [44 205 131 25];
obj.ScaleValueLabel.Text = 'Scaling value:';

% Create ScaleValue
obj.ScaleValue = uieditfield(obj.ScalingPanel, 'numeric');
obj.ScaleValue.RoundFractionalValues = 'on';
obj.ScaleValue.ValueChangedFcn = @(s,e)obj.Notify('ScalingChanged', eventData('ScaleValue'));
obj.ScaleValue.Editable = 'off';
obj.ScaleValue.FontName = 'Courier New';
obj.ScaleValue.FontSize = 16;
obj.ScaleValue.Enable = 'off';
obj.ScaleValue.Position = [230 208 156 22];
obj.ScaleValue.Value = 1;

% Create DisplayPanel
obj.DisplayPanel = uipanel(obj.container);
obj.DisplayPanel.AutoResizeChildren = 'off';
obj.DisplayPanel.Visible = 'off';
obj.DisplayPanel.BackgroundColor = [1 1 1];
obj.DisplayPanel.FontName = Aes.uiFontName;
obj.DisplayPanel.Position = [184 15 415 339];

% Create DisplayLabel
obj.DisplayLabel = uilabel(obj.DisplayPanel);
obj.DisplayLabel.FontName = Aes.uiFontName;
obj.DisplayLabel.FontSize = 16;
obj.DisplayLabel.Position = [19 304 55 22];
obj.DisplayLabel.Text = 'Display';

% Create LineDisplayStyleDropDownLabel
obj.LineDisplayStyleDropDownLabel = uilabel(obj.DisplayPanel);
obj.LineDisplayStyleDropDownLabel.FontName = Aes.uiFontName;
obj.LineDisplayStyleDropDownLabel.FontSize = 16;
obj.LineDisplayStyleDropDownLabel.Position = [22 262 130 22];
obj.LineDisplayStyleDropDownLabel.Text = 'Line Display Style:';

% Create LineStyle
obj.LineStyle = uidropdown(obj.DisplayPanel);
obj.LineStyle.Items = {'Solid', 'Dashed', 'Dotted', 'Dash-Dotted', 'None'};
obj.LineStyle.ValueChangedFcn = @(s,e)obj.Notify('DisplayChanged', eventData({'LineStyle',s.Value}));
obj.LineStyle.FontName = Aes.uiFontName;
obj.LineStyle.FontSize = 16;
obj.LineStyle.Position = [259 262 125 22];
obj.LineStyle.Value = 'Solid';

% Create MarkerDisplayStyleDropDownLabel
obj.MarkerDisplayStyleDropDownLabel = uilabel(obj.DisplayPanel);
obj.MarkerDisplayStyleDropDownLabel.FontName = Aes.uiFontName;
obj.MarkerDisplayStyleDropDownLabel.FontSize = 16;
obj.MarkerDisplayStyleDropDownLabel.Position = [22 168 148 22];
obj.MarkerDisplayStyleDropDownLabel.Text = 'Marker Display Style:';

% Create MarkerStyle
obj.MarkerStyle = uidropdown(obj.DisplayPanel);
obj.MarkerStyle.Items = { ...
  'None', 'Circle', 'Cross', 'Square', 'Diamond', 'Star', 'Triangle', 'Y' ...
  };
obj.MarkerStyle.ValueChangedFcn = @(s,e)obj.Notify('DisplayChanged', eventData({'MarkerStyle',s.Value}));
obj.MarkerStyle.FontName = Aes.uiFontName;
obj.MarkerStyle.FontSize = 16;
obj.MarkerStyle.Position = [259 168 125 22];
obj.MarkerStyle.Value = 'None';

% Create LineDisplayWidthLabel
obj.LineDisplayWidthLabel = uilabel(obj.DisplayPanel);
obj.LineDisplayWidthLabel.FontName = Aes.uiFontName;
obj.LineDisplayWidthLabel.FontSize = 16;
obj.LineDisplayWidthLabel.Position = [22 215 136 22];
obj.LineDisplayWidthLabel.Text = 'Line Display Width:';

% Create LineWidth
obj.LineWidth = uieditfield(obj.DisplayPanel, 'numeric');
obj.LineWidth.Limits = [0.5 5];
obj.LineWidth.ValueDisplayFormat = '%2.1f';
obj.LineWidth.ValueChangedFcn = @(s,e)obj.DisplayValueChanged(s,eventData({'LineWidth',s.Value}));
obj.LineWidth.FontName = 'Courier New';
obj.LineWidth.FontSize = 16;
obj.LineWidth.Position = [180 215 57 22];
obj.LineWidth.Value = 2;

% Create LineWidthSlider
obj.LineWidthSlider = uislider(obj.DisplayPanel);
obj.LineWidthSlider.Limits = [0.5 5];
obj.LineWidthSlider.MajorTicks = [0.5 2 3.5 5];
obj.LineWidthSlider.MajorTickLabels = {'0.5', '', '', '5'};
obj.LineWidthSlider.ValueChangedFcn = @(s,e)obj.DisplaySliderChanged(s,eventData(struct('Value',s.Value, 'Type', 'LineWidth')));
obj.LineWidthSlider.ValueChangingFcn = @(s,e)obj.DisplaySliderChanging(s,eventData(struct('Value',e.Value, 'Type', 'LineWidth')));
obj.LineWidthSlider.FontName = Aes.uiFontName;
obj.LineWidthSlider.Position = [259 237 125 3];
obj.LineWidthSlider.Value = 2;

% Create MarkerSizeSlider
obj.MarkerSizeSlider = uislider(obj.DisplayPanel);
obj.MarkerSizeSlider.Limits = [1 30];
obj.MarkerSizeSlider.MajorTickLabels = {'1', '', '', '', '', '', '30'};
obj.MarkerSizeSlider.ValueChangedFcn = @(s,e)obj.DisplaySliderChanged(s,eventData(struct('Value',s.Value, 'Type', 'MarkerSize')));
obj.MarkerSizeSlider.ValueChangingFcn = @(s,e)obj.DisplaySliderChanging(s,eventData(struct('Value',e.Value, 'Type', 'MarkerSize')));
obj.MarkerSizeSlider.FontName = Aes.uiFontName;
obj.MarkerSizeSlider.Position = [258 145 125 3];
obj.MarkerSizeSlider.Value = 8;

% Create MarkerSize
obj.MarkerSize = uieditfield(obj.DisplayPanel, 'numeric');
obj.MarkerSize.Limits = [1 30];
obj.MarkerSize.ValueDisplayFormat = '%2.1f';
obj.MarkerSize.ValueChangedFcn = @(s,e)obj.DisplayValueChanged(s,eventData({'MarkerSize',s.Value}));
obj.MarkerSize.FontName = 'Courier New';
obj.MarkerSize.FontSize = 16;
obj.MarkerSize.Position = [179 121 57 22];
obj.MarkerSize.Value = 8;

% Create MarkerDisplaySizeLabel
obj.MarkerDisplaySizeLabel = uilabel(obj.DisplayPanel);
obj.MarkerDisplaySizeLabel.FontName = Aes.uiFontName;
obj.MarkerDisplaySizeLabel.FontSize = 16;
obj.MarkerDisplaySizeLabel.Position = [22 121 142 22];
obj.MarkerDisplaySizeLabel.Text = 'Marker Display Size:';

% Create GridDropDownLabel
obj.GridDropDownLabel = uilabel(obj.DisplayPanel);
obj.GridDropDownLabel.FontName = Aes.uiFontName;
obj.GridDropDownLabel.FontSize = 16;
obj.GridDropDownLabel.Position = [23 27 39 22];
obj.GridDropDownLabel.Text = 'Grid:';

% Create Grid
obj.Grid = uidropdown(obj.DisplayPanel);
obj.Grid.Items = {'None', 'X Axis', 'Y Axis', 'Both'};
obj.Grid.ValueChangedFcn = @(s,e)obj.Notify('DisplayChanged', eventData({'Grid', s.Value}));
obj.Grid.FontName = Aes.uiFontName;
obj.Grid.FontSize = 16;
obj.Grid.Position = [81 27 110 22];
obj.Grid.Value = 'None';

% Create XAxisDropDownLabel
obj.XAxisDropDownLabel = uilabel(obj.DisplayPanel);
obj.XAxisDropDownLabel.FontName = Aes.uiFontName;
obj.XAxisDropDownLabel.FontSize = 16;
obj.XAxisDropDownLabel.Position = [22 74 56 22];
obj.XAxisDropDownLabel.Text = 'X Axis:';

% Create AxesScaleX
obj.AxesScaleX = uidropdown(obj.DisplayPanel);
obj.AxesScaleX.Items = {'Linear', 'Logarithmic'};
obj.AxesScaleX.ValueChangedFcn = @(s,e)obj.Notify('DisplayChanged', eventData({'AxesScaleX',s.Value}));
obj.AxesScaleX.FontName = Aes.uiFontName;
obj.AxesScaleX.FontSize = 16;
obj.AxesScaleX.Position = [81 74 110 22];
obj.AxesScaleX.Value = 'Linear';

% Create YAxisDropDownLabel
obj.YAxisDropDownLabel = uilabel(obj.DisplayPanel);
obj.YAxisDropDownLabel.FontName = Aes.uiFontName;
obj.YAxisDropDownLabel.FontSize = 16;
obj.YAxisDropDownLabel.Position = [215 74 51 22];
obj.YAxisDropDownLabel.Text = 'Y Axis';

% Create AxesScaleY
obj.AxesScaleY = uidropdown(obj.DisplayPanel);
obj.AxesScaleY.Items = {'Linear', 'Logarithmic'};
obj.AxesScaleY.ValueChangedFcn = @(s,e)obj.Notify('DisplayChanged', eventData({'AxesScaleY',s.Value}));
obj.AxesScaleY.FontName = Aes.uiFontName;
obj.AxesScaleY.FontSize = 16;
obj.AxesScaleY.Position = [274 74 110 22];
obj.AxesScaleY.Value = 'Linear';

% Create ResetPreferences
obj.ResetPreferences = uibutton(obj.container, 'push');
obj.ResetPreferences.FontName = Aes.uiFontName;
obj.ResetPreferences.FontSize = 14;
obj.ResetPreferences.Position = [51 15 87 22];
obj.ResetPreferences.Text = 'Defaults';
obj.ResetPreferences.ButtonPushedFcn = @(s,e)obj.resetContainerPrefs;

obj.update;
end