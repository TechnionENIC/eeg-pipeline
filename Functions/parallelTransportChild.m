
function parallelTransportChild(ds_cov_2017,ds_cov_2018,years_adapter,mat_cov_2017,mat_cov_2018)
    ds_cov_2017_names = [ds_cov_2017.name].';
    ds_cov_2017_type = [ds_cov_2017.type].';

    ds_cov_2018_names = [ds_cov_2018.name].';
    ds_cov_2018_type = [ds_cov_2018.type].';

    ind_2017 = find( years_adapter(1,1) == ds_cov_2017_names);
    ind_2018 = find( years_adapter(1,2) == ds_cov_2018_names);
    curr_child_17_type = ds_cov_2017_type(ind_2017);
    curr_child_18_type = ds_cov_2018_type(ind_2018);
    curr_child_type = [curr_child_17_type;curr_child_18_type];

    ind_story = find(curr_child_type == "story");
    ind_control = find(curr_child_type == "control");

    num_of_sections_2017 = length(ind_2017);
    num_of_sections_2018 = length(ind_2018);
    
    cov_mat_2017 = mat_cov_2017(ind_2017,:);
    cov_mat_2018 = mat_cov_2018(ind_2018,:);
    cov_mat_2017_3D = [];
    cov_mat_2018_3D = [];
    for kk=1:num_of_sections_2017
        cov_mat_2017_3D(:,:,kk) = reshape(cov_mat_2017(kk,:),sqrt(size(cov_mat_2017,2)),sqrt(size(cov_mat_2017,2)));  
    end
    for kk=1:num_of_sections_2018
        cov_mat_2018_3D(:,:,kk) = reshape(cov_mat_2018(kk,:),sqrt(size(cov_mat_2018,2)),sqrt(size(cov_mat_2018,2)));  
    end
    % CalcDiffusionMapEucDist
    % CalcDiffusionMapRimDist_SDP
    num_dim =2;
    epsilonFactor = 100; % good range 1 - 5 CalcDiffusionMapEucDist
    cov_mat_total_child = [cov_mat_2017;cov_mat_2018];
    [eval_euc_dist,evec_euc_dist] = CalcDiffusionMapRimDist_SDP(cov_mat_total_child,epsilonFactor);
    pt_dmap_2017 = evec_euc_dist(1:length(curr_child_17_type),1:num_dim);
    pt_dmap_2018 = evec_euc_dist((length(curr_child_17_type)+1):end,1:num_dim);
    pt_dmap_story = evec_euc_dist(ind_story,1:num_dim);
    pt_dmap_control = evec_euc_dist(ind_control,1:num_dim);
    % graph same child different year
    figure();
    subplot(2,2,1);
    s = scatter(pt_dmap_2017(:,1),pt_dmap_2017(:,2));
    s.MarkerFaceColor = [255 0 0]/255;
    hold on;
    s = scatter(pt_dmap_2018(:,1),pt_dmap_2018(:,2));
    s.MarkerFaceColor = [0 0 139]/255;
    legend('2017','2018');
    title('Before Parallel Transport');
    grid on;

    % graph in order to story or control
    subplot(2,2,2);
    s = scatter(pt_dmap_story(:,1),pt_dmap_story(:,2));
    s.MarkerFaceColor = [124 252 0]/255;
    hold on;
    s = scatter(pt_dmap_control(:,1),pt_dmap_control(:,2));
    s.MarkerFaceColor = [255 0 255]/255;
    legend('story','control');
    title('Before Parallel Transport');
    grid on;

    % parallel transport action
    % calculate Riemannian Mean
    rm_2017 = RiemannianMean(cov_mat_2017_3D);
    rm_2018 = RiemannianMean(cov_mat_2018_3D);

    % calculate E matrix
    E = (rm_2018*inv(rm_2017))^(1/2);

    % parallel transport calculate
    cov_mat_2017_3D_new = [];
    cov_mat_2017_new = zeros(length(num_of_sections_2017),size(cov_mat_2017,2));
    for kk=1:num_of_sections_2017
       cov_mat_2017_3D_new(:,:,kk) = E*cov_mat_2017_3D(:,:,kk)*transpose(E);
       tmp = cov_mat_2017_3D_new(:,:,kk);
       cov_mat_2017_new(kk,:) = tmp(:);
    end
    % CalcDiffusionMapEucDist
    % CalcDiffusionMapRimDist_SDP
    num_dim = 2;
    epsilonFactor = 100; % good range 1 - 5 CalcDiffusionMapEucDist
    cov_mat_new = [cov_mat_2017_new;cov_mat_2018];
    [eval_euc_dist_new,evec_euc_dist_new] = CalcDiffusionMapRimDist_SDP(cov_mat_new,epsilonFactor);
    dmap_2017_new = evec_euc_dist_new(1:length(curr_child_17_type),1:num_dim);
    dmap_2018_new = evec_euc_dist_new((length(curr_child_17_type)+1):end,1:num_dim);
    pt_dmap_story_new = evec_euc_dist_new(ind_story,1:num_dim);
    pt_dmap_control_new = evec_euc_dist_new(ind_control,1:num_dim);

    subplot(2,2,3);
    s = scatter(dmap_2017_new(:,1),dmap_2017_new(:,2));
    s.MarkerFaceColor = [255 0 0]/255;
    hold on;
    s = scatter(dmap_2018_new(:,1),dmap_2018_new(:,2));
    s.MarkerFaceColor = [0 0 139]/255;
    legend();
    legend('2017','2018');
    title('After Parallel Transport');
    grid on;

    % graph in order to story or control
    subplot(2,2,4);
    s = scatter(pt_dmap_story_new(:,1),pt_dmap_story_new(:,2));
    s.MarkerFaceColor = [124 252 0]/255;
    hold on;
    s = scatter(pt_dmap_control_new(:,1),pt_dmap_control_new(:,2));
    s.MarkerFaceColor = [255 0 255]/255;
    legend('story','control');
    title('After Parallel Transport');
    grid on;
end

