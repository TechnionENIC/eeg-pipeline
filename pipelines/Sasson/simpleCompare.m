% Init pipeline with default configuration
myDir = '/Users/dlevanon/Desktop/private/data/';
file_name = 'happy.vhdr';
filepath_before = '/Users/dlevanon/Desktop/private/data/output/sasson';
filepath_after = '/Users/dlevanon/Desktop/private/data/output/sasson';
cap385 = '/Users/dlevanon/Desktop/private/eeg-pipeline-main/eeglab2021.0/plugins/dipfit/standard_BESA/standard-10-5-cap385.elp';
run('preprocessing_63_func.m');
resultFileToPlot('Sasson') = '/Users/dlevanon/Desktop/private/data/output/sasson/happy_2_hlpf.set';