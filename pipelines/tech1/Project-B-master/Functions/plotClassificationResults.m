function plotClassificationResults(TPR_table ,FPR_table ,TNR_table ,PPV_table)
    col_names = FPR_table.Properties.VariableNames;
    for i = 1:size(TPR_table,2)
        FPR = nanmean(FPR_table{:,i});
        PPV = nanmean(PPV_table{:,i});
        TNR = nanmean(TNR_table{:,i});
        TPR = nanmean(TPR_table{:,i});
        X = categorical({'FPR','PPV','TNR','TPR'});
        X = reordercats(X,{'FPR','PPV','TNR','TPR'});
        y = [FPR PPV TNR TPR];
        figure('Renderer', 'painters', 'Position', [10 10 200 200])
        b = bar(X,y); ylim([0 1])
        b(1).FaceColor = [1 51/255 51/255];
        title(col_names(i), 'Interpreter', 'none'); grid on;
%         saveas(gcf,[string(col_names(i)) + '_2017.emf'])
    end
end


