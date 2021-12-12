function bindUI(obj)
  % BINDUI binds all callbacks to the UI
  import iris.infra.eventData;

  % menu items
  obj.appendYes.MenuSelectedFcn = @obj.onAppendMethodChanged;
  obj.appendNo.MenuSelectedFcn = @obj.onAppendMethodChanged;
  obj.appendAsk.MenuSelectedFcn = @obj.onAppendMethodChanged;
  obj.sendToCommandOption.MenuSelectedFcn = @(src,evt) ...
    obj.onOptionMenuChanged(src,eventData({'command',~src.Checked},evt));
  obj.backtrackDataIndicesOption.MenuSelectedFcn = @(src,evt) ...
    obj.onOptionMenuChanged(src,eventData({'backtrack',~src.Checked},evt));
  obj.resetDefaultsOption.MenuSelectedFcn = @(src,evt)obj.resetContainerPrefs();

  % visibility of extra panels
  obj.batchVisibilityButton.ValueChangedFcn = @obj.onUpdateBatchVisibility;
  obj.argumentsToggleOut.ValueChangedFcn = @(src,evt) ...
    obj.onUpdateArgumentsVisibilty(src,eventData({'out',evt.Value},evt));
  obj.argumentsToggleIn.ValueChangedFcn = @(src,evt) ...
    obj.onUpdateArgumentsVisibilty(src,eventData({'in',evt.Value},evt));
  
  % parse data indices
  obj.dataInput.ValueChangedFcn = @obj.onDataIndicesChanged;

  % parse selected analysis function
  obj.selectDropdown.ValueChangedFcn = @obj.onAnalysisChanged;

  % output file
  obj.outputFile.ValueChangedFcn = @obj.onOutputFileChanged;
  obj.outputLocation.ButtonPushedFcn = @obj.onGetNewLocation;

    % reduce/show function call signature
  obj.functionCallLabel.StatusChangedFcn = @obj.onToggleFunctionCallString;
  obj.functionCallLabel.HeightChangedFcn = @obj.onFunctionCallHeightChanged;
  
  % Interact with selected analysis
  obj.editAnalysisButton.ButtonPushedFcn = @obj.onEditCurrentAnalysis;
  obj.refreshAnalysisButton.ButtonPushedFcn = @obj.onRefreshAnalysesList;
  obj.updateDefaultsButton.ButtonPushedFcn = @obj.onSetCurrentAnalysisDefaults;
  
  % validate table entry
  obj.argumentsOutTable.CellEditCallback = @obj.onOutputTableCellChanged;
  obj.argumentsInTable.CellEditCallback = @obj.onInputTableCellChanged;
  
  % perform the selected analysis
  obj.outputAnalyzeButton.ButtonPushedFcn = @obj.onRequestAnalysis;

  % update bound status
  obj.isBound = true;
end

