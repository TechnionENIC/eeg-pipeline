function [data_set_o, total_mat] = calcCovMat(data_set)
    data_set_o = [];
    tmp = struct;
    col = size(data_set(1).data,1);
    total_mat = zeros(size(data_set,2),col*col);
    for k = 1:size(data_set,2)
        tmp = data_set(k);
        tmp.cov_mat = covariances(tmp.data);
        total_mat(k,:) = tmp.cov_mat(:);
        data_set_o = [data_set_o tmp];
    end
end

