function nh_cleaned = cleanNewNeighborRows(nh_new_rows, delete_index)
% cleanNewNeighborRows - Cleans new neighbor rows by removing deleted points and sorting neighbors
%
% Syntax:
%   nh_cleaned = cleanNewNeighborRows(nh_new_rows, delete_index)
%
% Inputs:
%   nh_new_rows - (NxM array) New neighbor rows to be cleaned
%   delete_index - (Px1 logical or numeric array) Indices of points to be deleted
%
% Output:
%   nh_cleaned - (NxM array) Cleaned neighbor rows with deleted points removed, duplicates removed, and neighbors sorted
%
% Description:
%   This function removes references to deleted points in a new neighbor list,
%   removes duplicate neighbors, and ensures neighbor entries are compact and sorted.

    % Step 1: Trim nh_new_rows to the correct number of rows
    num_valid_rows = sum(any(nh_new_rows,2)); % Alternative to (index_neu - index_old - 1)
    nh_cleaned = nh_new_rows(1:num_valid_rows, :);

    % Step 2: Process each row
    for i = 1:size(nh_cleaned, 1)
        % Extract current neighbor entries (excluding the first column, which is the point index)
        current_neighbors = nh_cleaned(i, 2:end);
        
        % Remove deleted points from neighbor list
        current_neighbors(ismember(current_neighbors, find(delete_index))) = 0;
        
        % Keep only unique, non-zero neighbors
        cleaned_neighbors = unique(current_neighbors(current_neighbors > 0));
        
        % Write cleaned neighbors back, padded with zeros
        nh_cleaned(i, 2:end) = [cleaned_neighbors, zeros(1, size(nh_cleaned,2) - length(cleaned_neighbors) - 1)];
    end

end
