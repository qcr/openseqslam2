classdef ResultsGUI < handle

    properties (Constant)
        SCREENS = { ...
            'Image preprocessing', ...
            'Difference Matrix', ...
            'Sequence Matches', ...
            'Matches Video'};

        FIG_WIDTH_FACTOR = 4.5;
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

        results = emptyResults();
        config = emptyConfig();
    end

    methods
        function obj = ResultsGUI(results, config)
            % Create and size the GUI
            obj.createGUI();
            obj.sizeGUI();

            % Save the config and results
            obj.config = config;
            obj.results = results;

            % Perform any necessary 'first run actions'
            obj.populateDatasetList();

            % Start on the matches screen
            obj.hScreen.Value = 3;
            obj.openScreen(obj.hScreen.Value);

            % Finally, show the figure when we are done configuring
            obj.hFig.Visible = 'on';
        end
    end

    methods (Access = private)
        function cbDiffOptionChange(obj, src, event)
            obj.drawDiffMatrix();
        end

        function cbMatchesOptionChange(obj, src, event)
            obj.drawMatches();
        end

        function cbChangeDataset(obj, src, event)
            % Grey out all of the plots because we have a change
            obj.greyAxes();

            % Re-populate the dataset list
            obj.populateDatasetList();
        end

        function cbChangeImage(obj, src, event)
            % Grey out all of the plots because we have a change
            obj.greyAxes();
        end

        function cbRefreshPreprocessed(obj, src, even)
            obj.drawPreprocessed();
        end

        function cbSelectScreen(obj, src, event)
            obj.openScreen(obj.hScreen.Value);
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

            % Hide all axes
            obj.hAxA.Visible = 'off';
            obj.hAxB.Visible = 'off';
            obj.hAxC.Visible = 'off';
            obj.hAxD.Visible = 'off';
            obj.hAxMain.Visible = 'off';

            % Clear the axes
            cla(obj.hAxA);
            cla(obj.hAxB);
            cla(obj.hAxC);
            cla(obj.hAxD);
            cla(obj.hAxMain);
        end

        function createGUI(obj)
            % Create the figure (and hide it)
            obj.hFig = figure('Visible', 'off');
            GUISettings.applyFigureStyle(obj.hFig);
            obj.hFig.Name = 'SeqSLAM Results';
			
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
        end

        function drawPreprocessed(obj)
            % Get all of the requested parameters
            ds = lower(obj.hOptsPreDatasetValue.String{ ...
                obj.hOptsPreDatasetValue.Value});
            indices = obj.results.preprocessed.([ds '_indices']);
            path = obj.config.(ds).path;
            info = obj.config.(ds).(obj.config.(ds).type);
            isVideo = strcmp(obj.config.(ds).type, 'video');
            index = obj.hOptsPreImageValue.Value;
            
            % Load the original image
            if isVideo
                v = VideoReader(path);
                v.CurrentTime = datasetFrameInfo(indices(index)-1, ...
                    v.FrameRate, 0);
                img = v.readFrame();
            else
                img = imread(datasetImageInfo(path, info.token_start, ...
                    info.token_end, indices(index), info.index_end, 0));
            end

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
            obj.results.dbg0 = imgs{2};
            obj.results.dbg1 = img_out;

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
            GUISettings.axesDiffMatrixStyle(obj.hAxMain, ...
                size(obj.results.diff_matrix.enhanced));
        end

        function drawMatches(obj)
            % Clear the axis to start
            cla(obj.hAxMain);
            hold(obj.hAxMain, 'on');

            % Draw the difference matrix as the background
            if obj.hOptsMatchDiff.Value
                h = imagesc(obj.hAxMain, obj.results.diff_matrix.enhanced);
                h.AlphaData = 0.25;
            end

            % Draw any requested overlaying plots
            if obj.hOptsMatchSeqs.Value
                plot(obj.hAxMain, ...
                    [1 size(obj.results.diff_matrix.base,2)], ...
                    [1 size(obj.results.diff_matrix.base,1)]);
            end
            if obj.hOptsMatchMatches.Value
                plot(obj.hAxMain, obj.results.matches.thresholded, '.');
            end
            hold(obj.hAxMain, 'off');

            % Style the plot
            GUISettings.axesDiffMatrixStyle(obj.hAxMain, ...
                size(obj.results.diff_matrix.enhanced));
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
            switch screen
                case 1
                    % Image preprocessing screen
                    % Show the appropriate options
                    obj.hOptsPreDataset.Visible = 'on';
                    obj.hOptsPreDatasetValue.Visible = 'on';
                    obj.hOptsPreImage.Visible = 'on';
                    obj.hOptsPreImageValue.Visible = 'on';
                    obj.hOptsPreRefresh.Visible = 'on';

                    % Turn on the required axes
                    obj.hAxMain.Visible = 'on';

                    % Draw the content
                    obj.drawPreprocessed();
                case 2
                    % Difference matrix screen
                    % Show the appropriate options
                    obj.hOptsDiffContr.Visible = 'on';
                    obj.hOptsDiffCol.Visible = 'on';
                    obj.hOptsDiffColValue.Visible = 'on';

                    % Turn on the required axes
                    obj.hAxMain.Visible = 'on';

                    % Draw the content
                    obj.drawDiffMatrix();
                case 3
                    % Sequence matches screen
                    % Show the appropriate options
                    obj.hOptsMatchDiff.Visible = 'on';
                    obj.hOptsMatchSeqs.Visible = 'on';
                    obj.hOptsMatchMatches.Visible = 'on';
                    
                    % Turn on the required axes
                    obj.hAxMain.Visible = 'on';

                    % Draw the content
                    obj.drawMatches();
                case 4
                    % Matches video screen
                    % TODO
            end

            % Force a draw at the end
            drawnow();
        end

        function populateDatasetList(obj)
            % Get all of the requested parameters
            ds = lower(obj.hOptsPreDatasetValue.String{ ...
                obj.hOptsPreDatasetValue.Value});
            indices = obj.results.preprocessed.([ds '_indices']);
            path = obj.config.(ds).path;
            info = obj.config.(ds).(obj.config.(ds).type);
            isVideo = strcmp(obj.config.(ds).type, 'video');

            % Populate the list
            list = cell(length(indices),1);
            for k = 1:length(list)
                if isVideo
                    list{k} = datasetFrameInfo(indices(k), info.frame_rate, ...
                        1, path, k);
                else
                    list{k} = datasetImageInfo(path, info.token_start, ...
                        info.token_end, indices(k), info.index_end, 1, k);
                end
            end

            % Apply the list
            obj.hOptsPreImageValue.String = list;
        end

        function sizeGUI(obj)
            % Statically size for now
            % TODO handle potential resizing gracefully
            widthUnit = obj.hTitle.Extent(3);
            heightUnit = obj.hTitle.Extent(4);
			
            % Size and position the figure
            obj.hFig.Position = [0, 0, ...
                widthUnit * ProgressGUI.FIG_WIDTH_FACTOR, ...
                heightUnit * ProgressGUI.FIG_HEIGHT_FACTOR];
            movegui(obj.hFig, 'center');
			
            % Now that the figure (space for placing UI elements is set),
            % size all of the elements
            SpecSize.size(obj.hScreen, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.8);

            SpecSize.size(obj.hTitle, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hTitle, SpecSize.WIDTH, SpecSize.MATCH, ...
                obj.hFig, GUISettings.PAD_MED);

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
                obj.hFig, 0.7);
            SpecSize.size(obj.hAxMain, SpecSize.HEIGHT, SpecSize.RATIO, 3/4);

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
                SpecPosition.CENTER_X);
        end
    end
end
