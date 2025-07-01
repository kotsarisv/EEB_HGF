function [logp, yhat, res] = tapas_unitsq_sgm_w(r, infStates, ptrans)
% tapas_unitsq_sgm_w  Compute log-probabilities under the unit-square sigmoid response model
%
% USAGE:
%  [logp, yhat, res] = tapas_unitsq_sgm_w(r, infStates, ptrans)
%
% INPUTS:
%  r         - response structure with fields:
%                .y       (n x 1) observed binary responses (0 or 1)
%                .c_obs   (struct) model configuration, with field predorpost:
%                           1 = use predictions, 2 = use posteriors
%                .irr     (index vector) indices of irregular trials to ignore
%  infStates - inferred states array (n x 1 x 3) from HGF output
%              dimension 1: trial number
%              dimension 3: hidden state levels (1 for first level, 3 for third level)
%  ptrans    - transformed parameters vector [log(zeta); logit(we)]
%
% OUTPUTS:
%  logp      - (n x 1) log-probabilities of response y=1 for each trial
%              NaN for irregular trials
%  yhat      - (n x 1) model-predicted probability x
%  res       - (n x 1) standardized residuals (y - x) / sqrt(x * (1 - x))
%
% DESCRIPTION:
%  This function implements the unit-square sigmoid response mapping, combining
%  beliefs from two levels of the HGF (x1 and x2) weighted by parameter w_e,
%  passed through a power sigmoid with exponent zeta, to compute the log-probability
%  of the binary response y. Irregular trials (specified in r.irr) are returned as NaN.
%
%  The combined belief at each trial is:
%     x = w_e * x1 + (1 - w_e) * x2
%  and the log-probability under the sigmoid is:
%     logp = log( x^zeta / (x^zeta + (1-x)^zeta) )
%  with analytic adjustment for numerical stability. The standardized residuals are
%     (y - x) / sqrt(x * (1-x)).
%
% Author: Modified by Vassilis Kotsaris & Dimitris Bolis, University of
% Kent, 2023
% Original HGF toolbox function (Mathys et al., 2012-2013)

% Determine whether to use predicted or posterior beliefs
pop = 1;  % default: use predictions
if r.c_obs.predorpost == 2
    pop = 3;  % use posterior beliefs at level 1
end

% Transform zeta to its native space
ze = exp(ptrans(1));
% Transform we to its native space
we = 1/(1+exp(-ptrans(2)));

% Initialize returned log-probabilities as NaNs so that NaN is
% returned for all irregualar trials
n = size(infStates,1);
logp = NaN(n,1);
yhat = NaN(n,1);
res  = NaN(n,1);

% Weed irregular trials out from inferred states and responses
x1 = infStates(:,1,1);
x1(r.irr) = [];
x2 = infStates(:,1,5);
x2(r.irr) = [];
y = r.y(:,1);
y(r.irr) = [];

%combined belief
x=we.*x1+(1-we).*x2;

% Avoid any numerical problems when taking logarithms close to 1
logx = log(x);
log1pxm1 = log1p(x-1);
logx(1-x<1e-4) = log1pxm1(1-x<1e-4);
log1mx = log(1-x);
log1pmx = log1p(-x);
log1mx(x<1e-4) = log1pmx(x<1e-4); 

% Calculate log-probabilities for non-irregular trials
reg = ~ismember(1:n,r.irr);
logp(reg) = y.*ze.*(logx -log1mx) +ze.*log1mx -log((1-x).^ze +x.^ze);
yhat(reg) = x;
res(reg) = (y-x)./sqrt(x.*(1-x));

return;
