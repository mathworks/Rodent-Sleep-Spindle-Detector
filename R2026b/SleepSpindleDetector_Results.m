classdef SleepSpindleDetector_Results < matlab.apps.App

    % Used to locate and load the app's XML configuration file
    properties (Access = public, Constant)
        AppConfigFilename = './SleepSpindleDetector_Results.xml'; % File path to the app configuration file containing component layout and settings
    end

    % Properties that correspond to app components
    properties (Access = public)
        SleepSpindleDetectorResultsUIFigure  matlab.ui.Figure
        FileMenu                        matlab.ui.container.Menu
        SaveasMenu                      matlab.ui.container.Menu
        AllMenu                         matlab.ui.container.Menu
        SummaryMenu                     matlab.ui.container.Menu
        EpochSummaryMenu                matlab.ui.container.Menu
        DurationsMenu                   matlab.ui.container.Menu
        SpecificsMenu                   matlab.ui.container.Menu
        PrimaryMenu                     matlab.ui.container.Menu
        SecondaryMenu                   matlab.ui.container.Menu
        BinaryClassificationsMenu       matlab.ui.container.Menu
        GroundTruthMenu                 matlab.ui.container.Menu
        StatsMenu                       matlab.ui.container.Menu
        LoadMenu                        matlab.ui.container.Menu
        GroundTruthMenu_2               matlab.ui.container.Menu
        Menu                            matlab.ui.container.Menu
        FileMenu_2                      matlab.ui.container.Menu
        SaveasMenu_2                    matlab.ui.container.Menu
        PrimaryMenu_2                   matlab.ui.container.Menu
        SecondaryMenu_2                 matlab.ui.container.Menu
        FileMenu_3                      matlab.ui.container.Menu
        SaveasMenu_3                    matlab.ui.container.Menu
        StatsMenu_2                     matlab.ui.container.Menu
        CalculateMenu                   matlab.ui.container.Menu
        TabGroup                        matlab.ui.container.TabGroup
        SummaryTab                      matlab.ui.container.Tab
        SummaryLabel                    matlab.ui.control.Label
        EpochSummaryUITable             matlab.ui.control.Table
        SecondaryPanel                  matlab.ui.container.Panel
        SecondaryUITable                matlab.ui.control.Table
        PrimaryPanel                    matlab.ui.container.Panel
        PrimaryUITable                  matlab.ui.control.Table
        SleepSleepSpecificsTab          matlab.ui.container.Tab
        TabGroup2                       matlab.ui.container.TabGroup
        PrimaryClassificationTab        matlab.ui.container.Tab
        PrimarySpecifics                matlab.ui.control.Table
        SecondaryClassifcationTab       matlab.ui.container.Tab
        SecondarySpecifics              matlab.ui.control.Table
        ValidationTab                   matlab.ui.container.Tab
        ProgressTextLabel               matlab.ui.control.Label
        GraphPredictionsButton          matlab.ui.control.Button
        PlotGroundTruthButton           matlab.ui.control.Button
        LoadGroundTruthButton           matlab.ui.control.Button
        GroundTruthUITable              matlab.ui.control.Table
        CaculateButton                  matlab.ui.control.Button
        UITable                         matlab.ui.control.Table
        BinaryUITable                   matlab.ui.control.Table
        UIAxes                          matlab.ui.control.UIAxes
        Tab                             matlab.ui.container.Tab
    end

    
    properties (Access = public)
        Callingapp
    end
    

    % Callbacks that handle component events
    methods

        % Code that executes after component creation
        function startupFcn(app, MainApp)
%             app.SleepSpindleDetectorResultsUIFigure.Visible = "off";
            app.Callingapp = MainApp;

            app.SleepSpindleDetectorResultsUIFigure.Units = 'normalized';
            app.SleepSpindleDetectorResultsUIFigure.Position(1) = 0.3;
            app.SleepSpindleDetectorResultsUIFigure.Position(2) = 0.3;
            app.SleepSpindleDetectorResultsUIFigure.Units = 'pixel';
        end

        % Button pushed function: LoadGroundTruthButton
        function LoadGroundTruthButtonPushed(app, event)
            filename = uigetfile;
            data = load(filename);

            if size(data.GroundTruth,2)>size(data.GroundTruth,1)
                data.GroundTruth = data.GroundTruth';
            end
            app.GroundTruthUITable.Data = double(data.GroundTruth);
            
            app.PlotGroundTruthButton.Enable = "on";

            figure(app.SleepSpindleDetectorResultsUIFigure)
        end

        % Button pushed function: CaculateButton
        function CaculateButtonPushed(app, event)
%             bar(app.UIAxes,app.Callingapp.Primary_SS)


            [TP,TN,FP,FN,Sensitivity,Specificity,Accuracy,MCC,Fscore] = Tracking_stats(app.Callingapp.Primary_SS,app.GroundTruthUITable.Data);
            [TP2,TN2,FP2,FN2,Sensitivity2,Specificity2,Accuracy2,MCC2,Fscore2] = Tracking_stats(app.Callingapp.Secondary_SS,app.GroundTruthUITable.Data);

            t = table;
            t.Methods = ["Primary";"Secondary"];
            t.TP = [TP;TP2];
            t.TN = [TN;TN2];
            t.FP = [FP;FP2];
            t.FN = [FN;FN2];
            t.Sensitivity = [Sensitivity;Sensitivity2];
            t.Specificity = [Specificity;Specificity2];
            t.Accuracy = [Accuracy;Accuracy2];
            t.MCC = [MCC;MCC2];
            t.Fscore = [Fscore;Fscore2];

            set(app.UITable,"Data",t);
        end

        % Button pushed function: PlotGroundTruthButton
        function PlotGroundTruthButtonPushed(app, event)
            if ~isempty(app.GroundTruthUITable.Data)
            bar(app.UIAxes,app.GroundTruthUITable.Data)
            hold(app.UIAxes,"on")
            end
        end

        % Menu selected function: AllMenu
        function AllMenuSelected(app, event)
            [folder,filename] = uiputfile(fullfile(pwd,".csv"));
            writetable(app.UITable.Data,fullfile(folder,filename))
            
         
        end
    end

    % App creation
    methods (Access = public)

        % Construct app
        function app = SleepSpindleDetector_Results(varargin)
            app = app@matlab.apps.App(varargin{:});

            if nargout == 0
                clear app
            end
        end
    end
end