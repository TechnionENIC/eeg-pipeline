% This function delete the channel (rem_channels) from the
% data set (data_set_o)
function clean_data_set_o = removeChannels(data_set_o,rem_channels)
    clean_data_set_o = data_set_o;
    for k = 1:size(data_set_o,2)
        tmp = data_set_o(k).data.data;
        tmp(rem_channels,:) = [];
        clean_data_set_o(k).data.data = tmp;
    end
end

