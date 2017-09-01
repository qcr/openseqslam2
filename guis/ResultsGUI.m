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

        hOpts;

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

            % Finally, show the figure when we are done configuring
            obj.hFig.Visible = 'on';
        end
    end

    methods (Access = private)
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

            % Options area for each screen
            obj.hOpts = uipanel();
            GUISettings.applyUIPanelStyle(obj.hOpts);
            obj.hOpts.Title = 'Options';
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

            SpecSize.size(obj.hOpts, SpecSize.HEIGHT, SpecSize.ABSOLUTE, ...
                1.5*heightUnit);
            SpecSize.size(obj.hOpts, SpecSize.WIDTH, SpecSize.MATCH, ...
                obj.hFig, GUISettings.PAD_MED);

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
        end
    end
end
