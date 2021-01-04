%% Description:
%  the function split the data to train and test randomly
%% Inputs:
%  data_set_cov_mat     - 
%  per_of_train         - the percent of the training data from the all data
%% Outputs:
%  train_data_set - 
%  test_data_set  - 
function [train_data_set, train_mat_cov, test_data_set, test_mat_cov] = split_data_sections(data_set, mat_cov, per_of_train)
  
    names = [];
    for i = 1:size(data_set,2)
        names = [names data_set(i).name];
    end
    
    % split according to files
    num_of_rows = length(names);
    rnd_ind = randperm(num_of_rows);
    num_of_train_ind = floor((per_of_train/100)*length(rnd_ind));
    train_ind = rnd_ind(1:num_of_train_ind);
    test_ind = rnd_ind(num_of_train_ind+1:end);

    train_data_set = [];
    train_mat_cov = [];
    % create train-set
    for k = 1:length(train_ind)
        train_data_set = [train_data_set data_set(train_ind(k))];
        train_mat_cov = [train_mat_cov ; mat_cov(train_ind(k),:)];
    end

    test_data_set = [];
    test_mat_cov = [];
    % create test-set
    for k = 1:length(test_ind)
        test_data_set = [test_data_set  data_set(test_ind(k))];
        test_mat_cov = [test_mat_cov ; mat_cov(test_ind(k),:)];
    end
end


