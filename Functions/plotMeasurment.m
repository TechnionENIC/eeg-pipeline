% The function plot a scatter plot of the
% measurment_vec - vec with answers of the subjects
% measurment_name - name of the measurment
% data_set - with all info of the subjects
% coeff - features to plot
function plotMeasurment(measurment_vec, measurment_name, data_set, coeff)
    num_of_groups = 4;
    [sorted_measurment, ~] = sort(measurment_vec(1:end));
    number_of_children = length(sorted_measurment);
    ind =round(linspace(1,number_of_children,num_of_groups+1));
    thresholds = sorted_measurment(ind(2:(end-1)));
    unique_thresholds = unique(thresholds);
    answers = zeros(size(data_set,2),1);
    for k=1:size(data_set,2)
        answers(k) = data_set(k).answers.(measurment_name);
    end
    
    figure();
    ind_curr_group = find(answers<unique_thresholds(1));   
    s = scatter(coeff(ind_curr_group,1),coeff(ind_curr_group,2));
    s.MarkerFaceColor = [rand rand rand];
    hold on;
    for ii = 1:length(unique_thresholds) 
        if ii == length(unique_thresholds)
            ind_curr_group = find(answers>=unique_thresholds(ii));
        else
            ind_curr_group = find((answers>=unique_thresholds(ii))&(answers<unique_thresholds(ii+1)));
        end
        s = scatter(coeff(ind_curr_group,1),coeff(ind_curr_group,2));
        s.MarkerFaceColor = [rand rand rand];
        hold on;
%         title([question,' ,threshold: ',num2str(threshold)],...
%             'Interpreter', 'none');grid on;
%         legend('above threshold','below threshold');
%         savefig([question,'2018.fig']);
    end
    title(measurment_name,'Interpreter', 'none');
    grid on;
    names = [];
    for k=1:size(data_set,2)
        names =[names; data_set(k).name];
    end
    uniq_names = unique(names);
    len_names = length(uniq_names);
%     for ii=1:len_names
%         ind_curr_child = find(names == uniq_names(ii));
%         x = coeff(ind_curr_child,1);
%         y = coeff(ind_curr_child,2);
%         k = boundary(x,y);
%         hold on;
%         plot(x(k),y(k)); 
% %       txt = '\leftarrow ';
% %         [~,min_ind] = min(y);
% %         text(x(min_ind),y(min_ind),string(uniq_names(ii)))
%     end
    if length(unique_thresholds) == 3
        legend(['measurment < ',num2str(unique_thresholds(1))],[num2str(unique_thresholds(1)),' < measurment < ',num2str(unique_thresholds(2))],[num2str(unique_thresholds(2)),' < measurment < ',num2str(unique_thresholds(3))],['measurment > ',num2str(unique_thresholds(3))]);
    elseif length(unique_thresholds) == 2
          legend(['measurment < ',num2str(unique_thresholds(1))],[num2str(unique_thresholds(1)),' < measurment < ',num2str(unique_thresholds(2))],[num2str(unique_thresholds(2)),' < measurment ']);
    end
end