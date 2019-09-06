function C = struct2param( S )
%STRUCT2PARAM Convert a struct to name,value pairs.

fn = fieldnames(S);
fv = struct2cell(S);

C = [fn,fv]';% matrix{
C = C(:);%single vector

end

