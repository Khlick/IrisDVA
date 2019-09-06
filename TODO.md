TODO:
- IrisData needs a "saveas" method for saving the data object to session, matrix, csv, etc.
- [low] Create an uninstall method which asks to remove all preferences.
- [med] Change Protocols viewer to be a "Current Epochs Explorer" such that it resembles 
  Data Overview with a node tree that explores the currently selected epochs combined
  protocols in a table (it already does this) and allows the user to explore the 
  configuration fields of the datums. It could have the following tree levels:
  + CurrentView: All protocols in propTable
  |-- + Epoch 1: Epoch 1 protocols in propTable
  |   |-- + responseConfigs: flatten underlying structure to Nx2 cell for proptable
  |   |   |-- + device1..N: Individual device configurations flattened
  |   |   |-- + ...
  |   |-- + deviceConfigs: flatten underlying structures to Nx2 cell for proptable
  |   |   |-- + device1..N: Individual device configurations flattened
  |   |   |-- + ...
- In Preferences:
  x Baseline region options: Beginning, End, Custom, where Custom allows the user
    to enter in an offset number of points. This box should parse to uint64 but 
    can allow user to enter an expression. Like 0.5*1e3 -> 500.
    - Also requires updated iris.data.encode.plotData.(get.y) update.
    * Set this to Beginning, End, Fit (Asym) and Fit (Sym)
      x Need to implement the Fit types, which fit a line to the pts + offset of 
        Beginning (Asym) or <Beginning ... End> (Sym). The symmetrical version will 
        use the corresponding Xs such that the fit is calculated: 
          inds = [1:npts + Ofst, (end-Ofst)-((npts-1):-1:0)];
          subLine = fit(X(inds),Y(inds), 'y=mx+b');
  x Populate Statistics GroupBy box
  x (removed) Scaling method "Select" needs to be completed. 
    - Ideally, this would activate the 
      primary axes and halt execution until a nearby data point is selected. I don't 
      think this is available in 2019a, but there is the tooltip feature of the axes.
    - A better method may be to cycle through each shown device and popup a Java 
      figure and use the ginput() method.
    - If we can find a way to hijack the uiaxes for this purpose, it would be worth
      creating a module-like (mlapp) that sends the current data in and plots it 
      with a device (dropdown) selection and a table to display the x,y data points.
      - If this is possible, maybe we can also use this to select a baseline region
        for zero baseline subtraction?
    x Decided to ditch this, however, I used the line click callback to set a
      public property on primary window
- Iris:
  x onServiceDisplayUpdate: Sends a disp() to the console.. not sure why, investigate.
  - onToggleSwitch: Stats. Need to implement statistics switch.
    - This requires a few things:
      x1 populate preferences stats groupby
      2 Handler.getSummarizedData() should return plotData() of summarized data
        and grey colored original traces (if selected in settings).
      3 Update how app.ui plots. Currently we send a pointer to the handler from 
        Iris.draw(...). What we should do is send the plot data and any other 
        info for updating ui elements. I like the idea of having objects self-update
        based on input flags/data/info.
      3.1 The handler and datum objects need to manage the colorization of pts/lines
          Adding this into those objects will make the draw method faster. It should 
          be located in a single method to make things less ambiguous.
  - Keyboard shortcuts need completing. Things like screenshot and Ctrl+<accel>
  - Once stats switch is working, implement a check for the slider change (or line 
    selection) to throw a warning if pref.stats.showOriginal != true
    - Slider should only navigate original epochs (not stats lines). To do this, 
      expect that app.ui.Axes.CurrentLines{i}.UserData.index == []. Thus, 
      iris.ui.primary will do nothing when the stats line is clicked.
- Handler:
  - Need to setup Handler to make any modifications to data before plotting. Handler
    is in a optimal location to combine device subsetting, colorization for 
    epoch inclusion and for differing epoch nums (devices get the same color for 
    each epoch). 
  x Need an export method (exportCurrent()) to export the irisData class for analysis
    and modules.
  x Save method implemented already, need a reader for session files. This will 
    require a change in the output information for current readers. Instead of 
    multiple output objects (meta,notes,data), turn reader outputs into struct with
    set names. Then we can have the session reader return a membership field to 
    populate memberships field of handler in the case of many files having been 
    subset. New files can be appended as normal.
x ReadToSession utility needs to have updated reader syntax (when that gets done).
* NOTE: UIOBJ.update() now calls setContainerPrefs, so use it sparingly.
- Create an app resize function. I want it to be able to full screen without issues 
  since this is often how RF uses it. 

- Aggregate method for Handler: 
  - The idea is to move all the mechanisms for retrieving plot data is moved to the Handler and Datum objects. I should remove the plotData object and replace it with handler constructed structs(). When the stats switch is thrown, the user should only be able to navigate the last selected data. The slider should still show the original epoch numbers, but they should map their respective aggregate trace, i.e. that trace should highlight. This will require a major rethink of how the main window interacts with the main axes. My first thought is to create the index property as a vector in the plotting obj and have the AxesPanel object extract a map from the data which has keys that correspond to the original index and values that correspond to 1:nAggregates. This will be something constructed during aggregation but also something that has to have a 1:1 map when stats switch is off.

