# Screens and Distractions - Project Code
------------------------------------------
The main script of the project is runProject.m, it contains several 
sections that runs the differents algorithms

Files Requirement :
-------------------
1. Put all the (.eeg, .vhdr, .vmrk) files of in the data folder (or subfolders in the data folder)
2. Put the questionnaire answers (.mat) in the MAT - Files folder
Notes:
* The questionnaire answers (.mat) should have a column fileName which contains the (.eeg, .vhdr, .vmrk) names
* An example of the files structure can be found in the For_SIPL_Backup 


Section 1: Importing the data
-----------------------------
Function Name:
[data_set] =loadData(path,questionnaire_file)
Inputs:
path - the path to the folder with the files (.eeg, .vhdr, .vmrk)
questionnaire_file - the .MAT file which contains the answers for the eeg files
Outputs:
data_set - data_set struct which contains the following fieldes for each subject: 
           file_name, data struct of eeglab(contains the eeg signals),  questionnaire answers for the subject
Notes:
*All of our function will get and work with this dataset!!!


Section 2: Preprocessing
------------------------
This function performs BPF to the data, and after that rereferancing to TP10 electrode
Function Name:
[data_set_o] = preprocessing(data_set,locutoff,hicutoff)
Inputs:
data_set - The data_set object from section 1
locutoff,hicutoff - band pass range in Hz
Outputs:
data_set_o - The dataset after the preprocessing



Section 3: Bad Channels removal
-------------------------------
This function removes bad chnnels from the data_set
Function Name:
[clean_data_set_o] = removeChannels(data_set,rem_channels)
Inputs:
data_set - The data_set 
rem_channels - list of channels to be removed
Outputs:
data_set_o - The dataset after the channels removal



Section 4: Split To Events
--------------------------
The function split the each file to story of control based on the triggers marks
Function Name:
[data_set_o] = splitToEvents(data_set, envolve_resting)
Inputs:
data_set - The data_set
envolve_resting - 0-no/1-yes, whether or not to delete the 4 sec of rest in the begining of the event
Outputs:
data_set_o - The dataset after the splitting



Section 5: Split each event to smaller sections
-----------------------------------------------
Function Name:
[data_set_o] = splitToSections(data_set,number_of_sections)
Inputs:
data_set - The data_set
number_of_sections - the number of sections to be splited to
Outputs:
data_set_o - The dataset after the splitting

You can average those sections with the function:
[data_set_o] = avergeOfSections(data_set)




Section 6: Calc Covariance Matrices
-----------------------------------
[data_set_o, cov_mat] = calcCovMat(data_set)
Inputs:
data_set - The data_set
Outputs:
data_set_o - The dataset with a new field which is the cov matrix
cov_mat - a matrix which its rows are the subjects and columns are the cov mat flatted



Section 7: PCA - Dimensionality Reduction
-----------------------------------------
[pca_coeff, ~] = pca(mat_cov, num_dim)
Inputs:
mat_cov - the matrix from previous section
num_dim - the new dimension
Outputs:
pca_coeff - the coefficients 


Section 8: Diffusion Map - Euclidian metric
-------------------------------------------
dmap_coeff = diffusion_maps(mat_cov, num_dim, alpha, epsilon)
Inputs:
mat_cov - the matrix from previous section
num_dim - the new dimension
alpha,epsilon - diffusion maps parameters
Outputs:
dmap_coeff - the coefficients 


Section 9: Diffusion Map - Riemannian metric
-------------------------------------------
[eval_euc_dist_2017,evec_euc_dist_2017] = CalcDiffusionMapRimDist_SDP(mat_cov,epsilonFactor);
Inputs:
mat_cov - the matrix from previous section
epsilonFactor - diffusion maps parameters
Outputs:
dmap_coeff - the coefficients


Functions for plotting the results:
-----------------------------------
The function plot the answers histogram of all the questions:
plotAnswersHist(questionnaire_file,8)
Inputs:
questionnaire_file - the .MAT file which contains the answers for the eeg files



The function plot the dimensionality reduction results (2D) and colors each  subject with different color
plotByChildren(ds_cov,dmap_coeff,title);
Inputs:
data_set - The data_set
dmap_coeff - the coefficients of the dimensionality reduction
title - title for the graph


The function split the range of answers to 4 groups and color each group with  different color
plotByGroups(ds_cov,coeff,questionnaire_file)
Inputs:
ds_cov - the data_set with the cov matrix inside of him
data_set - The data_set
dmap_coeff - the coefficients of the dimensionality reduction

Section 10: SVM Classification
------------------------------
The function split the dataset to train and test, and apply svm classifier

[results_TPR,results_FPR,results_TNR,results_PPV] = ...
    svmClassification(cov_mat,ds,questionnaire_ans,per_of_train,num_of_iterations)
Inputs:
cov_mat - from previous sections
ds - The data_set
questionnaire_ans - table which conatains the questionnaire answers
per_of_train - the percantage of the train group
num_of_iterations - number of itrataions to repeat the lassification
Outputs:
tables with the results of all questions and all iterations

The function will plot a graph with the results:
plotClassificationResults(results_TPR,results_FPR,results_TNR,results_PPV)



Section 11: Min Dist Classification With Riemannian metric
----------------------------------------------------------
[results_TPR,results_FPR,results_TNR,results_PPV] =...
    minDistClassification(cov_mat,ds,questionnaire_ans,per_of_train,num_of_iterations)
Inputs:
cov_mat - from previous sections
ds - The data_set
questionnaire_ans - table which conatains the questionnaire answers
per_of_train - the percantage of the train group
num_of_iterations - number of itrataions to repeat the lassification
Outputs:
tables with the results of all questions and all iterations
	

Section 12: Parallel Transport For children in both years
---------------------------------------------------------
The function plot the a graph of the child before and after the parallel transport
parallelTransportChild(ds_cov_2017,ds_cov_2018,years_adapter,mat_cov_2017,mat_cov_2018)
years_adapter - is an adapter for the name of the child in both years



