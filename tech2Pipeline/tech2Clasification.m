%clear; % clear workspace
%close all;
%clc; % clear command window

% Select all eeg data that was preporcessed
setDataFiles = dir("C:\output\behav\**\*6_remove_iclabel.set");
numOfSubjects = length(setDataFiles);
%numOfSubjects = 6;

EPOCH_LOW = 0.1; 
EPOCH_HIGH = 1;

suffixLength = 4;
% Holds final event summary dashboard
eventSummary = struct;
EEG_STRUCT_CORRECT_CONTROL = [];
EEG_STRUCT_CORRECT_DYS = [];
EEG_STRUCT_NONWORD_CORRECT_CONTROL = [];
EEG_STRUCT_NONWORD_CORRECT_DYS = [];
labels = [];
ALL_SUBJECTS_CORRECT_WORD = cell(1,40);
ALL_SUBJECTS_CORRECT_WORD_COV = cell(1,40);
ALL_SUBJECTS_CORRECT_NONWORD = cell(1,40);
ALL_SUBJECTS_CORRECT_NONWORD_COV = cell(1,40);

[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

fprintf('\n--- Start processing %d subjects ---\n', numOfSubjects);
for n=1:numOfSubjects
    filename = setDataFiles(n).name;
    fprintf('\n--- Processing subject %d (%s) ---\n', n, filename);
    
    %% - Step 1: Importing .set data structure for each subject
    % Remove file extention from file name
    %     setname = filename(1:end-suffixLength);
    %     EEG.setname = setname;
    setPath = [setDataFiles(n).folder filesep filename];
    EEG = pop_loadset(setPath);
    eventSummary(n).setname = EEG.setname;
    
    groupArr = split(setPath, "\");
    eventSummary(n).group = char(groupArr(4));
    
    % In this specfic research we had 4 events S 1/2 is auditory word stimuli
    % S 11/12 is the child response
    allEventTypes = {EEG.event.type}';
    s11Idx = find(strcmp(allEventTypes, 'S 11'));
    s12Idx = find(strcmp(allEventTypes, 'S 12'));
    s1Idx = find(strcmp(allEventTypes, 'S  1'));
    s2Idx = find(strcmp(allEventTypes, 'S  2'));
    
    eventSummary(n).numOfEvents = length(allEventTypes);
    eventSummary(n).numOfS11 = length(s11Idx);
    eventSummary(n).numOfS12 = length(s12Idx);
    eventSummary(n).numOfS1 = length(s1Idx);
    eventSummary(n).numOfS2 = length(s2Idx);
    eventSummary(n).totalNumOfAnswers = eventSummary(n).numOfS1 + eventSummary(n).numOfS2;
    eventSummary(n).totalNumOfQuestions = eventSummary(n).numOfS11 + eventSummary(n).numOfS12;
    
    % Validation and categorization of answer to stimulai, can be correct,
    % wrong, no-answer or multiple answers (which also can be distingwish to
    % wrong and then correct or hardware failue such as correct correct
    % correct...) will be represented as a string of "ttt" (i.e true true ture)
    eventSummary(n).eventQASummary = struct;
    iEvent = 1;
    % Iterate over all events
    while iEvent < length(EEG.event)
        % If event is of type questions
        if (strcmp(EEG.event(iEvent).type, 'S 11') || strcmp(EEG.event(iEvent).type, 'S 12'))
            questionEventType = EEG.event(iEvent).type;
            iEventOrig = iEvent;
            iEvent = iEvent + 1;
            totalAnswersEventStr = "";
            % Iterate all answers events (0..inf) until we get another
            % questions event, valid answer is of length 1.
            while (iEvent < length(EEG.event) && ~(strcmp(EEG.event(iEvent).type, 'S 11') || strcmp(EEG.event(iEvent).type, 'S 12')))
                singleAnswerEvent = "";
                if (strcmp(EEG.event(iEvent).type, 'S  1'))
                    if (strcmp(questionEventType, 'S 11'))
                        singleAnswerEvent = "t";
                    end
                    if (strcmp(questionEventType, 'S 12'))
                        singleAnswerEvent = "f";
                    end
                end
                if (strcmp(EEG.event(iEvent).type, 'S  2'))
                    if (strcmp(questionEventType, 'S 11'))
                        singleAnswerEvent = "f";
                    end
                    if (strcmp(questionEventType, 'S 12'))
                        singleAnswerEvent = "t";
                    end
                end
                totalAnswersEventStr = totalAnswersEventStr + singleAnswerEvent;
                iEvent = iEvent + 1;
            end
            
            eventSummary(n).eventQASummary(end + 1).questionId = iEventOrig;
            eventSummary(n).eventQASummary(end).questionType = questionEventType;
            eventSummary(n).eventQASummary(end).answer = totalAnswersEventStr;
            
        else % Skip non question events
            iEvent = iEvent + 1;
        end
    end
    
    qStrArr = [eventSummary(n).eventQASummary.answer];
    eventSummary(n).maxResponse = 0;
    eventSummary(n).minResponse = 0;
    eventSummary(n).avgResponse = 0;
    eventSummary(n).totalCorrectAnswer = length(find(strcmp(qStrArr, "t")));
    eventSummary(n).totalInCcrrectAnswer = length(find(strcmp(qStrArr, "f")));
    eventSummary(n).totalMultipleAnswer = length(find(strlength(qStrArr) > 1));
    eventSummary(n).totalNoAnswer = length(find(strcmp(qStrArr, "")));
    
    correctWordEventIndices = [];
    correctNonWordEventIndices = [];
    % First phase we take only correct answer from both groups.
    % Should we look at the data as continuous? merging beween epoch?
    % Should we take a more tight range (ms) of the answer event?
    % EEG_EVENT = pop_epoch(EEG, [], [-0.2 0.2], 'eventindices' ,eventSummary(n).eventQASummary(i).questionId);
    % Should we take same constant 2.4 sec from questions to next
    % question, where it is garanteed answer event is present.
    for i = 1:length(eventSummary(n).eventQASummary)
        if (strcmp(eventSummary(n).eventQASummary(i).answer, "t") && strcmp(eventSummary(n).eventQASummary(i).questionType, "S 11"))
            correctWordEventIndices = [correctWordEventIndices eventSummary(n).eventQASummary(i).questionId];    
        end
        if (strcmp(eventSummary(n).eventQASummary(i).answer, "t") && strcmp(eventSummary(n).eventQASummary(i).questionType, "S 12"))
            correctNonWordEventIndices = [correctNonWordEventIndices eventSummary(n).eventQASummary(i).questionId];    
        end
    end

    EEG_STRUCT_CORRECT_WORD = pop_epoch(EEG, [], [EPOCH_LOW EPOCH_HIGH], 'eventindices' ,correctWordEventIndices);
    EEG_STRUCT_CORRECT_NONWORD = pop_epoch(EEG, [], [EPOCH_LOW EPOCH_HIGH], 'eventindices' ,correctNonWordEventIndices);
   
    % Rephasing from 3D data matrix to 2D - [NumOfChannel, Signal,
    % NumOfCorrectAnswer) = e.g [64, 440, 85] to continious without NumOfCorrectAnswer segrigation [NumOfChannel,
    % Signal]
    %S = size(EEG_STRUCT_CORRECT.data);
    %EEG_STRUCT_CORRECT.data = reshape(EEG_STRUCT_CORRECT.data,[S(1),S(2)*S(3)]);
    
    % Mean over epoch 
    meanEpochCorretWord = mean(EEG_STRUCT_CORRECT_WORD.data, 3);
    meanEpochCorretNonWord = mean(EEG_STRUCT_CORRECT_NONWORD.data, 3);
    
    ALL_SUBJECTS_CORRECT_WORD{n} = meanEpochCorretWord;
    ALL_SUBJECTS_CORRECT_NONWORD{n} = meanEpochCorretNonWord;
    fprintf('Calculate covariance matrix \n');
    ALL_SUBJECTS_CORRECT_WORD_COV{n} = cov(meanEpochCorretWord);
    ALL_SUBJECTS_CORRECT_NONWORD_COV{n} = cov(meanEpochCorretNonWord);
    if (strcmp(eventSummary(n).group, "Control"))
         tmpLabel = 1;
         EEG_STRUCT_CORRECT_CONTROL = [EEG_STRUCT_CORRECT_CONTROL meanEpochCorretWord];
         EEG_STRUCT_NONWORD_CORRECT_CONTROL = [EEG_STRUCT_NONWORD_CORRECT_CONTROL meanEpochCorretNonWord];
    else
         tmpLabel = 2;
         EEG_STRUCT_CORRECT_DYS = [EEG_STRUCT_CORRECT_DYS meanEpochCorretWord];
         EEG_STRUCT_NONWORD_CORRECT_DYS = [EEG_STRUCT_NONWORD_CORRECT_DYS meanEpochCorretNonWord];
    end
    labels = [labels tmpLabel];
end

% pop_eegplot(EEG_EVENT)

% When measuring brain activity, you usually make a long, 
% continuous recording during which you expose your study participants to 
% a task over and over again. There's a lot of noise in the recordings,
% so you need to average over many instances of a stimulus/task event to
% get an idea of what it does to the brain. To average, 
% you need to cut the recording into trials (also called epochs).

% - Feature extraction section: Calc Covariance Matrices
%mat_cov_control = calcCovMat(EEG_STRUCT_CORRECT_CONTROL);


% - Feature reduction section: PCA
%fprintf('Calculate PCA matrix \n');
%pca_cov_dys = pca(GLOBAL_CORRECT);
%[dysU, dysS, dysV] = pca(EEG_EVENT_DYS, 2);

% - Classifier section: SVM Classification
fprintf('Starting SVM training \n');
Mdl = fitcsvm(ALL_SUBJECTS_CORRECT_WORD_COV, labels);
predicted = predict(Mdl, ALL_SUBJECTS_CORRECT_WORD_COV);

%[SVM_TPR_DYS ,SVM_FPR_DYS ,SVM_TNR_DYS ,SVM_PPV_DYS] =...
%    svmClassification(mat_cov_dys,ds_cov_dys,per_of_train,num_of_iterations);

plotClassificationResults(SVM_TPR_CONTROL ,SVM_FPR_CONTROL ,SVM_TNR_CONTROL ,SVM_PPV_CONTROL);
%plotClassificationResults(SVM_TPR_DYS ,SVM_FPR_DYS ,SVM_TNR_DYS ,SVM_PPV_DYS);
    

function plotClassificationResults(TPR_table ,FPR_table ,TNR_table ,PPV_table)
    col_names = FPR_table.Properties.VariableNames;
    for i = 1:size(TPR_table,2)
        FPR = nanmean(FPR_table{:,i});
        PPV = nanmean(PPV_table{:,i});
        TNR = nanmean(TNR_table{:,i});
        TPR = nanmean(TPR_table{:,i});
        X = categorical({'FPR','PPV','TNR','TPR'});
        X = reordercats(X,{'FPR','PPV','TNR','TPR'});
        y = [FPR PPV TNR TPR];
        figure('Renderer', 'painters', 'Position', [10 10 200 200])
        b = bar(X,y); ylim([0 1])
        b(1).FaceColor = [1 51/255 51/255];
        title(col_names(i), 'Interpreter', 'none'); grid on;
    end
end







