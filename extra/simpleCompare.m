% Init pipeline with default configuration
run('configuration.m');
RunPipelineConfiguration('studyName') = 'compare'; 
RunPipelineConfiguration('outputDir') = '../output/tech2';
RunPipelineConfiguration('dataDir') = '/Users/dlevanon/Desktop/private/data/';
RunPipelineConfiguration('runSteps') = ['1 BIDS Data', '2 HLPF'];
RunPipelineConfiguration('plotsave') = ['1 BIDS Data', '2 HLPF'];
run('tech2.m');
resultFileToPlot('tech2') = '../output/tech2/happy_2_hlpf.set';