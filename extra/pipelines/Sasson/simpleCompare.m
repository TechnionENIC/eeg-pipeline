% Init pipeline with default configuration
myDir = 'C:\Users\Dvirs\Desktop\eeg_sample_data\21032021';
file_name = '1_LDT.vhdr';
filepath_before = 'C:\Users\Dvirs\Desktop\eeg_sample_data\21032021\sasson';
filepath_after = 'C:\Users\Dvirs\Desktop\eeg_sample_data\21032021\sasson';
cap385 = 'C:\git\eeg\toolbox\eeglab2020_0\plugins\dipfit3.6\standard_BESA\standard-10-5-cap385.elp';
run('preprocessing_63_func.m');