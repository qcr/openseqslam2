classdef ConfigGUI < handle
   
    properties(Access = private, Constant)
        % Sizing parameters
        FIG_WIDTH_FACTOR = 5;       % Times largest button on bottom row
        FIG_HEIGHT_FACTOR = 17;     % Times height of buttons at font size
        
    end
    
    properties
        hFig;
        
        hParamsImport;
        hParamsExport;
        
        hRef;
        hRefLocation;
        hRefPicker;
        hRefStatus;
        
        hQuery;
        hQueryLocation;
        hQueryPicker;
        hQueryStatus;
        
        hResults;
        hResultsLocation;
        hResultsPicker;
        hResultsStatus;
        
        hSettingsSeqSLAM;
        hSettingsVisualiser;
        hStart;
    end
    
    methods
        function obj = ConfigGUI()
            % Create the figure (and hide it)
            obj.hFig = figure('Visible', 'off');
            GUISettings.applyFigureStyle(obj.hFig);
            obj.hFig.Name = "SeqSLAM Configuration";

            % Buttons for exporting and importing parameters
            obj.hParamsImport = uicontrol('Style', 'pushbutton');
            GUISettings.applyUIControlStyle(obj.hParamsImport);
            obj.hParamsImport.String = 'Import params';
            obj.hParamsExport = uicontrol('Style', 'pushbutton');
            GUISettings.applyUIControlStyle(obj.hParamsExport);
            obj.hParamsExport.String = 'Export params';
            
            % Reference dataset elements (title, path edit, file select
            % button, selection status)
            obj.hRef = uipanel();
            GUISettings.applyUIPanelStyle(obj.hRef);
            obj.hRef.Title = 'Reference Dataset Location';
            
            obj.hRefLocation = uicontrol('Style', 'edit');
            obj.hRefLocation.Parent = obj.hRef;
            GUISettings.applyUIControlStyle(obj.hRefLocation);
            obj.hRefLocation.String = '';
            
            obj.hRefPicker = uicontrol('Style', 'pushbutton');
            obj.hRefPicker.Parent = obj.hRef;
            GUISettings.applyUIControlStyle(obj.hRefPicker);
            obj.hRefPicker.String = '...';
            
            obj.hRefStatus = uicontrol('Style', 'text');
            obj.hRefStatus.Parent = obj.hRef;
            GUISettings.applyUIControlStyle(obj.hRefStatus);
            obj.hRefStatus.FontAngle = 'italic';
            obj.hRefStatus.HorizontalAlignment = 'right';
            obj.hRefStatus.String = '';
            
            obj.hRefLocation.Callback = {@obj.callbackEvaluateDataset, ...
                obj.hRefStatus};
            obj.hRefPicker.Callback = {@obj.callbackChooseDataset, ...
                obj.hRefLocation, obj.hRefStatus};

            % Query dataset elements (title, path edit, file select
            % button, selection status)
            obj.hQuery = uipanel();
            GUISettings.applyUIPanelStyle(obj.hQuery);
            obj.hQuery.Title = 'Query Dataset Location';
            
            obj.hQueryLocation = uicontrol('Style', 'edit');
            obj.hQueryLocation.Parent = obj.hQuery;
            GUISettings.applyUIControlStyle(obj.hQueryLocation);
            obj.hQueryLocation.String = '';
            
            obj.hQueryPicker = uicontrol('Style', 'pushbutton');
            obj.hQueryPicker.Parent = obj.hQuery;
            GUISettings.applyUIControlStyle(obj.hQueryPicker);
            obj.hQueryPicker.String = '...';
            
            obj.hQueryStatus = uicontrol('Style', 'text');
            obj.hQueryStatus.Parent = obj.hQuery;
            GUISettings.applyUIControlStyle(obj.hQueryStatus);
            obj.hQueryStatus.FontAngle = 'italic';
            obj.hQueryStatus.HorizontalAlignment = 'right';
            obj.hQueryStatus.String = '';
            
            obj.hQueryLocation.Callback = {@obj.callbackEvaluateDataset, ...
                obj.hQueryStatus};
            obj.hQueryPicker.Callback = {@obj.callbackChooseDataset, ...
                obj.hQueryLocation, obj.hQueryStatus};

            % Results elements (title, path edit, file select button, 
            % selection status)
            obj.hResults = uipanel();
            GUISettings.applyUIPanelStyle(obj.hResults);
            obj.hResults.Title = 'Results Save Location';
            
            obj.hResultsLocation = uicontrol('Style', 'edit');
            obj.hResultsLocation.Parent = obj.hResults;
            GUISettings.applyUIControlStyle(obj.hResultsLocation);
            obj.hResultsLocation.String = '';
            
            obj.hResultsPicker = uicontrol('Style', 'pushbutton');
            obj.hResultsPicker.Parent = obj.hResults;
            GUISettings.applyUIControlStyle(obj.hResultsPicker);
            obj.hResultsPicker.String = '...';
            
            obj.hResultsStatus = uicontrol('Style', 'text');
            obj.hResultsStatus.Parent = obj.hResults;
            GUISettings.applyUIControlStyle(obj.hResultsStatus);
            obj.hResultsStatus.FontAngle = 'italic';
            obj.hResultsStatus.HorizontalAlignment = 'right';
            obj.hResultsStatus.String = '';
            
            obj.hResultsLocation.Callback = {@obj.callbackEvaluateResults, ...
                obj.hResultsStatus};
            obj.hResultsPicker.Callback = {@obj.callbackChooseResults, ...
                obj.hResultsLocation, obj.hResultsStatus};

            % SeqSLAM settings button
            obj.hSettingsSeqSLAM = uicontrol('Style', 'pushbutton');
            GUISettings.applyUIControlStyle(obj.hSettingsSeqSLAM);
            obj.hSettingsSeqSLAM.String = 'SeqSLAM Settings';
            
            % Visualiser settings button
            obj.hSettingsVisualiser = uicontrol('Style', 'pushbutton');
            GUISettings.applyUIControlStyle(obj.hSettingsVisualiser);
            obj.hSettingsVisualiser.String = 'Visualiser Settings';
            
            % Start button
            obj.hStart = uicontrol('Style', 'pushbutton');
            GUISettings.applyUIControlStyle(obj.hStart);
            obj.hStart.String = 'Start';
            
            % Perform sizing of the GUI
            obj.sizeGUI();
            
            % Finally, show the figure when we are done configuring
            obj.hFig.Visible = 'on';
        end
    end
    
    methods (Access = private)
        function callbackChooseDataset(obj, src, event, edit, status)
            obj.interactivity(false);

            % Select the format of the dataset
            % TODO Dialog is flakey as hell (menubar sometimes overlays...)
            choice = questdlg(...
                'Is the dataset a collection of images or a video?', ...
                'Dataset Format?', 'Images', 'Video', 'Cancel', 'Cancel');
            
            % Select the dataset
            dataSet = '';
            if (strcmp(choice,'Images'))
                % Choose the directory where the images reside
                dataSet = uigetdir('', ...
                    'Select the directory containing the dataset images');
            elseif (strcmp(choice,'Video'))
                % Choose the video file
                [f, p] = uigetfile( ...
                    VideoReader.getFileFormats().getFilterSpec(), ...
                    'Select a supported video file as the dataset');
                dataSet = fullfile(p, f);
            end

            % Display the dataset selection (and manually trigger evaluation)
            if (ischar(dataSet) || isstr(dataSet)) && exist(dataSet, 'file')
                edit.String = dataSet;
                %edit.Callback{1}(obj, edit, event, status); TODO this version
                obj.callbackEvaluateDataset(edit, event, status);
            end
            
            obj.interactivity(true);
        end

        function callbackChooseResults(obj, src, event, edit, status)
            obj.interactivity(false);

            % Select the results directory
            resultsDir = uigetdir('', ...
                'Select the directory to store / access results');

            % Display the selected directory (and manually trigger evaluation)
            if (ischar(resultsDir) || isstr(resultsDir)) && ...
                    exist(resultsDir, 'file')
                edit.String = resultsDir;
                obj.callbackEvaluateResults(edit, event, status);
            end
            
            obj.interactivity(true);
        end

        function callbackEvaluateDataset(obj, src, event, status)
            obj.interactivity(false); status.Enable = 'on';

            % Perform validation
            status.String = 'Validating...'; 
            status.ForegroundColor = GUISettings.COL_LOADING;
            drawnow();
            [p, n, e] = fileparts(src.String);
            if ~exist(src.String, 'file')
                % Inform that the path does not point to an existing file
                status.String = 'Error: File does not exist!';
                status.ForegroundColor = GUISettings.COL_ERROR;
            elseif isdir(src.String)
                % Take the most prominent image extension in directory
                exts = arrayfun(@(x) x.ext, imformats, 'uni', 0);
                exts = [exts{:}];

                % Process is:
                % 1) Loop over every image extension
                % 2) Get the names of all files matching that extension
                % 3) if number of files is less than pervious max, bail
                % 4) Use regex to extract the number as a token
                % 5) Record min and maxes
                % TODO worry about if numbers not sequential, or matched tokens
                % aren't consistent (i.e. tokens{:}{1}{1})!
                dsPath = fullfile([src.String filesep() filesep()]);
                ext = '';
                tokenStart = '';
                tokenEnd = '';
                imMin = 0; imMax = 0;
                exts = {'png'};
                for k = 1:length(exts)
                    fns = dir([dsPath '*.' exts{k}]);
                    fns = {fns.name};

                    if k > 1 && (length(fns) < imMax - imMin)
                        continue;
                    end

                    tokens = regexp(fns, ['^(.*?)(\d+)(.?\.' exts{k} ')'], ...
                        'tokens');
                    nums = cellfun(@(x) str2num(x{1}{2}), tokens);
                    tempMax = max(nums);
                    tempMin = min(nums);
                    if (tempMax - tempMin) > (imMax - imMin)
                        imMax = tempMax;
                        imMin = tempMin;
                        ext = exts{k};
                        tokenStart = tokens{1}{1}{1};
                        tokenEnd = tokens{1}{1}{3};
                    end
                end

                % Report the results
                if (imMin == 0 && imMax == 0) || isempty(ext)
                    status.String = ['Error: no dataset was found (' ...
                        'a filename patterns wasn''t identified)!'];
                    status.ForegroundColor = GUISettings.COL_ERROR;
                else
                    status.String = ['Success: dataset with filenames ''' ...
                        tokenStart '[' ...
                        num2str(imMin, ...
                            ['%0' num2str(numel(num2str(imMax))) 'd']) ...
                        '-' num2str(imMax) ']' tokenEnd ''' identified!'];
                    status.ForegroundColor = GUISettings.COL_SUCCESS; 
                end
            elseif any(ismember({VideoReader.getFileFormats().Extension}, ...
                    e(2:end)))
                % Attempt to read the video
                v = VideoReader(src.String);
                if v.Duration > 0
                    status.String = ['Success: video read (' ...
                        int2str(v.Duration/60) 'm ' ...
                        num2str(round(mod(v.Duration,60)), '%02d') 's)!'];
                    status.ForegroundColor = GUISettings.COL_SUCCESS;
                else
                    status.String = [ 'Error: an empty video ' ...
                        '(duration of 0 seconds) was read!'];
                    status.ForegroundColor = GUISettings.COL_ERROR;
                end
            else
                % Unsupported video format
                status.String = ['Error: ''*' e ...
                    ''' is an unsupported video format'];
                status.ForegroundColor = GUISettings.COL_ERROR;
            end

            obj.interactivity(true);
        end

        function callbackEvaluateResults(obj, src, event, status)
            obj.interactivity(false); status.Enable = 'on';

            % Perform evaluation
            status.String = 'Validating...';
            status.ForegroundColor = GUISettings.COL_LOADING;
            drawnow();
            obj.interactivity(true);
            if ~exist(src.String, 'file')
                % Inform that the path does not point to an existing directory
                status.String = 'Error: Selected directory does not exist!';
                status.ForegroundColor = GUISettings.COL_ERROR;
            elseif ConfigGUI.containsResults(src.String)
                % Results directory selected with existing results
                status.String = ['Success: selected directory contains ' ...
                    'previous results'];
                status.ForegroundColor = GUISettings.COL_SUCCESS;
            else
                % A new results directory was selected
                status.String = ['Success: selected directory contains ' ...
                    'no existing results'];
                status.ForegroundColor = GUISettings.COL_SUCCESS;
            end

            obj.interactivity(true);
        end

        function interactivity(obj, enable)
            if enable
                status = 'on';
            else
                status = 'off';
            end
            
            obj.hParamsImport.Enable = status;
            obj.hParamsExport.Enable = status;

            obj.hRefLocation.Enable = status;
            obj.hRefPicker.Enable = status;
            obj.hRefStatus.Enable = status;

            obj.hQueryLocation.Enable = status;
            obj.hQueryPicker.Enable = status;
            obj.hQueryStatus.Enable = status;

            obj.hResultsLocation.Enable = status;
            obj.hResultsPicker.Enable = status;
            obj.hResultsStatus.Enable = status;

            obj.hSettingsSeqSLAM.Enable = status;
            obj.hSettingsVisualiser.Enable = status;
            obj.hStart.Enable = status;
        end
        
        function sizeGUI(obj)
            % Get some reference dimensions (max width of 3 buttons, and
            % default height of a button)
            maxWidth = max(...
                [obj.hSettingsSeqSLAM.Extent(3), ...
                obj.hSettingsVisualiser.Extent(3), ... 
                obj.hStart.Extent(3)]);
            heightUnit = obj.hStart.Extent(4);
            
            % Size and position the figure
            obj.hFig.Position = [0, 0, ...
                maxWidth * ConfigGUI.FIG_WIDTH_FACTOR, ...
                heightUnit * ConfigGUI.FIG_HEIGHT_FACTOR];
            movegui(obj.hFig, 'center');
              
            % Now that the figure (space for placing UI elements is set),
            % size all of the elements
            SpecSize.size(obj.hParamsImport, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.25);
            SpecSize.size(obj.hParamsExport, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.25);
            
            SpecSize.size(obj.hRef, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hFig, GUISettings.PAD_MED);
            SpecSize.size(obj.hRef, SpecSize.HEIGHT, ...
                SpecSize.ABSOLUTE, 4*heightUnit);
            SpecSize.size(obj.hRefLocation, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hRef, 0.9, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hRefPicker, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hRef, 0.1, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hRefStatus, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hRef, GUISettings.PAD_MED);
            
            SpecSize.size(obj.hQuery, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hFig, GUISettings.PAD_MED);
            SpecSize.size(obj.hQuery, SpecSize.HEIGHT, ...
                SpecSize.ABSOLUTE, 4*heightUnit);
            SpecSize.size(obj.hQueryLocation, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hQuery, 0.9, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hQueryPicker, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hQuery, 0.1, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hQueryStatus, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hQuery, GUISettings.PAD_MED);
            
            SpecSize.size(obj.hResults, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hFig, GUISettings.PAD_MED);
            SpecSize.size(obj.hResults, SpecSize.HEIGHT, ...
                SpecSize.ABSOLUTE, 4*heightUnit);
            SpecSize.size(obj.hResultsLocation, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hResults, 0.9, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hResultsPicker, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hResults, 0.1, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hResultsStatus, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hResults, GUISettings.PAD_MED);
            
            SpecSize.size(obj.hSettingsSeqSLAM, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.25);
            SpecSize.size(obj.hSettingsVisualiser, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.25);
            SpecSize.size(obj.hStart, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.2);
            
            % Then, systematically place
            SpecPosition.positionIn(obj.hParamsExport, obj.hFig, ...
                SpecPosition.RIGHT, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hParamsExport, obj.hFig, ...
                SpecPosition.TOP, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hParamsImport, ...
                obj.hParamsExport, SpecPosition.LEFT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hParamsImport, ...
                obj.hParamsExport, SpecPosition.CENTER_Y);
            
            SpecPosition.positionIn(obj.hRef, obj.hFig, ...
                SpecPosition.CENTER_X);
            SpecPosition.positionRelative(obj.hRef, obj.hParamsImport, ...
                SpecPosition.BELOW, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hRefLocation, obj.hRef, ...
                SpecPosition.TOP, 1.5*heightUnit);
            SpecPosition.positionIn(obj.hRefLocation, obj.hRef, ...
                SpecPosition.LEFT, GUISettings.PAD_SMALL);
            SpecPosition.positionRelative(obj.hRefPicker, ...
                obj.hRefLocation, SpecPosition.CENTER_Y);
            SpecPosition.positionIn(obj.hRefPicker, obj.hRef, ...
                SpecPosition.RIGHT, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hRefStatus, obj.hRef, ...
                SpecPosition.RIGHT, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hRefStatus, ...
                obj.hRefPicker, SpecPosition.BELOW, 0.5*heightUnit);
            
            SpecPosition.positionIn(obj.hQuery, obj.hFig, ...
                SpecPosition.CENTER_X);
            SpecPosition.positionRelative(obj.hQuery, obj.hRef, ...
                SpecPosition.BELOW, GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hQueryLocation, obj.hQuery, ...
                SpecPosition.TOP, 1.5*heightUnit);
            SpecPosition.positionIn(obj.hQueryLocation, obj.hQuery, ...
                SpecPosition.LEFT, GUISettings.PAD_SMALL);
            SpecPosition.positionRelative(obj.hQueryPicker, ...
                obj.hQueryLocation, SpecPosition.CENTER_Y);
            SpecPosition.positionIn(obj.hQueryPicker, obj.hQuery, ...
                SpecPosition.RIGHT, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hQueryStatus, obj.hQuery, ...
                SpecPosition.RIGHT, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hQueryStatus, ...
                obj.hQueryPicker, SpecPosition.BELOW, 0.5*heightUnit);
            
            SpecPosition.positionIn(obj.hResults, obj.hFig, ...
                SpecPosition.CENTER_X);
            SpecPosition.positionRelative(obj.hResults, obj.hQuery, ...
                SpecPosition.BELOW, GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hResultsLocation, obj.hResults, ...
                SpecPosition.TOP, 1.5*heightUnit);
            SpecPosition.positionIn(obj.hResultsLocation, obj.hResults, ...
                SpecPosition.LEFT, GUISettings.PAD_SMALL);
            SpecPosition.positionRelative(obj.hResultsPicker, ...
                obj.hResultsLocation, SpecPosition.CENTER_Y);
            SpecPosition.positionIn(obj.hResultsPicker, obj.hResults, ...
                SpecPosition.RIGHT, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hResultsStatus, obj.hResults, ...
                SpecPosition.RIGHT, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hResultsStatus, ...
                obj.hResultsPicker, SpecPosition.BELOW, 0.5*heightUnit);
            
            SpecPosition.positionIn(obj.hSettingsSeqSLAM, obj.hFig, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hSettingsSeqSLAM, obj.hFig, ...
                SpecPosition.BOTTOM, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hSettingsVisualiser, ...
                obj.hSettingsSeqSLAM, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hSettingsVisualiser, ...
                obj.hSettingsSeqSLAM, SpecPosition.CENTER_Y);
            SpecPosition.positionIn(obj.hStart, obj.hFig, ...
                SpecPosition.RIGHT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hStart, ...
                obj.hSettingsSeqSLAM, SpecPosition.CENTER_Y);
        end
    end

    methods (Static, Access=private)
        function results = containsResults(directory)
            results = exist(fullfile(directory, 'results.mat'), 'file');
        end
    end
end
