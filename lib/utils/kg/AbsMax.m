function amx = AbsMax(matx)
%ABSMAX Get the absolute max, corrected by the original sign
[amx,ind] = max(abs(matx),[],'all','linear','omitnan');
amx = sign(matx(ind)) * amx;
end

