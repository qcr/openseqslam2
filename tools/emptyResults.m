function empty = emptyResults()
    % Creates and returns an empty config (creates all of the possible struct
    % elements)

    % Preprocessing
    empty.preprocessed.reference = [];
    empty.preprocessed.reference_indices = [];
    empty.preprocessed.query = [];
    empty.preprocessed.query_indices = [];
    
    % Difference matrices
    empty.diff_matrix.base = [];
    empty.diff_matrix.enhanced = [];

    % Matching
    empty.matches.all = [];
    empty.matches.thresholded = [];
end
