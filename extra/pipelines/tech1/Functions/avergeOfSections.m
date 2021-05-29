%This function calculate the averge of tje sections to any child
function [data_set_o] = avergeOfSections(data_set)
    data_set_o = [];
    event = struct;
    names = [];
    for k=1:size(data_set,2)
        names =[names; data_set(k).name];
    end
    uniq_names = unique(names);
    len_names = length(uniq_names);
    for ii=1:len_names
        ind_curr_child = find(names == uniq_names(ii));
        num_of_sections = length(ind_curr_child);
        EEG_MAT = data_set(ind_curr_child);
        for kk=1:num_of_sections
            eeg_data = EEG_MAT(kk).data;% struct of eeglab
        end
        average_data = eeg_data;
        % split every event to number_of_sections sections
            event.name = EEG_MAT(1).name;
            event.type = 'average';
            event.data = average_data;
            event.answers = EEG_MAT(1).answers;
            data_set_o = [data_set_o event];
    end
end

