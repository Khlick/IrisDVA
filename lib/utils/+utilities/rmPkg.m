function status = rmPkg(pkg,base)
status = {};

if isa(pkg,'meta.package')
  for I = 1:numel(putilities.ClassList)
    status{end+1} = utilities.rmPkg(putilities.ClassList(I),base);
  end
  for J = 1:numel(putilities.PackageList)
    status{end+1} = utilities.rmPkg(putilities.PackageList(J),base);
  end
end

try 
  cn = regexprep(putilities.Name,'\.','_');
  rmpref(base,cn);
  status{end+1} = sprintf('Removed "%s" for "%s"!',cn,base);
catch
  status{end+1} = sprintf('No pref "%s" for "%s".',cn,base);
end

status = {status{:}};%#ok
end