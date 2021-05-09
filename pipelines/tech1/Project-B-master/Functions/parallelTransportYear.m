function [] = parallelTransportYear(mat_cov,ds_cov)
    % Plot Before PT
    num_dim = 2;
    epsilonFactor = 100;
    [eval_euc_dist,evec_euc_dist] = CalcDiffusionMapRimDist_SDP(mat_cov,epsilonFactor);
    dmap = evec_euc_dist(:,1:num_dim);

    ds_cov_type = [ds_cov.type].';

    ind_story = find(ds_cov_type == "story");
    ind_control = find(ds_cov_type == "control");

    figure();
    subplot(1,2,1);
    s = scatter(dmap(ind_story,1),dmap(ind_story,2));
    s.MarkerFaceColor = [0 255 255]/255; grid on;
    hold on;
    s = scatter(dmap(ind_control,1),dmap(ind_control,2));
    s.MarkerFaceColor = [255 140 0]/255;
    legend('story','control');
    title('Before Parallel Transport');

    % Plot After PT
    ds_cov_names = [ds_cov.name].';
    ind_ref = find(ds_cov_names(1) == ds_cov_names);
    ind_other = find(~(ds_cov_names(1) == ds_cov_names));
    cov_mat_ref = mat_cov(ind_ref,:);
    cov_mat_other = mat_cov(ind_other,:);

    cov_mat_3D_ref = [];
    for kk=1:length(ind_ref)
        cov_mat_3D_ref(:,:,kk) = reshape(cov_mat_ref(kk,:),sqrt(size(cov_mat_ref,2)),sqrt(size(cov_mat_ref,2)));  
    end

    cov_mat_3D_other = [];
    for kk=1:length(ind_other)
        cov_mat_3D_other(:,:,kk) = reshape(cov_mat_other(kk,:),sqrt(size(cov_mat_other,2)),sqrt(size(cov_mat_other,2)));  
    end

    rm_ref = RiemannianMean(cov_mat_3D_ref);
    ds_cov_names_unique = unique(ds_cov_names(length(ind_ref)+1:end));
    cov_mat_new = [];
    for nn=1:length(ds_cov_names_unique)
        ind_other_child = find(ds_cov_names_unique(nn) == ds_cov_names);
        ind_other_child_initialized = ind_other_child-ind_ref(end);%child index in cov_mat_3D_other
        num_of_sections_for_child = length(ind_other_child);
        cov_mat_3D_other_tmp = cov_mat_3D_other(:,:,ind_other_child_initialized);
        rm_other = RiemannianMean(cov_mat_3D_other_tmp);

        % calculate E matrix
        E = (rm_ref*inv(rm_other))^(1/2);

        % parallel transport calculate
        cov_mat_3D_new = [];
        cov_mat_new_tmp = zeros(num_of_sections_for_child,size(cov_mat_other,2));
        for kk=1:num_of_sections_for_child
           cov_mat_3D_new(:,:,kk) = E*cov_mat_3D_other_tmp(:,:,kk)*transpose(E);
           tmp = cov_mat_3D_new(:,:,kk);
           cov_mat_new_tmp(kk,:) = tmp(:);
        end
        cov_mat_new = [cov_mat_new;cov_mat_new_tmp];
    end
    num_dim = 2;
    epsilonFactor = 100; % good range 1 - 5 CalcDiffusionMapEucDist
    cov_mat_new = [cov_mat_ref;cov_mat_new];
    [eval_euc_dist_new,evec_euc_dist_new] = CalcDiffusionMapRimDist_SDP(cov_mat_new,epsilonFactor);
    dmap_new = evec_euc_dist_new(:,1:num_dim);

    subplot(1,2,2);
    s = scatter(dmap_new(ind_story,1),dmap_new(ind_story,2));
    s.MarkerFaceColor = [0 255 255]/255;grid on;
    hold on;
    s = scatter(dmap_new(ind_control,1),dmap_new(ind_control,2));
    s.MarkerFaceColor = [255 140 0]/255;
    legend('story','control');
    title('After Parallel Transport');
end

