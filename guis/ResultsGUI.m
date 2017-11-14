classdef ResultsGUI < handle

    properties (Constant)
        SCREENS = { ...
            'Image preprocessing', ...
            'Difference Matrix', ...
            'Sequence Matches', ...
            'Matches Video'};

        FIG_WIDTH_FACTOR = 5.5;
        FIG_HEIGHT_FACTOR = 20;
    end

    properties
        hFig;

        hScreen;

        hTitle;

        hAxA;
        hAxB;
        hAxC;
        hAxD;
        hAxMain;
        hAxVideo;

        hOpts;

        hOptsPreDataset;
        hOptsPreDatasetValue;
        hOptsPreImage;
        hOptsPreImageValue;
        hOptsPreRefresh;

        hOptsDiffContr;
        hOptsDiffCol;
        hOptsDiffColValue;

        hOptsMatchDiff;
        hOptsMatchSeqs;
        hOptsMatchMatches;
        hOptsMatchSelect;
        hOptsMatchSelectValue;
        hOptsMatchTweak;

        hOptsVidRate;
        hOptsVidRateValue;
        hOptsVidPlay;
        hOptsVidExport;

        hFocus;

        hFocusAx;
        hFocusButton;
        hFocusRef;
        hFocusRefAx;
        hFocusQuery;
        hFocusQueryAx;

        results = emptyResults();
        config = emptyConfig();

        listReference = {};
        listQuery = {};
        listMatches = {};

        selectedDiff = [];
        selectedMatch = [];

        currentVideoMatch = [];
        videoTimer = [];
    end

    methods
        function obj = ResultsGUI(results, config)
            % Create and size the GUI
            obj.createGUI();
            obj.sizeGUI();

            % Save the config and results
            obj.config = config;
            obj.results = results;

            % Populate the static lists
            obj.populateDatasetLists();

            % Start on the matches screen
            obj.hScreen.Value = 3;
            obj.openScreen(obj.hScreen.Value);

            % Finally, show the figure when we are done configuring
            obj.hFig.Visible = 'on';
        end
    end

    methods (Access = private, Static)
        function next = nextMatch(current, matches)
            % Get index of matches
            inds = find(~isnan(matches));

            % Get all that are above current
            nexts = inds(inds > current(1));

            % Return the next
            if ~isempty(nexts)
                next = [nexts(1) matches(nexts(1))];
            else
                next = [];
            end
        end
    end

    methods (Access = private)
        function cbChangeDataset(obj, src, event)
            % Grey out all of the plots because we have a change
            obj.greyAxes();

            % Update the displayed list
            if (obj.hOptsPreDatasetValue.Value > 1)
                obj.hOptsPreImageValue.String = obj.listQuery;
            else
                obj.hOptsPreImageValue.String = obj.listReference;
            end
        end

        function cbChangeImage(obj, src, event)
            % Grey out all of the plots because we have a change
            obj.greyAxes();
        end

        function cbDiffClicked(obj, src, event)
            % Figure out which diff was clicked
            obj.selectedDiff = round(obj.hAxMain.CurrentPoint(1,1:2));

            % Redraw the diff matrix screen
            obj.drawDiffMatrix();
        end

        function cbDiffOptionChange(obj, src, event)
            obj.drawDiffMatrix();
        end

        function cbExportVideo(obj, src, event)
            % Request a save location, exiting if none is provided
            [f, p] = uiputfile('*', 'Select export location');
            if isnumeric(f) || isnumeric(p)
                uiwait(errordlg(['No save location was selected, ' ...
                    'video was not exported'], 'No save location selected'));
                return;
            end

            % Save the current state of the playback UI, and disable all
            uiMatch = obj.currentVideoMatch;
            obj.hScreen.Enable = 'off';
            obj.hOptsVidRateValue.Enable = 'off';
            obj.hOptsVidPlay.Enable = 'off';
            obj.hOptsVidExport.Enable = 'off';
            obj.hOptsVidExport.String = 'Exporting...';

            % Setup the video output file, and figure out frame sizing
            v = VideoWriter(fullfile(p, f), 'Uncompressed AVI');
            v.FrameRate = str2num(obj.hOptsVidRateValue.String);

            f = getframe(obj.hAxVideo);
            fSz = size(f.cdata);
            imSz = size(obj.hAxVideo.Children(end).CData);
            boxIm = [0.5 -0.5+obj.hAxVideo.YLim(2)-imSz(1) imSz(2) imSz(1)];
            scales = [fSz(2) fSz(1)] ./ ...
                [range(obj.hAxVideo.XLim) range(obj.hAxVideo.YLim)];
            boxFr = boxIm .* repmat(scales, 1, 2);

            % Loop through each of the matches, writing the frame to the video
            open(v);
            currentMatch = ResultsGUI.nextMatch([0 0], ...
                obj.results.matching.thresholded.matches);
            while ~isempty(currentMatch)
                obj.currentVideoMatch = currentMatch;
                obj.drawVideo();
                v.writeVideo(getframe(obj.hAxVideo, boxFr));
                currentMatch = ResultsGUI.nextMatch(currentMatch, ...
                    obj.results.matching.thresholded.matches);
            end
            close(v);

            % Restore the state of the playback UI, and re-enable all
            obj.currentVideoMatch = uiMatch;
            obj.hScreen.Enable = 'on';
            obj.hOptsVidRateValue.Enable = 'on';
            obj.hOptsVidPlay.Enable = 'on';
            obj.hOptsVidExport.Enable = 'on';
            obj.hOptsVidExport.String = 'Export';

            obj.drawVideo();
        end

        function cbMatchesOptionChange(obj, src, event)
            obj.drawMatches();
        end

        function cbMatchClicked(obj, src, event)
            % Figure out which match was clicked
            ms = obj.results.matching.thresholded.matches;
            cs = [(1:length(ms))' ms];
            cs = cs(~isnan(ms),:); % Coords corresponding to each match
            vs = cs - ones(size(cs))*diag(obj.hAxMain.CurrentPoint(1,1:2));
            [x, mI] = min(sum(vs.^2, 2)); % Index for match with min distance^2
            obj.selectedMatch = cs(mI,:);

            % Update the UI selector to reflect the match
            obj.hOptsMatchSelectValue.Value = mI + 1;

            % Redraw the matches screen
            obj.drawMatches();
        end

        function cbMatchSelected(obj, src, event)
            % Update the selected match
            obj.updateSelectedMatch();

            % Redraw the matches screen
            obj.drawMatches();
        end

        function cbNextFrame(obj, src, event)
            % Get the next frame
            obj.currentVideoMatch = ResultsGUI.nextMatch( ...
                obj.currentVideoMatch, ...
                obj.results.matching.thresholded.matches);
            if isempty(obj.currentVideoMatch)
                obj.currentVideoMatch = ResultsGUI.nextMatch([0 0], ...
                    obj.results.matching.thresholded.matches);
            end

            % Redraw the axes on screen
            obj.drawVideo();
        end

        function cbPlayVideo(obj, src, event)
            % Go down two possible branches, depending on if video is playing
            if strcmpi(obj.hOptsVidPlay.String, 'play')
                % Update the UI to reflect that the video is playing
                obj.hOptsVidPlay.String = 'Pause';
                obj.hOptsVidRateValue.Enable = 'off';
                obj.hOptsVidExport.Enable = 'off';
                obj.hScreen.Enable = 'off';

                % Start the timer
                obj.videoTimer = timer();
                obj.videoTimer.BusyMode = 'queue';
                obj.videoTimer.ExecutionMode = 'fixedrate';
                obj.videoTimer.ObjectVisibility = 'off';
                obj.videoTimer.Period =  ...
                    1 / str2num(obj.hOptsVidRateValue.String);
                obj.videoTimer.TimerFcn = {@obj.cbNextFrame};
                start(obj.videoTimer);
            else
                % Update the UI to reflect that the video is now paused
                obj.hOptsVidPlay.String = 'Play';
                obj.hOptsVidRateValue.Enable = 'on';
                obj.hOptsVidExport.Enable = 'on';
                obj.hScreen.Enable = 'on';

                % Stop the timer, and delete it
                stop(obj.videoTimer);
                delete(obj.videoTimer);
                obj.videoTimer = [];
            end
        end

        function cbRefreshPreprocessed(obj, src, even)
            obj.drawPreprocessed();
        end

        function cbSelectScreen(obj, src, event)
            obj.openScreen(obj.hScreen.Value);
        end

        function cbShowSequence(obj, src, event)
            obj.hFocusButton.Enable = 'off';

            % Figure out the rs and qs
            qs = squeeze( ...
                obj.results.matching.thresholded.trajectories( ...
                obj.selectedMatch(1),1,:));
            rs = squeeze( ...
                obj.results.matching.thresholded.trajectories( ...
                obj.selectedMatch(1),2,:));

            % Call the sequence popup (it should block until closed)
            SequencePopup(qs, rs, obj.config, obj.results);

            obj.hFocusButton.Enable = 'on';
        end

        function cbTweakMatches(obj, src, event)
            % Launch the tweaking popup (and wait until done)
            tweakui = TweakMatchesPopup(obj.config, obj.results);
            uiwait(tweakui.hFig);

            % Update the config, and results (changes should only have been
            % made if apply was clicked, and not close)
            obj.results = tweakui.results;
            obj.config = tweakui.config;

            % Update the results, and update the GUI
            obj.selectedMatch = [];
            obj.hOptsMatchSelectValue.Value = 1;
            obj.updateMatches();
            obj.drawMatches();
        end

        function clearScreen(obj)
            % Hide all options
            obj.hOptsPreDataset.Visible = 'off';
            obj.hOptsPreDatasetValue.Visible = 'off';
            obj.hOptsPreImage.Visible = 'off';
            obj.hOptsPreImageValue.Visible = 'off';
            obj.hOptsPreRefresh.Visible = 'off';
            obj.hOptsDiffContr.Visible = 'off';
            obj.hOptsDiffCol.Visible = 'off';
            obj.hOptsDiffColValue.Visible = 'off';
            obj.hOptsMatchDiff.Visible = 'off';
            obj.hOptsMatchSeqs.Visible = 'off';
            obj.hOptsMatchMatches.Visible = 'off';
            obj.hOptsMatchSelect.Visible = 'off';
            obj.hOptsMatchSelectValue.Visible = 'off';
            obj.hOptsMatchTweak.Visible = 'off';
            obj.hOptsVidRate.Visible = 'off';
            obj.hOptsVidRateValue.Visible = 'off';
            obj.hOptsVidPlay.Visible = 'off';
            obj.hOptsVidExport.Visible = 'off';

            % Hide all on screen content
            obj.hAxA.Visible = 'off';
            obj.hAxA.Title.Visible = 'off';
            obj.hAxB.Visible = 'off';
            obj.hAxB.Title.Visible = 'off';
            obj.hAxC.Visible = 'off';
            obj.hAxC.Title.Visible = 'off';
            obj.hAxD.Visible = 'off';
            obj.hAxD.Title.Visible = 'off';
            obj.hAxMain.Visible = 'off';
            obj.hAxMain.Title.Visible = 'off';
            obj.hAxVideo.Visible = 'off';
            obj.hAxVideo.Title.Visible = 'off';

            obj.hFocus.Visible = 'off';

            % Clear the axes
            cla(obj.hAxA);
            cla(obj.hAxB);
            cla(obj.hAxC);
            cla(obj.hAxD);
            cla(obj.hAxMain);
            cla(obj.hAxVideo);

            % Remove any screen dependent callbacks
            obj.hAxMain.ButtonDownFcn = {};
        end

        function createGUI(obj)
            % Create the figure (and hide it)
            obj.hFig = figure('Visible', 'off');
            GUISettings.applyFigureStyle(obj.hFig);
            obj.hFig.Name = 'OpenSeqSLAM2.0 Results';

            % Generic elements
            obj.hScreen = uicontrol('Style', 'popupmenu');
            GUISettings.applyUIControlStyle(obj.hScreen);
            obj.hScreen.String = ResultsGUI.SCREENS;

            obj.hTitle = uicontrol('Style', 'text');
            GUISettings.applyUIControlStyle(obj.hTitle);
            GUISettings.setFontScale(obj.hTitle, 2.5);
            obj.hTitle.FontWeight = 'bold';
            obj.hTitle.String = 'Testing 1 2 3';

            % Axes
            obj.hAxA = axes();
            GUISettings.applyUIAxesStyle(obj.hAxA);
            obj.hAxA.Visible = 'off';

            obj.hAxB = axes();
            GUISettings.applyUIAxesStyle(obj.hAxB);
            obj.hAxB.Visible = 'off';

            obj.hAxC = axes();
            GUISettings.applyUIAxesStyle(obj.hAxC);
            obj.hAxC.Visible = 'off';

            obj.hAxD = axes();
            GUISettings.applyUIAxesStyle(obj.hAxD);
            obj.hAxD.Visible = 'off';

            obj.hAxMain = axes();
            GUISettings.applyUIAxesStyle(obj.hAxMain);
            obj.hAxMain.Visible = 'off';

            obj.hAxVideo = axes();
            GUISettings.applyUIAxesStyle(obj.hAxVideo);
            obj.hAxVideo.Visible = 'off';

            % Options area for each screen
            obj.hOpts = uipanel();
            GUISettings.applyUIPanelStyle(obj.hOpts);
            obj.hOpts.Title = 'Options';

            obj.hOptsPreDataset = uicontrol('Style', 'text');
            obj.hOptsPreDataset.Parent = obj.hOpts;
            GUISettings.applyUIControlStyle(obj.hOptsPreDataset);
            obj.hOptsPreDataset.String = 'Dataset:';

            obj.hOptsPreDatasetValue = uicontrol('Style', 'popupmenu');
            obj.hOptsPreDatasetValue.Parent = obj.hOpts;
            GUISettings.applyUIControlStyle(obj.hOptsPreDatasetValue);
            obj.hOptsPreDatasetValue.String = {'Reference', 'Query'};

            obj.hOptsPreImage = uicontrol('Style', 'text');
            obj.hOptsPreImage.Parent = obj.hOpts;
            GUISettings.applyUIControlStyle(obj.hOptsPreImage);
            obj.hOptsPreImage.String = 'Image:';

            obj.hOptsPreImageValue = uicontrol('Style', 'popupmenu');
            obj.hOptsPreImageValue.Parent = obj.hOpts;
            GUISettings.applyUIControlStyle(obj.hOptsPreImageValue);
            obj.hOptsPreImageValue.String = '';

            obj.hOptsPreRefresh = uicontrol('Style', 'pushbutton');
            obj.hOptsPreRefresh.Parent = obj.hOpts;
            GUISettings.applyUIControlStyle(obj.hOptsPreRefresh);
            obj.hOptsPreRefresh.String = 'Refresh';

            obj.hOptsDiffContr = uicontrol('Style', 'checkbox');
            obj.hOptsDiffContr.Parent = obj.hOpts;
            GUISettings.applyUIControlStyle(obj.hOptsDiffContr);
            obj.hOptsDiffContr.String = 'Contrast Enhanced';

            obj.hOptsDiffCol = uicontrol('Style', 'text');
            obj.hOptsDiffCol.Parent = obj.hOpts;
            GUISettings.applyUIControlStyle(obj.hOptsDiffCol);
            obj.hOptsDiffCol.String = 'Outlier Fading:';

            obj.hOptsDiffColValue = uicontrol('Style', 'slider');
            obj.hOptsDiffColValue.Parent = obj.hOpts;
            GUISettings.applyUIControlStyle(obj.hOptsDiffColValue);

            obj.hOptsMatchDiff = uicontrol('Style', 'checkbox');
            obj.hOptsMatchDiff.Parent = obj.hOpts;
            GUISettings.applyUIControlStyle(obj.hOptsMatchDiff);
            obj.hOptsMatchDiff.String = 'Show Difference Matrix';
            obj.hOptsMatchDiff.Value = 1;

            obj.hOptsMatchSeqs = uicontrol('Style', 'checkbox');
            obj.hOptsMatchSeqs.Parent = obj.hOpts;
            GUISettings.applyUIControlStyle(obj.hOptsMatchSeqs);
            obj.hOptsMatchSeqs.String = 'Plot Sequences';

            obj.hOptsMatchMatches = uicontrol('Style', 'checkbox');
            obj.hOptsMatchMatches.Parent = obj.hOpts;
            GUISettings.applyUIControlStyle(obj.hOptsMatchMatches);
            obj.hOptsMatchMatches.String = 'Plot Matches';
            obj.hOptsMatchMatches.Value = 1;

            obj.hOptsMatchSelect = uicontrol('Style', 'text');
            obj.hOptsMatchSelect.Parent = obj.hOpts;
            GUISettings.applyUIControlStyle(obj.hOptsMatchSelect);
            obj.hOptsMatchSelect.String = 'Selected Match:';

            obj.hOptsMatchSelectValue = uicontrol('Style', 'popupmenu');
            obj.hOptsMatchSelectValue.Parent = obj.hOpts;
            GUISettings.applyUIControlStyle(obj.hOptsMatchSelectValue);
            obj.hOptsMatchSelectValue.String = '';

            obj.hOptsMatchTweak = uicontrol('Style', 'pushbutton');
            obj.hOptsMatchTweak.Parent = obj.hOpts;
            GUISettings.applyUIControlStyle(obj.hOptsMatchTweak);
            obj.hOptsMatchTweak.String = 'Tweak matching';

            obj.hOptsVidRate = uicontrol('Style', 'text');
            obj.hOptsVidRate.Parent = obj.hOpts;
            GUISettings.applyUIControlStyle(obj.hOptsVidRate);
            obj.hOptsVidRate.String = 'Frame rate (Hz):';

            obj.hOptsVidRateValue = uicontrol('Style', 'edit');
            obj.hOptsVidRateValue.Parent = obj.hOpts;
            GUISettings.applyUIControlStyle(obj.hOptsVidRateValue);
            obj.hOptsVidRateValue.String = '1';

            obj.hOptsVidPlay = uicontrol('Style', 'pushbutton');
            obj.hOptsVidPlay.Parent = obj.hOpts;
            GUISettings.applyUIControlStyle(obj.hOptsVidPlay);
            obj.hOptsVidPlay.String = 'Play';

            obj.hOptsVidExport = uicontrol('Style', 'pushbutton');
            obj.hOptsVidExport.Parent = obj.hOpts;
            GUISettings.applyUIControlStyle(obj.hOptsVidExport);
            obj.hOptsVidExport.String = 'Export...';

            % Focus Pane
            obj.hFocus = uipanel();
            GUISettings.applyUIPanelStyle(obj.hFocus);
            obj.hFocus.Title = 'Focus: Off';

            obj.hFocusAx = axes();
            obj.hFocusAx.Parent = obj.hFocus;
            GUISettings.applyUIAxesStyle(obj.hFocusAx);
            obj.hFocusAx.Visible = 'off';

            obj.hFocusButton = uicontrol('Style', 'pushbutton');
            obj.hFocusButton.Parent = obj.hFocus;
            GUISettings.applyUIControlStyle(obj.hFocusButton);
            obj.hFocusButton.String = 'Show sequence';

            obj.hFocusRef = uicontrol('Style', 'text');
            obj.hFocusRef.Parent = obj.hFocus;
            GUISettings.applyUIControlStyle(obj.hFocusRef);
            obj.hFocusRef.String = 'Reference Image:';

            obj.hFocusRefAx = axes();
            obj.hFocusRefAx.Parent = obj.hFocus;
            GUISettings.applyUIAxesStyle(obj.hFocusRefAx);
            obj.hFocusRefAx.Visible = 'off';

            obj.hFocusQuery = uicontrol('Style', 'text');
            obj.hFocusQuery.Parent = obj.hFocus;
            GUISettings.applyUIControlStyle(obj.hFocusQuery);
            obj.hFocusQuery.String = 'Query Image:';

            obj.hFocusQueryAx = axes();
            obj.hFocusQueryAx.Parent = obj.hFocus;
            GUISettings.applyUIAxesStyle(obj.hFocusQueryAx);
            obj.hFocusQueryAx.Visible = 'off';

            % Callbacks (must be last, otherwise empty objects passed...)
            obj.hScreen.Callback = {@obj.cbSelectScreen};
            obj.hOptsPreDatasetValue.Callback = {@obj.cbChangeDataset};
            obj.hOptsPreImageValue.Callback = {@obj.cbChangeImage};
            obj.hOptsPreRefresh.Callback = {@obj.cbRefreshPreprocessed};
            obj.hOptsDiffContr.Callback = {@obj.cbDiffOptionChange};
            obj.hOptsDiffColValue.Callback = {@obj.cbDiffOptionChange};
            obj.hOptsMatchDiff.Callback = {@obj.cbMatchesOptionChange};
            obj.hOptsMatchSeqs.Callback = {@obj.cbMatchesOptionChange};
            obj.hOptsMatchMatches.Callback = {@obj.cbMatchesOptionChange};
            obj.hOptsMatchSelectValue.Callback = {@obj.cbMatchSelected};
            obj.hOptsMatchTweak.Callback = {@obj.cbTweakMatches};
            obj.hOptsVidPlay.Callback = {@obj.cbPlayVideo};
            obj.hOptsVidExport.Callback = {@obj.cbExportVideo};
            obj.hFocusButton.Callback = {@obj.cbShowSequence};
        end

        function drawPreprocessed(obj)
            % Get all of the requested parameters
            ds = lower(obj.hOptsPreDatasetValue.String{ ...
                obj.hOptsPreDatasetValue.Value});
            img = datasetOpenImage(obj.config.(ds), ...
                obj.hOptsPreImageValue.Value, ...
                obj.results.preprocessed.([ds '_indices']));

            % Grab the images from each of the steps
            [img_out, imgs] = SeqSLAMInstance.preprocessSingle(img, ...
                obj.config.seqslam.image_processing, ...
                lower(obj.hOptsPreDatasetValue.String{ ...
                obj.hOptsPreDatasetValue.Value}), 1);

            % Plot the 4 images
            cla(obj.hAxA); imshow(img, 'Parent', obj.hAxA);
            cla(obj.hAxB); imshow(imgs{1}, 'Parent', obj.hAxB);
            cla(obj.hAxC); imshow(imgs{2}, 'Parent', obj.hAxC);
            cla(obj.hAxD); imshow(img_out, 'Parent', obj.hAxD);

            % Style the plots
            obj.hAxA.Title.String = ['Original (' ...
                num2str(size(img, 2)) 'x' ...
                num2str(size(img, 1)) ')'];
            obj.hAxB.Title.String = ['Greyscale (' ...
                num2str(size(imgs{1}, 2)) 'x' ...
                num2str(size(imgs{1}, 1)) ')'];
            obj.hAxC.Title.String = ['Resized and cropped (' ...
                num2str(size(imgs{2}, 2)) 'x' ...
                num2str(size(imgs{2}, 1)) ')'];
            obj.hAxD.Title.String = ['Patch normalised (' ...
                num2str(size(img_out, 2)) 'x' ...
                num2str(size(img_out, 1)) ')'];
            GUISettings.axesHide(obj.hAxA);
            GUISettings.axesHide(obj.hAxB);
            GUISettings.axesHide(obj.hAxC);
            GUISettings.axesHide(obj.hAxD);

            % Do the prettying up (don't know why I have to do this after
            % every plot call Matlab...)
            obj.hAxMain.Visible = 'off';
        end

        function drawDiffMatrix(obj)
            % Useful temporaries
            szDiff = size(obj.results.diff_matrix.enhanced);
            d = obj.selectedDiff;
            ds = obj.config.seqslam.matching.trajectory.d_s;

            % Clear the axis to start
            cla(obj.hAxMain);
            hold(obj.hAxMain, 'on');

            % Draw the requested difference matrix
            % TODO apply colour scaling!
            if obj.hOptsDiffContr.Value
                imagesc(obj.hAxMain, obj.results.diff_matrix.enhanced);
            else
                imagesc(obj.hAxMain, obj.results.diff_matrix.base);
            end
            hold(obj.hAxMain, 'off');

            % Style the plot
            GUISettings.axesDiffMatrixStyle(obj.hAxMain, szDiff);
            arrayfun(@(x) set(x, 'HitTest', 'off'), obj.hAxMain.Children);

            % Update the focus area and plots
            if ~isempty(d)
                % Display, and update the title with the details
                obj.hFocus.Visible = 'on';
                obj.hFocus.Title = ['Focus: centred on (query #' ...
                    num2str(d(1)) ', ref #' num2str(d(2)) ')'];

                % Get the limits of the cutout, and the cutout data
                rLimits = d(2) - floor(ds/2) + [0 ds-1];
                qLimits = d(1) - floor(ds/2) + [0 ds-1];
                rDataLimits = max(rLimits(1),1) : min(rLimits(2), szDiff(1));
                qDataLimits = max(qLimits(1),1) : min(qLimits(2), szDiff(1));

                % Draw the focus box in the main axis
                hold(obj.hAxMain, 'on');
                h = rectangle(obj.hAxMain, 'Position', ...
                    [qDataLimits(1), rDataLimits(1), ...
                    range(qDataLimits), range(rDataLimits)]);
                hold(obj.hAxMain, 'off');

                % Draw the elements of the focus cutout
                cla(obj.hFocusAx);
                hold(obj.hFocusAx, 'on');
                if obj.hOptsDiffContr.Value
                    imagesc(obj.hFocusAx, qDataLimits, rDataLimits, ...
                        obj.results.diff_matrix.enhanced(rDataLimits, ...
                        qDataLimits));
                else
                    imagesc(obj.hFocusAx, qDataLimits, rDataLimits, ...
                        obj.results.diff_matrix.base(rDataLimits, ...
                        qDataLimits));
                end
                h = plot(obj.hFocusAx, d(1), d(2), 'k.');
                h.MarkerSize = h.MarkerSize * 6;
                hold(obj.hFocusAx, 'off');
                GUISettings.axesDiffMatrixFocusStyle(obj.hFocusAx, ...
                    qLimits, rLimits);

                % Draw the reference and query images
                imshow(datasetOpenImage(obj.config.('reference'), d(2), ...
                    obj.results.preprocessed.('reference_indices')), ...
                    'Parent', obj.hFocusRefAx);
                imshow(datasetOpenImage(obj.config.('query'), d(1), ...
                    obj.results.preprocessed.('query_indices')), ...
                    'Parent', obj.hFocusQueryAx);
            else
                obj.hFocus.Visible = 'off';
                obj.hFocus.Title = ['Focus: Off'];
            end
        end

        function drawMatches(obj)
            % Useful temporaries
            m = obj.selectedMatch;
            szDiff = size(obj.results.diff_matrix.enhanced);
            szTrajs = size(obj.results.matching.thresholded.trajectories);

            % Fill in the difference matrix plot, with any requested overlaying
            % features
            cla(obj.hAxMain);
            hold(obj.hAxMain, 'on');
            if obj.hOptsMatchDiff.Value
                h = imagesc(obj.hAxMain, obj.results.diff_matrix.enhanced);
                h.AlphaData = 0.25;
            end
            if obj.hOptsMatchSeqs.Value
                arrayfun(@(x) plot(obj.hAxMain, ...
                    squeeze(obj.results.matching.thresholded.trajectories( ...
                    x,1,:)), ...
                    squeeze(obj.results.matching.thresholded.trajectories( ...
                    x,2,:)), ...
                    '-'), 1:szTrajs(1));
            end
            if obj.hOptsMatchMatches.Value
                plot(obj.hAxMain, ...
                    obj.results.matching.thresholded.matches, '.');
            end
            if ~isempty(m)
                plot(obj.hAxMain, [m(1) m(1)], [1 szDiff(1)], 'k--', ...
                    [1 szDiff(2)], [m(2) m(2)], 'k--');
            end
            hold(obj.hAxMain, 'off');

            % Style the difference matrix plot
            GUISettings.axesDiffMatrixStyle(obj.hAxMain, szDiff);
            arrayfun(@(x) set(x, 'HitTest', 'off'), obj.hAxMain.Children);

            % Update the focus area and plots
            if ~isempty(m)
                % Get the trajectory, and update the title with its details
                t = obj.results.matching.thresholded.trajectories(m(1),:,:);
                obj.hFocus.Visible = 'on';
                obj.hFocus.Title = ['Focus: (matched #' num2str(m(1)) ...
                    ' with #' num2str(m(2)) ')'];

                % Get maximum "distance", and limits for the focus cutout
                ds = max(obj.config.seqslam.matching.trajectory.d_s, ...
                    1 + range(t(:,2,:)));
                if ds == obj.config.seqslam.matching.trajectory.d_s
                    rLimits = m(2) - floor(ds/2) + [0 ds-1];
                else
                    rLimits = [min(t(:,2,:)) max(t(:,2,:))];
                end
                qLimits = m(1) - floor(ds/2) + [0 ds-1];

                % Draw the elements of the focus cutout
                cla(obj.hFocusAx);
                hold(obj.hFocusAx, 'on');
                if obj.hOptsMatchDiff.Value
                    qDataLimits = max(qLimits(1), 1) : ...
                        min(qLimits(2), szDiff(2));
                    rDataLimits = max(rLimits(1), 1) : ...
                        min(rLimits(2), szDiff(1));
                    h = imagesc(obj.hFocusAx, qDataLimits, rDataLimits, ...
                        obj.results.diff_matrix.enhanced(rDataLimits, ...
                        qDataLimits));
                end
                if obj.hOptsMatchSeqs.Value
                    h = plot(obj.hFocusAx, squeeze(t(:,1,:)), ...
                        squeeze(t(:,2,:)), 'k-');
                    h.LineWidth = h.LineWidth * 5;
                end
                if obj.hOptsMatchMatches.Value
                    h = plot(obj.hFocusAx, m(1), ...
                        obj.results.matching.thresholded.matches(m(1)), 'k.');
                    h.MarkerSize = h.MarkerSize * 6;
                end
                hold(obj.hFocusAx, 'off');
                GUISettings.axesDiffMatrixFocusStyle(obj.hFocusAx, ...
                    qLimits, rLimits);

                % Draw the reference and query images
                imshow(datasetOpenImage(obj.config.('reference'), m(2), ...
                    obj.results.preprocessed.('reference_indices')), ...
                    'Parent', obj.hFocusRefAx);
                imshow(datasetOpenImage(obj.config.('query'), m(1), ...
                    obj.results.preprocessed.('query_indices')), ...
                    'Parent', obj.hFocusQueryAx);
            else
                obj.hFocus.Visible = 'off';
                obj.hFocus.Title = ['Focus: Off'];
            end
        end

        function drawVideo(obj)
            hold(obj.hAxVideo, 'on');

            % Build the frame, then display it
            qIm = datasetOpenImage( ...
                obj.config.query, ...
                obj.currentVideoMatch(1), ...
                obj.results.preprocessed.query_indices);
            rIm = datasetOpenImage( ...
                obj.config.reference, ...
                obj.currentVideoMatch(2), ...
                obj.results.preprocessed.reference_indices);
            frame = [qIm; rIm];
            imshow(frame, 'Parent', obj.hAxVideo);

            % Draw the text over the top
            inset = 0.05 * size(qIm,1);
            t = text(obj.hAxVideo, inset, inset, ...
                ['Query #' num2str(obj.currentVideoMatch(1))]);
            t.FontSize = 16;
            t.Color = 'r';
            t = text(obj.hAxVideo, inset, size(frame,1) - inset, ...
                ['Reference #' num2str(obj.currentVideoMatch(2))]);
            t.FontSize = 16;
            t.Color = 'r';

            hold(obj.hAxVideo, 'off');
        end

        function greyAxes(obj)
            % Apply alpha to axes
            alpha(obj.hAxA, 0.2);
            alpha(obj.hAxB, 0.2);
            alpha(obj.hAxC, 0.2);
            alpha(obj.hAxD, 0.2);
            alpha(obj.hAxMain, 0.2);

            % Hide the titles
            obj.hAxA.Title.Visible = 'off';
            obj.hAxB.Title.Visible = 'off';
            obj.hAxC.Title.Visible = 'off';
            obj.hAxD.Title.Visible = 'off';
            obj.hAxMain.Title.Visible = 'off';
        end

        function openScreen(obj, screen)
            % Clear everything off the screen
            obj.clearScreen();

            % Update the title
            obj.hTitle.String = ResultsGUI.SCREENS{screen};

            % Add the appropriate elements for the screen
            if (screen == 1)
                % Image preprocessing screen
                % Show the appropriate options
                obj.hOptsPreDataset.Visible = 'on';
                obj.hOptsPreDatasetValue.Visible = 'on';
                obj.hOptsPreImage.Visible = 'on';
                obj.hOptsPreImageValue.Visible = 'on';
                obj.hOptsPreRefresh.Visible = 'on';

                % Turn on the required axes
                obj.hAxMain.Visible = 'on';

                % Select the dataset, and manually trigger the refresh
                obj.cbChangeDataset();
                obj.cbRefreshPreprocessed();
            elseif (screen == 2)
                % Difference matrix screen
                % Show the appropriate options
                obj.hOptsDiffContr.Visible = 'on';
                obj.hOptsDiffCol.Visible = 'on';
                obj.hOptsDiffColValue.Visible = 'on';

                % Turn on the required axes
                obj.hAxMain.Visible = 'on';

                % Turn on the focus box
                obj.hFocus.Visible = 'on';
                obj.hFocusButton.Visible = 'off';

                % Register the callback for the main axis
                obj.hAxMain.ButtonDownFcn = {@obj.cbDiffClicked};

                % Draw the content
                obj.drawDiffMatrix();
            elseif(screen == 3)
                % Sequence matches screen
                % Show the appropriate options
                obj.hOptsMatchDiff.Visible = 'on';
                obj.hOptsMatchSeqs.Visible = 'on';
                obj.hOptsMatchMatches.Visible = 'on';
                obj.hOptsMatchSelect.Visible = 'on';
                obj.hOptsMatchSelectValue.Visible = 'on';
                obj.hOptsMatchTweak.Visible = 'on';

                % Turn on the required axes
                obj.hAxMain.Visible = 'on';

                % Turn on the focus box
                obj.hFocus.Visible = 'on';
                obj.hFocusButton.Visible = 'on';

                % Register the callback for the main axis
                obj.hAxMain.ButtonDownFcn = {@obj.cbMatchClicked};

                % Create and draw the content
                obj.updateMatches();
                obj.drawMatches();
            elseif (screen == 4)
                % Matches video screen
                obj.hOptsVidRate.Visible = 'on';
                obj.hOptsVidRateValue.Visible = 'on';
                obj.hOptsVidPlay.Visible = 'on';
                obj.hOptsVidExport.Visible = 'on';

                % Turn on the required axes
                obj.hAxVideo.Visible = 'on';

                % Always start at the first frame
                obj.currentVideoMatch = ResultsGUI.nextMatch( ...
                    [0 0], obj.results.matching.thresholded.matches);

                % Draw the content
                obj.drawVideo();
            end

            % Force a draw at the end
            drawnow();
        end

        function populateDatasetLists(obj)
            % Get the lists for each of the datasets
            obj.listReference = datasetImageList(obj.config.reference, ...
                obj.results.preprocessed.reference_indices);
            obj.listQuery = datasetImageList(obj.config.query, ...
                obj.results.preprocessed.query_indices);
        end

        function populateMatchList(obj)
            % transforming the query dataset list
            obj.listMatches = ['All' ...
                obj.listQuery(~isnan(obj.results.matching.thresholded.mask))];
        end

        function sizeGUI(obj)
            % Statically size for now
            % TODO handle potential resizing gracefully
            widthUnit = obj.hTitle.Extent(3);
            heightUnit = obj.hTitle.Extent(4);

            % Size and position the figure
            obj.hFig.Position = [0, 0, ...
                widthUnit * ResultsGUI.FIG_WIDTH_FACTOR, ...
                heightUnit * ResultsGUI.FIG_HEIGHT_FACTOR];
            movegui(obj.hFig, 'center');

            % Now that the figure (space for placing UI elements is set),
            % size all of the elements
            SpecSize.size(obj.hScreen, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.8);

            SpecSize.size(obj.hTitle, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hTitle, SpecSize.WIDTH, SpecSize.MATCH, ...
                obj.hFig, GUISettings.PAD_MED);

            SpecSize.size(obj.hOpts, SpecSize.HEIGHT, SpecSize.ABSOLUTE, ...
                1.5*heightUnit);
            SpecSize.size(obj.hOpts, SpecSize.WIDTH, SpecSize.MATCH, ...
                obj.hFig, GUISettings.PAD_MED);

            SpecSize.size(obj.hOptsPreDataset, SpecSize.WIDTH, SpecSize.WRAP);
            SpecSize.size(obj.hOptsPreDatasetValue, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_LARGE);
            SpecSize.size(obj.hOptsPreImage, SpecSize.WIDTH, SpecSize.WRAP);
            SpecSize.size(obj.hOptsPreImageValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hOpts, 0.6);
            SpecSize.size(obj.hOptsPreRefresh, SpecSize.WIDTH, SpecSize.WRAP);

            SpecSize.size(obj.hOptsDiffContr, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_LARGE);
            SpecSize.size(obj.hOptsDiffCol, SpecSize.WIDTH, SpecSize.WRAP);
            SpecSize.size(obj.hOptsDiffColValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hOpts, 0.5);

            SpecSize.size(obj.hOptsMatchDiff, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_LARGE);
            SpecSize.size(obj.hOptsMatchSeqs, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_LARGE);
            SpecSize.size(obj.hOptsMatchMatches, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_LARGE);
            SpecSize.size(obj.hOptsMatchSelect, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hOptsMatchSelectValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hOpts, 0.4);
            SpecSize.size(obj.hOptsMatchTweak, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hOpts, 0.1);

            SpecSize.size(obj.hOptsVidRate, SpecSize.WIDTH, SpecSize.WRAP, ...
                GUISettings.PAD_SMALL);
            SpecSize.size(obj.hOptsVidRateValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hOpts, 0.1);
            SpecSize.size(obj.hOptsVidPlay, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hOpts, 0.15);
            SpecSize.size(obj.hOptsVidExport, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hOpts, 0.15);

            SpecSize.size(obj.hAxA, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.25);
            SpecSize.size(obj.hAxA, SpecSize.HEIGHT, SpecSize.RATIO, 3/4);
            SpecSize.size(obj.hAxB, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.25);
            SpecSize.size(obj.hAxB, SpecSize.HEIGHT, SpecSize.RATIO, 3/4);
            SpecSize.size(obj.hAxC, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.25);
            SpecSize.size(obj.hAxC, SpecSize.HEIGHT, SpecSize.RATIO, 3/4);
            SpecSize.size(obj.hAxD, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.25);
            SpecSize.size(obj.hAxD, SpecSize.HEIGHT, SpecSize.RATIO, 3/4);

            SpecSize.size(obj.hAxMain, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.6);
            SpecSize.size(obj.hAxMain, SpecSize.HEIGHT, SpecSize.RATIO, 3/4);

            SpecSize.size(obj.hAxVideo, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.9);
            SpecSize.size(obj.hAxVideo, SpecSize.HEIGHT, SpecSize.PERCENT, ...
                obj.hFig, 0.7);

            SpecSize.size(obj.hFocus, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.3);
            SpecSize.size(obj.hFocus, SpecSize.HEIGHT, SpecSize.PERCENT, ...
                obj.hFig, 0.775);
            SpecSize.size(obj.hFocusAx, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFocus, 0.6);
            SpecSize.size(obj.hFocusAx, SpecSize.HEIGHT, SpecSize.RATIO, 3/4);
            SpecSize.size(obj.hFocusButton, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFocus, 0.5)
            SpecSize.size(obj.hFocusRef, SpecSize.WIDTH, SpecSize.WRAP);
            SpecSize.size(obj.hFocusRefAx, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFocus, 0.5);
            SpecSize.size(obj.hFocusRefAx, SpecSize.HEIGHT, SpecSize.RATIO, ...
                3/4);
            SpecSize.size(obj.hFocusQuery, SpecSize.WIDTH, SpecSize.WRAP);
            SpecSize.size(obj.hFocusQueryAx, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFocus, 0.5);
            SpecSize.size(obj.hFocusQueryAx, SpecSize.HEIGHT, ...
                SpecSize.RATIO, 3/4);

            % Then, systematically place
            SpecPosition.positionIn(obj.hScreen, obj.hFig, ...
                SpecPosition.TOP, GUISettings.PAD_SMALL);
            SpecPosition.positionIn(obj.hScreen, obj.hFig, ...
                SpecPosition.CENTER_X);

            SpecPosition.positionRelative(obj.hTitle, obj.hScreen, ...
                SpecPosition.BELOW, GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hTitle, obj.hFig, ...
                SpecPosition.LEFT, GUISettings.PAD_LARGE);

            SpecPosition.positionRelative(obj.hOpts, obj.hTitle, ...
                SpecPosition.BELOW, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hOpts, obj.hFig, ...
                SpecPosition.CENTER_X);

            SpecPosition.positionIn(obj.hOptsPreDataset, obj.hOpts, ...
                SpecPosition.TOP, 1.75*GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hOptsPreDataset, obj.hOpts, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hOptsPreDatasetValue, ...
                obj.hOptsPreDataset, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hOptsPreDatasetValue, ...
                obj.hOptsPreDataset, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hOptsPreRefresh, ...
                obj.hOptsPreDataset, SpecPosition.CENTER_Y);
            SpecPosition.positionIn(obj.hOptsPreRefresh, obj.hOpts, ...
                SpecPosition.RIGHT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hOptsPreImageValue, ...
                obj.hOptsPreDataset, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hOptsPreImageValue, ...
                obj.hOptsPreRefresh, SpecPosition.LEFT_OF, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hOptsPreImage, ...
                obj.hOptsPreDataset, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hOptsPreImage, ...
                obj.hOptsPreImageValue, SpecPosition.LEFT_OF, ...
                GUISettings.PAD_MED);

            SpecPosition.positionIn(obj.hOptsDiffContr, obj.hOpts, ...
                SpecPosition.TOP, 1.75*GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hOptsDiffContr, obj.hOpts, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hOptsDiffCol, ...
                obj.hOptsDiffContr, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hOptsDiffCol, ...
                obj.hOptsDiffContr, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hOptsDiffColValue, ...
                obj.hOptsDiffCol, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hOptsDiffColValue, ...
                obj.hOptsDiffCol, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_LARGE);

            SpecPosition.positionIn(obj.hOptsMatchDiff, obj.hOpts, ...
                SpecPosition.TOP, 1.75*GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hOptsMatchDiff, obj.hOpts, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hOptsMatchSeqs, ...
                obj.hOptsMatchDiff, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hOptsMatchSeqs, ...
                obj.hOptsMatchDiff, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hOptsMatchMatches, ...
                obj.hOptsMatchSeqs, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hOptsMatchMatches, ...
                obj.hOptsMatchSeqs, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hOptsMatchSelect, ...
                obj.hOptsMatchMatches, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hOptsMatchSelect, ...
                obj.hOptsMatchMatches, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hOptsMatchSelectValue, ...
                obj.hOptsMatchSelect, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hOptsMatchSelectValue, ...
                obj.hOptsMatchSelect, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hOptsMatchTweak, ...
                obj.hOptsMatchSelect, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hOptsMatchTweak, ...
                obj.hOptsMatchSelectValue, SpecPosition.RIGHT_OF, ...
                2*GUISettings.PAD_LARGE);

            SpecPosition.positionIn(obj.hOptsVidRate, obj.hOpts, ...
                SpecPosition.TOP, 1.75*GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hOptsVidRate, obj.hOpts, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hOptsVidRateValue, ...
                obj.hOptsVidRate, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hOptsVidRateValue, ...
                obj.hOptsVidRate, SpecPosition.RIGHT_OF, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hOptsVidPlay, ...
                obj.hOptsVidRate, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hOptsVidPlay, ...
                obj.hOptsVidRateValue, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hOptsVidExport, ...
                obj.hOptsVidRate, SpecPosition.CENTER_Y);
            SpecPosition.positionIn(obj.hOptsVidExport, obj.hOpts, ...
                SpecPosition.RIGHT, GUISettings.PAD_MED);

            SpecPosition.positionRelative(obj.hAxA, obj.hOpts, ...
                SpecPosition.BELOW, 8*GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hAxA, obj.hOpts, ...
                SpecPosition.LEFT, 12*GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hAxB, obj.hOpts, ...
                SpecPosition.BELOW, 8*GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hAxB, obj.hOpts, ...
                SpecPosition.RIGHT, 12*GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hAxC, obj.hAxA, ...
                SpecPosition.BELOW, 2*GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hAxC, obj.hOpts, ...
                SpecPosition.LEFT, 12*GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hAxD, obj.hAxB, ...
                SpecPosition.BELOW, 2*GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hAxD, obj.hOpts, ...
                SpecPosition.RIGHT, 12*GUISettings.PAD_LARGE);

            SpecPosition.positionRelative(obj.hAxMain, obj.hOpts, ...
                SpecPosition.BELOW, 3*GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hAxMain, obj.hFig, ...
                SpecPosition.LEFT, 4*GUISettings.PAD_LARGE);

            SpecPosition.positionRelative(obj.hAxVideo, obj.hOpts, ...
                SpecPosition.BELOW, 2*GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hAxVideo, obj.hFig, ...
                SpecPosition.CENTER_X);

            SpecPosition.positionIn(obj.hFocus, obj.hFig, ...
                SpecPosition.RIGHT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hFocus, obj.hOpts, ...
                SpecPosition.BELOW, 1.5*GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hFocusAx, obj.hFocus, ...
                SpecPosition.TOP, 2*GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hFocusAx, obj.hFocus, ...
                SpecPosition.CENTER_X);
            SpecPosition.positionRelative(obj.hFocusButton, obj.hFocusAx, ...
                SpecPosition.BELOW, GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hFocusButton, obj.hFocus, ...
                SpecPosition.CENTER_X);

            SpecPosition.positionIn(obj.hFocusQueryAx, ...
                obj.hFocus, SpecPosition.BOTTOM);
            SpecPosition.positionIn(obj.hFocusQuery, obj.hFocus, ...
                SpecPosition.CENTER_X);
            SpecPosition.positionRelative(obj.hFocusQuery, ...
                obj.hFocusQueryAx, SpecPosition.ABOVE);
            SpecPosition.positionIn(obj.hFocusQuery, obj.hFocus, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hFocusRefAx, obj.hFocusQuery, ...
                SpecPosition.ABOVE);
            SpecPosition.positionIn(obj.hFocusRef, obj.hFocus, ...
                SpecPosition.CENTER_X);
            SpecPosition.positionRelative(obj.hFocusRef, obj.hFocusRefAx, ...
                SpecPosition.ABOVE);
            SpecPosition.positionIn(obj.hFocusRef, obj.hFocus, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
        end

        function updateMatches(obj)
            obj.populateMatchList();
            obj.hOptsMatchSelectValue.String = obj.listMatches;
        end

        function updateSelectedMatch(obj)
            v = obj.hOptsMatchSelectValue.Value;
            if v == 1
                % Store an empty matrix if all are selected
                m = [];
            else
                % Get the match indices
                mIs = find(~isnan(obj.results.matching.thresholded.mask));

                % Stor the image # for query and reference ([mQ, mR])
                obj.selectedMatch = [mIs(v-1) ...
                    obj.results.matching.thresholded.matches(mIs(v-1))];
            end
        end
    end
end
