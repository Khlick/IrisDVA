function pp = drawArrow(ax, arrowAtX, forceDir, color, width_p, height_p, forceYAt)

  if nargin < 7, forceYAt = []; end
  if nargin < 6 || isempty(height_p), height_p = 0.02; end
  if nargin < 5 || isempty(width_p), width_p = 0.0075; end
  if nargin < 4, color = [0 0 0]; end
  if nargin < 3, forceDir = 0; end

  % setting force dir to 0 lets the code figure it out. otherwise +1 is up and
  % -1 is down;
  % define arrow height as a percent of current axes limits
  width_d = width_p * diff(ax.XLim);

  % we expect to draw the arrow away from the response direction so
  % rougly within 3% of the boundary
  v_offset_p = 0.02; % 5 percent
  height_d = height_p * diff(ax.YLim);
  v_offset_d = v_offset_p * diff(ax.YLim);
  y_mid_d = mean(ax.YLim);

  % determine Y location by finding the ydomain of the region
  % comprised of width_d
  xSearch = width_d ./ [-2, 2] + arrowAtX;
  yDom = nan(1, 2);
  yMean = nan(1);

  for ch = 1:numel(ax.Children)

    if isa(ax.Children(ch), 'matlab.graphics.primitive.Patch')
      continue
    end

    try %#ok<TRYNC>
      thisX = ax.Children(ch).XData;
      inds = thisX >= xSearch(1) & thisX <= xSearch(2);
      thisY = ax.Children(ch).YData(inds);
      yDom = utilities.domain([yDom(:); thisY(:)]).';
      yMean = nanmean([yMean; thisY(:)]);
    end

  end

  if ~forceDir
    isArrowOnTop = yMean >= y_mid_d;
    arrowDir = 2 * (isArrowOnTop) - 1; % + is up, - is down
  else
    arrowDir = forceDir;

    if arrowDir >= 0
      isArrowOnTop = true;
    else
      isArrowOnTop = false;
    end

  end

  if ~isempty(forceYAt)
    yStart = forceYAt - v_offset_d * arrowDir;
  elseif isArrowOnTop
    yStart = yDom(2);
  else
    yStart = yDom(1);
  end

  % build counter clockwise from the point closest to the data
  arrowAtY = yStart + v_offset_d * arrowDir;

  verts = [ ...
             arrowAtX, arrowAtY; ...
             xSearch(1), arrowAtY + height_d * arrowDir; ...
             xSearch(2), arrowAtY + height_d * arrowDir ...
           ];

  pp = patch( ...
    ax, ...
    'XData', verts(:, 1), 'YData', verts(:, 2), 'ZData', ones(1, 3), ...
    'FaceColor', color, ...
    'EdgeColor', color, ...
    'FaceAlpha', 1 ...
  );

end
