function fig = createIrisFigure(name,width,height,visible,figureParams)
%CREATEIRISFIGURE Creates a figure with iris theming

arguments
  name string = "Figure"
  width (1,1) double {mustBeNonnegative} = 1000
  height (1,1) double {mustBeNonnegative} = 650
  visible matlab.lang.OnOffSwitchState = 'off'
  figureParams.?matlab.ui.Figure
end

import utilities.centerFigPos;

% defaults
params = { ...
  'Visible', visible; ...
  'NumberTitle', 'off'; ...
  'Color', [1,1,1]; ...
  'Units','pixels';...
  'DefaultUicontrolFontName', 'Times New Roman'; ...
  'DefaultAxesColor', [1,1,1]; ...
  'DefaultAxesFontName', 'Times New Roman'; ...
  'DefaultTextFontName', 'Times New Roman'; ...
  'DefaultAxesFontSize', 16; ...
  'DefaultTextFontSize', 18; ...
  'DefaultUipanelUnits', 'pixels'; ...
  'DefaultUipanelBordertype', 'line'; ...
  'DefaultUipanelFontname', 'Times New Roman';...
  'DefaultUipanelFontunits', 'pixels'; ...
  'DefaultUipanelFontsize', 12;...
  'DefaultUipanelAutoresizechildren', 'off'; ...
  'DefaultUitabgroupUnits', 'pixels'; ...
  'DefaultUitabgroupAutoresizechildren', 'off'; ...
  'DefaultUitabUnits', 'pixels'; ...
  'DefaultUitabAutoresizechildren', 'off'; ...
  'DefaultUibuttongroupUnits', 'pixels'; ...
  'DefaultUibuttongroupBordertype', 'line'; ...
  'DefaultUibuttongroupFontname', 'Times New Roman';...
  'DefaultUibuttongroupFontunits', 'pixels'; ...
  'DefaultUibuttongroupFontsize', 12;...
  'DefaultUibuttongroupAutoresizechildren', 'off'; ...
  'DefaultUitableFontname', 'Times New Roman'; ...
  'DefaultUitableFontunits', 'pixels';...
  'DefaultUitableFontsize', 12 ...
  };

params(:,1) = lower(params(:,1));
params = cell2struct(params(:,2),params(:,1));

fn = fieldnames(figureParams);
for f = string(fn(:)')
  params.(lower(f)) = figureParams.(f);
end

params.name = name;
params.position = centerFigPos(width,height);


fig = handle(figure(params));

end

