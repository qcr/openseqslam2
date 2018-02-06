function empty = emptyConfig()
    % Creates and returns an empty config (creates all of the possible struct
    % elements)

    % Reference dataset
    empty.reference.path = [];
    empty.reference.subsample_factor = [];
    empty.reference.type = [];

    empty.reference.image.ext = [];
    empty.reference.image.numbers = [];
    empty.reference.image.token_start = [];
    empty.reference.image.token_end = [];

    empty.reference.video.ext = [];
    empty.reference.video.frames = [];

    % Query dataset
    empty.query.path = [];
    empty.query.subsample_factor = [];
    empty.query.type = [];

    empty.query.image.ext = [];
    empty.query.image.numbers = [];
    empty.query.image.token_start = [];
    empty.query.image.token_end = [];

    empty.query.video.ext = [];
    empty.query.video.frames = [];
    empty.query.video.frame_rate = [];

    % Results
    empty.results.path = [];

    % SeqSLAM settings (image processing)
    empty.seqslam.image_processing.downsample.width = [];
    empty.seqslam.image_processing.downsample.height = [];
    empty.seqslam.image_processing.downsample.method = [];

    empty.seqslam.image_processing.crop.reference = [];
    empty.seqslam.image_processing.crop.query = [];

    empty.seqslam.image_processing.normalisation.threshold = [];
    empty.seqslam.image_processing.normalisation.strength = [];

    % SeqSLAM settings (difference matrix)
    empty.seqslam.diff_matrix.contrast.r_window = [];

    % SeqSLAM settings (search)
    empty.seqslam.search.d_s = [];
    empty.seqslam.search.v_min = [];
    empty.seqslam.search.v_max = [];
    empty.seqslam.search.method = []; % traj, cone, hybrid
    empty.seqslam.search.method_traj.v_step = [];

    % SeqSLAM settings (matching)
    empty.seqslam.matching.method = []; % window, thresh
    empty.seqslam.matching.method_window.r_window = [];
    empty.seqslam.matching.method_window.u = [];
    empty.seqslam.matching.method_thresh.threshold = [];

    % Visual settings (progress UI)
    empty.visual.progress.percent_freq = [];
    empty.visual.progress.preprocess_freq = [];
    empty.visual.progress.diff_matrix_freq = [];
    empty.visual.progress.enhance_freq = [];
    empty.visual.progress.match_freq = [];

    % Super parameters (parameters that modify / override parameters)
    empty.super.downsample_multiplier = [];
    empty.super.trajectory_angle = [];
    empty.super.auto_optimise_selection = []; % empty, p, r, f1
end
