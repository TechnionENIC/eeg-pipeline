% Init pipeline with default configuration
myDir = 'C:\Users\neuro\Desktop\Dvir\data';
file_name = 'story_050717_20.vhdr';
filepath_before = 'C:\Users\neuro\Desktop\Dvir\sasson\before';
filepath_after = 'C:\Users\neuro\Desktop\Dvir\sasson\after';
cap385 = 'C:\git\eeg-pipeline\eeglab2021.0\plugins\dipfit\standard_BESA\standard-10-5-cap385.elp';
run('preprocessing_63_func.m');
% resultFileToPlot('Sasson') = '/Users/dlevanon/Desktop/private/data/output/sasson/happy_2_hlpf.set';