
function plotByGroups(ds_cov,coeff,questionnaire_file)

    A = load(questionnaire_file);
    vars = whos(matfile(questionnaire_file));
    questionnaire = A.(vars(1).name);
    ansTable = questionnaire(:,3:end);
    
    
for k = 3:size(ansTable,2)
    measurment_name = string(ansTable.Properties.VariableNames(k));
    measurment_vec = table2array(ansTable(:,k));
    plotMeasurment(measurment_vec, measurment_name,ds_cov , coeff);
%     savefig([measurment_name + '_DM_17_Riem.fig']);
%     saveas(gcf,[measurment_name + '_pca_17.emf'])
%     close all;
end

end

