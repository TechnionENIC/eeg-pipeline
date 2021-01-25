% TODO: check if following two lines needed, after GUI implementation
%clear; % clear workspace
%close all;
clc; % clear command window

% TODO: validation of required plugins
requiredPlugins = ['ICLabel' 'PrepPipeline0.55.4' 'SIFT1.52', 'dipfit3.6'];

[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

rawDataFiles = dir(RunPipelineConfiguration('dataDir'));

% Iterate over entire subject data (probably worth testing it on 2 before running on all subjects)
numOfSubjects = 2;
if (RunPipelineConfiguration('singlesubject') == "Off")
    numOfSubjects = length(rawDataFiles); 
end
    
fprintf('\n--- Start processing %d subjects ---\n', numOfSubjects);
parfor n=1:numOfSubjects
    filename = rawDataFiles(n).name;
    fprintf('\n--- Processing subject %d (%s) ---\n', n, filename);
        
    %% - Step 1: Importing raw data or .set data structure for each subject
    if (contains(RunPipelineConfiguration('runSteps'), "1"))
        fprintf('\n--- Step 1: Building EEGLab data structure [subject %d] ---\n', n);
        % Convert & load by specified datastructure protocol into EEGLAB
        switch RunPipelineConfiguration('dataprotocol')
            case 'brainVision'
                EEG = pop_loadbv(rawDataFiles(n).folder, filename);
            case 'EEGLab set'    
                EEG = pop_loadset(rawDataFiles(n).folder, filename);
            case 'emotive'
                % TODO: get real emotive file to check how we upload
                EEG = pop_loadbv(rawDataFiles(n).folder, filename);
        end
        
        % Load auto channel location
        EEG = pop_chanedit(EEG, 'lookup', channelFile, 'load', []);

        % Remove file extention from file name
        setname = filename(1:end-5);
        EEG.setname = setname;

        % BIDS (Brain Imaging Data Structure) folder directory, study -> subjectN -> subjectN.set  
        subjectOutputPath = fullfile(RunPipelineConfiguration('outputDir'), RunPipelineConfiguration('studyName'), EEG.setname);
        mkdir(subjectOutputPath);

        % Save #1 - raw data as EEG dataset structure
        if (contains(RunPipelineConfiguration('savepoint'), "1"))
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
    if (contains(RunPipelineConfiguration('runSteps'), "2"))
        fprintf('\n--- Step 2: Highpass & Lowpass filter [subject %d] ---\n', n);
        % Highpass filter 0.1hz
        EEG = pop_eegfiltnew(EEG, [], RunPipelineConfiguration('highpass'), [], false, [], 0);
        % Lowpass filter 50hz
        EEG = pop_eegfiltnew(EEG, [], RunPipelineConfiguration('lowpass'), [], false, [], 0);
        % Save #2 - raw data as EEG dataset structure
        if (contains(RunPipelineConfiguration('savepoint'), "2"))
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
    
    if (contains(RunPipelineConfiguration('runSteps'), "3"))
        fprintf('\n--- Step 3: Clean raw data using PREP preprocessing pipeline [subject %d] ---\n', n);
        reportHTMLOutputPath = fullfile(RunPipelineConfiguration('outputDir'), RunPipelineConfiguration('studyName'), EEG.setname, strcat(EEG.setname,'.html'));
        reportPDFOutputPath = fullfile(RunPipelineConfiguration('outputDir'), RunPipelineConfiguration('studyName'), EEG.setname, strcat(EEG.setname,'.pdf'));
        EEG = pop_prepPipeline(EEG, struct('ignoreBoundaryEvents', true, ...
                                      'detrendCutoff', RunPipelineConfiguration('detrendCutoff'), ...
                                      'detrendStepSize', RunPipelineConfiguration('detrendStepSize'), ...
                                      'ransacCorrelationThreshold', RunPipelineConfiguration('ransacCorrelationThreshold'), ...
                                      'robustDeviationThreshold', RunPipelineConfiguration('robustDeviationThreshold'), ...
                                      'highFrequencyNoiseThreshold', RunPipelineConfiguration('highFrequencyNoiseThreshold'), ... 
                                      'correlationThreshold', RunPipelineConfiguration('correlationThreshold'), ...
                                      'badTimeThreshold', RunPipelineConfiguration('badTimeThreshold'), ...
                                      'sessionFilePath', reportPDFOutputPath, ...
                                      'summaryFilePath', reportHTMLOutputPath, ...
                                      'consoleFID', 1, ...
                                      'cleanupReference', true, ...
                                      'keepFiltered', true, ...
                                      'removeInterpolatedChannels', false));

        % Alternative preprocessing option with "clear_rawdata"                          
        % EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',4,'Highpass','off','BurstCriterion',20,'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian','WindowCriterionTolerances',[-Inf 7] );
        EEG = eeg_checkset(EEG);

        % Save #3 - Dataset after preprocessing
        if (contains(RunPipelineConfiguration('savepoint'), "3"))
            EEG = pop_saveset(EEG, 'filename', [EEG.setname '_3_prep.set'], 'filepath', subjectOutputPath);
        end
    end
    
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
    % The command below does the automated rejection (the pop_select command after that includes manual editing)
    %EEG = pop_rejcont(EEG, 'elecrange', [1:64] , ...
    %                       'freqlimit', [20 40] , ...
    %                       'threshold', 10, ... 
    %                       'epochlength', 0.5, ...
    %                       'contiguous', 4, ...
    %                       'addlength', 0.25, ...
    %                       'taper', 'hamming');
    % EEG = pop_select( EEG, 'nopoint',[321 480;3489 3936;4289 4608;7713 7904;13505 13664;26561 26816;27201 27360;27553 27840;28033 28544]);
    
    %% - Step 4: Run Independent component analysis (ICA)
    % Run ICA
    if (contains(RunPipelineConfiguration('runSteps'), "4"))
        fprintf('\n--- Step 4: Run Independent component analysis (ICA) [subject %d] ---\n', n);
        EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'interrupt', 'off');
        EEG = eeg_checkset(EEG);

        % Save #4 - Dataset with ICA weights
        if (contains(RunPipelineConfiguration('savepoint'), "4"))
            EEG = pop_saveset(EEG, 'filename', [EEG.setname '_4_ica.set'], 'filepath', subjectOutputPath);
        end
    end
    
    %% - Step 5: Run ICLabel to identify artifact sources: 'Brain' 'Muscle' 'Eye' 'Heart' 'Line Noise' 'Channel Noise' 'Other', with configured probability
    % Run ICLabel (Pion-Tonachini et al., 2019)
    if (contains(RunPipelineConfiguration('runSteps'), "5"))
        fprintf('\n--- Step 5: Running ICLabel [subject %d] ---\n', n);
        EEG = iclabel(EEG, 'default');
        EEG = eeg_checkset(EEG);
    end
    
    %% - Step 6: Remove ICA artifacts by thresholds defined above
    % Remove ICLabel artifacts
    if (contains(RunPipelineConfiguration('runSteps'), "6"))
        fprintf('\n--- Step 6: Remove ICA artifacts by thresholds defined above [subject %d] ---\n', n);
        icflagThresh = [0 0;0 0; RunPipelineConfiguration("eye") 1; 0 0; 0 0; 0 0; 0 0];
      
        EEG = pop_icflag(EEG, icflagThresh);
        EEG = eeg_checkset(EEG);
    end
    
    %% - Step 7: Run SIFT pipeline
    
    % Translate to bands
    %figure; pop_spectopo(EEG, 1, [0  252048], 'EEG' , 'percent', 50, 'freq', [6 10 22], 'freqrange', [2 25], 'electrodes', 'on');
    
    % This example Matlab code shows how to compute power spectrum of epoched data, channel 2.
    %[spectra,freqs] = spectopo(EEG.data(2,:,:), 0, EEG.srate);

    % Set the following frequency bands: delta=1-4, theta=4-8, alpha=8-13, beta=13-30, gamma=30-80.
    
	% Save #5 - Dataset with model and connectivity
    if (contains(RunPipelineConfiguration('savepoint'), "5"))
        EEG = pop_saveset(EEG, 'filename', [EEG.setname '_5_final.set'], 'filepath', subjectOutputPath);
    end
    %[ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, n); 
end
eeglab redraw
