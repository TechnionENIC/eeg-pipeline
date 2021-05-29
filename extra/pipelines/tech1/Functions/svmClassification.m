% The function split the data into train and test sets, preforms a svm 
% classification and return the results

function [results_TPR,results_FPR,results_TNR,results_PPV] = ...
    svmClassification(cov_mat,ds,questionnaire_ans,per_of_train,num_of_iterations)

    question_vec = [];
    for kk = 3:size(questionnaire_ans,2)
        question_vec = [question_vec, string(cell2mat...
            (questionnaire_ans.Properties.VariableNames(kk)))];
    end

    results_TPR = table(); results_FPR = table();
    results_TNR = table(); results_PPV = table();
    for q  = question_vec
        results_TPR.(q)=-100; results_FPR.(q)=-100;
        results_TNR.(q)=-100; results_PPV.(q)=-100;
    end            

    for k = 3:size(questionnaire_ans,2) % go over all questions in questionnaire
        disp(k-2);
        for jj = 1:num_of_iterations
            % Split the data
            [train_ds, train_cov_mat, test_ds, test_cov_mat] =...
                split_data(ds, cov_mat, per_of_train);

            % Convert cov matricies to 3D
            train_cov_mat_3D = convertTo3D(train_cov_mat);
            test_cov_mat_3D = convertTo3D(test_cov_mat);

            % Project to tangent space
            mean_cov = RiemannianMean(train_cov_mat_3D);
%             if ~isreal(mean_cov)
%                 continue
%             end
            [feat_train, ~] = Tangent_space(train_cov_mat_3D, mean_cov);
            [feat_test,  ~] = Tangent_space(test_cov_mat_3D, mean_cov);
            feat_train = feat_train'; feat_test = feat_test';

%             if ~isreal(feat_train)
%                 continue
%             end
            
            % Creating the labels
            measurment_name = string(questionnaire_ans.Properties.VariableNames(k));
            measurment_vec = table2array(questionnaire_ans(:,k)); 
            train_answers = zeros(size(train_cov_mat,1),1);
            for ii=1:size(train_ds,2)
                train_answers(ii) = train_ds(ii).answers.(measurment_name);
            end
            test_answers = zeros(size(test_cov_mat,1),1);
            for ii=1:size(test_ds,2)
                test_answers(ii) = test_ds(ii).answers.(measurment_name);
            end
            thresh_hold = mean(measurment_vec);
            train_labels = double(train_answers>=thresh_hold);
            test_labels = double(test_answers>=thresh_hold);

            % SVM classification

            Mdl1 = fitcsvm(real(feat_train),train_labels);
            [predicted_label,~] = predict(Mdl1,real(feat_test));

            TP = sum((predicted_label == 1) & (test_labels == 1));
            FP = sum((predicted_label == 1) & (test_labels == 0));
            FN = sum((predicted_label == 0) & (test_labels == 1));
            TN = sum((predicted_label == 0) & (test_labels == 0));

            results_TPR.(question_vec(k-2))(jj,1) = TP/(TP+FN);
            results_FPR.(question_vec(k-2))(jj,1) = FP/(TN+FP); 
            results_TNR.(question_vec(k-2))(jj,1) = TN/(TN+FP); 
            results_PPV.(question_vec(k-2))(jj,1) = TP/(TP+FP); 
        end
    end
end

function cov_mat_3D = convertTo3D(cov_mat)
    cov_mat_3D = []; 
    for kk = 1:size(cov_mat,1)
       cov_mat_3D(:,:,kk) = reshape(cov_mat(kk,:),...
           sqrt(size(cov_mat,2)),sqrt(size(cov_mat,2)));  
    end
end

