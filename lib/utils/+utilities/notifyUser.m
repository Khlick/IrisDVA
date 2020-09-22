function h = notifyUser(message,title,sizeParams,figParams)
%NOTIFYUSER Display a message, returns uifigure handle
arguments
  message string
  title (1,1) string = "Notification"
  sizeParams.width (1,1) double = 460
  sizeParams.height (1,1) double = 230
  figParams.?matlab.ui.Figure
  figParams.Color = [1,1,1]
end

% check that iris is on the path
ii = what('iris');
if isempty(ii)
  error('Iris DVA must be on the MATLAB path.');
end


% collect the figure parameters as a cell array
params = reshape(namedargs2cell(figParams),2,[]);

%% build the ui
h = utilities.createIrisUiFigure( ...
  title, ...
  sizeParams.width, ...
  sizeParams.height, ...
  'off', ...
  'CloseRequestFcn', @(s,e)fprintf(2,'Please wait.\n'), ...
  params{:} ...
  );

gridLayout = uigridlayout(h,[5,4]);
gridLayout.RowHeight = {'1x','1x',64,'1x','1x'};
% 2x padding on right than on left
gridLayout.ColumnWidth = {'1x',64,'5x','2x'};

sPanel = uipanel(gridLayout);
sPanel.Layout.Row = 3;
sPanel.Layout.Column = 2;
sPanel.BackgroundColor = [1,1,1];
sPanel.BorderType = 'none';

sText = uilabel(gridLayout);
sText.Layout.Row = [2,4];
sText.Layout.Column = 3;
sText.FontSize = 28;
sText.FontName = 'Times New Roman';
sText.Text = sprintf("%*s",fix(strlength(message)*1.651),'');

drawnow();
pause(0.5);

% inject css

