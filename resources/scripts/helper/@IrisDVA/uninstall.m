function uninstall()
  %UNINSTALL Uninstall current version of Iris
  response = questdlg( ...
    'Remove Iris preferences?', ...
    'Clear prefs?', ...
    'Yes', 'No', 'No' ...
    );
  if string(response)=="", return; end
  % remove prefs if selected
  if strcmp(response,'Yes')
    IrisDVA.resetPreferences();
  end
  % detach iris if it is mounted, otherwise the folder may not be deleted
  if IrisDVA.isMounted()
    IrisDVA.detach();
  end
  % use matlab's uninstaller
  appid = [IrisDVA.APP_NAME,IrisDVA.APP_ID];
  matlab.apputil.uninstall(appid);
end

