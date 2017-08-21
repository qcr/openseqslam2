classdef ResultsGUI < handle

    properties (Access = private, Constant)

    end

    properties
        hFig;
    end

    methods
        function obj = ResultsGUI(results, params)
            % Create the figure (and hide it)
            obj.hFig = figure('Visible', 'off');
            GUISettings.applyFigureStyle(obj.hFig);
            obj.hFig.Name = 'SeqSLAM Results';

            % Hacky code just to get a graph happening
            % TODO make legitimate
            m = results.matches(:,1);
            thresh=0.9;  
            m(results.matches(:,2)>thresh) = NaN;  % remove the weakest matches
            plot(m,'.');      % ideally, this would only be the diagonal
            title('Matchings');                 
            xlabel('Reference Image Number');
            ylabel('Query Image Number');

            % Finally, show the figure when we are done configuring
            obj.hFig.Visible = 'on';

        end
    end

    methods (Access = private)

    end

    methods (Static, Access=private)

    end
end
