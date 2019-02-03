function createUI(obj)
%createUI Creates the primary window view
%% Initialize
import iris.ui.*;
import iris.app.*;
import iris.infra.*;

obj.startUp;

w = 550;
h = 400;

set(obj.container,...
  'Name', 'Analysis Export',...
  'Units', 'pixels',...
  'resize', 'on', ...
  'position', centerFigPos(w,h));

obj.labelTitle = uicontrol(obj.container,...
  'style', 'text', 'backgroundcolor', [1,1,1],...
  'units', 'pixels');
obj.labelTitle.Position = [10,h-30,110,25];
obj.labelTitle.String = 'Select Analysis:';
obj.labelTitle.FontSize = 12;
obj.labelTitle.HorizontalAlignment = 'left';

obj.selectAnalysis = uicontrol(obj.container,...
  'style', 'popupmenu', 'backgroundcolor', [1,1,1],...
  'units', 'pixels', 'String', obj.availableAnalyses);
obj.selectAnalysis.Position = [115,h-29,140,25];
obj.selectAnalysis.FontSize = 9;
obj.selectAnalysis.Callback = @(s,e) ...
  obj.setFxn(iris.infra.eventData(s.String{s.Value}));

obj.epochInput = uicontrol(obj.container, ...
  'style', 'edit', ...
  'fontname', 'Courier New', ...
  'String', 'Enter Epochs', ...
  'units', 'pixels' ...
  );
obj.epochInput.Position = [w-270, h-25, w-20-270, 20];
obj.epochInput.Callback = @(s,e)obj.setEpochs(s.String);

obj.labelFunction = uicontrol(obj.container,...
  'style', 'text', 'backgroundcolor', ones(1,3).*0.9601,...
  'units', 'pixels');
obj.labelFunction.Position = [10,h-57,w-20,16];obj.labelFunction.String = 'Function Call';
obj.labelFunction.FontSize = 9;
obj.labelFunction.FontName = 'Courier New';
obj.labelFunction.HorizontalAlignment = 'center';


obj.labelNargout = uicontrol(obj.container,...
  'style', 'text', 'backgroundColor', [1,1,1],...
  'units', 'pixels');
obj.labelNargout.Position = [0, h-100, fix(w/2), 30];
obj.labelNargout.String = 'Output Arguments';
obj.labelNargout.FontSize = 16;


obj.labelNargin = uicontrol(obj.container,...
  'style', 'text', 'backgroundColor', [1,1,1],...
  'units', 'pixels');
obj.labelNargin.Position = [fix(w/2)+1, h-100, fix(w/2), 30];
obj.labelNargin.String = 'Input Arguments';
obj.labelNargin.FontSize = 16;


obj.panelOutput = uipanel(obj.container, ...
  'highlightcolor', ones(1,3).*0.9804,...
  'backgroundcolor', [1 1 1],...
  'units', 'pixels', ...
  'tag', 'Output');
obj.panelOutput.Position = [10,60,fix(w/2)-20,h-170];
obj.panelOutput.BorderType = 'none';
obj.panelOutput.Clipping = 'off';


obj.tableOutput = uitable(obj.panelOutput, ...
  'units', 'normalized', ...
  'position', [0,0,1,1], ...
  'backgroundcolor', [1,1,1],...
  'rowname', {}, ...
  'columnname', {'Argument', '<html><center>Desired<br />Name</center>'}, ...
  'columnformat', {'char', 'char'},...
  'columneditable', [false,true], ...
  'columnwidth', num2cell(obj.panelOutput.Position([3,3])./2 + [-11,10]), ...
  'rowstriping', 'off', ...
  'data', cell(1,2), ...
  'celleditcallback', @obj.validateTableEntry);
obj.tableOutput.Tag = 'Output';
% get the ratio of cell widths for resize function
obj.panelOutput.UserData = obj.tableOutput.ColumnWidth{1};
obj.panelOutput.SizeChangedFcn = @obj.tableChangeSize;

obj.panelInput = uipanel(obj.container, ...
  'highlightcolor', ones(1,3).*0.9804,...
  'backgroundcolor', [1 1 1],...
  'units', 'pixels', ...
  'tag', 'Input');
