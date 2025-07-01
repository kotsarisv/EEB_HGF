%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract Evoked Heart Rate Responses Aligned to Feedback Triggers
%
% DESCRIPTION:
% This script processes pre-recorded heart rate data from multiple subjects
% to extract event-related inter-beat interval (IBI) measures around
% feedback triggers. It:
%   - Loads raw heart data from .mat files and corresponding trial data
%   - Identifies trigger points associated with feedback onset
%   - Applies the Pan-Tompkins algorithm to detect heartbeats (QRS peaks)
%   - Computes inter-beat intervals (IBIs) and filters outliers
%   - Interpolates IBIs to obtain a continuous time series
%   - Computes baseline-normalised IBI metrics:
%       HRInitial = peak deceleration after feedback
%       HRFinal   = peak acceleration after feedback
%       HRall     = average IBI change after feedback
%   - Stores trial-wise HR metrics in a modified version of the df table
%
% DEPENDENCIES:
% - pan_tompkin.m (Pan-Tompkins QRS detection algorithm)
% - df.mat (trial info per subject)
% - Heart data .mat files in directory D (variable 'data' must exist)
%
% INPUTS (manually set in workspace):
% - D: folder path with heart data .mat files
%
% OUTPUTS (in workspace):
% - df0HR: cell array of tables per subject with added HR metrics
% - av: average evoked HR response time course per subject
%
% NOTE:
% Sampling rate is assumed to be 2000 Hz
% Triggers are adjusted to align to feedback events
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
S = dir(fullfile(D,'*.mat'));

for s = 1:numel
   
F = fullfile(D,S(s).name);
dfH{s}= load(F); 
 
% load 37LG  %1000 triggers % I believe there are two participants tested sequentially on this file, check which one is 37

data=dfH{s}.data;

plotevery=1;

hr=data(:,2); % heart data

c=0; trig=[];  %find triggers
for i=2:length(data)
    if data(i-1,3)<4 && data(i,3)>4.5
        c=c+1;
        trig(c)=i+200;%the trigger was sent 100ms before the outcome
    end
end

trig=trig(9:end); %% exclude for practice trials (i.e. 8 triggers)

hr=hr(trig(1)-12000:trig(end)+13000); %remove from heart data time period before and after first trigger to clean noise

trig=trig-trig(1)+12000; % correct trigger times for removed period

trig=trig(1:2:492); % get only the triggers for the feedback and not the ITI, assuming the first trial of each block does not have the ITI (NEED TO CHECK WHAT HAPPENS BETWEEN BLOCK, i.e. BEFORE ONE ENDS AND WHEN THE OTHER STARTS )
%trig=trig+7200;
trg{s}=trig;

[qrs_amp_raw,qrs_i_raw,delay]=pan_tompkin(hr,2000,plotevery); 
b=qrs_i_raw; %%get HB timings  NOTE: sampling rate is 2000ms


dist=[];
for i=2:length(b)
    dist(i-1)=b(i)-b(i-1); %% get IBIs, i.e. the time distances between consecutive heartbeats
end
%dist(1)=dist(2);
%dist(1)=nanmean(dist); % first point is zero, so assign the same as average (this point is not used for data only to calculate the average)
dist(end+1)=nanmean(dist); % first point is zero, so assign the same as average (this point is not used for data only to calculate the average)

mdist=mean(dist);
stdist=std(dist);
for i=3:length(dist)  %% get rid of IBI outliers
    if dist(i)>=(mean(dist)+(std(dist)*3)) || dist(i)<=(mean(dist)-(std(dist)*3))
        dist(i)=dist(i-1);
    end
    
end

ibi=interp1(b,dist,[1:1:max(b)]); %interpolate to get continuous vector of IBI values

df0HR{s}=df{s};
df0HR{s}.HRInitial(:)=NaN;
df0HR{s}.HRFinal(:)=NaN;
df0HR{s}.HRall(:)=NaN;

%mtx{s}=df0HR{s};

for t=1:size(df0HR{s},1)
    
%     acc=table2array(df0HR{s}(t,2));
%     if acc<100
        
        df0HR{s}.HRInitial(t)=nanmax(ibi(trig(t)+1000:trig(t)+8000)/nanmean(ibi(trig(t)-4000:trig(t)-1))); %Average initial heart deceleration, i.e. average IBI 0-3000ms after stimuli divided by 2000ms baseline ; note: sampling rate is 2000
        df0HR{s}.HRFinal(t)=nanmin(ibi(trig(t)+1000:trig(t)+8000)/nanmean(ibi(trig(t)-4000:trig(t)-1)));%Average final heart aceleration, i.e. average IBI 3000ms-6000ms after stimuli divided by 2000ms baseline; note: sampling rate is 2000
        df0HR{s}.HRall(t)=nanmean(ibi(trig(t)+1000:trig(t)+8000)/nanmean(ibi(trig(t)-4000:trig(t)-1)));%Average total heart change, i.e. average IBI 0-6000ms after stimuli divided by 2000ms baseline; note: sampling rate is 2000
       
        heart(t,:)=ibi(trig(t):trig(t)+12000)/nanmean(ibi(trig(t)-4000:trig(t)-1));  %%get continuous heart changes to plot
        
    %end
end
av(s,:)=(nanmean(heart));

end
