function summaries = hgf_outputs(est, respAcc, outDir, opts)
% summarise_hgf_outputs  Extract trial‑ and subject‑level metrics from HGF fits
%
%   summaries = summarise_hgf_outputs(est, respAcc, outDir, opts)
%
% INPUTS
%   est       (1×N cell) each cell is the HGF model output for one subject
%   respAcc   (1×N cell) binary accuracy vectors (same length as trials)
%   outDir    string      path to save summary .csv files (created if missing)
%   opts      struct      optional parameters:
%              .trialMask struct with fields neu, cong, inc  (logical index)
%              .blockSize double  default 40
%
% OUTPUT
%   summaries struct with fields:
%                LME          (N×1)
%                MUH          (N×3)
%                SA           (struct with SA1, SA2, SA3)
%                WT           (struct with WT1, WT2, WT3)
%                DSA2, DWT1‑3, OM, ZE, accuracy, ...
%              Additionally, writes tidy CSVs for HGFp1 and HGFp2
%
% DESCRIPTION
%   This function rewrites the original monolithic post‑HGF script into a
%   reusable, parameterised module.  For each subject it extracts:
%     • Log model evidence (LME)
%     • Mean beliefs (MUH)
%     • Precision of predictions (SAH) & beliefs (SA)
%     • Precision‑weighted PE weights (WT) per HGF level
%     • Differences between conditions (neutral / congruent / incongruent)
%     • Observation model parameters (ZE, OM)
%     • Behavioural accuracy
%   The outputs are assembled into tables HGFp1 and HGFp2 (mirroring the
%   original workflow) and saved to <outDir>/HGFp1.csv etc.
%
% EXAMPLE
%   load demo_est.mat   % provides {est} and {respAcc}
%   summaries = summarise_hgf_outputs(est, respAcc, "results", struct());
%
% AUTHOR: Vassilis Kotsaris, University of Kent, 2023

arguments
    est (1,:) cell
    respAcc (1,:) cell
    outDir (1,1) string
    opts.blockSize double = 40
end

if ~isfolder(outDir); mkdir(outDir); end
nSubj = numel(est);

%% Pre‑allocate containers
LME  = zeros(nSubj,1);
MUH  = zeros(nSubj,3);
OM   = zeros(nSubj,2);
ZE   = zeros(nSubj,2);
accuracy = zeros(nSubj,2);

WT1 = zeros(nSubj,3); WT2 = WT1; WT3 = WT1;
SA1 = WT1;  SA2 = WT1; SA3 = WT1;
DWT1 = WT1; DWT2 = WT1; DWT3 = WT1;
DSA2 = WT1;

% Trial indices for 3 conditions repeated twice (N‑C‑I)×2 blocks
idx.neu = [1:opts.blockSize, 3*opts.blockSize+1:4*opts.blockSize];
idx.cong= [opts.blockSize+1:2*opts.blockSize,5*opts.blockSize+1:6*opts.blockSize];
idx.inc = [2*opts.blockSize+1:3*opts.blockSize,4*opts.blockSize+1:5*opts.blockSize];

for i = 1:nSubj
    m = est{i};
    LME(i) = m.optim.LME;

    %% Means of muhat at levels 1‑3
    MUH(i,:) = mean(m.traj.muhat(:,1:3),1);

    %% Observation model params
    OM(i,:) = m.p_prc.om(1,2:3);
    ZE(i,1) = m.p_obs.ze(1,1);
    ZE(i,2) = m.p_obs.we(1,1);

    %% Accuracy
    accuracy(i,1) = sum(respAcc{i});
    accuracy(i,2) = 100*mean(respAcc{i});

    %% Weights on prediction errors (WT) per level
    WT = m.traj.wt(:,1:3);
    SA = m.traj.sa(:,1:3);

    % Helper to compute per‑condition average
    fn = @(x,cond) mean(x(idx.(cond),:),1);

    WT1(i,:) = fn(WT(:,1),"neu");
    WT2(i,:) = fn(WT(:,2),"neu");
    WT3(i,:) = fn(WT(:,3),"neu");

    % Differences (neu‑cong etc.)
    tmp1 = [fn(WT(:,1),"neu"); fn(WT(:,1),"cong"); fn(WT(:,1),"inc")];
    DWT1(i,:) = [tmp1(1)-tmp1(2), tmp1(1)-tmp1(3), tmp1(2)-tmp1(3)];
    tmp2 = [fn(WT(:,2),"neu"); fn(WT(:,2),"cong"); fn(WT(:,2),"inc")];
    DWT2(i,:) = [tmp2(1)-tmp2(2), tmp2(1)-tmp2(3), tmp2(2)-tmp2(3)];
    tmp3 = [fn(WT(:,3),"neu"); fn(WT(:,3),"cong"); fn(WT(:,3),"inc")];
    DWT3(i,:) = [tmp3(1)-tmp3(2), tmp3(1)-tmp3(3), tmp3(2)-tmp3(3)];

    SA1(i,:) = fn(SA(:,1),"neu");
    SA2(i,:) = fn(SA(:,2),"neu");
    SA3(i,:) = fn(SA(:,3),"neu");

    % Differences for SA2
    tmpSA2 = [fn(SA(:,2),"neu"); fn(SA(:,2),"cong"); fn(SA(:,2),"inc")];
    DSA2(i,:) = [tmpSA2(1)-tmpSA2(2), tmpSA2(1)-tmpSA2(3), tmpSA2(2)-tmpSA2(3)];
end

%% Assemble tables mirroring original workflow
HGF1 = [array2table(accuracy(:,2),"VariableNames",{"AccPercent"}), ...
        array2table(LME, "VariableNames",{"LME"}), ...
        array2table(MUH), array2table(SA1), array2table(SA2), array2table(SA3), ...
        array2table(SA2), array2table(WT1), array2table(WT2), array2table(WT3), ...
        array2table(OM) ];
HGF2 = [array2table(accuracy(:,2)), array2table(LME), array2table(DSA2), ...
        array2table(DWT1), array2table(DWT2), array2table(DWT3), array2table(ZE) ];

summaries.HGF1 = HGF1;
summaries.HGF2 = HGF2;

%% Write CSVs
writetable(HGF1, fullfile(outDir,'HGFp1.csv'));
writetable(HGF2, fullfile(outDir,'HGFp2.csv'));

end
