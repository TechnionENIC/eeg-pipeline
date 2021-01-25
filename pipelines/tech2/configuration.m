%% ---- Configuration ----
eeglabRoot = fileparts(which('eeglab'));

% Basic tab configurtaion
studyName = 'mindfulness';
dataDir = '../../data/**/*.vhdr'; % Diretory path of EEG data files
dataprotocol = 'brainVision';     % Protocol to treat EEG data
singlesubject = 'Off';            % Run pipeline on single subject
plotsave = 'Off';                 % Plot data after each saveing point
outputDir = fullfile(pwd, 'output'); % Directory Path of output save BIDS (Brain Imaging Data Structure) file structure
% This channel location is compatiable with our 64Ch actiCAP snap AP-64 layout of easycap
channelFile = fullfile(eeglabRoot, 'plugins\dipfit3.6\standard_BESA\standard-10-5-cap385.elp'); % Channel location file path
runSteps = ['1 BIDS Data', '2 HLPF', '3 PREP', '4 ICA', '5 IClabel', '6 Clean Label'];          % Steps to run
savepoint = ['1 BIDS Data', '2 HLPF', '3 PREP', '4 ICA', '5 IClabel', '6 Clean Label'];         % Save after those steps

% PREP tab configurtaion
% Harmonic line frequencies to be removed
lineFrequencies = [50,100,150,200]; % IL/EU
% Filter
lowpass = 50;                          % Lowpass filter 50Hz
highpass = 0.1;                        % Highpass filter 0.1HZ
detrendCutoff = 1;
detrendStepSize = 0.02;
% Bad channel
robustDeviationThreshold = 5;      % Deviation - Extream amplitude, robust Z score cutoff for robut standard deviation  
correlationThreshold = 0.4;        % Correlation - Lack of correlation with any other channel, correlation below which window is bad
badTimeThreshold = 0.01;           %               cutoff fraction of bad corr windows
highFrequencyNoiseThreshold = 5;   % Noiseness - Unusual HF noise, z score cutoff for SNR (signal above 50 Hz)
ransacCorrelationThreshold = 0.75; % Random sample consensus (RANSAC) cutoff correlation for abnormal wrt neighbors

% Manually defind study events and action EEG.event.type, EEG.event.code
events = {'S  3','Stimulus';'S  1','Stimulus';'R  1','Response';'S  3','Stimulus';'S  3','Stimulus';'R  1','Response';'S  4','Stimulus';'S 10','Stimulus';'S  3','Stimulus';'S  2','Stimulus';'R  1','Response';'S  3','Stimulus';'S 14','Stimulus';'S  4','Stimulus';'S 10','Stimulus';'S  3','Stimulus';'S 12','Stimulus'};

% ICLabel artifact removal threshold
brain = 0;
muscle = 0;
eye = 0.9;
heart = 0;
line = 0;
channel = 0;
other = 0;

keysConf = {'studyName', 'dataprotocol', 'singlesubject', 'plotsave', 'dataDir', 'channelFile', 'outputDir', 'runSteps', 'savepoint', 'lineFrequencies', ...
            'lowpass', 'highpass', 'detrendCutoff', 'detrendStepSize', 'robustDeviationThreshold', 'correlationThreshold', 'badTimeThreshold', 'highFrequencyNoiseThreshold', ...
            'ransacCorrelationThreshold', 'brain', 'muscle', 'eye', 'heart', 'line', 'channel', 'other'};
valuesConf = {studyName, dataprotocol, singlesubject, plotsave, dataDir, channelFile, outputDir, runSteps, savepoint, lineFrequencies, ...
            lowpass, highpass, detrendCutoff, detrendStepSize, robustDeviationThreshold, correlationThreshold, badTimeThreshold, highFrequencyNoiseThreshold, ...
            ransacCorrelationThreshold, brain, muscle, eye, heart, line, channel, other};
RunPipelineConfiguration = containers.Map(keysConf, valuesConf);   