% This function get data sae and go over it's elements and split the signal
% to story event or control event
% envolve_resting = 0 - No / 1 - yes
function [data_set_o] = splitToEvents(data_set, envolve_resting)
    data_set_o = [];
    event = struct;
    for i = 1:size(data_set,2)
        EEG = data_set(i);
        EEGLAB = EEG.data;% struct of eeglab
        eeg_data = EEGLAB.data;
        eeg_times = EEGLAB.times;
        triggers = EEGLAB.urevent;
        triggers_names = {triggers.type};
        triggers_ind = cell2mat({triggers.latency});
        
        
        %remove section before "R  1" (it a duplicate of the privious ind)
        ind = strcmp(triggers_names,'R  1');
        ind_rmv = find(ind == 1);
        triggers_names(ind_rmv-1) = [];
        triggers_ind(ind_rmv-1) = [];
        % split the data to story sections
        triggers_length = triggers_ind(3:end)-triggers_ind(2:end-1);
        ind = strcmp(triggers_names,'S  3');
        ind_story = find(ind == 1);
        %ind_story = find((triggers_length(ind_maybe_story-1)<2500) & triggers_length(ind_maybe_story)>14000);
        triggers_ind_story_end = zeros(size(ind_story));
        if envolve_resting == 1
            triggers_ind_story_start = triggers_ind(ind_story);
        else
            triggers_ind_story_start = triggers_ind(ind_story+1);
        end
        if (ind_story(end)+2 > size(triggers_names,2))
            triggers_ind_story_end(1:end-1) = triggers_ind(ind_story(1:end-1)+2);
            triggers_ind_story_end(end) = size(eeg_data,2);
        else
            triggers_ind_story_end = triggers_ind(ind_story+2);
        end
        % split the data to control sections
        ind = strcmp(triggers_names,'S  4');
        ind_control = find(ind == 1);
        triggers_ind_control_end = zeros(size(ind_control));
        if envolve_resting == 1
            triggers_ind_control_start = triggers_ind(ind_control);
        else
            triggers_ind_control_start = triggers_ind(ind_control+1);
        end
        if (ind_control(end)+2 > size(triggers_names,2))
            triggers_ind_control_end(1:end-1) = triggers_ind(ind_control(1:end-1)+2);
            triggers_ind_control_end(end) = size(eeg_data,2);
        else
            triggers_ind_control_end = triggers_ind(ind_control(1:end)+2);
        end
        % now we have 4 vectors, 2 for the start and the end of stories
        % blocks and 2 for start and end of controls blocks
        for k =1:size(triggers_ind_story_start,2)
            event.name = EEG.file_name;
            event.type = "story";
            event.data = eeg_data(:,triggers_ind_story_start(k):triggers_ind_story_end(k));
            event.answers = EEG.answers;
            data_set_o = [data_set_o event];
        end
        for k =1:size(triggers_ind_control_start,2)
            event.name = EEG.file_name;
            event.type = "control";
            event.data = eeg_data(:,triggers_ind_control_start(k):triggers_ind_control_end(k));
            event.answers = EEG.answers;
            data_set_o = [data_set_o event];
        end
   end
end

