% The function manage the preprocessing:
% 1) filtering,filtering range: [locutoff,hicutoff)]
% 2) re-referencing
function [data_set_o] = preprocessing(data_set,locutoff,hicutoff)
    data_set_o = [];
    [data_set_o1] = filteringDataSet(data_set,locutoff,hicutoff);
    [data_set_o] = rerefDataSet(data_set_o1);
end