obj.panelInput.Position = [fix(w/2)+11,60,fix(w/2)-20,h-170];
obj.panelInput.BorderType = 'none';
obj.panelInput.Clipping = 'off';


obj.tableInput = uitable(obj.panelInput, ...
  'units', 'normalized', ...
  'position', [0,0,1,1], ...
  'backgroundcolor', [1,1,1],...
  'rowname', {}, ...
  'columnname', ...
    {'Argument', ...
    ['<html><center>Input Value<br /><font', ...
     ' style="font-size:9pt">(MATLAB Expression)</font></center>']}, ...
  'columnformat', {'char', 'char'},...
  'columneditable', [false,true], ...
  'columnwidth', num2cell(obj.panelOutput.Position([3,3])./2 + [-11,10]), ...
  'rowstriping', 'off', ...
  'data', cell(1,2), ...
  'celleditcallback', @obj.validateTableEntry);
obj.tableInput.Tag = 'Input';
% get the ratio of cell widths for resize function
obj.panelInput.UserData = obj.tableInput.ColumnWidth{1};
obj.panelInput.SizeChangedFcn = @obj.tableChangeSize;


obj.editFileOutput = uicontrol(obj.container,...
  'style', 'edit',...
  'fontname', 'Courier New',...
  'String', 'FileName',...
  'units', 'pixels');
obj.editFileOutput.Position = [20,20,220,20];
obj.editFileOutput.Callback = @obj.validateFilename;

%collect the position of the edit field and shift by 10 pixels
pstrt = sum(obj.editFileOutput.Position([1,3]))+10;

obj.checkboxSendToCmd = uicontrol(obj.container,...
  'style', 'checkbox', ...
  'units', 'pixels', ...
  'value', 1, ...
  'backgroundcolor', [1,1,1]);
obj.checkboxSendToCmd.Position = [...
  pstrt, 30, w-160-pstrt, 20];
obj.checkboxSendToCmd.String = ...
  ['<html><font ', ...
  'style="font-size:7px;generic-family:serif;">', ...
  'Send copy to Command.</font>'];

obj.checkboxAppend= uicontrol(obj.container,...
  'style', 'checkbox', ...
  'units', 'pixels', ...
  'value', 1, ...
  'backgroundcolor', [1,1,1]);
obj.checkboxAppend.Position = [...
  pstrt, 10, w-160-pstrt, 20];
obj.checkboxAppend.String = ...
  ['<html><font ', ...
  'style="font-size:7px;generic-family:serif;">', ...
  'Append to existing.</font>'];

obj.buttonGo = uicontrol(obj.container,...
  'style', 'pushbutton', 'string', 'Go',...
  'backgroundColor', ones(1,3).*0.9804,...
  'units', 'pixels');
obj.buttonGo.Position = [w-150,20,60,20];
obj.buttonGo.Callback = @obj.executeFunction;


obj.buttonClose = uicontrol(obj.container,...
  'style', 'pushbutton', 'string', 'Close', ...
  'backgroundColor', ones(1,3).*0.9804,...
  'units', 'pixels');
obj.buttonClose.Position = [w-80,20,60,20];
obj.buttonClose.Callback = @(s,e)notify(obj,'Close');



%tables made, now normalize the panels so the figure can be resized.
obj.buttonClose.Units = 'normalized';
obj.labelTitle.Units = 'normalized';
obj.panelOutput.Units = 'normalized';
obj.buttonGo.Units = 'normalized';
obj.checkboxSendToCmd.Units = 'normalized';
obj.editFileOutput.Units = 'normalized';
obj.tableInput.Units = 'normalized';
obj.panelInput.Units = 'normalized';
obj.labelNargin.Units = 'normalized';
obj.labelNargout.Units = 'normalized';
obj.labelFunction.Units = 'normalized';
obj.checkboxAppend.Units = 'normalized';
obj.selectAnalysis.Units = 'normalized';
obj.epochInput.Units = 'normalized';
%% Now change the size
pos = obj.position;
if isempty(pos)
  pos = centerFigPos(w,h);
end
obj.position = pos; %sets container too
end