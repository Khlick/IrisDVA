function onDatumIndexChanged(app,src,evt)
  % check if there is pending changes and ask to apply them
  if ~isempty(app.EditorTable.Data)
    p = iris.ui.questionBox( ...
      Title= 'Apply Changes?', ...
      Options= {'Yes','No'}, ...
      Prompt= 'There are unsaved changes, apply them first?', ...
      Default= 'Yes' ...
      );
    if strcmp(p.response,'Yes')
      app.onApplyCurrentCorrections([],[]);
      pause(0.1);
    end
  end
  
  % check for included datums
  oldIndex = app.datumIndex;
  disallowed = find(~app.Data.InclusionList);
  
  switch src.Tag
    case 'increment'
      maxVal = app.Data.nDatums;
      newIndex = min(oldIndex + 1, maxVal);
      while ismember(newIndex,disallowed)
        if newIndex == maxVal
          newIndex = oldIndex;
          break
        end
        newIndex = min(newIndex+1,maxVal);
      end        
    case 'decrement'
      newIndex = max(oldIndex - 1, 1);
      while ismember(newIndex,disallowed)
        if newIndex == 1
          newIndex = oldIndex;
          break
        end
        newIndex = max(newIndex-1,1);
      end
    otherwise
      % edit field has built-in validation for limits, check only newIndex is
      % included
      newIndex = evt.Value;
      oldIndex = evt.PreviousValue;
      dc = sign(newIndex-oldIndex);
      if dc > 0
        comp = @min;
        lim = app.Data.nDatums;
      else
        comp = @max;
        lim = 1;
      end
      while ismember(newIndex,disallowed)
        if newIndex == lim
          newIndex = oldIndex;
          break
        end
        newIndex = comp(newIndex+dc,lim);
      end
      src.Value = newIndex;
      pause(0.001);
      app.updateDatum();
      return
  end
  if oldIndex ~= newIndex
    app.DatumIndexField.Value = newIndex;
    app.updateDatum();
  end
end

