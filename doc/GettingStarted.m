%% Getting Started with Rodent Sleep Spindle Detector
% Preview a bundled EEG recording and its known spindle labels, then follow
% the app workflow to detect spindles and review results. Run this script
% from top to bottom; no personal recordings or file dialogs are needed.
%
% The preview uses MATLAB and the bundled EDF reader. The optional app
% requires Signal Processing Toolbox, Image Processing Toolbox, Curve
% Fitting Toolbox, and a compatible bundled McSleep tvd MEX file. The app
% files were saved in R2024a; use that release or newer.
%
% Set this flag to true to open the app after the preview. Full-recording
% detection starts when you click Analyze after loading an EDF in the app.

launchApp = false;

%% Set Up the Repository
% Resolve paths relative to this script, so the example also works when
% MATLAB's Current Folder is elsewhere. Paths are added for this session.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(repoRoot)
addpath(fullfile(repoRoot, 'EDF-Reader'))
addpath(fullfile(repoRoot, 'mcsleep-master'))
addpath(fullfile(repoRoot, 'Sleep Spindle Detector Alpha_resources'))

%% Locate the Example Recording and Labels
% This recording contains artificial 15 Hz spindles with a nominal duration
% of 1 second. The EDF is the app input; the matching MAT file contains the
% sample-level logical vector |GroundTruth|. A value of 1 marks a spindle.
% The other answer-key MAT file, ending in |_AnswerKey_signal|, contains a
% waveform and is not the binary ground truth used by the Validation tab.

sampleFolder = fullfile(repoRoot, 'Simulated Signals', 'Artificial Spindles');
sampleName = '20220926_simulated_artificial_signal_freq_15_dur_1_Amp_1';
sampleFile = fullfile(sampleFolder, [sampleName '.edf']);
groundTruthFile = fullfile(sampleFolder, ...
    [sampleName '_AnswerKey_GroundTruth.mat']);
assert(isfile(sampleFile) && isfile(groundTruthFile), ...
    'Keep the Simulated Signals folder with the downloaded repository.');

% The app's ground-truth loader resolves files by name. Adding the sample
% folder also makes this answer key available during the later GUI steps.
addpath(sampleFolder)

%% Inspect the EDF Header
% EDFData reads the header and maps the signal data without loading the
% full recording. Its getData method uses inclusive, one-based sample
% indices. Sampling rate and units come from the EDF header.

eegFile = EDFData(sampleFile);
channel = 1;
sampleRateHz = eegFile.sf(channel);
recordingDurationSeconds = eegFile.records * eegFile.duration;
recordingSampleCount = eegFile.records * eegFile.samples(channel);
recordingInfo = table(string(eegFile.label{channel}), sampleRateHz, ...
    recordingDurationSeconds, recordingSampleCount, ...
    'VariableNames', {'Channel', 'SampleRateHz', 'DurationSeconds', 'Samples'});
disp(recordingInfo)

% Expected: ChannelFake, 2034 Hz, 10000 seconds, and 20340000 samples.

%% Read a Short Preview
% Request the first 30 seconds of EEG for display. The reader accesses whole
% EDF data records before trimming the returned samples. The compact logical
% answer key is loaded separately; the signal MAT files are not needed.

previewDurationSeconds = 30;
previewSampleCount = min(round(previewDurationSeconds * sampleRateHz), ...
    recordingSampleCount);
eegPreview = eegFile.getData([1 previewSampleCount], channel);
timeSeconds = (0:previewSampleCount-1)' / sampleRateHz;

truthData = load(groundTruthFile, 'GroundTruth');
assert(numel(truthData.GroundTruth) == recordingSampleCount, ...
    'GroundTruth must have one label per EEG sample.');
groundTruthPreview = truthData.GroundTruth(1:previewSampleCount);
groundTruthPreview = groundTruthPreview(:);

%% Plot EEG and Known Spindle Intervals
% The lower plot shows the supplied answer key. These labels are reference
% annotations; the detector has not run yet. The EEG retains the physical
% units recorded in the EDF header.

previewFigure = figure('Name', 'Bundled EEG and Spindle Ground Truth', ...
    'NumberTitle', 'off');
previewLayout = tiledlayout(previewFigure, 2, 1, ...
    'TileSpacing', 'compact', 'Padding', 'compact');
