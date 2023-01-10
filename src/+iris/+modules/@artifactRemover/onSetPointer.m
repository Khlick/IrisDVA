function onSetPointer(app,fig,src,type)
  switch type
    case 'in'
      ptr = 'left';
      alpha = app.ALPHA_HOVER;
      app.currentROITag = src.Tag;
    otherwise
      ptr = 'arrow';
      alpha = app.ALPHA;
      app.currentROITag = "";
  end
  fig.Pointer = ptr;
  src.FaceAlpha = alpha;
end

