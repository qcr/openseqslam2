classdef SequencePopup < handle

    properties (Constant)
        FIG_WIDTH_FACTOR = 12;
        FIG_HEIGHT_FACTOR = 16;
    end

    properties
        hFig;
        hHelp;

        hTitle;

        hQueryTitle;
        hQueryAxes = [];
        hRefTitle;
        hRefAxes = [];

        config = emptyConfig();
        results = emptyResults();

        listRs = [];
        listQs = [];
    end

    methods
        function obj = SequencePopup(qs, rs, config, results)
            % Save the provided data
            obj.config = config;
            obj.results = results;
            obj.listRs = rs;
            obj.listQs = qs;

            % Create and size the popup
            obj.createPopup();
            obj.sizePopup();

            % Add the help button to the figure
            obj.hHelp = HelpPopup.addHelpButton(obj.hFig);
            HelpPopup.setDestination(obj.hHelp, ...
                'sequence');

            % Draw the screen content (images)
            obj.drawScreen();

            % Finally, show the figure once done configuring
            obj.hFig.Visible = 'on';
        end
    end

    methods (Access = private)
        function createPopup(obj)
            % Create the figure (and hide it)
            obj.hFig = figure('Visible', 'off');
            GUISettings.applyFigureStyle(obj.hFig);
            obj.hFig.Name = 'Matched Sequence Viewer';

            % Generic elements
            obj.hTitle = uicontrol('Style', 'text');
            GUISettings.applyUIControlStyle(obj.hTitle);
            GUISettings.setFontScale(obj.hTitle, 1.5);
            obj.hTitle.FontWeight = 'bold';
            obj.hTitle.String = ['Matched Sequence for Query Image #' ...
                num2str(obj.listQs(floor(end/2)+1))];

            % Create query elements
            obj.hQueryTitle = uicontrol('Style', 'text');
            obj.hQueryTitle.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hQueryTitle);
            obj.hQueryTitle.String = 'Query images';

            obj.hQueryAxes = gobjects(size(obj.listQs));
            for k = 1:length(obj.listQs)
                obj.hQueryAxes(k) = axes();
                GUISettings.applyUIAxesStyle(obj.hQueryAxes(k));
                obj.hQueryAxes(k).Visible = 'off';
            end

            obj.hRefTitle = uicontrol('Style', 'text');
            obj.hRefTitle.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hRefTitle);
            obj.hRefTitle.String = 'Reference images';

            obj.hRefAxes = gobjects(size(obj.listRs));
            for k = 1:length(obj.listRs)
                obj.hRefAxes(k) = axes();
                GUISettings.applyUIAxesStyle(obj.hRefAxes(k));
                obj.hRefAxes(k).Visible = 'off';
            end
        end

        function drawScreen(obj)
            % Draw each of the query images in each of the axis
            for k = 1:length(obj.hQueryAxes)
                cla(obj.hQueryAxes(k));
                imshow(datasetOpenImage(obj.config.('query'), obj.listQs(k), ...
                    obj.results.preprocessed.('query_numbers')), ...
                    'Parent', obj.hQueryAxes(k));
            end

            % Draw each of the reference images in each of the axis
            for k = 1:length(obj.hRefAxes)
                cla(obj.hRefAxes(k));
                imshow(datasetOpenImage(obj.config.('reference'), ...
                    obj.listRs(k), ...
                    obj.results.preprocessed.('reference_numbers')), ...
                    'Parent', obj.hRefAxes(k));
            end
        end

        function sizePopup(obj)
            % Statically size for now
            % TODO handle potential resizing gracefully
            widthUnit = obj.hTitle.Extent(3);
            heightUnit = obj.hTitle.Extent(4);

            % Size and position the figure
            obj.hFig.Position = [0, 0, ...
                widthUnit * SequencePopup.FIG_WIDTH_FACTOR, ...
                heightUnit * SequencePopup.FIG_HEIGHT_FACTOR];
            movegui(obj.hFig, 'center');

            % Now that the figure (space for placing UI elements is set),
            % size all of the elements
            SpecSize.size(obj.hTitle, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hTitle, SpecSize.WIDTH, SpecSize.MATCH, ...
                obj.hFig, GUISettings.PAD_MED);

            SpecSize.size(obj.hQueryTitle, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hQueryTitle, SpecSize.WIDTH, SpecSize.MATCH, ...
                obj.hFig, GUISettings.PAD_MED);

            n = length(obj.hQueryAxes);
            for k = 1:n
                SpecSize.size(obj.hQueryAxes(k), SpecSize.WIDTH, ...
                    SpecSize.PERCENT, obj.hFig, 0.975*1/11);
                SpecSize.size(obj.hQueryAxes(k), SpecSize.HEIGHT, ...
                    SpecSize.RATIO, 3/4);
            end

            SpecSize.size(obj.hRefTitle, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hRefTitle, SpecSize.WIDTH, SpecSize.MATCH, ...
                obj.hFig, GUISettings.PAD_MED);

            n = length(obj.hRefAxes);
            for k = 1:n
                SpecSize.size(obj.hRefAxes(k), SpecSize.WIDTH, ...
                    SpecSize.PERCENT, obj.hFig, 0.975*1/11);
                SpecSize.size(obj.hRefAxes(k), SpecSize.HEIGHT, ...
                    SpecSize.RATIO, 3/4);
            end

            % Then, systematically place
            SpecPosition.positionIn(obj.hTitle, obj.hFig, ...
                SpecPosition.TOP, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hTitle, obj.hFig, ...
                SpecPosition.CENTER_X);

            SpecPosition.positionRelative(obj.hQueryTitle, obj.hTitle, ...
                SpecPosition.BELOW, GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hQueryTitle, obj.hFig, ...
                SpecPosition.LEFT, GUISettings.PAD_LARGE);

            SpecPosition.positionRelative(obj.hQueryAxes(1), ...
                obj.hQueryTitle, SpecPosition.BELOW);
            SpecPosition.positionIn(obj.hQueryAxes(1), obj.hFig, ...
                SpecPosition.LEFT, GUISettings.PAD_LARGE);
            for k = 2:length(obj.hQueryAxes)
                SpecPosition.positionRelative(obj.hQueryAxes(k), ...
                    obj.hQueryAxes(1), SpecPosition.CENTER_Y);
                SpecPosition.positionRelative(obj.hQueryAxes(k), ...
                    obj.hQueryAxes(k-1), SpecPosition.RIGHT_OF, ...
                    0.5*GUISettings.PAD_SMALL);
            end

            SpecPosition.positionRelative(obj.hRefTitle, obj.hQueryAxes(1), ...
                SpecPosition.BELOW, 3*GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hRefTitle, obj.hFig, ...
                SpecPosition.LEFT, GUISettings.PAD_LARGE);

            SpecPosition.positionRelative(obj.hRefAxes(1), ...
                obj.hRefTitle, SpecPosition.BELOW);
            SpecPosition.positionIn(obj.hRefAxes(1), obj.hFig, ...
                SpecPosition.LEFT, GUISettings.PAD_LARGE);
            for k = 2:length(obj.hRefAxes)
                SpecPosition.positionRelative(obj.hRefAxes(k), ...
                    obj.hRefAxes(1), SpecPosition.CENTER_Y);
                SpecPosition.positionRelative(obj.hRefAxes(k), ...
                    obj.hRefAxes(k-1), SpecPosition.RIGHT_OF, ...
                    0.5*GUISettings.PAD_SMALL);
            end
        end
    end
end

