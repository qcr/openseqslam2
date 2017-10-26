classdef ConfigSeqSLAMGUI < handle
    % TODO on the image preprocessing settings screen selecting the same value
    % should not cause the disabling, but currently does

    properties (Access = private, Constant)
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

        hDone;

        config = emptyConfig();

        indicesRef = [];
        indicesQuery = [];

        listImagesRef = [];
        listImagesQuery = [];

        dimRef = [];
        dimQuery = [];
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

        function cbRefreshPreprocessed(obj, src, event)
            if ~obj.isDataValid(obj.hScreen.Value);
                return;
            end

            obj.drawProcessingPreviews();
        end

        function cbLoadProcessed(obj, src, event)
            if src.Value == 0
                % Turn on all of the visual elements
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
                % Turn off of the visual elements
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

        function clearScreen(obj)
            % Hide all options
            obj.hImPrLoad.Visible = 'off';
            obj.hImPrRef.Visible = 'off';
            obj.hImPrRefSample.Visible = 'off';
            obj.hImPrRefAxCrop.Visible = 'off';
            obj.hImPrRefCropBox.Visible = 'off';
            obj.hImPrRefAxResize.Visible = 'off';
            obj.hImPrRefAxNorm.Visible = 'off';
            obj.hImPrQuery.Visible = 'off';
            obj.hImPrQuerySample.Visible = 'off';
            obj.hImPrQueryAxCrop.Visible = 'off';
            obj.hImPrQueryCropBox.Visible = 'off';
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

            % Clear the axes
            cla(obj.hImPrRefAxCrop);
            cla(obj.hImPrRefAxResize);
            cla(obj.hImPrRefAxNorm);
            cla(obj.hImPrQueryAxCrop);
            cla(obj.hImPrQueryAxResize);
            cla(obj.hImPrQueryAxNorm);
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
            GUISettings.applyFigureStyle(obj.hFig);
            obj.hFig.Name = 'SeqSLAM Settings';
            obj.hFig.Resize = 'off';

            % Create the dropdown list for toggling the setting screens
            obj.hScreen = uicontrol('Style', 'popupmenu');
            obj.hScreen.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hScreen);
            obj.hScreen.String = { 'Image Processing' };

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

            % Done button
            obj.hDone = uicontrol('Style', 'pushbutton');
            GUISettings.applyUIControlStyle(obj.hDone);
            obj.hDone.String = 'Done';

            % Callbacks (must be last, otherwise empty objects passed...)
            obj.hImPrLoad.Callback = {@obj.cbLoadProcessed};
            obj.hImPrRefSample.Callback = {@obj.cbChangePreviewImage};
            obj.hImPrQuerySample.Callback = {@obj.cbChangePreviewImage};
            obj.hImPrRefresh.Callback = {@obj.cbRefreshPreprocessed};
            obj.hImPrResizeW.Callback = {@obj.cbChangeResize};
            obj.hImPrResizeH.Callback = {@obj.cbChangeResize};
            obj.hImPrResizeMethodValue.Callback = {@obj.cbChangeResize};
            obj.hImPrNormThreshValue.Callback = {@obj.cbChangeNorm};
            obj.hImPrNormStrengthValue.Callback = {@obj.cbChangeNorm};
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
                obj.hImPrRefCropBox.Visible = 'on';
                obj.hImPrRefAxResize.Visible = 'on';
                obj.hImPrRefAxNorm.Visible = 'on';
                obj.hImPrQuery.Visible = 'on';
                obj.hImPrQuerySample.Visible = 'on';
                obj.hImPrQueryAxCrop.Visible = 'on';
                obj.hImPrQueryCropBox.Visible = 'on';
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
                % Difference matrix settings
                % TODO
            elseif (screen == 3)
                % Matching settings
                % TODO
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

            SpecSize.size(obj.hDone, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.25);

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
        end
    end
end
