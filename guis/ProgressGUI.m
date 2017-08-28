classdef ProgressGUI < handle

    properties (Constant)
        STATE_START = 0;
        STATE_PREPROCESS_REF = 1;
        STATE_PREPROCESS_QUERY = 2;
        STATE_DIFF_MATRIX = 3;
        STATE_DIFF_MATRIX_CONTRAST = 4;
        STATE_MATCHING = 5;
        STATE_MATCHING_FILTERING = 6;
        STATE_DONE = 7;

        FIG_WIDTH_FACTOR = 45;
        FIG_HEIGHT_FACTOR = 30;
    end

    properties
        hFig;

        hStatus1;
        hStatus2;
        hStatus3;
        hStatus4;
        hStatus5;
        hStatus6;
        hStatus12;
        hStatus23;
        hStatus34;
        hStatus45;
        hStatus56;

        hTitle;

        hAxQ1;
        hAxQ2;
        hAxQ3;
        hAxQ4;
        hAxMain;

        hPercent;

        config = emptyConfig();
        progress;

        lastRefresh = cputime();

        instance;

        results = emptyResults();
    end

    methods
        function obj = ProgressGUI(config)
            % Create and size the GUI
            obj.createGUI();
            obj.sizeGUI();

            % Save the config
            obj.config = config;

            % TODO fix hack!!!
            obj.config.visualiser.rate = 1;

            % Create an initial progress state
            progress = [];
            progress.state = ProgressGUI.STATE_START;
            obj.refreshUI(progress);

            % Create, and attach to, the SeqSLAM instance
            obj.instance = SeqSLAMInstance(config);
            obj.instance.attachUI(@obj.refreshDue, @obj.refreshUI);

            % Finally, show the figure when we are done configuring
            obj.hFig.Visible = 'on';
        end

        function due = refreshDue(obj, state)
            due = state ~= obj.progress.state || ...
                cputime() - obj.lastRefresh > obj.config.visualiser.rate || ...
                cputime() - obj.lastRefresh < 0;
        end
        
        function refreshUI(obj, progress)
            % Save the new progress
            obj.progress = progress;

            % Update each of the elements
            obj.updateStatusBar();
            obj.updateTitle();
            obj.updatePlots();
            obj.updatePercent();

            % Force a draw
            drawnow();
            obj.lastRefresh = cputime();
        end

        function run(obj)
            obj.instance.run();
            obj.results = obj.instance.results;

            % Close when done
            % TODO maybe there is a more appropriate place for this?
            close(obj.hFig);
        end
    end

    methods (Access = private)
        function createGUI(obj)
            % Create the figure (and hide it)
            obj.hFig = figure('Visible', 'off');
            GUISettings.applyFigureStyle(obj.hFig);
            obj.hFig.Name = 'SeqSLAM Progress';
			
            % Status bar elements
            obj.hStatus1 = uicontrol('Style', 'text');
            GUISettings.applyUIControlStyle(obj.hStatus1);
            GUISettings.setFontScale(obj.hStatus1, 1.5);
            obj.hStatus1.FontWeight = 'bold';
            obj.hStatus1.String = '1';
			
            obj.hStatus2 = uicontrol('Style', 'text');
            GUISettings.applyUIControlStyle(obj.hStatus2);
            GUISettings.setFontScale(obj.hStatus2, 1.5);
            obj.hStatus2.FontWeight = 'bold';
            obj.hStatus2.String = '2';
			
            obj.hStatus3 = uicontrol('Style', 'text');
            GUISettings.applyUIControlStyle(obj.hStatus3);
            GUISettings.setFontScale(obj.hStatus3, 1.5);
            obj.hStatus3.FontWeight = 'bold';
            obj.hStatus3.String = '3';
			
            obj.hStatus4 = uicontrol('Style', 'text');
            GUISettings.applyUIControlStyle(obj.hStatus4);
            GUISettings.setFontScale(obj.hStatus4, 1.5);
            obj.hStatus4.FontWeight = 'bold';
            obj.hStatus4.String = '4';
			
            obj.hStatus5 = uicontrol('Style', 'text');
            GUISettings.applyUIControlStyle(obj.hStatus5);
            GUISettings.setFontScale(obj.hStatus5, 1.5);
            obj.hStatus5.FontWeight = 'bold';
            obj.hStatus5.String = '5';
			
            obj.hStatus6 = uicontrol('Style', 'text');
            GUISettings.applyUIControlStyle(obj.hStatus6);
            GUISettings.setFontScale(obj.hStatus6, 1.5);
            obj.hStatus6.FontWeight = 'bold';
            obj.hStatus6.String = '6';
			
            obj.hStatus12 = uicontrol('Style', 'text');
            GUISettings.applyUIControlStyle(obj.hStatus12);
            GUISettings.setFontScale(obj.hStatus12, 1.5);
            obj.hStatus12.FontWeight = 'bold';
            obj.hStatus12.String = ' - ';
			
            obj.hStatus23 = uicontrol('Style', 'text');
            GUISettings.applyUIControlStyle(obj.hStatus23);
            GUISettings.setFontScale(obj.hStatus23, 1.5);
            obj.hStatus23.FontWeight = 'bold';
            obj.hStatus23.String = ' - ';
			
            obj.hStatus34 = uicontrol('Style', 'text');
            GUISettings.applyUIControlStyle(obj.hStatus34);
            GUISettings.setFontScale(obj.hStatus34, 1.5);
            obj.hStatus34.FontWeight = 'bold';
            obj.hStatus34.String = ' - ';
			
            obj.hStatus45 = uicontrol('Style', 'text');
            GUISettings.applyUIControlStyle(obj.hStatus45);
            GUISettings.setFontScale(obj.hStatus45, 1.5);
            obj.hStatus45.FontWeight = 'bold';
            obj.hStatus45.String = ' - ';
			
            obj.hStatus56 = uicontrol('Style', 'text');
            GUISettings.applyUIControlStyle(obj.hStatus56);
            GUISettings.setFontScale(obj.hStatus56, 1.5);
            obj.hStatus56.FontWeight = 'bold';
            obj.hStatus56.String = ' - ';
			
            % Title
            obj.hTitle = uicontrol('Style', 'text');
            GUISettings.applyUIControlStyle(obj.hTitle);
            GUISettings.setFontScale(obj.hTitle, 2.5);
            obj.hTitle.FontWeight = 'bold';
            obj.hTitle.String = 'Testing 1 2 3';
            
            % Axes
            % TODO
			
            % Percent
            obj.hPercent = uicontrol('Style', 'text');
            GUISettings.applyUIControlStyle(obj.hPercent);
            GUISettings.setFontScale(obj.hPercent,2);
            obj.hPercent.FontWeight = 'bold';
            obj.hPercent.HorizontalAlignment = 'right';
            obj.hPercent.String = '50%';
        end

        function sizeGUI(obj)
            % Statically size for now
            % TODO handle potential resizing gracefully
            widthUnit = obj.hStatus12.Extent(3);
            heightUnit = obj.hStatus1.Extent(4);
			
            % Size and position the figure
            obj.hFig.Position = [0, 0, ...
                widthUnit * ProgressGUI.FIG_WIDTH_FACTOR, ...
                heightUnit * ProgressGUI.FIG_HEIGHT_FACTOR];
            movegui(obj.hFig, 'center');
			
            % Now that the figure (space for placing UI elements is set),
            % size all of the elements
            SpecSize.size(obj.hStatus1, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hStatus1, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.08);
            SpecSize.size(obj.hStatus2, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hStatus2, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.08);
            SpecSize.size(obj.hStatus3, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hStatus3, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.08);
            SpecSize.size(obj.hStatus4, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hStatus4, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.08);
            SpecSize.size(obj.hStatus5, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hStatus5, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.08);
            SpecSize.size(obj.hStatus6, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hStatus6, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.08);
            SpecSize.size(obj.hStatus12, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hStatus12, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.08);
            SpecSize.size(obj.hStatus23, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hStatus23, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.08);
            SpecSize.size(obj.hStatus34, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hStatus34, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.08);
            SpecSize.size(obj.hStatus45, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hStatus45, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.08);
            SpecSize.size(obj.hStatus56, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hStatus56, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.08);
			
            SpecSize.size(obj.hTitle, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hTitle, SpecSize.WIDTH, SpecSize.MATCH, ...
                obj.hFig, GUISettings.PAD_MED);
			
            SpecSize.size(obj.hPercent, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hPercent, SpecSize.WIDTH, SpecSize.MATCH, ...
                obj.hFig, GUISettings.PAD_MED);
			
            % Then, systematically place
            SpecPosition.positionIn(obj.hStatus34, obj.hFig, ...
                SpecPosition.TOP, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hStatus34, obj.hFig, ...
                SpecPosition.CENTER_X);

            SpecPosition.positionRelative(obj.hStatus3, obj.hStatus34, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hStatus3, obj.hStatus34, ...
                SpecPosition.LEFT_OF, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hStatus23, obj.hStatus34, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hStatus23, obj.hStatus3, ...
                SpecPosition.LEFT_OF, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hStatus2, obj.hStatus34, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hStatus2, obj.hStatus23, ...
                SpecPosition.LEFT_OF, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hStatus12, obj.hStatus34, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hStatus12, obj.hStatus2, ...
                SpecPosition.LEFT_OF, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hStatus1, obj.hStatus34, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hStatus1, obj.hStatus12, ...
                SpecPosition.LEFT_OF, GUISettings.PAD_MED);
			
            SpecPosition.positionRelative(obj.hStatus4, obj.hStatus34, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hStatus4, obj.hStatus34, ...
                SpecPosition.RIGHT_OF, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hStatus45, obj.hStatus34, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hStatus45, obj.hStatus4, ...
                SpecPosition.RIGHT_OF, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hStatus5, obj.hStatus34, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hStatus5, obj.hStatus45, ...
                SpecPosition.RIGHT_OF, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hStatus56, obj.hStatus34, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hStatus56, obj.hStatus5, ...
                SpecPosition.RIGHT_OF, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hStatus6, obj.hStatus34, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hStatus6, obj.hStatus56, ...
                SpecPosition.RIGHT_OF, GUISettings.PAD_MED);
			
            SpecPosition.positionRelative(obj.hTitle, obj.hStatus34, ...
                SpecPosition.BELOW, GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hTitle, obj.hFig, ...
                SpecPosition.LEFT, GUISettings.PAD_LARGE);
			
            SpecPosition.positionIn(obj.hPercent, obj.hFig, ...
                SpecPosition.BOTTOM, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hPercent, obj.hFig, ...
                SpecPosition.RIGHT, GUISettings.PAD_MED);
        end

        function updatePercent(obj)
            if ~isfield(obj.progress, 'percent') || isempty(obj.progress.percent)
                obj.hPercent.String = '';
            else
                obj.hPercent.String = [num2str(round(obj.progress.percent)) '%'];
            end
        end

        function updatePlots(obj)

        end

        function updateStatusBar(obj)
            % Default everything to grey
            obj.hStatus1.ForegroundColor = GUISettings.COL_LOADING;
            obj.hStatus2.ForegroundColor = GUISettings.COL_LOADING;
            obj.hStatus3.ForegroundColor = GUISettings.COL_LOADING;
            obj.hStatus4.ForegroundColor = GUISettings.COL_LOADING;
            obj.hStatus5.ForegroundColor = GUISettings.COL_LOADING;
            obj.hStatus6.ForegroundColor = GUISettings.COL_LOADING;
            obj.hStatus12.ForegroundColor = GUISettings.COL_LOADING;
            obj.hStatus23.ForegroundColor = GUISettings.COL_LOADING;
            obj.hStatus34.ForegroundColor = GUISettings.COL_LOADING;
            obj.hStatus45.ForegroundColor = GUISettings.COL_LOADING;
            obj.hStatus56.ForegroundColor = GUISettings.COL_LOADING;

            % Change colors based on progression through states
            if obj.progress.state == ProgressGUI.STATE_PREPROCESS_REF
                obj.hStatus1.ForegroundColor = GUISettings.COL_DEFAULT;
            end
            if obj.progress.state > ProgressGUI.STATE_PREPROCESS_REF
                obj.hStatus1.ForegroundColor = GUISettings.COL_SUCCESS;
                obj.hStatus12.ForegroundColor = GUISettings.COL_SUCCESS;
                obj.hStatus2.ForegroundColor = GUISettings.COL_DEFAULT;
            end
            if obj.progress.state > ProgressGUI.STATE_PREPROCESS_QUERY
                obj.hStatus2.ForegroundColor = GUISettings.COL_SUCCESS;
                obj.hStatus23.ForegroundColor = GUISettings.COL_SUCCESS;
                obj.hStatus3.ForegroundColor = GUISettings.COL_DEFAULT;
            end
            if obj.progress.state > ProgressGUI.STATE_DIFF_MATRIX
                obj.hStatus3.ForegroundColor = GUISettings.COL_SUCCESS;
                obj.hStatus34.ForegroundColor = GUISettings.COL_SUCCESS;
                obj.hStatus4.ForegroundColor = GUISettings.COL_DEFAULT;
            end
            if obj.progress.state > ProgressGUI.STATE_DIFF_MATRIX_CONTRAST
                obj.hStatus4.ForegroundColor = GUISettings.COL_SUCCESS;
                obj.hStatus45.ForegroundColor = GUISettings.COL_SUCCESS;
                obj.hStatus5.ForegroundColor = GUISettings.COL_DEFAULT;
            end
            if obj.progress.state > ProgressGUI.STATE_MATCHING
                obj.hStatus5.ForegroundColor = GUISettings.COL_SUCCESS;
                obj.hStatus56.ForegroundColor = GUISettings.COL_SUCCESS;
                obj.hStatus6.ForegroundColor = GUISettings.COL_DEFAULT;
            end
            if obj.progress.state > ProgressGUI.STATE_MATCHING_FILTERING
                obj.hStatus6.ForegroundColor = GUISettings.COL_SUCCESS;
            end
        end

        function updateTitle(obj)
            if obj.progress.state == ProgressGUI.STATE_PREPROCESS_REF
                obj.hTitle.String = '1 - Preprocessing Reference Images';
            elseif obj.progress.state == ProgressGUI.STATE_PREPROCESS_QUERY
                obj.hTitle.String = '2 - Preprocessing Query Images';
            elseif obj.progress.state == ProgressGUI.STATE_DIFF_MATRIX
                obj.hTitle.String = '3 - Constructing Difference Matrix';
            elseif obj.progress.state == ProgressGUI.STATE_DIFF_MATRIX_CONTRAST
                obj.hTitle.String = '4 - Enhancing Difference Matrix Contrast';
            elseif obj.progress.state == ProgressGUI.STATE_MATCHING
                obj.hTitle.String = '5 - Searching for Matches';
            elseif obj.progress.state == ProgressGUI.STATE_MATCHING_FILTERING
                obj.hTitle.String = '6 - Filtering Best Matches';
            elseif obj.progress.state == ProgressGUI.STATE_DONE
                obj.hTitle.String = 'Done!';
            else
                obj.hTitle.String = '';
            end
        end
    end
end
