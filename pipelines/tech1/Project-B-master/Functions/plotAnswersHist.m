% The function plot the hist of the questions
% Input: table which the columns are the answers, nbins of the hist
function [] = plotAnswersHist(questionnaire_file,nbins)

    A = load(questionnaire_file);
    vars = whos(matfile(questionnaire_file));
    questionnaire = A.(vars(1).name);
    ansTable = questionnaire(:,3:end);
    
    num_of_col = size(ansTable,2);
    figure();
    col_names = ansTable.Properties.VariableNames;
    for i=1:num_of_col
        %subplot(ceil(sqrt(num_of_col)),ceil(sqrt(num_of_col)),i);
        figure();
        hist(table2array(ansTable(:,i)),nbins); grid on;grid minor;
        ylabel('#subjects');
        h = findobj(gca,'Type','patch');
        h.FaceColor = [1 51/255 51/255];
        h.EdgeColor = 'w';
        title(col_names(i), 'Interpreter', 'none');
    end
end

