% The function go over the data-set, plot for each element the time and
% frequency graphs, and saves the bad channels (input from the user)
function [to_be_removed] = plotIterator(data_set,low_cut_off,high_cut_off)
    to_be_removed = [];

    for i = 1:size(data_set,2)
        tmp = struct;
        EEG1 = data_set(i);
        tmp.file_name = EEG1.file_name;
        EEGLAB = EEG1.data;% struct of eeglab
        plotResults(EEGLAB,'raw',[low_cut_off high_cut_off]);
        prompt = 'Enter bad channels numbers ';
        x = input(prompt,'s')
        tmp.channelsToBeRemoved = x;
        close all;
        
        to_be_removed = [to_be_removed tmp];
    end
end

function plotResults(EEGLAB,str,range)
    eegplot(EEGLAB.data,'submean','on');title([str]);  
    figure(); 
    spectopo(EEGLAB.data, 0, 500,'freqrange',range);
    title([str]);       
    
end