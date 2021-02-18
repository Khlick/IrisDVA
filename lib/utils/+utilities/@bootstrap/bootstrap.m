classdef (Abstract) bootstrap
  % BOOTSTRAP is a collection of methods for analyzing passive membrane properties
  
  properties (Constant)
    B = 10000 % Number of bootstrap samples.
  end
  
  methods (Access = public, Static = true)
    
    function [boots,ci] = getConfidenceIntervals(data,stat,level,B,method)
      % GETCONFIDENCEINTERVALS Univariate Data Only, data in column vector
      arguments
        data (:,1) double
        stat (1,1) function_handle = @mean
        level (1,1) double {mustBeInRange(level,0,1,"exclude-lower","exclude-upper")} = 0.95
        B (1,1) double = utilities.bootstrap.B
        method (1,1) string {mustBeMember(method,["Percentile","BCa"])} = "BCa"
      end
      
      boots = utilities.bootstrap.boot(data,stat,B);
      probs = sort((1-level)/2 + [level,0]);
      
      if strcmp(method,"Percentile")
        ci = quantile(boots,probs);
        return
      end
      % default to BCa
      normalDist = makedist('Normal');
      
      actual = stat(data);
      biasCorProbability = (1+sum(boots < actual))/(B+1); % in case outside
      biasCorrection = normalDist.icdf(biasCorProbability);
      
      % acceleration from jackknife
      knives = utilities.bootstrap.jackknife(data,stat);
      jackEstimate = stat(knives);
      accelEstimate = ...
        sum((jackEstimate - knives).^3) / ...
        ( ...
          6 * sum((jackEstimate - knives).^2)^(3/2) ...
        );
      if isnan(accelEstimate)
        accelEstimate = 0;
      end
      % adjust by alpha
      corBounds = biasCorrection + normalDist.icdf(probs); %[L,U]
      BCaInterval = normalDist.cdf( ...
        corBounds ./ (1-accelEstimate*corBounds) + biasCorrection ...
        );
      ci = quantile(boots,BCaInterval);  
    end
    
    function boots = getBootstraps(data,stat,B)
      arguments
        data (:,1) double
        stat (1,1) function_handle = @mean
        B (1,1) double = 10000
      end
      boots = utilities.bootstrap.boot(data,stat,B);
    end
    
    function varargout = getFitConfidenceIntervals(X,Y,fxString,estimate,spacing,level,B,method,npts)
      % GETFITCONFIDENCEINTERVALS 
      % data must be n rows by 2 columns array with x values in the first column
      % fxString must be of form: "@(b,x)..." where b is the vector of parameters.
      
      % validate args
      arguments
        X (:,1) double
        Y (:,1) double
        fxString (1,1) string
        estimate (1,:) double
        spacing (1,1) string {mustBeMember(spacing,["linear","log"])} = "linear"
        level (1,1) double {mustBeInRange(level,0,1,"exclude-lower","exclude-upper")} = 0.95
        B (1,1) double = utilities.bootstrap.B
        method (1,1) string {mustBeMember(method,["Percentile","BCa"])} = "BCa"
        npts (1,1) uint64 = 2000
      end
      assert(numel(X) == numel(Y));
      
      error("Not implemented.");
      
      % import
      import utilities.domain
      
      % wrangle
      data = [X,Y];
      nParams = numel(regexp(fxString,"b(?=\(\d+)",'match'));
      if numel(estimate) ~= nParams
        error("Estimate must be the same length as parameters");
      end
      
      fx = str2func(fxString);
      
      stat = @(d) dofit(fx,d(:,1),d(:,2),estimate);
      
      params = stat(data);
      resids = fx(params,data(:,1)) - data(:,2);
      dataRange = log10(domain(data(:,1)));
      X_fit = logspace(dataRange(1),dataRange(2),npts)';
      Y_fit = fx(params,X_fit);
      % Perform bootstrap
      bootParams = nan(B,nParams);
      bootFits = nan(npts,B);
      for b = 1:B
        bootParams(b,:) = stat([data(:,1),Y_fit - randsample(resids,N,true)]);
        bootFits(:,b) = fx(bootParams(b,:),X_fit);
      end
      
      probs = sort((1-level)/2 + [level,0]);
      if strcmp(method,"Percentile")
        ci = quantile(boots,probs,1);
      else
        normalDist = makedist('Normal');
        
      end
      
      varargout{1} = ci;
      n = nargout;
      if n > 1
        varargout{2} = bootParams;
      end
      if n > 2
        varargout{3} = bootFits;
      end
      if n > 3
        [varargout{4:nargout}] = deal([]);
      end
      
      function param = dofit(fHandle,x,y,b0)
        param = lsqcurvefit( ...
          fHandle, ...
          b0, ...
          x, ...
          y, ...
          [],[], ...
          optimoptions('lsqcurvefit','Display', 'off','MaxIterations',utilities.bootstrap.B) ...
          );
      end
    end
    
  end
  
  methods (Access = private, Static = true)
    
    function boots = boot(data,stat,B)
      N = length(data);
      samps = data(randi(N,N,B));
      if (N < 5) && (length(unique(data)) > 1)
        samps = samps + randn(N,B)/1000;
      end
      boots = stat(samps);
    end
    
    function knives = jackknife(data,stat)
      N = length(data) - 1;
      inds = (1:(N+1))' * ones(1,N+1);
      for n = (0:N)+1
        inds(:,n) = circshift(inds(:,n),n);
      end
      % remove 1
      inds(end,:) = [];
      knives = stat(data(inds));
    end
  end
  
end