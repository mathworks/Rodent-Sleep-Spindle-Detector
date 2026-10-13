classdef SleepSpindleDetector_VideoWindow < matlab.apps.App

    % Used to locate and load the app's XML configuration file
    properties (Access = public, Constant)
        AppConfigFilename = './SleepSpindleDetector_VideoWindow.xml'; % File path to the app configuration file containing component layout and settings
    end

    % Properties that correspond to app components
    properties (Access = public)
        SleepSpindleDetectorVideoWindowUIFigure  matlab.ui.Figure
        GridLayout                      matlab.ui.container.GridLayout
        PrevSec_ax                      matlab.ui.control.UIAxes
        CurSec_ax                       matlab.ui.control.UIAxes
        Difference_ax                   matlab.ui.control.UIAxes
        Thresholded_ax                  matlab.ui.control.UIAxes
    end

    % Callbacks that handle component events
    methods

        % Code that executes after component creation
        function startupFcn(app)
            app.SleepSpindleDetectorVideoWindowUIFigure.Units = 'normalized';
            app.SleepSpindleDetectorVideoWindowUIFigure.Position = [0.63 0.5 0.35 0.45];
        end
    end

    % App creation
    methods (Access = public)

        % Construct app
        function app = SleepSpindleDetector_VideoWindow(varargin)
            app = app@matlab.apps.App(varargin{:});

            if nargout == 0
                clear app
            end
        end
    end
end