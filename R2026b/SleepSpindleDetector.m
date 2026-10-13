classdef SleepSpindleDetector < matlab.apps.App

    % Used to locate and load the app's XML configuration file
    properties (Access = public, Constant)
        AppConfigFilename = './SleepSpindleDetector.xml'; % File path to the app configuration file containing component layout and settings
    end

    % Properties that correspond to app components
    properties (Access = public)
        SleepSpindleDetectorControllerUIFigure  matlab.ui.Figure
        FIleMenu                        matlab.ui.container.Menu
        LoadEEGMenu                     matlab.ui.container.Menu
        LoadVideoMenu                   matlab.ui.container.Menu
        SaveProjectMenu                 matlab.ui.container.Menu
        LoadProjectMenu                 matlab.ui.container.Menu
        AnalyzeMenu                     matlab.ui.container.Menu
        EditMenu                        matlab.ui.container.Menu
        CropImageMenu                   matlab.ui.container.Menu
        UncropImageMenu                 matlab.ui.container.Menu
        VideofpsMenu                    matlab.ui.container.Menu
        ViewMenu                        matlab.ui.container.Menu
        EEGMenu                         matlab.ui.container.Menu
        VideoMenu                       matlab.ui.container.Menu
        ResultsMenu                     matlab.ui.container.Menu
        AnalyzeMenu_2                   matlab.ui.container.Menu
        StatsMenu                       matlab.ui.container.Menu
        GridLayout                      matlab.ui.container.GridLayout
        AnalyzeButton                   matlab.ui.control.Button
        RightArrowArea                  matlab.ui.control.Button
        AreaThresholdSlider             matlab.ui.control.Slider
        LeftArrowArea                   matlab.ui.control.Button
        TextArea                        matlab.ui.control.TextArea
        PlayButton                      matlab.ui.control.Button
        AreaThresholdEditField          matlab.ui.control.NumericEditField
        AreaThresholdLabel              matlab.ui.control.Label
        NotesLabel                      matlab.ui.control.Label
        RThresholdEditField             matlab.ui.control.NumericEditField
        R2ThresholdLabel                matlab.ui.control.Label
        RightArrowBinary                matlab.ui.control.Button
        BinaryThresholdSlider           matlab.ui.control.Slider
        LeftArrowBinary                 matlab.ui.control.Button
        RightArrowZoom                  matlab.ui.control.Button
        ZoomSlider                      matlab.ui.control.Slider
        LeftArrowZoom                   matlab.ui.control.Button
        ChannelDropDown                 matlab.ui.control.DropDown
        BinaryThresholdEditField        matlab.ui.control.NumericEditField
        BinaryThresholdLabel            matlab.ui.control.Label
        ZoomEditField                   matlab.ui.control.NumericEditField
        ZoomLabel                       matlab.ui.control.Label
        ChannelDropDownLabel            matlab.ui.control.Label
        RightArrowEpoch                 matlab.ui.control.Button
        EpochSlider                     matlab.ui.control.Slider
        LeftArrowEpoch                  matlab.ui.control.Button
        OpenVideoFile                   matlab.ui.control.Button
        VideoFileDropDown               matlab.ui.control.DropDown
        EpochEditField                  matlab.ui.control.NumericEditField
        EpochLabel                      matlab.ui.control.Label
        VideoFileDropDownLabel          matlab.ui.control.Label
        RightArrowTime                  matlab.ui.control.Button
        TimesSlider                     matlab.ui.control.Slider
        LeftArrowTime                   matlab.ui.control.Button
        OpenEEGFile                     matlab.ui.control.Button
        EEGFileDropDown                 matlab.ui.control.DropDown
        TimesEditField                  matlab.ui.control.NumericEditField
        TimesSliderLabel                matlab.ui.control.Label
        EEGFileDropDownLabel            matlab.ui.control.Label
    end

    properties (Access = public)
        EEG_Window = SleepSpindleDetector_EEGWindow;
        Video_Window = SleepSpindleDetector_VideoWindow;
        Result_Window;
        Stats_Window
        Crop_Window
        Controller;
        Time=0;
        Stop=0;
        t=table;
        t2=table;
        t3=table;
        t4=table;
        t5=table;
        v;
        EEG_Filename;
        EEG_folder;
        Video_Filename;
        Video_folder;
        Window_size = 100;
        channel = 1;
        HDR
        roi
        timedelay = 0.5; % seconds
        binary_SS
        binary_SS_secondary
        Primary_SS
        Primary_SS_raw
        Secondary_SS
        Secondary_SS_raw
        QuiescentPeriod
    end
    methods (Access = public)
        function OpenEEG(app)
        %% READ EDF
        app.HDR = EDFData(fullfile(app.EEG_folder,app.EEG_Filename));

        app.channel = app.ChannelDropDown.ValueIndex;
        app.ChannelDropDown.Items = app.HDR.label;
        app.ChannelDropDown.Value = app.HDR.label{app.channel};

        % Define Constraints
        SR = app.HDR.sf(app.channel);                % sample rate
        DurRec = floor(app.HDR.records*app.HDR.duration);   % Edf full duration record
        nSec = app.Window_size;                          % 100 second window
        epochs = floor(DurRec/nSec);       % number of iteration "Epochs"

        %Update Epoch Slider
        app.EpochSlider.Limits(2) = epochs;
        app.TimesSlider.Limits(2) = nSec;

        %Load EEG epoch
        stPos = round((app.EpochSlider.Value-1)*nSec*SR);                                % starting Position
        if length(SR)>1
            raw = app.HDR.getData([stPos+1 round(stPos+nSec*SR(app.channel))],app.channel); % reading the edf file starting from [stPos] for duration of [nSec]
        else
            raw = app.HDR.getData([stPos+1 round(stPos+nSec*SR)],app.channel);
        end
        %% Normalize Raw EEG Data

        norm_Y = zeros(size(raw));
        for i = 1%:8
            norm_Y(:,i) = (raw(:,i) - median(raw(:,i)))/(max(abs(raw(:,i) -median(raw(:,i)))));
        end
        raw=norm_Y;

        %% Run McSleep transient separation on EEG data given by Y

        if length(SR)>1
            time=(0:1/SR(app.channel):nSec-(1/SR(app.channel)));
        else
            time=(0:1/SR:nSec-(1/SR));
        end
        fs = length(time)/(time(end)-time(1));


        % Define parameters
        if length(SR)>1
            param = struct('lam1', .000000000000000000006, 'lam2',.007 ,'lam3',.001,'K',floor(SR(app.channel)),...  %.00006,.0007  .000728, 00009
                'mu', 0.3,'O',SR(app.channel)/2,'Nit',50); %8-7-2020 TAM KSH optimized lam1 = 0.00004, lam2 = 0.00003, lam3 = 0.001, mu = 0.3
        else
            param = struct('lam1', .000000000000000000006, 'lam2',.007 ,'lam3',.001,'K',floor(SR),...  %.00006,.0007  .000728, 00009
                'mu', 0.3,'O',SR/2,'Nit',50); %8-7-2020 TAM KSH optimized lam1 = 0.00004, lam2 = 0.00003, lam3 = 0.001, mu = 0.3
        end

        param.calculateCost = 1;
        if length(SR)>1
            % raw=raw(1:SR(app.channel)*nSec,:); % uncomment if using processed signal with fractional Sample Rate
        else
            % raw=raw(1:SR*nSec,:); % uncomment if using processed signal with fractional Sample Rate
        end

        % Define operators for block low rank property
        H = @(x,s,k) Op_A(x,s,k);
        HT = @(x,s,k) Op_AT(x,s,k);

        tic; [~,s,~] = mcsleep(raw', H, HT, param); toc

        %% Bandpass filter
        % Bandpass filter parameters
        params.f1 = 11;
        params.f2 = 17;
        params.filtOrder = 4;

        % Apply bandpass filter to oscillatory component
        fprintf('Applying bandpass filter to oscillatory component ... \n');
        [B,A] = cheby1(params.filtOrder,0.1,[params.f1 params.f2]/(fs/2)); %butter(params.filtOrder, [params.f1 params.f2]/(fs/2));
        Oscillatory_Component_bandpassFiltered = filtfilt(B,A,s');

        %% Find peaks

        % Primary Classifcation Method
        [peaks_value, peaks_index] = findpeaks(abs(Oscillatory_Component_bandpassFiltered(:,1)));

        % Secondary Classifcation Method (separate odd and even datapoints (peaks)
        peaks_value_odd = peaks_value(1:2:end,1);
        peaks_value_even = peaks_value(2:2:end,1);

        peaks_index_odd = peaks_index(1:2:end,1);
        peaks_index_even = peaks_index(2:2:end,1);

        %% Find Peaks of Peaks and filter for highest peaks

        % Primary Classification Method
        [peak_peaks_value, peak_peaks_index] = findpeaks(peaks_value);
        peak_peaks_value_filtered = peak_peaks_value/max(peak_peaks_value);

        % Secondary Classification Method

        % Odd Peak Peaks
        [peak_peaks_value_odd, peak_peaks_index_odd] = findpeaks(peaks_value_odd);
        peak_peaks_value_filtered_odd = peak_peaks_value_odd/max(peak_peaks_value_odd);

        % Even Peak Peaks
        [peak_peaks_value_even, peak_peaks_index_even] = findpeaks(peaks_value_even);
        peak_peaks_value_filtered_even = peak_peaks_value_even/max(peak_peaks_value_even);

        %% Detect Spindles

        % Primary Classification Method
        SS_peaks = Downhill(app,peaks_value,peaks_index, peak_peaks_index,peak_peaks_value_filtered);

        % Secondary Classification Method
        SS_peaks_odd = Downhill_secondary(app,peaks_value_odd,peaks_index, peak_peaks_index_odd,peak_peaks_value_filtered_odd);
        SS_peaks_even = Downhill_secondary(app,peaks_value_even,peaks_index, peak_peaks_index_even,peak_peaks_value_filtered_even);

        %% Remove Spindles of Short Duration
        minimum_duration = 10;

        counter=0;
        % Primary Classification
        for ii = 1:length(SS_peaks)
            % First Classification Method
            if SS_peaks(ii) == 1
                counter = counter+1;
            else
                if counter < minimum_duration+1
                    for c = 1:counter
                        SS_peaks(ii-c)=0;
                    end
                end
                counter = 0;
            end
        end

        % Secondary Classification (odd)
        minimum_duration = round(minimum_duration/2);
        counter=0;
        for ii = 1:length(SS_peaks_odd)
            % Secondary Classification Method (odd)
            if SS_peaks_odd(ii) == 1
                counter = counter+1;
            else
                if counter < minimum_duration+1
                    for c = 1:counter
                        SS_peaks_odd(ii-c)=0;
                    end
                end
                counter = 0;
            end
        end
        % Secondary Classification (even)
        counter=0;
        for ii = 1:length(SS_peaks_even)
            % Secondary Classification Method (even)
            if SS_peaks_even(ii) == 1
                counter = counter+1;
            else
                if counter < minimum_duration+1
                    for c = 1:counter
                        SS_peaks_even(ii-c)=0;
                    end
                end
                counter = 0;
            end
        end

        %% Curvefit for odd
        counter_odd=0;
        for ii = 1:length(SS_peaks_odd)
            if SS_peaks_odd(ii) == 1
                counter_odd = counter_odd+1;
            else
                if ii>1 && SS_peaks_odd(ii-1) == 1
                    odd_Spindle_Amplitude = zeros(counter_odd,1);
                    for c = 1:counter_odd
                        odd_Spindle_Amplitude(c) = peaks_value_odd(ii-c);
                    end
                    Data_Points=1:c;
                    try
                        [~, gof] = createFit(Data_Points(round(0.4*length(odd_Spindle_Amplitude)):round(0.6*length(odd_Spindle_Amplitude))), odd_Spindle_Amplitude(round(0.4*length(odd_Spindle_Amplitude)):round(0.6*length(odd_Spindle_Amplitude)))'); % Plot has been commented out in the function CreateFit
                    catch
                        [~, gof] = createFit(Data_Points, odd_Spindle_Amplitude'); % Plot has been commented out in the function CreateFit
                    end
                    % title(['Odd side of Spindle with a R Coefficient of ' num2str(gof.rsquare)])
                    if gof.rsquare < app.RThresholdEditField.Value
                        for c = 1:counter_odd
                            SS_peaks_odd(ii-c)=0;
                        end
                    end
                end
                counter_odd = 0;
            end
        end

        %% Curvefit for even
        counter_even=0;
        for ii = 1:length(SS_peaks_even)
            if SS_peaks_even(ii) == 1
                counter_even = counter_even+1;
            else
                if ii>1 && SS_peaks_even(ii-1) == 1
                    even_Spindle_Amplitude = zeros(counter_even,1);
                    for c = 1:counter_even
                        even_Spindle_Amplitude(c) = peaks_value_even(ii-c);
                    end
                    Data_Points=1:c;
                    try
                        [~, gof] = createFit(Data_Points(round(0.4*length(even_Spindle_Amplitude)):round(0.6*length(even_Spindle_Amplitude))), even_Spindle_Amplitude(round(0.4*length(even_Spindle_Amplitude)):round(0.6*length(even_Spindle_Amplitude)))'); % Plot has been commented out in the function CreateFit
                        %                         title(['Even side of Spindle with a R Coefficient of ' num2str(gof.rsquare)])
                    catch
                        [~, gof] = createFit(Data_Points, even_Spindle_Amplitude'); % Plot has been commented out in the function CreateFit
                    end
                    if gof.rsquare < app.RThresholdEditField.Value
                        for c = 1:counter_even
                            SS_peaks_even(ii-c)=0;
                        end
                    end
                end
                counter_even = 0;
            end
        end

        % Merge odd and even peak datapoints back together
%         SS_peaks_secondary(1:2:end)=SS_peaks_odd;
%         SS_peaks_secondary(2:2:end)=SS_peaks_even;


        %% Convert logical spindle detection array from peak dimensions to datapoint (signal) dimensions
        % preallocate
        app.binary_SS = zeros(size(Oscillatory_Component_bandpassFiltered(:,1)));
        app.binary_SS_secondary = zeros(size(Oscillatory_Component_bandpassFiltered(:,1)));
        binary_SS_odd = zeros(size(Oscillatory_Component_bandpassFiltered(:,1)));
        binary_SS_even = zeros(size(Oscillatory_Component_bandpassFiltered(:,1)));

        %count number of sleep spindles
        count = 0;
        if peaks_index(1) == 1 && SS_peaks(1) == 1
            count = count + 1;
            app.binary_SS(1)= 1;
        end

        for iii = 1:length(peaks_index)
            if SS_peaks(iii) == 1 && SS_peaks(iii-1) == 0
                count = count + 1;
                app.binary_SS(peaks_index(iii))=1;
            end
            if SS_peaks(iii) == 1 && SS_peaks(iii-1) == 1
                app.binary_SS(peaks_index(iii-1):peaks_index(iii))=1;
            end
        end

        %Secondary Classification odd
        count_odd = 0;
        if peaks_index_odd(1) == 1 && SS_peaks_odd(1) == 1
            count_odd = count_odd + 1;
            binary_SS_odd(1)= 1;
        end

        for iii = 2:length(peaks_index_odd)
            if SS_peaks_odd(iii) == 1 && SS_peaks_odd(iii-1) == 0
                count_odd = count_odd + 1;
                binary_SS_odd(peaks_index_odd(iii))=1;
            end
            if SS_peaks_odd(iii) == 1 && SS_peaks_odd(iii-1) == 1
                binary_SS_odd(peaks_index_odd(iii-1):peaks_index_odd(iii))=1;
            end
        end

        %Secondary Classification even
        count_even = 0;
        if peaks_index_even(1) == 1 && SS_peaks_even(1) == 1
            count_even = count_even + 1;
            binary_SS_even(1)= 1;
        end

        for iii = 2:length(peaks_index_even)
            if SS_peaks_even(iii) == 1 && SS_peaks_even(iii-1) == 0
                count_even = count_even + 1;
                binary_SS_even(peaks_index_even(iii))=1;
            end
            if SS_peaks_even(iii) == 1 && SS_peaks_even(iii-1) == 1
                binary_SS_even(peaks_index_even(iii-1):peaks_index_even(iii))=1;
            end
        end


        %Secondary Classification, combine binaries
        app.binary_SS_secondary = binary_SS_odd+binary_SS_even;
        app.binary_SS_secondary(app.binary_SS_secondary>1)=1;

        %Secondary Classification
        count_secondary = 0;


        for iii = 2:length(app.binary_SS_secondary)
            if app.binary_SS_secondary(iii) == 1 && app.binary_SS_secondary(iii-1) == 0
                count_secondary = count_secondary + 1;
            end
        end


        %% Remove Spindles of Short Duration
%         minimum_duration = 600; % 0.294985251 seconds
% 
%         counter=0;
% 
%         % Primary Classification
%         for ii = 1:length(app.binary_SS_secondary)
%             % First Classification Method
%             if app.binary_SS_secondary(ii) == 1
%                 counter = counter+1;
%             else
%                 if counter < minimum_duration+1
%                     for c = 1:counter
%                         app.binary_SS_secondary(ii-c)=0;
%                     end
%                 end
%                 counter = 0;
%             end
%         end

        %% Plot EEG Data

        if length(SR)>1
            app.Time=(0:1/floor(SR(app.channel)):nSec-(1/floor(SR(app.channel))));
        else
            app.Time=(0:1/floor(SR):nSec-(1/floor(SR)));
        end

        % Raw
        hold(app.EEG_Window.RawAxis,"off")
        plot(app.EEG_Window.RawAxis,app.Time,s(1,:)) %child 9
        title(app.EEG_Window.RawAxis,'Raw')
        xlabel(app.EEG_Window.RawAxis,'Time(s)')
        xlim(app.EEG_Window.RawAxis,[0 nSec])
        app.EEG_Window.RawAxis.XTick = 0:floor(nSec/6):nSec;
        app.EEG_Window.RawAxis.XTickLabel = 0:floor(nSec/6):nSec;
        ylim_min = app.EEG_Window.RawAxis.YLim(1);
        ylim_max = app.EEG_Window.RawAxis.YLim(2);
        hold(app.EEG_Window.RawAxis,'on')
        area(app.EEG_Window.RawAxis,app.Time,app.binary_SS_secondary*ylim_max*2,"FaceAlpha",.5,'FaceColor',[.6 .6 .6],'EdgeColor','n')%child 7
        area(app.EEG_Window.RawAxis,app.Time,-app.binary_SS_secondary*ylim_max*2,"FaceAlpha",.5,'FaceColor',[.6 .6 .6],'EdgeColor','n')%child 6
        xline(app.EEG_Window.RawAxis,app.TimesSlider.Value,'r','LineWidth',2)%child 5
        area(app.EEG_Window.RawAxis,app.Time,app.binary_SS*ylim_max*2,"FaceAlpha",.5,'FaceColor','c','EdgeColor','n')%child 4
        area(app.EEG_Window.RawAxis,app.Time,-app.binary_SS*ylim_max*2,"FaceAlpha",.5,'FaceColor','c','EdgeColor','n')%child 3
        app.EEG_Window.RawAxis.YLim = [ylim_min ylim_max];
        area(app.EEG_Window.RawAxis,1:0.5:app.Window_size,zeros(1,(app.Window_size*2)-1)*ylim_max*2,"FaceAlpha",.5,'FaceColor','m','EdgeColor','n') %child 2
        area(app.EEG_Window.RawAxis,1:0.5:app.Window_size,-zeros(1,(app.Window_size*2)-1)*ylim_max*2,"FaceAlpha",.5,'FaceColor','m','EdgeColor','n') %child 1

        % Filtered Oscillatory Component
        hold(app.EEG_Window.FilterAxis,"off")
        plot(app.EEG_Window.FilterAxis,app.Time,Oscillatory_Component_bandpassFiltered(:,1)) %child 6
        hold(app.EEG_Window.FilterAxis,"on")
        title(app.EEG_Window.FilterAxis,'Filtered Oscillatory Component')
        xlabel(app.EEG_Window.FilterAxis,'Time(s)')
        %             xlim(app.EEG_Window.FilterAxis,[0 nSec])
        app.EEG_Window.FilterAxis.XTick = 0:floor(nSec/6):nSec;
        app.EEG_Window.FilterAxis.XTickLabel = 0:floor(nSec/6):nSec;
        ylim_min = app.EEG_Window.FilterAxis.YLim(1);
        ylim_max = app.EEG_Window.FilterAxis.YLim(2);
        area(app.EEG_Window.FilterAxis,app.Time,app.binary_SS_secondary*ylim_max*4,"FaceAlpha",.5,'FaceColor',[.6 .6 .6],'EdgeColor','n')%child 8
        area(app.EEG_Window.FilterAxis,app.Time,-app.binary_SS_secondary*ylim_max*4,"FaceAlpha",.5,'FaceColor',[.6 .6 .6],'EdgeColor','n')%child 7
        xline(app.EEG_Window.FilterAxis,app.TimesSlider.Value,'r','LineWidth',2) %child 5
        area(app.EEG_Window.FilterAxis,app.Time,app.binary_SS*ylim_max*4,"FaceAlpha",.5,'FaceColor','c','EdgeColor','n') %child 4
        area(app.EEG_Window.FilterAxis,app.Time,-app.binary_SS*ylim_max*4,"FaceAlpha",.5,'FaceColor','c','EdgeColor','n') %child 3
        app.EEG_Window.FilterAxis.YLim = [ylim_min ylim_max];
        area(app.EEG_Window.FilterAxis,1:0.5:app.Window_size,zeros(1,(app.Window_size*2)-1)*ylim_max*2,"FaceAlpha",.5,'FaceColor','m','EdgeColor','n') %child 2
        area(app.EEG_Window.FilterAxis,1:0.5:app.Window_size,-zeros(1,(app.Window_size*2)-1)*ylim_max*2,"FaceAlpha",.5,'FaceColor','m','EdgeColor','n') %child 1


        % Spindle and Quiescent Detection
        title(app.EEG_Window.PeakAxis,'Find Peak Envelope of Absolute Value of Filtered Oscillatory Component')
        xlabel(app.EEG_Window.PeakAxis,'Time(s)')
        app.EEG_Window.PeakAxis.XTick = 0:floor(nSec/6):nSec;
        app.EEG_Window.PeakAxis.XTickLabel = 0:floor(nSec/6):nSec;
        hold(app.EEG_Window.PeakAxis,'off')
        %             ylim_min = app.EEG_Window.PeakAxis.YLim(1);
        %             ylim_max = app.EEG_Window.PeakAxis.YLim(2);
        area(app.EEG_Window.PeakAxis,app.Time,app.binary_SS_secondary*ylim_max*4,"FaceAlpha",.5,'FaceColor',[.6 .6 .6],'EdgeColor','n')%child 7
        hold(app.EEG_Window.PeakAxis,'on')
        area(app.EEG_Window.PeakAxis,app.Time,-app.binary_SS_secondary*ylim_max*4,"FaceAlpha",.5,'FaceColor',[.6 .6 .6],'EdgeColor','n')%child 6
        area(app.EEG_Window.PeakAxis,app.Time(peaks_index),-SS_peaks*ylim_max*4,"FaceAlpha",.5,'FaceColor','c','EdgeColor','n') %child 5
        area(app.EEG_Window.PeakAxis,app.Time(peaks_index),SS_peaks*ylim_max*4,"FaceAlpha",.5,'FaceColor','c','EdgeColor','n') %child 4
        area(app.EEG_Window.PeakAxis,1:0.5:app.Window_size,zeros(1,(app.Window_size*2)-1)*ylim_max*2,"FaceAlpha",.5,'FaceColor','m','EdgeColor','n') %child 3
        plot(app.EEG_Window.PeakAxis,app.Time(peaks_index),peaks_value,'Color','k') %child 2
        xline(app.EEG_Window.PeakAxis,app.TimesEditField.Value,'r','LineWidth',2) %child 1
        app.EEG_Window.PeakAxis.YLim = [0 1.5*ylim_max];

%         Spindle_percentage = 100*(sum(app.binary_SS)/length(app.binary_SS));
%         Spindle_percentage_secondary = 100*(sum(app.binary_SS_secondary)/length(app.binary_SS_secondary));

        linkaxes([app.EEG_Window.RawAxis,app.EEG_Window.FilterAxis,app.EEG_Window.PeakAxis],'x');

        figure(app.SleepSpindleDetectorControllerUIFigure)
        figure(app.EEG_Window.SleepSpindleDetectorEEGWindowUIFigure)
        figure(app.Video_Window.SleepSpindleDetectorVideoWindowUIFigure)

        % Add notes

        app.TextArea.Value = ['filename: ' app.EEG_Filename];

        app.EEG_Window.SpindlecountLabel.Text = ['Primary Spindle count: ' num2str(count) ', Secondary Spindle count: ' num2str(count_secondary)];
          

        if ~isempty(app.v)
            AreaThresholdSliderValueChanged(app)
        end
        end
    end 

    % Callbacks that handle component events
    methods

        % Code that executes after component creation
        function startupFcn(app)
            app.Crop_Window = VideoCropper(app);
            app.Crop_Window.CropImageUIFigure.Visible = "off";
            
            app.SleepSpindleDetectorControllerUIFigure.Units = 'normalized';
            app.SleepSpindleDetectorControllerUIFigure.Position = [0.025 0.045 0.95 0.45];
            app.SleepSpindleDetectorControllerUIFigure.Units = 'pixels';

        end

        % Button pushed function: OpenEEGFile
        function OpenEEGFileButtonPushed(app, event)

            [filename, folder] = uigetfile('C:\*.edf');
            if ~ischar(filename); return; end   %user cancel
            [~,~,ext] = fileparts(filename);
            files = dir(fullfile(folder,['*' ext]));
            app.EEGFileDropDown.Items = {files.name};
            app.EEGFileDropDown.Value = filename;
            app.EEGFileDropDown.Enable = 'on';
            app.EEG_Filename = filename;
            app.EEG_folder = folder;
            
            app.TimesSlider.Enable = 'on';
            app.ZoomSlider.Enable = 'on';
            app.EpochSlider.Enable = 'on';
            app.TimesEditField.Enable = 'on';
            app.ZoomEditField.Enable = 'on';
            app.EpochEditField.Enable = 'on';
            app.TextArea.Enable = 'on';
            app.ChannelDropDown.Enable = 'on';
            app.PlayButton.Enable = 'on';
            
            app.LeftArrowTime.Enable = 'on';
            app.LeftArrowZoom.Enable = 'on';
            app.LeftArrowEpoch.Enable = 'on';
            app.RightArrowTime.Enable = 'on';
            app.RightArrowZoom.Enable = 'on';
            app.RightArrowEpoch.Enable = 'on';
            app.AnalyzeButton.Enable = 'on';
            app.AnalyzeMenu.Enable = 'on';
%             app.SaveProjectButton.Enable = 'on';
            
            OpenEEG(app)
        end

        % Value changed function: TimesSlider
        function TimesSliderValueChanged(app, event)
            app.TimesSlider.Value = round(app.TimesSlider.Value,1);
            app.TimesEditField.Value = app.TimesSlider.Value;

            %Raw
            app.EEG_Window.RawAxis.Children(5).Value = app.TimesSlider.Value;

            %Filtered Oscillatory Component
            app.EEG_Window.FilterAxis.Children(5).Value = app.TimesSlider.Value;

            %Spindle and Quiescent Detection
            app.EEG_Window.PeakAxis.Children(1).Value = app.TimesSlider.Value;

            if ~isempty(app.v)
                %% Update Video Window
                FS = app.v.FrameRate;

                %generate images

                if app.TimesSlider.Value > 1
                    Image_previous = rgb2gray(read(app.v,floor(FS*(app.TimesSlider.Value+(app.EpochSlider.Value-1)*app.Window_size-1/2)-FS*app.timedelay)));
                    Image_current = rgb2gray(read(app.v,floor(FS*(app.TimesSlider.Value+(app.EpochSlider.Value-1)*app.Window_size)-FS*app.timedelay)));
                    Image_diff = Image_current - Image_previous;
                    Image_diff_bw = im2bw(Image_diff,round(app.BinaryThresholdSlider.Value,2));

                    %crop?
                    if ~isempty(app.roi)
                        app.roi.Position = round(app.roi.Position);
                        ycrop = app.roi.Position(1):app.roi.Position(1)+app.roi.Position(3)-1;
                        xcrop = app.roi.Position(2):app.roi.Position(2)+app.roi.Position(4)-1;
                    else
                        xcrop = 1:size(Image_current,1);
                        ycrop = 1:size(Image_current,2);
                    end

                    %% Plot Video Data
                    imshow(Image_previous(xcrop,ycrop),'Parent',app.Video_Window.PrevSec_ax)
                    xlabel(app.Video_Window.PrevSec_ax,'')
                    ylabel(app.Video_Window.PrevSec_ax,'')
                    title(app.Video_Window.PrevSec_ax,'Previous Second')
                    imshow(Image_current(xcrop,ycrop),'Parent',app.Video_Window.CurSec_ax)
                    xlabel(app.Video_Window.CurSec_ax,'')
                    ylabel(app.Video_Window.CurSec_ax,'')
                    title(app.Video_Window.CurSec_ax,'Current Time')
                    imshow(Image_diff(xcrop,ycrop),'Parent',app.Video_Window.Difference_ax)
                    xlabel(app.Video_Window.Difference_ax,'')
                    ylabel(app.Video_Window.Difference_ax,'')
                    title(app.Video_Window.Difference_ax,'Difference')
                    imshow(Image_diff_bw(xcrop,ycrop),'Parent',app.Video_Window.Thresholded_ax)
                    xlabel(app.Video_Window.Thresholded_ax,'')
                    ylabel(app.Video_Window.Thresholded_ax,'')
                    title(app.Video_Window.Thresholded_ax,'Thresholded')
                    drawnow
                end
            end
        end

        % Value changing function: TimesSlider
        function TimesSliderValueChanging(app, event)
            changingValue = event.Value;

            %Raw
            app.EEG_Window.RawAxis.Children(5).Value = changingValue;

            %Filtered Oscillatory Component
            app.EEG_Window.FilterAxis.Children(5).Value = changingValue;
            
            %Spindle and Quiescent Detection
            app.EEG_Window.PeakAxis.Children(1).Value = changingValue;

        end

        % Value changed function: ZoomSlider
        function ZoomSliderValueChanged(app, event)
            if app.ZoomSlider.Value < 1

                %Raw
                app.EEG_Window.RawAxis.XLim(2) = round(app.Time(end));

                %Filtered Oscillatory Component
                app.EEG_Window.FilterAxis.XLim(2) = round(app.Time(end));

                %Filtered Oscillatory Component
                app.EEG_Window.PeakAxis.XLim(2) = round(app.Time(end));

            else

                %Raw
                app.EEG_Window.RawAxis.XLim(2) = round(app.Time(end))/app.ZoomSlider.Value;
                app.EEG_Window.RawAxis.XTick = 0:app.TimesSlider.Limits(2)/6/app.ZoomSlider.Value:app.TimesSlider.Limits(2);
                app.EEG_Window.RawAxis.XTickLabel = 0:app.TimesSlider.Limits(2)/6/app.ZoomSlider.Value:app.TimesSlider.Limits(2);

                %Filtered Oscillatory Component
                app.EEG_Window.FilterAxis.XLim(2) = round(app.Time(end))/app.ZoomSlider.Value;
                app.EEG_Window.FilterAxis.XTick = 0:app.TimesSlider.Limits(2)/6/app.ZoomSlider.Value:app.TimesSlider.Limits(2);
                app.EEG_Window.FilterAxis.XTickLabel = 0:app.TimesSlider.Limits(2)/6/app.ZoomSlider.Value:app.TimesSlider.Limits(2);

                %Filtered Oscillatory Component
                app.EEG_Window.PeakAxis.XLim(2) = round(app.Time(end))/app.ZoomSlider.Value;
                app.EEG_Window.PeakAxis.XTick = 0:app.TimesSlider.Limits(2)/6/app.ZoomSlider.Value:app.TimesSlider.Limits(2);
                app.EEG_Window.PeakAxis.XTickLabel = 0:app.TimesSlider.Limits(2)/6/app.ZoomSlider.Value:app.TimesSlider.Limits(2);
            end

            app.ZoomEditField.Value = app.ZoomSlider.Value;

            pan(app.EEG_Window.RawAxis,'xon')
            pan(app.EEG_Window.FilterAxis,'xon')
            pan(app.EEG_Window.PeakAxis,'xon')
        end

        % Value changing function: ZoomSlider
        function ZoomSliderValueChanging(app, event)
            changingValue = event.Value;
            if changingValue < 1

                %Raw
                app.EEG_Window.RawAxis.XLim(2) = round(app.Time(end));

                %Filtered Oscillatory Component
                app.EEG_Window.FilterAxis.XLim(2) = round(app.Time(end));

                %Filtered Oscillatory Component
                app.EEG_Window.PeakAxis.XLim(2) = round(app.Time(end));

            else

                %Raw
                app.EEG_Window.RawAxis.XLim(2) = round(app.Time(end))/changingValue;

                %Filtered Oscillatory Component
                app.EEG_Window.FilterAxis.XLim(2) = round(app.Time(end))/changingValue;

                %Filtered Oscillatory Component
                app.EEG_Window.PeakAxis.XLim(2) = round(app.Time(end))/changingValue;
            end

            app.ZoomEditField.Value = changingValue;

            pan(app.EEG_Window.RawAxis,'xon')
            pan(app.EEG_Window.FilterAxis,'xon')
            pan(app.EEG_Window.PeakAxis,'xon')
        end

        % Button pushed function: PlayButton
        function PlayButtonPushed(app, event)
            if app.PlayButton.Text == "Play"
                app.PlayButton.Text = "Stop";
                app.PlayButton.Icon = "IconEnd.png";
                app.Stop = 0;

                for ii = app.TimesSlider.Value:.1:app.TimesSlider.Limits(2)

                    app.TimesSlider.Value = ii;
                    app.TimesEditField.Value = ii;

                    %Raw
                    app.EEG_Window.RawAxis.Children(5).Value = app.TimesSlider.Value;

                    %Filtered Oscillatory Component
                    app.EEG_Window.FilterAxis.Children(5).Value = app.TimesSlider.Value;

                    %Spindle and Quiescent Detection
                    app.EEG_Window.PeakAxis.Children(1).Value = app.TimesSlider.Value;

                    drawnow

                    %Generate images
                    if ~isempty(app.v)
                        % Update Video Window
                        FS = app.v.FrameRate;
                        if app.TimesSlider.Value > 1
                            Image_previous = rgb2gray(read(app.v,floor(FS*(app.TimesSlider.Value+(app.EpochSlider.Value-1)*app.Window_size)-(FS/2)-FS*app.timedelay)));
                            Image_current = rgb2gray(read(app.v,floor(FS*(app.TimesSlider.Value+(app.EpochSlider.Value-1)*app.Window_size)-FS*app.timedelay)));
                            Image_diff = Image_current - Image_previous;
                            Image_diff_bw = im2bw(Image_diff,round(app.BinaryThresholdSlider.Value,2));

                            %crop?
                            if ~isempty(app.roi)
                                ycrop = app.roi.Position(1):app.roi.Position(1)+app.roi.Position(3)-1;
                                xcrop = app.roi.Position(2):app.roi.Position(2)+app.roi.Position(4)-1;
                            else
                                xcrop = 1:size(Image_current,1);
                                ycrop = 1:size(Image_current,2);
                            end

                            % Plot Video Data
                            imshow(Image_previous(xcrop,ycrop),'Parent',app.Video_Window.PrevSec_ax)
                            xlabel(app.Video_Window.PrevSec_ax,'')
                            ylabel(app.Video_Window.PrevSec_ax,'')
                            title(app.Video_Window.PrevSec_ax,'Previous Second')
                            imshow(Image_current(xcrop,ycrop),'Parent',app.Video_Window.CurSec_ax)
                            xlabel(app.Video_Window.CurSec_ax,'')
                            ylabel(app.Video_Window.CurSec_ax,'')
                            title(app.Video_Window.CurSec_ax,'Current Time')
                            imshow(Image_diff(xcrop,ycrop),'Parent',app.Video_Window.Difference_ax)
                            xlabel(app.Video_Window.Difference_ax,'')
                            ylabel(app.Video_Window.Difference_ax,'')
                            title(app.Video_Window.Difference_ax,'Difference')
                            imshow(Image_diff_bw(xcrop,ycrop),'Parent',app.Video_Window.Thresholded_ax)
                            xlabel(app.Video_Window.Thresholded_ax,'')
                            ylabel(app.Video_Window.Thresholded_ax,'')
                            title(app.Video_Window.Thresholded_ax,'Thresholded')
                            drawnow
                        end
                    end
                    if app.Stop == 1
                        app.Stop = 0;
                        break
                    end
                end
            else
                app.PlayButton.Text = "Play";
                app.PlayButton.Icon = "IconPlay.png";
                app.Stop = 1;
            end
        end

        % Button pushed function: AnalyzeButton
        function AnalyzeButtonPushed(app, event)
            % READ EDF
            app.HDR = EDFData(fullfile(app.EEG_folder,app.EEG_Filename));
            
            % Define Constraints
            SR = app.HDR.sf(app.channel);                % sample rate
            DurRec = floor(app.HDR.records*app.HDR.duration);   % Edf full duration record
            nSec = app.Window_size;                          % 100 second window
            epochs = floor(DurRec/nSec);       % number of iteration "Epochs"

            % Preallocate variables
            app.t=table;
            app.t.Epoch = (1:1:epochs)';
            app.t.SpindleCount = zeros(epochs,1);
            app.t.SpindleCount_secondary = zeros(epochs,1);
            app.t.Spindle_percentage = zeros(epochs,1);
            app.t.Spindle_percentage_secondary = zeros(epochs,1);
            app.t.Quiescent_percentage = zeros(epochs,1); 

            table2_type = [];
            table2_epoch = [];
            table2_epochdatapoint = [];
            table2_max_amplitude = [];
            table2_mean_amplitude = [];
            table2_median_amplitude = [];

            table3_type = [];
            table3_epoch = [];
            table3_epochdatapoint = [];
            table3_max_amplitude = [];
            table3_mean_amplitude = [];
            table3_median_amplitude = [];

%             med_freq = [];
%             time_med_freq = [];

            % Progress Bar
            d = uiprogressdlg(app.SleepSpindleDetectorControllerUIFigure,'Title','Analyzing All Data to Detect Sleep Spindles... Please Wait','Message','Analyzing...','Icon','SleepSpindleIconSmall.png');
            app.Primary_SS = [];
            app.Secondary_SS = [];
            app.QuiescentPeriod = [];

            for epoch = 1:1:epochs%epochs-

                %Load EEG epoch
                if length(SR)>1
                    stPos = round((epoch-1)*nSec*SR(app.channel));                                % starting Position
                    raw = app.HDR.getData([stPos+1 stPos+round(nSec*SR(app.channel))],app.channel); % reading the edf file starting from [stPos] for duration of [nSec]
                else
                    stPos = round((epoch-1)*nSec*SR);                                % starting Position
                    raw = app.HDR.getData([stPos+1 stPos+round(nSec*SR)],app.channel); % reading the edf file starting from [stPos] for duration of [nSec]
                end
                %% Normalize Raw EEG Data

                norm_Y = zeros(size(raw));
                for i = 1%:8
                    norm_Y(:,i) = (raw(:,i) - median(raw(:,i)))/(max(abs(raw(:,i) -median(raw(:,i)))));
                end
                raw=norm_Y;

                %% Run McSleep transient separation on EEG data given by Y

                if length(SR)>1
                time=(0:1/SR(app.channel):nSec-(1/SR(app.channel)));
                else
                time=(0:1/SR:nSec-(1/SR));
                end

                
                fs = floor(length(time)/(time(end)-time(1)));

                % Define operators for block low rank property
                H = @(x,s,k) Op_A(x,s,k);
                HT = @(x,s,k) Op_AT(x,s,k);


                % Define parameters
                if length(SR)>1
                    param = struct('lam1', .000000000000000000006, 'lam2',.007 ,'lam3',.001,'K',floor(SR(app.channel)),...  %.00006,.0007  .000728, 00009
                        'mu', 0.3,'O',floor(SR(app.channel))/2,'Nit',50); %8-7-2020 TAM KSH optimized lam1 = 0.00004, lam2 = 0.00003, lam3 = 0.001, mu = 0.3
                else
                    param = struct('lam1', .000000000000000000006, 'lam2',.007 ,'lam3',.001,'K',floor(SR),...  %.00006,.0007  .000728, 00009
                        'mu', 0.3,'O',floor(SR)/2,'Nit',50); %8-7-2020 TAM KSH optimized lam1 = 0.00004, lam2 = 0.00003, lam3 = 0.001, mu = 0.3
                end
                param.calculateCost = 1;

                if length(SR)>1
                % raw=raw(1:floor(SR(app.channel))*nSec,:); % uncomment if using processed signal with fractional Sample Rate
                else
                % raw=raw(1:floor(SR)*nSec,:); % uncomment if using processed signal with fractional Sample Rate
                end

                

                tic; [~,s,~] = mcsleep(raw', H, HT, param); toc

                %% Bandpass filter
                % Bandpass filter parameters
                params.f1 = 11;
                params.f2 = 17;
                params.filtOrder = 4;

                % Apply bandpass filter to oscillatory component
                fprintf('Applying bandpass filter to oscillatory component ... \n');
                [B,A] = cheby1(params.filtOrder,0.1,[params.f1 params.f2]/(fs/2)); %butter(params.filtOrder, [params.f1 params.f2]/(fs/2));
                Oscillatory_Component_bandpassFiltered = filtfilt(B,A,s');

                %% Find peaks

                % Primary Classifcation Method
                [peaks_value, peaks_index] = findpeaks(abs(Oscillatory_Component_bandpassFiltered(:,1)));

                % Secondary Classifcation Method (separate odd and even datapoints (peaks)
                peaks_value_odd = peaks_value(1:2:end,1);
                peaks_value_even = peaks_value(2:2:end,1);

                peaks_index_odd = peaks_index(1:2:end,1);
                peaks_index_even = peaks_index(2:2:end,1);

                %% Find Peaks of Peaks and filter for highest peaks

                % Primary Classification Method
                [peak_peaks_value, peak_peaks_index] = findpeaks(peaks_value);
                peak_peaks_value_filtered = peak_peaks_value/max(peak_peaks_value);

                % Secondary Classification Method

                % Odd Peak Peaks
                [peak_peaks_value_odd, peak_peaks_index_odd] = findpeaks(peaks_value_odd);
                peak_peaks_value_filtered_odd = peak_peaks_value_odd/max(peak_peaks_value_odd);

                % Even Peak Peaks
                [peak_peaks_value_even, peak_peaks_index_even] = findpeaks(peaks_value_even);
                peak_peaks_value_filtered_even = peak_peaks_value_even/max(peak_peaks_value_even);

                %% Detect Spindles

                % Primary Classification Method
                SS_peaks = Downhill(app,peaks_value,peaks_index, peak_peaks_index,peak_peaks_value_filtered);

                % Secondary Classification Method
                SS_peaks_odd = Downhill_secondary(app,peaks_value_odd,peaks_index, peak_peaks_index_odd,peak_peaks_value_filtered_odd);
                SS_peaks_even = Downhill_secondary(app,peaks_value_even,peaks_index, peak_peaks_index_even,peak_peaks_value_filtered_even);

                %% Remove Spindles of Short Duration
                minimum_duration = 10;

                counter=0;
                % Primary Classification
                for ii = 1:length(SS_peaks)
                    % First Classification Method
                    if SS_peaks(ii) == 1
                        counter = counter+1;
                    else
                        if counter < minimum_duration+1
                            for c = 1:counter
                                SS_peaks(ii-c)=0;
                            end
                        end
                        counter = 0;
                    end
                end

                % Secondary Classification (odd)
                minimum_duration = round(minimum_duration/2);
                counter=0;
                for ii = 1:length(SS_peaks_odd)
                    % Secondary Classification Method (odd)
                    if SS_peaks_odd(ii) == 1
                        counter = counter+1;
                    else
                        if counter < minimum_duration+1
                            for c = 1:counter
                                SS_peaks_odd(ii-c)=0;
                            end
                        end
                        counter = 0;
                    end
                end
                % Secondary Classification (even)
                counter=0;
                for ii = 1:length(SS_peaks_even)
                    % Secondary Classification Method (even)
                    if SS_peaks_even(ii) == 1
                        counter = counter+1;
                    else
                        if counter < minimum_duration+1
                            for c = 1:counter
                                SS_peaks_even(ii-c)=0;
                            end
                        end
                        counter = 0;
                    end
                end

                %% Curvefit for odd
                counter_odd=0;
                for ii = 1:length(SS_peaks_odd)
                    if SS_peaks_odd(ii) == 1
                        counter_odd = counter_odd+1;
                    else
                        if ii>1 && SS_peaks_odd(ii-1) == 1
                            odd_Spindle_Amplitude = zeros(counter_odd,1);
                            for c = 1:counter_odd
                                odd_Spindle_Amplitude(c) = peaks_value_odd(ii-c);
                            end
                            Data_Points=1:c;
                            try
                                [~, gof] = createFit(Data_Points(round(0.4*length(odd_Spindle_Amplitude)):round(0.6*length(odd_Spindle_Amplitude))), odd_Spindle_Amplitude(round(0.4*length(odd_Spindle_Amplitude)):round(0.6*length(odd_Spindle_Amplitude)))'); % Plot has been commented out in the function CreateFit
                            catch
                                [~, gof] = createFit(Data_Points, odd_Spindle_Amplitude'); % Plot has been commented out in the function CreateFit
                            end
                            % title(['Odd side of Spindle with a R Coefficient of ' num2str(gof.rsquare)])
                            if gof.rsquare < app.RThresholdEditField.Value
                                for c = 1:counter_odd
                                    SS_peaks_odd(ii-c)=0;
                                end
                            end
                        end
                        counter_odd = 0;
                    end
                end

                %% Curvefit for even
                counter_even=0;
                for ii = 1:length(SS_peaks_even)
                    if SS_peaks_even(ii) == 1
                        counter_even = counter_even+1;
                    else
                        if ii>1 && SS_peaks_even(ii-1) == 1
                            even_Spindle_Amplitude = zeros(counter_even,1);
                            for c = 1:counter_even
                                even_Spindle_Amplitude(c) = peaks_value_even(ii-c);
                            end
                            Data_Points=1:c;
                            try
                                [~, gof] = createFit(Data_Points(round(0.4*length(even_Spindle_Amplitude)):round(0.6*length(even_Spindle_Amplitude))), even_Spindle_Amplitude(round(0.4*length(even_Spindle_Amplitude)):round(0.6*length(even_Spindle_Amplitude)))'); % Plot has been commented out in the function CreateFit
                                %                         title(['Even side of Spindle with a R Coefficient of ' num2str(gof.rsquare)])
                            catch
                                disp(ii)
                                [~, gof] = createFit(Data_Points, even_Spindle_Amplitude'); % Plot has been commented out in the function CreateFit
                            end
                            if gof.rsquare < app.RThresholdEditField.Value
                                for c = 1:counter_even
                                    SS_peaks_even(ii-c)=0;
                                end
                            end
                        end
                        counter_even = 0;
                    end
                end

                % Merge odd and even peak datapoints back together
                %         SS_peaks_secondary(1:2:end)=SS_peaks_odd;
                %         SS_peaks_secondary(2:2:end)=SS_peaks_even;


                %% Convert logical spindle detection array from peak dimensions to datapoint (signal) dimensions
                % preallocate
                app.binary_SS = zeros(size(Oscillatory_Component_bandpassFiltered(:,1)));
                app.binary_SS_secondary = zeros(size(Oscillatory_Component_bandpassFiltered(:,1)));
                binary_SS_odd = zeros(size(Oscillatory_Component_bandpassFiltered(:,1)));
                binary_SS_even = zeros(size(Oscillatory_Component_bandpassFiltered(:,1)));


                % count number of sleep spindles
                count = 0;
                if peaks_index(1) == 1 && SS_peaks(1) == 1
                    count = count + 1;
                    app.binary_SS(1)= 1;
                end


                for iii = 2:length(peaks_index)
                    if SS_peaks(iii) == 1 && SS_peaks(iii-1) == 0  %detects 01, i.e. Start Point
                        count = count + 1;
                        app.binary_SS(peaks_index(iii))=1;
                        table2_type = [table2_type; "start time"];
                        table2_epoch = [table2_epoch; epoch];
                        table2_epochdatapoint = [table2_epochdatapoint; peaks_index(iii)];
                        table2_max_amplitude = [table2_max_amplitude;NaN];
                        table2_mean_amplitude = [table2_mean_amplitude;NaN];
                        table2_median_amplitude = [table2_median_amplitude;NaN];
                    end

                    if SS_peaks(iii) == 0 && SS_peaks(iii-1) == 1 && SS_peaks(iii-2) == 1 && table2_type(end)=="start time" %detects 110, i.e. End Point   %
                        table2_type = [table2_type; "end time"];
                        table2_epoch = [table2_epoch; epoch];
                        table2_epochdatapoint = [table2_epochdatapoint; peaks_index(iii)];
                        table2_max_amplitude = [table2_max_amplitude; max(abs(Oscillatory_Component_bandpassFiltered(table2_epochdatapoint(end-1):table2_epochdatapoint(end))))];
                        table2_mean_amplitude = [table2_mean_amplitude; mean(abs(Oscillatory_Component_bandpassFiltered(table2_epochdatapoint(end-1):table2_epochdatapoint(end))))];
                        table2_median_amplitude = [table2_median_amplitude; median(abs(Oscillatory_Component_bandpassFiltered(table2_epochdatapoint(end-1):table2_epochdatapoint(end))))];
                    end
                    if iii == length(peaks_index) && SS_peaks(iii) == 1 && SS_peaks(iii-1) == 1
                        table2_type = [table2_type; "end time"];
                        table2_epoch = [table2_epoch; epoch];
                        table2_epochdatapoint = [table2_epochdatapoint; peaks_index(iii)];
                        table2_max_amplitude = [table2_max_amplitude; max(abs(Oscillatory_Component_bandpassFiltered(table2_epochdatapoint(end-1):table2_epochdatapoint(end))))];
                        table2_mean_amplitude = [table2_mean_amplitude; mean(abs(Oscillatory_Component_bandpassFiltered(table2_epochdatapoint(end-1):table2_epochdatapoint(end))))];
                        table2_median_amplitude = [table2_median_amplitude; median(abs(Oscillatory_Component_bandpassFiltered(table2_epochdatapoint(end-1):table2_epochdatapoint(end))))];
                    elseif SS_peaks(iii) == 1 && SS_peaks(iii-1) == 1
                        app.binary_SS(peaks_index(iii-1):peaks_index(iii))=1;
                    end
                end
                % % %         %Secondary Classification
                %         count_secondary = 0;
                %
                %
                %         for iii = 2:length(app.binary_SS_secondary)
                %             if app.binary_SS_secondary(iii) == 1 && app.binary_SS_secondary(iii-1) == 0
                %                 count_secondary = count_secondary + 1;
                %             end
                %         end
                %
                %Secondary Classification odd
                count_odd = 0;
                if peaks_index_odd(1) == 1 && SS_peaks_odd(1) == 1
                    count_odd = count_odd + 1;
                    binary_SS_odd(1)= 1;
                end

                for iii = 2:length(peaks_index_odd)
                    if SS_peaks_odd(iii) == 1 && SS_peaks_odd(iii-1) == 0
                        count_odd = count_odd + 1;
                        binary_SS_odd(peaks_index_odd(iii))=1;
                    end
                    if SS_peaks_odd(iii) == 1 && SS_peaks_odd(iii-1) == 1
                        binary_SS_odd(peaks_index_odd(iii-1):peaks_index_odd(iii))=1;
                    end
                end

                %Secondary Classification even
                count_even = 0;
                if peaks_index_even(1) == 1 && SS_peaks_even(1) == 1
                    count_even = count_even + 1;
                    binary_SS_even(1)= 1;
                end

                for iii = 2:length(peaks_index_even)
                    if SS_peaks_even(iii) == 1 && SS_peaks_even(iii-1) == 0
                        count_even = count_even + 1;
                        binary_SS_even(peaks_index_even(iii))=1;
                    end
                    if SS_peaks_even(iii) == 1 && SS_peaks_even(iii-1) == 1
                        binary_SS_even(peaks_index_even(iii-1):peaks_index_even(iii))=1;
                    end
                end

                %Secondary Classification, combine binaries
                app.binary_SS_secondary = binary_SS_odd+binary_SS_even;
                app.binary_SS_secondary(app.binary_SS_secondary>1)=1;    

                %Secondary Classification
                count_secondary = 0;

                for iii = 2:length(app.binary_SS_secondary)
                    if app.binary_SS_secondary(iii) == 1 && app.binary_SS_secondary(iii-1) == 0  %detects 01, i.e. Start Point
                        count_secondary = count_secondary + 1;
                        table3_type = [table3_type; "start time"];
                        table3_epoch = [table3_epoch; epoch];
                        table3_epochdatapoint = [table3_epochdatapoint; iii];
                        table3_max_amplitude = [table3_max_amplitude;NaN];
                        table3_mean_amplitude = [table3_mean_amplitude;NaN];
                        table3_median_amplitude = [table3_median_amplitude;NaN];
                    end
                    if app.binary_SS_secondary(iii) == 0 && app.binary_SS_secondary(iii-1) == 1 && app.binary_SS_secondary(iii-2) == 1 && table3_type(end)=="start time" %detects 110, i.e. End Point
                        table3_type = [table3_type; "end time"];
                        table3_epoch = [table3_epoch; epoch];
                        table3_epochdatapoint = [table3_epochdatapoint; iii];
                        table3_max_amplitude = [table3_max_amplitude; max(abs(Oscillatory_Component_bandpassFiltered(table3_epochdatapoint(end-1):table3_epochdatapoint(end))))];
                        table3_mean_amplitude = [table3_mean_amplitude; mean(abs(Oscillatory_Component_bandpassFiltered(table3_epochdatapoint(end-1):table3_epochdatapoint(end))))];
                        table3_median_amplitude = [table3_median_amplitude; median(abs(Oscillatory_Component_bandpassFiltered(table3_epochdatapoint(end-1):table3_epochdatapoint(end))))];
                    end
                end



                %Progress bar epoch update
                d.Value = epoch/epochs;
                d.Message = ['Analyzing... epoch (' num2str(epoch) '/' num2str(epochs) ') ' num2str(100*epoch/epochs,"%.2f") '%'];

                if ~isempty(app.v)
                    FS = app.v.FrameRate;
                    segment = (FS/2)+1:FS/2:app.Window_size*FS;

                    %Preallocate
                    AreaofDifference = zeros(size(segment));

                    d_v = uiprogressdlg(app.Video_Window.SleepSpindleDetectorVideoWindowUIFigure,'Title','Detecting Sleep Segments... Please Wait','Message','Detecting Sleep Segments...','Icon','SleepSpindleIconSmall.png');
                    d_v.Message = ['Analyzing... epoch (0/' num2str(epochs) ') 0%'];

                    for i = segment

                        if i+(epoch-1)*app.Window_size*FS <= app.v.NumFrames
                            

                        rgb2gray(read(app.v,floor(FS*(app.TimesSlider.Value)-(FS/2))));
                        Image_previous = rgb2gray(read(app.v,floor(i-(FS/2)+(epoch-1)*app.Window_size*FS)));%-(floor(app.HDR.NRec*app.HDR.Dur)-(app.v.NumFrames/app.v.FrameRate)))));
                        Image_current = rgb2gray(read(app.v,floor(i+(epoch-1)*app.Window_size*FS)));%-(floor(app.HDR.NRec*app.HDR.Dur)-(app.v.NumFrames/app.v.FrameRate)))));
                        Image_diff = Image_current - Image_previous;
                        Image_diff_bw = im2bw(Image_diff,app.BinaryThresholdSlider.Value);

                        %crop?
                        if ~isempty(app.roi)
                            app.roi.Position = round(app.roi.Position);
                            ycrop = app.roi.Position(1):app.roi.Position(1)+app.roi.Position(3)-1;
                            xcrop = app.roi.Position(2):app.roi.Position(2)+app.roi.Position(4)-1;
                        else
                            xcrop = 1:size(Image_current,1);
                            ycrop = 1:size(Image_current,2);
                        end

                        AreaofDifference((i-1)/(FS/2)) = sum(sum(Image_diff_bw(xcrop,ycrop)));

                        else
                        AreaofDifference(((i-1)/(FS/2)):end)=[];
                        i = segment(end);
                        d_v.Value = i/(FS*app.Window_size);
                        d_v.Message = ['Analyzing... epoch (' num2str(epoch) '/' num2str(epochs) ') ' num2str(100*(i/(FS*app.Window_size))) '%'];
                            break
                           % AreaofDifference((i-1)/(FS/2)) = NaN; 
                        end
                        %Progress bar update
                        d_v.Value = i/(FS*app.Window_size);
                        d_v.Message = ['Analyzing... epoch (' num2str(epoch) '/' num2str(epochs) ') ' num2str(100*(i/(FS*app.Window_size))) '%'];
                    
                        
                    end
                    AreaofDifference(1)=AreaofDifference(2);
                    Area_med = smooth(AreaofDifference);

                    NoMovementDetected = zeros(size(Area_med));
                    NoMovementDetected(AreaofDifference<app.AreaThresholdSlider.Value)=1;

                    Quiescent_percentage = 100*(sum(NoMovementDetected)/length(NoMovementDetected));
                    app.t.Quiescent_percentage(epoch) = Quiescent_percentage;
                    close(d_v)

                    quiescentperiod(1:(1/2)*fs) = NaN;
                    for iii = 1:length(NoMovementDetected)%segment)
                        quiescentperiod((iii)*(1/2)*fs+1:(iii+1)*(1/2)*fs)=NoMovementDetected(iii);
                    end
                    
                    % Pad the array with 0s at both ends
                    binary_SS_padded = [0; app.binary_SS.*quiescentperiod'; 0];
                    % Find differences
                    dx = diff(binary_SS_padded);
                    % Count the transitions from 0 to 1
                    app.t.SpindleCount(epoch) = sum(dx == 1);

                    % Pad the array with 0s at both ends
                    binary_SS_secondary_padded = [0; app.binary_SS.*quiescentperiod'; 0];
                    % Find differences
                    dx = diff(binary_SS_secondary_padded);
                    % Count the transitions from 0 to 1
                    app.t.SpindleCount_secondary(epoch) = sum(dx == 1);

                    Spindle_percentage = 100*(sum(app.binary_SS.*quiescentperiod',1,'omitmissing')/length(app.binary_SS));
                    Spindle_percentage_secondary = 100*(sum(app.binary_SS_secondary.*quiescentperiod',1,'omitmissing')/length(app.binary_SS_secondary));

                    app.Primary_SS_raw = [app.Primary_SS; app.binary_SS];
                    app.Secondary_SS_raw = [app.Secondary_SS; app.binary_SS_secondary];
                    app.Primary_SS = [app.Primary_SS; app.binary_SS.*quiescentperiod'];
                    app.Secondary_SS = [app.Secondary_SS; app.binary_SS_secondary.*quiescentperiod'];

                    % app.QuiescentPeriod = [app.QuiescentPeriod; [NaN;NoMovementDetected]];
                    app.QuiescentPeriod = [app.QuiescentPeriod; quiescentperiod'];
                
                else
                    app.t.SpindleCount(epoch) = count;
                    app.t.SpindleCount_secondary(epoch) = count_secondary;
                    Spindle_percentage = 100*(sum(app.binary_SS)/length(app.binary_SS));
                    Spindle_percentage_secondary = 100*(sum(app.binary_SS_secondary)/length(app.binary_SS_secondary));

                    app.Primary_SS = [app.Primary_SS; app.binary_SS];
                    app.Secondary_SS = [app.Secondary_SS; app.binary_SS_secondary];
                end

                


                %                 app.t.Epoch(epoch) = epoch;
               
                app.t.Spindle_percentage(epoch) = Spindle_percentage;
                app.t.Spindle_percentage_secondary(epoch) = Spindle_percentage_secondary;
                
            end

            %Close progress bar
            close(d)         

            % ((length(segment)*epochs)/2)*fs+fs*app.Window_size/2;

            % Calculating values for Table 1
            average_SC = mean(app.t.SpindleCount,'omitnan');
            average_SC2 = mean(app.t.SpindleCount_secondary,'omitnan');
            average_SP = mean(app.t.Spindle_percentage,'omitnan');
            average_SP2 = mean(app.t.Spindle_percentage_secondary,'omitnan');
            average_QuiescentPercentage = mean(app.t.Quiescent_percentage,'omitnan');

            % Update Table 1 with data
            app.t = [app.t;{"Mean" average_SC average_SC2 average_SP average_SP2 average_QuiescentPercentage}];

            % Calculate values and Update Table 2 with data
            app.t2=table;
            app.t2.type = table2_type;
            app.t2.epoch = table2_epoch;
            app.t2.epochtime = table2_epochdatapoint;
            app.t2.time = app.t2.epoch*app.Window_size+app.t2.epochtime/app.HDR.sf(app.channel);
            app.t2.duration(2:2:length(app.t2.time)) = app.t2.time(2:2:end)-app.t2.time(1:2:end-1);
            app.t2.duration(1:2:length(app.t2.time)) = NaN;
            app.t2.max_amplitude = table2_max_amplitude;
            app.t2.mean_amplitude = table2_mean_amplitude;
            app.t2.median_amplitude = table2_median_amplitude;

            % Calculate values and Update Table 3 with data
            app.t3=table;
            app.t3.type = table3_type;
            app.t3.epoch = table3_epoch;
            app.t3.epochtime = table3_epochdatapoint;
            app.t3.time = app.t3.epoch*app.Window_size+app.t3.epochtime/app.HDR.sf(app.channel);
            app.t3.duration(2:2:length(app.t3.time)) = app.t3.time(2:2:end)-app.t3.time(1:2:end-1);
            app.t3.duration(1:2:length(app.t3.time)) = NaN;
            app.t3.max_amplitude = table3_max_amplitude;
            app.t3.mean_amplitude = table3_mean_amplitude;
            app.t3.median_amplitude = table3_median_amplitude;

            if ~isempty(app.v)
                test=app.t2.epochtime.*app.t2.epoch;
                for ii = length(test)-1:-2:1
                    if test(ii+1)-test(ii) <= sum(app.QuiescentPeriod(test(ii):test(ii+1)))

                    else
                        app.t2(ii:ii+1,:)=[];
                    end

                end

                test=app.t3.epochtime.*app.t3.epoch;
                for ii = length(test)-1:-2:1
                    if test(ii+1)-test(ii) <= sum(app.QuiescentPeriod(test(ii):test(ii+1)))

                    else
                        app.t3(ii:ii+1,:)=[];
                    end

                end
            end

            t2_mean_duration = mean(app.t2.duration,'omitnan');
            t2_std_duration = std(app.t2.duration,'omitnan');
            t2_median_duration = median(app.t2.duration,'omitnan');

            t3_mean_duration = mean(app.t3.duration,'omitnan');
            t3_std_duration = std(app.t3.duration,'omitnan');
            t3_median_duration = median(app.t3.duration,'omitnan');

            % Table 4
            app.t4=table;
            app.t4.Primary_Classification_mean_duration = t2_mean_duration;
            app.t4.Primary_Classification_std_duration = t2_std_duration;
            app.t4.Primary_Classification_median_duration = t2_median_duration;

            % Table 5
            app.t5=table;
            app.t5.Secondary_Classification_mean_duration = t3_mean_duration;
            app.t5.Secondary_Classification_std_duration = t3_std_duration;
            app.t5.Secondary_Classification_median_duration = t3_median_duration;

            % Display results
            app.Result_Window = SleepSpindleDetector_Results(app);
%             app.Result_Window.SleepSpindleDetectorResultsUIFigure.Visible = "on";
            
            % Summary Tab
            app.Result_Window.EpochSummaryUITable.Data = app.t;
            app.Result_Window.PrimaryUITable.Data = app.t4;
            app.Result_Window.SecondaryUITable.Data = app.t5;

            %
            app.Result_Window.PrimarySpecifics.Data = app.t2;
            app.Result_Window.SecondarySpecifics.Data = app.t3;

            % Binary & Statistics

            if isempty(app.v)
            app.Result_Window.BinaryUITable.Data = [app.Primary_SS,app.Secondary_SS];
            else
            app.Result_Window.BinaryUITable.Data = [app.Primary_SS_raw,app.Secondary_SS_raw,app.QuiescentPeriod,app.Primary_SS,app.Secondary_SS];
            app.Result_Window.BinaryUITable.ColumnName = {'Primary Raw','Secondary Raw','app.QuiescentPeriod','Primary','Secondary'};
            end
            
        end

        % Button pushed function: OpenVideoFile
        function OpenVideoFileButtonPushed(app, event)
            [app.Video_Filename, app.Video_folder] = uigetfile('C:\Users\kevinh\OneDrive - MathWorks\Documents\Development\SleepSpindleDetector\Internal\SleepSpindleDetector\Video Sample\*.avi');
            if ~ischar(app.Video_Filename); return; end   %user cancel
            [~,~,ext] = fileparts(app.Video_Filename);
            files = dir(fullfile(app.Video_folder,['*' ext]));
            app.VideoFileDropDown.Items = {files.name};
            app.VideoFileDropDown.Value = app.Video_Filename;
            app.VideoFileDropDown.Enable = 'on';
            
            app.TimesSlider.Enable = 'on';
            app.ZoomSlider.Enable = 'on';
            app.EpochSlider.Enable = 'on';
            app.TimesEditField.Enable = 'on';
            app.ZoomEditField.Enable = 'on';
            app.EpochEditField.Enable = 'on';
            app.TextArea.Enable = 'on';
            app.ChannelDropDown.Enable = 'on';
            app.PlayButton.Enable = 'on';

            app.AreaThresholdSlider.Enable = 'on';
            app.BinaryThresholdSlider.Enable = 'on';
            app.AreaThresholdEditField.Enable = 'on';
            app.BinaryThresholdEditField.Enable = 'on';
            
            app.LeftArrowArea.Enable = 'on';
            app.LeftArrowBinary.Enable = 'on';
            app.RightArrowArea.Enable = 'on';
            app.RightArrowBinary.Enable = 'on';
            app.CropImageMenu.Enable = 'on';
            
            app.Video_Window.PrevSec_ax.Visible = 'on';
            app.Video_Window.CurSec_ax.Visible = 'on';
            app.Video_Window.Difference_ax.Visible = 'on';
            app.Video_Window.Thresholded_ax.Visible = 'on';
            
            app.TimesSlider.Value = round(app.TimesSlider.Limits(2)/2);
            app.TimesEditField.Value = app.TimesSlider.Value;

            app.PlayButton.Enable = 'on';

            figure(app.SleepSpindleDetectorControllerUIFigure)
            figure(app.EEG_Window.SleepSpindleDetectorEEGWindowUIFigure)
            figure(app.Video_Window.SleepSpindleDetectorVideoWindowUIFigure)
            %% Read Video Data
            app.v = VideoReader(fullfile(app.Video_folder,app.Video_Filename));
            % datestr(v.CurrentTime/24/60/60,'hh:mm:ss')

            %Parameters
            FS = app.v.FrameRate;

            %Generate images
            Image_previous = rgb2gray(read(app.v,FS*app.TimesSlider.Value-(FS/2)));
            Image_current = rgb2gray(read(app.v,FS*app.TimesSlider.Value));
            Image_diff = Image_current - Image_previous;
            Image_diff_bw = im2bw(Image_diff,app.BinaryThresholdSlider.Value);

%             x = app.roi.Position(1):app.roi.Position(1)+app.roi.Position(3)-1;
%             y = app.roi.Position(2):app.roi.Position(2)+app.roi.Position(4)-1;

            %% Plot Video Data
            imshow(Image_previous,'Parent',app.Video_Window.PrevSec_ax)
            xlabel(app.Video_Window.PrevSec_ax,'')
            ylabel(app.Video_Window.PrevSec_ax,'')
            title(app.Video_Window.PrevSec_ax,'Previous Second')
            imshow(Image_current,'Parent',app.Video_Window.CurSec_ax)
            xlabel(app.Video_Window.CurSec_ax,'')
            ylabel(app.Video_Window.CurSec_ax,'')
            title(app.Video_Window.CurSec_ax,'Current Time')
            imshow(Image_diff,'Parent',app.Video_Window.Difference_ax)
            xlabel(app.Video_Window.Difference_ax,'')
            ylabel(app.Video_Window.Difference_ax,'')
            title(app.Video_Window.Difference_ax,'Difference')
            imshow(Image_diff_bw,'Parent',app.Video_Window.Thresholded_ax)
            xlabel(app.Video_Window.Thresholded_ax,'')
            ylabel(app.Video_Window.Thresholded_ax,'')
            title(app.Video_Window.Thresholded_ax,'Thresholded')

            if app.EpochSlider.Enable == 1
            AreaThresholdSliderValueChanged(app)
            end

%             app.AreaThresholdSlider.Enable = 'on';
%             app.BinaryThresholdSlider.Enable = 'on';
%             app.LeftArrowArea.Enable = 'on';
%             app.LeftArrowBinary.Enable = 'on';
%             app.RightArrowArea.Enable = 'on';
%             app.RightArrowBinary.Enable = 'on';
        end

        % Value changed function: EpochSlider
        function EpochSliderValueChanged(app, event)
            value = round(app.EpochSlider.Value,0);

            app.EpochEditField.Value = value;

            if ~isempty(app.EEG_Filename)
                OpenEEG(app)
            end
            figure(app.SleepSpindleDetectorControllerUIFigure)
            figure(app.EEG_Window.SleepSpindleDetectorEEGWindowUIFigure)
            figure(app.Video_Window.SleepSpindleDetectorVideoWindowUIFigure)

%             app.EEG_Window.SpindlecountLabel.Text = ['Spindle count: ' num2str(count)];
%             app.EEG_Window.SpindlecountLabel.Text = ['Primary Spindle count: ' num2str(count) ', Secondary Spindle count: ' num2str(count_secondary)];
            if ~isempty(app.v)
            %% Update Video Window

            % Read Video Data

            FS = app.v.FrameRate;

            app.TimesSlider.Value = round(app.TimesSlider.Value,1);
%             app.TimesSliderLabel.Text = ['Time: ' num2str(round(app.TimesSlider.Value,1)) ' s'];
%             app.EpochSlider.Value

            %generate images

            if app.TimesSlider.Value > 1

                Image_previous = rgb2gray(read(app.v,floor(FS*(app.TimesSlider.Value+(value-1)*app.Window_size)-(FS/2)-FS*app.timedelay)));
                Image_current = rgb2gray(read(app.v,floor(FS*(app.TimesSlider.Value+(value-1)*app.Window_size)-FS*app.timedelay)));
                Image_diff = Image_current - Image_previous;
                Image_diff_bw = im2bw(Image_diff,round(app.BinaryThresholdSlider.Value,2));


                %crop?
                    if ~isempty(app.roi)
                        ycrop = app.roi.Position(1):app.roi.Position(1)+app.roi.Position(3)-1;
                        xcrop = app.roi.Position(2):app.roi.Position(2)+app.roi.Position(4)-1;
                    else
                        xcrop = 1:size(Image_current,1);
                        ycrop = 1:size(Image_current,2);
                    end

                    %% Plot Video Data
                    imshow(Image_previous(xcrop,ycrop),'Parent',app.Video_Window.PrevSec_ax)
                    xlabel(app.Video_Window.PrevSec_ax,'')
                    ylabel(app.Video_Window.PrevSec_ax,'')
                    title(app.Video_Window.PrevSec_ax,'Previous Second')
                    imshow(Image_current(xcrop,ycrop),'Parent',app.Video_Window.CurSec_ax)
                    xlabel(app.Video_Window.CurSec_ax,'')
                    ylabel(app.Video_Window.CurSec_ax,'')
                    title(app.Video_Window.CurSec_ax,'Current Time')
                    imshow(Image_diff(xcrop,ycrop),'Parent',app.Video_Window.Difference_ax)
                    xlabel(app.Video_Window.Difference_ax,'')
                    ylabel(app.Video_Window.Difference_ax,'')
                    title(app.Video_Window.Difference_ax,'Difference')
                    imshow(Image_diff_bw(xcrop,ycrop),'Parent',app.Video_Window.Thresholded_ax)
                    xlabel(app.Video_Window.Thresholded_ax,'')
                    ylabel(app.Video_Window.Thresholded_ax,'')
                    title(app.Video_Window.Thresholded_ax,'Thresholded')
                    drawnow
            end
            end
        end

        % Close request function: SleepSpindleDetectorControllerUIFigure
        function SleepSpindleDetectorControllerUIFigureCloseRequest(app, event)
            close all
            delete(app)           
        end

        % Value changed function: BinaryThresholdSlider
        function BinaryThresholdSliderValueChanged(app, event)
            AreaThresholdSliderValueChanged(app)

        end

        % Value changed function: AreaThresholdSlider
        function AreaThresholdSliderValueChanged(app, event)
            app.AreaThresholdSlider.Enable = 'off';
            app.BinaryThresholdSlider.Enable = 'off';
            app.LeftArrowArea.Enable = 'off';
            app.LeftArrowBinary.Enable = 'off';
            app.RightArrowArea.Enable = 'off';
            app.RightArrowBinary.Enable = 'off';

            FS = app.v.FrameRate;

            app.BinaryThresholdSlider.Value = round(app.BinaryThresholdSlider.Value,2);
%             app.BinaryThresholdLabel.Text = ['Binary Threshold: ' num2str(round(app.BinaryThresholdSlider.Value,2))];
            app.BinaryThresholdEditField.Value = app.BinaryThresholdSlider.Value;

            app.AreaThresholdSlider.Value = round(app.AreaThresholdSlider.Value,0);
%             app.AreaThresholdLabel.Text = ['Area Threshold: ' num2str(round(app.AreaThresholdSlider.Value,0))];
            app.AreaThresholdEditField.Value = app.AreaThresholdSlider.Value;

            if app.TimesSlider.Value > 1

                Image_previous = rgb2gray(read(app.v,floor(FS*(app.TimesSlider.Value+(app.EpochSlider.Value-1)*app.Window_size-1/2)-FS*app.timedelay)));
                Image_current = rgb2gray(read(app.v,floor(FS*(app.TimesSlider.Value+(app.EpochSlider.Value-1)*app.Window_size)-FS*app.timedelay)));
                Image_diff = Image_current - Image_previous;
                Image_diff_bw = im2bw(Image_diff,round(app.BinaryThresholdSlider.Value,2));

                %crop?
                if ~isempty(app.roi)
                    ycrop = round(app.roi.Position(1):app.roi.Position(1)+app.roi.Position(3)-1);
                    xcrop = round(app.roi.Position(2):app.roi.Position(2)+app.roi.Position(4)-1);
                else
                    xcrop = 1:size(Image_current,1);
                    ycrop = 1:size(Image_current,2);
                end

                %% Plot Video Data
                imshow(Image_previous(xcrop,ycrop),'Parent',app.Video_Window.PrevSec_ax)
                xlabel(app.Video_Window.PrevSec_ax,'')
                ylabel(app.Video_Window.PrevSec_ax,'')
                title(app.Video_Window.PrevSec_ax,'Previous Second')
                imshow(Image_current(xcrop,ycrop),'Parent',app.Video_Window.CurSec_ax)
                xlabel(app.Video_Window.CurSec_ax,'')
                ylabel(app.Video_Window.CurSec_ax,'')
                title(app.Video_Window.CurSec_ax,'Current Time')
                imshow(Image_diff(xcrop,ycrop),'Parent',app.Video_Window.Difference_ax)
                xlabel(app.Video_Window.Difference_ax,'')
                ylabel(app.Video_Window.Difference_ax,'')
                title(app.Video_Window.Difference_ax,'Difference')
                imshow(Image_diff_bw(xcrop,ycrop),'Parent',app.Video_Window.Thresholded_ax)
                xlabel(app.Video_Window.Thresholded_ax,'')
                ylabel(app.Video_Window.Thresholded_ax,'')
                title(app.Video_Window.Thresholded_ax,'Thresholded')
                drawnow

                %% Quiescent Period Detection

                if ~isempty(app.EEG_Filename)
                segment = (FS/2)+1:FS/2:app.Window_size*FS;

                %Preallocate
                AreaofDifference = zeros(size(segment));

                %Progress bar
                d = uiprogressdlg(app.SleepSpindleDetectorControllerUIFigure,'Title','Analyzing Sleep Detection Please Wait','Message','Analyzing...','Icon','SleepSpindleIconSmall.png');

                for i = segment

                    Image_previous = rgb2gray(read(app.v,floor(i-(FS/2)+FS*(app.EpochSlider.Value-1)*app.Window_size-FS*app.timedelay)));% time delay adjustment, could use (floor((app.HDR.NRec*app.HDR.Dur)-(app.v.NumFrames/app.v.FrameRate))) 
                    Image_current = rgb2gray(read(app.v,floor(i+FS*(app.EpochSlider.Value-1)*app.Window_size-FS*app.timedelay))); % time delay adjustment, could use (floor((app.HDR.NRec*app.HDR.Dur)-(app.v.NumFrames/app.v.FrameRate))) 
                    Image_diff = Image_current - Image_previous;
                    Image_diff_bw = im2bw(Image_diff,app.BinaryThresholdSlider.Value);


                    %crop?
                    if ~isempty(app.roi)
                        ycrop = app.roi.Position(1):app.roi.Position(1)+app.roi.Position(3)-1;
                        xcrop = app.roi.Position(2):app.roi.Position(2)+app.roi.Position(4)-1;
                    else
                        xcrop = 1:size(Image_current,1);
                        ycrop = 1:size(Image_current,2);
                    end

                    AreaofDifference((i-1)/(FS/2)) = sum(sum(Image_diff_bw(xcrop,ycrop)));

                    %Progress bar update
                    d.Value = i/(FS*app.Window_size);
                    d.Message = ['Analyzing...' num2str(100*(i/(FS*app.Window_size))) '%'];
                end

                %Close Progress bar
                close(d)

                AreaofDifference(1)=AreaofDifference(2);
                Area_med = smooth(AreaofDifference);

                NoMovementDetected = zeros(size(Area_med));
                NoMovementDetected(AreaofDifference<app.AreaThresholdSlider.Value)=1;

%                 disp('Analyzing...')

                QuiescentDetection = zeros(size(1,length(NoMovementDetected)));

                for jjj = 5:length(NoMovementDetected)
                    if NoMovementDetected(jjj) == 0
                        QuiescentDetection(jjj) = 0;
                    elseif NoMovementDetected(jjj-1) == 0
                        QuiescentDetection(jjj) = 0;
                    elseif NoMovementDetected(jjj-2) == 0
                        QuiescentDetection(jjj) = 0;
                    elseif NoMovementDetected(jjj-3) == 0
                        QuiescentDetection(jjj) = 0;
                    elseif NoMovementDetected(jjj-4) == 0
                        QuiescentDetection(jjj) = 0;
                    else
                        QuiescentDetection(jjj)=1;
                    end
                end


                count = 0;
                for jjj = 1:length(QuiescentDetection)
                    if QuiescentDetection(jjj) == 1
                        count = count+1;
                    else
                        if count<31
                            for jjjj = 1:count
                                QuiescentDetection(jjj-jjjj)=0;
                            end
                            count=0;
                        else
                            count=0;
                        end
                    end
                end

                % figure
                % subplot(2,1,1)
                % plot(Area_med)
                % subplot(2,1,2)
                % plot(QuiescentDetection)

                %Update Quiescent Detection Area Graphs

                %Raw Axis
                ylim_max = app.EEG_Window.RawAxis.YLim(2);
                app.EEG_Window.RawAxis.Children(1).YData = -QuiescentDetection*ylim_max*200;
                app.EEG_Window.RawAxis.Children(2).YData = QuiescentDetection*ylim_max*200;

                %Filter Axis
                ylim_max = app.EEG_Window.FilterAxis.YLim(2);
                app.EEG_Window.FilterAxis.Children(1).YData = -QuiescentDetection*ylim_max*200;
                app.EEG_Window.FilterAxis.Children(2).YData = QuiescentDetection*ylim_max*200;

                %Peak Axis
                ylim_max = app.EEG_Window.PeakAxis.YLim(2);
                app.EEG_Window.PeakAxis.Children(3).YData = QuiescentDetection*ylim_max*200;
                end
            end
            % app.EEG_Window.FilterAxis.YLim = [ylim_min ylim_max];


            % ylim_min = app.EEG_Window.FilterAxis.YLim(1);
            %FS/2
            % area(app.EEG_Window.FilterAxis,1:0.5:app.Window_size,QuiescentDetection*ylim_max*2,'FaceAlpha',0.5,'FaceColor','m','EdgeColor','none')

            app.AreaThresholdSlider.Enable = 'on';
            app.BinaryThresholdSlider.Enable = 'on';
            app.LeftArrowArea.Enable = 'on';
            app.LeftArrowBinary.Enable = 'on';
            app.RightArrowArea.Enable = 'on';
            app.RightArrowBinary.Enable = 'on';

        end

        % Value changed function: ChannelDropDown
        function ChannelDropDownValueChanged(app, event)
            Index = ismember(app.ChannelDropDown.Items, {app.ChannelDropDown.Value});
            items = 1:length(Index);
            app.channel = items(Index);
            
            %% Update EEG Window
            % READ EDF
            app.HDR = EDFData(fullfile(app.EEG_folder,app.EEG_Filename));
            
            % Define Constraints
            SR = app.HDR.sf(app.channel);                % sample rate
            DurRec = floor(app.HDR.records*app.HDR.duration);   % Edf full duration record
            nSec = app.Window_size;                          % 100 second window
            epochs = floor(DurRec/nSec);       % number of iteration "Epochs"

            %Update Epoch Slider
            app.EpochSlider.Limits(2) = epochs;
            app.TimesSlider.Limits(2) = nSec;
%             app.TimesSlider.MinorTicks = 0:0.5:nSec;

            %Load EEG epoch
            stPos = round((app.EpochSlider.Value-1)*nSec*SR);                                % starting Position
            raw = app.HDR.getData([stPos+1 stPos+round(nSec*SR)],app.channel); % reading the edf file starting from [stPos] for duration of [nSec]

            %% Normalize Raw EEG Data

            norm_Y = zeros(size(raw));
            for i = 1%:8
                norm_Y(:,i) = (raw(:,i) - median(raw(:,i)))/(max(abs(raw(:,i) -median(raw(:,i)))));
            end
            raw=norm_Y;

            %% Run McSleep transient separation on EEG data given by Y

            if length(SR)>1
                time=(0:1/SR(app.channel):nSec-(1/SR(app.channel)));
            else
                time=(0:1/SR:nSec-(1/SR));
            end

         
            fs = floor(length(time)/(time(end)-time(1)));

            % Define operators for block low rank property
            H = @(x,s,k) Op_A(x,s,k);
            HT = @(x,s,k) Op_AT(x,s,k);

            % Define parameters
            if length(SR)>1
                param = struct('lam1', .000000000000000000006, 'lam2',.007 ,'lam3',.001,'K',floor(SR(app.channel)),...  %.00006,.0007  .000728, 00009
                    'mu', 0.3,'O',floor(SR(app.channel))/2,'Nit',50); %8-7-2020 TAM KSH optimized lam1 = 0.00004, lam2 = 0.00003, lam3 = 0.001, mu = 0.3
            else
                param = struct('lam1', .000000000000000000006, 'lam2',.007 ,'lam3',.001,'K',floor(SR),...  %.00006,.0007  .000728, 00009
                    'mu', 0.3,'O',floor(SR)/2,'Nit',50); %8-7-2020 TAM KSH optimized lam1 = 0.00004, lam2 = 0.00003, lam3 = 0.001, mu = 0.3
            end
            param.calculateCost = 1;

            if length(SR)>1
                % raw=raw(1:floor(SR(app.channel))*nSec,:); % comment out if using processed signal with fractional Sample Rate
            else
                % raw=raw(1:floor(SR)*nSec,:); % comment out if using processed signal with fractional Sample Rate
            end
            tic; [~,s,~] = mcsleep(raw', H, HT, param); toc

            %% Bandpass filter
            % Bandpass filter parameters
            params.f1 = 11; %11;
            params.f2 = 17; %17;
            params.filtOrder = 4;

            % Apply bandpass filter to oscillatory component
            fprintf('Applying bandpass filter to oscillatory component ... \n');
            [B,A] = cheby1(params.filtOrder,0.1,[params.f1 params.f2]/(fs/2)); %butter(params.filtOrder, [params.f1 params.f2]/(fs/2));
            Oscillatory_Component_bandpassFiltered = filtfilt(B,A,s');

            % % %% Teager Analysis
            % % %preallocate
            % % spindles = zeros(size(Oscillartory_Component_bandpassFiltered));
            % % envelopeSpindle = zeros(size(Oscillartory_Component_bandpassFiltered,1)-1,size(Oscillartory_Component_bandpassFiltered,2));
            % % % binary = zeros(size(bandpassFiltered,1)-1,size(bandpassFiltered,2));
            % %
            % % for chan = 1:8
            % % % Apply Teager Operator and get the envelope
            % % fprintf('Evaluating envelope of bandpass filtered signal ... \n');
            % % % envelopeSpindle = T(mean(bandpassFiltered,2));
            % % envelopeSpindle(:,chan) = T(Oscillartory_Component_bandpassFiltered(:,chan));
            % % end

            %% Find peaks

            % Primary Classifcation Method
            [peaks_value, peaks_index] = findpeaks(abs(Oscillatory_Component_bandpassFiltered(:,1)));

            % Secondary Classifcation Method (separate odd and even datapoints (peaks)
            peaks_value_odd = peaks_value(1:2:end,1);
            peaks_value_even = peaks_value(2:2:end,1);

            peaks_index_odd = peaks_index(1:2:end,1);
            peaks_index_even = peaks_index(2:2:end,1);

            %% Find Peaks of Peaks and filter for highest peaks

            % Primary Classification Method
            [peak_peaks_value, peak_peaks_index] = findpeaks(peaks_value);
            peak_peaks_value_filtered = peak_peaks_value/max(peak_peaks_value);
%             peak_peaks_value_filtered(peak_peaks_value_filtered<0.5)=0;

            % Secondary Classification Method

            % Odd Peak Peaks
            [peak_peaks_value_odd, peak_peaks_index_odd] = findpeaks(peaks_value_odd);
            peak_peaks_value_filtered_odd = peak_peaks_value_odd/max(peak_peaks_value_odd);
%             peak_peaks_value_filtered_odd(peak_peaks_value_filtered_odd<0.5)=0;

            % Even Peak Peaks
            [peak_peaks_value_even, peak_peaks_index_even] = findpeaks(peaks_value_even);
            peak_peaks_value_filtered_even = peak_peaks_value_even/max(peak_peaks_value_even);
%             peak_peaks_value_filtered_even(peak_peaks_value_filtered_even<0.5)=0;

            %% Detect Spindles

            % Primary Classification Method

                % Preallocate variables
                counter = 0;
                SS_peaks = zeros(size(peaks_value));

                % For loops through the highest peaks
                for ii = 1:length(peak_peaks_value_filtered)
                    if peak_peaks_value_filtered(ii)>0.5
                        SS_peaks(peak_peaks_index(ii))=1;
                        for iii = 1:30 %change number based on longest possible spindle duration
                            if peaks_index(peak_peaks_index(ii))+iii*10/2>length(app.binary_SS) %out of bounds to the right
                                break
                            else
                                if peak_peaks_index(ii) == iii %out of bounds to the left
                                    break
                                else
                                    % right < point && left < point
                                    if peaks_value(peak_peaks_index(ii)+iii)<peaks_value(peak_peaks_index(ii)+(iii-1)) && peaks_value(peak_peaks_index(ii)-iii)<peaks_value(peak_peaks_index(ii)-(iii-1))
                                        SS_peaks(peak_peaks_index(ii)+iii)=1;
                                        SS_peaks(peak_peaks_index(ii)-iii)=1;
                                    else
                                        counter = counter+1;
                                        SS_peaks(peak_peaks_index(ii)+iii)=0;
                                        SS_peaks(peak_peaks_index(ii)-iii)=0;
                                        if counter > 1
                                            SS_peaks(peak_peaks_index(ii)+iii)=0;
                                            SS_peaks(peak_peaks_index(ii)-iii)=0;
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                % Remove Spindles of Short Duration
                minimum_duration = 10;
    
                counter=0;
                
                % Primary Classification
                for ii = 1:length(SS_peaks)
                    % First Classification Method
                    if SS_peaks(ii) == 1
                        counter = counter+1;
                    else
                        if counter < minimum_duration+1
                            for c = 1:counter
                                SS_peaks(ii-c)=0;
                            end
                        end
                        counter = 0;
                    end
                end

          % Secondary Classification Method

                % Preallocate
%                 SS_peaks_secondary = zeros(size(peaks_value));
                SS_peaks_odd = zeros(size(peaks_value_odd));
                SS_peaks_even = zeros(size(peaks_value_even));
                
                % Secondary Classification Odd
                % For loops through the highest odd peaks
                counter = 0;
                for ii = 1:length(peak_peaks_value_filtered_odd)
                    if peak_peaks_value_filtered_odd(ii)>0.5
                        SS_peaks_odd(peak_peaks_index_odd(ii))=1;
                        for iii = 1:30 %change number based on longest possible spindle duration
                            if peaks_index(peak_peaks_index_odd(ii)*2)+iii*10/2>length(app.binary_SS)%  || peak_peaks_index_odd(ii)+iii<=length(peaks_value_odd) %out of bounds to the right
                                break
                            else
                                if peak_peaks_index_odd(ii) == iii %out of bounds to the left
                                    break
                                else
                                    % right < point && left < point
                                    if peaks_value_odd(peak_peaks_index_odd(ii)+iii)<peaks_value_odd(peak_peaks_index_odd(ii)+(iii-1)) && peaks_value_odd(peak_peaks_index_odd(ii)-iii)<peaks_value_odd(peak_peaks_index_odd(ii)-(iii-1))
                                        SS_peaks_odd(peak_peaks_index_odd(ii)+iii)=1;
                                        SS_peaks_odd(peak_peaks_index_odd(ii)-iii)=1;
                                    else
                                        counter = counter+1;
                                        SS_peaks_odd(peak_peaks_index_odd(ii)+iii)=0;
                                        SS_peaks_odd(peak_peaks_index_odd(ii)-iii)=0;
                                        if counter > 1
                                            SS_peaks_odd(peak_peaks_index_odd(ii)+iii)=0;
                                            SS_peaks_odd(peak_peaks_index_odd(ii)-iii)=0;
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                % Secondary Classification Even
                % For loops through the highest even peaks
                counter = 0;
                for ii = 1:length(peak_peaks_value_filtered_even)
                    if peak_peaks_value_filtered_even(ii)>0.5
                        SS_peaks_even(peak_peaks_index_even(ii))=1;
                        for iii = 1:30 %change number based on longest possible spindle duration
                            if peaks_index(peak_peaks_index_even(ii)*2)+iii*10/2>length(app.binary_SS)%  || peak_peaks_index_even(ii)+iii<=length(peaks_value_even) %out of bounds to the right
                                break
                            else
                                if peak_peaks_index_even(ii) == iii %out of bounds to the left
                                    break
                                else
                                    % right < point && left < point
                                    if peaks_value_even(peak_peaks_index_even(ii)+iii)<peaks_value_even(peak_peaks_index_even(ii)+(iii-1)) && peaks_value_even(peak_peaks_index_even(ii)-iii)<peaks_value_even(peak_peaks_index_even(ii)-(iii-1))
                                        SS_peaks_even(peak_peaks_index_even(ii)+iii)=1;
                                        SS_peaks_even(peak_peaks_index_even(ii)-iii)=1;
                                    else
                                        counter = counter+1;
                                        SS_peaks_even(peak_peaks_index_even(ii)+iii)=0;
                                        SS_peaks_even(peak_peaks_index_even(ii)-iii)=0;
                                        if counter > 1
                                            SS_peaks_even(peak_peaks_index_even(ii)+iii)=0;
                                            SS_peaks_even(peak_peaks_index_even(ii)-iii)=0;
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

            % Remove Spindles of Short Duration
            minimum_duration = round(minimum_duration/2);

            % Secondary Classification (odd)
            counter=0;
            for ii = 1:length(SS_peaks_odd)
                % Secondary Classification Method (odd)
                if SS_peaks_odd(ii) == 1
                    counter = counter+1;
                else
                    if counter < minimum_duration+1
                        for c = 1:counter
                            SS_peaks_odd(ii-c)=0;
                        end
                    end
                    counter = 0;
                end
            end
            % Secondary Classification (even)
            counter=0;
            for ii = 1:length(SS_peaks_even)
                % Secondary Classification Method (even)
                if SS_peaks_even(ii) == 1
                    counter = counter+1;
                else
                    if counter < minimum_duration+1
                        for c = 1:counter
                            SS_peaks_even(ii-c)=0;
                        end
                    end
                    counter = 0;
                end
            end

            % Curvefit for odd
            counter_odd=0;
            for ii = 1:length(SS_peaks_odd)
                if SS_peaks_odd(ii) == 1
                    counter_odd = counter_odd+1;
                else
                    if ii>1 && SS_peaks_odd(ii-1) == 1
                        odd_Spindle_Amplitude = zeros(counter_odd,1);
                        for c = 1:counter_odd
                            odd_Spindle_Amplitude(c) = peaks_value_odd(ii-c);
                        end
                        Data_Points=1:c;
                        [~, gof] = createFit(Data_Points(round(0.4*length(odd_Spindle_Amplitude)):round(0.6*length(odd_Spindle_Amplitude))), odd_Spindle_Amplitude(round(0.4*length(odd_Spindle_Amplitude)):round(0.6*length(odd_Spindle_Amplitude)))'); % Plot has been commented out in the function CreateFit
%                         title(['Odd side of Spindle with a R Coefficient of ' num2str(gof.rsquare)])
                        if gof.rsquare < app.RThresholdEditField.Value
                            for c = 1:counter_odd
                                SS_peaks_odd(ii-c)=0;
                            end
                        end
                    end
                    counter_odd = 0;
                end
            end

            % Curvefit for even
            counter_even=0;
            for ii = 1:length(SS_peaks_even)
                if SS_peaks_even(ii) == 1
                    counter_even = counter_even+1;
                else
                    if ii>1 && SS_peaks_even(ii-1) == 1
                        even_Spindle_Amplitude = zeros(counter_even,1);
                        for c = 1:counter_even
                            even_Spindle_Amplitude(c) = peaks_value_even(ii-c);
                        end
                        Data_Points=1:c;
                        [~, gof] = createFit(Data_Points(round(0.4*length(even_Spindle_Amplitude)):round(0.6*length(even_Spindle_Amplitude))), even_Spindle_Amplitude(round(0.4*length(even_Spindle_Amplitude)):round(0.6*length(even_Spindle_Amplitude)))'); % Plot has been commented out in the function CreateFit
%                         title(['Even side of Spindle with a R Coefficient of ' num2str(gof.rsquare)])
                        if gof.rsquare < app.RThresholdEditField.Value
                            for c = 1:counter_even
                                SS_peaks_even(ii-c)=0;
                            end
                        end
                    end
                    counter_even = 0;
                end
            end

            % Merge odd and even peak datapoints back together
%             SS_peaks_secondary(1:2:end)=SS_peaks_odd;
%             SS_peaks_secondary(2:2:end)=SS_peaks_even;


%% Convert logical spindle detection array from peak dimensions to datapoint (signal) dimensions
            % preallocate
            app.binary_SS = zeros(size(Oscillatory_Component_bandpassFiltered(:,1)));
            app.binary_SS_secondary = zeros(size(Oscillatory_Component_bandpassFiltered(:,1)));
            binary_SS_odd = zeros(size(Oscillatory_Component_bandpassFiltered(:,1)));
            binary_SS_even = zeros(size(Oscillatory_Component_bandpassFiltered(:,1)));

            %count number of sleep spindles
            count = 0;
            if peaks_index(1) == 1 && SS_peaks(1) == 1
                count = count + 1;
                app.binary_SS(1)= 1;
            end

            for iii = 2:length(peaks_index)
                if SS_peaks(iii) == 1 && SS_peaks(iii-1) == 0
                    count = count + 1;
                    app.binary_SS(peaks_index(iii))=1;
                end
                if SS_peaks(iii) == 1 && SS_peaks(iii-1) == 1
                    app.binary_SS(peaks_index(iii-1):peaks_index(iii))=1;
                end
            end

            %Secondary Classification odd
            count_odd = 0;
            if peaks_index_odd(1) == 1 && SS_peaks_odd(1) == 1
                count_odd = count_odd + 1;
                binary_SS_odd(1)= 1;
            end

            for iii = 2:length(peaks_index_odd)
                if SS_peaks_odd(iii) == 1 && SS_peaks_odd(iii-1) == 0
                    count_odd = count_odd + 1;
                    binary_SS_odd(peaks_index_odd(iii))=1;
                end
                if SS_peaks_odd(iii) == 1 && SS_peaks_odd(iii-1) == 1
                    binary_SS_odd(peaks_index_odd(iii-1):peaks_index_odd(iii))=1;
                end
            end

             %Secondary Classification even
            count_even = 0;
            if peaks_index_even(1) == 1 && SS_peaks_even(1) == 1
                count_even = count_even + 1;
                binary_SS_even(1)= 1;
            end

            for iii = 2:length(peaks_index_even)
                if SS_peaks_even(iii) == 1 && SS_peaks_even(iii-1) == 0
                    count_even = count_even + 1;
                    binary_SS_even(peaks_index_even(iii))=1;
                end
                if SS_peaks_even(iii) == 1 && SS_peaks_even(iii-1) == 1
                    binary_SS_even(peaks_index_even(iii-1):peaks_index_even(iii))=1;
                end
            end


            %Secondary Classification, combine binaries
            app.binary_SS_secondary = binary_SS_odd+binary_SS_even;
            app.binary_SS_secondary(app.binary_SS_secondary>1)=1;

            %Secondary Classification
            count_secondary = 0;

            for iii = 2:length(app.binary_SS_secondary)
                if app.binary_SS_secondary(iii) == 1 && app.binary_SS_secondary(iii-1) == 0
                    count_secondary = count_secondary + 1;
                end
            end

            %           % Remove Spindles of Short Duration
%             minimum_duration = 600; % 0.294985251 seconds
% 
%             counter=0;
%                 
%                 % Primary Classification
%                 for ii = 1:length(app.binary_SS_secondary)
%                     % First Classification Method
%                     if app.binary_SS_secondary(ii) == 1
%                         counter = counter+1;
%                     else
%                         if counter < minimum_duration+1
%                             for c = 1:counter
%                                 app.binary_SS_secondary(ii-c)=0;
%                             end
%                         end
%                         counter = 0;
%                     end
%                 end

            %% Plot EEG Data
            if length(SR)>1
                app.Time=(0:1/floor(SR(app.channel)):nSec-(1/floor(SR(app.channel))));
            else
                app.Time=(0:1/floor(SR):nSec-(1/floor(SR)));
            end

             % Raw,0,'r'
                hold(app.EEG_Window.RawAxis,"off")
                plot(app.EEG_Window.RawAxis,app.Time,s(1,:)) %child 9
                title(app.EEG_Window.RawAxis,'Raw')
                xlabel(app.EEG_Window.RawAxis,'Time(s)')
                xlim(app.EEG_Window.RawAxis,[0 nSec])
                app.EEG_Window.RawAxis.XTick = 0:floor(nSec/6):nSec;
                app.EEG_Window.RawAxis.XTickLabel = 0:floor(nSec/6):nSec;
                ylim_min = app.EEG_Window.RawAxis.YLim(1);
                ylim_max = app.EEG_Window.RawAxis.YLim(2);
                hold(app.EEG_Window.RawAxis,'on')
                area(app.EEG_Window.RawAxis,app.Time,app.binary_SS_secondary*ylim_max*2,"FaceAlpha",.5,'FaceColor',[.6 .6 .6],'EdgeColor','n')%child 7
                area(app.EEG_Window.RawAxis,app.Time,-app.binary_SS_secondary*ylim_max*2,"FaceAlpha",.5,'FaceColor',[.6 .6 .6],'EdgeColor','n')%child 6
                xline(app.EEG_Window.RawAxis,app.TimesSlider.Value,'r','LineWidth',2)%child 5
                area(app.EEG_Window.RawAxis,app.Time,app.binary_SS*ylim_max*2,"FaceAlpha",.5,'FaceColor','c','EdgeColor','n')%child 4
                area(app.EEG_Window.RawAxis,app.Time,-app.binary_SS*ylim_max*2,"FaceAlpha",.5,'FaceColor','c','EdgeColor','n')%child 3
                app.EEG_Window.RawAxis.YLim = [ylim_min ylim_max];
                area(app.EEG_Window.RawAxis,1:0.5:app.Window_size,zeros(1,(app.Window_size*2)-1)*ylim_max*2,"FaceAlpha",.5,'FaceColor','m','EdgeColor','n') %child 2
                area(app.EEG_Window.RawAxis,1:0.5:app.Window_size,-zeros(1,(app.Window_size*2)-1)*ylim_max*2,"FaceAlpha",.5,'FaceColor','m','EdgeColor','n') %child 1
                
                % Filtered Oscillatory Component
                hold(app.EEG_Window.FilterAxis,"off")
                plot(app.EEG_Window.FilterAxis,app.Time,Oscillatory_Component_bandpassFiltered(:,1)) %child 6
                hold(app.EEG_Window.FilterAxis,"on")
                title(app.EEG_Window.FilterAxis,'Filtered Oscillatory Component')
                xlabel(app.EEG_Window.FilterAxis,'Time(s)')
                %             xlim(app.EEG_Window.FilterAxis,[0 nSec])
                app.EEG_Window.FilterAxis.XTick = 0:floor(nSec/6):nSec;
                app.EEG_Window.FilterAxis.XTickLabel = 0:floor(nSec/6):nSec;
                ylim_min = app.EEG_Window.FilterAxis.YLim(1);
                ylim_max = app.EEG_Window.FilterAxis.YLim(2);
                area(app.EEG_Window.FilterAxis,app.Time,app.binary_SS_secondary*ylim_max*4,"FaceAlpha",.5,'FaceColor',[.6 .6 .6],'EdgeColor','n')%child 8
                area(app.EEG_Window.FilterAxis,app.Time,-app.binary_SS_secondary*ylim_max*4,"FaceAlpha",.5,'FaceColor',[.6 .6 .6],'EdgeColor','n')%child 7
                xline(app.EEG_Window.FilterAxis,app.TimesSlider.Value,'r','LineWidth',2) %child 5
                area(app.EEG_Window.FilterAxis,app.Time,app.binary_SS*ylim_max*4,"FaceAlpha",.5,'FaceColor','c','EdgeColor','n') %child 4
                area(app.EEG_Window.FilterAxis,app.Time,-app.binary_SS*ylim_max*4,"FaceAlpha",.5,'FaceColor','c','EdgeColor','n') %child 3
                app.EEG_Window.FilterAxis.YLim = [ylim_min ylim_max];
                area(app.EEG_Window.FilterAxis,1:0.5:app.Window_size,zeros(1,(app.Window_size*2)-1)*ylim_max*2,"FaceAlpha",.5,'FaceColor','m','EdgeColor','n') %child 2
                area(app.EEG_Window.FilterAxis,1:0.5:app.Window_size,-zeros(1,(app.Window_size*2)-1)*ylim_max*2,"FaceAlpha",.5,'FaceColor','m','EdgeColor','n') %child 1


                % Spindle and Quiescent Detection
                title(app.EEG_Window.PeakAxis,'Find Peak Envelope of Absolute Value of Filtered Oscillatory Component')
                xlabel(app.EEG_Window.PeakAxis,'Time(s)')
                app.EEG_Window.PeakAxis.XTick = 0:floor(nSec/6):nSec;
                app.EEG_Window.PeakAxis.XTickLabel = 0:floor(nSec/6):nSec;
                hold(app.EEG_Window.PeakAxis,'off')
                %             ylim_min = app.EEG_Window.PeakAxis.YLim(1);
                %             ylim_max = app.EEG_Window.PeakAxis.YLim(2);
                area(app.EEG_Window.PeakAxis,app.Time,app.binary_SS_secondary*ylim_max*4,"FaceAlpha",.5,'FaceColor',[.6 .6 .6],'EdgeColor','n')%child 7
                hold(app.EEG_Window.PeakAxis,'on')
                area(app.EEG_Window.PeakAxis,app.Time,-app.binary_SS_secondary*ylim_max*4,"FaceAlpha",.5,'FaceColor',[.6 .6 .6],'EdgeColor','n')%child 6
                area(app.EEG_Window.PeakAxis,app.Time(peaks_index),-SS_peaks*ylim_max*4,"FaceAlpha",.5,'FaceColor','c','EdgeColor','n') %child 5
                area(app.EEG_Window.PeakAxis,app.Time(peaks_index),SS_peaks*ylim_max*4,"FaceAlpha",.5,'FaceColor','c','EdgeColor','n') %child 4
                area(app.EEG_Window.PeakAxis,1:0.5:app.Window_size,zeros(1,(app.Window_size*2)-1)*ylim_max*2,"FaceAlpha",.5,'FaceColor','m','EdgeColor','n') %child 3
                plot(app.EEG_Window.PeakAxis,app.Time(peaks_index),peaks_value,'Color','k') %child 2
                xline(app.EEG_Window.PeakAxis,app.TimesSlider.Value,'r','LineWidth',2) %child 1
                app.EEG_Window.PeakAxis.YLim = [0 1.5*ylim_max];

            Spindle_percentage = 100*(sum(app.binary_SS)/length(app.binary_SS));
            Spindle_percentage_secondary = 100*(sum(app.binary_SS_secondary)/length(app.binary_SS_secondary));

            app.t=table;
            app.t.SpindleCount = count;
            app.t.SpindleCount_secondary = count_secondary;
            app.t.Spindle_percentage = Spindle_percentage;
            app.t.Spindle_percentage_secondary = Spindle_percentage_secondary;
            
            linkaxes([app.EEG_Window.RawAxis,app.EEG_Window.FilterAxis,app.EEG_Window.PeakAxis],'x');

            app.EEG_Window.SpindlecountLabel.Text = ['Primary Spindle count: ' num2str(count) ', Secondary Spindle count: ' num2str(count_secondary)];

        end

        % Menu selected function: LoadEEGMenu
        function LoadEEGMenuSelected(app, event)
            OpenEEGFileButtonPushed(app);
        end

        % Menu selected function: LoadVideoMenu
        function LoadVideoMenuSelected(app, event)
            OpenVideoFileButtonPushed(app);
        end

        % Menu selected function: AnalyzeMenu
        function AnalyzeMenuSelected(app, event)
            AnalyzeButtonPushed(app);
        end

        % Button pushed function: LeftArrowTime
        function LeftArrowTimeButtonPushed(app, event)
            if app.TimesSlider.Value >= 0.1%1/app.HDR.SampleRate
                app.TimesSlider.Value = app.TimesSlider.Value - 0.1;%1/app.HDR.SampleRate;
            end
            TimesSliderValueChanged(app)
        end

        % Button pushed function: RightArrowTime
        function RightArrowTimeButtonPushed(app, event)
            if app.TimesSlider.Value <= app.TimesSlider.Limits(2) - 0.1%1/app.HDR.SampleRate
                app.TimesSlider.Value = app.TimesSlider.Value + 0.1;%1/app.HDR.SampleRate;
            end
            TimesSliderValueChanged(app)
        end

        % Button pushed function: LeftArrowEpoch
        function LeftArrowEpochButtonPushed(app, event)
            if app.EpochSlider.Value >= 1
            app.EpochSlider.Value = round(app.EpochSlider.Value)-1;
            EpochSliderValueChanged(app)
            end
        end

        % Button pushed function: RightArrowEpoch
        function RightArrowEpochButtonPushed(app, event)
            if  app.EpochSlider.Value <= app.EpochSlider.Limits(2)-1
                app.EpochSlider.Value = round(app.EpochSlider.Value)+1;
            end
            EpochSliderValueChanged(app)
        end

        % Button pushed function: LeftArrowZoom
        function LeftArrowZoomButtonPushed(app, event)
            if app.ZoomSlider.Value >= 0.1
                app.ZoomSlider.Value = app.ZoomSlider.Value - 0.1;
            end
            ZoomSliderValueChanged(app)
        end

        % Button pushed function: RightArrowZoom
        function RightArrowZoomButtonPushed(app, event)
            if app.ZoomSlider.Value <= app.ZoomSlider.Limits(2) - 0.1
                app.ZoomSlider.Value = app.ZoomSlider.Value + 0.1;
            end
            ZoomSliderValueChanged(app)
        end

        % Button pushed function: LeftArrowBinary
        function LeftArrowBinaryButtonPushed(app, event)
            if app.BinaryThresholdSlider.Value >= 0.01
                app.BinaryThresholdSlider.Value = app.BinaryThresholdSlider.Value - 0.01;
            end
            BinaryThresholdSliderValueChanged(app)         
        end

        % Button pushed function: RightArrowBinary
        function RightArrowBinaryButtonPushed(app, event)
            if app.BinaryThresholdSlider.Value >= app.BinaryThresholdSlider.Limits(2) - 0.01
                app.BinaryThresholdSlider.Value = app.BinaryThresholdSlider.Value + 0.01;
            end
            BinaryThresholdSliderValueChanged(app)                
        end

        % Button pushed function: LeftArrowArea
        function LeftArrowAreaButtonPushed(app, event)
            if app.AreaThresholdSlider.Value >= 1
            app.AreaThresholdSlider.Value = round(app.AreaThresholdSlider.Value)-1;
            end
            AreaThresholdSliderValueChanged(app)
        end

        % Button pushed function: RightArrowArea
        function RightArrowAreaButtonPushed(app, event)
            if app.AreaThresholdSlider.Value <= app.AreaThresholdSlider.Limits(2) - 1
                app.AreaThresholdSlider.Value = round(app.AreaThresholdSlider.Value)+1;
            end
            AreaThresholdSliderValueChanged(app)
        end

        % Menu selected function: CropImageMenu
        function CropImageMenuSelected(app, event)
            app.Crop_Window.CropImageUIFigure.Visible = 'on';
            FS = app.v.FrameRate;
            
            Image_current = rgb2gray(read(app.v,floor(FS*(app.TimesSlider.Value))+floor(FS*(app.EpochSlider.Value-1)*app.Window_size-FS*app.timedelay))); % time delay adjustment, could use (floor((app.HDR.NRec*app.HDR.Dur)-(app.v.NumFrames/app.v.FrameRate))) 
%             app.Crop_Window.UIAxes = uiaxes(app.Crop_Window.UIFigure);
            imshow(Image_current,'Parent',app.Crop_Window.UIAxes)

            app.UncropImageMenu.Enable = 'on';
        end

        % Value changed function: TimesEditField
        function TimesEditFieldValueChanged(app, event)
            app.TimesSlider.Value = app.TimesEditField.Value;
            TimesSliderValueChanged(app)
        end

        % Value changed function: EpochEditField
        function EpochEditFieldValueChanged(app, event)
            app.EpochSlider.Value = app.EpochEditField.Value;
            EpochSliderValueChanged(app)
        end

        % Value changed function: BinaryThresholdEditField
        function BinaryThresholdEditFieldValueChanged(app, event)
            app.BinaryThresholdSlider.Value = app.BinaryThresholdEditField.Value;
            app.BinaryThresholdSliderValueChanged(app)
        end

        % Value changed function: AreaThresholdEditField
        function AreaThresholdEditFieldValueChanged(app, event)
            app.AreaThresholdSlider.Value = app.AreaThresholdEditField.Value;
            app.AreaThresholdSliderValueChanged(app)
        end

        % Menu selected function: VideofpsMenu
        function VideofpsMenuSelected(app, event)
            app.v.FrameRate = str2double(inputdlg("What is the camera's fps?"));
            EpochSliderValueChanged(app)
        end

        % Menu selected function: UncropImageMenu
        function UncropImageMenuSelected(app, event)
% % %             app.Video_Filename = app.VideoFileDropDown.Value;
% % %             Video_Folder = app.Video_Folder;
% % % 
% % %             %% Read Video Data
% % %             app.v = VideoReader(fullfile(Video_Folder,app.Video_Filename));
% % %             % datestr(v.CurrentTime/24/60/60,'hh:mm:ss')

            %Parameters
            FS = app.v.FrameRate;

            %Generate images
            Image_previous = rgb2gray(read(app.v,FS*app.TimesSlider.Value-(FS/2)));
            Image_current = rgb2gray(read(app.v,FS*app.TimesSlider.Value));
            Image_diff = Image_current - Image_previous;
            Image_diff_bw = im2bw(Image_diff,app.BinaryThresholdSlider.Value);

            %% Plot Video Data
            imshow(Image_previous,'Parent',app.Video_Window.PrevSec_ax)
            xlabel(app.Video_Window.PrevSec_ax,'')
            ylabel(app.Video_Window.PrevSec_ax,'')
            title(app.Video_Window.PrevSec_ax,'Previous Second')
            imshow(Image_current,'Parent',app.Video_Window.CurSec_ax)
            xlabel(app.Video_Window.CurSec_ax,'')
            ylabel(app.Video_Window.CurSec_ax,'')
            title(app.Video_Window.CurSec_ax,'Current Time')
            imshow(Image_diff,'Parent',app.Video_Window.Difference_ax)
            xlabel(app.Video_Window.Difference_ax,'')
            ylabel(app.Video_Window.Difference_ax,'')
            title(app.Video_Window.Difference_ax,'Difference')
            imshow(Image_diff_bw,'Parent',app.Video_Window.Thresholded_ax)
            xlabel(app.Video_Window.Thresholded_ax,'')
            ylabel(app.Video_Window.Thresholded_ax,'')
            title(app.Video_Window.Thresholded_ax,'Thresholded')
        end

        % Value changed function: ZoomEditField
        function ZoomEditFieldValueChanged(app, event)
            app.ZoomSlider.Value = app.ZoomEditField.Value;
            ZoomSliderValueChanged(app)
        end

        % Value changed function: RThresholdEditField
        function RThresholdEditFieldValueChanged(app, event)
                EpochSliderValueChanged(app)
        end

        % Menu selected function: StatsMenu
        function StatsMenuSelected(app, event)
           
            if isempty(app.Stats_Window)
                app.Stats_Window = SleepSpindleDetector_Results(app);
            else
                app.Stats_Window.Visible = "on";
            end

        end

        % Value changed function: EEGFileDropDown
        function EEGFileDropDownValueChanged(app, event)
            app.EEG_Filename = app.EEGFileDropDown.Value;
            OpenEEG(app)
        end
    end

    % App creation
    methods (Access = public)

        % Construct app
        function app = SleepSpindleDetector(varargin)
            app = app@matlab.apps.App(varargin{:});

            if nargout == 0
                clear app
            end
        end
    end
end