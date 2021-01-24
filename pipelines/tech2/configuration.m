%% ---- Configuration ----
eeglabRoot = fileparts(which('eeglab'));

studyName = 'mindfulness';

% Diretory where EEG data is present
dataDir = '../../data/**/*.vhdr';

dataprotocol = 'brainVision';

singlesubject = 'off';

plotsave = 'off';
% Directory where we want to save BIDS (Brain Imaging Data Structure) file structure
outputDir = fullfile(pwd, 'output');

% This channel location is compatiable with our 64Ch actiCAP snap AP-64 layout of easycap
channelFile = fullfile(eeglabRoot, 'plugins\dipfit3.6\standard_BESA\standard-10-5-cap385.elp');

% TODO: write warnning when savepoint is not in runSteps
% Which steps to run?
runSteps = [1 2 3 4 5 6];
% Save dataset after which steps?
savepoint = [1 2 3 4 5];

% PREP preprocessing configuration
% Harmonic line frequencies to be removed
% IL/EU
lineFrequencies = [50  100  150  200];
% US
%lineFrequencies = [50  60  100  120  150  180  200  240];

% HPF & LPF
lowpass = 50; % Lowpass filter 30 Hz
highpass = 0.1; % Highpass filter 0.1HZ

detrendCutoff = 1;
detrendStepSize = 0.02;

% Bad channel
robustDeviationThreshold = 5;      % Deviation - Extream amplitude, robust Z score cutoff for robut standard deviation  
correlationThreshold = 0.4;        % Correlation - Lack of correlation with any other channel, correlation below which window is bad
badTimeThreshold = 0.01;           %               cutoff fraction of bad corr windows
highFrequencyNoiseThreshold = 5;   % Noiseness - Unusual HF noise, z score cutoff for SNR (signal above 50 Hz)
ransacCorrelationThreshold = 0.75; % Random sample consensus (RANSAC) cutoff correlation for abnormal wrt neighbors

% Details about how bad channel removal works
% -------------------------------------------
% In the output reports you can view:
%    noisyChannels               - list of identified bad channel numbers
%    badChannelsFromCorrelation  - list of bad channels identified by correlation
%    badChannelsFromDeviation    - list of bad channels identified by amplitude
%    badChannelsFromHFNoise      - list of bad channels identified by SNR
%    badChannelsFromRansac       - list of channels identified by ransac
% Method 1: too low or high amplitude. If the z score of robust
%           channel deviation falls below robustDeviationThreshold, the channel is
%           considered to be bad.
% Method 2: too low an SNR. If the z score of estimate of signal above
%           50 Hz to that below 50 Hz above highFrequencyNoiseThreshold, the channel
%           is considered to be bad.
% Method 3: low correlation with other channels. Here correlationWindowSize is the window
%           size over which the correlation is computed. If the maximum
%           correlation of the channel to the other channels falls below
%           correlationThreshold, the channel is considered bad in that window.
%           If the fraction of bad correlation windows for a channel
%           exceeds badTimeThreshold, the channel is marked as bad.
%
% After the channels from methods 2 and 3 are removed, method 4 is
% computed on the remaining signals
%
% Method 4: each channel is predicted using ransac interpolation based
%           on a ransac fraction of the channels. If the correlation of
%           the prediction to the actual behavior is too low for too
%           long, the channel is marked as bad.


% TODO: flag for manual/automatic rejection of sections
% TODO: Verify ICA after removal of eye movements and view the channel
% after.

% Manually defind study events and action EEG.event.type, EEG.event.code
events = {'S  3','Stimulus';'S  1','Stimulus';'R  1','Response';'S  3','Stimulus';'S  3','Stimulus';'R  1','Response';'S  4','Stimulus';'S 10','Stimulus';'S  3','Stimulus';'S  2','Stimulus';'R  1','Response';'S  3','Stimulus';'S 14','Stimulus';'S  4','Stimulus';'S 10','Stimulus';'S  3','Stimulus';'S 12','Stimulus'};

% ICLabel artifact removal threshold
% Each array cell compose of min & max probability value for certain artifact
% default is at least 90% probability for Eye classification 
% According to order: Brain, Muscle, Eye, Heart, Line Noise, Channel Noise, Other.
icflagThresh = [0 0;0 0; 0.9 1; 0 0; 0 0; 0 0; 0 0];

keysConf = {'studyName', 'dataprotocol', 'singlesubject', 'plotsave', 'dataDir', 'channelFile', 'outputDir', 'runSteps', 'savepoint', 'lineFrequencies', ...
        'lowpass', 'highpass', 'detrendCutoff', 'detrendStepSize', 'robustDeviationThreshold', ...
        'correlationThreshold', 'badTimeThreshold', 'highFrequencyNoiseThreshold', 'ransacCorrelationThreshold'};

valuesConf = {studyName, dataprotocol, singlesubject, plotsave, dataDir, channelFile, outputDir, runSteps, savepoint, lineFrequencies, ...
        lowpass, highpass, detrendCutoff, detrendStepSize, robustDeviationThreshold, ...
        correlationThreshold, badTimeThreshold, highFrequencyNoiseThreshold, ransacCorrelationThreshold};

RunPipelineConfiguration = containers.Map(keysConf, valuesConf);   