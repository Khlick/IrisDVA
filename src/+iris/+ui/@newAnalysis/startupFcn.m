function startupFcn(obj,varargin)
%obj.inputArgs.Data = {'Data', 'DataObject'};
obj.inputArgs.Data = table("Data","DataObject",'VariableNames',obj.inputArgs.ColumnName);
%obj.outputArgs.Data = {'result'};
obj.outputArgs.Data = table("result",'VariableNames',obj.outputArgs.ColumnName);
obj.toggleArgs([],[]);

addlistener(obj,'Close',@(s,e)obj.onCloseRequest);
end

