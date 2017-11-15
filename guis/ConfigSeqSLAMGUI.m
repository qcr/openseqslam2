classdef ConfigSeqSLAMGUI < handle
    % TODO on the image preprocessing settings screen selecting the same value
    % should not cause the disabling, but currently does

    properties (Access = private, Constant)
        SCREENS = { ...
            'Image preprocessing', ...
            'Sequence Matching', ...
            'Miscellaneous'};

        % Sizing parameters
        FIG_WIDTH_FACTOR = 12;  % Times longest internal heading
        FIG_HEIGHT_FACTOR = 40; % Times height of buttons at font size

        % Visual constants
        IMAGE_FADE = 0.2;
    end

    properties
        hFig;
        hScreen;

        hImPrLoad;
        hImPrRef;
        hImPrRefSample;
        hImPrRefAxCrop;
        hImPrRefCropBox;
        hImPrRefAxResize;
        hImPrRefAxNorm;
        hImPrQuery;
        hImPrQuerySample;
        hImPrQueryAxCrop;
        hImPrQueryCropBox;
        hImPrQueryAxResize;
        hImPrQueryAxNorm;
        hImPrRefresh;
        hImPrCropRef;
        hImPrCropRefValue;
        hImPrCropQuery;
        hImPrCropQueryValue;
        hImPrResize;
        hImPrResizeW;
        hImPrResizeX;
        hImPrResizeH;
        hImPrResizeMethod;
        hImPrResizeMethodValue;
        hImPrNorm;
        hImPrNormThresh;
        hImPrNormThreshValue;
        hImPrNormStrength;
        hImPrNormStrengthValue;

        %TODO hDiff

        hMatchLoad;
        hMatchTrajTitle;
        hMatchTrajAx;
        hMatchTrajLength;
        hMatchTrajLengthValue;
        hMatchTrajVmin;
        hMatchTrajVminValue;
        hMatchTrajVmax;
        hMatchTrajVmaxValue;
        hMatchTrajVstep;
        hMatchTrajVstepValue;
        hMatchCriTitle;
        hMatchCriAx;
        hMatchCriMethod;
        hMatchCriMethodValue;
        hMatchCriWindow;
        hMatchCriWindowValue;
        hMatchCriU;
        hMatchCriUValue;
        hMatchCriThreshold;
        hMatchCriThresholdValue;

        hMscDiff;
        hMscDiffLoad;
        hMscDiffEnh;
        hMscDiffEnhValue;
        hMscVis;
        hMscVisWarn;
        hMscVisPerc;
        hMscVisPercValue;
        hMscVisPrepro;
        hMscVisPreproValue;
        hMscVisDiff;
        hMscVisDiffValue;
        hMscVisContr;
        hMscVisContrValue;
        hMscVisMatch;
        hMscVisMatchValue;

        hDone;

        config = emptyConfig();

        indicesRef = [];
        indicesQuery = [];

        listImagesRef = [];
        listImagesQuery = [];

        dimRef = [];
        dimQuery = [];

        dataTraj = [];
        dataWindow = [];
        dataThresh = [];
    end

    methods
        function obj = ConfigSeqSLAMGUI(config)
            % Build all required data
            obj.config = config;
            obj.generateImageLists();

            % Create and size the GUI
            obj.createGUI();
            obj.sizeGUI();

            % Populate the UI, and open the default screen (first)
            obj.populate();
            obj.openScreen(obj.hScreen.Value);

            % Finally, show the figure when we are done configuring
            obj.hFig.Visible = 'on';
        end
    end

    methods (Access = private, Static)
        function out = constrainInLimits(in, xlims, ylims)
            % Force the start positions to remain inside left and top limits
            out(1:2) = max(in(1:2), [xlims(1) ylims(1)]);

            % Adapt width and height so other box edges remain at same place
            %out(3:4) = in(3:4) - (out(1:2) - in(1:2));
            out(3:4) = in(3:4);

            % Force width and height to keep box inside right and bottom limits
            out(3:4) = min(out(3:4), [xlims(2) ylims(2)]-out(1:2));

            % Handle the rounding due to limits being at X.5
            if out(1) + out(3) == xlims(2)
                out(3) = out(3) - 0.01;
            end
            if out(2) + out(4) == ylims(2)
                out(4) = out(4) - 0.01;
            end
        end
    end

    methods (Access = private)
        function cbDone(obj, src, event)
            % Valid the data before proceeding
            if ~obj.isDataValid([]);
                return;
            end

            % Strip the UI data, save it in the config, and close the GUI
            obj.strip();
            close(obj.hFig);
        end

        function cbChangeCrop(obj, src, event)
            if src == obj.hImPrRefCropBox
                mask = [0 0; 1 0; 1 0];
            elseif src == obj.hImPrQueryCropBox
                mask = [0 0; 0 1; 0 1];
            end
            obj.disableProcessingPreviews(mask);
        end

        function cbChangePreviewImage(obj, src, event)
            if (src == obj.hImPrRefSample)
                mask = [1 0; 1 0; 1 0];
            elseif (src == obj.hImPrQuerySample)
                mask = [0 1; 0 1; 0 1];
            end
            obj.disableProcessingPreviews(mask);
        end

        function cbChangeResize(obj, src, event)
            % Disable the appropriate previews
            obj.disableProcessingPreviews([0 0; 1 1; 1 1]);

            % Force the other resize value to maintain the aspect ratio
            pos = obj.hImPrRefCropBox.getPosition();
            ar = pos(3) / pos(4);
            if src == obj.hImPrResizeW
                obj.hImPrResizeH.String = num2str(round( ...
                    str2num(obj.hImPrResizeW.String) / ar));
            elseif src == obj.hImPrResizeH
                obj.hImPrResizeW.String = num2str(round( ...
                    str2num(obj.hImPrResizeH.String) * ar));
            end
        end

        function cbChangeNorm(obj, src, event)
            obj.disableProcessingPreviews([0 0; 0 0; 1 1]);
        end

        function cbChangeScreen(obj, src, event)
            obj.openScreen(obj.hScreen.Value);
        end

        function cbRefreshDiagrams(obj, src, event)
            obj.drawMatchDiagrams();
        end

        function cbRefreshPreprocessed(obj, src, event)
            if ~obj.isDataValid(obj.hScreen.Value);
                return;
            end

            obj.drawProcessingPreviews();
        end

        function cbLoadMatch(obj, src, event)
            if src.Value == 0
                % Turn on all of the interactive visual elements
                obj.hMatchTrajLengthValue.Enable = 'on';
                obj.hMatchTrajVminValue.Enable = 'on';
                obj.hMatchTrajVmaxValue.Enable = 'on';
                obj.hMatchTrajVstepValue.Enable = 'on';
                obj.hMatchCriWindowValue.Enable = 'on';
                obj.hMatchCriUValue.Enable = 'on';

                % Refresh all of the diagrams
                obj.drawMatchDiagrams();
            else
                % Turn off all of the interactive visual elements
                obj.hMatchTrajLengthValue.Enable = 'off';
                obj.hMatchTrajVminValue.Enable = 'off';
                obj.hMatchTrajVmaxValue.Enable = 'off';
                obj.hMatchTrajVstepValue.Enable = 'off';
                obj.hMatchCriWindowValue.Enable = 'off';
                obj.hMatchCriUValue.Enable = 'off';

                % Mask over all of the diagrams
                % TODO MANUALLY
            end
        end

        function cbLoadProcessed(obj, src, event)
            if src.Value == 0
                % Turn on all of the interactive visual elements
                obj.hImPrRefSample.Enable = 'on';
                obj.hImPrQuerySample.Enable = 'on';
                obj.hImPrRefresh.Enable = 'on';
                obj.hImPrResizeW.Enable = 'on';
                obj.hImPrResizeH.Enable = 'on';
                obj.hImPrResizeMethodValue.Enable = 'on';
                obj.hImPrNormThreshValue.Enable = 'on';
                obj.hImPrNormStrengthValue.Enable = 'on';

                % Refresh all of the previews
                obj.drawProcessingPreviews();
            else
                % Turn off of the visual interactive elements
                obj.hImPrRefSample.Enable = 'off';
                obj.hImPrQuerySample.Enable = 'off';
                obj.hImPrRefresh.Enable = 'off';
                obj.hImPrResizeW.Enable = 'off';
                obj.hImPrResizeH.Enable = 'off';
                obj.hImPrResizeMethodValue.Enable = 'off';
                obj.hImPrNormThreshValue.Enable = 'off';
                obj.hImPrNormStrengthValue.Enable = 'off';

                % Delete any crop boxes
                delete(obj.hImPrRefCropBox);
                delete(obj.hImPrQueryCropBox);

                % Mask over all of the previews
                obj.disableProcessingPreviews([1 1; 1 1; 1 1])
            end
        end

        function cbSelectMatchMethod(obj, src, event)
            % Enable the correct visual elements (1 is the default)
            if obj.hMatchCriMethodValue.Value == 2
                obj.hMatchCriWindow.Visible = 'off';
                obj.hMatchCriWindowValue.Visible = 'off';
                obj.hMatchCriU.Visible = 'off';
                obj.hMatchCriUValue.Visible = 'off';
                obj.hMatchCriThreshold.Visible = 'on';
                obj.hMatchCriThresholdValue.Visible = 'on';
            else
                obj.hMatchCriWindow.Visible = 'on';
                obj.hMatchCriWindowValue.Visible = 'on';
                obj.hMatchCriU.Visible = 'on';
                obj.hMatchCriUValue.Visible = 'on';
                obj.hMatchCriThreshold.Visible = 'off';
                obj.hMatchCriThresholdValue.Visible = 'off';
            end

            % Refresh the diagrams
            obj.cbRefreshDiagrams(src, event);
        end

        function clearScreen(obj)
            % Hide all options
            obj.hImPrLoad.Visible = 'off';
            obj.hImPrRef.Visible = 'off';
            obj.hImPrRefSample.Visible = 'off';
            obj.hImPrRefAxCrop.Visible = 'off';
            obj.hImPrRefAxResize.Visible = 'off';
            obj.hImPrRefAxNorm.Visible = 'off';
            obj.hImPrQuery.Visible = 'off';
            obj.hImPrQuerySample.Visible = 'off';
            obj.hImPrQueryAxCrop.Visible = 'off';
            obj.hImPrQueryAxResize.Visible = 'off';
            obj.hImPrQueryAxNorm.Visible = 'off';
            obj.hImPrRefresh.Visible = 'off';
            obj.hImPrCropRef.Visible = 'off';
            obj.hImPrCropRefValue.Visible = 'off';
            obj.hImPrCropQuery.Visible = 'off';
            obj.hImPrCropQueryValue.Visible = 'off';
            obj.hImPrResize.Visible = 'off';
            obj.hImPrResizeW.Visible = 'off';
            obj.hImPrResizeX.Visible = 'off';
            obj.hImPrResizeH.Visible = 'off';
            obj.hImPrResizeMethod.Visible = 'off';
            obj.hImPrResizeMethodValue.Visible = 'off';
            obj.hImPrNorm.Visible = 'off';
            obj.hImPrNormThresh.Visible = 'off';
            obj.hImPrNormThreshValue.Visible = 'off';
            obj.hImPrNormStrength.Visible = 'off';
            obj.hImPrNormStrengthValue.Visible = 'off';

            obj.hMatchLoad.Visible = 'off';
            obj.hMatchTrajTitle.Visible = 'off';
            obj.hMatchTrajAx.Visible = 'off';
            obj.hMatchTrajLength.Visible = 'off';
            obj.hMatchTrajLengthValue.Visible = 'off';
            obj.hMatchTrajVmin.Visible = 'off';
            obj.hMatchTrajVminValue.Visible = 'off';
            obj.hMatchTrajVmax.Visible = 'off';
            obj.hMatchTrajVmaxValue.Visible = 'off';
            obj.hMatchTrajVstep.Visible = 'off';
            obj.hMatchTrajVstepValue.Visible = 'off';
            obj.hMatchCriTitle.Visible = 'off';
            obj.hMatchCriAx.Visible = 'off';
            obj.hMatchCriMethod.Visible = 'off';
            obj.hMatchCriMethodValue.Visible = 'off';
            obj.hMatchCriWindow.Visible = 'off';
            obj.hMatchCriWindowValue.Visible = 'off';
            obj.hMatchCriU.Visible = 'off';
            obj.hMatchCriUValue.Visible = 'off';
            obj.hMatchCriThreshold.Visible = 'off';
            obj.hMatchCriThresholdValue.Visible = 'off';

            obj.hMscDiff.Visible = 'off';
            obj.hMscVis.Visible = 'off';

            % Clear the axes
            cla(obj.hImPrRefAxCrop);
            cla(obj.hImPrRefAxResize);
            cla(obj.hImPrRefAxNorm);
            cla(obj.hImPrQueryAxCrop);
            cla(obj.hImPrQueryAxResize);
            cla(obj.hImPrQueryAxNorm);
            cla(obj.hMatchTrajAx);
            cla(obj.hMatchCriAx);

            % Delete any remaining objects
            delete(obj.hImPrRefCropBox);
            delete(obj.hImPrQueryCropBox);
        end

        function posOut = constrainedQueryPosition(obj, posIn)
            % Force to be within axis limits
            posOut = ConfigSeqSLAMGUI.constrainInLimits(posIn, ...
                obj.hImPrQueryAxCrop.XLim, obj.hImPrQueryAxCrop.YLim);

            % Enforce that the aspect ratio must remain the same
            if abs(posOut(3)/posOut(4) - posIn(3)/posIn(4)) > 0.001
                newW = posOut(4) * posIn(3)/posIn(4);
                newH = posOut(3) * posIn(4)/posIn(3);
                if newW < posOut(3)
                    posOut(3) = newW;
                elseif newH < posOut(4)
                    posOut(4) = newH;
                end
            end

            % Update the text boxes
            pos = SafeData.vector2str(round( ...
                [posOut(1:2) posOut(1:2)+posOut(3:4)]));
            obj.hImPrCropQueryValue.String = pos;
        end

        function posOut = constrainedRefPosition(obj, posIn)
            % Force to be within axis limits
            posOut = ConfigSeqSLAMGUI.constrainInLimits(posIn, ...
                obj.hImPrRefAxCrop.XLim, obj.hImPrRefAxCrop.YLim);

            % Force the other crop box to have the same position
            % TODO could be more flexible here... but this is easy
            obj.hImPrQueryCropBox.setPosition(posOut);

            % Update the text boxes
            pos = SafeData.vector2str(round( ...
                [posOut(1:2) posOut(1:2)+posOut(3:4)]));
            obj.hImPrCropRefValue.String = pos;
            obj.hImPrCropQueryValue.String = pos;
        end

        function createGUI(obj)
            % Create the figure (and hide it)
            obj.hFig = figure('Visible', 'off');
            obj.hFig.WindowStyle = 'modal';
            GUISettings.applyFigureStyle(obj.hFig);
            obj.hFig.Name = 'SeqSLAM Settings';
            obj.hFig.Resize = 'off';

            % Create the dropdown list for toggling the setting screens
            obj.hScreen = uicontrol('Style', 'popupmenu');
            obj.hScreen.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hScreen);
            obj.hScreen.String = ConfigSeqSLAMGUI.SCREENS;

            % Create the image processing panel
            obj.hImPrLoad = uicontrol('Style', 'checkbox');
            obj.hImPrLoad.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hImPrLoad);
            obj.hImPrLoad.String = 'Load existing';

            obj.hImPrRef = uicontrol('Style', 'text');
            obj.hImPrRef.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hImPrRef);
            obj.hImPrRef.String = 'Reference Image Preview:';
            obj.hImPrRef.HorizontalAlignment = 'left';

            obj.hImPrRefSample = uicontrol('Style', 'popupmenu');
            obj.hImPrRefSample.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hImPrRefSample);
            obj.hImPrRefSample.String = obj.listImagesRef;

            obj.hImPrRefAxCrop = axes();
            GUISettings.applyUIAxesStyle(obj.hImPrRefAxCrop);
            obj.hImPrRefAxCrop.Visible = 'off';

            obj.hImPrRefAxResize = axes();
            GUISettings.applyUIAxesStyle(obj.hImPrRefAxResize);
            obj.hImPrRefAxResize.Visible = 'off';

            obj.hImPrRefAxNorm = axes();
            GUISettings.applyUIAxesStyle(obj.hImPrRefAxNorm);
            obj.hImPrRefAxNorm.Visible = 'off';

            obj.hImPrQuery = uicontrol('Style', 'text');
            obj.hImPrQuery.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hImPrQuery);
            obj.hImPrQuery.String = 'Query Image Preview:';
            obj.hImPrQuery.HorizontalAlignment = 'left';

            obj.hImPrQuerySample = uicontrol('Style', 'popupmenu');
            obj.hImPrQuerySample.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hImPrQuerySample);
            obj.hImPrQuerySample.String = obj.listImagesQuery;

            obj.hImPrQueryAxCrop = axes();
            GUISettings.applyUIAxesStyle(obj.hImPrQueryAxCrop);
            obj.hImPrQueryAxCrop.Visible = 'off';

            obj.hImPrQueryAxResize = axes();
            GUISettings.applyUIAxesStyle(obj.hImPrQueryAxResize);
            obj.hImPrQueryAxResize.Visible = 'off';

            obj.hImPrQueryAxNorm = axes();
            GUISettings.applyUIAxesStyle(obj.hImPrQueryAxNorm);
            obj.hImPrQueryAxNorm.Visible = 'off';

            obj.hImPrRefresh = uicontrol('Style', 'pushbutton');
            obj.hImPrRefresh.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hImPrRefresh);
            obj.hImPrRefresh.String = 'Refresh previews';

            obj.hImPrCropRef = uicontrol('Style', 'text');
            obj.hImPrCropRef.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hImPrCropRef);
            obj.hImPrCropRef.String = 'Reference image crop:';

            obj.hImPrCropRefValue = uicontrol('Style', 'edit');
            obj.hImPrCropRefValue.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hImPrCropRefValue);
            obj.hImPrCropRefValue.String = '';
            obj.hImPrCropRefValue.Enable = 'off';

            obj.hImPrCropQuery = uicontrol('Style', 'text');
            obj.hImPrCropQuery.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hImPrCropQuery);
            obj.hImPrCropQuery.String = 'Query image crop:';

            obj.hImPrCropQueryValue = uicontrol('Style', 'edit');
            obj.hImPrCropQueryValue.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hImPrCropQueryValue);
            obj.hImPrCropQueryValue.String = '';
            obj.hImPrCropQueryValue.Enable = 'off';

            obj.hImPrResize = uicontrol('Style', 'text');
            obj.hImPrResize.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hImPrResize);
            obj.hImPrResize.String = 'Resized dimensions:';

            obj.hImPrResizeW = uicontrol('Style', 'edit');
            obj.hImPrResizeW.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hImPrResizeW);
            obj.hImPrResizeW.String = '';

            obj.hImPrResizeX = uicontrol('Style', 'text');
            obj.hImPrResizeX.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hImPrResizeX);
            obj.hImPrResizeX.String = 'x';

            obj.hImPrResizeH = uicontrol('Style', 'edit');
            obj.hImPrResizeH.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hImPrResizeH);
            obj.hImPrResizeH.String = '';

            obj.hImPrResizeMethod = uicontrol('Style', 'text');
            obj.hImPrResizeMethod.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hImPrResizeMethod);
            obj.hImPrResizeMethod.String = 'Resize method:';

            obj.hImPrResizeMethodValue = uicontrol('Style', 'popupmenu');
            obj.hImPrResizeMethodValue.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hImPrResizeMethodValue);
            obj.hImPrResizeMethodValue.String = {'lanczos3' 'TODO'};

            obj.hImPrNorm = uicontrol('Style', 'text');
            obj.hImPrNorm.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hImPrNorm);
            obj.hImPrNorm.String = 'Normalisation:';

            obj.hImPrNormThresh = uicontrol('Style', 'text');
            obj.hImPrNormThresh.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hImPrNormThresh);
            obj.hImPrNormThresh.String = 'Edge threshold:';
            obj.hImPrNormThresh.HorizontalAlignment = 'left';

            obj.hImPrNormThreshValue = uicontrol('Style', 'edit');
            obj.hImPrNormThreshValue.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hImPrNormThreshValue);
            obj.hImPrNormThreshValue.String = '';

            obj.hImPrNormStrength = uicontrol('Style', 'text');
            obj.hImPrNormStrength.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hImPrNormStrength);
            obj.hImPrNormStrength.String = 'Enhance strength:';
            obj.hImPrNormStrength.HorizontalAlignment = 'left';

            obj.hImPrNormStrengthValue = uicontrol('Style', 'edit');
            obj.hImPrNormStrengthValue.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hImPrNormStrengthValue);
            obj.hImPrNormStrengthValue.String = '';

            % Create the difference matrix panel
            % TODO

            % Create the matching panel
            obj.hMatchLoad = uicontrol('Style', 'checkbox');
            obj.hMatchLoad.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hMatchLoad);
            obj.hMatchLoad.String = 'Load existing';

            obj.hMatchTrajTitle = uicontrol('Style', 'text');
            obj.hMatchTrajTitle.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hMatchTrajTitle);
            obj.hMatchTrajTitle.String = 'Search Trajectory Settings';

            obj.hMatchTrajAx = axes();
            GUISettings.applyUIAxesStyle(obj.hMatchTrajAx);
            obj.hMatchTrajAx.YDir = 'reverse';
            obj.hMatchTrajAx.Visible = 'off';

            obj.hMatchTrajLength = annotation(obj.hFig, 'textbox');
            obj.hMatchTrajLength.String = 'Trajectory length ($d_s$):';
            GUISettings.applyAnnotationStyle(obj.hMatchTrajLength);

            obj.hMatchTrajLengthValue = uicontrol('Style', 'edit');
            obj.hMatchTrajLengthValue.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hMatchTrajLengthValue);
            obj.hMatchTrajLengthValue.String = '';

            obj.hMatchTrajVmin = annotation(obj.hFig, 'textbox');
            obj.hMatchTrajVmin.String = 'Trajectory $v_{min}$:';
            GUISettings.applyAnnotationStyle(obj.hMatchTrajVmin);

            obj.hMatchTrajVminValue = uicontrol('Style', 'edit');
            obj.hMatchTrajVminValue.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hMatchTrajVminValue);
            obj.hMatchTrajVminValue.String = '';

            obj.hMatchTrajVmax = annotation(obj.hFig, 'textbox');
            obj.hMatchTrajVmax.String = 'Trajectory $v_{max}$:';
            GUISettings.applyAnnotationStyle(obj.hMatchTrajVmax);

            obj.hMatchTrajVmaxValue = uicontrol('Style', 'edit');
            obj.hMatchTrajVmaxValue.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hMatchTrajVmaxValue);
            obj.hMatchTrajVmaxValue.String = '';

            obj.hMatchTrajVstep = annotation(obj.hFig, 'textbox');
            obj.hMatchTrajVstep.String = 'Trajectory $v_{step}$:';
            GUISettings.applyAnnotationStyle(obj.hMatchTrajVstep);

            obj.hMatchTrajVstepValue = uicontrol('Style', 'edit');
            obj.hMatchTrajVstepValue.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hMatchTrajVstepValue);
            obj.hMatchTrajVstepValue.String = '';

            obj.hMatchCriTitle = uicontrol('Style', 'text');
            obj.hMatchCriTitle.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hMatchCriTitle);
            obj.hMatchCriTitle.String = 'Match Selection Settings';

            obj.hMatchCriAx = axes();
            GUISettings.applyUIAxesStyle(obj.hMatchCriAx);
            obj.hMatchCriAx.XAxisLocation = 'top';
            obj.hMatchCriAx.Visible = 'off';

            obj.hMatchCriMethod = annotation(obj.hFig, 'textbox');
            obj.hMatchCriMethod.String = 'Selection Method:';
            GUISettings.applyAnnotationStyle(obj.hMatchCriMethod);

            obj.hMatchCriMethodValue = uicontrol('Style', 'popupmenu');
            obj.hMatchCriMethodValue.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hMatchCriMethodValue);
            obj.hMatchCriMethodValue.String = ...
                { 'Windowed Uniqueness' 'Basic Thresholding' };

            obj.hMatchCriWindow = annotation(obj.hFig, 'textbox');
            obj.hMatchCriWindow.String = 'Exclusion window ($r_{window}$):';
            GUISettings.applyAnnotationStyle(obj.hMatchCriWindow);

            obj.hMatchCriWindowValue = uicontrol('Style', 'edit');
            obj.hMatchCriWindowValue.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hMatchCriWindowValue);
            obj.hMatchCriWindowValue.String = '';

            obj.hMatchCriU = annotation(obj.hFig, 'textbox');
            obj.hMatchCriU.String = ...
                'Uniqueness factor ($\mu = \frac{min_2}{min_1}$):';
            GUISettings.applyAnnotationStyle(obj.hMatchCriU);

            obj.hMatchCriUValue = uicontrol('Style', 'edit');
            obj.hMatchCriUValue.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hMatchCriUValue);
            obj.hMatchCriUValue.String = '';

            obj.hMatchCriThreshold = annotation(obj.hFig, 'textbox');
            obj.hMatchCriThreshold.String = 'Threshold ($\lambda$):';
            GUISettings.applyAnnotationStyle(obj.hMatchCriThreshold);

            obj.hMatchCriThresholdValue = uicontrol('Style', 'edit');
            obj.hMatchCriThresholdValue.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hMatchCriThresholdValue);
            obj.hMatchCriThresholdValue.String = '';

            obj.hMscDiff = uipanel();
            GUISettings.applyUIPanelStyle(obj.hMscDiff);
            obj.hMscDiff.Title = 'Difference Matrix Contrast Enhancement';

            obj.hMscDiffLoad = uicontrol('Style', 'checkbox');
            obj.hMscDiffLoad.Parent = obj.hMscDiff;
            GUISettings.applyUIControlStyle(obj.hMscDiffLoad);
            obj.hMscDiffLoad.String = 'Load existing';

            obj.hMscDiffEnh = annotation(obj.hMscDiff, 'textbox');
            obj.hMscDiffEnh.String = ...
                'Enhancement Window Size ($R_{window}$):';
            GUISettings.applyAnnotationStyle(obj.hMscDiffEnh);

            obj.hMscDiffEnhValue = uicontrol('Style', 'edit');
            obj.hMscDiffEnhValue.Parent = obj.hMscDiff;
            GUISettings.applyUIControlStyle(obj.hMscDiffEnhValue);
            obj.hMscDiffEnhValue.String = '';

            obj.hMscVis = uipanel();
            GUISettings.applyUIPanelStyle(obj.hMscVis);
            obj.hMscVis.Title = 'Progress UI Visualisation Timings';

            obj.hMscVisWarn = uicontrol('Style', 'text');
            obj.hMscVisWarn.Parent = obj.hMscVis;
            GUISettings.applyUIControlStyle(obj.hMscVisWarn);
            obj.hMscVisWarn.String = 'Note: Lowering values can significantly decrease performance!';
            obj.hMscVisWarn.ForegroundColor = GUISettings.COL_ERROR;
            obj.hMscVisWarn.FontWeight = 'bold';
            obj.hMscVisWarn.FontAngle = 'italic';

            obj.hMscVisPerc = uicontrol('Style', 'text');
            obj.hMscVisPerc.Parent = obj.hMscVis;
            GUISettings.applyUIControlStyle(obj.hMscVisPerc);
            obj.hMscVisPerc.String = 'Percent value update frequency (%):';
            obj.hMscVisPerc.HorizontalAlignment = 'left';

            obj.hMscVisPercValue = uicontrol('Style', 'edit');
            obj.hMscVisPercValue.Parent = obj.hMscVis;
            GUISettings.applyUIControlStyle(obj.hMscVisPercValue);
            obj.hMscVisPercValue.String = '';

            obj.hMscVisPrepro = uicontrol('Style', 'text');
            obj.hMscVisPrepro.Parent = obj.hMscVis;
            GUISettings.applyUIControlStyle(obj.hMscVisPrepro);
            obj.hMscVisPrepro.String = 'Preprocessing visualisation update frequency (%):';
            obj.hMscVisPrepro.HorizontalAlignment = 'left';

            obj.hMscVisPreproValue = uicontrol('Style', 'edit');
            obj.hMscVisPreproValue.Parent = obj.hMscVis;
            GUISettings.applyUIControlStyle(obj.hMscVisPreproValue);
            obj.hMscVisPreproValue.String = '';

            obj.hMscVisDiff = uicontrol('Style', 'text');
            obj.hMscVisDiff.Parent = obj.hMscVis;
            GUISettings.applyUIControlStyle(obj.hMscVisDiff);
            obj.hMscVisDiff.String = 'Difference matrix visualisation update frequency (%):';
            obj.hMscVisDiff.HorizontalAlignment = 'left';

            obj.hMscVisDiffValue = uicontrol('Style', 'edit');
            obj.hMscVisDiffValue.Parent = obj.hMscVis;
            GUISettings.applyUIControlStyle(obj.hMscVisDiffValue);
            obj.hMscVisDiffValue.String = '';

            obj.hMscVisContr = uicontrol('Style', 'text');
            obj.hMscVisContr.Parent = obj.hMscVis;
            GUISettings.applyUIControlStyle(obj.hMscVisContr);
            obj.hMscVisContr.String = 'Local contrast visualisation update frequency (%):';
            obj.hMscVisContr.HorizontalAlignment = 'left';

            obj.hMscVisContrValue = uicontrol('Style', 'edit');
            obj.hMscVisContrValue.Parent = obj.hMscVis;
            GUISettings.applyUIControlStyle(obj.hMscVisContrValue);
            obj.hMscVisContrValue.String = '';

            obj.hMscVisMatch = uicontrol('Style', 'text');
            obj.hMscVisMatch.Parent = obj.hMscVis;
            GUISettings.applyUIControlStyle(obj.hMscVisMatch);
            obj.hMscVisMatch.String = 'Matching visualisation update frequency (%):';
            obj.hMscVisMatch.HorizontalAlignment = 'left';

            obj.hMscVisMatchValue = uicontrol('Style', 'edit');
            obj.hMscVisMatchValue.Parent = obj.hMscVis;
            GUISettings.applyUIControlStyle(obj.hMscVisMatchValue);
            obj.hMscVisMatchValue.String = '';

            % Done button
            obj.hDone = uicontrol('Style', 'pushbutton');
            GUISettings.applyUIControlStyle(obj.hDone);
            obj.hDone.String = 'Done';

            % Callbacks (must be last, otherwise empty objects passed...)
            obj.hScreen.Callback = {@obj.cbChangeScreen};
            obj.hImPrLoad.Callback = {@obj.cbLoadProcessed};
            obj.hImPrRefSample.Callback = {@obj.cbChangePreviewImage};
            obj.hImPrQuerySample.Callback = {@obj.cbChangePreviewImage};
            obj.hImPrRefresh.Callback = {@obj.cbRefreshPreprocessed};
            obj.hImPrResizeW.Callback = {@obj.cbChangeResize};
            obj.hImPrResizeH.Callback = {@obj.cbChangeResize};
            obj.hImPrResizeMethodValue.Callback = {@obj.cbChangeResize};
            obj.hImPrNormThreshValue.Callback = {@obj.cbChangeNorm};
            obj.hImPrNormStrengthValue.Callback = {@obj.cbChangeNorm};
            obj.hMatchLoad.Callback = {@obj.cbLoadMatch};
            obj.hMatchTrajLengthValue.Callback = {@obj.cbRefreshDiagrams};
            obj.hMatchTrajVminValue.Callback = {@obj.cbRefreshDiagrams};
            obj.hMatchTrajVmaxValue.Callback = {@obj.cbRefreshDiagrams};
            obj.hMatchTrajVstepValue.Callback = {@obj.cbRefreshDiagrams};
            obj.hMatchCriMethodValue.Callback = {@obj.cbSelectMatchMethod};
            obj.hMatchCriWindowValue.Callback = {@obj.cbRefreshDiagrams};
            obj.hMatchCriUValue.Callback = {@obj.cbRefreshDiagrams};
            obj.hMatchCriThresholdValue.Callback = {@obj.cbRefreshDiagrams};
            obj.hDone.Callback = {@obj.cbDone};
        end

        function disableProcessingPreviews(obj, mask)
            axs = [ ...
                obj.hImPrRefAxCrop   , obj.hImPrQueryAxCrop; ...
                obj.hImPrRefAxResize , obj.hImPrQueryAxResize; ...
                obj.hImPrRefAxNorm   , obj.hImPrQueryAxNorm ...
                ];
            axs = axs(logical(mask));
            arrayfun(@(x) alpha(x, ConfigSeqSLAMGUI.IMAGE_FADE), axs);
        end

        function drawMatchDiagrams(obj)
            % Useful temporaries
            ds = str2num(obj.hMatchTrajLengthValue.String);
            vmin = str2num(obj.hMatchTrajVminValue.String);
            vmax = str2num(obj.hMatchTrajVmaxValue.String);
            vstep = str2num(obj.hMatchTrajVstepValue.String);

            rwin = str2num(obj.hMatchCriWindowValue.String);

            % Draw the trajectory preview diagram
            FACTOR = 1.5;
            sz = round(0.5*ds*FACTOR) * 2 - 1;  % Ensure there is always a middle
            center = ceil(0.5*sz);
            offBack = floor((ds-1)/2);
            offFront = floor(ds/2);
            if (sz ~= length(obj.dataTraj))
                obj.dataTraj = rand(sz);
            end
            cla(obj.hMatchTrajAx);
            hold(obj.hMatchTrajAx, 'on');
            obj.hMatchTrajAx.Visible = 'off';
            h = imagesc(obj.dataTraj, 'Parent', obj.hMatchTrajAx);
            h.AlphaData = 0.5;
            h = plot(obj.hMatchTrajAx, center, center, 'k.');
            h.MarkerSize = h.MarkerSize * 6;
            for k = [vmin:vstep:vmax vmax]
                th = atan(k);
                h =plot(obj.hMatchTrajAx, ...
                    [center-offBack center+offFront], ...
                    [center-offBack*sin(th) center+offFront*sin(th)], 'k');
                if k == vmin || k == vmax
                    h.LineWidth = h.LineWidth * 3;
                end
            end

            % Add text annotations to the trajectory preview diagram
            h = text(obj.hMatchTrajAx, center+offFront, ...
                center+offFront*sin(atan(vmin)), '$v_{min}$', ...
                'interpreter', 'latex', 'HorizontalAlignment', 'left', ...
                'VerticalAlignment', 'bottom');
            h.FontSize = h.FontSize * GUISettings.LATEX_FACTOR * 1.25;
            h = text(obj.hMatchTrajAx, center+offFront, ...
                center+offFront*sin(atan(vmax)), '$v_{max}$', ...
                'interpreter', 'latex', 'HorizontalAlignment', 'left', ...
                'VerticalAlignment', 'top');
            h.FontSize = h.FontSize * GUISettings.LATEX_FACTOR * 1.25;
            h = text(obj.hMatchTrajAx, center+offFront, ...
                center+offFront*mean([sin(atan(vmin)) sin(atan(vmax))]), ...
                '$v_{step}$', 'interpreter', 'latex', 'HorizontalAlignment', ...
                'left', 'VerticalAlignment', 'middle');
            h.FontSize = h.FontSize * GUISettings.LATEX_FACTOR * 1.25;
            plot(obj.hMatchTrajAx, [center-offBack center+offFront], ...
                [sz sz], 'k');
            h = plot(obj.hMatchTrajAx, center-offBack, sz, 'k<');
            h.MarkerFaceColor = 'k';
            h = plot(obj.hMatchTrajAx, center+offFront, sz, 'k>');
            h.MarkerFaceColor = 'k';
            h = text(obj.hMatchTrajAx, center, sz-0.5, '$d_s$', ...
                'interpreter', 'latex', 'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom');
            h.FontSize = h.FontSize * GUISettings.LATEX_FACTOR * 1.25;
            hold(obj.hMatchTrajAx, 'off');

            % Draw match selection diagram for the chosen method
            if (obj.hMatchCriMethodValue.Value == 2)
                % Draw the thresholded selction method diagram
                if (length(obj.dataThresh) ~= 100)
                    data = -1 * rand(1, 100);
                end
                cla(obj.hMatchCriAx);
                hold(obj.hMatchCriAx, 'on');
                h = plot(obj.hMatchCriAx, obj.dataThresh, 'k.');
                h.MarkerSize = h.MarkerSize * 2;
                r = rectangle(obj.hMatchCriAx, 'Position', ...
                    [0 -1 100 0.4]);
                r.FaceColor = [GUISettings.COL_SUCCESS 0.25];
                r.EdgeColor = 'none';
                h = plot(obj.hMatchCriAx, [0 100], [-0.6 -0.6], 'k:');
                h.LineWidth = h.LineWidth * 2;
                hold(obj.hMatchCriAx, 'off');
                obj.hMatchCriAx.YLim = [-1 0];
                obj.hMatchCriAx.XLabel.String = 'query image #';
                obj.hMatchCriAx.XTick = [];
                obj.hMatchCriAx.YLabel.String = 'lowest trajectory score';
                obj.hMatchCriAx.YTick = [];

                % Add text annotations for the thresholded selection method
                h = text(obj.hMatchCriAx, 100, -0.6, '$\lambda$', ...
                    'interpreter', 'latex', 'HorizontalAlignment', 'right', ...
                    'VerticalAlignment', 'top');
                h.FontSize = h.FontSize * GUISettings.LATEX_FACTOR * 1.25;
            else
                % Draw the windowed selection method diagram
                if (length(obj.dataWindow) ~= 5*rwin)
                    obj.dataWindow = -1 * rand(1, 5*rwin);
                    obj.dataWindow(2*rwin:3*rwin-1) = ...
                        obj.dataWindow(2*rwin:3*rwin-1) - 0.5;
                    obj.dataWindow(end/2) = -1.5;
                end
                minwin = min(obj.dataWindow(2*rwin:3*rwin-1));
                minout = min([obj.dataWindow(1:2*rwin-1) ...
                    obj.dataWindow(3*rwin:end)]);
                cla(obj.hMatchCriAx);
                hold(obj.hMatchCriAx, 'on');
                h = plot(obj.hMatchCriAx, obj.dataWindow, 'k.');
                h.MarkerSize = h.MarkerSize * 2;
                r = rectangle(obj.hMatchCriAx, 'Position', ...
                    [2*rwin -1.75 rwin 1.75]);
                r.FaceColor = [GUISettings.COL_DEFAULT 0.25];
                r.EdgeColor = 'none';
                h = plot(obj.hMatchCriAx, [0 5*rwin], [minwin minwin], 'k');
                h.LineWidth = h.LineWidth * 2;
                h = plot(obj.hMatchCriAx, [0 5*rwin], [minout minout], 'k:');
                h.LineWidth = h.LineWidth * 2;
                hold(obj.hMatchCriAx, 'off');
                obj.hMatchCriAx.YLim = [-1.75 0];
                obj.hMatchCriAx.XLabel.String = 'reference image #';
                obj.hMatchCriAx.XTick = [];
                obj.hMatchCriAx.YLabel.String = 'trajectory score';
                obj.hMatchCriAx.YTick = [];

                % Add text annotations to the windowed selection method diagram
                h = text(obj.hMatchCriAx, 5*rwin, minout, '$min_2$', ...
                    'interpreter', 'latex', 'HorizontalAlignment', 'right', ...
                    'VerticalAlignment', 'top');
                h.FontSize = h.FontSize * GUISettings.LATEX_FACTOR * 1.25;
                h = text(obj.hMatchCriAx, 5*rwin, minwin, '$min_1$', ...
                    'interpreter', 'latex', 'HorizontalAlignment', 'right', ...
                    'VerticalAlignment', 'bottom');
                h.FontSize = h.FontSize * GUISettings.LATEX_FACTOR * 1.25;
            end
        end

        function drawProcessingPreviews(obj)
            % Strip the UI (we need the config to be up to date)
            obj.strip();

            % Generate all of the required images
            refImg = datasetOpenImage(obj.config.reference, ...
                obj.hImPrRefSample.Value, obj.indicesRef);
            queryImg = datasetOpenImage(obj.config.query, ...
                obj.hImPrQuerySample.Value, obj.indicesQuery);
            [refImgOut, refImgs] = SeqSLAMInstance.preprocessSingle( ...
                refImg, obj.config.seqslam.image_processing, 'reference', 1);
            [queryImgOut, queryImgs] = SeqSLAMInstance.preprocessSingle( ...
                queryImg, obj.config.seqslam.image_processing, 'query', 1);

            % Clear all axes
            cla(obj.hImPrRefAxCrop);
            cla(obj.hImPrRefAxResize);
            cla(obj.hImPrRefAxNorm);
            cla(obj.hImPrQueryAxCrop);
            cla(obj.hImPrQueryAxResize);
            cla(obj.hImPrQueryAxNorm);

            % Show all of the images
            imshow(refImg, 'Parent', obj.hImPrRefAxCrop);
            imshow(refImgs{2}, 'Parent', obj.hImPrRefAxResize);
            imshow(refImgOut, 'Parent', obj.hImPrRefAxNorm);
            imshow(queryImg, 'Parent', obj.hImPrQueryAxCrop);
            imshow(queryImgs{2}, 'Parent', obj.hImPrQueryAxResize);
            imshow(queryImgOut, 'Parent', obj.hImPrQueryAxNorm);

            % Draw the crop-boxes
            obj.hImPrRefCropBox = imrect(obj.hImPrRefAxCrop, ...
                [obj.hImPrRefAxCrop.XLim(1) obj.hImPrRefAxCrop.YLim(1) ...
                diff(obj.hImPrRefAxCrop.XLim) diff(obj.hImPrRefAxCrop.YLim)]);
            obj.hImPrRefCropBox.setPositionConstraintFcn( ...
                @obj.constrainedRefPosition);
            obj.hImPrQueryCropBox = imrect(obj.hImPrQueryAxCrop, ...
                [obj.hImPrQueryAxCrop.XLim(1) obj.hImPrQueryAxCrop.YLim(1) ...
                diff(obj.hImPrQueryAxCrop.XLim) diff(obj.hImPrQueryAxCrop.YLim)]);
            obj.hImPrQueryCropBox.setPositionConstraintFcn( ...
                @obj.constrainedQueryPosition);
            obj.hImPrQueryCropBox.setFixedAspectRatioMode(1);
        end

        function generateImageLists(obj)
            obj.indicesRef = SeqSLAMInstance.indices(obj.config.reference);
            obj.listImagesRef = datasetImageList(obj.config.reference, ...
                obj.indicesRef);
            obj.indicesQuery = SeqSLAMInstance.indices(obj.config.query);
            obj.listImagesQuery = datasetImageList(obj.config.query, ...
                obj.indicesQuery);
        end

        function valid = isDataValid(obj, screen)
            valid = false;
            if isempty(screen) || screen == 1
                % Normalisation threshold
                v = str2num(obj.hImPrNormThreshValue.String);
                if v < 0 || v > 1
                    errordlg( ...
                        'Normalisation edge threshold must be in range [0, 1]');
                    return;
                end

                % Normalisation strength
                v = str2num(obj.hImPrNormStrengthValue.String);
                if v < -1 || v > 1
                    errordlg( ...
                        'Normalisation strength must be in range [-1, 1]');
                    return;
                end
            end

            valid = true;
        end

        function openScreen(obj, screen)
            % Clear everything off the screen
            obj.clearScreen();

            % Add the appropriate elements for the screen
            if (screen == 1)
                % Image preprocessing settings
                % Show the appropriate options and axes
                obj.hImPrLoad.Visible = 'on';
                obj.hImPrRef.Visible = 'on';
                obj.hImPrRefSample.Visible = 'on';
                obj.hImPrRefAxCrop.Visible = 'on';
                obj.hImPrRefAxResize.Visible = 'on';
                obj.hImPrRefAxNorm.Visible = 'on';
                obj.hImPrQuery.Visible = 'on';
                obj.hImPrQuerySample.Visible = 'on';
                obj.hImPrQueryAxCrop.Visible = 'on';
                obj.hImPrQueryAxResize.Visible = 'on';
                obj.hImPrQueryAxNorm.Visible = 'on';
                obj.hImPrRefresh.Visible = 'on';
                obj.hImPrCropRef.Visible = 'on';
                obj.hImPrCropRefValue.Visible = 'on';
                obj.hImPrCropQuery.Visible = 'on';
                obj.hImPrCropQueryValue.Visible = 'on';
                obj.hImPrResize.Visible = 'on';
                obj.hImPrResizeW.Visible = 'on';
                obj.hImPrResizeX.Visible = 'on';
                obj.hImPrResizeH.Visible = 'on';
                obj.hImPrResizeMethod.Visible = 'on';
                obj.hImPrResizeMethodValue.Visible = 'on';
                obj.hImPrNorm.Visible = 'on';
                obj.hImPrNormThresh.Visible = 'on';
                obj.hImPrNormThreshValue.Visible = 'on';
                obj.hImPrNormStrength.Visible = 'on';
                obj.hImPrNormStrengthValue.Visible = 'on';

                % Force a refresh of all of the previews
                obj.drawProcessingPreviews();

                % Force the load setting to apply
                obj.cbLoadProcessed(obj.hImPrLoad, []);
            elseif (screen == 2)
                % Matching settings
                % Show the appropriate options and axes
                obj.hMatchLoad.Visible = 'on';
                obj.hMatchTrajTitle.Visible = 'on';
                obj.hMatchTrajAx.Visible = 'on';
                obj.hMatchTrajLength.Visible = 'on';
                obj.hMatchTrajLengthValue.Visible = 'on';
                obj.hMatchTrajVmin.Visible = 'on';
                obj.hMatchTrajVminValue.Visible = 'on';
                obj.hMatchTrajVmax.Visible = 'on';
                obj.hMatchTrajVmaxValue.Visible = 'on';
                obj.hMatchTrajVstep.Visible = 'on';
                obj.hMatchTrajVstepValue.Visible = 'on';
                obj.hMatchCriTitle.Visible = 'on';
                obj.hMatchCriAx.Visible = 'on';
                obj.hMatchCriMethod.Visible = 'on';
                obj.hMatchCriMethodValue.Visible = 'on';
                obj.hMatchCriWindow.Visible = 'on';
                obj.hMatchCriWindowValue.Visible = 'on';
                obj.hMatchCriU.Visible = 'on';
                obj.hMatchCriUValue.Visible = 'on';
                obj.hMatchCriThreshold.Visible = 'on';
                obj.hMatchCriThresholdValue.Visible = 'on';

                % Force a refresh of all of the diagrams
                obj.drawMatchDiagrams();

                % Force the calling of any necessary callbacks
                obj.cbSelectMatchMethod(obj.hMatchCriMethodValue, []);
                obj.cbLoadMatch(obj.hMatchLoad, []);
            elseif (screen == 3)
                % Other settings
                obj.hMscDiff.Visible = 'on';
                obj.hMscVis.Visible = 'on';
            end

            % Force a draw at the end
            drawnow();
        end

        function populate(obj)
            % Use the first image in each dataset to get some reference dimensions
            obj.dimRef = size(datasetOpenImage(obj.config.reference, 1, ...
                obj.indicesRef));
            obj.dimQuery = size(datasetOpenImage(obj.config.query, 1, ...
                obj.indicesQuery));

            % Dump all data from the config struct to the UI
            obj.hImPrLoad.Value = SafeData.noEmpty( ...
                obj.config.seqslam.image_processing.load, 0);
            obj.hImPrCropRefValue.String = SafeData.noEmpty( ...
                obj.config.seqslam.image_processing.crop.reference, ...
                ['1, 1, ' num2str(obj.dimRef(2)) ', ' num2str(obj.dimRef(1))]);
            obj.hImPrCropQueryValue.String = SafeData.noEmpty( ...
                obj.config.seqslam.image_processing.crop.query, ['1, 1, ' ...
                num2str(obj.dimQuery(2)) ', ' num2str(obj.dimQuery(1))]);
            obj.hImPrResizeW.String = SafeData.noEmpty( ...
                obj.config.seqslam.image_processing.downsample.width, ...
                obj.dimRef(2));
            obj.hImPrResizeH.String = SafeData.noEmpty( ...
                obj.config.seqslam.image_processing.downsample.height, ...
                obj.dimRef(1));
            obj.hImPrNormThreshValue.String = SafeData.noEmpty( ...
                obj.config.seqslam.image_processing.normalisation.threshold,...
                0.5);
            obj.hImPrNormStrengthValue.String = SafeData.noEmpty( ...
                obj.config.seqslam.image_processing.normalisation.strength, ...
                0.5);

            obj.hMatchLoad.Value = SafeData.noEmpty( ...
                obj.config.seqslam.matching.load, 0);
            obj.hMatchTrajLengthValue.String = SafeData.noEmpty( ...
                obj.config.seqslam.matching.trajectory.d_s, 10);
            obj.hMatchTrajVminValue.String = SafeData.noEmpty( ...
                obj.config.seqslam.matching.trajectory.v_min, 0.8);
            obj.hMatchTrajVmaxValue.String = SafeData.noEmpty( ...
                obj.config.seqslam.matching.trajectory.v_max, 1.2);
            obj.hMatchTrajVstepValue.String = SafeData.noEmpty( ...
                obj.config.seqslam.matching.trajectory.v_step, 0.1);
            method = SafeData.noEmpty(obj.config.seqslam.matching.method, ...
                'window');
            if strcmpi(method, 'thresh')
                obj.hMatchCriMethodValue.Value = 2;
            else
                obj.hMatchCriMethodValue.Value = 1;
            end
            obj.hMatchCriWindowValue.String = SafeData.noEmpty( ...
                obj.config.seqslam.matching.method_window.r_window, 10);
            obj.hMatchCriUValue.String = SafeData.noEmpty( ...
                obj.config.seqslam.matching.method_window.u, 1.11);
            obj.hMatchCriThresholdValue.String = SafeData.noEmpty( ...
                obj.config.seqslam.matching.method_thresh.threshold, 2.5);

            obj.hMscDiffLoad.Value = SafeData.noEmpty( ...
                obj.config.seqslam.diff_matrix.load, 0);
            obj.hMscDiffEnhValue.String = SafeData.noEmpty( ...
                obj.config.seqslam.diff_matrix.contrast.r_window, 10);
            obj.hMscVisPercValue.String = SafeData.noEmpty( ...
                obj.config.visual.progress.percent_freq, 1);
            obj.hMscVisPreproValue.String = SafeData.noEmpty( ...
                obj.config.visual.progress.preprocess_freq, 5);
            obj.hMscVisDiffValue.String = SafeData.noEmpty( ...
                obj.config.visual.progress.diff_matrix_freq, 5);
            obj.hMscVisContrValue.String = SafeData.noEmpty( ...
                obj.config.visual.progress.enhance_freq, 5);
            obj.hMscVisMatchValue.String = SafeData.noEmpty( ...
                obj.config.visual.progress.match_freq, 5);
        end

        function sizeGUI(obj)
            % Get some reference dimensions (max width of headings, and
            % default height of a button
            widthUnit = obj.hImPrLoad.Extent(3);
            heightUnit = obj.hDone.Extent(4);

            % Size and position of the figure
            obj.hFig.Position = [0, 0, ...
                widthUnit * ConfigSeqSLAMGUI.FIG_WIDTH_FACTOR, ...
                heightUnit * ConfigSeqSLAMGUI.FIG_HEIGHT_FACTOR];
            movegui(obj.hFig, 'center');

            % Now that the figure (space for placing UI elements is set),
            % size all of the elements
            SpecSize.size(obj.hScreen, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.66);

            SpecSize.size(obj.hImPrLoad, SpecSize.WIDTH, SpecSize.WRAP, ...
                GUISettings.PAD_LARGE);
            SpecSize.size(obj.hImPrRef, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.33, GUISettings.PAD_MED);
            SpecSize.size(obj.hImPrRefSample, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hImPrRef);
            SpecSize.size(obj.hImPrRefAxCrop, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hImPrRef);
            SpecSize.size(obj.hImPrRefAxCrop, SpecSize.HEIGHT, ...
                SpecSize.RATIO, 2/3);
            SpecSize.size(obj.hImPrRefAxResize, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hImPrRef);
            SpecSize.size(obj.hImPrRefAxResize, SpecSize.HEIGHT, ...
                SpecSize.RATIO, 2/3);
            SpecSize.size(obj.hImPrRefAxNorm, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hImPrRef);
            SpecSize.size(obj.hImPrRefAxNorm, SpecSize.HEIGHT, ...
                SpecSize.RATIO, 2/3);
            SpecSize.size(obj.hImPrQuery, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.33, GUISettings.PAD_MED);
            SpecSize.size(obj.hImPrQuerySample, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hImPrQuery);
            SpecSize.size(obj.hImPrQueryAxCrop, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hImPrQuery);
            SpecSize.size(obj.hImPrQueryAxCrop, SpecSize.HEIGHT, ...
                SpecSize.RATIO, 2/3);
            SpecSize.size(obj.hImPrQueryAxResize, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hImPrQuery);
            SpecSize.size(obj.hImPrQueryAxResize, SpecSize.HEIGHT, ...
                SpecSize.RATIO, 2/3);
            SpecSize.size(obj.hImPrQueryAxNorm, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hImPrQuery);
            SpecSize.size(obj.hImPrQueryAxNorm, SpecSize.HEIGHT, ...
                SpecSize.RATIO, 2/3);
            SpecSize.size(obj.hImPrRefresh, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.33, GUISettings.PAD_MED);
            SpecSize.size(obj.hImPrCropRef, SpecSize.WIDTH, SpecSize.MATCH, ...
                obj.hImPrRefresh);
            SpecSize.size(obj.hImPrCropRefValue, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hImPrRefresh);
            SpecSize.size(obj.hImPrCropQuery, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hImPrRefresh);
            SpecSize.size(obj.hImPrCropQueryValue, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hImPrRefresh);
            SpecSize.size(obj.hImPrResize, SpecSize.WIDTH, SpecSize.MATCH, ...
                obj.hImPrRefresh);
            SpecSize.size(obj.hImPrResizeW, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hImPrRefresh, 0.4);
            SpecSize.size(obj.hImPrResizeX, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hImPrRefresh, 0.2, GUISettings.PAD_MED);
            SpecSize.size(obj.hImPrResizeH, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hImPrRefresh, 0.4);
            SpecSize.size(obj.hImPrResizeMethod, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hImPrRefresh);
            SpecSize.size(obj.hImPrResizeMethodValue, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hImPrRefresh);
            SpecSize.size(obj.hImPrNorm, SpecSize.WIDTH, SpecSize.MATCH, ...
                obj.hImPrRefresh);
            SpecSize.size(obj.hImPrNormThresh, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hImPrRefresh, 0.4);
            SpecSize.size(obj.hImPrNormThreshValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hImPrRefresh, 0.3);
            SpecSize.size(obj.hImPrNormStrength, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hImPrRefresh, 0.4);
            SpecSize.size(obj.hImPrNormStrengthValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hImPrRefresh, 0.3);

            SpecSize.size(obj.hMatchLoad, SpecSize.WIDTH, SpecSize.WRAP, ...
                GUISettings.PAD_LARGE);
            SpecSize.size(obj.hMatchTrajTitle, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hFig);
            SpecSize.size(obj.hMatchTrajAx, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.5, 4*GUISettings.PAD_LARGE);
            SpecSize.size(obj.hMatchTrajAx, SpecSize.HEIGHT, ...
                SpecSize.RATIO, 1);
            SpecSize.size(obj.hMatchTrajLength, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.25);
            SpecSize.size(obj.hMatchTrajLengthValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.2);
            SpecSize.size(obj.hMatchTrajVmin, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.25);
            SpecSize.size(obj.hMatchTrajVminValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.2);
            SpecSize.size(obj.hMatchTrajVmax, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.25);
            SpecSize.size(obj.hMatchTrajVmaxValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.2);
            SpecSize.size(obj.hMatchTrajVstep, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.25);
            SpecSize.size(obj.hMatchTrajVstepValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.2);
            SpecSize.size(obj.hMatchCriTitle, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hFig);
            SpecSize.size(obj.hMatchCriAx, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.5, 4*GUISettings.PAD_LARGE);
            SpecSize.size(obj.hMatchCriAx, SpecSize.HEIGHT, SpecSize.RATIO, ...
                0.5);
            SpecSize.size(obj.hMatchCriMethod, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.25);
            SpecSize.size(obj.hMatchCriMethodValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.2);
            SpecSize.size(obj.hMatchCriWindow, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.25);
            SpecSize.size(obj.hMatchCriWindowValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.2);
            SpecSize.size(obj.hMatchCriU, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.25);
            SpecSize.size(obj.hMatchCriUValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.2);
            SpecSize.size(obj.hMatchCriThreshold, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.25);
            SpecSize.size(obj.hMatchCriThresholdValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.2);

            SpecSize.size(obj.hMscDiff, SpecSize.WIDTH, SpecSize.MATCH, ...
                obj.hFig, GUISettings.PAD_MED);
            SpecSize.size(obj.hMscDiff, SpecSize.HEIGHT, SpecSize.PERCENT, ...
                obj.hFig, 0.1);
            SpecSize.size(obj.hMscDiffLoad, SpecSize.WIDTH, SpecSize.WRAP, ...
                GUISettings.PAD_LARGE);
            SpecSize.size(obj.hMscDiffEnh, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hMscDiff, 0.35, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hMscDiffEnhValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hMscDiff, 0.1, GUISettings.PAD_MED);

            SpecSize.size(obj.hMscVis, SpecSize.WIDTH, SpecSize.MATCH, ...
                obj.hFig, GUISettings.PAD_MED);
            SpecSize.size(obj.hMscVis, SpecSize.HEIGHT, SpecSize.PERCENT, ...
                obj.hFig, 0.225);
            SpecSize.size(obj.hMscVisWarn, SpecSize.WIDTH, SpecSize.MATCH, ...
                obj.hMscVis, GUISettings.PAD_LARGE);
            SpecSize.size(obj.hMscVisPerc, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hMscVis, 0.35, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hMscVisPercValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hMscVis, 0.1, GUISettings.PAD_MED);
            SpecSize.size(obj.hMscVisPrepro, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hMscVis, 0.35, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hMscVisPreproValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hMscVis, 0.1, GUISettings.PAD_MED);
            SpecSize.size(obj.hMscVisDiff, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hMscVis, 0.35, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hMscVisDiffValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hMscVis, 0.1, GUISettings.PAD_MED);
            SpecSize.size(obj.hMscVisContr, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hMscVis, 0.35, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hMscVisContrValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hMscVis, 0.1, GUISettings.PAD_MED);
            SpecSize.size(obj.hMscVisMatch, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hMscVis, 0.35, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hMscVisMatchValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hMscVis, 0.1, GUISettings.PAD_MED);

            SpecSize.size(obj.hDone, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.2);

            % Then, systematically place
            SpecPosition.positionIn(obj.hFig, obj.hFig, ...
                SpecPosition.TOP, GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hFig, obj.hFig, ...
                SpecPosition.CENTER_X);

            SpecPosition.positionIn(obj.hScreen, obj.hFig, ...
                SpecPosition.TOP, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hScreen, obj.hFig, ...
                SpecPosition.CENTER_X);

            SpecPosition.positionRelative(obj.hImPrLoad, obj.hScreen, ...
                SpecPosition.BELOW, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hImPrLoad, obj.hFig, ...
                SpecPosition.RIGHT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hImPrRef, obj.hImPrLoad, ...
                SpecPosition.BELOW);
            SpecPosition.positionIn(obj.hImPrRef, obj.hFig, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hImPrRefSample, obj.hImPrRef, ...
                SpecPosition.BELOW);
            SpecPosition.positionRelative(obj.hImPrRefSample, obj.hImPrRef, ...
                SpecPosition.LEFT);
            SpecPosition.positionRelative(obj.hImPrRefAxCrop, ...
                obj.hImPrRefSample, SpecPosition.BELOW, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hImPrRefAxCrop, obj.hImPrRef, ...
                SpecPosition.LEFT);
            SpecPosition.positionRelative(obj.hImPrRefAxResize, ...
                obj.hImPrRefAxCrop, SpecPosition.BELOW, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hImPrRefAxResize, ...
                obj.hImPrRef, SpecPosition.LEFT);
            SpecPosition.positionRelative(obj.hImPrRefAxNorm, ...
                obj.hImPrRefAxResize, SpecPosition.BELOW, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hImPrRefAxNorm, obj.hImPrRef, ...
                SpecPosition.LEFT);
            SpecPosition.positionRelative(obj.hImPrQuery, obj.hImPrRef, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionIn(obj.hImPrQuery, obj.hFig, ...
                SpecPosition.CENTER_X);
            SpecPosition.positionRelative(obj.hImPrQuerySample, ...
                obj.hImPrQuery, SpecPosition.BELOW);
            SpecPosition.positionRelative(obj.hImPrQuerySample, ...
                obj.hImPrQuery, SpecPosition.LEFT);
            SpecPosition.positionRelative(obj.hImPrQueryAxCrop, ...
                obj.hImPrQuerySample, SpecPosition.BELOW, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hImPrQueryAxCrop, ...
                obj.hImPrQuery, SpecPosition.LEFT);
            SpecPosition.positionRelative(obj.hImPrQueryAxResize, ...
                obj.hImPrQueryAxCrop, SpecPosition.BELOW, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hImPrQueryAxResize, ...
                obj.hImPrQuery, SpecPosition.LEFT);
            SpecPosition.positionRelative(obj.hImPrQueryAxNorm, ...
                obj.hImPrQueryAxResize, SpecPosition.BELOW, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hImPrQueryAxNorm, ...
                obj.hImPrQuery, SpecPosition.LEFT);
            SpecPosition.positionRelative(obj.hImPrRefresh, ...
                obj.hImPrRefSample, SpecPosition.CENTER_Y);
            SpecPosition.positionIn(obj.hImPrRefresh, obj.hFig, ...
                SpecPosition.RIGHT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hImPrCropRef, ...
                obj.hImPrRefAxCrop, SpecPosition.TOP, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hImPrCropRef, ...
                obj.hImPrRefresh, SpecPosition.LEFT);
            SpecPosition.positionRelative(obj.hImPrCropRefValue, ...
                obj.hImPrCropRef, SpecPosition.BELOW, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hImPrCropRefValue, ...
                obj.hImPrRefresh, SpecPosition.LEFT);
            SpecPosition.positionRelative(obj.hImPrCropQuery, ...
                obj.hImPrCropRefValue, SpecPosition.BELOW, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hImPrCropQuery, ...
                obj.hImPrRefresh, SpecPosition.LEFT);
            SpecPosition.positionRelative(obj.hImPrCropQueryValue, ...
                obj.hImPrCropQuery, SpecPosition.BELOW, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hImPrCropQueryValue, ...
                obj.hImPrRefresh, SpecPosition.LEFT);
            SpecPosition.positionRelative(obj.hImPrResize, ...
                obj.hImPrRefAxResize, SpecPosition.TOP, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hImPrResize, obj.hImPrRefresh, ...
                SpecPosition.LEFT);
            SpecPosition.positionRelative(obj.hImPrResizeW, obj.hImPrResize, ...
                SpecPosition.BELOW, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hImPrResizeW, ...
                obj.hImPrRefresh, SpecPosition.LEFT);
            SpecPosition.positionRelative(obj.hImPrResizeX, ...
                obj.hImPrResizeW, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hImPrResizeX, ...
                obj.hImPrResizeW, SpecPosition.RIGHT_OF, GUISettings.PAD_SMALL);
            SpecPosition.positionRelative(obj.hImPrResizeH, ...
                obj.hImPrResizeW, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hImPrResizeH, ...
                obj.hImPrResizeX, SpecPosition.RIGHT_OF, GUISettings.PAD_SMALL);
            SpecPosition.positionRelative(obj.hImPrResizeMethod, ...
                obj.hImPrResizeW, SpecPosition.BELOW, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hImPrResizeMethod, ...
                obj.hImPrRefresh, SpecPosition.LEFT);
            SpecPosition.positionRelative(obj.hImPrResizeMethodValue, ...
                obj.hImPrResizeMethod, SpecPosition.BELOW, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hImPrResizeMethodValue, ...
                obj.hImPrRefresh, SpecPosition.LEFT);
            SpecPosition.positionRelative(obj.hImPrNorm, obj.hImPrRefAxNorm, ...
                SpecPosition.TOP, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hImPrNorm, obj.hImPrRefresh, ...
                SpecPosition.LEFT);
            SpecPosition.positionRelative(obj.hImPrNormThresh, ...
                obj.hImPrNorm, SpecPosition.BELOW, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hImPrNormThresh, ...
                obj.hImPrRefresh, SpecPosition.LEFT);
            SpecPosition.positionRelative(obj.hImPrNormThreshValue, ...
                obj.hImPrNormThresh, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hImPrNormThreshValue, ...
                obj.hImPrNormThresh, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hImPrNormStrength, ...
                obj.hImPrNormThresh, SpecPosition.BELOW, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hImPrNormStrength, ...
                obj.hImPrRefresh, SpecPosition.LEFT);
            SpecPosition.positionRelative(obj.hImPrNormStrengthValue, ...
                obj.hImPrNormStrength, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hImPrNormStrengthValue, ...
                obj.hImPrNormStrength, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_MED);

            SpecPosition.positionRelative(obj.hMatchLoad, obj.hScreen, ...
                SpecPosition.BELOW, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hMatchLoad, obj.hFig, ...
                SpecPosition.RIGHT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMatchTrajTitle, ...
                obj.hMatchLoad, SpecPosition.BELOW);
            SpecPosition.positionIn(obj.hMatchTrajTitle, obj.hFig, ...
                SpecPosition.CENTER_X);
            SpecPosition.positionRelative(obj.hMatchTrajAx, ...
                obj.hMatchTrajTitle, SpecPosition.BELOW, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hMatchTrajAx, obj.hFig, ...
                SpecPosition.LEFT, 3*GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hMatchTrajLengthValue, ...
                obj.hMatchTrajTitle, SpecPosition.BELOW, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hMatchTrajLengthValue, obj.hFig, ...
                SpecPosition.RIGHT, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hMatchTrajLength, ...
                obj.hMatchTrajLengthValue, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMatchTrajLength, ...
                obj.hMatchTrajLengthValue, SpecPosition.LEFT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMatchTrajVminValue, ...
                obj.hMatchTrajLengthValue, SpecPosition.BELOW, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMatchTrajVminValue, ...
                obj.hMatchTrajLengthValue, SpecPosition.CENTER_X);
            SpecPosition.positionRelative(obj.hMatchTrajVmin, ...
                obj.hMatchTrajVminValue, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMatchTrajVmin, ...
                obj.hMatchTrajVminValue, SpecPosition.LEFT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMatchTrajVmaxValue, ...
                obj.hMatchTrajVminValue, SpecPosition.BELOW, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMatchTrajVmaxValue, ...
                obj.hMatchTrajVminValue, SpecPosition.CENTER_X);
            SpecPosition.positionRelative(obj.hMatchTrajVmax, ...
                obj.hMatchTrajVmaxValue, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMatchTrajVmax, ...
                obj.hMatchTrajVmaxValue, SpecPosition.LEFT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMatchTrajVstepValue, ...
                obj.hMatchTrajVmaxValue, SpecPosition.BELOW, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMatchTrajVstepValue, ...
                obj.hMatchTrajVmaxValue, SpecPosition.CENTER_X);
            SpecPosition.positionRelative(obj.hMatchTrajVstep, ...
                obj.hMatchTrajVstepValue, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMatchTrajVstep, ...
                obj.hMatchTrajVstepValue, SpecPosition.LEFT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMatchCriTitle, ...
                obj.hMatchTrajAx, SpecPosition.BELOW, 3*GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hMatchCriTitle, obj.hFig, ...
                SpecPosition.CENTER_X);
            SpecPosition.positionRelative(obj.hMatchCriAx, ...
                obj.hMatchCriTitle, SpecPosition.BELOW, ...
                2*GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hMatchCriAx, obj.hFig, ...
                SpecPosition.LEFT, 3*GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hMatchCriMethodValue, ...
                obj.hMatchCriTitle, SpecPosition.BELOW, GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hMatchCriMethodValue, obj.hFig, ...
                SpecPosition.RIGHT, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hMatchCriMethod, ...
                obj.hMatchCriMethodValue, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMatchCriMethod, ...
                obj.hMatchCriMethodValue, SpecPosition.LEFT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMatchCriWindowValue, ...
                obj.hMatchCriMethodValue, SpecPosition.BELOW, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hMatchCriWindowValue, ...
                obj.hMatchCriMethodValue, SpecPosition.CENTER_X);
            SpecPosition.positionRelative(obj.hMatchCriWindow, ...
                obj.hMatchCriWindowValue, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMatchCriWindow, ...
                obj.hMatchCriWindowValue, SpecPosition.LEFT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMatchCriUValue, ...
                obj.hMatchCriWindowValue, SpecPosition.BELOW, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMatchCriUValue, ...
                obj.hMatchCriWindowValue, SpecPosition.CENTER_X);
            SpecPosition.positionRelative(obj.hMatchCriU, ...
                obj.hMatchCriUValue, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMatchCriU, ...
                obj.hMatchCriUValue, SpecPosition.LEFT_OF, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMatchCriThresholdValue, ...
                obj.hMatchCriMethodValue, SpecPosition.BELOW, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hMatchCriThresholdValue, ...
                obj.hMatchCriMethodValue, SpecPosition.CENTER_X);
            SpecPosition.positionRelative(obj.hMatchCriThreshold, ...
                obj.hMatchCriThresholdValue, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMatchCriThreshold, ...
                obj.hMatchCriThresholdValue, SpecPosition.LEFT_OF, ...
                GUISettings.PAD_MED);

            SpecPosition.positionRelative(obj.hMscDiff, obj.hScreen, ...
                SpecPosition.BELOW, 2*GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hMscDiff, obj.hFig, ...
                SpecPosition.CENTER_X);
            SpecPosition.positionIn(obj.hMscDiffLoad, obj.hMscDiff, ...
                SpecPosition.TOP, GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hMscDiffLoad, obj.hMscDiff, ...
                SpecPosition.RIGHT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMscDiffEnh, obj.hMscDiffLoad, ...
                SpecPosition.BELOW, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hMscDiffEnh, obj.hMscDiff, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMscDiffEnhValue, ...
                obj.hMscDiffEnh, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMscDiffEnhValue, ...
                obj.hMscDiffEnh, SpecPosition.RIGHT_OF, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMscVis, obj.hMscDiff, ...
                SpecPosition.BELOW, GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hMscVis, obj.hFig, ...
                SpecPosition.CENTER_X);
            SpecPosition.positionIn(obj.hMscVisWarn, obj.hMscVis, ...
                SpecPosition.TOP, 2*GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hMscVisWarn, obj.hMscVis, ...
                SpecPosition.CENTER_X);
            SpecPosition.positionRelative(obj.hMscVisPerc, obj.hMscVisWarn, ...
                SpecPosition.BELOW, GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hMscVisPerc, obj.hMscVis, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMscVisPercValue, ...
                obj.hMscVisPerc, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMscVisPercValue, ...
                obj.hMscVisPerc, SpecPosition.RIGHT_OF, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMscVisPrepro, ...
                obj.hMscVisPerc, SpecPosition.BELOW, 2*GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hMscVisPrepro, ...
                obj.hMscVisPerc, SpecPosition.CENTER_X);
            SpecPosition.positionRelative(obj.hMscVisPreproValue, ...
                obj.hMscVisPrepro, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMscVisPreproValue, ...
                obj.hMscVisPrepro, SpecPosition.RIGHT_OF, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMscVisDiff, ...
                obj.hMscVisPrepro, SpecPosition.BELOW, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMscVisDiff, ...
                obj.hMscVisPrepro, SpecPosition.CENTER_X);
            SpecPosition.positionRelative(obj.hMscVisDiffValue, ...
                obj.hMscVisDiff, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMscVisDiffValue, ...
                obj.hMscVisDiff, SpecPosition.RIGHT_OF, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMscVisContrValue, ...
                obj.hMscVisPrepro, SpecPosition.CENTER_Y);
            SpecPosition.positionIn(obj.hMscVisContrValue, obj.hMscVis, ...
                SpecPosition.RIGHT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMscVisContr, ...
                obj.hMscVisContrValue, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMscVisContr, ...
                obj.hMscVisContrValue, SpecPosition.LEFT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMscVisMatchValue, ...
                obj.hMscVisContrValue, SpecPosition.BELOW, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMscVisMatchValue, ...
                obj.hMscVisContrValue, SpecPosition.CENTER_X);
            SpecPosition.positionRelative(obj.hMscVisMatch, ...
                obj.hMscVisMatchValue, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMscVisMatch, ...
                obj.hMscVisMatchValue, SpecPosition.LEFT_OF, ...
                GUISettings.PAD_MED);

            SpecPosition.positionIn(obj.hDone, obj.hFig, ...
                SpecPosition.RIGHT, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hDone, obj.hFig, ...
                SpecPosition.BOTTOM, GUISettings.PAD_MED);
        end

        function strip(obj)
            % Strip data from the UI, and store it in the config struct
            obj.config.seqslam.image_processing.load = ...
                logical(obj.hImPrLoad.Value);
            obj.config.seqslam.image_processing.crop.reference = ...
                SafeData.str2vector(obj.hImPrCropRefValue.String);
            obj.config.seqslam.image_processing.crop.query = ...
                SafeData.str2vector(obj.hImPrCropQueryValue.String);
            obj.config.seqslam.image_processing.downsample.width = ...
                str2num(obj.hImPrResizeW.String);
            obj.config.seqslam.image_processing.downsample.height = ...
                str2num(obj.hImPrResizeH.String);
            obj.config.seqslam.image_processing.downsample.method = ...
                obj.hImPrResizeMethodValue.String{ ...
                obj.hImPrResizeMethodValue.Value};
            obj.config.seqslam.image_processing.normalisation.threshold = ...
                str2num(obj.hImPrNormThreshValue.String);
            obj.config.seqslam.image_processing.normalisation.strength = ...
                str2num(obj.hImPrNormStrengthValue.String);

            obj.config.seqslam.matching.load = ...
                logical(obj.hMatchLoad.Value);
            obj.config.seqslam.matching.trajectory.d_s = ...
                str2num(obj.hMatchTrajLengthValue.String);
            obj.config.seqslam.matching.trajectory.v_min = ...
                str2num(obj.hMatchTrajVminValue.String);
            obj.config.seqslam.matching.trajectory.v_max = ...
                str2num(obj.hMatchTrajVmaxValue.String);
            obj.config.seqslam.matching.trajectory.v_step = ...
                str2num(obj.hMatchTrajVstepValue.String);
            if obj.hMatchCriMethodValue.Value == 2
                obj.config.seqslam.matching.method = 'thresh';
            else
                obj.config.seqslam.matching.method = 'window';
            end
            obj.config.seqslam.matching.method_window.r_window = ...
                str2num(obj.hMatchCriWindowValue.String);
            obj.config.seqslam.matching.method_window.u = ...
                str2num(obj.hMatchCriUValue.String);
            obj.config.seqslam.matching.method_thresh.threshold = ...
                str2num(obj.hMatchCriThresholdValue.String);

            obj.config.seqslam.diff_matrix.load = ...
                logical(obj.hMscDiffLoad.Value);
            empty.seqslam.diff_matrix.contrast.r_window = ...
                str2num(obj.hMscDiffEnhValue.String);
            empty.visual.progress.percent_freq = ...
                str2num(obj.hMscVisPercValue.String);
            empty.visual.progress.preprocess_freq = ...
                str2num(obj.hMscVisPreproValue.String);
            empty.visual.progress.diff_matrix_freq = ...
                str2num(obj.hMscVisDiffValue.String);
            empty.visual.progress.enhance_freq = ...
                str2num(obj.hMscVisContrValue.String);
            empty.visual.progress.match_freq = ...
                str2num(obj.hMscVisMatchValue.String);
        end
    end
end
