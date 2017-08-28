function [ext, a, b, startToken, endToken] = imageDatasetProfile(directory)
    % TODO this function does NOT handle (or even check) if:
    % - the tokens found in the images differ (i.e. filenames differ besides
    %   number)
    % - the numbers for images are not sequential

    % Get all of the possible image extensions
    exts = arrayfun(@(x) x.ext, imformats, 'uni', 0);
    exts = [exts{:}];

    % Loop over every possible image extension, recording the extension that
    % matches the most image files in the directory
    directorySafe = fullfile(directory);
    ext = '';
    startToken = ''; endToken = '';
    a = 0; b = 0;
    for k = 1:length(exts)
        % Get the filenames of all files matching that extension
        fns = dir([directorySafe filesep() '*.' exts{k}]);
        fns = {fns.name};

        % Skip the rest of the loop if: no files matched, or number of matches
        % is less than what has been matched for a previous extension
        if isempty(fns) || (length(fns) < (b-a))
            continue;
        end

        % Use regex on the filenames, and extract the tokens
        tokens = regexp(fns, ['^(.*?)(\d+)(.?\.' exts{k} ')'], ...
            'tokens');
        nums = cellfun(@(x) str2num(x{1}{2}), tokens);
        extMax = max(nums); extMin = min(nums);
        if (extMax - extMin) > (b - a)
            a = extMin; b = extMax; ext = exts{k};
            startToken = tokens{1}{1}{1}; endToken = tokens{1}{1}{3};
        end
    end
end
