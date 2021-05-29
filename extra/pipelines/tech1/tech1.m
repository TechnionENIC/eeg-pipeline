clear; % clear workspace
close all;
clc; % clear command window

%% - Section 1: Importing the data
addpath(genpath('Functions'));

path_2017 = 'data\raw_stories_2017'
questionnaire_file_2017 = 'questionnaire_ans_2017.mat';
[ds_2017] = loadData(path_2017,questionnaire_file_2017);

path_2018 = 'data\raw_stories_2018'
questionnaire_file_2018 = 'questionnaire_ans_2018.mat';
[ds_2018] = loadData(path_2018,questionnaire_file_2018);

%% - Section 2: Preprocessing
% BPF parameters
low_cut_off = 4;
high_cut_off = 8;

[ds_2017_o] = preprocessing(ds_2017,low_cut_off,high_cut_off);
[ds_2018_o] = preprocessing(ds_2018,low_cut_off,high_cut_off);


%% - Section 3: Bad Channels removal
rem_channels_2017 = [1,5,10,13];
clean_ds_2017_o = removeChannels(ds_2017_o,rem_channels_2017);

rem_channels_2018 = [1,5,10,13];
clean_ds_2018_o = removeChannels(ds_2018_o,rem_channels_2018);

%% - Section 4: Split To Events
% story / control
[ds_o_2017] = splitToEvents(clean_ds_2017_o,0);
[ds_o_2018] = splitToEvents(clean_ds_2018_o,0);

%% - Section 5: Split each event to smaller sections
number_of_sections = 6;
[data_set_sections_2017] = splitToSections(ds_o_2017,number_of_sections);
[data_set_sections_2018] = splitToSections(ds_o_2018,number_of_sections);

% - Average sections
[data_set_averge_2017] = avergeOfSections(data_set_sections_2017);
[data_set_averge_2018] = avergeOfSections(data_set_sections_2018);

%% - Section 6: Calc Covariance Matrices
[ds_cov_2017, mat_cov_2017] = calcCovMat(ds_o_2017);
[ds_cov_2018, mat_cov_2018] = calcCovMat(ds_o_2018);


%% - Section 7: PCA - Dimensionality Reduction
num_dim = 2;
[pca_coeff_2017, ~] = pca(mat_cov_2017, num_dim);
[pca_coeff_2018, ~] = pca(mat_cov_2018, num_dim);


%% - Section 8: Diffusion Map - Euclidian metric
alpha = 1;  epsilon = 500;
dmap_2017_toolbox = diffusion_maps(mat_cov_2017, num_dim, alpha, epsilon);
dmap_2018_toolbox = diffusion_maps(mat_cov_2018, num_dim, alpha, epsilon);

%% - Section 9: Diffusion Map - Riemannian metric
num_dim = 2;
epsilonFactor = 100;
[eval_Rim_dist_2017,evec_Rim_dist_2017] = CalcDiffusionMapRimDist_SDP(mat_cov_2017,epsilonFactor);
dmap_2017 = evec_Rim_dist_2017(:,1:num_dim);

[eval_Rim_dist_2018,evec_Rim_dist_2018] = CalcDiffusionMapRimDist_SDP(mat_cov_2018,epsilonFactor);
dmap_2018 = evec_Rim_dist_2018(:,1:num_dim);


%% - Functions for plotting the results:
% - Plotting Histogram
questionnaire_file_2017 = 'questionnaire_ans_2017.mat';
plotAnswersHist(questionnaire_file_2017,8)
questionnaire_file_2018 = 'questionnaire_ans_2018.mat';
plotAnswersHist(questionnaire_file_2018,8)


%%
% - Plotting 2017 PCA - by children
plotByChildren(ds_cov_2017,pca_coeff_2017,'PCA - 2017');
%% - Plotting 2018 PCA - by children
plotByChildren(ds_cov_2018,pca_coeff_2018,'PCA - 2018');
%% - Plotting 2017 Diffusion Maps(Euc) - by children
plotByChildren(ds_cov_2017,dmap_2017_toolbox,'Diffusion Map(Euc) - 2017');
%% - Plotting 2018 Diffusion Maps(Euc) - by children
plotByChildren(ds_cov_2018,dmap_2018_toolbox,'Diffusion Map(Euc) - 2018');
%% - Plotting 2017 Diffusion Maps(Riemmanian) - by children
plotByChildren(ds_cov_2017,dmap_2017,'Diffusion Map(Riemmanian) - 2017');
%% - Plotting 2018 Diffusion Maps(Riemmanian) - by children
plotByChildren(ds_cov_2018,dmap_2018,'Diffusion Map(Riemmanian) - 2018');

%% - Plotting results for measures - 2017/18
coeff = pca_coeff_2017;
plotByGroups(ds_cov_2017,coeff,questionnaire_file_2017)

coeff = pca_coeff_2018;
plotByGroups(ds_cov_2018,coeff,questionnaire_file_2018)


%% - Section 10: SVM Classification
per_of_train = 70;  num_of_iterations = 5;
load questionnaire_ans_2017.mat;
[SVM_TPR_17 ,SVM_FPR_17 ,SVM_TNR_17 ,SVM_PPV_17] =...
    svmClassification(mat_cov_2017,ds_o_2017,questionnaire_ans_2017,per_of_train,num_of_iterations);
plotClassificationResults(SVM_TPR_17 ,SVM_FPR_17 ,SVM_TNR_17 ,SVM_PPV_17);

load questionnaire_ans_2018.mat;
[SVM_TPR_18 ,SVM_FPR_18 ,SVM_TNR_18 ,SVM_PPV_18] =...
    svmClassification(mat_cov_2018,ds_o_2018,questionnaire_ans_2018,per_of_train,num_of_iterations);
plotClassificationResults(SVM_TPR_18 ,SVM_FPR_18 ,SVM_TNR_18 ,SVM_PPV_18);

%% - Section 11: Min Dist Classification With Riemannian metric
per_of_train = 70;  num_of_iterations = 5;
[results_TPR_17,results_FPR_17,results_TNR_17,results_PPV_17] =...
    minDistClassification(mat_cov_2017,ds_o_2017,questionnaire_ans_2017,per_of_train,num_of_iterations);
plotClassificationResults(results_TPR_17,results_FPR_17,results_TNR_17,results_PPV_17)

[results_TPR_18,results_FPR_18,results_TNR_18,results_PPV_18] =...
    minDistClassification(mat_cov_2018,ds_o_2018,questionnaire_ans_2018,per_of_train,num_of_iterations);
plotClassificationResults(results_TPR_18,results_FPR_18,results_TNR_18,results_PPV_18)


%% - Section 12: Parallel Transport For children in both years
% "story_22_25617","stories_122_020518"
% "story_24_050717","stories_105_300518"
% "story_200617_daniel26","stories_119_230518"
% "story_130617_liad_28","stories_116_180618"
% "story_260617_adi37","stories_125_100518"

% Note: The size of the features in both kids must be the same!!!
years_adapter = ["story_260617_adi37","stories_125_100518"];
parallelTransportChild(ds_cov_2017,ds_cov_2018,years_adapter,mat_cov_2017,mat_cov_2018)

%% Parallel Transport of a Year to Referens child
clc;close all;
%2017
parallelTransportYear(mat_cov_2017,ds_cov_2017)
%2018
parallelTransportYear(mat_cov_2018,ds_cov_2018)