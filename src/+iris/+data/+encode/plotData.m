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
  end
  
  methods
    
    function obj = plotData(d,dPrefs,lineOpacity,markerOpacity)
      if nargin < 1, return; end
      if nargin < 4, markerOpacity = 0.6; end
      if nargin < 3, lineOpacity = 0.95; end
      if nargin < 2
        dPrefs = iris.pref.display.getDefault();
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
      % generate array based on the number of response devices
      N = length(d.y);
      colorMap = iris.app.Aes.appColor(N,'contrast');
      % Get preferences
      fp = iris.pref.dsp.getDefault();
      sp = iris.pref.scales.getDefault();
      bp = iris.pref.statistics.getDefault();
      % build object
      obj(N,1) = iris.data.encode.plotData();%empty
      for ix = 1:N
        obj(ix).line = iris.data.encode.line( ...
          dPrefs.LineWidth, ... %width
          colorMap(ix,:),   ... %color
          dPrefs.LineStyle, ... %style
          lineOpacity       ... %opacity
          );
        obj(ix).marker = iris.data.encode.marker( ...
          dPrefs.MarkerSize, ... %size
          colorMap(ix,:),    ... %color
          dPrefs.Marker,     ... %style
          markerOpacity      ... %opacity
          );
        obj(ix).UserData = struct('index',d.index,'device',d.devices{ix});
        obj(ix).name = sprintf('%s (%s)', d.id, d.devices{ix});
        if isa(d.x{ix},'function_handle')
          obj(ix).xOriginal = d.x{ix}();
        else
          obj(ix).xOriginal = d.x{ix};
        end
        obj(ix).yOriginal = d.y{ix};
        obj(ix).mode = modeStr;
        obj(ix).sampleRate = d.sampleRate{ix};
        obj(ix).filterPrefs = fp;
        obj(ix).scalePrefs = sp;
        obj(ix).baselinePrefs = bp;
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
      % dev: for now return the correct values
      yvals = obj.yOriginal;
      % If baseline
      if obj.baselinePrefs.isBaselined
        switch obj.baselinePrefs.BaselineRegion
          case 'Beginning'
            inds = 1:obj.baselinePrefs.BaselinePoints;
          case 'End'
            inds = size(yvals,1)-((obj.baselinePrefs.BaselinePoints:-1:1)-1);
          otherwise
            fprintf('"%s" not supported yet. Using "Beginning".\n',...
              obj.baselinePrefs.BaselineRegion);
            inds = 1:obj.baselinePrefs.BaselinePoints;
        end
        baselineValue = mean(yvals(inds,:),1,'omitnan');
        baselineValue(isnan(baselineValue)) = 0;
        % set baselined values:
        yvals = yvals - baselineValue(ones(size(yvals,1),1),:);
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
          
        ButterParam('save');%turn on saving for parameter values
        
        mu = mean(yvals,1,'omitnan'); %column means
        preVal = mean(yvals(1:100,:)-mu(ones(100,1),:));
        postVal = mean(yvals(end-(99:-1:0),:)-mu(ones(100,1),:));
        %build filter
        [b,a] = ButterParam(obj.filterPrefs.Order,flt./obj.sampleRate, ftype);
        
        % pad and filter
        fY = FiltFiltM(b,a, ...
          [ ...
            preVal(ones(2000,1),:); ...
            yvals-mu(ones(size(yvals,1),1),:); ...
            postVal(ones(2000,1),:) ...
          ]);
        yvals = fY(2000 + (1:size(yvals,1)),:) + mu(ones(size(yvals,1),1),:);
      end
      
      %If Scaled
      if obj.scalePrefs.isScaled
        % We will use the value in the scale prefs. We expect that this
        % value is updated based on the current selection before we access
        % this plot data.
        yvals = yvals./obj.scalePrefs.Value;
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