function startupFcn(obj,varargin)
obj.inputArgs.Data = {'Data', 'DataObject'};
obj.outputArgs.Data = {'result'};
obj.toggleArgs([],[]);

addlistener(obj,'Close',@(s,e)obj.onCloseRequest);
end

