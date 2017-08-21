classdef ConfigSeqSLAMGUI < handle

    properties (Access = private, Constant)
        % Sizing parameters
        FIG_WIDTH_FACTOR = 2.5;     % Times longest internal heading
        FIG_HEIGHT_FACTOR = 35;     % Times height of buttons at font size
    end
    
    properties
        hFig;

        hImPr;
        hImPrLoad;
        hImPrDownSample;
        hImPrDownSampleSize;
        hImPrDownSampleW;
        hImPrDownSamplex;
        hImPrDownSampleH;
        hImPrDownSampleMethod;
        hImPrDownSampleMethodValue;
        hImPrCrop;
        hImPrCropRef;
        hImPrCropRefValue;
        hImPrCropQuery;
        hImPrCropQueryValue;
        hImPrNormalise;
        hImPrNormaliseLength;
        hImPrNormaliseLengthValue;
        hImPrNormaliseMode;
        hImPrNormaliseModeValue;

        hDiff;
        hDiffLoad;
        hDiffConEn;
        hDiffConEnR;
        hDiffConEnRValue;

        hMatch;
        hMatchLoad;
        hMatchDs;
        hMatchDsValue;
        hMatchTraj;
        hMatchTrajVmin;
        hMatchTrajVminValue;
        hMatchTrajVmax;
        hMatchTrajVmaxValue;
        hMatchTrajVstep;
        hMatchTrajVstepValue;
        hMatchRrecent;
        hMatchRrecentValue;
        hMatchCriteria;
        hMatchCriteriaRwindow;
        hMatchCriteriaRwindowValue;
        hMatchCriteriaU;
        hMatchCriteriaUValue;
        
        hDone;

        config = emptyConfig();
    end

    methods
        function obj = ConfigSeqSLAMGUI()
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
        function callbackDone(obj, src, event)
            % Strip the UI data, save it in the config, and close the GUI
            obj.strip();
            close(obj.hFig);
        end

        function createGUI(obj)
            % Create the figure (and hide it)
            obj.hFig = figure('Visible', 'off');
            GUISettings.applyFigureStyle(obj.hFig);
            obj.hFig.Name = 'SeqSLAM Settings';
            obj.hFig.Resize = 'off';

            % Create the image processing panel
            obj.hImPr = uipanel();
            GUISettings.applyUIPanelStyle(obj.hImPr);
            obj.hImPr.Title = 'Image Processing Settings';

            obj.hImPrLoad = uicontrol('Style', 'checkbox');
            obj.hImPrLoad.Parent = obj.hImPr;
            GUISettings.applyUIControlStyle(obj.hImPrLoad);
            obj.hImPrLoad.String = 'Load existing images if available';
            
            obj.hImPrDownSample = uicontrol('Style', 'text');
            obj.hImPrDownSample.Parent = obj.hImPr;
            GUISettings.applyUIControlStyle(obj.hImPrDownSample);
            obj.hImPrDownSample.String = 'Downsampling:';
            obj.hImPrDownSample.HorizontalAlignment = 'left';

            obj.hImPrDownSampleSize = uicontrol('Style', 'text');
            obj.hImPrDownSampleSize.Parent = obj.hImPr;
            GUISettings.applyUIControlStyle(obj.hImPrDownSampleSize);
            obj.hImPrDownSampleSize.String = 'Size:';
            obj.hImPrDownSampleSize.HorizontalAlignment = 'left';

            obj.hImPrDownSampleW = uicontrol('Style', 'edit');
            obj.hImPrDownSampleW.Parent = obj.hImPr;
            GUISettings.applyUIControlStyle(obj.hImPrDownSampleW);
            obj.hImPrDownSampleW.String = '';

            obj.hImPrDownSamplex = uicontrol('Style', 'text');
            obj.hImPrDownSamplex.Parent = obj.hImPr;
            GUISettings.applyUIControlStyle(obj.hImPrDownSamplex);
            obj.hImPrDownSamplex.String = 'x';

            obj.hImPrDownSampleH = uicontrol('Style', 'edit');
            obj.hImPrDownSampleH.Parent = obj.hImPr;
            GUISettings.applyUIControlStyle(obj.hImPrDownSampleH);
            obj.hImPrDownSampleH.String = '';
            
            obj.hImPrDownSampleMethod = uicontrol('Style', 'text');
            obj.hImPrDownSampleMethod.Parent = obj.hImPr;
            GUISettings.applyUIControlStyle(obj.hImPrDownSampleMethod);
            obj.hImPrDownSampleMethod.String = 'Method:';
            obj.hImPrDownSampleMethod.HorizontalAlignment = 'left';

            obj.hImPrDownSampleMethodValue = uicontrol('Style', 'popupmenu');
            obj.hImPrDownSampleMethodValue.Parent = obj.hImPr;
            GUISettings.applyUIControlStyle(obj.hImPrDownSampleMethodValue);
            obj.hImPrDownSampleMethodValue.String = {'lanczos3', 'TODO'};

            obj.hImPrCrop = uicontrol('Style', 'text');
            obj.hImPrCrop.Parent = obj.hImPr;
            GUISettings.applyUIControlStyle(obj.hImPrCrop);
            obj.hImPrCrop.String = 'Cropping (x_l, y_t, x_r, y_b):';
            obj.hImPrCrop.HorizontalAlignment = 'left';

            obj.hImPrCropRef = uicontrol('Style', 'text');
            obj.hImPrCropRef.Parent = obj.hImPr;
            GUISettings.applyUIControlStyle(obj.hImPrCropRef);
            obj.hImPrCropRef.String = 'Reference:';
            obj.hImPrCropRef.HorizontalAlignment = 'left';

            obj.hImPrCropRefValue = uicontrol('Style', 'edit');
            obj.hImPrCropRefValue.Parent = obj.hImPr;
            GUISettings.applyUIControlStyle(obj.hImPrCropRefValue);
            obj.hImPrCropRefValue.String = '';

            obj.hImPrCropQuery = uicontrol('Style', 'text');
            obj.hImPrCropQuery.Parent = obj.hImPr;
            GUISettings.applyUIControlStyle(obj.hImPrCropQuery);
            obj.hImPrCropQuery.String = 'Query:';
            obj.hImPrCropQuery.HorizontalAlignment = 'left';

            obj.hImPrCropQueryValue = uicontrol('Style', 'edit');
            obj.hImPrCropQueryValue.Parent = obj.hImPr;
            GUISettings.applyUIControlStyle(obj.hImPrCropQueryValue);
            obj.hImPrCropQueryValue.String = '';

            obj.hImPrNormalise = uicontrol('Style', 'text');
            obj.hImPrNormalise.Parent = obj.hImPr;
            GUISettings.applyUIControlStyle(obj.hImPrNormalise);
            obj.hImPrNormalise.String = 'Patch Normalisation:';
            obj.hImPrNormalise.HorizontalAlignment = 'left';

            obj.hImPrNormaliseLength = uicontrol('Style', 'text');
            obj.hImPrNormaliseLength.Parent = obj.hImPr;
            GUISettings.applyUIControlStyle(obj.hImPrNormaliseLength);
            obj.hImPrNormaliseLength.String = 'Side length:';
            obj.hImPrNormaliseLength.HorizontalAlignment = 'left';

            obj.hImPrNormaliseLengthValue = uicontrol('Style', 'edit');
            obj.hImPrNormaliseLengthValue.Parent = obj.hImPr;
            GUISettings.applyUIControlStyle(obj.hImPrNormaliseLengthValue);
            obj.hImPrNormaliseLengthValue.String = '';

            obj.hImPrNormaliseMode = uicontrol('Style', 'text');
            obj.hImPrNormaliseMode.Parent = obj.hImPr;
            GUISettings.applyUIControlStyle(obj.hImPrNormaliseMode);
            obj.hImPrNormaliseMode.String = 'Mode:';
            obj.hImPrNormaliseMode.HorizontalAlignment = 'left';

            obj.hImPrNormaliseModeValue = uicontrol('Style', 'edit');
            obj.hImPrNormaliseModeValue.Parent = obj.hImPr;
            GUISettings.applyUIControlStyle(obj.hImPrNormaliseModeValue);
            obj.hImPrNormaliseModeValue.String = '';

            obj.hDiff = uipanel();
            GUISettings.applyUIPanelStyle(obj.hDiff);
            obj.hDiff.Title = 'Difference Matrix Settings';

            obj.hDiffLoad = uicontrol('Style', 'checkbox');
            obj.hDiffLoad.Parent = obj.hDiff;
            GUISettings.applyUIControlStyle(obj.hDiffLoad);
            obj.hDiffLoad.String = 'Load difference matrix if available';

            obj.hDiffConEn = uicontrol('Style', 'text');
            obj.hDiffConEn.Parent = obj.hDiff;
            GUISettings.applyUIControlStyle(obj.hDiffConEn);
            obj.hDiffConEn.String = 'Local Contrast Enhancement:';
            obj.hDiffConEn.HorizontalAlignment = 'left';

            obj.hDiffConEnR = uicontrol('Style', 'text');
            obj.hDiffConEnR.Parent = obj.hDiff;
            GUISettings.applyUIControlStyle(obj.hDiffConEnR);
            obj.hDiffConEnR.String = 'Window (R_window)';
            obj.hDiffConEnR.HorizontalAlignment = 'left';

            obj.hDiffConEnRValue = uicontrol('Style', 'edit');
            obj.hDiffConEnRValue.Parent = obj.hDiff;
            GUISettings.applyUIControlStyle(obj.hDiffConEnRValue);
            obj.hDiffConEnRValue.String = '';

            obj.hMatch = uipanel();
            GUISettings.applyUIPanelStyle(obj.hMatch);
            obj.hMatch.Title = 'Matching Settings:';

            obj.hMatchLoad = uicontrol('Style', 'checkbox');
            obj.hMatchLoad.Parent = obj.hMatch;
            GUISettings.applyUIControlStyle(obj.hMatchLoad);
            obj.hMatchLoad.String = 'Load matches if available';

            obj.hMatchDs = uicontrol('Style', 'text');
            obj.hMatchDs.Parent = obj.hMatch;
            GUISettings.applyUIControlStyle(obj.hMatchDs);
            obj.hMatchDs.String = 'Search Length (d_s):';
            obj.hMatchDs.HorizontalAlignment = 'left';

            obj.hMatchDsValue = uicontrol('Style', 'edit');
            obj.hMatchDsValue.Parent = obj.hMatch;
            GUISettings.applyUIControlStyle(obj.hMatchDsValue);
            obj.hMatchDsValue.String = '';

            obj.hMatchTraj = uicontrol('Style', 'text');
            obj.hMatchTraj.Parent = obj.hMatch;
            GUISettings.applyUIControlStyle(obj.hMatchTraj);
            obj.hMatchTraj.String = 'Search trajectories:';
            obj.hMatchTraj.HorizontalAlignment = 'left';

            obj.hMatchTrajVmin = uicontrol('Style', 'text');
            obj.hMatchTrajVmin.Parent = obj.hMatch;
            GUISettings.applyUIControlStyle(obj.hMatchTrajVmin);
            obj.hMatchTrajVmin.String = 'V_min:';
            obj.hMatchTrajVmin.HorizontalAlignment = 'left';

            obj.hMatchTrajVminValue = uicontrol('Style', 'edit');
            obj.hMatchTrajVminValue.Parent = obj.hMatch;
            GUISettings.applyUIControlStyle(obj.hMatchTrajVminValue);
            obj.hMatchTrajVminValue.String = '';

            obj.hMatchTrajVmax = uicontrol('Style', 'text');
            obj.hMatchTrajVmax.Parent = obj.hMatch;
            GUISettings.applyUIControlStyle(obj.hMatchTrajVmax);
            obj.hMatchTrajVmax.String = 'V_max:';
            obj.hMatchTrajVmax.HorizontalAlignment = 'left';

            obj.hMatchTrajVmaxValue = uicontrol('Style', 'edit');
            obj.hMatchTrajVmaxValue.Parent = obj.hMatch;
            GUISettings.applyUIControlStyle(obj.hMatchTrajVmaxValue);
            obj.hMatchTrajVmaxValue.String = '';

            obj.hMatchTrajVstep = uicontrol('Style', 'text');
            obj.hMatchTrajVstep.Parent = obj.hMatch;
            GUISettings.applyUIControlStyle(obj.hMatchTrajVstep);
            obj.hMatchTrajVstep.String = 'V_step:';
            obj.hMatchTrajVstep.HorizontalAlignment = 'left';

            obj.hMatchTrajVstepValue = uicontrol('Style', 'edit');
            obj.hMatchTrajVstepValue.Parent = obj.hMatch;
            GUISettings.applyUIControlStyle(obj.hMatchTrajVstepValue);
            obj.hMatchTrajVstepValue.String = '';

            obj.hMatchRrecent = uicontrol('Style', 'text');
            obj.hMatchRrecent.Parent = obj.hMatch;
            GUISettings.applyUIControlStyle(obj.hMatchRrecent);
            obj.hMatchRrecent.String = 'Excluded recents (R_recent):';
            obj.hMatchRrecent.HorizontalAlignment = 'left';

            obj.hMatchRrecentValue = uicontrol('Style', 'edit');
            obj.hMatchRrecentValue.Parent = obj.hMatch;
            GUISettings.applyUIControlStyle(obj.hMatchRrecentValue);
            obj.hMatchRrecentValue.String = '';

            obj.hMatchCriteria = uicontrol('Style', 'text');
            obj.hMatchCriteria.Parent = obj.hMatch;
            GUISettings.applyUIControlStyle(obj.hMatchCriteria);
            obj.hMatchCriteria.String = 'Matching Criteria:';
            obj.hMatchCriteria.HorizontalAlignment = 'left';

            obj.hMatchCriteriaRwindow = uicontrol('Style', 'text');
            obj.hMatchCriteriaRwindow.Parent = obj.hMatch;
            GUISettings.applyUIControlStyle(obj.hMatchCriteriaRwindow);
            obj.hMatchCriteriaRwindow.String = 'Sliding window (R_window):';
            obj.hMatchCriteriaRwindow.HorizontalAlignment = 'left';

            obj.hMatchCriteriaRwindowValue = uicontrol('Style', 'edit');
            obj.hMatchCriteriaRwindowValue.Parent = obj.hMatch;
            GUISettings.applyUIControlStyle(obj.hMatchCriteriaRwindowValue);
            obj.hMatchCriteriaRwindowValue.String = '';

            obj.hMatchCriteriaU = uicontrol('Style', 'text');
            obj.hMatchCriteriaU.Parent = obj.hMatch;
            GUISettings.applyUIControlStyle(obj.hMatchCriteriaU);
            obj.hMatchCriteriaU.String = 'Selection factor (u):';
            obj.hMatchCriteriaU.HorizontalAlignment = 'left';

            obj.hMatchCriteriaUValue = uicontrol('Style', 'edit');
            obj.hMatchCriteriaUValue.Parent = obj.hMatch;
            GUISettings.applyUIControlStyle(obj.hMatchCriteriaUValue);
            obj.hMatchCriteriaUValue.String = '';

            % Done button
            obj.hDone = uicontrol('Style', 'pushbutton');
            GUISettings.applyUIControlStyle(obj.hDone);
            obj.hDone.String = 'Done';

            % Callbacks (must be last, otherwise empty objects passed...)
            obj.hDone.Callback = {@obj.callbackDone};
        end

        function populate(obj)
            % Dump all data from the config struct to the UI
            obj.hImPrLoad.Value = SafeData.noEmpty( ...
                obj.config.seqslam.image_processing.load, 0);

            obj.hImPrDownSampleW.String = num2str( ...
                obj.config.seqslam.image_processing.downsample.width);
            obj.hImPrDownSampleH.String = num2str( ...
                obj.config.seqslam.image_processing.downsample.height);
            obj.hImPrDownSampleMethodValue.Value = SafeData.noEmpty( ...
                find(strcmp(obj.hImPrDownSampleMethodValue.String, ...
                    obj.config.seqslam.image_processing.downsample.method)), 1);

            obj.hImPrCropRefValue.String = SafeData.vector2str( ...
                obj.config.seqslam.image_processing.crop.reference);
            obj.hImPrCropQueryValue.String = SafeData.vector2str( ...
                obj.config.seqslam.image_processing.crop.query);

            obj.hImPrNormaliseLengthValue.String = num2str( ...
                obj.config.seqslam.image_processing.normalisation.length);
            obj.hImPrNormaliseModeValue.String = num2str( ...
                obj.config.seqslam.image_processing.normalisation.mode);

            obj.hDiffLoad.Value = SafeData.noEmpty( ...
                obj.config.seqslam.diff_matrix.load, 0);

            obj.hDiffConEnRValue.String = num2str( ...
                obj.config.seqslam.diff_matrix.contrast.r_window);
            
            obj.hMatchLoad.Value = SafeData.noEmpty( ...
                obj.config.seqslam.matching.load, 0);
            obj.hMatchDsValue.String = num2str( ...
                obj.config.seqslam.matching.d_s);

            obj.hMatchTrajVminValue.String = num2str( ...
                obj.config.seqslam.matching.trajectories.v_min);
            obj.hMatchTrajVmaxValue.String = num2str( ...
                obj.config.seqslam.matching.trajectories.v_max);
            obj.hMatchTrajVstepValue.String = num2str( ...
                obj.config.seqslam.matching.trajectories.v_step);

            obj.hMatchRrecentValue.String = num2str( ...
                obj.config.seqslam.matching.r_recent);

            obj.hMatchCriteriaRwindowValue.String = num2str( ...
                obj.config.seqslam.matching.criteria.r_window);
            obj.hMatchCriteriaUValue.String = num2str( ...
                obj.config.seqslam.matching.criteria.u);
        end

        function sizeGUI(obj)
            % Get some reference dimensions (max width of headings, and
            % default height of a button
            maxWidth = max(...
                [obj.hImPrLoad.Extent(3), ...
                obj.hDiffLoad.Extent(3), ...
                obj.hMatchLoad.Extent(3)]);
            heightUnit = obj.hDone.Extent(4);

            % Size and position of the figure
            obj.hFig.Position = [0, 0, ...
                maxWidth * ConfigSeqSLAMGUI.FIG_WIDTH_FACTOR, ...
                heightUnit * ConfigSeqSLAMGUI.FIG_HEIGHT_FACTOR];
            movegui(obj.hFig, 'center');

            % Now that the figure (space for placing UI elements is set),
            % size all of the elements
            SpecSize.size(obj.hImPr, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hFig, GUISettings.PAD_MED);
            SpecSize.size(obj.hImPr, SpecSize.HEIGHT, ...
                SpecSize.ABSOLUTE, 12*heightUnit);
            SpecSize.size(obj.hImPrLoad, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_MED);
            SpecSize.size(obj.hImPrDownSample, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hImPrDownSampleSize, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hImPrDownSamplex, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hImPrDownSampleMethod, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hImPrCrop, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hImPrCropRef, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hImPrCropQuery, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hImPrNormalise, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hImPrNormaliseLength, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hImPrNormaliseMode, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            
            SpecSize.size(obj.hDiff, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hFig, GUISettings.PAD_MED);
            SpecSize.size(obj.hDiff, SpecSize.HEIGHT, ...
                SpecSize.ABSOLUTE, 6*heightUnit);
            SpecSize.size(obj.hDiffLoad, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_MED);
            SpecSize.size(obj.hDiffConEn, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hDiffConEnR, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);

            SpecSize.size(obj.hMatch, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hFig, GUISettings.PAD_MED);
            SpecSize.size(obj.hMatch, SpecSize.HEIGHT, ...
                SpecSize.ABSOLUTE, 12*heightUnit);
            SpecSize.size(obj.hMatchLoad, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_MED);
            SpecSize.size(obj.hMatchDs, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hMatchTraj, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hMatchTrajVmin, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hMatchTrajVmax, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hMatchTrajVstep, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hMatchRrecent, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hMatchCriteria, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hMatchCriteriaRwindow, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hMatchCriteriaU, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);

            SpecSize.size(obj.hDone, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.25);

            % Then, systematically place
            SpecPosition.positionIn(obj.hImPr, obj.hFig, ...
                SpecPosition.CENTER_X);
            SpecPosition.positionIn(obj.hImPr, obj.hFig, ...
                SpecPosition.TOP, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hImPrLoad, obj.hImPr, ...
                SpecPosition.TOP, heightUnit);
            SpecPosition.positionIn(obj.hImPrLoad, obj.hImPr, ...
                SpecPosition.RIGHT, GUISettings.PAD_SMALL);
            SpecPosition.positionRelative(obj.hImPrDownSample, ...
                obj.hImPrLoad, SpecPosition.BELOW, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hImPrDownSample, obj.hImPr, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hImPrDownSampleSize, ...
                obj.hImPrDownSample, SpecPosition.BELOW, ...
                GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hImPrDownSampleSize, obj.hImPr, ...
                SpecPosition.LEFT, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hImPrDownSampleW, ...
                obj.hImPrDownSampleSize, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hImPrDownSampleW, ...
                obj.hImPrDownSampleSize, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hImPrDownSamplex, ...
                obj.hImPrDownSampleSize, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hImPrDownSamplex, ...
                obj.hImPrDownSampleW, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_SMALL);
            SpecPosition.positionRelative(obj.hImPrDownSampleH, ...
                obj.hImPrDownSampleSize, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hImPrDownSampleH, ...
                obj.hImPrDownSamplex, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_SMALL);
            SpecPosition.positionRelative(obj.hImPrDownSampleMethod, ...
                obj.hImPrDownSampleSize, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hImPrDownSampleMethod, ...
                obj.hImPrDownSampleH, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hImPrDownSampleMethodValue, ...
                obj.hImPrDownSampleSize, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hImPrDownSampleMethodValue, ...
                obj.hImPrDownSampleMethod, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hImPrCrop, ...
                obj.hImPrDownSampleSize, SpecPosition.BELOW, ...
                GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hImPrCrop, obj.hImPr, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hImPrCropRef, ...
                obj.hImPrCrop, SpecPosition.BELOW, ...
                GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hImPrCropRef, obj.hImPr, ...
                SpecPosition.LEFT, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hImPrCropRefValue, ...
                obj.hImPrCropRef, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hImPrCropRefValue, ...
                obj.hImPrCropRef, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hImPrCropQuery, ...
                obj.hImPrCropRef, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hImPrCropQuery, ...
                obj.hImPrCropRefValue, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hImPrCropQueryValue, ...
                obj.hImPrCropRef, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hImPrCropQueryValue, ...
                obj.hImPrCropQuery, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hImPrNormalise, ...
                obj.hImPrCropRef, SpecPosition.BELOW, ...
                GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hImPrNormalise, obj.hImPr, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hImPrNormaliseLength, ...
                obj.hImPrNormalise, SpecPosition.BELOW, ...
                GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hImPrNormaliseLength, obj.hImPr, ...
                SpecPosition.LEFT, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hImPrNormaliseLengthValue, ...
                obj.hImPrNormaliseLength, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hImPrNormaliseLengthValue, ...
                obj.hImPrNormaliseLength, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hImPrNormaliseMode, ...
                obj.hImPrNormaliseLength, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hImPrNormaliseMode, ...
                obj.hImPrNormaliseLengthValue, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hImPrNormaliseModeValue, ...
                obj.hImPrNormaliseLength, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hImPrNormaliseModeValue, ...
                obj.hImPrNormaliseMode, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_MED);

            SpecPosition.positionIn(obj.hDiff, obj.hFig, ...
                SpecPosition.CENTER_X);
            SpecPosition.positionRelative(obj.hDiff, obj.hImPr, ...
                SpecPosition.BELOW, GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hDiffLoad, obj.hDiff, ...
                SpecPosition.TOP, heightUnit);
            SpecPosition.positionIn(obj.hDiffLoad, obj.hDiff, ...
                SpecPosition.RIGHT, GUISettings.PAD_SMALL);
            SpecPosition.positionRelative(obj.hDiffConEn, ...
                obj.hDiffLoad, SpecPosition.BELOW, ...
                GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hDiffConEn, obj.hDiff, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hDiffConEnR, ...
                obj.hDiffConEn, SpecPosition.BELOW, ...
                GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hDiffConEnR, obj.hDiff, ...
                SpecPosition.LEFT, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hDiffConEnRValue, ...
                obj.hDiffConEnR, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hDiffConEnRValue, ...
                obj.hDiffConEnR, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_MED);

            SpecPosition.positionIn(obj.hMatch, obj.hFig, ...
                SpecPosition.CENTER_X);
            SpecPosition.positionRelative(obj.hMatch, obj.hDiff, ...
                SpecPosition.BELOW, GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hMatchLoad, obj.hMatch, ...
                SpecPosition.TOP, heightUnit);
            SpecPosition.positionIn(obj.hMatchLoad, obj.hMatch, ...
                SpecPosition.RIGHT, GUISettings.PAD_SMALL);
            SpecPosition.positionRelative(obj.hMatchDs, ...
                obj.hMatchLoad, SpecPosition.BELOW, ...
                GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hMatchDs, obj.hMatchLoad, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMatchDsValue, ...
                obj.hMatchDs, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMatchDsValue, ...
                obj.hMatchDs, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMatchTraj, ...
                obj.hMatchDs, SpecPosition.BELOW, ...
                GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hMatchTraj, obj.hMatchDs, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMatchTrajVmin, ...
                obj.hMatchTraj, SpecPosition.BELOW, ...
                GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hMatchTrajVmin, obj.hMatchDs, ...
                SpecPosition.LEFT, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hMatchTrajVminValue, ...
                obj.hMatchTrajVmin, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMatchTrajVminValue, ...
                obj.hMatchTrajVmin, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMatchTrajVmax, ...
                obj.hMatchTrajVminValue, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMatchTrajVmax, ...
                obj.hMatchTrajVminValue, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hMatchTrajVmaxValue, ...
                obj.hMatchTrajVmax, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMatchTrajVmaxValue, ...
                obj.hMatchTrajVmax, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMatchTrajVstep, ...
                obj.hMatchTrajVmaxValue, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMatchTrajVstep, ...
                obj.hMatchTrajVmaxValue, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hMatchTrajVstepValue, ...
                obj.hMatchTrajVstep, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMatchTrajVstepValue, ...
                obj.hMatchTrajVstep, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMatchRrecent, ...
                obj.hMatchTrajVmin, SpecPosition.BELOW, ...
                GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hMatchRrecent, obj.hMatchTrajVstepValue, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMatchRrecentValue, ...
                obj.hMatchRrecent, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMatchRrecentValue, ...
                obj.hMatchRrecent, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMatchCriteria, ...
                obj.hMatchRrecent, SpecPosition.BELOW, ...
                GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hMatchCriteria, obj.hMatchRrecent, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMatchCriteriaRwindow, ...
                obj.hMatchCriteria, SpecPosition.BELOW, ...
                GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hMatchCriteriaRwindow, obj.hMatchRrecent, ...
                SpecPosition.LEFT, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hMatchCriteriaRwindowValue, ...
                obj.hMatchCriteriaRwindow, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMatchCriteriaRwindowValue, ...
                obj.hMatchCriteriaRwindow, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hMatchCriteriaU, ...
                obj.hMatchCriteriaRwindowValue, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMatchCriteriaU, ...
                obj.hMatchCriteriaRwindowValue, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hMatchCriteriaUValue, ...
                obj.hMatchCriteriaU, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hMatchCriteriaUValue, ...
                obj.hMatchCriteriaU, SpecPosition.RIGHT_OF, ...
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

            obj.config.seqslam.image_processing.downsample.width = ...
                str2num(obj.hImPrDownSampleW.String);
            obj.config.seqslam.image_processing.downsample.height = ...
                str2num(obj.hImPrDownSampleH.String);
            obj.config.seqslam.image_processing.downsample.method = ...
                obj.hImPrDownSampleMethodValue.String{...
                    obj.hImPrDownSampleMethodValue.Value};

            obj.config.seqslam.image_processing.crop.reference = ...
                SafeData.str2vector(obj.hImPrCropRefValue.String);
            obj.config.seqslam.image_processing.crop.query = ...
                SafeData.str2vector(obj.hImPrCropQueryValue.String);
            
            obj.config.seqslam.image_processing.normalisation.length = ...
                str2num(obj.hImPrNormaliseLengthValue.String);
            obj.config.seqslam.image_processing.normalisation.length = ...
                str2num(obj.hImPrNormaliseLengthValue.String);
            obj.config.seqslam.image_processing.normalisation.mode = ...
                str2num(obj.hImPrNormaliseModeValue.String);

            obj.config.seqslam.diff_matrix.load = logical(obj.hDiffLoad.Value);

            obj.config.seqslam.diff_matrix.contrast.r_window = ...
                str2num(obj.hDiffConEnRValue.String);
            
            obj.config.seqslam.matching.load = logical(obj.hMatchLoad.Value);

            obj.config.seqslam.matching.d_s = str2num(obj.hMatchDsValue.String);

            obj.config.seqslam.matching.trajectories.v_min = ...
                str2num(obj.hMatchTrajVminValue.String);
            obj.config.seqslam.matching.trajectories.v_max = ...
                str2num(obj.hMatchTrajVmaxValue.String);
            obj.config.seqslam.matching.trajectories.v_step = ...
                str2num(obj.hMatchTrajVstepValue.String);
            
            obj.config.seqslam.matching.r_recent = ...
                str2num(obj.hMatchRrecentValue.String);

            obj.config.seqslam.matching.criteria.r_window = ...
                str2num(obj.hMatchCriteriaRwindowValue.String);
            obj.config.seqslam.matching.criteria.u = ...
                str2num(obj.hMatchCriteriaUValue.String);
        end
    end
end
