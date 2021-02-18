function params = orthoReg(X,Y)

data = [X(:),Y(:)];

N = length(X);

colMeans = mean(data,1);

[coefs,scores,~] = pca(data);


directionVector = coefs(:,1);

% orthofit = mu + scores*coefs' (of 1st pc)
% projection of each point on the fit line by the original coordinate
% such that orthoFit(:,1) == x_hat and orthoFit(:,2) == y_hat
orthoFit = colMeans + scores(:,1)*directionVector';

% gather the parameters for the orthogonal fit line
% such that y_hat = b1 * x_hat + b2 | b = [b1,b2]
% this fit should be perfect because of how the pca performs the linearization
orthoParams = polyfit(orthoFit(:,1),orthoFit(:,2),1);


% compute the orthogonal error pairs
xPairs = [data(:,1),orthoFit(:,1)]';
yPairs = [data(:,2),orthoFit(:,2)]';

errPair(1:N) = struct('xdata',0,'ydata',0);
errDist = zeros(N,1);
for n = 1:N
  ex = xPairs(:,n);
  ey = yPairs(:,n);
  errPair(n).xdata = ex;
  errPair(n).ydata = ey;
  errDist(n) = sqrt(diff(ex)^2 + diff(ey)^2);
end

% output
params = struct();
params.OrthogonalParameters = orthoParams;
params.OrthogonalLine = orthoFit;
params.Residual = errPair;
params.ResidualDistance = errDist;

end