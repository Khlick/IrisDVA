function drawCorrections(app,result)
  x = cat(1,result.XData); % make columns in multiple results sent.
  y = cat(1,result.YData);
  target = result(1).target+"_C";
  % make sure we have only unique x points
  [~,ux,~] = unique(x,'stable');
  x = x(ux);
  y = y(ux);
  % locate existing lines
  L = app.EditorCorrectionLines( ...
    ismember({app.EditorCorrectionLines.Tag},target) ...
    );
  set(L,XData=x,YData=y);
end

