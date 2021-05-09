% Inputs:
% path - the path to the folder with the files (.eeg, .vhdr, .vmrk)
% questionnaire_file - the .MAT file which contains the answers for the eeg files
% Outputs:
% data_set - data_set struct which contains the following fieldes for each subject: 
% 		   file_name, data struct of eeglab(contains the eeg signals),  questionnaire answers for the subject

function [data_set] = loadData(path,questionnaire_file)
    disp('Loading Data.');
    addpath(genpath('Toolbox - Automagic'));
    addpath(genpath('Toolbox - covariance'));
    addpath(genpath('Toolbox - dr'));
    addpath(genpath('Toolbox - EEGLAB'));
    addpath(genpath('MAT - Files'));

    A = load(questionnaire_file);
    vars = whos(matfile(questionnaire_file));
    questionnaire = A.(vars(1).name);

    data_set = [];
    files = questionnaire.fileName;
    listing = dir('**/*.eeg');
    exist_files = {listing.name};
    for i=1:length(files)
        tmp = struct;
        tmp.file_name = files(i);
        
        res = isExist(files(i),exist_files);
        if(res == 0)
            continue;
        end
        disp(['loading: '+files(i)]);
        [EEG, com] = pop_loadbv(path, strcat(files(i),'.vhdr'));
        tmp.data = EEG;
        tmp.answers = questionnaire(i,(3:end));
        data_set = [data_set tmp];
    end
    
end

% If file_name exist in files then return 1 else return 0
function res = isExist(file_name,files)
    res = 0;
    for k=1:length(files)
        curr_file = convertCharsToStrings(files{k});
        if(strcmp([file_name+'.eeg'],curr_file) == 1)
            res = 1;
        end
    end
end