classdef SleepSpindleDetector_EEGWindow < matlab.apps.App

    % Used to locate and load the app's XML configuration file
    properties (Access = public, Constant)
        AppConfigFilename = './SleepSpindleDetector_EEGWindow.xml'; % File path to the app configuration file containing component layout and settings
    end

    % Properties that correspond to app components
    properties (Access = public)
        SleepSpindleDetectorEEGWindowUIFigure  matlab.ui.Figure
        SpindlecountLabel               matlab.ui.control.Label
        GridLayout                      matlab.ui.container.GridLayout
        RawAxis                         matlab.ui.control.UIAxes
        FilterAxis                      matlab.ui.control.UIAxes
        PeakAxis                        matlab.ui.control.UIAxes
    end



    % Callbacks that handle component events
    methods

        % Code that executes after component creation
        function startupFcn(app)
            app.SleepSpindleDetectorEEGWindowUIFigure.Units = 'normalized';
            app.SleepSpindleDetectorEEGWindowUIFigure.Position = [0.02 0.50 0.60 0.45];
        end
    end

    % App creation
    methods (Access = public)

        % Construct app
        function app = SleepSpindleDetector_EEGWindow(varargin)
            app = app@matlab.apps.App(varargin{:});

            if nargout == 0
                clear app
            end
        end
    end
end