classdef ConfigVisualGUI < handle

    properties (Access = private, Constant)
        % Sizing parameters
        FIG_WIDTH_FACTOR = 2;     % Times longest internal heading
        FIG_HEIGHT_FACTOR = 13;     % Times height of buttons at font size
    end

    properties
        hFig;

        hProg;
        hProgWarning;
        hProgPerc;
        hProgPercValue;
        hProgPre;
        hProgPreValue;
        hProgDiff;
        hProgDiffValue;
        hProgEnh;
        hProgEnhValue;
        hProgMatch;
        hProgMatchValue;

        hDone;

        config = emptyConfig();
    end

    methods
        function obj = ConfigVisualGUI()
            % Create and size the GUI
            obj.createGUI();
            obj.sizeGUI();
            
            % Finally, show the figure when we are done configuring
            obj.hFig.Visible = 'on';
        end

        function updateConfig(obj, config)
            obj.config = config;
            obj.populate();
        end
    end

    methods (Access = private)
        function cbDone(obj, src, event)
            % Strip the UI data, save it in the config, and close the GUI
            obj.strip();
            close(obj.hFig);
        end

        function createGUI(obj)
            % Create the figure (and hide it)
            obj.hFig = figure('Visible', 'off');
            GUISettings.applyFigureStyle(obj.hFig);
            obj.hFig.Name = 'Visualisation Settings';
            obj.hFig.Resize = 'off';
			
            % Create the progress panel
            obj.hProg = uipanel();
            GUISettings.applyUIPanelStyle(obj.hProg);
            obj.hProg.Title = 'Progress UI';
			
            obj.hProgWarning = uicontrol('Style', 'text');
            obj.hProgWarning.Parent = obj.hProg;
            GUISettings.applyUIControlStyle(obj.hProgWarning);
            obj.hProgWarning.FontAngle = 'italic';
            obj.hProgWarning.ForegroundColor = GUISettings.COL_ERROR;
            obj.hProgWarning.String = ['Note: Lowering values can ' ...
                'significantly effect performance!'];
			
            obj.hProgPerc = uicontrol('Style', 'text');
            obj.hProgPerc.Parent = obj.hProg;
            GUISettings.applyUIControlStyle(obj.hProgPerc);
            obj.hProgPerc.HorizontalAlignment = 'left';
            obj.hProgPerc.String = 'Percents update frequency (s):';
			
            obj.hProgPercValue = uicontrol('Style', 'edit');
            obj.hProgPercValue.Parent = obj.hProg;
            GUISettings.applyUIControlStyle(obj.hProgPercValue);
            obj.hProgPercValue.String = '';
			
            obj.hProgPre = uicontrol('Style', 'text');
            obj.hProgPre.Parent = obj.hProg;
            GUISettings.applyUIControlStyle(obj.hProgPre);
            obj.hProgPre.HorizontalAlignment = 'left';
            obj.hProgPre.String = 'Preprocessed sample frequency (s):';
			
            obj.hProgPreValue = uicontrol('Style', 'edit');
            obj.hProgPreValue.Parent = obj.hProg;
            GUISettings.applyUIControlStyle(obj.hProgPreValue);
            obj.hProgPreValue.String = '';
			
            obj.hProgDiff = uicontrol('Style', 'text');
            obj.hProgDiff.Parent = obj.hProg;
            GUISettings.applyUIControlStyle(obj.hProgDiff);
            obj.hProgDiff.HorizontalAlignment = 'left';
            obj.hProgDiff.String = 'Difference matrix update frequency (s):';
            
            obj.hProgDiffValue = uicontrol('Style', 'edit');
            obj.hProgDiffValue.Parent = obj.hProg;
            GUISettings.applyUIControlStyle(obj.hProgDiffValue);
            obj.hProgDiffValue.String = '';
			
            obj.hProgEnh = uicontrol('Style', 'text');
            obj.hProgEnh.Parent = obj.hProg;
            GUISettings.applyUIControlStyle(obj.hProgEnh);
            obj.hProgEnh.HorizontalAlignment = 'left';
            obj.hProgEnh.String = 'Contrast enhance update frequency (s):';
			
            obj.hProgEnhValue = uicontrol('Style', 'edit');
            obj.hProgEnhValue.Parent = obj.hProg;
            GUISettings.applyUIControlStyle(obj.hProgEnhValue);
            obj.hProgEnhValue.String = '';
			
            obj.hProgMatch = uicontrol('Style', 'text');
            obj.hProgMatch.Parent = obj.hProg;
            GUISettings.applyUIControlStyle(obj.hProgMatch);
            obj.hProgMatch.HorizontalAlignment = 'left';
            obj.hProgMatch.String = 'Matching update frequency (s):';
			
            obj.hProgMatchValue = uicontrol('Style', 'edit');
            obj.hProgMatchValue.Parent = obj.hProg;
            GUISettings.applyUIControlStyle(obj.hProgMatchValue);
            obj.hProgMatchValue.String = '';

            % Done button
            obj.hDone = uicontrol('Style', 'pushbutton');
            GUISettings.applyUIControlStyle(obj.hDone);
            obj.hDone.String = 'Done';

            % Callbacks (must be last, otherwise empty objects passed...)
            obj.hDone.Callback = {@obj.cbDone};
        end

        function populate(obj)
            % Dump all data from the config struct to the UI
            obj.hProgPercValue.String = num2str( ...
                obj.config.visual.progress.percent_rate);
            obj.hProgPreValue.String = num2str( ...
                obj.config.visual.progress.preprocess_rate);
            obj.hProgDiffValue.String = num2str( ...
                obj.config.visual.progress.diff_matrix_rate);
            obj.hProgEnhValue.String = num2str( ...
                obj.config.visual.progress.enhance_rate);
            obj.hProgMatchValue.String = num2str( ...
                obj.config.visual.progress.match_rate);
        end

        function sizeGUI(obj)
            % Get some reference dimensions (max width of headings, and
            % default height of a button
            widthUnit = obj.hProgDiff.Extent(3);
            heightUnit = obj.hDone.Extent(4);

            % Size and position of the figure
            obj.hFig.Position = [0, 0, ...
                widthUnit * ConfigVisualGUI.FIG_WIDTH_FACTOR, ...
                heightUnit * ConfigVisualGUI.FIG_HEIGHT_FACTOR];
            movegui(obj.hFig, 'center');

            % Now that the figure (space for placing UI elements is set),
            % size all of the elements
            SpecSize.size(obj.hProg, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hFig, GUISettings.PAD_MED);
            SpecSize.size(obj.hProg, SpecSize.HEIGHT, ...
                SpecSize.ABSOLUTE, 10.5*heightUnit);
            SpecSize.size(obj.hProgWarning, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hProg, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hProgWarning, SpecSize.HEIGHT, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hProgPerc, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hProg, 0.6, GUISettings.PAD_MED);
            SpecSize.size(obj.hProgPercValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hProg, 0.25);
            SpecSize.size(obj.hProgPre, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hProg, 0.6, GUISettings.PAD_MED);
            SpecSize.size(obj.hProgPreValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hProg, 0.25);
            SpecSize.size(obj.hProgDiff, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hProg, 0.6, GUISettings.PAD_MED);
            SpecSize.size(obj.hProgDiffValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hProg, 0.25);
            SpecSize.size(obj.hProgEnh, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hProg, 0.6, GUISettings.PAD_MED);
            SpecSize.size(obj.hProgEnhValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hProg, 0.25);
            SpecSize.size(obj.hProgMatch, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hProg, 0.6, GUISettings.PAD_MED);
            SpecSize.size(obj.hProgMatchValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hProg, 0.25);

            SpecSize.size(obj.hDone, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.25);

            % Then, systematically place
            SpecPosition.positionIn(obj.hProg, obj.hFig, ...
                SpecPosition.CENTER_X);
            SpecPosition.positionIn(obj.hProg, obj.hFig, ...
                SpecPosition.TOP, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hProgWarning, obj.hProg, ...
                SpecPosition.CENTER_X);
            SpecPosition.positionIn(obj.hProgWarning, obj.hProg, ...
                SpecPosition.TOP, heightUnit);
            SpecPosition.positionRelative(obj.hProgPerc, obj.hProgWarning, ...
                SpecPosition.BELOW, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hProgPerc, obj.hProg, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hProgPercValue, obj.hProgPerc, ...
                SpecPosition.TOP);
            SpecPosition.positionRelative(obj.hProgPercValue, obj.hProgPerc, ...
                SpecPosition.RIGHT_OF, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hProgPre, obj.hProgPerc, ...
                SpecPosition.BELOW, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hProgPre, obj.hProg, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hProgPreValue, obj.hProgPre, ...
                SpecPosition.TOP);
            SpecPosition.positionRelative(obj.hProgPreValue, obj.hProgPre, ...
                SpecPosition.RIGHT_OF, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hProgDiff, obj.hProgPre, ...
                SpecPosition.BELOW, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hProgDiff, obj.hProg, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hProgDiffValue, obj.hProgDiff, ...
                SpecPosition.TOP);
            SpecPosition.positionRelative(obj.hProgDiffValue, obj.hProgDiff, ...
                SpecPosition.RIGHT_OF, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hProgEnh, obj.hProgDiff, ...
                SpecPosition.BELOW, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hProgEnh, obj.hProg, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hProgEnhValue, obj.hProgEnh, ...
                SpecPosition.TOP);
            SpecPosition.positionRelative(obj.hProgEnhValue, obj.hProgEnh, ...
                SpecPosition.RIGHT_OF, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hProgMatch, obj.hProgEnh, ...
                SpecPosition.BELOW, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hProgMatch, obj.hProg, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hProgMatchValue, obj.hProgMatch, ...
                SpecPosition.TOP);
            SpecPosition.positionRelative(obj.hProgMatchValue, obj.hProgMatch, ...
                SpecPosition.RIGHT_OF, GUISettings.PAD_LARGE);

            SpecPosition.positionIn(obj.hDone, obj.hFig, ...
                SpecPosition.RIGHT, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hDone, obj.hFig, ...
                SpecPosition.BOTTOM, GUISettings.PAD_MED);
        end

        function strip(obj)
            % Strip data from the UI, and store it in the config struct
            obj.config.visual.progress.percent_rate = ...
                str2num(obj.hProgPercValue.String);
            obj.config.visual.progress.preprocess_rate = ...
                str2num(obj.hProgPreValue.String);
            obj.config.visual.progress.diff_matrix_rate = ...
                str2num(obj.hProgDiffValue.String);
            obj.config.visual.progress.enhance_rate = ...
                str2num(obj.hProgEnhValue.String);
            obj.config.visual.progress.match_rate = ...
                str2num(obj.hProgMatchValue.String);
        end
    end
end
