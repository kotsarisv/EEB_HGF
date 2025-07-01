function c = tapas_unitsq_sgm_config_w
% tapas_unitsq_sgm_config_w  Configuration for the unit-square sigmoid response model
%
% USAGE:
%   c = tapas_unitsq_sgm_config_w
%
% OUTPUT:
%   c      - struct containing model configuration and prior parameter settings:
%             .predorpost      (1 | 2) use predictions (1) or posteriors (2)
%             .model           model identifier string
%             .logzemu         prior mean of log(zeta)
%             .logzesa         prior variance of log(zeta)
%             .logitwemu       prior mean of logit(w_e)
%             .logwesa         prior variance of logit(w_e)
%             .priormus        vector of prior means [logzemu; logitwemu]
%             .priorsas        vector of prior variances [logzesa; logwesa]
%             .obs_fun         function handle for log-probability computation
%             .transp_obs_fun  function handle for parameter back-transformation
%
% DESCRIPTION:
%   Defines the prior distributions and observation mapping settings for the
%   unit-square sigmoid (ussgm) model of binary choice. The ussgm maps a belief
%   x in [0,1] to a probability via:
%       f(x) = x^zeta / (x^zeta + (1-x)^zeta),
%   where zeta > 0 controls the steepness of the sigmoid. A larger zeta yields
%   a more step-like decision rule (less noise), while zeta = 1 returns the
%   identity mapping (f(x)=x).
%
%   This config uses a shrinkage prior on log(zeta) and logit(w_e) (the weight
%   combining two belief sources). Variance terms are set high for weak priors.
%
% Author: Modified by Vassilis Kotsaris & Dimitris Bolis, University of
% Kent, 2023
% Original HGF toolbox function (Mathys et al., 2012-2013)

% Initialize config struct
c = struct;

% Choose belief source: 1 = predictions, 2 = posteriors
c.predorpost = 2;

% Identifier for this observation model
c.model = 'tapas_unitsq_sgm';

% Prior mean and variance for log(zeta) (inverse decision noise)
c.logzemu = log(48);
c.logzesa = 10;

% Prior mean and variance for weight w_e (logit-transformed) between belief levels
x = 0.5;                   % nominal weight value
delta = x / (1 - x);      % logit(x)
c.logitwemu = log(delta);
c.logwesa    = 10;

% Assemble prior parameter vectors
c.priormus = [c.logzemu; c.logitwemu];
c.priorsas = [c.logzesa;  c.logwesa];

% Function handle for computing log-probabilities under this model
c.obs_fun       = @tapas_unitsq_sgm_w;

% Function handle for transforming estimated parameters back to native scale
c.transp_obs_fun = @tapas_unitsq_sgm_transp_w;

end
