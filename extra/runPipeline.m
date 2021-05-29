clear; % clear workspace
close all;
clc; % clear command window

piplinesFiles = dir('pipelines');
numOfPipelines = length(piplinesFiles);


fprintf('\n\n--- Please make sure you edit required configuration in pipeline file before running it ---\n\n');

fprintf('Pipelines available: \n');
for n=3:numOfPipelines
 fprintf('%d) %s \n', n, piplinesFiles(n).name);
end

% TODO: add validation of range
selectedPipelineNum = input('Enter number of pipeline to run: ');
selectPipelineName = piplinesFiles(selectedPipelineNum).name;
fprintf('Running %s pipeline \n', selectPipelineName);
run(['pipelines' filesep selectPipelineName filesep selectPipelineName]);
