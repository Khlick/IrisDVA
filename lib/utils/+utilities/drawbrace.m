function h = drawbrace(start, stop, width, varargin)
% DRAWBRACE   Draw curly brace on current figure
%    DRAWBRACE([X1, Y1], [X2, Y2]) draws a curly brace from the point [X1,
%    Y1] to the point [X2, Y2]
%
%    DRAWBRACE([X1,Y1], [X2,Y2], W) draws a brace using the brace width W.
%
%    DRAWBRACE(..., 'Param1', 'Value1', 'Param2', 'Value2') draws a brace 
%    using the LineSeries property values specified by 'Param1'/'Value1',
%    'Param2'/'Value2', ... .
%
%    H = DRAWBRACE(...) returns the LineSeries handle to the brace.
%
%    Example:
%       H = drawbrace([0 0], [1 1], 20, 'Color', 'k')
%
%    FROM:Curly brace annotation
%    version 1.0.0.0 (1.9 KB) by Pål Næverlid Sævik
%    Draws curly brace on current figure
%    URL: https://www.mathworks.com/matlabcentral/fileexchange/38716-curly-brace-annotation
    
    % Get axis size
    
    if numel(varargin)>0 && ismember("axes",lower(string(varargin(1:2:end))))
      loc = find(ismember(lower(string(varargin(1:2:end))),"axes"),1,'first')*2;
      axs = varargin{loc};
      varargin([loc-1,loc]) = [];
    else
      axs = gca;
    end
    pos = get(axs, 'Position');
    opos = get(gcf, 'Position');
    ylims = axs.YLim;
    xlims = axs.XLim;
    
    % Take logarithmic scale into account
    isxlog = strcmp(get(axs, 'XScale'), 'log');
    isylog = strcmp(get(axs, 'YScale'), 'log');
    if isxlog
        start(1) = log(start(1));
        stop(1) = log(stop(1));
        xlims = log(xlims);
    end
    if isylog
        start(2) = log(start(2));
        stop(2) = log(stop(2));
        ylims = log(ylims);
    end
    
    % Transform from axis to screen coordinates
    xscale = pos(3) * opos(3) / diff(xlims);
    yscale = pos(4) * opos(4) / diff(ylims);
    start = (start - [xlims(1) ylims(1)]) .* [xscale yscale];
    stop = (stop - [xlims(1) ylims(1)]) .* [xscale yscale];
    % Find standard width
    if nargin == 2
        width = norm(stop - start)/10; 
    end
    
    % Find brace points
    th = atan2(stop(2)-start(2), stop(1)-start(1));
    c1 = start + width*[cos(th) sin(th)];
    c2 = 0.5*(start+stop) + 2*width*[-sin(th) cos(th)] - width*[cos(th) sin(th)];
    c3 = 0.5*(start+stop) + 2*width*[-sin(th) cos(th)] + width*[cos(th) sin(th)];
    c4 = stop - width*[cos(th) sin(th)];
    
    % Assemble brace coordinates
    q = linspace(0+th, pi/2+th, 50)';
    t = flipud(q);
    part1x = width*cos(t+pi/2) + c1(1);
    part1y = width*sin(t+pi/2) + c1(2);
    part2x = width*cos(q-pi/2) + c2(1);
    part2y = width*sin(q-pi/2) + c2(2);
    part3x = width*cos(q+pi) + c3(1);
    part3y = width*sin(q+pi) + c3(2);
    part4x = width*cos(t) + c4(1);
    part4y = width*sin(t) + c4(2);
    x = [part1x; part2x; part3x; part4x];
    y = [part1y; part2y; part3y; part4y];
    
    % Transform back to axis coordinates
    x = x / xscale + xlims(1);
    y = y / yscale + ylims(1);
    if isxlog
        x = exp(x); end
    if isylog
        y = exp(y); end
    
    % Plot brace
    h = line(axs,x, y);
    for i = 1:2:numel(varargin)
        set(h, varargin{i}, varargin{i+1}); 
    end
end
