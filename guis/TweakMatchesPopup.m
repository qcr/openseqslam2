classdef TweakMatchesPopup < handle

    properties (Constant)
        FIG_WIDTH_FACTOR = 5;
        FIG_HEIGHT_FACTOR = 25;
    end

    properties
        hFig;

        hTitle;

        hGroup;

        hMethod;
        hMethodValue;

        hSlidingWindow;
        hSlidingWindowValue;
        hSlidingU;
        hSlidingUValue;

        % TODO
        hAbs;
        hAbsValue;

        hAxis;
        hLine;

        hApply;

        config = emptyConfig();
        results = emptyResults();
    end

    methods
        function obj = TweakMatchesPopup(config, results)
            % Save the provided data
            obj.config = config;
            obj.results = results;

            % Create and size the popup
            obj.createPopup();
            obj.sizePopup();

            % Draw the screen content (images)
            obj.drawScreen();

            % Finally, show the figure once done configuring
            obj.hFig.Visible = 'on';
        end
    end

    methods (Access = private)
        function cbApplyThreshold(obj, src, data)
            % Get the new thresholded matches
            obj.results.matching.thresholded = SeqSLAMInstance.threshold( ...
                obj.results.matching.all, str2num(obj.hSlidingUValue.String));

            % Apply the new config
            obj.config.seqslam.matching.criteria.r_window = str2num( ...
                obj.hSlidingWindowValue.String);
            obj.config.seqslam.matching.criteria.u = str2num( ...
                obj.hSlidingUValue.String);

            % Close the figure
            close(obj.hFig)
        end

        function cbUpdateSlidingU(obj, src, data)
            % Do some lazy validity checking (and enforce in UI)
            u = str2num(obj.hSlidingUValue.String);
            uMax = max(obj.results.matching.all.matches(:,2));
            if length(u) ~= 1 || u < 1
                u = 1;
            elseif u > uMax
                u = uMax;
            end
            obj.hSlidingUValue.String = num2str(u);

            % Update the screen
            obj.drawScreen();
        end

        function posOut = constrainedPosition(obj, posIn)
            posOut = posIn;

            % Allow no changes if resizing
            v = str2num(obj.hSlidingUValue.String);
            c = obj.hLine.getPosition();
            if abs(range(c(:,2))-range(posOut(:,2))) > 0.001 || ...
                    abs(range(c(:,1))-range(obj.hAxis.XLim)) > 0.001
                posOut(:,1) = obj.hAxis.XLim;
                posOut(:,2) = v;
                return;
            end

            % Force to be within y axis limits
            posOut(1,2) = max(posOut(1,2), obj.hAxis.YLim(1));
            posOut(1,2) = min(posOut(1,2), obj.hAxis.YLim(2));
            posOut(2,2) = posOut(1,2);

            % Force to remain at x axis limits
            posOut(:,1) = obj.hAxis.XLim;

            % Set the new value and call a redraw TODO maybe a little heavy...
            obj.hSlidingUValue.String = num2str(posOut(1,2));
            obj.drawScreen();
        end

        function createPopup(obj)
            % Create the figure (and hide it)
            obj.hFig = figure('Visible', 'off');
            obj.hFig.WindowStyle = 'modal';
            GUISettings.applyFigureStyle(obj.hFig);
            obj.hFig.Name = 'Matched Sequence';

            % Create the title
            obj.hTitle = uicontrol('Style', 'text');
            obj.hTitle.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hTitle);
            GUISettings.setFontScale(obj.hTitle, 1.5);
            obj.hTitle.String = 'Tweak Matching Threshold';

            % Create the configuration UI elements
            obj.hMethod = uicontrol('Style', 'text');
            obj.hMethod.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hMethod);
            obj.hMethod.String = 'Thresholding method:';

            obj.hMethodValue = uicontrol('Style', 'popupmenu');
            obj.hMethodValue.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hMethodValue);
            obj.hMethodValue.String = {'Sliding window' 'Absolute value'};

            obj.hSlidingWindow = uicontrol('Style', 'text');
            obj.hSlidingWindow.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hSlidingWindow);
            obj.hSlidingWindow.String = 'Sliding window width:';

            obj.hSlidingWindowValue = uicontrol('Style', 'edit');
            obj.hSlidingWindowValue.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hSlidingWindowValue);
            obj.hSlidingWindowValue.String = num2str( ...
                obj.config.seqslam.matching.criteria.r_window);
            obj.hSlidingWindowValue.Enable = 'off'; % TODO implement

            obj.hSlidingU = uicontrol('Style', 'text');
            obj.hSlidingU.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hSlidingU);
            obj.hSlidingU.String = 'u threshold:';

            obj.hSlidingUValue = uicontrol('Style', 'edit');
            obj.hSlidingUValue.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hSlidingUValue);
            obj.hSlidingUValue.String = num2str( ...
                obj.config.seqslam.matching.criteria.u);

            % Create the axis
            obj.hAxis = axes();
            GUISettings.applyUIAxesStyle(obj.hAxis);
            obj.hAxis.Visible = 'off';

            % Create the apply button
            obj.hApply = uicontrol('Style', 'pushbutton');
            obj.hApply.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hApply);
            obj.hApply.String = 'Apply new threshold';

            % Callbacks (must be last, otherwise empty objects passed...)
            obj.hSlidingUValue.Callback = {@obj.cbUpdateSlidingU};
            obj.hApply.Callback = {@obj.cbApplyThreshold};
        end

        function drawScreen(obj)
            % Get the value
            v = str2num(obj.hSlidingUValue.String);

            % Plot the data
            plot(obj.hAxis, obj.results.matching.all.matches(:,1), ...
                obj.results.matching.all.matches(:,2), '.');

            % Configure the axis
            obj.hAxis.Visible = 'on';
            obj.hAxis.Box = 'off';
            obj.hAxis.XLim = [min(obj.results.matching.all.matches(:,1)) ...
                max(obj.results.matching.all.matches(:,1))];
            obj.hAxis.YLim = [1 max(obj.results.matching.all.matches(:,2))];

            % Draw the overlay components
            hold(obj.hAxis, 'on');
            r = rectangle(obj.hAxis, 'Position', [obj.hAxis.XLim(1) v ...
                range(obj.hAxis.XLim) abs(obj.hAxis.YLim(2) - v)]);
            r.LineStyle = 'none';
            r.FaceColor = [GUISettings.COL_SUCCESS 0.25];
            obj.hLine = imline(obj.hAxis, obj.hAxis.XLim, [v v]);
            obj.hLine.setColor(GUISettings.COL_SUCCESS);
            obj.hLine.setPositionConstraintFcn(@obj.constrainedPosition);
            hold(obj.hAxis, 'off');
        end

        function sizePopup(obj)
            % Statically size for now
            % TODO handle potential resizing gracefully
            widthUnit = obj.hTitle.Extent(3);
            heightUnit = obj.hTitle.Extent(4);

            % Size and position the figure
            obj.hFig.Position = [0, 0, ...
                widthUnit * TweakMatchesPopup.FIG_WIDTH_FACTOR, ...
                heightUnit * TweakMatchesPopup.FIG_HEIGHT_FACTOR];
            movegui(obj.hFig, 'center');

            % Now that the figure (space for placing UI elements is set),
            % size all of the elements
            SpecSize.size(obj.hTitle, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hTitle, SpecSize.WIDTH, SpecSize.MATCH, ...
                obj.hFig, GUISettings.PAD_MED);

            SpecSize.size(obj.hMethod, SpecSize.WIDTH, SpecSize.WRAP);
            SpecSize.size(obj.hMethodValue, SpecSize.WIDTH, SpecSize.WRAP, ...
                GUISettings.PAD_LARGE);

            SpecSize.size(obj.hSlidingWindow, SpecSize.WIDTH, SpecSize.WRAP);
            SpecSize.size(obj.hSlidingWindowValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.1);
            SpecSize.size(obj.hSlidingU, SpecSize.WIDTH, SpecSize.WRAP);
            SpecSize.size(obj.hSlidingUValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.1);

            SpecSize.size(obj.hAxis, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.9);
            SpecSize.size(obj.hAxis, SpecSize.HEIGHT, SpecSize.PERCENT, ...
                obj.hFig, 0.75);

            SpecSize.size(obj.hApply, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.2);

            % Then, systematically place
            SpecPosition.positionIn(obj.hTitle, obj.hFig, ...
                SpecPosition.TOP, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hTitle, obj.hFig, ...
                SpecPosition.CENTER_X);

            SpecPosition.positionRelative(obj.hMethod, obj.hTitle, ...
                SpecPosition.BELOW, GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hMethod, obj.hFig, ...
                SpecPosition.LEFT, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hMethodValue, obj.hMethod, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMethodValue, obj.hMethod, ...
                SpecPosition.RIGHT_OF, GUISettings.PAD_MED);

            SpecPosition.positionRelative(obj.hSlidingWindow, obj.hMethod, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hSlidingWindow, ...
                obj.hMethodValue, SpecPosition.RIGHT_OF, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hSlidingWindowValue, ...
                obj.hMethod, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hSlidingWindowValue, ...
                obj.hSlidingWindow, SpecPosition.RIGHT_OF, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hSlidingU, obj.hMethod, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hSlidingU, ...
                obj.hSlidingWindowValue, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hSlidingUValue, obj.hMethod, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hSlidingUValue, obj.hSlidingU, ...
                SpecPosition.RIGHT_OF, GUISettings.PAD_MED);

            SpecPosition.positionRelative(obj.hAxis, obj.hMethod, ...
                SpecPosition.BELOW, 2*GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hAxis, obj.hFig, ...
                SpecPosition.CENTER_X);

            SpecPosition.positionIn(obj.hApply, obj.hFig, ...
                SpecPosition.BOTTOM, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hApply, obj.hFig, ...
                SpecPosition.RIGHT, GUISettings.PAD_LARGE);
        end
    end
end
