function startupFcn(obj)
% expand nodes
obj.PreferencesTree.expand('all');
% add the keyboard documentation
obj.createKeyboardMenu;
% add the close listener
addlistener(obj, 'Close', @(s,e)obj.onCloseRequest);
% reorder the workspace panel to force the buttons to show. Don't know why
% exactly this needs to be done, but it won't show unless we do this after
% building!
obj.WorkspacePanel.Children = obj.WorkspacePanel.Children(end:-1:1);
% add all the tooltips
obj.injectTooltips();
% update
obj.update();
end