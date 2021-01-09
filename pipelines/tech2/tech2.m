clear; % clear workspace
close all;
clc; % clear command window

eeglabRoot = fileparts(which('eeglab'));

%% ---- Configuration ----

% TODO: get all configuration data from GUI
% TODO: validation of required plugins
requiredPlugins = ['ICLabel' 'PrepPipeline0.55.4' 'SIFT1.52', 'dipfit3.6'];

studyName = 'mindfulness';
% Filter file that are not BrainVision header files
rawDataFiles = dir('../../data/**/*.vhdr');
% Directory where we want to save BIDS (Brain Imaging Data Structure) file structure
outputPath = fullfile(pwd, 'output');
% This channel location is compatiable with our 64Ch actiCAP snap AP-64 layout of easycap
pathToChannelLocationFile = fullfile(eeglabRoot, 'plugins\dipfit3.6\standard_BESA\standard-10-5-cap385.elp');

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

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% Iterate over entire subject data (probably worth testing it on 2 before running on all subjects) 
numOfSubjects = 2;
%numOfSubjects = length(rawDataFiles);
fprintf('\n--- Start processing %d subjects ---\n', numOfSubjects);
parfor n=1:numOfSubjects    
    filename = rawDataFiles(n).name;
    fprintf('\n--- Processing subject %d (%s) ---\n', n, filename);
        
    %% - Step 1: Importing raw BrainVision data and create .set data structure for each subject
    if (ismember(1, runSteps))
        fprintf('\n--- Step 1: Building EEGLab data structure [subject %d] ---\n', n);
        % Convert & load BrainVision datastructure into EEGLAB 
        EEG = pop_loadbv(rawDataFiles(n).folder, filename);

        % Load auto channel location
        EEG = pop_chanedit(EEG, 'lookup', pathToChannelLocationFile, 'load', []);

        % Remove file extention from file name
        setname = filename(1:end-5);
        EEG.setname = setname;

        % BIDS (Brain Imaging Data Structure) folder directory, study -> subjectN -> subjectN.set  
        subjectOutputPath = fullfile(outputPath, studyName, EEG.setname);
        mkdir(subjectOutputPath);

        % Save #1 - raw data as EEG dataset structure
        if (ismember(1, savepoint))
            EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', subjectOutputPath);
        end
        %[ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, n); 
        
        try
            disp(EEG.event(2));
            disp(EEG.event(18));
        catch e
            warning('Problem with event');
        end
    end
    
    %% - Step 2: Highpass & Lowpass filter
    if (ismember(2, runSteps))
        fprintf('\n--- Step 2: Highpass & Lowpass filter [subject %d] ---\n', n);
        % Highpass filter 0.1hz
        EEG = pop_eegfiltnew(EEG, [], highpass, [], false, [], 0);
        % Lowpass filter 50hz
        EEG = pop_eegfiltnew(EEG, [], lowpass, [], false, [], 0);
        % Save #2 - raw data as EEG dataset structure
        if (ismember(2, savepoint))
            EEG = pop_saveset(EEG, 'filename', [EEG.setname '_2_hlpf.set'], 'filepath', subjectOutputPath);
        end
    end
    
    %% - Step 3: Clean raw data using PREP preprocessing pipeline
    % Run PREP pipeline
    % See param information and default values http://vislab.github.io/EEG-Clean-Tools/
    % 1. Handle boundary events prior to processing
    % 2. Remove trend (high pass) temporarily to properly compute thresholds
    % 3. Remove line noise without committing to a filtering strategy
    % 4. Robustly reference the signal relative to an estimate of the “true” average reference
    % 5. Detect and interpolate bad channels relative to this reference
    % 6. Produce reports if desired
    % 7. Post process if desired
    
    % TODO: create another save point after/before average - one channel
    % snapshot image send to Michal, also before and after cutting time artifacts, run it beofre ICA (see suggested pipeline of EEGLAB) 
    % 
    if (ismember(3, runSteps))
        fprintf('\n--- Step 3: Clean raw data using PREP preprocessing pipeline [subject %d] ---\n', n);
        reportHTMLOutputPath = fullfile(outputPath, studyName, EEG.setname, strcat(EEG.setname,'.html'));
        reportPDFOutputPath = fullfile(outputPath, studyName, EEG.setname, strcat(EEG.setname,'.pdf'));
        EEG = pop_prepPipeline(EEG, struct('ignoreBoundaryEvents', true, ...
                                      'detrendCutoff', detrendCutoff, ...
                                      'detrendStepSize', detrendStepSize, ...
                                      'ransacCorrelationThreshold', ransacCorrelationThreshold, ...
                                      'robustDeviationThreshold', robustDeviationThreshold, ...
                                      'highFrequencyNoiseThreshold', highFrequencyNoiseThreshold, ... 
                                      'correlationThreshold', correlationThreshold, ...
                                      'badTimeThreshold', badTimeThreshold, ...
                                      'sessionFilePath', reportPDFOutputPath, ...
                                      'summaryFilePath', reportHTMLOutputPath, ...
                                      'consoleFID', 1, ...
                                      'cleanupReference', false, ...
                                      'keepFiltered', true, ...
                                      'removeInterpolatedChannels', false));

        % Alternative preprocessing option with "clear_rawdata"                          
        % EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',4,'Highpass','off','BurstCriterion',20,'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian','WindowCriterionTolerances',[-Inf 7] );
        EEG = eeg_checkset(EEG);

        % Save #3 - Dataset after preprocessing
        if (ismember(3, savepoint))
            EEG = pop_saveset(EEG, 'filename', [EEG.setname '_3_prep.set'], 'filepath', subjectOutputPath);
        end
    end
    
    %% - Step 4: Run Independent component analysis (ICA)
    % Run ICA
    if (ismember(4, runSteps))
        fprintf('\n--- Step 4: Run Independent component analysis (ICA) [subject %d] ---\n', n);
        EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'interrupt', 'off');
        EEG = eeg_checkset(EEG);

        % Save #4 - Dataset with ICA weights
        if (ismember(4, savepoint))
            EEG = pop_saveset(EEG, 'filename', [EEG.setname '_4_ica.set'], 'filepath', subjectOutputPath);
        end
    end
    
    %% - Step 5: Run ICLabel to identify artifact sources: 'Brain' 'Muscle' 'Eye' 'Heart' 'Line Noise' 'Channel Noise' 'Other', with configured probability
    % Run ICLabel (Pion-Tonachini et al., 2019)
    if (ismember(5, runSteps))
        fprintf('\n--- Step 5: Running ICLabel [subject %d] ---\n', n);
        EEG = iclabel(EEG, 'default');
        EEG = eeg_checkset(EEG);
    end
    
    %% - Step 6: Remove ICA artifacts by thresholds defined above
    % Remove ICLabel artifacts
    if (ismember(6, runSteps))
        fprintf('\n--- Step 6: Remove ICA artifacts by thresholds defined above [subject %d] ---\n', n);
        EEG = pop_icflag(EEG, icflagThresh);
        EEG = eeg_checkset(EEG);
    end
    
    % Split into events
    % events
    
    % Translate to bands
    %figure; pop_spectopo(EEG, 1, [0  252048], 'EEG' , 'percent', 50, 'freq', [6 10 22], 'freqrange', [2 25], 'electrodes', 'on');
    
    % This example Matlab code shows how to compute power spectrum of epoched data, channel 2.
    %[spectra,freqs] = spectopo(EEG.data(2,:,:), 0, EEG.srate);

    % Set the following frequency bands: delta=1-4, theta=4-8, alpha=8-13, beta=13-30, gamma=30-80.
    
    % The command below does the automated rejection (the pop_select command after that includes manual editing)
    %EEG = pop_rejcont(EEG, 'elecrange', [1:64] , ...
    %                       'freqlimit', [20 40] , ...
    %                       'threshold', 10, ... 
    %                       'epochlength', 0.5, ...
    %                       'contiguous', 4, ...
    %                       'addlength', 0.25, ...
    %                       'taper', 'hamming');
     
    %% - Step 7: Run SIFT pipeline
    
	% Save #5 - Dataset with model and connectivity
    if (ismember(5, savepoint))
        EEG = pop_saveset(EEG, 'filename', [EEG.setname '_5_final.set'], 'filepath', subjectOutputPath);
    end
    %[ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, n); 
end
eeglab redraw
