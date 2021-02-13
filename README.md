EEG Pipelines
-------------

This project purpose is to suggest an infrastructure for processing, modeling and analyzing raw EEG data relying on MatLab and EEGLAB.

To start the app GUI run:
`app1.mlapp`

![alt text](static/ICLabel.png)
![alt text](static/ica.png)
![alt text](static/inspect.png)
![alt text](static/prep.png)
![alt text](static/basic.png)


EEG analysing pipeline tutorial
-------------------------------

## Workspace setup
Includes MATLAB R2020B with Parallel Computing and [EEGLAB 2020_0 toolbox](https://sccn.ucsd.edu/eeglab/download.php), EEGLAB has both GUI & Scripting abilities and has proprietary plugin manager that I use to install: 
- clean_rawdata v2.3
- Cleanline v1.04
- firfilt v2.4
- ICLabel v1.3
- dipfit v3.7
- PrepPipeline0.55.4

Business logic is in sync with GitHub repo (without subjects data), to quickly learn how to script in EEGLAB it is recommended to use GUI and view command history by running eegh or EEG.history in terminal. There are many resources online including library of free open source EEG dataset and here, Youtube tutorials by founder and wiki page with workshops.

## EEG raw data composition

A total of 77 subjects:
2017 - 32 subjects (report claimed 24), files naming template (story/stories)_D_DDMMYY or (story/stories)_DDMMYY_D
2018 - 45 subjects (report claimed 34), files naming template
 stories_DDD_DDMMYY

Data captured by 64 channels with sampling interval in microseconds 2000, frequency is 500Hz and length of each session is about 4 minutes

If you have channels names like Fz, Cz, Pz... this naming rule is called 'international 10-5 system' which EEGLAB can find their default values according to Oostenveld and Praamstra (2001)

64Ch actiCAP snap AP-64 layout of easycap


Childerns at the age of 3-8 practice mindfulness.

Experiment can be splitted into 3 main events:

Hearing stories (30sec) marked as 11,12,13,14,15
Control hearing sounds (30sec) marked as 10
Rest marked as 3,4

Following flow format:
(Rest) Story →  (Rest) Story →  (Rest) Control →  (Rest) Story →  (Rest) Story →  (Rest) Control →  (Rest) Story 

Notice, as we can see from data, events was not marked in a consistent way


## Load raw data to EEGLAB data structure
Raw data was captured by BrainVision data files includes eeg, vhdr, vmrk
- A text header file (.vhdr) containing metadata
- A text marker file (.vmrk) containing information about events in the data
- A binary data file (.eeg) containing the voltage values of the EEG


% Details about how bad channel removal works
% -------------------------------------------
% In the output reports you can view:
%    noisyChannels               - list of identified bad channel numbers
%    badChannelsFromCorrelation  - list of bad channels identified by correlation
%    badChannelsFromDeviation    - list of bad channels identified by amplitude
%    badChannelsFromHFNoise      - list of bad channels identified by SNR
%    badChannelsFromRansac       - list of channels identified by ransac
% Method 1: too low or high amplitude. If the z score of robust
%           channel deviation falls below robustDeviationThreshold, the channel is
%           considered to be bad.
% Method 2: too low an SNR. If the z score of estimate of signal above
%           50 Hz to that below 50 Hz above highFrequencyNoiseThreshold, the channel
%           is considered to be bad.
% Method 3: low correlation with other channels. Here correlationWindowSize is the window
%           size over which the correlation is computed. If the maximum
%           correlation of the channel to the other channels falls below
%           correlationThreshold, the channel is considered bad in that window.
%           If the fraction of bad correlation windows for a channel
%           exceeds badTimeThreshold, the channel is marked as bad.
%
% After the channels from methods 2 and 3 are removed, method 4 is
% computed on the remaining signals
%
% Method 4: each channel is predicted using ransac interpolation based
%           on a ransac fraction of the channels. If the correlation of
%           the prediction to the actual behavior is too low for too
%           long, the channel is marked as bad.

## Citations and references
### Automagic - Standardized Preprocessing of Big EEG Data
[Github](https://github.com/methlabUZH/automagic) [Paper](https://www.biorxiv.org/content/10.1101/460469v3.full)
Pedroni, A., Bahreini, A., & Langer, N. (2019). Automagic: Standardized preprocessing of big EEG data. Neuroimage. doi: 10.1016/j.neuroimage.2019.06.046

### BEAPP - Batch EEG Automated Processing Platform 
[Github](https://github.com/lcnbeapp/beapp) [Paper](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6090769/)
Levin AR, Méndez Leal AS, Gabard-Durnam LJ, and O'Leary, HM. BEAPP: The Batch Electroencephalography Automated Processing Platform. Frontiers in Neuroscience (2018).

### HAPPE - The Harvard Automated Processing Pipeline for Electroencephalography
[Github](https://github.com/lcnhappe/happe) [Paper](https://www.frontiersin.org/articles/10.3389/fnins.2018.00097/full)
Gabard-Durnam LJ, Mendez Leal AS, Wilkinson CL and Levin AR (2018) The Harvard Automated Processing Pipeline for Electroencephalography (HAPPE): Standardized Processing Software for Developmental and High-Artifact Data. Front. Neurosci. 12:97. doi: 10.3389/fnins.2018.00097

### MADE - The Maryland analysis of developmental EEG pipeline
[Github](https://github.com/ChildDevLab/MADE-EEG-preprocessing-pipeline) [Paper](https://www.biorxiv.org/content/10.1101/2020.01.29.925271v1)
The Maryland Analysis of Developmental EEG (MADE) Pipeline Ranjan Debnath, George A. Buzzell, Santiago Morales, Maureen E. Bowers, Stephanie C. Leach, Nathan A. Fox bioRxiv 2020.01.29.925271; doi: https://doi.org/10.1101/2020.01.29.925271

### PREP - pipeline for standardized preprocessing of EEG
[Github](https://github.com/VisLab/EEG-Clean-Tools) [Paper](https://www.frontiersin.org/articles/10.3389/fninf.2015.00016/full)
Bigdely-Shamlo N, Mullen T, Kothe C, Su K-M and Robbins KA (2015)
The PREP pipeline: standardized preprocessing for large-scale EEG analysis
Front. Neuroinform. 9:16. doi: 10.3389/fninf.2015.00016

### ADJUST - An automatic EEG artifact detector
[Github](https://github.com/mdelpozobanos/eegadjust) [Paper](https://pubmed.ncbi.nlm.nih.gov/20636297/)
Mognon A, Jovicich J, Bruzzone L, Buiatti M. ADJUST: An automatic EEG artifact detector based on the joint use of spatial and temporal features. Psychophysiology. 2011 Feb;48(2):229-40. doi: 10.1111/j.1469-8986.2010.01061.x. PMID: 20636297.

### MARA - Multiple Artifact Rejection Algorithm
[Github](https://github.com/irenne/MARA) [Paper](https://iopscience.iop.org/article/10.1088/1741-2560/11/3/035013)
Irene Winkler, Stephanie Brandl, Franziska Horn, Eric Waldburger, Carsten Allefeld and Michael Tangermann. Robust artifactual independent component classification for BCI practitioners. Journal of Neural Engineering, 11 035013, 2014.

### SASICA - SemiAutomatic Selection of Independent Components for Artifact correction in the EEG
[Github](https://github.com/dnacombo/SASICA) [Paper](https://pubmed.ncbi.nlm.nih.gov/25791012/)
Chaumon M, Bishop DV, Busch NA. A Practical Guide to the Selection of Independent Components of the Electroencephalogram for Artifact Correction. Journal of neuroscience methods. 2015 

### FASTER - Fully automated statistical thresholding for EEG artifact rejection
[Github](https://github.com/mdelpozobanos/eegfaster) [Paper](https://www-sciencedirect-com.ezlibrary.technion.ac.il/science/article/pii/S0165027010003894)
H. Nolan, R. Whelan, and R.B. Reilly. Faster: Fully automated statistical thresholding for eeg artifact rejection. Journal of Neuroscience Methods, 192(1):152-162, 2010.

### Artifact Subspace Reconstruction (ASR)

### Makoto's_preprocessing_pipeline
[code](https://sccn.ucsd.edu/wiki/Makoto's_preprocessing_pipeline)

