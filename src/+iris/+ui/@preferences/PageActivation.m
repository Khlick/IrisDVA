function PageActivation(obj,~,event)

%selectedNodes = obj.PreferencesTree.SelectedNodes;
selectedNode = event.SelectedNodes;
if isempty(selectedNode)
  selectedNode = struct('Text','');
end
lastNode = event.PreviousSelectedNodes;
if isempty(lastNode)
  lastNode = struct('Text','');
end

% show selected panel
switch selectedNode.Text
  case 'Variables'
    obj.WorkspacePanel.Visible = 'on';
  case {'Keyboard','Control','Filter','Statistics','Scaling','Display'}
    obj.([selectedNode.Text,'Panel']).Visible = 'on';
  otherwise
    % show the "Select Subset" panel
    obj.SelectSubsetPanel.Visible = 'on';
end

% hide previous panel
switch lastNode.Text
  case 'Variables'
    obj.WorkspacePanel.Visible = 'off';
  case {'Keyboard','Control','Filter','Statistics','Scaling','Display'}
    obj.([lastNode.Text,'Panel']).Visible = 'off';
  otherwise
    % hide the "Select Subset" panel
    obj.SelectSubsetPanel.Visible = 'off';
end
drawnow('nocallbacks');
obj.setContainerPrefs;
end