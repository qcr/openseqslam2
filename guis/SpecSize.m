classdef SpecSize < uint16

    enumeration
        % Specify dimension
        WIDTH (0)
        HEIGHT (1)
        
        % Specify sizing method
        MATCH (2)
        PERCENT (3)
        ABSOLUTE (4)
    end
    
    methods (Static)
        function size(handle, dim, method, varargin)
            p = inputParser;
            p.addRequired('handle', @ishandle);
            p.addRequired('dim', ...
                @(x) x == SpecSize.WIDTH || x == SpecSize.HEIGHT);
            p.addRequired('method', ...
                @(x) x == SpecSize.MATCH || x == SpecSize.PERCENT || ...
                x == SpecSize.ABSOLUTE);
            p.parse(handle, dim, method);
            
            if (method == SpecSize.MATCH)
                % Expected arguments: handle, dim, method, handleref
                % Optional arguments: padding
                if (nargin < 4 || ~ishandle(varargin{1}))
                    error('Invalid: Match needs a reference handle');
                end
                if (nargin > 4 && ~isnumeric(varargin{2}))
                    error('Invalid: Padding must be numeric');
                elseif (nargin < 5)
                    padding = 0;
                else
                    padding = varargin{2};
                end
                SpecSize.sizeMatch(handle, dim, varargin{1}, padding);
            elseif (method == SpecSize.PERCENT)
                % Expected arguments: handle, dim, method, handleref
                % Optional arguments: percent, padding
                if (nargin < 4 || ~ishandle(varargin{1}))
                    error('Invalid: Percent needs a reference handle');
                end
                if (nargin > 4 && ~isnumeric(varargin{2}))
                    error('Invalid: Percent value must be numeric');
                elseif (nargin < 5)
                    percent = 1.0;
                else
                    percent = varargin{2};
                end
                if (nargin > 5 && ~isnumeric(varargin{3}))
                    error('Invalid: Padding must be numeric');
                elseif (nargin < 6)
                    padding = 0;
                else
                    padding = varargin{3};
                end
                SpecSize.sizePercent(handle, dim, varargin{1}, percent, ...
                    padding);
            elseif (method == SpecSize.ABSOLUTE)
                % Expected arguments: handle, dim, method, value
                if (nargin < 4 || ~isnumeric(varargin{1}))
                    error('Invalid: Absolute needs a numeric value');
                end
                SpecSize.sizeAbsolute(handle, dim, varargin{1});
            end
        end
    end

    methods (Static, Access = private)
        function sizeMatch(handle, dim, handleRef, padding)
           if (nargin < 3)
               padding = 0;
           end
           handle.Position(3+dim) = handleRef.Position(3+dim) - 2*padding;
        end
        
        function sizePercent(handle, dim, handleRef, percent, padding)
            if (nargin < 4)
               padding = 0;
            end
           handle.Position(3+dim) = handleRef.Position(3+dim)*percent - ...
               2*padding;
        end
        
        function sizeAbsolute(handle, dim, value)
            handle.Position(3+dim) = value; 
        end
    end
end
