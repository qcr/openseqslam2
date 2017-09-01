classdef ResultsGUI < handle

    properties (Access = private, Constant)
        FN_CONFIG = 'config.xml';
        FN_PREPROCESSED = '0_preprocessed';
        FN_PREPROCESSED_REF = [ResultsGUI.FN_PREPROCESSED '_ref.mat'];
        FN_PREPROCESSED_QUERY = [ResultsGUI.FN_PREPROCESSED '_query.mat'];
        
        FN_DIFF_MATRIX = '1_diff_matrx.mat';
        FN_DIFF_MATRIX_ENHANCED = '2_diff_matrix_enhanced.mat';

        FN_MATCHING_SCORE = '3_matching_scores.mat';
    end

    properties
        hFig;
        hAxes;

        hToggle;

        results;
        config;
    end

    methods
        function obj = ResultsGUI(results, config)
            % TODO fix hacky
            obj.results = results;
            obj.config = config;
            
            % Create and size the GUI
            obj.createGUI();
            obj.sizeGUI();

            % Finally, show the figure when we are done configuring
            obj.hFig.Visible = 'on';

            % TODO hacky initial selection
            obj.hToggle.Value = length(obj.hToggle.String);
            obj.callbackToggle(obj.hToggle, []);
        end
    end

    methods (Access = private)
        function callbackToggle(obj, src, event)
            if (obj.hToggle.Value == 1)
                imagesc(obj.hAxes, obj.results.diff_matrix.base);
                obj.hAxes.Title.String = 'Difference Matrix';
            elseif (obj.hToggle.Value == 2)
                imagesc(obj.hAxes, obj.results.diff_matrix.enhanced);
                obj.hAxes.Title.String = 'Difference Matrix (enhanced)';
            elseif (obj.hToggle.Value == 3)
                plot(obj.hAxes, obj.results.matches.all, '.');
                axis([0, size(obj.results.diff_matrix.base, 2), ...
                    0, size(obj.results.diff_matrix.base, 1)]);
                obj.hAxes.Title.String = 'Matches (best & trajectory scores)';
                obj.hAxes.YDir = 'reverse';
            elseif (obj.hToggle.Value == 4)
                plot(obj.hAxes, obj.results.matches.thresholded, '.');
                axis([0, size(obj.results.diff_matrix.base, 2), ...
                    0, size(obj.results.diff_matrix.base, 1)]);
                obj.hAxes.Title.String = 'Matches (thresholded)';
                obj.hAxes.YDir = 'reverse';
            end
        end

        function createGUI(obj)
            % Create the figure (and hide it)
            obj.hFig = figure('Visible', 'off');
            GUISettings.applyFigureStyle(obj.hFig);
            obj.hFig.Name = 'SeqSLAM Results';

            % Hacky
            % TODO make legitimate
            obj.hToggle = uicontrol('Style', 'popupmenu');
            GUISettings.applyUIControlStyle(obj.hToggle);
            obj.hToggle.String = { ...
                'Difference Matrix' ...
                'Difference Matrix (Enhanced)' ...
                'Matches (best)' ...
                'Matches (thresholded)'};

            obj.hAxes = axes(obj.hFig);

            obj.hToggle.Callback = {@obj.callbackToggle};
        end

        function sizeGUI(obj)
            obj.hToggle.Units = 'normalized';
            obj.hToggle.Position(1) = 0.1;
            obj.hToggle.Position(3) = 0.8;
            obj.hToggle.Position(2) = 0.01;
        end
    end

    methods (Static)
        function fn = getFileName(config, string)
            fn = fileparts(config.results.path, string);
        end

        function fn = getValidatedFileName(config, string)
            fn = getFileName(config, string);
            if ~exist(fn, 'file')
                fn = [];
            end
        end
    end

    methods (Static, Access=private)

    end
end
