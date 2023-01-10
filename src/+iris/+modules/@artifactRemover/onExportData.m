function onExportData(app,~,~)
  if ~isempty(app.EditorTable.Data)
    p = iris.ui.questionBox( ...
      Title= 'Apply Changes?', ...
      Options= {'Yes','No','Cancel'}, ...
      Prompt= 'There are unsaved changes, apply them first?', ...
      Default= 'No' ...
      );
    switch p.response
      case 'Yes'
        % run save and export
        app.onSaveChanges([],[]);
        pause(0.1);
      case 'Cancel'
        return
      otherwise
        % NO
    end
  end

  fpath = app.Data.Files(1);
  [~,name,ext] = fileparts(fpath);
  defPath = fullfile(app.lastSaveDirectory,strcat(name,"_cleaned",ext));
  filePath = IrisModule.putFile( ...
    "Export Cleaned Data", ...
    '*.idata', ...
    defPath ...
    );
  [saveDir,fName,~] = fileparts(filePath);
  fprintf("Saving file: '%s'...",fName);

  iData = app.Data;
  save(filePath,'iData','-mat');
  % store last saved directory
  
  app.lastSaveDirectory = string(saveDir);
  fprintf(' Success!\n');
end

