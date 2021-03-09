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
rawPipelinesToCompare = input('Enter number of pipeline to compare with space as delimeter: ');
arrPipelinesToCompare = rawPipelinesToCompare.split;

fprintf('Running comparassion between %n ipelines: \n', arrPipelinesToCompare.length);
for n=1:arrPipelinesToCompare.length
  fprintf('%s \n', piplinesFiles(str2double(arrPipelinesToCompare(n))).name);
end

datafilePath = input('Enter full path of .vhdr data file: ');
% /Users/dlevanon/Desktop/data/happy.vhdr
resultFileToPlot = containers.Map;

for n=1:arrPipelinesToCompare.length
  run(['pipelines' filesep piplinesFiles(str2double(arrPipelinesToCompare(n))).name  filesep simpleCompare]);
end

