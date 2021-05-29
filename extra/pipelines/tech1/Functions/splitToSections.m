% The function split every story/control to smaller sections
function [data_set_o] = splitToSections(data_set,number_of_sections)
    data_set_o = [];
    event = struct;
    for i = 1:size(data_set,2)
        EEG = data_set(i);
        eeg_data = EEG.data;% struct of eeglab
        % split every event to number_of_sections sections
        size_of_section = round(length(eeg_data)/number_of_sections);
        start_section = linspace(1,length(eeg_data)-size_of_section,number_of_sections);
        end_section = zeros(number_of_sections,1);
        end_section(1:number_of_sections-1) = start_section(2:number_of_sections);
        end_section(end) = length(eeg_data);
        for k =1:number_of_sections
            event.name = EEG.name;
            event.type = EEG.type;
            event.data = eeg_data(:,start_section(k):end_section(k));
            event.answers = EEG.answers;
            data_set_o = [data_set_o event];
        end
   end
end
