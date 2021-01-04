% The function go over all subjects in the data set and filter 
% the data. filtering range: [locutoff,hicutoff)]
function [data_set_o] = filteringDataSet(data_set,locutoff,hicutoff)

    data_set_o = [];
    for i = 1:size(data_set,2)
        tmp = struct;
        EEG1 = data_set(i);
        tmp = EEG1;
        EEG1.file_name
        EEGLAB = EEG1.data;% struct of eeglab
        
        % Filtering the data
        EEGOUT = pop_eegfilt( EEGLAB, 0, hicutoff);
        EEGOUT = pop_eegfilt( EEGOUT, locutoff, 0);
        
        tmp.data = EEGOUT;
        data_set_o = [data_set_o tmp];
    end
end

