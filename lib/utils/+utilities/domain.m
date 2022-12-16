function varargout = domain(inputData)
  %DOMAIN min,max array for each input argument provided, operates col-wise on matrix.
  arguments (Repeating)
    inputData (:,:) {mustBeNumeric(inputData)}
  end
  nIn = length(inputData);
  varargout = cell(1,min([nargout,nIn]));
  for I = 1:min([max([1,nargout]),nIn])
    thisRange = inputData{I};
    sz = size(thisRange);
    nanLoc = isnan(thisRange);
    % convert to column matrix and replace nans with mean value
    if any(nanLoc(:)) && all(sz > 1) % is matrix with nan, operate on columns
      colMeans = mean(thisRange,1,'omitnan');
      for col = 1:size(thisRange,2)
        thisRange(nanLoc(:,col),col) = colMeans(col);
      end
    elseif any(nanLoc(:)) && ~all(sz > 1) % is vector with nan, reshape to column replace
      thisRange = thisRange(:);
      thisRange(nanLoc) = mean(thisRange,'omitnan');
    elseif ~all(sz > 1) % is vector, no nan, reshape only
      thisRange = thisRange(:);
    end
    % sort
    thisRange = sort(thisRange); %col-wise
    % retrieve first and last
    varargout{I} = thisRange([1,end],:);
  end
end

