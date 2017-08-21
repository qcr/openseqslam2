classdef ConfigIOGUI < handle
   
    properties (Access = private, Constant)
        % Sizing parameters
        FIG_WIDTH_FACTOR = 5;       % Times largest button on bottom row
        FIG_HEIGHT_FACTOR = 20;     % Times height of buttons at font size
    end
    
    properties
        hFig;
        
        hConfigImport;
        hConfigExport;
        
        hRef;
        hRefLocation;
        hRefPicker;
        hRefStatus;
        hRefSample;
        hRefSampleValue;
        
        hQuery;
        hQueryLocation;
        hQueryPicker;
        hQueryStatus;
        hQuerySample;
        hQuerySampleValue;
        
        hResults;
        hResultsLocation;
        hResultsPicker;
        hResultsStatus;
        
        hSettingsSeqSLAM;
        hSettingsVisualiser;
        hStart;

        config = emptyConfig();
    end
    
    methods
        function obj = ConfigIOGUI()
            % Create and size the GUI
            obj.createGUI();
            obj.sizeGUI();
            
            % Finally, show the figure when we are done configuring
            obj.hFig.Visible = 'on';
        end

        function dumpConfigToXML(obj, filename)
            % Strip the GUI's config, and dump to XML
            obj.strip();
            settings2xml(obj.config, filename);
        end

        function success = loadConfigFromXML(obj, filename)
            % Extract the struct from the file
            s = xml2settings(filename);
            if isempty(s)
                success = false;
                return;
            end

            % Save the struct as the config, and populate the GUI
            obj.config = s;
            obj.populate();
            success = true;
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
                obj.evaluateDataset(edit.String, status);
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
            obj.evaluateDataset(src.String, status);
        end

        function callbackEvaluateResults(obj, src, event, status)
            obj.evaluateResults(src.String, status);
        end

        function callbackImport(obj, src, event)
            % Prompt the user to select and XML file
            [f, p] = uigetfile('*.xml', 'Select an XML configuration file');
            if isnumeric(f) || isnumeric(p)
                uiwait(errordlg( ...
                    ['No file was selected, ' ...
                        'no configuration was loaded'], ...
                    'No file selected'));
                return;
            end
            xmlfile = fullfile(f, p);
            [p, f, e] = fileparts(xmlfile);
            if ~strcmpi(e, '.xml')
                uiwait(errordlg( ...
                    ['No *.xml file was selected, ' ...
                        'no configuration was loaded'], ...
                    'No *.xml file selected'));
                return;
            end

            % Attempt to load the settings
            s = obj.loadConfigFromXML(xmlfile);
            if ~s
                uiwait(errordlg( ...
                    ['Import failed, ' ...
                        'are you sure this is a valid config file?'], ...
                    'Import from *.xml file failed'));
                return;
            end
        end

        function callbackExport(obj, src, event)
            % Prompt user to select where they'd like to export
            [f, p] = uiputfile('*.xml', 'Select export location');
            if isnumeric(f) || isnumeric(p)
                uiwait(errordlg( ...
                    ['No save location was selected, ' ...
                        'configuration was not exported'], ...
                    'No save location selected'));
                return;
            end

            % Save the settings
            obj.dumpConfigToXML(fullfile(p, f));
        end

        function callbackSeqSLAMSettings(obj, src, event)
            obj.interactivity(false);

            % Open the GUI, populate it, and wait for the user to finish
            seqslamgui = ConfigSeqSLAMGUI();
            seqslamgui.updateConfig(obj.config);
            uiwait(seqslamgui.hFig);

            % Save the parameters returned
            obj.config = seqslamgui.config;

            obj.interactivity(true);
        end

        function callbackStart(obj, src, event)
            % Verify that all of the paths are valid
            if ~strncmpi(obj.hRefStatus.String, 'success', 7)
                h = errordlg( ...
                    'Please enter a valid reference dataset location', ...
                    'Invalid reference dataset location', 'modal');
                return;
            end
            if ~strncmpi(obj.hQueryStatus.String, 'success', 7)
                h = errordlg( ...
                    'Please enter a valid query dataset location', ...
                    'Invalid query dataset location', 'modal');
                return;
            end
            if ~strncmpi(obj.hResultsStatus.String, 'success', 7)
                h = errordlg( ...
                    'Please enter a valid location to store results', ...
                    'Invalid results location', 'modal');
                return;
            end

            % Extract all data from the UI, and store it in the object
            % TODO NOT DIRTY HACK TO GET THINGS WORKING!!!
            obj.hackDefaults();
            obj.hackExtras();

            obj.config.dataset(1).name = 'Query';
            obj.config.dataset(1).imagePath = obj.hQueryLocation.String;
            obj.config.dataset(2).name = 'Reference';
            obj.config.dataset(2).imagePath = obj.hRefLocation.String;
            obj.config.savePath = obj.hResultsLocation.String;
            obj.config.dataset(1).savePath = obj.hResultsLocation.String;
            obj.config.dataset(2).savePath = obj.hResultsLocation.String;

            % Get image indices legitimately
            % TODO remove hack
            datasetFN = obj.hQueryLocation.String;
            [p, n, e] = fileparts(datasetFN);
            if isdir(datasetFN)
                dsPath = fullfile([datasetFN filesep() filesep()]);
                fs = dir([datasetFN filesep() '*.png']);
                obj.config.dataset(1).imageIndices = ...
                    1:obj.config.dataset(1).imageSkip:length(fs);
            elseif any(ismember({VideoReader.getFileFormats().Extension}, ...
                    e(2:end)))
                v = VideoReader(datasetFN);
                frames = floor(v.Duration*v.FrameRate);
                obj.config.dataset(1).imageIndices = ...
                    1:obj.config.dataset(1).imageSkip:frames;
                obj.config.DO_RESIZE = 1;
            end
            datasetFN = obj.hRefLocation.String;
            [p, n, e] = fileparts(datasetFN);
            if isdir(datasetFN)
                dsPath = fullfile([datasetFN filesep() filesep()]);
                fs = dir([datasetFN filesep() '*.png']);
                obj.config.dataset(2).imageIndices = ...
                    1:obj.config.dataset(2).imageSkip:length(fs);
            elseif any(ismember({VideoReader.getFileFormats().Extension}, ...
                    e(2:end)))
                v = VideoReader(datasetFN);
                frames = floor(v.Duration*v.FrameRate);
                obj.config.dataset(2).imageIndices = ...
                    1:obj.config.dataset(2).imageSkip:frames;
                obj.config.DO_RESIZE = 1;
            end

            % Close the figure
            close(obj.hFig);
        end
        
        function createGUI(obj)
            % Create the figure (and hide it)
            obj.hFig = figure('Visible', 'off');
            GUISettings.applyFigureStyle(obj.hFig);
            obj.hFig.Name = 'SeqSLAM Configuration';
            obj.hFig.Resize = 'off';

            % Buttons for exporting and importing parameters
            obj.hConfigImport = uicontrol('Style', 'pushbutton');
            GUISettings.applyUIControlStyle(obj.hConfigImport);
            obj.hConfigImport.String = 'Import config';
            obj.hConfigExport = uicontrol('Style', 'pushbutton');
            GUISettings.applyUIControlStyle(obj.hConfigExport);
            obj.hConfigExport.String = 'Export config';
            
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
            
            obj.hRefSample = uicontrol('Style', 'text');
            obj.hRefSample.Parent = obj.hRef;
            GUISettings.applyUIControlStyle(obj.hRefSample);
            obj.hRefSample.String = 'Subsample Factor:';

            obj.hRefSampleValue = uicontrol('Style', 'edit');
            obj.hRefSampleValue.Parent = obj.hRef;
            GUISettings.applyUIControlStyle(obj.hRefSampleValue);
            obj.hRefSampleValue.String = '';

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
            
            obj.hQuerySample = uicontrol('Style', 'text');
            obj.hQuerySample.Parent = obj.hQuery;
            GUISettings.applyUIControlStyle(obj.hQuerySample);
            obj.hQuerySample.String = 'Subsample Factor:';

            obj.hQuerySampleValue = uicontrol('Style', 'edit');
            obj.hQuerySampleValue.Parent = obj.hQuery;
            GUISettings.applyUIControlStyle(obj.hQuerySampleValue);
            obj.hQuerySampleValue.String = '';

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
            
            % Callbacks (must be last, otherwise empty objects passed...)
            obj.hConfigImport.Callback = {@obj.callbackImport};
            obj.hConfigExport.Callback = {@obj.callbackExport};
            obj.hRefLocation.Callback = {@obj.callbackEvaluateDataset, ...
                obj.hRefStatus};
            obj.hRefPicker.Callback = {@obj.callbackChooseDataset, ...
                obj.hRefLocation, obj.hRefStatus};
            obj.hQueryLocation.Callback = {@obj.callbackEvaluateDataset, ...
                obj.hQueryStatus};
            obj.hQueryPicker.Callback = {@obj.callbackChooseDataset, ...
                obj.hQueryLocation, obj.hQueryStatus};
            obj.hResultsLocation.Callback = {@obj.callbackEvaluateResults, ...
                obj.hResultsStatus};
            obj.hResultsPicker.Callback = {@obj.callbackChooseResults, ...
                obj.hResultsLocation, obj.hResultsStatus};
            obj.hSettingsSeqSLAM.Callback = {@obj.callbackSeqSLAMSettings};
            obj.hStart.Callback= {@obj.callbackStart};
        end

        function evaluateDataset(obj, path, status)
            obj.interactivity(false); status.Enable = 'on';

            % Perform validation
            status.String = 'Validating...'; 
            status.ForegroundColor = GUISettings.COL_LOADING;
            drawnow();
            [p, n, e] = fileparts(path);
            if ~exist(path, 'file')
                % Inform that the path does not point to an existing file
                status.String = 'Error: File does not exist!';
                status.ForegroundColor = GUISettings.COL_ERROR;
            elseif isdir(path)
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
                dsPath = fullfile(path);
                ext = '';
                tokenStart = '';
                tokenEnd = '';
                imMin = 0; imMax = 0;
                exts = {'png'};
                for k = 1:length(exts)
                    fns = dir([dsPath filesep() '*.' exts{k}]);
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
                v = VideoReader(path);
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

        function evaluateResults(obj, path, status)
            obj.interactivity(false); status.Enable = 'on';

            % Perform evaluation
            status.String = 'Validating...';
            status.ForegroundColor = GUISettings.COL_LOADING;
            drawnow();
            obj.interactivity(true);
            if ~exist(path, 'file')
                % Inform that the path does not point to an existing directory
                status.String = 'Error: Selected directory does not exist!';
                status.ForegroundColor = GUISettings.COL_ERROR;
            elseif ConfigIOGUI.containsResults(path)
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
        
        function hackExtras(obj)
            % Nordland spring dataset
            ds.name = 'spring';
            ds.imagePath = '../datasets/nordland/64x32-grayscale-1fps/spring';    
            ds.prefix='images-';
            ds.extension='.png';
            ds.suffix='';
            ds.imageSkip = 100;     % use every n-nth image
            ds.imageIndices = 1:ds.imageSkip:35700;    
            ds.savePath = 'results';
            ds.saveFile = sprintf('%s-%d-%d-%d', ds.name, ds.imageIndices(1), ds.imageSkip, ds.imageIndices(end));
            
            ds.preprocessing.save = 1;
            ds.preprocessing.load = 1;
            %ds.crop=[1 1 60 32];  % x0 y0 x1 y1  cropping will be done after resizing!
            ds.crop=[];
            
            spring=ds;


            % nordland winter dataset
            ds.name = 'winter';
            ds.imagePath = '../datasets/nordland/64x32-grayscale-1fps/winter';       
            ds.saveFile = sprintf('%s-%d-%d-%d', ds.name, ds.imageIndices(1), ds.imageSkip, ds.imageIndices(end));
            % ds.crop=[5 1 64 32];
            ds.crop=[];
            
            winter=ds;        

            obj.config.dataset = [spring, winter];

            % load old results or re-calculate?
            obj.config.differencematrix.load = 0;
            obj.config.contrastenhanced.load = 0;
            obj.config.matching.load = 0;
            
            % where to save / load the results
            obj.config.savePath='results';
        end

        function hackDefaults(obj)
            % switches
            obj.config.DO_PREPROCESSING = 1;
            obj.config.DO_RESIZE        = 0;
            obj.config.DO_GRAYLEVEL     = 1;
            obj.config.DO_PATCHNORMALIZATION    = 1;
            obj.config.DO_SAVE_PREPROCESSED_IMG = 0;
            obj.config.DO_DIFF_MATRIX   = 1;
            obj.config.DO_CONTRAST_ENHANCEMENT  = 1;
            obj.config.DO_FIND_MATCHES  = 1;


            % parameters for preprocessing
            obj.config.downsample.size = [32 64];  % height, width
            obj.config.downsample.method = 'lanczos3';
            obj.config.normalization.sideLength = 8;
            obj.config.normalization.mode = 1;
                    
            
            % parameters regarding the matching between images
            obj.config.matching.ds = 10; 
            obj.config.matching.Rrecent=5;
            obj.config.matching.vmin = 0.8;
            obj.config.matching.vskip = 0.1;
            obj.config.matching.vmax = 1.2;  
            obj.config.matching.Rwindow = 10;
            obj.config.matching.save = 1;
            obj.config.matching.load = 1;
            
            % parameters for contrast enhancement on difference matrix  
            obj.config.contrastEnhancement.R = 10;

            % load old results or re-calculate? save results?
            obj.config.differenceMatrix.save = 1;
            obj.config.differenceMatrix.load = 1;
            
            obj.config.contrastEnhanced.save = 1;
            obj.config.contrastEnhanced.load = 1;
            
            % suffix appended on files containing the results
            obj.config.saveSuffix='';
        end

        function interactivity(obj, enable)
            if enable
                status = 'on';
            else
                status = 'off';
            end
            
            obj.hConfigImport.Enable = status;
            obj.hConfigExport.Enable = status;

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
        
        function populate(obj)
            % Dump all data from the config struct into the UI
            obj.hRefLocation.String = obj.config.reference.path;
            obj.hRefSampleValue.String = ...
                num2str(obj.config.reference.subsample_factor);

            obj.hQueryLocation.String = obj.config.query.path;
            obj.hQuerySampleValue.String = ...
                num2str(obj.config.query.subsample_factor);

            obj.hResultsLocation.String = obj.config.results.path;

            % Run any data validation methods after populating
            obj.evaluateDataset(obj.hRefLocation.String, obj.hRefStatus);
            obj.evaluateDataset(obj.hQueryLocation.String, obj.hQueryStatus);
            obj.evaluateResults(obj.hResultsLocation.String, obj.hResultsStatus);
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
                maxWidth * ConfigIOGUI.FIG_WIDTH_FACTOR, ...
                heightUnit * ConfigIOGUI.FIG_HEIGHT_FACTOR];
            movegui(obj.hFig, 'center');
              
            % Now that the figure (space for placing UI elements is set),
            % size all of the elements
            SpecSize.size(obj.hConfigImport, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.25);
            SpecSize.size(obj.hConfigExport, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.25);
            
            SpecSize.size(obj.hRef, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hFig, GUISettings.PAD_MED);
            SpecSize.size(obj.hRef, SpecSize.HEIGHT, ...
                SpecSize.ABSOLUTE, 5.5*heightUnit);
            SpecSize.size(obj.hRefLocation, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hRef, 0.9, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hRefPicker, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hRef, 0.1, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hRefStatus, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hRef, GUISettings.PAD_MED);
            SpecSize.size(obj.hRefSample, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            
            SpecSize.size(obj.hQuery, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hFig, GUISettings.PAD_MED);
            SpecSize.size(obj.hQuery, SpecSize.HEIGHT, ...
                SpecSize.ABSOLUTE, 5.5*heightUnit);
            SpecSize.size(obj.hQueryLocation, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hQuery, 0.9, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hQueryPicker, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hQuery, 0.1, GUISettings.PAD_SMALL);
            SpecSize.size(obj.hQueryStatus, SpecSize.WIDTH, ...
                SpecSize.MATCH, obj.hQuery, GUISettings.PAD_MED);
            SpecSize.size(obj.hQuerySample, SpecSize.WIDTH, ...
                SpecSize.WRAP, GUISettings.PAD_SMALL);
            
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
            SpecPosition.positionIn(obj.hConfigExport, obj.hFig, ...
                SpecPosition.RIGHT, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hConfigExport, obj.hFig, ...
                SpecPosition.TOP, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hConfigImport, ...
                obj.hConfigExport, SpecPosition.LEFT_OF, ...
                GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hConfigImport, ...
                obj.hConfigExport, SpecPosition.CENTER_Y);
            
            SpecPosition.positionIn(obj.hRef, obj.hFig, ...
                SpecPosition.CENTER_X);
            SpecPosition.positionRelative(obj.hRef, obj.hConfigImport, ...
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
            SpecPosition.positionRelative(obj.hRefSample, ...
                obj.hRefStatus, SpecPosition.BELOW, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hRefSample, obj.hRef, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hRefSampleValue, ...
                obj.hRefSample, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hRefSampleValue, ...
                obj.hRefSample, SpecPosition.RIGHT_OF, GUISettings.PAD_MED);

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
            SpecPosition.positionRelative(obj.hQuerySample, ...
                obj.hQueryStatus, SpecPosition.BELOW, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hQuerySample, obj.hQuery, ...
                SpecPosition.LEFT, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hQuerySampleValue, ...
                obj.hQuerySample, SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hQuerySampleValue, ...
                obj.hQuerySample, SpecPosition.RIGHT_OF, GUISettings.PAD_MED);
            
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

        function strip(obj)
            % Strip data from the UI, and store it in the config struct
            obj.config.reference.path = obj.hRefLocation.String;
            obj.config.reference.subsample_factor = ...
                str2num(obj.hRefSampleValue.String);

            obj.config.query.path = obj.hQueryLocation.String;
            obj.config.query.subsample_factor = ...
                str2num(obj.hQuerySampleValue.String);

            obj.config.results.path = obj.hResultsLocation.String;
        end
    end

    methods (Static, Access=private)
        function results = containsResults(directory)
            results = exist(fullfile(directory, 'results.mat'), 'file');
        end
    end
end
