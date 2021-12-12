function createUI(obj)

  % init
  import iris.app.Aes;
  %{
  obj = struct();
  obj.WIDTH = 950;
  obj.HEIGHT = 400;
  obj.container = utilities.createIrisUiFigure("Analysis",obj.WIDTH,obj.HEIGHT,true,'resize','on');
  obj.options = struct('AppendAnalysis', false,'SendToCommandWindow',false);
  %}
  greys = Aes.appColor(2,'greys','matrix');

  set(obj.container, ...
    'resize','on', ...
    'position',utilities.centerFigPos(obj.WIDTH,obj.HEIGHT) ...
    );
  obj.container.Name = 'Analysis Export';

  %%% MENU
  obj.optionsMenu = uimenu(obj.container,"Text","Options");
  
  obj.appendOption = uimenu(obj.optionsMenu,"Text","Append");
  obj.appendOption.Tooltip = Aes.strLib('analyze:checkboxAppend');

  obj.appendYes = uimenu(obj.appendOption,"Text","Yes");
  obj.appendYes.Tag = "yes";
  obj.appendNo = uimenu(obj.appendOption,"Text","No");
  obj.appendNo.Tag = "no";
  obj.appendAsk = uimenu(obj.appendOption,"Text","Ask");
  obj.appendAsk.Tooltip = Aes.strLib('analyze:appendAsk');
  obj.appendAsk.Tag = "ask";
  
  obj.sendToCommandOption = uimenu(obj.optionsMenu,"Text","Send To Workspace");
  obj.sendToCommandOption.Accelerator = "S";
  obj.sendToCommandOption.Tooltip = Aes.strLib('analyze:checkboxSendToCmd');
  
  obj.backtrackDataIndicesOption = uimenu(obj.optionsMenu,"Text","Backtrack Indices");
  obj.backtrackDataIndicesOption.Accelerator = "B";
  obj.backtrackDataIndicesOption.Tooltip = Aes.strLib('analyze:backtrackDataIndices');

  obj.createAnalysisOption = uimenu(obj.optionsMenu,"Text","Create New Analysis");
  obj.createAnalysisOption.Accelerator = "N";
  obj.createAnalysisOption.Separator = 'on';
  obj.createAnalysisOption.Tooltip = Aes.strLib('analyze:createAnalysis');
  
  obj.resetDefaultsOption = uimenu(obj.optionsMenu,"Text","Reset Preferences");
  obj.resetDefaultsOption.Separator = 'on';
  obj.resetDefaultsOption.Tooltip = Aes.strLib('analyze:resetDefaults');

  %%% Main UI
  % Create containerGrid
  obj.containerGrid = uigridlayout(obj.container);
  obj.containerGrid.ColumnWidth = {'1x',20,obj.BATCH_OFFSET};
  obj.containerGrid.RowHeight = {36, 'fit', '1x', 36};
  obj.containerGrid.ColumnSpacing = 0;
  obj.containerGrid.RowSpacing = 5;
  obj.containerGrid.Padding = [10 10 10 5];
  obj.containerGrid.BackgroundColor = [1,1,1,0];
  
  %%% Analysis selection controls
  % Create input panel
  obj.inputPanel = uipanel(obj.containerGrid);
  obj.inputPanel.Layout.Row = [1,2];
  obj.inputPanel.Layout.Column = 1;
  obj.inputPanel.BorderType = 'line';

  % input panel grid
  obj.inputGrid = uigridlayout(obj.inputPanel);
  obj.inputGrid.Padding = [10 3 10 3];
  obj.inputGrid.BackgroundColor = [1,1,1,0];
  obj.inputGrid.ColumnWidth = {'fit','1x',50,50,50};
  obj.inputGrid.RowHeight = {'1x',obj.FUNCTION_CALL_MAX_HEIGHT};
  obj.inputGrid.RowSpacing = 3;

  % Select analysis label
  obj.selectLabel = uilabel(obj.inputGrid,"Text","Analysis:");
  obj.selectLabel.Layout.Row = 1;
  obj.selectLabel.Layout.Column = 1;
  obj.selectLabel.FontName = Aes.uiFontName;
  obj.selectLabel.FontSize = Aes.uiFontSize('label');
  obj.selectLabel.HorizontalAlignment = 'right';

  % Analysis dropdown
  obj.selectDropdown = uidropdown(obj.inputGrid);
  obj.selectDropdown.FontName = Aes.uiFontName('mono');
  obj.selectDropdown.FontSize = Aes.uiFontSize();
  obj.selectDropdown.Tooltip = Aes.strLib('analyze:selectAnalysis');
  obj.selectDropdown.Items = obj.getAvailableAnalyses();
  obj.selectDropdown.Value = obj.selectDropdown.Items{1};

  % Edit Current Analysis button
  obj.editAnalysisButton = uibutton(obj.inputGrid);
  obj.editAnalysisButton.Layout.Row = 1;
  obj.editAnalysisButton.Layout.Column = 3;
  obj.editAnalysisButton.FontName = Aes.uiFontName();
  obj.editAnalysisButton.FontSize = Aes.uiFontSize();
  obj.editAnalysisButton.Text = "Edit";
  obj.editAnalysisButton.Tooltip = Aes.strLib('analyze:editAnalysisTooltip');
  obj.editAnalysisButton.Enable = 'off';

  % Refresh analyses list button
  obj.refreshAnalysisButton = uibutton(obj.inputGrid);
  obj.refreshAnalysisButton.Layout.Row = 1;
  obj.refreshAnalysisButton.Layout.Column = 4;
  obj.refreshAnalysisButton.FontName = Aes.uiFontName();
  obj.refreshAnalysisButton.FontSize = Aes.uiFontSize();
  obj.refreshAnalysisButton.Text = "Refresh";
  obj.refreshAnalysisButton.Tooltip = Aes.strLib('analyze:refreshAnalysisTooltip');
  obj.refreshAnalysisButton.Enable = 'on';

  % Update Analysis Defaults
  obj.updateDefaultsButton = uibutton(obj.inputGrid);
  obj.updateDefaultsButton.Layout.Row = 1;
  obj.updateDefaultsButton.Layout.Column = 5;
  obj.updateDefaultsButton.Text = "Set";
  obj.updateDefaultsButton.FontName = Aes.uiFontName();
  obj.updateDefaultsButton.FontSize = Aes.uiFontSize();
  obj.updateDefaultsButton.Tooltip = Aes.strLib('analyze:updateAnalysisTooltip');
  obj.updateDefaultsButton.Enable = 'off';
  
  % Function call string
  flayout = matlab.ui.layout.GridLayoutOptions();
  flayout.Row = 2;
  flayout.Column = [1,5];
  obj.functionCallLabel = iris.ui.elements.collapsibleTextbox( ...
    obj.inputGrid, ...
    'Label', 'Function Signature', ...
    'Text', 'Select', ...
    'Monospaced', true, ...
    'Layout', flayout, ...
    'TextColor', [0,0,0], ...
    'TextBackgroundColor', [1,1,1,0], ...
    'LabelColor', [1,1,1], ...
    'LabelBackgroundColor', greys(1,:), ...
    'FontSize', Aes.uiFontSize('shrink')-3 ...
    );
  obj.functionCallLabel.adjustMaxHeight(80);

  %%% Batch Processing controls
  % batch grid for shrinking button
  obj.batchButtonGrid = uigridlayout(obj.containerGrid);
  obj.batchButtonGrid.Layout.Row = 1;
  obj.batchButtonGrid.Layout.Column = 2;
  obj.batchButtonGrid.RowHeight = {'1x'};
  obj.batchButtonGrid.ColumnWidth = {'1x'};
  obj.batchButtonGrid.Padding = [1,abs(19-36),0,0];
  obj.batchButtonGrid.BackgroundColor = [1,1,1,0];
  obj.batchButtonGrid.ColumnSpacing = 0;
  obj.batchButtonGrid.RowSpacing = 0;

  % Batch expand button
  obj.batchVisibilityButton = uibutton(obj.batchButtonGrid,"state");
  obj.batchVisibilityButton.Layout.Row = 1;
  obj.batchVisibilityButton.Layout.Column = 1;
  obj.batchVisibilityButton.FontSize = Aes.uiFontSize('shrink');
  obj.batchVisibilityButton.FontName = Aes.uiFontName('mono');
  obj.batchVisibilityButton.Text = '+';
  obj.batchVisibilityButton.Value = false;
  obj.batchVisibilityButton.Tooltip = Aes.strLib('analyze:toggleBatchTooltip');

  % batch panel
  obj.batchPanel = uipanel(obj.containerGrid);
  obj.batchPanel.Layout.Row = [1,4];
  obj.batchPanel.Layout.Column = 3;
  
  %%% Function Settings
  % middle panel for layout
  obj.functionPanel = uipanel(obj.containerGrid);
  obj.functionPanel.Layout.Row = 3;
  obj.functionPanel.Layout.Column = [1,2];
  obj.functionPanel.BorderType = 'none';
  
  % Function layout grid
  obj.functionGrid = uigridlayout(obj.functionPanel);
  obj.functionGrid.RowHeight = {36,'1x'};
  obj.functionGrid.ColumnWidth = {'1x'};
  obj.functionGrid.Padding = [0,0,0,0];
  obj.functionGrid.ColumnSpacing = 0;
  obj.functionGrid.RowSpacing = 0;
  obj.functionGrid.BackgroundColor = [1,1,1,0];
  
  %%%% Data Input
  obj.dataPanel = uipanel(obj.functionGrid);
  obj.dataPanel.Layout.Row = 1;
  obj.dataPanel.Layout.Column = 1;
  
  % data Input Grid
  obj.dataGrid = uigridlayout(obj.dataPanel);
  obj.dataGrid.ColumnWidth = {'fit','1x'};
  obj.dataGrid.RowHeight = {'1x'};
  obj.dataGrid.ColumnSpacing = 5;
  obj.dataGrid.RowSpacing = 0;
  obj.dataGrid.Padding = [10 3 10 3];
  obj.dataGrid.BackgroundColor = [1,1,1,0];

  % data input lable
  obj.dataLabel = uilabel(obj.dataGrid,"Text","Data:");
  obj.dataLabel.Layout.Row = 1;
  obj.dataLabel.Layout.Column = 1;
  obj.dataLabel.FontName = Aes.uiFontName;
  obj.dataLabel.FontSize = Aes.uiFontSize('label');
  obj.dataLabel.HorizontalAlignment = 'right';
  
  % data input edit
  obj.dataInput = uieditfield(obj.dataGrid,"Editable","on");
  obj.dataInput.Layout.Row = 1;
  obj.dataInput.Layout.Column = 2;
  obj.dataInput.FontName = Aes.uiFontName('mono');
  obj.dataInput.FontSize = Aes.uiFontSize();
  obj.dataInput.HorizontalAlignment = 'center';
  obj.dataInput.Enable = 'off';

  %%%% Argument Parsing
  obj.argumentsPanel = uipanel(obj.functionGrid);
  obj.argumentsPanel.Layout.Row = 2;
  obj.argumentsPanel.Layout.Column = 1;
  obj.argumentsPanel.BorderType = 'none';

  % Arguments Grid
  obj.argumentsGrid = uigridlayout(obj.argumentsPanel);
  obj.argumentsGrid.RowHeight = {50,'1x'};
  obj.argumentsGrid.ColumnWidth = {'1x',20,'1x'};
  obj.argumentsGrid.Padding = [0 0 0 0];
  obj.argumentsGrid.ColumnSpacing = 2;
  obj.argumentsGrid.RowSpacing = 5;
  obj.argumentsGrid.BackgroundColor = [1,1,1,0];

  % output label
  obj.argumentsOutLabel = uilabel(obj.argumentsGrid,"Text","Output Arguments");
  obj.argumentsOutLabel.Layout.Row = 1;
  obj.argumentsOutLabel.Layout.Column = 1;
  obj.argumentsOutLabel.FontName = Aes.uiFontName;
  obj.argumentsOutLabel.FontWeight = 'bold';
  obj.argumentsOutLabel.FontSize = Aes.uiFontSize('label');
  obj.argumentsOutLabel.HorizontalAlignment = 'center';

  % argument toggles grid
  obj.argumentsToggleGrid = uigridlayout(obj.argumentsGrid);
  obj.argumentsToggleGrid.Layout.Row = 1;
  obj.argumentsToggleGrid.Layout.Column = 2;
  obj.argumentsToggleGrid.ColumnWidth = {'1x'};
  obj.argumentsToggleGrid.RowHeight = {'1x','1x'};
  obj.argumentsToggleGrid.RowSpacing = 1;
  obj.argumentsToggleGrid.BackgroundColor = [1,1,1];
  obj.argumentsToggleGrid.Padding = [0 5 0 5];
  
  % output arguments toggle
  obj.argumentsToggleOut = uibutton(obj.argumentsToggleGrid,"state");
  obj.argumentsToggleOut.Layout.Row = 1;
  obj.argumentsToggleOut.Layout.Column = 1;
  obj.argumentsToggleOut.Text = "<";
  obj.argumentsToggleOut.VerticalAlignment = 'top';
  obj.argumentsToggleOut.FontName = Aes.uiFontName('mono');
  obj.argumentsToggleOut.FontSize = Aes.uiFontSize('shrink');
  obj.argumentsToggleOut.Value = 1;
  obj.argumentsToggleOut.Tooltip = Aes.strLib('analyze:toggleOutputArguments');

  % input arguments toggle
  obj.argumentsToggleIn = uibutton(obj.argumentsToggleGrid,"state");
  obj.argumentsToggleIn.Layout.Row = 2;
  obj.argumentsToggleIn.Layout.Column = 1;
  obj.argumentsToggleIn.Text = ">";
  obj.argumentsToggleIn.VerticalAlignment = 'top';
  obj.argumentsToggleIn.FontName = Aes.uiFontName('mono');
  obj.argumentsToggleIn.FontSize = Aes.uiFontSize('shrink');
  obj.argumentsToggleIn.Value = 1;
  obj.argumentsToggleIn.Tooltip = Aes.strLib('analyze:toggleInputArguments');

  % input label
  obj.argumentsInLabel = uilabel(obj.argumentsGrid,"Text","Input Arguments");
  obj.argumentsInLabel.Layout.Row = 1;
  obj.argumentsInLabel.Layout.Column = 3;
  obj.argumentsInLabel.FontName = Aes.uiFontName;
  obj.argumentsInLabel.FontWeight = 'bold';
  obj.argumentsInLabel.FontSize = Aes.uiFontSize('label');
  obj.argumentsInLabel.HorizontalAlignment = 'center';

  % Output Arguments Table
  nameStyle = uistyle("HorizontalAlignment","right");
  inputStyle = uistyle("HorizontalAlignment","center","FontName",Aes.uiFontName('mono'));

  obj.argumentsOutTable = uitable(obj.argumentsGrid);
  obj.argumentsOutTable.Layout.Row = 2;
  obj.argumentsOutTable.Layout.Column = 1;
  obj.argumentsOutTable.FontName = Aes.uiFontName();
  obj.argumentsOutTable.FontSize = Aes.uiFontSize();
  obj.argumentsOutTable.ColumnName = {'Argument', 'Desired Name'};
  obj.argumentsOutTable.ColumnFormat = {'char','char'};
  obj.argumentsOutTable.ColumnEditable = [false,true];
  obj.argumentsOutTable.RowName = [];
  obj.argumentsOutTable.ColumnWidth = {'fit','1x'};
  obj.argumentsOutTable.addStyle(nameStyle,"column",1);
  obj.argumentsOutTable.addStyle(inputStyle,"column",2);

  % Input Arguments Table
  obj.argumentsInTable = uitable(obj.argumentsGrid);
  obj.argumentsInTable.Layout.Row = 2;
  obj.argumentsInTable.Layout.Column = 3;
  obj.argumentsInTable.FontName = Aes.uiFontName();
  obj.argumentsInTable.FontSize = Aes.uiFontSize();
  obj.argumentsInTable.ColumnName = {'Argument', 'Value'};
  obj.argumentsInTable.ColumnFormat = {'char','char'};
  obj.argumentsInTable.ColumnEditable = [false,true];
  obj.argumentsInTable.RowName = [];
  obj.argumentsInTable.ColumnWidth = {'fit','1x'};
  obj.argumentsInTable.addStyle(nameStyle,"column",1);
  obj.argumentsInTable.addStyle(inputStyle,"column",2);
  
  %{
  %%% TEST DATA
  obj.argumentsOutTable.Data = {'TestArg','SomeName';'testarg2','another name'};
  obj.argumentsInTable.Data = [
    sprintfc('Input%d',(1:10)'), ...
    sprintfc('Argument%d',(1:10)') ...
    ];
  %}

  %%% Output Control
  % Create output panel
  obj.outputPanel = uipanel(obj.containerGrid);
  obj.outputPanel.Layout.Row = 4;
  obj.outputPanel.Layout.Column = [1,2];
  obj.outputPanel.BorderType = 'none';

  % input panel grid
  obj.outputGrid = uigridlayout(obj.outputPanel);
  obj.outputGrid.Padding = [10 3 10 3];
  obj.outputGrid.BackgroundColor = [1,1,1,0];
  obj.outputGrid.ColumnWidth = {'1x',30,60};
  obj.outputGrid.RowHeight = {'1x'};

  % output file name
  obj.outputFile = uieditfield(obj.outputGrid,"Editable","on","Enable","off");
  obj.outputFile.Layout.Row = 1;
  obj.outputFile.Layout.Column = 1;
  obj.outputFile.FontName = Aes.uiFontName('mono');
  obj.outputFile.FontSize = Aes.uiFontSize();
  obj.outputFile.HorizontalAlignment = 'center';
  obj.outputFile.Value = "FileName";

  % output location selection
  obj.outputLocation = uibutton(obj.outputGrid,"Text",'');
  obj.outputLocation.Icon = fullfile( ...
    iris.app.Info.getResourcePath(), ...
    "icn", ...
    "icons8-folder-128.png" ...
    );
  obj.outputLocation.IconAlignment = 'center';
  obj.outputLocation.Layout.Row = 1;
  obj.outputLocation.Layout.Column = 2;
  obj.outputLocation.Enable = 'off';
  obj.outputLocation.Tooltip = Aes.strLib('analyze:selectDirectory');

  obj.outputAnalyzeButton = uibutton(obj.outputGrid,"Text","Analyze");
  obj.outputAnalyzeButton.Layout.Row = 1;
  obj.outputAnalyzeButton.Layout.Column = 3;
  obj.outputAnalyzeButton.FontName = Aes.uiFontName();
  obj.outputAnalyzeButton.FontSize = Aes.uiFontSize();
  obj.outputAnalyzeButton.FontWeight = 'bold';
  obj.outputAnalyzeButton.Enable = 'off';
  obj.outputAnalyzeButton.Tooltip = Aes.strLib('analyze:performAnalysis');
  
end

