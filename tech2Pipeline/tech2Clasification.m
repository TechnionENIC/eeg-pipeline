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

% X = 40 subjects, Y = Span of data matrix into vector
total_mat_corrent_word = zeros(40,11520); % 64 * 180 = 11520
total_mat_correct_nonword = zeros(40,11520); % 64 * 180 = 11520

% Cov on data frames cell
total_mat_corrent_word_cov = zeros(40,32400); % 180 * 180 = 32400
total_mat_correct_nonword_cov = zeros(40,32400); % 180 * 180 = 32400

% Cov on channels (what if channel removed for individual subject?)
total_mat_corrent_word_channel_cov = zeros(40,4096); % 64 * 64 = 4096
total_mat_correct_nonword_channel_cov = zeros(40,4096); % 64 * 64 = 4096


for k = 1:40
    temp = ALL_SUBJECTS_CORRECT_WORD(k);
    tempMat = cell2mat(temp);
    total_mat_corrent_word(k,:) = tempMat(:)';
    
    temp = ALL_SUBJECTS_CORRECT_NONWORD(k);
    tempMat = cell2mat(temp);
    total_mat_correct_nonword(k,:) = tempMat(:)';
    
    temp = ALL_SUBJECTS_CORRECT_WORD_COV(k);
    tempMat = cell2mat(temp);
    total_mat_corrent_word_cov(k,:) = tempMat(:)';
    
    temp = ALL_SUBJECTS_CORRECT_NONWORD_COV(k);
    tempMat = cell2mat(temp);
    total_mat_correct_nonword_cov(k,:) = tempMat(:)';
    
    extractTemp = ALL_SUBJECTS_CORRECT_WORD(k);
    extractTempMat = cell2mat(extractTemp);
    tempMat = cov(extractTempMat'); 
    total_mat_corrent_word_channel_cov(k,:) = tempMat(:)';
    
    extractTemp = ALL_SUBJECTS_CORRECT_NONWORD(k);
    extractTempMat = cell2mat(extractTemp);
    tempMat = cov(extractTempMat'); 
    total_mat_correct_nonword_channel_cov(k,:) = tempMat(:)';
end

pca_total_mat_corrent_word = pca(total_mat_corrent_word,2);
pca_total_mat_correct_nonword = pca(total_mat_correct_nonword,2);
pca_total_mat_corrent_word_cov = pca(total_mat_corrent_word_cov,2);
pca_total_mat_correct_nonword_cov = pca(total_mat_correct_nonword_cov,2);
pca_total_mat_corrent_word_channel_cov = pca(total_mat_corrent_word_channel_cov,2);
pca_total_mat_correct_nonword_channel_cov = pca(total_mat_correct_nonword_channel_cov,2);

figure('Name','pca_total_mat_corrent_word');
title('pca_total_mat_corrent_word');
for i = 1:40
s1 = scatter(pca_total_mat_corrent_word(i,1),pca_total_mat_corrent_word(i,2));
s1.Tag = "pca_total_mat_corrent_word";
s1.MarkerFaceColor = [rand rand rand];
% 1 is control 2 is dys
if (labels(i) == 1) 
   s1.Marker = 'o';
else
   s1.Marker = 'x';
end
s1.DisplayName = labels(i)+"data"+i;
grid on; hold on;
end

figure('Name','pca_total_mat_correct_nonword');
title('pca_total_mat_correct_nonword');
for i = 1:40
s2 = scatter(pca_total_mat_correct_nonword(i,1),pca_total_mat_correct_nonword(i,2));
s2.Tag = "pca_total_mat_correct_nonword";
s2.MarkerFaceColor = [rand rand rand];
% 1 is control 2 is dys
if (labels(i) == 1) 
   s2.Marker = 'o';
else
   s2.Marker = 'x';
end
s2.DisplayName = labels(i)+"data"+i;
grid on; hold on;
end

figure('Name','pca_total_mat_corrent_word_cov');
title('pca_total_mat_corrent_word_cov');
for i = 1:40
s3 = scatter(pca_total_mat_corrent_word_cov(i,1),pca_total_mat_corrent_word_cov(i,2));
s3.Tag = "pca_total_mat_corrent_word_cov";
s3.MarkerFaceColor = [rand rand rand];
% 1 is control 2 is dys
if (labels(i) == 1) 
   s3.Marker = 'o';
else
   s3.Marker = 'x';
end
s3.DisplayName = labels(i)+"data"+i;
grid on; hold on;
end

figure('Name','pca_total_mat_correct_nonword_cov');
title('pca_total_mat_correct_nonword_cov');
for i = 1:40
s4 = scatter(pca_total_mat_correct_nonword_cov(i,1),pca_total_mat_correct_nonword_cov(i,2));
s4.Tag = "pca_total_mat_correct_nonword_cov";
s4.MarkerFaceColor = [rand rand rand];
% 1 is control 2 is dys
if (labels(i) == 1) 
   s4.Marker = 'o';
else
   s4.Marker = 'x';
end
s4.DisplayName = labels(i)+"data"+i;
grid on; hold on;
end

figure('Name','pca_total_mat_corrent_word_channel_cov');
title('pca_total_mat_corrent_word_channel_cov');
for i = 1:40
s5 = scatter(pca_total_mat_corrent_word_channel_cov(i,1),pca_total_mat_corrent_word_channel_cov(i,2));
s5.Tag = "pca_total_mat_corrent_word_channel_cov";
s5.MarkerFaceColor = [rand rand rand];
% 1 is control 2 is dys
if (labels(i) == 1) 
   s5.Marker = 'o';
else
   s5.Marker = 'x';
end
s5.DisplayName = labels(i)+"data"+i;
grid on; hold on;
end

figure('Name','pca_total_mat_correct_nonword_channel_cov');
title('pca_total_mat_correct_nonword_channel_cov');
for i = 1:40
s6 = scatter(pca_total_mat_correct_nonword_channel_cov(i,1),pca_total_mat_correct_nonword_channel_cov(i,2));
s6.Tag = "pca_total_mat_correct_nonword_channel_cov";
s6.MarkerFaceColor = [rand rand rand];
% 1 is control 2 is dys
if (labels(i) == 1) 
   s6.Marker = 'o';
else
   s6.Marker = 'x';
end
s6.DisplayName = labels(i)+"data"+i;
grid on; hold on;
end

opts.fs = EEG.srate;
feat_mat_correct_nonword = zeros(40,34);
for i = 1:40
    
     f1 = jfeeg('rba', total_mat_correct_nonword(i,:), opts); 
     f2 = jfeeg('bpg', total_mat_correct_nonword(i,:), opts); 
     f3 = jfeeg('bpb', total_mat_correct_nonword(i,:), opts); 
     f4 = jfeeg('bpa', total_mat_correct_nonword(i,:), opts); 
     f5 = jfeeg('bpt', total_mat_correct_nonword(i,:), opts); 
     f6 = jfeeg('bpd', total_mat_correct_nonword(i,:), opts); 
    f7 = jfeeg('ha', total_mat_correct_nonword(i,:)); 
    f8 = jfeeg('hm', total_mat_correct_nonword(i,:));
    f9 = jfeeg('hc', total_mat_correct_nonword(i,:));
    f10 = jfeeg('skew', total_mat_correct_nonword(i,:));
    f11 = jfeeg('kurt', total_mat_correct_nonword(i,:));
    f12 = jfeeg('1d', total_mat_correct_nonword(i,:));
    f13 = jfeeg('n1d', total_mat_correct_nonword(i,:));
    f14 = jfeeg('2d', total_mat_correct_nonword(i,:));
    f15 = jfeeg('n2d', total_mat_correct_nonword(i,:));
    f16 = jfeeg('mcl', total_mat_correct_nonword(i,:));
    f17 = jfeeg('me', total_mat_correct_nonword(i,:));
    f18 = jfeeg('mte', total_mat_correct_nonword(i,:));
    f19 = jfeeg('lrssv', total_mat_correct_nonword(i,:));
    f20 = jfeeg('te', total_mat_correct_nonword(i,:));
    f21 = jfeeg('sh', total_mat_correct_nonword(i,:));
    f22 = jfeeg('le', total_mat_correct_nonword(i,:));
    f23 = jfeeg('re', total_mat_correct_nonword(i,:));
    f24 = jfeeg('am', total_mat_correct_nonword(i,:));
    f25 = jfeeg('sd', total_mat_correct_nonword(i,:));
    f26 = jfeeg('var', total_mat_correct_nonword(i,:));
    f27 = jfeeg('md', total_mat_correct_nonword(i,:));
    f28 = jfeeg('ar', total_mat_correct_nonword(i,:));
    f29 = jfeeg('max', total_mat_correct_nonword(i,:));
    f30 = jfeeg('min', total_mat_correct_nonword(i,:));
    
    feat = [f1, f2, f3, f4, f5, f6, f7 , f8 , f9 , f10 , f11 , f12 , f13 , f14 , f15 , f16 , f17 , f18 , f19 , f20 , f21 , f22 , f23 , f24 , f25 , f26 , f27 , f28 , f29 , f30 , labels(i)];
    feat_mat_correct_nonword(i,:) = feat;
end

feat_mat_correct_nonword_channel_cov = zeros(40,34);
for i = 1:40
     f1 = jfeeg('rba', total_mat_correct_nonword_channel_cov(i,:), opts); 
     f2 = jfeeg('bpg', total_mat_correct_nonword_channel_cov(i,:), opts); 
     f3 = jfeeg('bpb', total_mat_correct_nonword_channel_cov(i,:), opts); 
     f4 = jfeeg('bpa', total_mat_correct_nonword_channel_cov(i,:), opts); 
     f5 = jfeeg('bpt', total_mat_correct_nonword_channel_cov(i,:), opts); 
     f6 = jfeeg('bpd', total_mat_correct_nonword_channel_cov(i,:), opts); 
    f7 = jfeeg('ha', total_mat_correct_nonword_channel_cov(i,:)); 
    f8 = jfeeg('hm', total_mat_correct_nonword_channel_cov(i,:));
    f9 = jfeeg('hc', total_mat_correct_nonword_channel_cov(i,:));
    f10 = jfeeg('skew', total_mat_correct_nonword_channel_cov(i,:));
    f11 = jfeeg('kurt', total_mat_correct_nonword_channel_cov(i,:));
    f12 = jfeeg('1d', total_mat_correct_nonword_channel_cov(i,:));
    f13 = jfeeg('n1d', total_mat_correct_nonword_channel_cov(i,:));
    f14 = jfeeg('2d', total_mat_correct_nonword_channel_cov(i,:));
    f15 = jfeeg('n2d', total_mat_correct_nonword_channel_cov(i,:));
    f16 = jfeeg('mcl', total_mat_correct_nonword_channel_cov(i,:));
    f17 = jfeeg('me', total_mat_correct_nonword_channel_cov(i,:));
    f18 = jfeeg('mte', total_mat_correct_nonword_channel_cov(i,:));
    f19 = jfeeg('lrssv', total_mat_correct_nonword_channel_cov(i,:));
    f20 = jfeeg('te', total_mat_correct_nonword_channel_cov(i,:));
    f21 = jfeeg('sh', total_mat_correct_nonword_channel_cov(i,:));
    f22 = jfeeg('le', total_mat_correct_nonword_channel_cov(i,:));
    f23 = jfeeg('re', total_mat_correct_nonword_channel_cov(i,:));
    f24 = jfeeg('am', total_mat_correct_nonword_channel_cov(i,:));
    f25 = jfeeg('sd', total_mat_correct_nonword_channel_cov(i,:));
    f26 = jfeeg('var', total_mat_correct_nonword_channel_cov(i,:));
    f27 = jfeeg('md', total_mat_correct_nonword_channel_cov(i,:));
    f28 = jfeeg('ar', total_mat_correct_nonword_channel_cov(i,:));
    f29 = jfeeg('max', total_mat_correct_nonword_channel_cov(i,:));
    f30 = jfeeg('min', total_mat_correct_nonword_channel_cov(i,:));
    
    feat = [f1, f2, f3, f4, f5, f6, f7 , f8 , f9 , f10 , f11 , f12 , f13 , f14 , f15 , f16 , f17 , f18 , f19 , f20 , f21 , f22 , f23 , f24 , f25 , f26 , f27 , f28 , f29 , f30 , labels(i)];
    feat_mat_correct_nonword_channel_cov(i,:) = feat;
end

feat_mat_correct_nonword_cov = zeros(40,34);
for i = 1:40
     f1 = jfeeg('rba', total_mat_correct_nonword_cov(i,:), opts); 
     f2 = jfeeg('bpg', total_mat_correct_nonword_cov(i,:), opts); 
     f3 = jfeeg('bpb', total_mat_correct_nonword_cov(i,:), opts); 
     f4 = jfeeg('bpa', total_mat_correct_nonword_cov(i,:), opts); 
     f5 = jfeeg('bpt', total_mat_correct_nonword_cov(i,:), opts); 
     f6 = jfeeg('bpd', total_mat_correct_nonword_cov(i,:), opts); 
    f7 = jfeeg('ha', total_mat_correct_nonword_cov(i,:)); 
    f8 = jfeeg('hm', total_mat_correct_nonword_cov(i,:));
    f9 = jfeeg('hc', total_mat_correct_nonword_cov(i,:));
    f10 = jfeeg('skew', total_mat_correct_nonword_cov(i,:));
    f11 = jfeeg('kurt', total_mat_correct_nonword_cov(i,:));
    f12 = jfeeg('1d', total_mat_correct_nonword_cov(i,:));
    f13 = jfeeg('n1d', total_mat_correct_nonword_cov(i,:));
    f14 = jfeeg('2d', total_mat_correct_nonword_cov(i,:));
    f15 = jfeeg('n2d', total_mat_correct_nonword_cov(i,:));
    f16 = jfeeg('mcl', total_mat_correct_nonword_cov(i,:));
    f17 = jfeeg('me', total_mat_correct_nonword_cov(i,:));
    f18 = jfeeg('mte', total_mat_correct_nonword_cov(i,:));
    f19 = jfeeg('lrssv', total_mat_correct_nonword_cov(i,:));
    f20 = jfeeg('te', total_mat_correct_nonword_cov(i,:));
    f21 = jfeeg('sh', total_mat_correct_nonword_cov(i,:));
    f22 = jfeeg('le', total_mat_correct_nonword_cov(i,:));
    f23 = jfeeg('re', total_mat_correct_nonword_cov(i,:));
    f24 = jfeeg('am', total_mat_correct_nonword_cov(i,:));
    f25 = jfeeg('sd', total_mat_correct_nonword_cov(i,:));
    f26 = jfeeg('var', total_mat_correct_nonword_cov(i,:));
    f27 = jfeeg('md', total_mat_correct_nonword_cov(i,:));
    f28 = jfeeg('ar', total_mat_correct_nonword_cov(i,:));
    f29 = jfeeg('max', total_mat_correct_nonword_cov(i,:));
    f30 = jfeeg('min', total_mat_correct_nonword_cov(i,:));
    
    feat = [f1, f2, f3, f4, f5, f6, f7 , f8 , f9 , f10 , f11 , f12 , f13 , f14 , f15 , f16 , f17 , f18 , f19 , f20 , f21 , f22 , f23 , f24 , f25 , f26 , f27 , f28 , f29 , f30 , labels(i)];
    feat_mat_correct_nonword_cov(i,:) = feat;
end

feat_mat_corrent_word = zeros(40,34);
for i = 1:40
     f1 = jfeeg('rba', total_mat_correct_nonword(i,:), opts); 
     f2 = jfeeg('bpg', total_mat_correct_nonword(i,:), opts); 
     f3 = jfeeg('bpb', total_mat_correct_nonword(i,:), opts); 
     f4 = jfeeg('bpa', total_mat_correct_nonword(i,:), opts); 
     f5 = jfeeg('bpt', total_mat_correct_nonword(i,:), opts); 
     f6 = jfeeg('bpd', total_mat_correct_nonword(i,:), opts); 
    f7 = jfeeg('ha', total_mat_correct_nonword(i,:)); 
    f8 = jfeeg('hm', total_mat_correct_nonword(i,:));
    f9 = jfeeg('hc', total_mat_correct_nonword(i,:));
    f10 = jfeeg('skew', total_mat_correct_nonword(i,:));
    f11 = jfeeg('kurt', total_mat_correct_nonword(i,:));
    f12 = jfeeg('1d', total_mat_correct_nonword(i,:));
    f13 = jfeeg('n1d', total_mat_correct_nonword(i,:));
    f14 = jfeeg('2d', total_mat_correct_nonword(i,:));
    f15 = jfeeg('n2d', total_mat_correct_nonword(i,:));
    f16 = jfeeg('mcl', total_mat_correct_nonword(i,:));
    f17 = jfeeg('me', total_mat_correct_nonword(i,:));
    f18 = jfeeg('mte', total_mat_correct_nonword(i,:));
    f19 = jfeeg('lrssv', total_mat_correct_nonword(i,:));
    f20 = jfeeg('te', total_mat_correct_nonword(i,:));
    f21 = jfeeg('sh', total_mat_correct_nonword(i,:));
    f22 = jfeeg('le', total_mat_correct_nonword(i,:));
    f23 = jfeeg('re', total_mat_correct_nonword(i,:));
    f24 = jfeeg('am', total_mat_correct_nonword(i,:));
    f25 = jfeeg('sd', total_mat_correct_nonword(i,:));
    f26 = jfeeg('var', total_mat_correct_nonword(i,:));
    f27 = jfeeg('md', total_mat_correct_nonword(i,:));
    f28 = jfeeg('ar', total_mat_correct_nonword(i,:));
    f29 = jfeeg('max', total_mat_correct_nonword(i,:));
    f30 = jfeeg('min', total_mat_correct_nonword(i,:));
    
    feat = [f1, f2, f3, f4, f5, f6, f7 , f8 , f9 , f10 , f11 , f12 , f13 , f14 , f15 , f16 , f17 , f18 , f19 , f20 , f21 , f22 , f23 , f24 , f25 , f26 , f27 , f28 , f29 , f30 , labels(i)];
    feat_mat_corrent_word(i,:) = feat;
end

feat_mat_correct_nonword = zeros(40,34);
for i = 1:40
     f1 = jfeeg('rba', total_mat_corrent_word(i,:), opts); 
     f2 = jfeeg('bpg', total_mat_corrent_word(i,:), opts); 
     f3 = jfeeg('bpb', total_mat_corrent_word(i,:), opts); 
     f4 = jfeeg('bpa', total_mat_corrent_word(i,:), opts); 
     f5 = jfeeg('bpt', total_mat_corrent_word(i,:), opts); 
     f6 = jfeeg('bpd', total_mat_corrent_word(i,:), opts); 
    f7 = jfeeg('ha', total_mat_corrent_word(i,:)); 
    f8 = jfeeg('hm', total_mat_corrent_word(i,:));
    f9 = jfeeg('hc', total_mat_corrent_word(i,:));
    f10 = jfeeg('skew', total_mat_corrent_word(i,:));
    f11 = jfeeg('kurt', total_mat_corrent_word(i,:));
    f12 = jfeeg('1d', total_mat_corrent_word(i,:));
    f13 = jfeeg('n1d', total_mat_corrent_word(i,:));
    f14 = jfeeg('2d', total_mat_corrent_word(i,:));
    f15 = jfeeg('n2d', total_mat_corrent_word(i,:));
    f16 = jfeeg('mcl', total_mat_corrent_word(i,:));
    f17 = jfeeg('me', total_mat_corrent_word(i,:));
    f18 = jfeeg('mte', total_mat_corrent_word(i,:));
    f19 = jfeeg('lrssv', total_mat_corrent_word(i,:));
    f20 = jfeeg('te', total_mat_corrent_word(i,:));
    f21 = jfeeg('sh', total_mat_corrent_word(i,:));
    f22 = jfeeg('le', total_mat_corrent_word(i,:));
    f23 = jfeeg('re', total_mat_corrent_word(i,:));
    f24 = jfeeg('am', total_mat_corrent_word(i,:));
    f25 = jfeeg('sd', total_mat_corrent_word(i,:));
    f26 = jfeeg('var', total_mat_corrent_word(i,:));
    f27 = jfeeg('md', total_mat_corrent_word(i,:));
    f28 = jfeeg('ar', total_mat_corrent_word(i,:));
    f29 = jfeeg('max', total_mat_corrent_word(i,:));
    f30 = jfeeg('min', total_mat_corrent_word(i,:));
    
    feat = [f1, f2, f3, f4, f5, f6, f7 , f8 , f9 , f10 , f11 , f12 , f13 , f14 , f15 , f16 , f17 , f18 , f19 , f20 , f21 , f22 , f23 , f24 , f25 , f26 , f27 , f28 , f29 , f30 , labels(i)];
    feat_mat_correct_nonword(i,:) = feat;
end

feat_mat_corrent_word_channel_cov = zeros(40,34);
for i = 1:40
     f1 = jfeeg('rba', total_mat_corrent_word_channel_cov(i,:), opts); 
     f2 = jfeeg('bpg', total_mat_corrent_word_channel_cov(i,:), opts); 
     f3 = jfeeg('bpb', total_mat_corrent_word_channel_cov(i,:), opts); 
     f4 = jfeeg('bpa', total_mat_corrent_word_channel_cov(i,:), opts); 
     f5 = jfeeg('bpt', total_mat_corrent_word_channel_cov(i,:), opts); 
     f6 = jfeeg('bpd', total_mat_corrent_word_channel_cov(i,:), opts); 
    f7 = jfeeg('ha', total_mat_corrent_word_channel_cov(i,:)); 
    f8 = jfeeg('hm', total_mat_corrent_word_channel_cov(i,:));
    f9 = jfeeg('hc', total_mat_corrent_word_channel_cov(i,:));
    f10 = jfeeg('skew', total_mat_corrent_word_channel_cov(i,:));
    f11 = jfeeg('kurt', total_mat_corrent_word_channel_cov(i,:));
    f12 = jfeeg('1d', total_mat_corrent_word_channel_cov(i,:));
    f13 = jfeeg('n1d', total_mat_corrent_word_channel_cov(i,:));
    f14 = jfeeg('2d', total_mat_corrent_word_channel_cov(i,:));
    f15 = jfeeg('n2d', total_mat_corrent_word_channel_cov(i,:));
    f16 = jfeeg('mcl', total_mat_corrent_word_channel_cov(i,:));
    f17 = jfeeg('me', total_mat_corrent_word_channel_cov(i,:));
    f18 = jfeeg('mte', total_mat_corrent_word_channel_cov(i,:));
    f19 = jfeeg('lrssv', total_mat_corrent_word_channel_cov(i,:));
    f20 = jfeeg('te', total_mat_corrent_word_channel_cov(i,:));
    f21 = jfeeg('sh', total_mat_corrent_word_channel_cov(i,:));
    f22 = jfeeg('le', total_mat_corrent_word_channel_cov(i,:));
    f23 = jfeeg('re', total_mat_corrent_word_channel_cov(i,:));
    f24 = jfeeg('am', total_mat_corrent_word_channel_cov(i,:));
    f25 = jfeeg('sd', total_mat_corrent_word_channel_cov(i,:));
    f26 = jfeeg('var', total_mat_corrent_word_channel_cov(i,:));
    f27 = jfeeg('md', total_mat_corrent_word_channel_cov(i,:));
    f28 = jfeeg('ar', total_mat_corrent_word_channel_cov(i,:));
    f29 = jfeeg('max', total_mat_corrent_word_channel_cov(i,:));
    f30 = jfeeg('min', total_mat_corrent_word_channel_cov(i,:));
    
    feat = [f1, f2, f3, f4, f5, f6, f7 , f8 , f9 , f10 , f11 , f12 , f13 , f14 , f15 , f16 , f17 , f18 , f19 , f20 , f21 , f22 , f23 , f24 , f25 , f26 , f27 , f28 , f29 , f30 , labels(i)];
    feat_mat_corrent_word_channel_cov(i,:) = feat;
end

feat_mat_corrent_word_cov = zeros(40,34);
for i = 1:40
     f1 = jfeeg('rba', total_mat_corrent_word_cov(i,:), opts); 
     f2 = jfeeg('bpg', total_mat_corrent_word_cov(i,:), opts); 
     f3 = jfeeg('bpb', total_mat_corrent_word_cov(i,:), opts); 
     f4 = jfeeg('bpa', total_mat_corrent_word_cov(i,:), opts); 
     f5 = jfeeg('bpt', total_mat_corrent_word_cov(i,:), opts); 
     f6 = jfeeg('bpd', total_mat_corrent_word_cov(i,:), opts); 
    f7 = jfeeg('ha', total_mat_corrent_word_cov(i,:)); 
    f8 = jfeeg('hm', total_mat_corrent_word_cov(i,:));
    f9 = jfeeg('hc', total_mat_corrent_word_cov(i,:));
    f10 = jfeeg('skew', total_mat_corrent_word_cov(i,:));
    f11 = jfeeg('kurt', total_mat_corrent_word_cov(i,:));
    f12 = jfeeg('1d', total_mat_corrent_word_cov(i,:));
    f13 = jfeeg('n1d', total_mat_corrent_word_cov(i,:));
    f14 = jfeeg('2d', total_mat_corrent_word_cov(i,:));
    f15 = jfeeg('n2d', total_mat_corrent_word_cov(i,:));
    f16 = jfeeg('mcl', total_mat_corrent_word_cov(i,:));
    f17 = jfeeg('me', total_mat_corrent_word_cov(i,:));
    f18 = jfeeg('mte', total_mat_corrent_word_cov(i,:));
    f19 = jfeeg('lrssv', total_mat_corrent_word_cov(i,:));
    f20 = jfeeg('te', total_mat_corrent_word_cov(i,:));
    f21 = jfeeg('sh', total_mat_corrent_word_cov(i,:));
    f22 = jfeeg('le', total_mat_corrent_word_cov(i,:));
    f23 = jfeeg('re', total_mat_corrent_word_cov(i,:));
    f24 = jfeeg('am', total_mat_corrent_word_cov(i,:));
    f25 = jfeeg('sd', total_mat_corrent_word_cov(i,:));
    f26 = jfeeg('var', total_mat_corrent_word_cov(i,:));
    f27 = jfeeg('md', total_mat_corrent_word_cov(i,:));
    f28 = jfeeg('ar', total_mat_corrent_word_cov(i,:));
    f29 = jfeeg('max', total_mat_corrent_word_cov(i,:));
    f30 = jfeeg('min', total_mat_corrent_word_cov(i,:));
    
    feat = [f1, f2, f3, f4, f5, f6, f7 , f8 , f9 , f10 , f11 , f12 , f13 , f14 , f15 , f16 , f17 , f18 , f19 , f20 , f21 , f22 , f23 , f24 , f25 , f26 , f27 , f28 , f29 , f30 , labels(i)];
    feat_mat_corrent_word_cov(i,:) = feat;
end

t_total_mat_corrent_word_channel_cov = [total_mat_corrent_word_channel_cov labels'];
t_total_mat_corrent_word = [total_mat_corrent_word labels'];
t_total_mat_correct_nonword_cov = [total_mat_correct_nonword_cov labels'];
t_total_mat_corrent_word_cov = [total_mat_corrent_word_cov labels'];
r_total_mat_correct_nonword_channel_cov = [total_mat_correct_nonword_channel_cov labels'];

% - Feature reduction section: PCA
%fprintf('Calculate PCA matrix \n');
%pca_cov_dys = pca(GLOBAL_CORRECT);
%[dysU, dysS, dysV] = pca(EEG_EVENT_DYS, 2);

% - Classifier section: SVM Classification
% fprintf('Starting SVM training \n');
% Mdl = fitcsvm(total_mat_corrent_word_channel_cov, labels);
% predicted = predict(Mdl, ALL_SUBJECTS_CORRECT_WORD_COV);

%[SVM_TPR_DYS ,SVM_FPR_DYS ,SVM_TNR_DYS ,SVM_PPV_DYS] =...
%    svmClassification(mat_cov_dys,ds_cov_dys,per_of_train,num_of_iterations);

%plotClassificationResults(SVM_TPR_CONTROL ,SVM_FPR_CONTROL ,SVM_TNR_CONTROL ,SVM_PPV_CONTROL);
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




