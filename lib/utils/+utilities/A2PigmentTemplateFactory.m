function template = A2PigmentTemplateFactory(lambdaMax,scaleFactor)
%A2PIGMENTTEMPLATEFACTORY Returns A2 template function for a provided lambdaMax(s).
%   If lambdaMax is a vector, the spectrum template factory will use the maximum
%   (envelope) of the individual templates, the scale to scaleFactor.
if nargin < 2
  scaleFactor = 1;
end
template = @(L) templateFunction(L,lambdaMax,scaleFactor);

  function template = templateFunction(L,lmax,OD)
    A = 69.7;
    B = 28;
    b = 0.922;
    C = -14.9;
    c = 1.104;
    D = 0.674;

    %OD = 1; % scale of max peak

    y = zeros(length(L),length(lmax));

    for i = 1:length(lmax)
      lambdamax = lmax(i);

      x = lambdamax./L;
      a = 0.8795+0.0459.*exp(-((lambdamax-300).^2)./11940);

      A_expr = exp(A.*(a-x));
      B_expr = exp(B.*(b-x));
      C_expr = exp(C.*(c-x));

      Salpha = OD./(A_expr+B_expr+C_expr+D);

      bbeta = -40.5+0.195.*lambdamax;
      Lmbeta = 189+0.315.*lambdamax;
      Abeta = 0.26.*OD;

      Sbeta = Abeta.*exp(-((L-Lmbeta)./bbeta).^2);

      y(:,i) = Salpha(:) + Sbeta(:);
    end
    resultMax = max(y,[],2);
    resultMax(resultMax > OD) = OD;
    resultMax(resultMax < 0) = 0;
    template = resultMax(:);
  end
end

