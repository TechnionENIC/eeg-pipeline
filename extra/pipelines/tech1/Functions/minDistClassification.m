function [results_TPR,results_FPR,results_TNR,results_PPV] =...
    minDistClassification(cov_mat,ds,questionnaire_ans,per_of_train,num_of_iterations)
    
    answers = questionnaire_ans{:,3:size(questionnaire_ans,2)};
    question_vec = questionnaire_ans.Properties.VariableNames(3:end);
    
    results_TPR = table(); results_FPR = table();
    results_TNR = table(); results_PPV = table();
    for q  = question_vec(3:end)
        question_name = string(q);
        results_TPR.(question_name)=-100; results_FPR.(question_name)=-100;
        results_TNR.(question_name)=-100; results_PPV.(question_name)=-100;
    end
    
    for curr_ques_ind = 1:size(answers,2)
        disp("ques: " + num2str(curr_ques_ind) + "/" + num2str(size(answers,2)))
        threshold = mean(answers(:,curr_ques_ind));
        
        for iter_ind = 1:num_of_iterations
            [train_ds, train_mat_cov, test_ds, test_mat_cov] =...
                    split_data(ds,cov_mat, per_of_train);
                
            % Split training set to 2 groups by the threshold
            group1 = []; group2 = [];
            
            for k = 1:size(train_ds,2)
                answers_train = train_ds(k).answers{1,1:size(answers,2)};
                
                curr_cov_mat = reshape(train_mat_cov(k,:),...
                    sqrt(size(train_mat_cov,2)),sqrt(size(train_mat_cov,2)));
                
                if answers_train(curr_ques_ind) >= threshold
                    group1(:,:,size(group1,3)+1) = curr_cov_mat;
                else
                    group2(:,:,size(group2,3)+1) = curr_cov_mat;
                end
            end
            
            if (size(group1,1) == 0) || (size(group2,1) == 0)
                continue
            end
            
            % Calculate Riemannian Mean for each group
            group1_mean = RiemannianMean(group1(:,:,2:end));
            group2_mean = RiemannianMean(group2(:,:,2:end));
            
            correct_labels = [];
            predicted_labels = [];
            
            for k = 1:size(test_ds,2)
                answers_test = test_ds(k).answers{1,1:size(answers,2)};
                
                curr_cov_mat = reshape(test_mat_cov(k,:),...
                    sqrt(size(test_mat_cov,2)),sqrt(size(test_mat_cov,2)));
                
                % Calc correct labels
                if answers_test(curr_ques_ind) >= threshold
                    correct_labels = [correct_labels 1];
                else
                    correct_labels = [correct_labels 0];
                end

                % Calc predicted labels
                if (distance_riemann(group1_mean,curr_cov_mat) > ...
                        distance_riemann(group2_mean,curr_cov_mat))
                    predicted_labels = [predicted_labels 1];
                else
                    predicted_labels = [predicted_labels 0];
                end  
            end
            
            
            TP = sum((predicted_labels == 1) & (correct_labels == 1));
            FP = sum((predicted_labels == 1) & (correct_labels == 0));
            FN = sum((predicted_labels == 0) & (correct_labels == 1));
            TN = sum((predicted_labels == 0) & (correct_labels == 0));

            results_TPR.(string(question_vec(curr_ques_ind)))(iter_ind,1) = TP/(TP+FN);
            results_FPR.(string(question_vec(curr_ques_ind)))(iter_ind,1) = FP/(TN+FP); 
            results_TNR.(string(question_vec(curr_ques_ind)))(iter_ind,1) = TN/(TN+FP); 
            results_PPV.(string(question_vec(curr_ques_ind)))(iter_ind,1) = TP/(TP+FP);
            
        end
    end
    
end


    %         % plot the results 
    %         figure();
    %         s = scatter(dist_group1_from_mean1,dist_group1_from_mean2);
    %         xlabel('d_R(X,\mu_{above threshold})');
    %         ylabel('d_R(X,\mu_{below threshold})');
    %         s.MarkerFaceColor = [0 255 255]/255; grid on;
    %         hold on;
    %         s = scatter(dist_group2_from_mean1,dist_group2_from_mean2);
    %         s.MarkerFaceColor = [255 140 0]/255;
    %         title([question,' ,threshold: ',num2str(threshold)],...
    %               'Interpreter', 'none');grid on;
    %         plot(1:0.1:20,1:0.1:20,'k');
    %         legend('above threshold','below threshold');

        %%    


    %         s = scatter(d_train_m1(train_lables == 1),d_train_m2(train_lables == 1),'d');
    %         s.MarkerFaceColor = [0 255 255]/255;
    %         s.MarkerEdgeColor = [0 255 255]/255;
    %         s = scatter(d_train_m1(train_lables == 0),d_train_m2(train_lables == 0),'d');
    %         s.MarkerFaceColor = [255 140 0]/255;
    %         s.MarkerEdgeColor = [255 140 0]/255;

    %         legend('above threshold','below threshold','above threshold','below threshold','line');


    %         % plot the results 
    %         figure();
    %         s = scatter(d_m1(classifier_labels == 1),d_m2(classifier_labels == 1));
    %         xlabel('d_R(X,\mu_{above threshold})');
    %         ylabel('d_R(X,\mu_{below threshold})');
    %         s.MarkerFaceColor = [0 255 255]/255; grid on;
    %         hold on;
    %         s = scatter(d_m1(classifier_labels == 0),d_m2(classifier_labels == 0));
    %         s.MarkerFaceColor = [255 140 0]/255;
    %         title([question,' ,threshold: ',num2str(threshold)],...
    %               'Interpreter', 'none');grid on;
    %         legend('above threshold','below threshold');


