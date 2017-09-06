classdef GUISettings

    properties (Constant)
        % Figure properties
        BACK_COL = 'w';
        MAIN_COL = [0.4 0.4 0.4];
        
        % Colouring settings
        COL_SUCCESS = [0 0.6 0];
        COL_ERROR = 'r';
        COL_LOADING = [0.6 0.6 0.6];
        COL_DEFAULT = 'k';

        % Sizings (static for now)
        FONT_SCALE = 1.0;
        
        PAD_SMALL = 5;
        PAD_MED = 10;
        PAD_LARGE = 15;
    end
    
    methods (Static)
        function applyUIAxesStyle(axes)
            GUISettings.applyUICommonStyle(axes);
            axes.Color = GUISettings.BACK_COL;
        end

        function applyFigureStyle(figure)
            GUISettings.applyUICommonStyle(figure);
            figure.Color = GUISettings.BACK_COL;
            figure.NumberTitle = 'off';
            figure.MenuBar = 'none';
            figure.DockControls = 'off';
        end
        
        function applyUIControlStyle(uicontrol)
            GUISettings.applyUICommonStyle(uicontrol);
            uicontrol.BackgroundColor = GUISettings.BACK_COL;
            uicontrol.FontSize = get(groot, 'factoryUicontrolFontSize') ...
                * GUISettings.FONT_SCALE;
        end
        
        function applyUIPanelStyle(uipanel)
            GUISettings.applyUICommonStyle(uipanel);
            uipanel.BackgroundColor = GUISettings.BACK_COL;
            uipanel.FontSize = get(groot, 'factoryUipanelFontSize') ...
                * GUISettings.FONT_SCALE;
        end

        function axesHide(axes)
            axes.XTick = [];
            axes.XTickLabel = [];
            axes.XColor = 'none';
            axes.YTick = [];
            axes.YTickLabel = [];
            axes.YColor = 'none';
        end

        function axesDiffMatrixStyle(axes, limits)
            axes.Box = 'off';
            axes.YDir = 'reverse';
            axes.XAxisLocation = 'top';
            axes.YAxisLocation = 'left';
            axes.XLim = [1 limits(2)];
            axes.YLim = [1 limits(1)];
            axes.XLabel.String = 'Query Image #';
            axes.YLabel.String = 'Reference Image #';
        end

        function setFontScale(uicontrol, scale)
            uicontrol.FontSize = get(groot, 'factoryUicontrolFontSize') ...
                * scale;
        end
    end
    
    methods (Static, Access = private)
        function applyUICommonStyle(uielement)
            uielement.Units = 'pixels';
        end
    end
end

