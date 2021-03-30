% TODO: check if following two lines needed, after GUI implementation
%clear; % clear workspace
%close all;
clc; % clear command window

% TODO: validation of required plugins
requiredPlugins = ['ICLabel' 'PrepPipeline0.55.4' 'SIFT1.52', 'dipfit3.6'];

[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

switch RunPipelineConfiguration('dataprotocol')
    case 'brainVision'
        rawDataFiles = dir(RunPipelineConfiguration('dataDir') + "/**/*.vhdr");
        suffixLength = 5;
    case 'EEGLab set'    
        rawDataFiles = dir(RunPipelineConfiguration('dataDir') + "/**/*.set"); 
        suffixLength = 4;
    case 'emotive'
        rawDataFiles = dir(RunPipelineConfiguration('dataDir') + "/**/*.edf");
        suffixLength = 4;
end


% Iterate over entire subject data 
% Tip: Switch singlesubject On for first time test
% as it worth testing it on 1 before running on all subjects
numOfSubjects = 1;
if (RunPipelineConfiguration('singlesubject') == "Off")
    numOfSubjects = length(rawDataFiles); 
end
    
fprintf('\n--- Start processing %d subjects ---\n', numOfSubjects);
% parfor n=1:numOfSubjects
for n=1:numOfSubjects
    filename = rawDataFiles(n).name;
    fprintf('\n--- Processing subject %d (%s) ---\n', n, filename);
        
    %% - Step 1: Importing raw data or .set data structure for each subject
    if any(contains(RunPipelineConfiguration('runSteps'), "1"))
        fprintf('\n--- Step 1: Building EEGLab data structure [subject %d] ---\n', n);
        % Convert & load by specified datastructure protocol into EEGLAB
        pathRawDataFile = [rawDataFiles(n).folder filesep filename];
        switch RunPipelineConfiguration('dataprotocol')
            case 'brainVision'
                EEG = pop_loadbv(rawDataFiles(n).folder, filename);
            case 'EEGLab set'    
                EEG = pop_loadset(pathRawDataFile);
            case 'emotive'
                EEG = pop_biosig(pathRawDataFile);
        end
        
        % Load auto channel location
        EEG = pop_chanedit(EEG, 'lookup', RunPipelineConfiguration('channelFile'), 'load', []);

        % Remove file extention from file name
        setname = filename(1:end-suffixLength);
        EEG.setname = setname;

        % BIDS (Brain Imaging Data Structure) folder directory, study -> subjectN -> subjectN.set  
        subjectOutputPath = fullfile(RunPipelineConfiguration('outputDir'), RunPipelineConfiguration('studyName'), EEG.setname);
        mkdir(subjectOutputPath);

        % Save #1 - raw data as EEG dataset structure
        if any(contains(RunPipelineConfiguration('savepoint'), "1"))
            EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', subjectOutputPath);
            if any(contains(RunPipelineConfiguration('plotsave'), "1"))
                pop_eegplot(EEG, 1, 1, 1);
            end
        end
    end
    
    if (EEG.srate > 250)
       EEG = pop_resample(EEG, 200, 0.8, 0.4);
       EEG = eeg_checkset(EEG);
       fprintf('\n--- Performed downsampling from %s to 100 ---\n', EEG.srate);
       EEG = pop_saveset(EEG, 'filename', [EEG.setname '_downsample.set'], 'filepath', subjectOutputPath);
    end
    
    %% - Step 2: Highpass & Lowpass filter
    if any(contains(RunPipelineConfiguration('runSteps'), "2"))
        fprintf('\n--- Step 2: Highpass & Lowpass filter [subject %d] ---\n', n);
        % Highpass filter Hz
        EEG = pop_eegfiltnew(EEG, 'locutoff', RunPipelineConfiguration("lowpass"));
        EEG = eeg_checkset(EEG);

        % Notch filter Hz
        EEG = pop_eegfiltnew(EEG, 'locutoff', RunPipelineConfiguration("notchlow"), 'hicutoff', RunPipelineConfiguration("notchhigh"), 'revfilt',RunPipelineConfiguration("revfilt"));
        EEG = eeg_checkset(EEG);

        % Lowpass filter Hz
        EEG = pop_eegfiltnew(EEG, 'hicutoff', RunPipelineConfiguration("highpass"));
        EEG = eeg_checkset(EEG);

        % Save #2 - raw data as EEG dataset structure
        if any(contains(RunPipelineConfiguration('savepoint'), "2"))
            EEG = pop_saveset(EEG, 'filename', [EEG.setname '_2_hlpf.set'], 'filepath', subjectOutputPath);
            if any(contains(RunPipelineConfiguration('plotsave'), "2"))
                pop_eegplot(EEG, 1, 1, 1);
            end
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
 
    if any(contains(RunPipelineConfiguration('runSteps'), "3"))
        fprintf('\n--- Step 3: Clean raw data using PREP preprocessing pipeline [subject %d] ---\n', n);
        reportHTMLOutputPath = fullfile(subjectOutputPath, 'prep.html');
        EEG = pop_prepPipeline(EEG, struct('ignoreBoundaryEvents', true, ...
                                      'detrendCutoff', RunPipelineConfiguration('detrendCutoff'), ...
                                      'detrendStepSize', RunPipelineConfiguration('detrendStepSize'), ...
                                      'ransacCorrelationThreshold', RunPipelineConfiguration('ransacCorrelationThreshold'), ...
                                      'robustDeviationThreshold', RunPipelineConfiguration('robustDeviationThreshold'), ...
                                      'highFrequencyNoiseThreshold', RunPipelineConfiguration('highFrequencyNoiseThreshold'), ... 
                                      'correlationThreshold', RunPipelineConfiguration('correlationThreshold'), ...
                                      'badTimeThreshold', RunPipelineConfiguration('badTimeThreshold'), ...
                                      'summaryFilePath', reportHTMLOutputPath, ...
                                      'consoleFID', 1, ...
                                      'cleanupReference', true, ...
                                      'keepFiltered', true, ...
                                      'removeInterpolatedChannels', false));

        % Alternative preprocessing option with "cleanLineNoise "                          
%         signal      = struct('data', EEG.data, 'srate', EEG.srate);
%         lineNoiseIn = struct('lineNoiseMethod', 'clean', ...
%                              'lineNoiseChannels', 1:EEG.nbchan,...
%                              'Fs', EEG.srate, ...
%                              'lineFrequencies', [60 120 180 240],...
%                              'p', 0.01, ...
%                              'fScanBandWidth', 2, ...
%                              'taperBandWidth', 2, ...
%                              'taperWindowSize', 4, ...
%                              'taperWindowStep', 1, ...
%                              'tau', 100, ...
%                              'pad', 2, ...
%                              'fPassBand', [0 EEG.srate/2], ...
%                              'maximumIterations', 10);
%         [clnOutput, lineNoiseOut] = cleanLineNoise(signal, lineNoiseIn);
%         EEG.data = clnOutput.data;   
    % Step 7: Apply clean_rawdata() to reject bad channels and correct continuous data using Artifact Subspace Reconstruction (ASR). 
    % Note 'availableRAM_GB' is for clean_rawdata1.10. For any newer version, it will cause error.
%     originalEEG = EEG;
%     EEG = clean_rawdata(EEG, 5, -1, 0.85, 4, 20, 0.25, 'availableRAM_GB', 8);
%  
%     % Step 8: Interpolate all the removed channels
%     EEG = pop_interp(EEG, originalEEG.chanlocs, 'spherical');
    % Step 9: Re-reference the data to average
%     EEG.nbchan = EEG.nbchan+1;
%     EEG.data(end+1,:) = zeros(1, EEG.pnts);
%     EEG.chanlocs(1,EEG.nbchan).labels = 'initialReference';
%     EEG = pop_reref(EEG, []);
%     EEG = pop_select( EEG,'nochannel',{'initialReference'});
%  
        EEG = eeg_checkset(EEG);

        % Save #3 - Dataset after preprocessing
        if any(contains(RunPipelineConfiguration('savepoint'), "3"))
            EEG = pop_saveset(EEG, 'filename', [EEG.setname '_3_prep.set'], 'filepath', subjectOutputPath);
            if any(contains(RunPipelineConfiguration('plotsave'), "3"))
                pop_eegplot( EEG, 1, 1, 1);
            end
        end
    end
    
    %% - Step X: Automated reject sectors
    % The command below does the automated rejection (the pop_select command after that includes manual editing)
    if (contains(RunPipelineConfiguration('AutomaticrejectSwitch'), "On"))
          fprintf('\n--- Step 4: Run Independent component analysis (ICA) [subject %d] ---\n', n);
        % Using new ASR & Clean_rawdata
        EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',4,'Highpass','off','BurstCriterion',20,'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian','WindowCriterionTolerances',[-Inf 7] );
        % Using old eeglab method
        %EEG = pop_rejcont(EEG, 'taper', 'hamming');
        %EEG.rejected_samples = rejected;
        EEG = eeg_checkset( EEG );
    end
    
    %% - Step 4: Run Independent component analysis (ICA)
    % Run ICA
    if any(contains(RunPipelineConfiguration('runSteps'), "4"))
        fprintf('\n--- Step 4: Run Independent component analysis (ICA) [subject %d] ---\n', n);
        EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'interrupt', 'off');
        EEG = eeg_checkset(EEG);

        % Save #4 - Dataset with ICA weights
        if any(contains(RunPipelineConfiguration('savepoint'), "4"))
            EEG = pop_saveset(EEG, 'filename', [EEG.setname '_4_ica.set'], 'filepath', subjectOutputPath);
            if any(contains(RunPipelineConfiguration('plotsave'), "4"))
                pop_eegplot(EEG, 1, 1, 1);
            end
        end
    end
    
    %% - Step 5: Run ICLabel to identify artifact sources: 'Brain' 'Muscle' 'Eye' 'Heart' 'Line Noise' 'Channel Noise' 'Other', with configured probability
    % Run ICLabel (Pion-Tonachini et al., 2019)
    if any(contains(RunPipelineConfiguration('runSteps'), "5"))
        fprintf('\n--- Step 5: Running ICLabel [subject %d] ---\n', n);
        EEG = iclabel(EEG, 'default');
        EEG = eeg_checkset(EEG);
        
        % Save #5 - Dataset with ICLabel weights
        if any(contains(RunPipelineConfiguration('savepoint'), "5"))
            EEG = pop_saveset(EEG, 'filename', [EEG.setname '_5_iclabel.set'], 'filepath', subjectOutputPath);
            if any(contains(RunPipelineConfiguration('plotsave'), "5"))
                pop_eegplot(EEG, 1, 1, 1);
            end
        end
    end
    
    %% - Step 6: Remove ICA artifacts by thresholds defined above
    % Remove ICLabel artifacts
    if any(contains(RunPipelineConfiguration('runSteps'), "6"))
        fprintf('\n--- Step 6: Remove ICA artifacts by thresholds defined above [subject %d] ---\n', n);
        icflagThresh = [0 0;0 0; RunPipelineConfiguration("eye") 1; 0 0; 0 0; 0 0; 0 0];
      
        EEG = pop_icflag(EEG, icflagThresh);
        EEG = eeg_checkset(EEG);
        
        % Save #6 - Dataset remove ICLabel weights
        if any(contains(RunPipelineConfiguration('savepoint'), "6"))
            EEG = pop_saveset(EEG, 'filename', [EEG.setname '_6_remove_iclabel.set'], 'filepath', subjectOutputPath);
            if any(contains(RunPipelineConfiguration('plotsave'), "6"))
                pop_eegplot(EEG, 1, 1, 1);
            end
        end
    end
    
    % Translate to bands
    %figure; pop_spectopo(EEG, 1, [0  252048], 'EEG' , 'percent', 50, 'freq', [6 10 22], 'freqrange', [2 25], 'electrodes', 'on');

