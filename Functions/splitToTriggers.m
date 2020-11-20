
function [data_set_2017_o,data_set_2018_o] = splitToTriggers(data_set_2017,data_set_2018)
    data_set_2017_o = [];
    data_set_2018_o = [];
    
    event_name = ["S  1" "S 11" "S 12" "S 13" "S 14" "S 15"];
    
    for i = 1:size(data_set_2017,2)
        EEG = data_set_2017(i);
        EEGLAB = EEG.data;% struct of eeglab
        eeg_data = EEGLAB.data;
        eeg_times = EEGLAB.times;
        triggers = EEGLAB.urevent;
        triggers_names = {triggers.type};
        triggers_ind = cell2mat({triggers.latency});
        triggers_times = triggers_ind/500;
        
        %remove "R  1" (it a duplicate of the privious ind)
        ind = strcmp(triggers_names,'R  1');
        triggers_names(ind) = [];
        triggers_ind(ind) = [];
        triggers_times(ind) = [];
        
        for k = 1:length(triggers_names)
            trigger_name = convertCharsToStrings(triggers_names{k});
            if(sum(strcmp(event_name,trigger_name)) > 0)
                if(k == length(triggers_names))
                    indcies = [triggers_ind(k):((triggers_ind(k)+1500)-1)];
                else
                    indcies = [triggers_ind(k):(triggers_ind(k+1)-1)];
                end
                eeg_data2 = eeg_data(:,indcies);
                
                tmp = data_set_2017(i);
                tmp.data.data = eeg_data(:,indcies);
                tmp.data.times = eeg_times(:,indcies);
                data_set_2017_o = [data_set_2017_o tmp];
            end
        end
        
    end
    
    for i = 1:size(data_set_2018,2)
        EEG = data_set_2018(i);
        EEGLAB = EEG.data;% struct of eeglab
        eeg_data = EEGLAB.data;
        eeg_times = EEGLAB.times;
        triggers = EEGLAB.urevent;
        triggers_names = {triggers.type};
        triggers_ind = cell2mat({triggers.latency});
        triggers_times = triggers_ind/500;
        
        %remove "R  1" (it a duplicate of the privious ind)
        ind = strcmp(triggers_names,'R  1');
        triggers_names(ind) = [];
        triggers_ind(ind) = [];
        triggers_times(ind) = [];
        
        for k = 1:length(triggers_names)
            trigger_name = convertCharsToStrings(triggers_names{k});
            if(sum(strcmp(event_name,trigger_name)) > 0)
                if(k == length(triggers_names))
                    indcies = [triggers_ind(k):((triggers_ind(k)+1500)-1)];
                else
                    indcies = [triggers_ind(k):(triggers_ind(k+1)-1)];
                end
                eeg_data2 = eeg_data(:,indcies);
                
                tmp = data_set_2018(i);
                tmp.data.data = eeg_data(:,indcies);
                tmp.data.times = eeg_times(:,indcies);
                data_set_2018_o = [data_set_2018_o tmp];
            end
        end
        
    end
end

