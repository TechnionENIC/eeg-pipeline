% The function go over all subjects in the data set and rereferance
% the data
function [data_set_o] = rerefDataSet(data_set)
    % parameters:
    electrode = 'TP10';
    
    data_set_o = [];
    for i = 1:size(data_set,2)
        tmp = struct;
        EEG1 = data_set(i);
        tmp = EEG1;
        EEG1.file_name
        EEGLAB = EEG1.data;% struct of eeglab
        
        % Re referancing the data
        EEGOUT = pop_reref( EEGLAB, electrode);
        
        tmp.data = EEGOUT;
        data_set_o = [data_set_o tmp];
    end
end