window = mlapptools.getWebWindow(h);
cssFile = utilities.scriptRead(...
  fullfile( ...
  iris.app.Info.getResourcePath, ...
  'scripts', ...
  {'IrisStyles_0.css','spinner.css'} ...
  ), ...
  false, false, '''');
cssFile = strjoin(cssFile,' ');

window.executeJS('var css,spinner,panelNode,panel,pChilds,textSel,text;',1);
iter = 0;
while true
  try
    window.executeJS( ...
      [ ...
      'if (typeof css === ''undefined'') {',...
      'css = document.createElement("style");', ...
      'document.head.appendChild(css);', ...
      '}' ...
      ]);
    window.executeJS(['css.innerHTML = `',cssFile,'`;']);
    
    % add the spinner
    window.executeJS(...
      sprintf(...
      [ ...
      'spinner = document.createElement("div");', ...
      'spinner.id = "gear";', ...
      'spinner.innerHTML = `%s`;' ...
      ], ...
      fileread( ...
      fullfile( ...
      iris.app.Info.getResourcePath, 'icn', 'cog-solid.svg' ...
      ) ...
      )) ...
      );
    [~,id] = mlapptools.getWebElements(sPanel);
    v = ver('MATLAB');
    v = str2double(v.Version);
    if v == 9.8
      window.executeJS( ...
        sprintf( ...
        [ ...
        'panelNode = dojo.query("[%s = ''%s'']");', ...
        'panelNode.forEach((n,i,a)=>{dojo.style(n,{display: "flex" });});', ...
        'pChilds = dojo.query("> *",panelNode[0]);', ...
        'pChilds.forEach((n,i,a)=>{dojo.style(n,{display: "flex" });});', ...
        '[panel] = pChilds.slice(-1);', ...
        'panel.appendChild(spinner);' ...
        ], ...
        id.ID_attr, id.ID_val ...
        ));
    elseif v < 9.8
      % worked before v2020a
      window.executeJS( ...
        sprintf( ...
        [ ...
        'panel = dojo.query("[%s = ''%s'']")[0].lastChild;', ...
        'panel.appendChild(spinner);' ...
        ], ...
        id.ID_attr, id.ID_val ...
        ));
    else %2020b
      % in 2020b there is a new disableLayer which resides as the lastChild of
      % a panel widget. So we need to grab the content layer, here we just use
      % the second from the last slice, we could probably construct a way to
      % find the contentNode by:
      % data-dojo-attach-point = "scrollableContents,containerNode,canvasContents"
      % The new panel html structure is:
      %{
      <div (panelWidget)>
        <div (panelWrapper)>
          <div (titleNodeArea)>
            <div (titleNode if title)></div>
          </div>
          <div (titleUnderlineNode)></div>
          <div (scrollableContent)>
            <div (panelContent)> THIS IS OUR CONTENT TARGET </div>
          </div>
          <div (disableLayer)></div><!-- overlay for disabling panel -->
        </div>
        <div (disableFocusNode)></div> <!-- For moving focus away from children -->
      </div>
      %}
      window.executeJS( ...
        sprintf( ...
        [ ...
        'panelNode = dojo.query("[%s = ''%s'']");', ...
        'panel = dojo.query(".gbtPanelContent",panelNode[0]);', ...
        'panel[0].appendChild(spinner);' ...
        ], ...
        id.ID_attr, id.ID_val ...
        ) ...
        );
    end
  catch x
    %log this
    iter = iter+1;
    if iter > 20
      delete(h);
      rethrow(x);
    end
    pause(0.2);
    continue
  end
  break
end
% setup the typing animation
try
  [~,labID] = mlapptools.getWebElements(sText);
catch x
  delete(h);
  rethrow(x);
end
textQuery = sprintf( ...
  'textSel = dojo.query("[%s = ''%s'']");text = textSel[0];', ...
  labID.ID_attr, labID.ID_val ...
  );
iter = 0;
% In 2020a a text node will have the following html structure:
%{
<div data-dojo-attach-point="focusNode"
     class="mwDefaultVisualFamily mwIconAlignmentLeft mwDescriptionMixin mwDisabledMixin mwEnabled mwHorizontalAlignmentMixin mwIconAlignmentMixin mwIconMixin mwNoIcon mwSizeMixin mwTextMixin mwVerticalAlignmentMixin mwHorizontalAlignmentLeft mwVerticalAlignmentMiddle mwWidget mwLabel"
     id="uniqName_29_1" widgetid="uniqName_29_1" data-tag="" aria-disabled="false"
     aria-labelledby="uniqName_29_1_label" title=""
     style="background-color: rgba(0, 0, 0, 0); font: 28px &quot;Times New Roman&quot;, &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif; color: rgb(0, 0, 0); width: 100%; height: 100%;">
   <div data-dojo-attach-point="contentWrapperNode" class="mwContentWrapperNode"
        style="width: 100%; height: 100%;">
      <div data-dojo-attach-point="iconAndTextContainerNode"
           class="mwIconAndTextContainerNode mwAlignmentNode"
           style="max-width: none;">
         <div data-dojo-attach-point="iconNode" class="mwIconNode"></div>
         <div data-dojo-attach-point="textNode" class="mwTextNode"
              id="uniqName_29_1_label" style="max-height: none;"><span
                  class="mwTextLine">TEXT FOR LABEL HERE</span></div>
      </div>
   </div>
</div>
So the structure is kind of like:
controlElement > box > contentWrapper > textIconContainer > { iconBox, textBoxt > span}

the box inherits the width from the parent, #undefined, control.Label (controlElement).
<div
  id="undefined"
  data-type="matlab.ui.control.Label"
  data-tag="4cbf99cb"
  class="vc-widget"
  style= "
    left: 137.25px;
    bottom: 46.5px;
    width: auto;
    height: auto;
    position: static;
    grid-area: 3 / 5 / 8 / 6;
    margin-left: 0px;
    margin-top: 0px;
  "
>

%}
while true
  try
    window.executeJS(textQuery);
    window.executeJS('text.classList.add("funtext","reflow");');
  catch x
    %log x?
    iter = iter+1;
    if iter > 20, iris.app.Info.throwError(x.message); end
    pause(0.25);
    continue
  end
  %success
  break
end

pause(0.25);

h.Visible = 'on';
drawnow();
%figure(h);

sText.Text = message;

end

