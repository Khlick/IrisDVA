function resetPreferences()
  %RESETPREFERENCES Removes all of Iris' preferences.
  appInfo = IrisDVA.info;
  if isempty(appInfo)
    fprintf("Iris not installed. Not all preferenes may be removed.\n");
    try %#ok<*TRYNC> 
      rmpref('iris');
    end
    try 
      rmpref('Iris');
    end
    return
  end
  
  installDir = IrisDVA.import();
  
  % locate preferences
  ipk = meta.package.fromName('iris');
  for p = 1:numel(ipk.PackageList)
    recurseRM(ipk.PackageList(p));
  end
  try 
    rmpref('iris');
  end
  try 
    rmpref('Iris');
  end
  
  % remove Iris from the path
  rmpath(genpath(installDir));
end

function recurseRM(pkg)

if isa(pkg,'meta.package')
  for I = 1:numel(pkg.ClassList)
    recurseRM(pkg.ClassList(I));
  end
  for J = 1:numel(pkg.PackageList)
    recurseRM(pkg.PackageList(J));
  end
end

try
  cn = regexprep(pkg.Name,'\.','_');
  rmpref('iris',cn);
  fprintf('Removed "%s"!\n',cn);
end

end
