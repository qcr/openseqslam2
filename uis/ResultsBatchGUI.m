classdef ResultsBatchGUI < handle

    properties (Constant)
        FIG_WIDTH_FACTOR = 2.5;
        FIG_HEIGHT_FACTOR = 20;
    end

    properties
        hFig;

        hTitle;
        hParameter;
        hParameterValue;
        hValues;
        hValuesValue;

        hAxPR;
        hAxF1;

        results; % Note: is a batch results, not a normal results struct!
    end

    methods
        function obj = ResultsBatchGUI(results)
            % Save the batch results
            obj.results = results;

            % Create and size the GUI
            obj.createGUI();
            obj.sizeGUI();

            % Add the help button to the figure
            %obj.hHelp = HelpPopup.addHelpButton(obj.hFig);
            % TODO!

            % Draw the plots
            obj.drawPlots();

            % Finally, show the figure when we are done configuring
            obj.hFig.Visible = 'on';
        end
    end

    methods (Access = private)
        function createGUI(obj)
            % Create the figure (and hide it)
            obj.hFig = figure('Visible', 'off');
            GUISettings.applyFigureStyle(obj.hFig);
            obj.hFig.Name = 'OpenSeqSLAM2.0 Parameter Sweep Results';

            % Information elements
            obj.hTitle = uicontrol('Style', 'text');
            obj.hTitle.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hTitle);
            GUISettings.setFontScale(obj.hTitle, 2.5);
            obj.hTitle.FontWeight = 'bold';
            obj.hTitle.String = 'Batch Parameter Sweep Statistics';

            obj.hParameter = uicontrol('Style', 'text');
            obj.hParameter.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hParameter);
            GUISettings.setFontScale(obj.hParameter, 1.25);
            obj.hParameter.FontWeight = 'bold';
            obj.hParameter.String = 'Parameter Name:';

            obj.hParameterValue = uicontrol('Style', 'text');
            obj.hParameterValue.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hParameterValue);
            GUISettings.setFontScale(obj.hParameterValue, 1.25);
            obj.hParameterValue.String = obj.results.batch_param;

            obj.hValues = uicontrol('Style', 'text');
            obj.hValues.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hValues);
            GUISettings.setFontScale(obj.hValues, 1.25);
            obj.hValues.FontWeight = 'bold';
            obj.hValues.String = 'Parameter Values:';

            obj.hValuesValue = uicontrol('Style', 'text');
            obj.hValuesValue.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hValuesValue);
            GUISettings.setFontScale(obj.hValuesValue, 1.25);
            obj.hValuesValue.String = SafeData.vector2str( ...
                obj.results.batch_values);

            % Display axes
            obj.hAxPR = axes();
            GUISettings.applyUIAxesStyle(obj.hAxPR);
            obj.hAxPR.Visible = 'off';

            obj.hAxF1 = axes();
            GUISettings.applyUIAxesStyle(obj.hAxF1);
            obj.hAxF1.Visible = 'off';
        end

        function drawPlots(obj)
            % Remove all NaN elements from the data
            is = ~isnan(obj.results.precisions) & ~isnan(obj.results.recalls);
            ps = obj.results.precisions(is);
            rs = obj.results.recalls(is);
            vs = obj.results.batch_values(is);

            % Plot the precision and recall data
            cla(obj.hAxPR); hold(obj.hAxPR, 'on');
            h = plot(obj.hAxPR, rs, ps, 'bo-');
            h.MarkerFaceColor = 'b';
            h.MarkerSize = h.MarkerSize * 0.5;
            t = text(obj.hAxPR, rs(1), ps(1), num2str(vs(1)));
            t.FontSize = 14;
            t.Color = 'b';
            t.VerticalAlignment = 'top';
            t = text(obj.hAxPR, rs(end), ps(end), num2str(vs(end)));
            t.FontSize = 14;
            t.Color = 'b';
            t.VerticalAlignment = 'top';
            hold(obj.hAxPR, 'off');
            GUISettings.axesPrecisionRecallStyle(obj.hAxPR);

            % Plot the F1 scores
            cla(obj.hAxF1); hold(obj.hAxF1, 'on');
            h = plot(obj.hAxF1, vs, f1score(ps, rs), 'bo-');
            h.MarkerFaceColor = 'b';
            h.MarkerSize = h.MarkerSize * 0.5;
            hold(obj.hAxF1, 'off');
            GUISettings.axesF1Style(obj.hAxF1, vs, obj.results.batch_param);
        end

        function sizeGUI(obj)
            % Statically size for now
            % TODO handle potential resizing gracefully
            widthUnit = obj.hTitle.Extent(3) * toolboxWidthFactor();
            heightUnit = obj.hTitle.Extent(4);

            % Size and position the figure
            obj.hFig.Position = [0, 0, ...
                widthUnit * ResultsBatchGUI.FIG_WIDTH_FACTOR, ...
                heightUnit * ResultsBatchGUI.FIG_HEIGHT_FACTOR];
            movegui(obj.hFig, 'center');

            % Now that the figure (space for placing UI elements is set),
            % size all of the elements
            SpecSize.size(obj.hTitle, SpecSize.WIDTH, SpecSize.WRAP);
            SpecSize.size(obj.hTitle, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hParameter, SpecSize.WIDTH, SpecSize.WRAP);
            SpecSize.size(obj.hParameter, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hParameterValue, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.3);
            SpecSize.size(obj.hParameterValue, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hValues, SpecSize.WIDTH, SpecSize.WRAP);
            SpecSize.size(obj.hValues, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hValuesValue, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.4);
            obj.hValuesValue.String = textwrap(obj.hValuesValue, ...
                {obj.hValuesValue.String});
            SpecSize.size(obj.hValuesValue, SpecSize.HEIGHT, SpecSize.WRAP);

            SpecSize.size(obj.hAxPR, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.4);
            SpecSize.size(obj.hAxPR, SpecSize.HEIGHT, SpecSize.RATIO, 1);
            SpecSize.size(obj.hAxF1, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.4);
            SpecSize.size(obj.hAxF1, SpecSize.HEIGHT, SpecSize.RATIO, 1);

            % Then, systematically place
            SpecPosition.positionIn(obj.hTitle, obj.hFig, ...
                SpecPosition.TOP, GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hTitle, obj.hFig, ...
                SpecPosition.CENTER_X);

            SpecPosition.positionRelative(obj.hParameter, obj.hTitle, ...
                SpecPosition.BELOW, 3*GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hParameter, obj.hFig, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hParameterValue, ...
                obj.hParameter, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hParameterValue, ...
                obj.hParameter, SpecPosition.RIGHT_OF, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hValues, obj.hParameter, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hValues, obj.hParameterValue, ...
                SpecPosition.RIGHT_OF, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hValuesValue, obj.hParameter, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hValuesValue, obj.hValues, ...
                SpecPosition.RIGHT_OF, GUISettings.PAD_MED);

            SpecPosition.positionRelative(obj.hAxPR, obj.hParameter, ...
                SpecPosition.BELOW, 3*GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hAxPR, obj.hFig, ...
                SpecPosition.LEFT, 4*GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hAxF1, obj.hAxPR, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionIn(obj.hAxF1, obj.hFig, ...
                SpecPosition.RIGHT, 4*GUISettings.PAD_LARGE);
        end
    end
end
