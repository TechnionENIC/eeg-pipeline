% The function plot the EEG signals with a diffrent color for each child
% inputs: 
% ds_cov - data set witch contain the cov 
% dmap - points to plot (2D of the diffusion map or pca)
% my_title - title for the plot
function plotByChildren(ds_cov,dmap,my_title)
    names = [ds_cov.name];
    names_unique = unique(names);
    figure();
    for i = 1:size(names_unique,2)
        ind = find(names_unique(i) == names);
        s = scatter(dmap(ind,1),dmap(ind,2));
        s.MarkerFaceColor = [rand rand rand];
        grid on; hold on;
    end
    title(my_title);
%     saveas(gcf,[string(my_title) + '_.emf'])
end