[spectra,freqs] = spectopo(EEG.data, 0, EEG.srate);
% 
% % delta=1-4, theta=4-8, alpha=8-13, beta=13-30, gamma=30-80
% deltaIdx = find(freqs>1 & freqs<4);
% thetaIdx = find(freqs>4 & freqs<8);
% alphaIdx = find(freqs>8 & freqs<13);
% betaIdx  = find(freqs>13 & freqs<30);
% gammaIdx = find(freqs>30 & freqs<80);
% 
% % compute absolute power
% deltaPower = mean(10.^(spectra(deltaIdx)/10));
% thetaPower = mean(10.^(spectra(thetaIdx)/10));
% alphaPower = mean(10.^(spectra(alphaIdx)/10));
% betaPower  = mean(10.^(spectra(betaIdx)/10));
% gammaPower = mean(10.^(spectra(gammaIdx)/10));
% %%%%%%%%%%%%%%%%%
    % This example Matlab code shows how to compute power spectrum of epoched data, channel 2.
    %[spectra,freqs] = spectopo(EEG.data, 0, EEG.srate);

    % Set the following frequency bands: delta=1-4, theta=4-8, alpha=8-13, beta=13-30, gamma=30-80.
    
	% Save #5 - Dataset with model and connectivity
    if any(contains(RunPipelineConfiguration('savepoint'), "5"))
        EEG = pop_saveset(EEG, 'filename', [EEG.setname '_5_final.set'], 'filepath', subjectOutputPath);
        if any(contains(RunPipelineConfiguration('plotsave'), "5"))
                pop_eegplot(EEG, 1, 1, 1);
        end
    end
    
    %% - Step 7: Run SIFT pipeline
    %[ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, n); 
end
