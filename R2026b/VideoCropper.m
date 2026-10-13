classdef VideoCropper < matlab.apps.App

    % Used to locate and load the app's XML configuration file
    properties (Access = public, Constant)
        AppConfigFilename = './VideoCropper.xml'; % File path to the app configuration file containing component layout and settings
    end

    % Properties that correspond to app components
    properties (Access = public)
        CropImageUIFigure               matlab.ui.Figure
        FileMenu                        matlab.ui.container.Menu
        CropMenu                        matlab.ui.container.Menu
        Toolbar                         matlab.ui.container.Toolbar
        PushTool                        matlab.ui.container.toolbar.PushTool
        UIAxes                          matlab.ui.control.UIAxes
    end


    properties (Access = public)
        CallingApp
        roi
    end
    
    methods (Access = public)
        
        function roi_listener(app)
            app.roi.Position = round(app.roi.Position);
        end
    end
    

    % Callbacks that handle component events
    methods

        % Code that executes after component creation
        function startupFcn(app, mainapp)
           % Store main app object
            app.CallingApp = mainapp;
           
            app.CropImageUIFigure.Visible = 'off';
            app.CropImageUIFigure.Units = 'normalized';
            app.CropImageUIFigure.Position(1) = 0.35;%[0.35 0.35 0.30 0.30];
            app.CropImageUIFigure.Position(2) = 0.35;
            app.CropImageUIFigure.Units = 'pixel';
        end

        % Callback function: PushTool
        function PushToolClicked(app, event)
            app.CropMenu.Enable = 'on';

            app.roi = drawrectangle(app.UIAxes);
            app.roi.Position = round(app.roi.Position);

            addlistener(app.roi,'ROIMoved', @roi_listener);
        end

        % Menu selected function: CropMenu
        function CropMenuSelected(app, event)
            app.CallingApp.roi = app.roi;
            
            %Previous Axes
            
            if size(app.CallingApp.Video_Window.PrevSec_ax.Children.CData) < 3
                app.CallingApp.Video_Window.PrevSec_ax.Children.CData = app.CallingApp.Video_Window.PrevSec_ax.Children.CData(app.roi.Position(2):app.roi.Position(2)+app.roi.Position(4)-1,app.roi.Position(1):app.roi.Position(1)+app.roi.Position(3)-1);
            else
                app.CallingApp.Video_Window.PrevSec_ax.Children.CData = app.CallingApp.Video_Window.PrevSec_ax.Children.CData(app.roi.Position(2):app.roi.Position(2)+app.roi.Position(4)-1,app.roi.Position(1):app.roi.Position(1)+app.roi.Position(3)-1,:);
            end
            
            %Current Axes
            
            if size(app.CallingApp.Video_Window.CurSec_ax.Children.CData) < 3
                app.CallingApp.Video_Window.CurSec_ax.Children.CData = app.CallingApp.Video_Window.CurSec_ax.Children.CData(app.roi.Position(2):app.roi.Position(2)+app.roi.Position(4)-1,app.roi.Position(1):app.roi.Position(1)+app.roi.Position(3)-1);
            else
                app.CallingApp.Video_Window.CurSec_ax.Children.CData = app.CallingApp.Video_Window.CurSec_ax.Children.CData(app.roi.Position(2):app.roi.Position(2)+app.roi.Position(4)-1,app.roi.Position(1):app.roi.Position(1)+app.roi.Position(3)-1,:);
            end
            
            %Difference Axes
            
            if size(app.CallingApp.Video_Window.Difference_ax.Children.CData) < 3
                app.CallingApp.Video_Window.Difference_ax.Children.CData = app.CallingApp.Video_Window.Difference_ax.Children.CData(app.roi.Position(2):app.roi.Position(2)+app.roi.Position(4)-1,app.roi.Position(1):app.roi.Position(1)+app.roi.Position(3)-1);
            else
                app.CallingApp.Video_Window.Difference_ax.Children.CData = app.CallingApp.Video_Window.Difference_ax.Children.CData(app.roi.Position(2):app.roi.Position(2)+app.roi.Position(4)-1,app.roi.Position(1):app.roi.Position(1)+app.roi.Position(3)-1,:);
            end
            
            %Current Axes
            
            if size(app.CallingApp.Video_Window.Thresholded_ax.Children.CData) < 3
                app.CallingApp.Video_Window.Thresholded_ax.Children.CData = app.CallingApp.Video_Window.Thresholded_ax.Children.CData(app.roi.Position(2):app.roi.Position(2)+app.roi.Position(4)-1,app.roi.Position(1):app.roi.Position(1)+app.roi.Position(3)-1);
            else
                app.CallingApp.Video_Window.Thresholded_ax.Children.CData = app.CallingApp.Video_Window.Thresholded_ax.Children.CData(app.roi.Position(2):app.roi.Position(2)+app.roi.Position(4)-1,app.roi.Position(1):app.roi.Position(1)+app.roi.Position(3)-1,:);
            end
            
            app.CropImageUIFigure.Visible = 'off';
        end
    end

    % App creation
    methods (Access = public)

        % Construct app
        function app = VideoCropper(varargin)
            app = app@matlab.apps.App(varargin{:});

            if nargout == 0
                clear app
            end
        end
    end
end