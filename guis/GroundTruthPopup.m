classdef GroundTruthPopup < handle

    properties (Constant)
        FIG_WIDTH_FACTOR = 4;
        FIG_HEIGHT_FACTOR = 31;
    end

    properties
        hFig;
        hHelp;

        hTitle;

        hType;
        hTypeValue;

        hVelocityVel;
        hVelocityVelValue;
        hVelocityTol;
        hVelocityTolValue;

        hFilePathSelect;
        hFilePathDetails;

        hAxis;
        hError;

        hApply;

        results = emptyResults();

        selectedCSV = [];
        selectedCSVData = [];
        selectedMAT = [];
        selectedMATData = [];
        selectedVar = [];
        selectedMatrix = [];
    end

    methods
        function obj = GroundTruthPopup(results)
            % Save the provided data
            obj.results = results;

            % Create and size the popup
            obj.createPopup();
            obj.sizePopup();

            % Add the help button to the figure
            obj.hHelp = HelpPopup.addHelpButton(obj.hFig);
            HelpPopup.setDestination(obj.hHelp, ...
                'ground_truth');

            % Populate the UI (drawing happens after poulating selects a method)
            obj.populate();

            % Finally, show the figure once done configuring
            obj.hFig.Visible = 'on';
        end
    end

    methods (Access = private, Static)
        function matrix = addGroundTruthValue(matrix, q, r, t)
            rRange = r-t:r+t;
            rRange = rRange(rRange >= 1 & rRange <= size(matrix, 1));
            matrix(rRange, q) = 0.5;
            matrix(r, q) = 1.0;
        end
    end

    methods (Access = private)
        function cbApply(obj, src, event)
            % Handle error cases
            err = [];
            if obj.hTypeValue.Value == 2 && isempty(obj.selectedCSVData)
                err = 'No valid ground truth data was loaded from a *.csv file';
            elseif obj.hTypeValue.Value == 3 && isempty(obj.selectedMATData)
                err = 'No valid ground truth data was loaded from a *.mat file';
            end
            if ~isempty(err)
                uiwait(errordlg(err, 'Cannot apply empty ground truth data'));
                return;
            end

            % Strip out the chosen data, and construct the ground truth matrix
            obj.strip();
            obj.results.pr.ground_truth.matrix = obj.selectedMatrix > 0;

            % Close the figure
            close(obj.hFig)
        end

        function cbSelectSource(obj, src, event)
            if obj.hTypeValue.Value > 1
                obj.hVelocityVel.Visible = 'off';
                obj.hVelocityVelValue.Visible = 'off';
                obj.hVelocityTol.Visible = 'off';
                obj.hVelocityTolValue.Visible = 'off';

                obj.hFilePathSelect.Visible = 'on';
                obj.hFilePathDetails.Visible = 'on';
            else
                obj.hVelocityVel.Visible = 'on';
                obj.hVelocityVelValue.Visible = 'on';
                obj.hVelocityTol.Visible = 'on';
                obj.hVelocityTolValue.Visible = 'on';

                obj.hFilePathSelect.Visible = 'off';
                obj.hFilePathDetails.Visible = 'off';
            end
            obj.cbUpdateGroundTruth(obj.hTypeValue, []);
        end

        function cbSelectSourceFile(obj, src, event)
            % Attempt to open the source file, then update all ground truth data
            obj.openSourceFile();
            obj.updateGroundTruth();
            obj.drawScreen();
        end

        function cbUpdateGroundTruth(obj, src, event)
            % Update ground truth and redraw
            obj.updateGroundTruth();
            obj.drawScreen();
        end

        function createPopup(obj)
            % Create the figure (and hide it)
            obj.hFig = figure('Visible', 'off');
            GUISettings.applyFigureStyle(obj.hFig);
            obj.hFig.Name = 'Match Selection Tweaker';

            % Create the title
            obj.hTitle = uicontrol('Style', 'text');
            obj.hTitle.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hTitle);
            GUISettings.setFontScale(obj.hTitle, 1.5);
            obj.hTitle.String = 'Ground Truth Configuration';

            % Create the configuration UI elements
            obj.hType = uicontrol('Style', 'text');
            obj.hType.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hType);
            obj.hType.String = 'Ground Truth Source:';

            obj.hTypeValue = uicontrol('Style', 'popupmenu');
            obj.hTypeValue.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hTypeValue);
            obj.hTypeValue.String = { 'velocity model', '*.csv file', ...
                '*.mat matrix'};

            obj.hVelocityVel = uicontrol('Style', 'text');
            obj.hVelocityVel.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hVelocityVel);
            obj.hVelocityVel.String = 'Ground truth velocity:';

            obj.hVelocityVelValue = uicontrol('Style', 'edit');
            obj.hVelocityVelValue.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hVelocityVelValue);
            obj.hVelocityVelValue.String = '';

            obj.hVelocityTol = uicontrol('Style', 'text');
            obj.hVelocityTol.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hVelocityTol);
            obj.hVelocityTol.String = 'Ground truth tolerance:';

            obj.hVelocityTolValue = uicontrol('Style', 'edit');
            obj.hVelocityTolValue.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hVelocityTolValue);
            obj.hVelocityTolValue.String = '';

            obj.hFilePathSelect = uicontrol('Style', 'pushbutton');
            obj.hFilePathSelect.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hFilePathSelect);
            obj.hFilePathSelect.String = 'Select file';

            obj.hFilePathDetails = uicontrol('Style', 'text');
            obj.hFilePathDetails.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hFilePathDetails);
            obj.hFilePathDetails.String = {' ', ' '};
            obj.hFilePathDetails.FontAngle = 'italic';
            obj.hFilePathDetails.HorizontalAlignment = 'left';

            % Create the axis
            obj.hAxis = axes();
            GUISettings.applyUIAxesStyle(obj.hAxis);
            obj.hAxis.Visible = 'off';
            colormap(obj.hAxis, 'gray');

            obj.hError = uicontrol('Style', 'text');
            obj.hError.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hError);
            GUISettings.setFontScale(obj.hError, 1.25);
            obj.hError.String = 'Please select a valid ground truth file above';
            obj.hError.FontAngle = 'italic';

            % Create the apply button
            obj.hApply = uicontrol('Style', 'pushbutton');
            obj.hApply.Parent = obj.hFig;
            GUISettings.applyUIControlStyle(obj.hApply);
            obj.hApply.String = 'Apply ground truth settings';

            % Callbacks (must be last, otherwise empty objects passed...)
            obj.hTypeValue.Callback = {@obj.cbSelectSource};
            obj.hVelocityVelValue.Callback = {@obj.cbUpdateGroundTruth};
            obj.hVelocityTolValue.Callback = {@obj.cbUpdateGroundTruth};
            obj.hFilePathSelect.Callback = {@obj.cbSelectSourceFile};
            obj.hApply.Callback = {@obj.cbApply};
        end

        function drawScreen(obj)
            cla(obj.hAxis);

            % Either draw the matrix or show the error
            if (obj.hTypeValue.Value == 2 && isempty(obj.selectedCSV)) || ...
                    (obj.hTypeValue.Value == 3 && isempty(obj.selectedMAT))
                obj.hAxis.Visible = 'off';
                obj.hError.Visible = 'on';
            else
                obj.hAxis.Visible = 'on';
                obj.hError.Visible = 'off';

                % Draw the currently selected ground truth matrix
                imagesc(obj.selectedMatrix, 'Parent', obj.hAxis);
                GUISettings.axesDiffMatrixStyle(obj.hAxis, ...
                    size(obj.results.diff_matrix.enhanced));
            end

            % Update the details text if necessary
            if obj.hTypeValue.Value == 2 && ~isempty(obj.selectedCSV)
                obj.hFilePathDetails.String = {['Ground truth matrix loaded ' ...
                    'from:'], obj.selectedCSV};
            elseif obj.hTypeValue.Value == 3 && ~isempty(obj.selectedMAT)
                obj.hFilePathDetails.String = {['Ground truth matrix loaded ' ...
                    'from ''' obj.selectedVar ''' in:'], obj.selectedMAT};
            else
                obj.hFilePathDetails.String = {' ' ' '};
            end
        end

        function openSourceFile(obj)
            % Attempt to get a file of the appropriate type from the user
            f = 0; p = 0;
            if obj.hTypeValue.Value == 3
                [f, p] = uigetfile('*.mat', ...
                    'Select a *.mat file containing a ground truth matrix');
            elseif obj.hTypeValue.Value == 2
                [f, p] = uigetfile('*.csv', ...
                    'Select a *.csv file containing ground truth data');
            end

            % Bail if there was no valid file selected
            if isnumeric(f) || isnumeric (p)
                return;
            end
            f = fullfile(p, f);

            % Attempt to load the file
            err = [];
            data = [];
            v = [];
            if obj.hTypeValue.Value == 3
                % Get the user to select variable to use, then check validity
                vars = whos('-file', f);
                v = listdlg('PromptString', ...
                    'Which variable represents the ground truth matrix:', ...
                    'SelectionMode', 'Single', 'ListString', {vars.name});
                if ~isempty(v)
                    v = vars(v).name;
                    data = load(f, v);
                    data = getfield(data, v);
                end

                if isempty(data)
                    err = 'No data was loaded (data is empty)';
                elseif ~isequal(size(data), ...
                        size(obj.results.diff_matrix.enhanced))
                    err = ['The size of the data (' num2str(size(data, 1)) ...
                        'x' num2str(size(data,2)) ') does not match the ' ...
                        'size of the difference matrix (' ...
                        num2str(size(obj.results.diff_matrix.enhanced, 1)) ...
                        'x' ...
                        num2str(size(obj.results.diff_matrix.enhanced, 2)) ')'];
                elseif ~isempty(data(data(data(data ~=0 ) ~= 1) ~= 0.5))
                    err = ['Invalid values were detected in the data (' ...
                        'only 0, 0.5, and 1 are supported values)'];
                end
            elseif obj.hTypeValue.Value == 2
                % Read in the csv, and check validity
                data = csvread(f);
                if size(data,2) > 3
                    err = ['Data has too many values (' ...
                        num2str(size(data,2)) ') per row (3 expected)'];
                elseif min(min(data)) < 0
                    err = 'Data is invalid (negative values were detected)';
                elseif max(data(:,1)) > size(obj.results.diff_matrix.enhanced,2)
                    err = ['Data found with query image number (' ...
                        num2str(max(data(:,1))) ') greater than number of ' ...
                        'query images in the difference matrix (' ...
                        num2str(size(obj.results.diff_matrix.enhanced,2)) ')'];
                elseif max(data(:,2)) > size(obj.results.diff_matrix.enhanced,1)
                    err = ['Data found with reference image number (' ...
                        num2str(max(data(:,2))) ') greater than number of ' ...
                        'reference images in the difference matrix (' ...
                        num2str(size(obj.results.diff_matrix.enhanced,1)) ')'];
                end
            end

            % Bail if there was an error
            if ~isempty(err)
                uiwait(errordlg(err, 'Ground Truth Data Read Failed'));
                return;
            end

            % We have valid ground truth data, turn it into something that
            % we can use
            if obj.hTypeValue.Value == 3
                obj.selectedMAT = f;
                obj.selectedVar = v;
                obj.selectedMatrix = data;
                obj.selectedMATData = data;
            elseif obj.hTypeValue.Value == 2
                obj.selectedCSV = f;
                obj.selectedCSVData = data;
            end
        end

        function populate(obj)
            % Load the values in from the results
            source = SafeData.noEmpty(obj.results.pr.ground_truth.type, ...
                'velocity');
            if strcmpi(source, 'file')
                file = SafeData.noEmpty( ...
                    obj.results.pr.ground_truth.file.path, '*.csv');
                if endswith(file, 'mat')
                    obj.hTypeValue.Value = 3;
                else
                    obj.hTypeValue.Value = 2;
                end
            else
                obj.hTypeValue.Value = 1;
            end
            obj.hVelocityVelValue.String = SafeData.noEmpty( ...
                obj.results.pr.ground_truth.velocity.vel, 1);
            obj.hVelocityTolValue.String = SafeData.noEmpty( ...
                obj.results.pr.ground_truth.velocity.tol, 5);

            % Execute any required callbacks manually
            obj.cbSelectSource(obj.hTypeValue, []);
        end

        function sizePopup(obj)
            % Statically size for now
            % TODO handle potential resizing gracefully
            widthUnit = obj.hTitle.Extent(3);
            heightUnit = obj.hTitle.Extent(4);

            % Size and position the figure
            obj.hFig.Position = [0, 0, ...
                widthUnit * GroundTruthPopup.FIG_WIDTH_FACTOR, ...
                heightUnit * GroundTruthPopup.FIG_HEIGHT_FACTOR];
            movegui(obj.hFig, 'center');

            % Now that the figure (space for placing UI elements is set),
            % size all of the elements
            SpecSize.size(obj.hTitle, SpecSize.HEIGHT, SpecSize.WRAP);
            SpecSize.size(obj.hTitle, SpecSize.WIDTH, SpecSize.MATCH, ...
                obj.hFig, GUISettings.PAD_MED);

            SpecSize.size(obj.hType, SpecSize.WIDTH, SpecSize.WRAP, ...
                GUISettings.PAD_MED);
            SpecSize.size(obj.hTypeValue, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.125);

            SpecSize.size(obj.hVelocityVel, SpecSize.WIDTH, SpecSize.WRAP, ...
                GUISettings.PAD_MED);
            SpecSize.size(obj.hVelocityVelValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.1);
            SpecSize.size(obj.hVelocityTol, SpecSize.WIDTH, SpecSize.WRAP, ...
                GUISettings.PAD_MED);
            SpecSize.size(obj.hVelocityTolValue, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.1);

            SpecSize.size(obj.hFilePathSelect, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.1);
            SpecSize.size(obj.hFilePathDetails, SpecSize.WIDTH, ...
                SpecSize.PERCENT, obj.hFig, 0.6);
            SpecSize.size(obj.hFilePathDetails, SpecSize.HEIGHT, ...
                SpecSize.WRAP);

            SpecSize.size(obj.hAxis, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.8);
            SpecSize.size(obj.hAxis, SpecSize.HEIGHT, SpecSize.RATIO, 3/4);
            SpecSize.size(obj.hError, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.5);
            SpecSize.size(obj.hError, SpecSize.HEIGHT, SpecSize.PERCENT, ...
                obj.hFig, 0.5);

            SpecSize.size(obj.hApply, SpecSize.WIDTH, SpecSize.PERCENT, ...
                obj.hFig, 0.2);

            % Then, systematically place
            SpecPosition.positionIn(obj.hTitle, obj.hFig, ...
                SpecPosition.TOP, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hTitle, obj.hFig, ...
                SpecPosition.CENTER_X);

            SpecPosition.positionRelative(obj.hType, obj.hTitle, ...
                SpecPosition.BELOW, GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hType, obj.hFig, ...
                SpecPosition.LEFT, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hTypeValue, obj.hType, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hTypeValue, obj.hType, ...
                SpecPosition.RIGHT_OF, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hVelocityVel, obj.hType, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hVelocityVel, obj.hTypeValue, ...
                SpecPosition.RIGHT_OF, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hVelocityVelValue, obj.hType, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hVelocityVelValue, ...
                obj.hVelocityVel, SpecPosition.RIGHT_OF, GUISettings.PAD_MED);
            SpecPosition.positionRelative(obj.hVelocityTol, obj.hType, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hVelocityTol, ...
                obj.hVelocityVelValue, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hVelocityTolValue, obj.hType, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hVelocityTolValue, ...
                obj.hVelocityTol, SpecPosition.RIGHT_OF, GUISettings.PAD_MED);

            SpecPosition.positionRelative(obj.hFilePathSelect, obj.hType, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hFilePathSelect, ...
                obj.hTypeValue, SpecPosition.RIGHT_OF, GUISettings.PAD_LARGE);
            SpecPosition.positionRelative(obj.hFilePathDetails, obj.hType, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionRelative(obj.hFilePathDetails, ...
                obj.hFilePathSelect, SpecPosition.RIGHT_OF, ...
                GUISettings.PAD_MED);

            SpecPosition.positionRelative(obj.hAxis, obj.hType, ...
                SpecPosition.BELOW, 4*GUISettings.PAD_LARGE);
            SpecPosition.positionIn(obj.hAxis, obj.hFig, ...
                SpecPosition.CENTER_X);
            SpecPosition.positionIn(obj.hError, obj.hFig, ...
                SpecPosition.CENTER_Y);
            SpecPosition.positionIn(obj.hError, obj.hFig, ...
                SpecPosition.CENTER_X);

            SpecPosition.positionIn(obj.hApply, obj.hFig, ...
                SpecPosition.BOTTOM, GUISettings.PAD_MED);
            SpecPosition.positionIn(obj.hApply, obj.hFig, ...
                SpecPosition.RIGHT, GUISettings.PAD_MED);
        end

        function strip(obj)
            % ONLY strip out the values for the currently selected method
            if obj.hTypeValue.Value == 1
                obj.results.pr.ground_truth.type = 'velocity';
                obj.results.pr.ground_truth.file.path = [];
                obj.results.pr.ground_truth.velocity.vel = ...
                    str2num(obj.hVelocityVelValue.String);
                obj.results.pr.ground_truth.velocity.tol = ...
                    str2num(obj.hVelocityTolValue.String);
            elseif obj.hTypeValue.Value == 2
                obj.results.pr.ground_truth.type = 'file';
                obj.results.pr.ground_truth.file.path = obj.selectedCSV;
                obj.results.pr.ground_truth.velocity.vel = [];
                obj.results.pr.ground_truth.velocity.tol = [];
            elseif obj.hTypeValue.Value == 3
                obj.results.pr.ground_truth.type = 'file';
                obj.results.pr.ground_truth.file.path = obj.selectedMAT;
                obj.results.pr.ground_truth.velocity.vel = [];
                obj.results.pr.ground_truth.velocity.tol = [];
            end
        end

        function updateGroundTruth(obj)
            % Reconstruct the ground truth matrix as requested
            if obj.hTypeValue.Value == 1
                % Update the data
                v = str2num(obj.hVelocityVelValue.String);
                t = str2num(obj.hVelocityTolValue.String);
                qs = 1:size(obj.results.diff_matrix.enhanced, 2);
                rs = round(linspace(1, 1 + (length(qs)-1)*v, length(qs)));
                obj.selectedMatrix = zeros(length(rs), length(qs));
                for k = 1:length(qs)
                    obj.selectedMatrix = ...
                        GroundTruthPopup.addGroundTruthValue( ...
                        obj.selectedMatrix, qs(k), rs(k), t);
                end
            elseif obj.hTypeValue.Value == 2 && ~isempty(obj.selectedCSVData)
                obj.selectedMatrix = zeros( ...
                    size(obj.results.diff_matrix.enhanced));
                for k = 1:size(obj.selectedCSVData,1)
                    obj.selectedMatrix = ...
                        GroundTruthPopup.addGroundTruthValue( ...
                        obj.selectedMatrix, obj.selectedCSVData(k,1), ...
                        obj.selectedCSVData(k,2), obj.selectedCSVData(k,3));
                end
            elseif obj.hTypeValue.Value == 3 && ~isempty(obj.selectedMATData)
                obj.selectedMatrix = obj.selectedMATData;
            end
        end
    end
end
