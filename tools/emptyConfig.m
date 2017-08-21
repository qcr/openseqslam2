function empty = emptyConfig()
    % Creates and returns an empty config (creates all of the possible struct
    % elementS)

    % Reference dataset
    empty.reference.path = [];
    empty.reference.subsample_factor = [];
    
    % Query dataset
    empty.query.path = [];
    empty.query.subsample_factor = [];

    % Results
    empty.results.path = [];

    % SeqSLAM settings (image processing)
    empty.seqslam.image_processing.load = [];

    empty.seqslam.image_processing.downsample.width = [];
    empty.seqslam.image_processing.downsample.height = [];
    empty.seqslam.image_processing.downsample.method = [];

    empty.seqslam.image_processing.crop.reference = [];
    empty.seqslam.image_processing.crop.query = [];

    empty.seqslam.image_processing.normalisation.length = [];
    empty.seqslam.image_processing.normalisation.mode = [];

    % SeqSLAM settings (difference matrix)
    empty.seqslam.diff_matrix.load = [];

    empty.seqslam.diff_matrix.contrast.r_window = [];

    % SeqSLAM settings (matching)
    empty.seqslam.matching.load = [];

    empty.seqslam.matching.d_s = [];
    
    empty.seqslam.matching.trajectories.v_min = [];
    empty.seqslam.matching.trajectories.v_max = [];
    empty.seqslam.matching.trajectories.v_step = [];
    
    empty.seqslam.matching.r_recent = [];

    empty.seqslam.matching.criteria.r_window = [];
    empty.seqslam.matching.criteria.u = [];
end
