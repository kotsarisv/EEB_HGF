function df = prep_pipeline_lab(config)
% prep_pipeline_lab  Preprocess EEB lab data for HGF analysis
%
%   df = prep_pipeline_lab(config)
%
% INPUT (config struct):
%   config.data_dir   (string) path to folder with subject .mat files
%   config.subjects  (cell array of filenames) optional; defaults to all .mat
%   config.block_size (double) trials per block; default = 41
%   config.filters.minRT      (double) minimum RT in seconds; default = 0.1
%   config.filters.maxAcc     (double) maximum accuracy code; default = 2
%
% OUTPUT:
%   df  cell array of tables, one per subject, with columns:
%       ImgCode, Acc, Congruency, RT, RespLR, outcome, expression, noise,
%       block, blocktype, same (binary), IR (irregular trial flag)
%
% EXAMPLE USAGE:
%   cfg.data_dir    = 'data/demo';
%   cfg.subjects    = {};  % use all files
%   cfg.block_size  = 41;
%   cfg.filters.minRT  = 0.1;
%   cfg.filters.maxAcc = 2;
%   df = demo_pipeline(cfg);

% Parse and set defaults
if ~isfield(config,'data_dir') || isempty(config.data_dir)
    error('config.data_dir must specify a path to .mat files');
end
if ~isfield(config,'subjects') || isempty(config.subjects)
    S = dir(fullfile(config.data_dir,'*.mat'));
    files = {S.name};
else
    files = config.subjects;
end
if ~isfield(config,'block_size'), config.block_size = 41; end
if ~isfield(config,'filters') || ~isfield(config.filters,'minRT'), config.filters.minRT = 0.1; end
if ~isfield(config,'filters') || ~isfield(config.filters,'maxAcc'), config.filters.maxAcc = 2; end

nSubj = numel(files);
df = cell(nSubj,1);

for k = 1:nSubj
    % Load raw data
    dataStruct = load(fullfile(config.data_dir, files{k}), 'data', 'dataf', 'results');
    raw = dataStruct.dataf;
    res = dataStruct.results;
    y  = res.subj_resp_ER(:);  % binary responses
    acc = res.accuracy_ER(:);
    rt  = res.RT_ER(:);
    conj = raw.congruency(:);
    face = raw.face(:);
    outcome = raw.outcome(:);
    expr = raw.expression(:);
    noise = raw.noise(:);
    % Binarize outcome and expression
    outcomeBin = double(strcmp(outcome,'win'));
    exprBin    = double(strcmp(expr,'happy'));
    % Binarize noise parity
    noiseBin = mod(noise,2)==0;
    % Assemble trial table
    T = table(face, acc, conj, rt, y, outcomeBin, exprBin, noiseBin, ...
              'VariableNames', { 'ImgCode','Acc','Congruency','RT', ...
                                 'RespLR','outcome','expression','noise' });
    % Add block and blocktype labels
    bt = config.block_size;
    blocks = repmat((1:6)', bt, 1);
    types  = repmat([1;2;3], bt, 2);
    T.block = blocks;
    T.blocktype = types;
    % Flag irregular trials and apply filters
    IR = false(height(T),1);
    IR(T.RT < config.filters.minRT | T.Acc > config.filters.maxAcc) = true;
    T.IR = double(IR);
    % Compute 'same' as match between RespLR and Acc
    T.same = double(T.RespLR == T.Acc);
    % Keep only non-catch trials (ImgCode < 9000)
    T = T(T.ImgCode < 9000,:);
    % Store
    df{k} = T;
end

end
