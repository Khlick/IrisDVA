function createUI(obj)

%createUI Creates the primary window view
%% Initialize
import iris.ui.*;
import iris.app.*;
import iris.infra.*;

w = 380;
h = 390;

pos = obj.position;
if isempty(pos)
  pos = centerFigPos(w,h);
end
%force startup to max height
pos(4) = h;

obj.position = pos;

set(obj.container,...
  'Name', 'Create New Analysis',...
  'Units', 'pixels',...
  'resize', 'off' ...
  );

% Create nameLabel
obj.nameLabel = uilabel(obj.container);
obj.nameLabel.VerticalAlignment = 'bottom';
obj.nameLabel.FontName = 'Times New Roman';
obj.nameLabel.FontSize = 14;
obj.nameLabel.FontWeight = 'bold';
obj.nameLabel.Position = [15 360 350 25];
obj.nameLabel.Text = 'Enter a name for the analysis function:';

% Create analysisName
obj.analysisName = uieditfield(obj.container, 'text');
obj.analysisName.ValueChangedFcn = @obj.validateFxName;
obj.analysisName.FontName = 'Courier New';
obj.analysisName.FontSize = 16;
obj.analysisName.Position = [15 320 350 30];
obj.analysisName.Value = 'irisAnalysis';

% Create createButton
obj.createButton = uibutton(obj.container, 'push');
obj.createButton.BackgroundColor = [0.9412 0.949 0.9412];
obj.createButton.FontName = 'Times New Roman';
obj.createButton.FontSize = 14;
obj.createButton.Position = [75 266 100 24];
obj.createButton.Text = 'Create';
obj.createButton.ButtonPushedFcn = @obj.createNewFunction;

% Create cancelButton
obj.cancelButton = uibutton(obj.container, 'push');
obj.cancelButton.BackgroundColor = [0.9882 0.8902 0.8706];
obj.cancelButton.FontName = 'Times New Roman';
obj.cancelButton.FontSize = 14;
obj.cancelButton.Position = [195 266 100 24];
obj.cancelButton.Text = 'Cancel';
obj.cancelButton.ButtonPushedFcn = @(s,e)obj.onCloseRequest;

% Create argPanel
obj.argPanel = uipanel(obj.container);
obj.argPanel.AutoResizeChildren = 'off';
obj.argPanel.BackgroundColor = [1 1 1];
obj.argPanel.FontName = 'Times New Roman';
obj.argPanel.Position = [10 5 360 250];

% Create inputArgs
obj.inputArgs = uitable(obj.argPanel);
obj.inputArgs.ColumnName = {'Name'; 'Default Value'};
obj.inputArgs.RowName = {};
obj.inputArgs.ColumnEditable = true;
obj.inputArgs.CellEditCallback = @obj.validateInput;
obj.inputArgs.FontName = 'Times New Roman';
obj.inputArgs.Position = [125 10 230 206];

% Create outputArgs
obj.outputArgs = uitable(obj.argPanel);
obj.outputArgs.ColumnName = {'Name'};
obj.outputArgs.RowName = {};
obj.outputArgs.ColumnEditable = true;
obj.outputArgs.CellEditCallback = @obj.validateArgName;
obj.outputArgs.FontName = 'Times New Roman';
obj.outputArgs.Position = [5 10 110 206];

% Create outputsLabel
obj.outputsLabel = uilabel(obj.argPanel);
obj.outputsLabel.HorizontalAlignment = 'center';
obj.outputsLabel.FontName = 'Times New Roman';
obj.outputsLabel.FontSize = 14;
obj.outputsLabel.FontWeight = 'bold';
obj.outputsLabel.Position = [33 215 55 22];
obj.outputsLabel.Text = 'Outputs';

% Create InputArgumentsLabel
obj.InputArgumentsLabel = uilabel(obj.argPanel);
obj.InputArgumentsLabel.HorizontalAlignment = 'center';
obj.InputArgumentsLabel.FontName = 'Times New Roman';
obj.InputArgumentsLabel.FontSize = 14;
obj.InputArgumentsLabel.FontWeight = 'bold';
obj.InputArgumentsLabel.Position = [186 215 109 22];
obj.InputArgumentsLabel.Text = 'Input Arguments';

% Create addOutput
obj.addOutput = uibutton(obj.argPanel, 'push');
obj.addOutput.ButtonPushedFcn = @obj.addArg;
obj.addOutput.BackgroundColor = [1 1 1];
obj.addOutput.FontName = 'Times New Roman';
obj.addOutput.FontSize = 8;
obj.addOutput.FontWeight = 'bold';
obj.addOutput.Position = [5 219 15 15];
obj.addOutput.Text = '+';
obj.addOutput.Tag = 'out';

% Create addInput
obj.addInput = uibutton(obj.argPanel, 'push');
obj.addInput.ButtonPushedFcn = @obj.addArg;
obj.addInput.BackgroundColor = [1 1 1];
obj.addInput.FontName = 'Times New Roman';
obj.addInput.FontSize = 8;
obj.addInput.FontWeight = 'bold';
obj.addInput.Position = [125 219 15 15];
obj.addInput.Text = '+';
obj.addInput.Tag = 'in';

% Create showArgs
obj.showArgs = uibutton(obj.container, 'state');
obj.showArgs.ValueChangedFcn = @obj.toggleArgs;
obj.showArgs.Text = '+';
obj.showArgs.BackgroundColor = [1 1 1];
obj.showArgs.FontName = 'Times New Roman';
obj.showArgs.FontSize = 8;
obj.showArgs.FontWeight = 'bold';
obj.showArgs.Position = [10 266 15 15];


end

