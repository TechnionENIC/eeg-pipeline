%% ---- Configuration ----
eeglabRoot = fileparts(which('eeglab'));
pipelineSteps = ['1 BIDS Data', '2 HLPF', '3 PREP', '4 ICA', '5 IClabel', '6 Clean Label'];
% Basic tab configurtaion
studyName = 'mindfulness';
dataDir = fullfile(pwd, 'data');  % Diretory path of EEG data files
dataprotocol = 'brainVision';     % Protocol to treat EEG data
singlesubject = 'Off';            % Run pipeline on single subject
outputDir = fullfile(pwd, 'output'); % Directory Path of output save BIDS (Brain Imaging Data Structure) file structure
% This channel location is compatiable with our 64Ch actiCAP snap AP-64 layout of easycap
channelFile = fullfile(eeglabRoot, ['plugins' filesep 'dipfit' filesep 'standard_BESA' filesep 'standard-10-5-cap385.elp']); % Channel location file path
runSteps = pipelineSteps;         % Steps to run
savepoint = pipelineSteps;        % Save after those steps
plotsave = pipelineSteps;         % Plot data after those steps
numChannels = 16;
runChannels = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16];

% PREP tab configurtaion
% Harmonic line frequencies to be removed
lineFrequencies = [50,100,150,200]; % IL/EU
% Filter
lowpass = 0.3;                          % Lowpass filter Hz
highpass = 45;                          % Highpass filter Hz
notchlow = 47.5;                        % Notch low Hz
notchhigh = 52.5;                       % Notch high Hz
revfilt = 1; 

detrendCutoff = 1;
detrendStepSize = 0.02;
% Bad channel
robustDeviationThreshold = 5;      % Deviation - Extream amplitude, robust Z score cutoff for robut standard deviation  
correlationThreshold = 0.4;        % Correlation - Lack of correlation with any other channel, correlation below which window is bad
badTimeThreshold = 0.01;           %               cutoff fraction of bad corr windows
highFrequencyNoiseThreshold = 5;   % Noiseness - Unusual HF noise, z score cutoff for SNR (signal above 50 Hz)
ransacCorrelationThreshold = 0.75; % Random sample consensus (RANSAC) cutoff correlation for abnormal wrt neighbors

AutomaticrejectSwitch = "On";

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
            'lowpass', 'highpass','notchlow','notchhigh', 'revfilt', 'detrendCutoff', 'detrendStepSize', 'robustDeviationThreshold', 'correlationThreshold', 'badTimeThreshold', 'highFrequencyNoiseThreshold', ...
            'ransacCorrelationThreshold', 'brain', 'muscle', 'eye', 'heart', 'line', 'channel', 'other', 'runChannels','AutomaticrejectSwitch'};
valuesConf = {studyName, dataprotocol, singlesubject, plotsave, dataDir, channelFile, outputDir, runSteps, savepoint, lineFrequencies, ...
            lowpass, highpass, notchlow ,notchhigh, revfilt, detrendCutoff, detrendStepSize, robustDeviationThreshold, correlationThreshold, badTimeThreshold, highFrequencyNoiseThreshold, ...
            ransacCorrelationThreshold, brain, muscle, eye, heart, line, channel, other, runChannels, AutomaticrejectSwitch};
        
RunPipelineConfiguration = containers.Map(keysConf, valuesConf);   

    %  'elecrange'   - [integer array] electrode indices {Default: all electrodes} 
%  'epochlength' - [float] epoch length in seconds {Default: 0.5 s}
%  'overlap'     - [float] epoch overlap in seconds {Default: 0.25 s}
%  'freqlimit'   - [min max] frequency range too consider for thresholding
%                  Default is [35 128] Hz.
%  'threshold'   - [float] frequency upper threshold in dB {Default: 10}
%  'contiguous'  - [integer] number of contiguous epochs necessary to 
%                  label a region as artifactual {Default: 4}
%  'addlength'   - [float] once a region of contiguous epochs has been labeled
%                  as artifact, additional trailing neighboring regions on
%                  each side may also be added {Default: 0.25}
%  'eegplot'     - ['on'|'off'] plot rejected portions of data in a eegplot
%                  window. Default is 'off'.
%  'onlyreturnselection'  - ['on'|'off'] this option when set to 'on' only
%                  return the selected regions and does not remove them 
%                  from the datasets. This allow to perform quick
%                  optimization of the rejected portions of data.
%  'precompstruct' - [struct] structure containing precomputed spectrum (see
%                  Outputs) to be used instead of computing the spectrum.
%  'verbose'       - ['on'|'off'] display information. Default is 'off'.
%  'taper'         - ['none'|'hamming'] taper to use before FFT. Default is
%                    'none' for backward compatibility but 'hamming' is
%                    recommended.