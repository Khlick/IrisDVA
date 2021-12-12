function buildUI(obj,handler)
  % BUILDUI Interact with menuservice to construct/show this ui
  if nargin < 2, handler = obj.Handler; end
  % IF the window was closed, rebuild from superclass
  if obj.isClosed
    if ~handler.isready, error("Handler is not ready."); end
    obj.rebuild(handler); 
    return
  end
  % if a new handler is being passed
  newHandler = ~isequal(handler,obj.Handler);
  
  if ~newHandler, obj.show(); return; end
  
  % set new handler and rebuild listeners
  obj.Handler = handler;
  obj.rebindUI();

  % update ui
  obj.clearUI();
  obj.setSelectionFromHandler();

end

