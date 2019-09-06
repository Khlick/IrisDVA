
# Iris DVA

| Author:  | [Khris Griffis](mailto:khrisgriffis@ucla.edu)  |
|---|---|
| **Official release date:**  | **TBD**  |

---

*Contents:*
- [Iris DVA](#iris-dva)
  - [Introduction](#introduction)
  - [2019-09-05](#2019-09-05)
    - [Release 2.0.29a](#release-2029a)
  - [2019-09-04](#2019-09-04)
    - [Release 2.0.24a](#release-2024a)
  - [2019-09-03](#2019-09-03)
    - [Release 2.0.22a](#release-2022a)
  - [2019-09-02](#2019-09-02)
    - [Release 2.0.21a](#release-2021a)
  - [2019-08-29](#2019-08-29)
    - [Release 2.0.18a](#release-2018a)
  - [2019-08-27](#2019-08-27)
    - [Release 2.0.10a](#release-2010a)
  - [2019-08-26](#2019-08-26)
    - [Release 2.0.8a](#release-208a)
  - [2019-08-25](#2019-08-25)
    - [Release 2.0.7a](#release-207a)
  - [2019-08-22](#2019-08-22)
    - [Release 2.0.2a](#release-202a)
  - [2019-08-19](#2019-08-19)
    - [Release 2.0.1a](#release-201a)
  - [< 2019 PreRelease](#2019-prerelease)

## Introduction

Iris DVA is a MATLAB based tool for visualizing and analyzing electrophysiology data. Iris was originally created to standardize the process for viewing and performing offline analysis of physiological data acquired via [Symphony](https://symphony-das.github.io/) in the Sampath Lab, UCLA. While Iris is still in development stages, a secondary goal was to make the software extensible and modular to allow for any data and any analysis to be easily created by the end-user. Documentation is essentially non-existent except which resides in code comments, some of which is likely to be out-dated or simply inadequate... Sorry about that!

> *Usage Note:* Iris was developed in MATLAB 9.6+ (2019a) on windows (x64) platform using both 1080p and 4K displays. That said, it has not been tested on Mac or Unix distributions of MATLAB and if screen scaling (typically handled by the OS) is other than 100%, visual issues may be present. This app utilizes MATLAB's newer `uifigure` (app designer) which has some inherent bugs. One of which occurs sometimes when `drawnow()` is called, causing MATLAB to hang during a "coalescer flush" and the app ui to stop responding. This will not allow you to close the app using the quit or close window commands. Instead, use `delete(findall(groot,'HandleVisibility','off'))` then restart MATLAB. I am working to eliminate all `drawnow()` requirements, and there are very few.

---

## 2019-09-05

### Release 2.0.29a

- Updated Iris stats switch to use manual aggregation loop, which enhanced plotting speed a little. *Still need to optimize the plotting mechanism, I don't like how slow it is.*
- fixed timestamp accuracy when reading files in timezones other than pacific time. This applies to notes and datum times in Symphony h5 files.
- updated IrisData `Aggregate` method to check if builtin function was supplied as character array / string and then explicitly defines the function to operate only on columns. This prevents the need to pull out singleton datums and also allows functions like `var` to be computed for those singletons (note that `var(<scalar>) == 0`). But this removes the need to supply an anonymous function to  manage singletons, e.g. `@(x)mean(x,1)` or `@(x)max(x,[],1)`.
- fixed other minor bugs and typos

## 2019-09-04

### Release 2.0.24a

- updated AverageEpochs builtin analysis tool to include the filter example.
- modified how IrisData.Aggregate performs statistic. Now the entered statistic function MUST operate down columns (this has always been true when using `grpstats` but now you have to be more careful). E.g. if you want to compute averages across datums, supplying: `'statistic', 'nanmean'` to `IrisData.Aggregate()` will produce desired effect. Should you provide a custom function, create it to operate as though each datum is a row vector and the aggregate group will have $n_{groups}$ rows and $m_{samples}$ columns, e.g. `@(x)mean(x,1)` is appropriate to calculate the point-by-point mean of a group of datums. In the future, this may change to accommodate summarizing statistics.

## 2019-09-03

### Release 2.0.22a

- IrisData:
  - fixed issue where dropping the first datum in a family would lead to disorganized grouping. Now we can add an boolean `inclusions` vector to `IrisData.determineGroups()` in order to correctly determine group order

## 2019-09-02

### Release 2.0.21a

- IrisData:
  - fixed bug where dropping epochs sometimes led to error in `getDataMatrix`
- Iris:
  - added `Aggregate` method to manage in-app aggregation. *Functionality is not yet stable.*
    - When stats rocker is switched on, it is recommended to not navigate new epochs.
    - When rocker is on, changes in preferences are not redrawn sometimes. It is recommended to change preferences while rocker is OFF for most accurate results.
    - Note that the preferences checkbox baseline zeroing is only for aggregates, it does not affect the operation of the baseline rocker. When this option is checked, the baseline rocker effectively does nothing. If this checkbox is unchecked, the baseline rocker will then perform baseline zeroing for both original epochs and the aggregates.
  - modified plotting mechanism. Moved much of the data gathering to Datum, Handler and App.
- Future Bug fixes coming:
  - When modifying scaling values in "Custom" mode, values are reverted to 1 each time the scaling rocker is switched from OFF to ON. Currently, you need to switch the rocker to ON, then modify your custom scaling options.


## 2019-08-29

### Release 2.0.18a

- IrisData:
  - fixed bug in Aggregate that left temporarily padded NaNs. Datums are now subset to shortest datum WITHIN aggregate group (i.e. if 100 sample vector is averaged with 200 sample vector, rather than have in 100 points and 100 nans, it will just be 100pts).
  - Method chaining now works well e.g, IrisData.Filter().Aggregate()
- Iris:
  - enhanced file info tree naming and info table column widths
  - enhanced protocols table view
  - enhanced Datum getProp method (to match IrisData Specs get method)
  - enhanced symphony reader to include source labels for each Epoch.
    - This enabled grouping by `'Sources'`
  - enhanced ReadToSession with verbose flag

## 2019-08-27

### Release 2.0.10a

- IrisData:
  - added response and rig device configurations to the `Specs` table
  - fixed indexing bug when original indices overlapped during construction
- fixed an issue with parallel pool creation in ReadToSession utility

## 2019-08-26

### Release 2.0.8a

- fixed typing error resulting from IrisData Aggregation
- fixed bug where saving iris session from IrisData caused empty inclusion status
- fixed bug with plotting mechanism to allow for NaNs
- added cell parsing support to unknowncell2str and unknown2cellstr helpers
- modified output of IrisData save session to match the Iris data handler `saveobj`

## 2019-08-25

### Release 2.0.7a

- fixed typos
- added "Import Analysis" to analysis menu
- modified IrisData:
  - changed property `Filters` to `Specs`
    - to avoid typo issues with added method.
  - added `Filter` method to apply digital filtering to datums
  - Fixed bug associated with `Aggregate` which would fail to parse filenames correctly when more than 1 file was present.
  - Added public method `UpdateData` to easily create a new IrisData object from a modified data struct as retrieved from `IrisData.copyData()` method.
  - fixed some minor bugs with the `getOriginalIndex` method
- Attempted to add functionSignatures.json though it doesn't seem to work.

## 2019-08-22

### Release 2.0.2a

- bandaid patch of `drawnow()` issue, not fully fixed. maybe matlab bug
- added save iris session from IrisData classdef
- added subset method for splitting irisdata
- fixed some typos.

## 2019-08-19

**First Release**

### Release 2.0.1a

*Expect Bugs!*

## < 2019 PreRelease

Development began after finalizing version 1, originally called: MetaVision.