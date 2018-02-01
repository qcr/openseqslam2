function empty = emptyGroundTruth()
    % Creates and returns an empty config (creates all of the possible struct
    % elements)

    % Ground truth data
    empty.matrix = [];
    empty.type = [];
    empty.file.path = [];
    empty.velocity.vel = [];
    empty.velocity.tol = [];
end