eegAxes = nexttile(previewLayout);
plot(eegAxes, timeSeconds, eegPreview)
ylabel(eegAxes, ['EEG (' strtrim(eegFile.units{channel}) ')'])
title(eegAxes, 'Artificial 15 Hz spindle recording: first 30 seconds')
grid(eegAxes, 'on')

truthAxes = nexttile(previewLayout);
stairs(truthAxes, timeSeconds, double(groundTruthPreview), 'LineWidth', 1.2)
xlabel(truthAxes, 'Time from recording start (s)')
ylabel(truthAxes, 'Ground truth')
yticks(truthAxes, [0 1])
ylim(truthAxes, [-0.1 1.1])
grid(truthAxes, 'on')
linkaxes([eegAxes truthAxes], 'x')
xlim(eegAxes, [0 previewSampleCount / sampleRateHz])

%% List Labeled Intervals in the Preview
% Convert the binary labels into time intervals. Start times refer to the
% first included sample; end times refer to the boundary after the last
% included sample. Intervals that cross the preview edges are clipped.

labelChanges = diff([0; double(groundTruthPreview); 0]);
startSample = find(labelChanges == 1);
endSample = find(labelChanges == -1) - 1;
startSeconds = (startSample - 1) / sampleRateHz;
endSeconds = endSample / sampleRateHz;
labeledIntervals = table(startSeconds, endSeconds, endSeconds-startSeconds, ...
    'VariableNames', {'StartSeconds', 'EndSeconds', 'DurationSeconds'});
disp(labeledIntervals)

% For this example, four labeled intervals occur in the first 30 seconds.
% They begin near 6.85, 8.99, 21.64, and 24.33 seconds.

%% Open the Detector (Optional)
% Enable |launchApp| at the top of the script and run again to open the app.
% Keep |app| in the workspace to access tables after analysis. Set the
% starting epoch to 1 here because the app normally opens at epoch 21.

if launchApp
    app = SleepSpindleDetector; %#ok<UNRCH> Enabled by launchApp above.
    app.EpochSlider.Value = 1;
    app.EpochEditField.Value = 1;
end

disp('Example EDF:')
disp(sampleFile)
disp('Matching ground truth:')
disp(groundTruthFile)

%% Analyze the Example in the App
% # Choose *File > Load EEG* and select |sampleFile| from the path printed
%   above. Loading processes the selected 100-second preview epoch.
% # Select *ChannelFake*. Inspect the *Epoch*, *Time (s)*, and *Zoom*
%   controls. Start with the default *R^2 Threshold* of 0.7 for the secondary
%   classification. Video is optional for this example.
% # Click *Analyze* to process the recording's 100 complete epochs. This
%   takes longer than the 30-second reference preview in this script.
% # Review *Summary* and *Sleep Sleep Specifics* in the results window.
%   Analyze populates tables; it does not automatically save a spreadsheet.
%
% For your own EDF, the current slider requires at least two complete
% 100-second epochs. Analysis omits a trailing partial epoch. Review the
% README before supplying video or recordings with different sample rates.

%% Compare Detections with the Answer Key
% After Analyze completes, open the results window's *Validation* tab.
% Click *Load Ground Truth*, choose |groundTruthFile|, then click *Caculate*
% (the current button spelling). *Plot Ground Truth* shows the labels.
%
% Labels must match the analyzed samples. The current |Tracking_stats.mlx|
% helper interchanges false-positive and false-negative counts, affecting
% displayed sensitivity and specificity. Recompute these independently
% before using them; see README.md for the current limitations.

%% Export and Explore Further
% With the app still open after analysis, run commands such as these in the
% Command Window to save tables to a folder you choose. They are commented
% out here so running this tutorial does not create output files.
%
%   outputFolder = fullfile(repoRoot, 'results');
%   if ~isfolder(outputFolder), mkdir(outputFolder); end
%   writetable(app.t, fullfile(outputFolder, 'epoch_summary.csv'))
%   writetable(app.t2, fullfile(outputFolder, 'primary_spindles.csv'))
%   writetable(app.t3, fullfile(outputFolder, 'secondary_spindles.csv'))
%
% Reusing filenames replaces earlier exports. The app's save menus are
% incomplete; use workspace exports as described in README.md.
%
% * |app.t4| and |app.t5| contain duration summaries for each classification.
% * |app.Primary_SS| and |app.Secondary_SS| contain sample-level detections.
% * Explore other recordings under |Simulated Signals| with their matching
%   answer keys, and read the McSleep background in |mcsleep-master/README.md|.

% Copyright 2026 The MathWorks, Inc.
