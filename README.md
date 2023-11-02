# SleepSpindleDetector

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=kevinscottholly/SleepSpindleDetector)
[![View SleepSpindleDetector on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/SleepSpindleDetector)

![Alt-Text](https://github.com/kevinscottholly/SleepSpindleDetector/blob/main/Sleep%20Spindle%20Detector%20Alpha_resources/SleepSpindleIcon.png?raw=true)

## Setup 

1. Run RodentSleepSpindleDetector.mlappinstall to install the app
2. Select the Rodent Sleep Spindle Detector App Icon under the Apps tab wihin MATLAB

or

1. Make sure downloaded files are within your path
2. Run RodentSleepSpindleDetector.mlapp


### MathWorks Products (http://www.mathworks.com)

Requires MATLAB release R2021b or newer
- [Signal Processing Toolbox&trade;](https://www.mathworks.com/products/signal.html)
- [Image Processing Toolbox&trade;](https://www.mathworks.com/products/image.html)
- [Curve Fitting Toolbox&trade;](https://www.mathworks.com/products/curvefitting.html)

### System Requirements

[Operating System requirements](https://www.mathworks.com/support/requirements/previous-releases.html)

## Getting started

### Description

The multi-window Rodent Sleep Spindle Detector app can identify sleep spindles within intracranial EEG (iEEG) recordings. Periods of quiescence can optionally be identified via video recordings to improve sleep spindle detection. The program includes validation methods to compare detected results to a ground truth.


### Workflow

1. Open the app after installation.
2. Open EEG and/or video of a rodent
3. Use sliders or their respective edit fields to adjust the binary threshold, structural element size, and time.
4. Click the Analyze button or File>Analyze in the menu to analyze the entire EEG and generate a spreadsheet of results.

Validation (Optional)
5. Select the Validation tab
6. Click "Load GroundTruth"
7. Click "Calculate"

### EEG Specifications

European Data Format (EDF)

### Video Specifications

Supported video formats include Multi-TIFF files as well as those listed below.
All Platforms: AVI, including uncompressed, indexed, grayscale, and Motion JPEG-encoded video (.avi), Motion JPEG 2000 (.mj2)
All Windows: MPEG-1 (.mpg), Windows Media Video (.wmv, .asf, .asx), Any format supported by Microsoft® DirectShow®
Windows 7 or later: MPEG-4, including H.264 encoded video (.mp4, .m4v), Apple QuickTime Movie (.mov), Any format supported by Microsoft Media Foundation
Macintosh: Most formats supported by QuickTime Player, including: MPEG-1 (.mpg), MPEG-4, including H.264 encoded video (.mp4, .m4v), Apple QuickTime Movie (.mov), 3GPP, 3GPP2, AVCHD, DV
Note: For OS X Yosemite (Version 10.10) and later, MPEG-4/H.264 files play correctly, but display an inexact frame rate.

## License

The license is available in the License file within this repository.

## Community Support
[MATLAB Central](https://www.mathworks.com/matlabcentral)

Copyright 2022 The MathWorks, Inc.
