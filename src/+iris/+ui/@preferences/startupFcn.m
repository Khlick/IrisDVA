function startupFcn(obj)
% expand nodes
obj.PreferencesTree.expand('all');
% add the keyboard documentation
obj.createKeyboardMenu;
% add the close listener
addlistener(obj, 'Close', @(s,e)obj.onCloseRequest);
end