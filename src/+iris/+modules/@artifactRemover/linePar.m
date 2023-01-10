function par = linePar(color,target)
  arguments
    color (1,3) double
    target (1,1) string = ""
  end
  par = { ...
    'Color', color, ...
    'Marker','none', ...
    'LineStyle', '-' ...
    };
  if target ~= ""
    par(end+(1:2)) = {'Tag', target+"_C"};
  end
end
