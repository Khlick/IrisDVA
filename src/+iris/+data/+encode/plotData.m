classdef plotData
  %PLOTDATA Collect data for generating plot information.
  properties
    line iris.data.encode.line
    marker iris.data.encode.marker
    name
    mode
    UserData
  end
  properties (Dependent)
    x
    y
  end
  properties (Hidden)
    sampleRate
    info
    xOriginal
    yOriginal
    filterPrefs
    scalePrefs
    baselinePrefs
    isInteractive
  end
  
  methods
    
    function obj = plotData(d,dPrefs,varargin)
      if nargin < 1, return; end
      if nargin < 2
        dPrefs = iris.pref.display.getDefault();
      end
      
      p = inputParser();
      p.addParameter('color', [], ...
        @(x) validateattributes(x,{'double'},{'2d'}) ...
        );
      p.addParameter('lineOpacity', 0.9, @(x)isscalar(x) && (x>=0 && x<=1));
      p.addParameter('markerOpacity',0.9, @(x)isscalar(x) && (x>=0 && x<=1));
      p.addParameter('interactive', true, @(x)islogical(x) && isscalar(x));
      p.addParameter('filterPrefs', iris.pref.dsp.getDefault(), ...
        @(v) isa(v,'iris.pref.dsp') || isa(v,'struct') ...
        );
      p.addParameter('scalePrefs', iris.pref.dsp.getDefault(), ...
        @(v) isa(v,'iris.pref.scales') || isa(v,'struct') ...
        );
      p.addParameter('statsPrefs', iris.pref.dsp.getDefault(), ...
        @(v) isa(v,'iris.pref.statistics') || isa(v,'struct') ...
        );
      % parse inputs
      p.parse(varargin{:});
      
      isInteractive = p.Results.interactive;
      
      % generate array based on the number of response devices (length(d.y))
      N = length(d.y);
      
      % parse colors
      if isempty(p.Results.color)
        colorMap = iris.app.Aes.appColor(N,'contrast');
      else
        colorMap = p.Results.color;
      end
      nColors = size(colorMap,1);
      if nColors < N
        if nColors == 1
          colorMap = iris.app.Aes.shadifyColors(colorMap,N);
        else
          colorMap(end+(1:(N-nColors)),:) = colorMap(end,:);
        end
      elseif nColors > N
        colorMap = colorMap(1:N,:);
      end
      
      %create mode string
      modeStr = {};
      if ~strcmpi(dPrefs.LineStyle, 'None')
        modeStr{end+1} = 'lines';
      end
      if ~strcmpi(dPrefs.Marker, 'None')
        modeStr{end+1} = 'markers';
      end
      modeStr = strjoin(modeStr,'+');
      
      % Get preferences
      fp = p.Results.filterPrefs;
      sp = p.Results.scalePrefs;
      bp = p.Results.statsPrefs;
      
      % build object array
      obj(N,1) = iris.data.encode.plotData();%empty
      for ix = 1:N
        obj(ix).line = iris.data.encode.line( ...
          dPrefs.LineWidth, ... %width
          colorMap(ix,:),   ... %color
          dPrefs.LineStyle, ... %style
          p.Results.lineOpacity       ... %opacity
          );
        obj(ix).marker = iris.data.encode.marker( ...
          dPrefs.MarkerSize, ... %size
          colorMap(ix,:),    ... %color
          dPrefs.Marker,     ... %style
          p.Results.markerOpacity      ... %opacity
          );
        obj(ix).UserData = struct('index',d.index,'device',d.devices{ix});
        obj(ix).name = sprintf('%s (%s)', d.id, d.devices{ix});
        if isa(d.x{ix},'function_handle')
          obj(ix).xOriginal = d.x{ix}();
        else
          obj(ix).xOriginal = d.x{ix};
        end
        obj(ix).yOriginal = d.y{ix};
        % if a datum has length 1, turn markers on for that datum
        if numel(d.y{ix}) == 1
          obj(ix).mode = [modeStr,'+markers'];
          if strcmpi(obj(ix).marker.type,'None')
            obj(ix).marker.type = 'circle';
          end
        else
          obj(ix).mode = modeStr;
        end
        
        
        obj(ix).sampleRate = d.sampleRate{ix};
        obj(ix).filterPrefs = fp;
        obj(ix).scalePrefs = sp;
        obj(ix).baselinePrefs = bp;
        obj(ix).isInteractive = isInteractive;
      end
      
    end
    
    %% Change settings
    function setColor(obj,col)
      for o = 1:numel(obj)
        obj(o).line.color = col;
        obj(o).marker.color = col;
      end
    end
    
    function setLW(obj,newWidth)
      for o = 1:numel(obj)
        if isempty(newWidth)
          newWidth = 2*obj(o).line.width;
        end
        obj(o).line.width = newWidth;
      end
    end
    
    %% SET/GET
    function xvals = get.x(obj)
      if isempty(obj.filterPrefs), xvals=[]; return; end
      if isempty(obj.xOriginal), xvals=[]; return; end
      xvals = obj.xOriginal;
    end
    
    function yvals = get.y(obj)
      if isempty(obj.filterPrefs), yvals=[]; return; end
      if isempty(obj.yOriginal), yvals=[]; return; end
      % copy the original data for manipulation
      yvals = obj.yOriginal;
      
      % find and replace nans
      mu = mean(yvals,1,'omitnan'); %column means
        
      % find and replace nans with mu
      [rowNans,colNans] = find(isnan(yvals));
      for rc = 1:length(rowNans)
        yvals(rowNans(rc),colNans(rc)) = mu(colNans(rc));
      end
      
      
      % If filtered
      if obj.filterPrefs.isFiltered
        switch obj.filterPrefs.Type
          case 'Lowpass'
            ftype = 'low';
            flt = 2*obj.filterPrefs.LowPassFrequency;
          case 'Bandpass'
            ftype = 'bandpass';
            flt = sort( ...
              2 .* [ ...
                obj.filterPrefs.HighPassFrequency, ...
                obj.filterPrefs.LowPassFrequency ...
              ] ...
              );
          case 'Highpass'
            ftype = 'high';
            flt = 2*obj.filterPrefs.HighPassFrequency;
        end
          
        yLen = size(yvals,1);
        
        yvals = yvals - mu;
        
        %build filter
        [b,a] = ButterParam(obj.filterPrefs.Order,flt./obj.sampleRate, ftype);
        
        % pad and filter
        pre = mean(yvals(1:200,:),1,'omitnan');
        post = mean(yvals((end-199):end,:),1,'omitnan');
        
        yvals = [pre(ones(200,1),:);yvals;post(ones(200,1),:)];
        yvals = FiltFiltM(b,a, yvals);
        yvals = yvals(200+(1:yLen),:) +  mu;
        
      end
      
      %If Scaled
      if obj.scalePrefs.isScaled
        % We will use the value in the scale prefs. We expect that this
        % value is updated based on the current selection before we access
        % this plot data.
        scVals = obj.scalePrefs.Value;
        % find the current device
        scaleValue = scVals{ismember(scVals(:,1),obj.UserData.device),2};
        % apply the scale
        yvals = yvals.*scaleValue;
      end
      
      % If baseline
      if obj.baselinePrefs.isBaselined
        npts = obj.baselinePrefs.BaselinePoints;
        ofst = obj.baselinePrefs.BaselineOffset;
        
        doFit = contains(obj.baselinePrefs.BaselineRegion,'Fit');
        
        switch obj.baselinePrefs.BaselineRegion
          case 'Beginning'
            inds = (1:npts)+ofst;
          case 'End'
            inds = size(yvals,1)-ofst-((npts:-1:1)-1);
          otherwise
            if doFit
              inds = (1:npts)+ofst;
              isSym = strcmpi( ...
                regexp( ...
                  obj.baselinePrefs.BaselineRegion, ...
                  '(?<=\()\w+(?=\))', ...
                  'match','once' ...
                  ), ...
                'Sym' ...
                );
              if isSym
                inds = [inds,size(yvals,1)-ofst-((npts:-1:1)-1)];
              end
            end
        end
        % We need to verify that we don't have any strange means
        % check that we don't have any inds <= 0
        inds(inds <= 0) = [];
        % check that we don't have any inds > allowed
        inds(inds > size(yvals,1)) = [];
        % make inds unique
        inds = unique(inds); %is sorted too
        % finally, check that npts not longer than actual record
        if length(inds) > size(yvals,1)
          inds = inds(1:size(yvals,1));
        end
        
        if doFit
          % create fit based on inds for each line in the matrix
          baselineValue = zeros(size(yvals));
          Xs = obj.x;
          if isrow(Xs) || iscolumn(Xs)
            Xs = Xs(:);
            Xs = Xs(:,ones(1,size(yvals,2)));
          end
          % construct a matrix of line data for all Xs\Ys
          for i = 1:size(yvals,2)
            xfit = [ones(length(inds),1), Xs(inds,i)];
            yfit = yvals(inds,i);
            % fit to a smoothed data vector to prevent the line from being wierd
            betas = xfit\smooth(yfit,50);
            % y = b0 + b1*x;
            baselineValue(:,i) = betas(1) + betas(2).*Xs(:,i);
          end
          
          
          
        else
          baselineValue = mean(yvals(inds,:),1,'omitnan');
          baselineValue(isnan(baselineValue)) = 0;
          % create the appropriate matrix
          baselineValue = baselineValue(ones(size(yvals,1),1),:);
        end
        
        % set baselined values:
        yvals = yvals - baselineValue;
      end
      
      % replace nan positions with nan
      for rc = 1:length(rowNans)
        yvals(rowNans(rc),colNans(rc)) = nan;
      end
    end
    
    %% Collect JSON
    function s = jsonify(obj,wrap)
      if nargin < 2
        wrap = false;
      end
      if wrap
        s = '[';
      else
        s = '';
      end
      dlen = numel(obj);
      for i = 1:dlen
        %Line
        lcol = obj(i).line.color.*255;
        lsty = obj(i).line.style;
        if ~strcmpi(lsty,'none'), lsty = 'solid'; end
        lineText = sprintf( ...
          [ ...
            '{"color": %s,', ...
            '"width": %0.2f,', ...
            '"opacity": %0.2f,', ...
            '"style": "%s"}'  ...
          ], ...
          sprintf('"rgb(%0.0f,%0.0f,%0.0f)"',lcol(1:3)), ...
          obj(i).line.width, ...
          obj(i).line.opacity, ...
          lsty ...
          );
        %Marker
        mcol = obj(i).marker.color.*255;
        msty = obj(i).marker.type;
        if ~strcmpi(msty,'none'), msty = 'circle'; end
        markText = sprintf( ...
          [ ...
            '{"color": %s,', ...
            '"size": %0.2f,', ...
            '"opacity": %0.2f,', ...
            '"symbol": "%s"}'  ...
          ], ...
          sprintf('"rgb(%0.0f,%0.0f,%0.0f)"',mcol(1:3)), ...
          obj(i).marker.size, ...
          obj(i).marker.opacity, ...
          msty ...
          );
        xt = sprintf('%0.6f,',obj(i).x);
        yt = sprintf('%0.6f,', obj(i).y);
        if i < dlen
          sep = ',';
        else
          sep = '';
        end
        s = [s,sprintf( ...
          [ ...
            '{', ...
            '"line": %s,', ...
            '"marker": %s,', ...
            '"name": "%s",', ...
            '"mode": "%s",', ...
            '"x": [%s],', ...
            '"y": [%s]', ...
            '}%s' ...
          ], ...
          lineText, ...
          markText, ...
          obj(i).name, ...
          obj(i).mode, ...
          xt(1:end-1), ...
          yt(1:end-1), ...
          sep ...
          )]; %#ok
      end
      if wrap
        s = [s,']'];
      end
    end
  end
end