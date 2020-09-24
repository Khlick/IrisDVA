<img src="./resources/img/Iris100px.png" align="right" height="60px" alt="Iris DVA Logo" title="Iris DVA" />

Iris Data Visualization and Analysis
====================================

Iris DVA is a MATLAB based tool for visualizing and analyzing electrophysiology data. Iris was originally created to standardize the process for viewing and performing offline analysis of physiological data acquired via [Symphony](https://symphony-das.github.io/) in the Sampath Lab, UCLA. While Iris is still in development stages, a secondary goal was to make the software extensible and modular to allow for any data and any analysis to be easily created by the end-user. Documentation is essentially non-existent except which resides in code comments, UI tooltips, and this document, some of which is likely to be out-dated or simply inadequate... Sorry about that! Eventually, documentation will reside in this [gitbook](https://sampathlab.gitbook.io/iris-dva).

## Requirements
Iris was developed to be compatible with Windows, Mac and Linux operating
systems though all development was in a Windows 64-bit environment.
The minimum system requirements are the same as the requirements to run MATLAB
in your environment.

The recommended system is Windows 10 pro 64-bit workstation with 12+ Gb of RAM.
This recommendation comes from the expectation that ephys data is often large.

The recommended MATLAB version is 2020b, 64-bit though Iris is compatible with
2018b+ releases. If using a version 2019b or earlier, their will be some
functionality loss and the likelihood to encounter the [coalescer
issue](#Coalescer-Issue) is high.

## Installation
* (*recommended*) Download the latest `mlappinstall` from the releases page and install using the
MATLAB app installer (from the toolstrip or by
[`matlab.apputil.install`](https://www.mathworks.com/help/matlab/ref/matlab.apputil.install.html?s_tid=srchtitle)).
  * Install the command line tools by running Iris, goto Help \> Install
    Helpers, see [Command Line Interface](#Command-Line-Interface).

* Alternatively, clone this repo, navigate to the directory using the MATLAB
  Current Folder and run `runIris()` to start the app.
  * *Using this approach will prevent usage of the command line tools described above.*

## How To Use
\<Overview of usage coming soon\>

## Command Line Interface
The CLI is a MATLAB command toolkit enables interaction with Iris and utilities within
from the MATLAB command window. Installing the CLI enables access the `IrisDVA`
Abstract class.

### Properties
* `IrisDVA.VERSION` <span style="margin-left:10px;border-left:4px solid;border-color:#4b4b4b;background-color:#eee;">Read-only</span>
  * Display the current version of the IrisDVA 

### Methods
* `IrisDVA.start([...])`: Runs the Iris app and optionally loads the provided filepaths.
* `IrisDVA.update(mlappinstall_file)`: update the iris app with the supplied
  `mlappinstall` file.
* `IrisDVA.import()`: Load Iris libraries into the MATLAB session
  * Useful for developing analysis functions and working with IrisData objects.
* `IrisDVA.detach()`: Remove Iris libraries from the current MATLAB session.
* `IrisDVA.installedVersion()`: Check the installed version of Iris.
* `IrisDVA.isRunning()`: Check if Iris is running.
* `IrisDVA.isMounted()`: Check if Iris is on the MATLAB path.

## Known Issues
Iris utilizes MATLAB's web-based `uifigure`s for the user interface. As this is
still relatively new and under active development by The MathWorks, there are
some bugs and some features are under-optimized. That said, not all the issues
you may run into with Iris are TMW's fault :grin:.

### Web-UI
Because Iris development started in 2016 (2016b release) and the functionality of
`uifigure` was severely lacking in comparison to today's `uifigure`, I employed
a number of hacks to get a semblance of usefulness for the application. Some of
those UI hacks are no longer needed but remain in place (why fix something
that's not broken?). Because of this, you may encounter so UI elements that
don't display correctly (though this won't affect functionality). The one place
where there is an appreciable lack of optimization is at startup. The reason
startup is slow is due to how the app's preferences UI is constructed. An
optimization update for this is in the works (Sep 2020).

### Coalescer Issue
Starting in MATLAB 2020a, this appears to have become a non-issue, mostly. The
short description for this issue is that MATLAB will occasionally call `drawnow`
which may lead to a infinite recursion in the `flushCoalescer` method of the
internal `FigureController` class. The complete issue is described well
[here](https://www.mathworks.com/matlabcentral/answers/467671-real-time-plotting-slow-figurecontroller-flushcoalescer-needs-a-lot-of-memory-and-cpu-time).
As of 2020b, the infinite recursion seems to be gone, but there is an occasional
lag following actions which result in a call to `drawnow`. There is a workaround
in place, which seems to help a bit.

### Performance
Iris was originally written to view, manage and analyze data acquired using
[Symphony DAS](https://symphony-das.github.io/) which is stored if hdf5 format.
A main goal was to prevent needing Symphony installed on the analysis machines,
primarily because Symphony is written specifically for a Windows environment and
we had a lot of Mac users in the lab. For this reason, I opted for taking a
page-cache approach of caching data directly in volatile memory. I never got
around to optimizing the hdf5 reading method (for either Symphony 1 or Symphony
2 files), it takes a while to load a single experiment. In my experience, the
typical Symphony2 file from an experiment is roughly 100-200Mb on disk. This
results in a ~3 minute load time on my i7 pc and <30 seconds on my Xeon E5
workstation. In 2020b, MATLAB has a new way of parsing mat-files which has
caused a significant hit to reading/writing performance in my experience. I'm
working on optimizing this, but have no target date.

## Acknowledgements

Iris uses a number of open source packages, utilities and toolkits. The complete
list will be compiled and displayed here in the near future. In the meantime,
licenses for each tool can be found in their containing directories.

I want to thank my colleagues at the Sampath Lab, UCLA, for all their extensive
alpha and beta testing.

## License

Licensed under the [MIT License](https://opensource.org/licenses/MIT), an [open source license](https://opensource.org/docs/osd).