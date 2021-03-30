% myDir = path .vhdr (and eeg)
% file_name = full name with .vhdr
% filepath_before = temp
% filpath_after = output
% cap = full path of locations
%function [indelec] = preprocessing_63_func(myDir,file_name,filepath_before,filepath_after,cap385)
    %% 0-  Load eeglab

    clc; close all;
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    sprintf('Preprocessing %s', file_name);
    
    %% 1-  Loading the data (all channels)

    EEG = pop_loadbv(myDir, file_name, [], []);
    EEG.setname='Original';
    EEG = eeg_checkset( EEG );
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG); % save modifications 

    %% 2- Reading channel locations

    EEG=pop_chanedit(EEG, 'lookup',cap385);
    EEG = eeg_checkset( EEG );
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG); % save modifications

    if (EEG.srate > 250)
       EEG = pop_resample(EEG, 200, 0.8, 0.4);
       EEG = eeg_checkset(EEG);
       fprintf('\n--- Performed downsampling from %s to 100 ---\n', EEG.srate);
       pop_saveset(EEG, 'filename', 'downsample.set', 'filepath', filepath_after);
    end
    
    
    %% 3- filtering - BPF [0.3 - 45 Hz]
    %HP 0.3
    EEG = pop_eegfiltnew(EEG, 'locutoff',0.3);
    EEG.setname='0.3 [Hz] HPF';
    EEG = eeg_checkset( EEG );
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);

    % 50 Hz notch ( 47.5-52.5 BSF)
    EEG = pop_eegfiltnew(EEG, 'locutoff',47.5,'hicutoff',52.5,'revfilt',1);
    EEG.setname='50 [Hz] Notch';
    EEG = eeg_checkset( EEG );
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);

    %LP 45
    EEG = pop_eegfiltnew(EEG, 'hicutoff',45);
    EEG.setname='45 [Hz] LPF';
    EEG = eeg_checkset( EEG );
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    
    pop_saveset(EEG, 'filename', '3_filter.set', 'filepath', filepath_after);

   
    %% 4- Referecence to avarage

    EEG = pop_reref( EEG, []);
    EEG.setname='Referenced';
    EEG = eeg_checkset( EEG );
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    pop_saveset(EEG, 'filename', '3_ref.set', 'filepath', filepath_after);
    
    %% 5- Reject artifact automatically
    [EEG rejected] = pop_rejcont(EEG, 'taper', 'hamming');
    EEG.rejected_samples = rejected;
    EEG.setname='Auto-rejecting samples';
    EEG = eeg_checkset( EEG );
    pop_saveset(EEG, 'filename', '4_rej_art.set', 'filepath', filepath_after);
        
    %% 6- reject automatically before decompose data by ICA

    [EEG, indelec] = pop_rejchan(EEG, 'elec',[1:EEG.nbchan] ,'threshold',5,'norm','on','measure','prob');
    EEG.rejected_channels = indelec;
    EEG.setname='after_auto_reject';
    EEG = eeg_checkset( EEG );
    [ALLEEG EEG  CURRENTSET] = eeg_store(ALLEEG, EEG);
    pop_saveset(EEG, 'filename', '5_rej_chan.set', 'filepath', filepath_after);
    %% 7- decompose by ICA

    [EEG, indelec] = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','off');
    EEG.setname='After ICA';
    EEG = eeg_checkset( EEG );
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG); % save modifications
    pop_saveset(EEG, 'filename', '6_ica.set', 'filepath', filepath_after);
    %% 8- saving dataset to library - optional for automatically saving the dataset 

    % saving the dataset to filepath before component removing
    EEG = pop_saveset( EEG, 'filename',file_name,'filepath',filepath_before);
    EEG = eeg_checkset( EEG );

    % labeling the ICAs automatically
    EEG = pop_iclabel(EEG, 'default');
    EEG = eeg_checkset( EEG );
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG); % save modifications

    % remove ICAs with 90% precent to be muscle/eye
    EEG = pop_icflag(EEG, [NaN NaN;0.9 1;0.9 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]);
    EEG = eeg_checkset( EEG );
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG); % save modifications
    pop_saveset(EEG, 'filename', '7_after_iclabel.set', 'filepath', filepath_after);

    % saving the dataset to filepath after component removing
    EEG = pop_saveset( EEG, 'filename',file_name,'filepath',filepath_after);
    EEG = eeg_checkset( EEG );
    EEG.setname='After component removing';
    %[ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG); % save modifications

% 
%     %% 9- pop the gui
% 
%      eeglab redraw
     
%end