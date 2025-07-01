function [df, stats] = prep_pipeline_online(config)
% prer_pipeline_online  Pre‑process online EEB CSV data for HGF analysis
%
%   [df, stats] = prep_pipeline_online(config)
%
% INPUT (config struct):
%   config.data_dir       string  Path to folder with subject .csv files (required)
%   config.subjects       cell    Filenames to process (default: all *.csv in data_dir)
%   config.block_size     double  Trials per block (default: 40)
%   config.filters.minRT  double  Minimum RT in seconds (default: 0.2)
%   config.filters.maxRT  double  Maximum RT in seconds (default: Inf)
%   config.filters.keep_cols cell  Column names to retain (default list below)
%   config.compute_stats  logical If true, returns summary statistics (default: false)
%
% OUTPUT:
%   df    cell array (nSubj×1) of tidy tables for each subject
%   stats struct of summary matrices (only if compute_stats==true)
%
% EXAMPLE:
%   cfg.data_dir = 'path/to/csvs';
%   [df, stats] = demo_pipeline_online(cfg);

% --- Default settings and input validation ---
if nargin < 1 || ~isstruct(config)
    error('You must provide a config struct with at least ''data_dir'' defined.');
end
% Required field: data_dir
if ~isfield(config,'data_dir') || isempty(config.data_dir)
    error('config.data_dir must specify the folder containing .csv files.');
end
% Optional: subjects list
if ~isfield(config,'subjects') || isempty(config.subjects)
    S = dir(fullfile(config.data_dir, '*.csv'));
    files = {S.name};
else
    files = config.subjects;
end
% Default block_size
if ~isfield(config,'block_size') || isempty(config.block_size)
    config.block_size = 40;
end
% Default filters sub-struct
if ~isfield(config,'filters') || ~isstruct(config.filters)
    config.filters = struct();
end
if ~isfield(config.filters,'minRT') || isempty(config.filters.minRT)
    config.filters.minRT = 0.2;
end
if ~isfield(config.filters,'maxRT') || isempty(config.filters.maxRT)
    config.filters.maxRT = Inf;
end
% Default keep_cols
if ~isfield(config.filters,'keep_cols') || isempty(config.filters.keep_cols)
    config.filters.keep_cols = { ...
        'age','id','outcome','expression','same', ...
        'model','game_bet','congruency','noise', ...
        'blocktype','block','ER_resp_keys', ...
        'ER_resp_corr','ER_resp_rt'};
end
% Default compute_stats
if ~isfield(config,'compute_stats') || isempty(config.compute_stats)
    config.compute_stats = false;
end

% Number of subjects
nSubj = numel(files);
% Preallocate outputs
df = cell(nSubj,1);
if config.compute_stats
    stats = struct('accuracy',zeros(nSubj,6),'RTmean',zeros(nSubj,6));
else
    stats = [];
end

% --- Main loop over subjects ---
for k = 1:nSubj
    fname = fullfile(config.data_dir, files{k});
    raw = readtable(fname, 'TextType', 'string');

    % Remove practice and catch rows
    mask = ~isnan(raw.face) & ~isnan(raw.Practice_thisRepN);
    raw = raw(mask,:);

    % Recode categorical variables to binary
    raw.outcome      = double(raw.outcome == 'win');
    raw.expression   = double(raw.expression == 'happy');
    raw.ER_resp_keys = double(raw.ER_resp_keys == 'right');
    raw.noise        = double(raw.noise == 'high');

    % Add block and blocktype labels
    bt = config.block_size;
    raw.block     = repelem((1:6)', bt);
    raw.blocktype = repelem([1;2;3;1;3;2], bt);

    % Compute 'same' flag
    raw.same = double(raw.outcome == raw.ER_resp_keys);
    % Subject ID
    raw.id = repmat(k, height(raw), 1);

    % Flag irregular trials by RT
    IR = raw.ER_resp_rt < config.filters.minRT | raw.ER_resp_rt > config.filters.maxRT;
    raw.IR = double(IR);

    % Retain only specified columns
    keepVars = intersect(config.filters.keep_cols, raw.Properties.VariableNames);
    tidy = raw(:, keepVars);
    df{k} = tidy;

    % Compute summary stats
    if config.compute_stats
        for b = 1:6
            blkRows = tidy.block == b & tidy.IR == 0;
            stats.accuracy(k,b) = mean(tidy.ER_resp_corr(blkRows));
            stats.RTmean(k,b)   = mean(tidy.ER_resp_rt(blkRows));
        end
    end
end

end
