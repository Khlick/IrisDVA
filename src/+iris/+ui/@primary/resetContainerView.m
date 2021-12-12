function resetContainerView(obj, ~, ~)
  % resetContainerView Returns all off-screen windows to center of main monitor
  % move the main figure to the center of the main monitor
  p = utilities.centerFigPos(obj.WIDTH, obj.HEIGHT);
  obj.position = p;

  % find all visible figure windows
  figs = findall(groot,'Type','Figure','Visible', 'on');
  if isempty(figs)
    return
  end

  screenSize = get(groot, 'ScreenSize');

  % extents of screen
  % pad 5 pixels
  pixelPadding = 5;
  sLeft = screenSize(1) + pixelPadding;
  sRight = sum(screenSize([1,3])) - pixelPadding;
  sTop = sum(screenSize([2,4])) - pixelPadding;
  sBottom = screenSize(2) + pixelPadding;

  figPositions = get(figs, {'Position'});
  figPositions = cat(1, figPositions{:});

  % extents of open figures
  fRight = figPositions(:,1)+figPositions(:,3);
  fLeft = figPositions(:,1);
  fTop = figPositions(:,2)+figPositions(:,4);
  fBottom = figPositions(:,2);

  % find figures whos bounds are beyond limits
  targets = find( ...
    fLeft < sLeft | ...
    fRight > sRight | ...
    fTop > sTop | ...
    fBottom < sBottom ...
    );
  nTargets = numel(targets);
  for f = 1:nTargets
    fig = figs(targets(f));
    p = figPositions(targets(f),3:4);
    fig.Position = utilities.centerFigPos(p(1),p(2));
  end
end
