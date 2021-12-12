classdef dataOverview < iris.ui.UIContainer
  %DATAOVERVIEW Manage currently open data.
  % Properties that correspond to app components
  properties (Access = public)
    FileTree            matlab.ui.container.Tree
    FileNodes
    PropNodes
    GridLayout          matlab.ui.container.GridLayout
    PropTable           matlab.ui.control.Table
    ActionsGrid    matlab.ui.container.GridLayout
    ActionsPanel   matlab.ui.container.Panel
    NotifierLabel   matlab.ui.control.Label
    DatumList           matlab.ui.control.ListBox
    Actions             matlab.ui.control.DropDown
    Apply               matlab.ui.control.Button
    Handler
  end
  
  properties (Hidden)
    InclusionIcon = fullfile(iris.app.Info.getResourcePath,'icn','Data_Iconincl.png')
    ExclusionIcon = fullfile(iris.app.Info.getResourcePath,'icn','Data_Iconexcl.png')
    handlerListeners = {}
  end
  
  
  %% Public methods
  methods
    
    function buildUI(obj,handler,force)
      if nargin < 3, force = false; end
      if nargin < 2
        handler = obj.Handler;
      end
      
      if obj.isClosed
        obj.rebuild();
        pause(0.05);
      end
      % determine if we are simply unhiding the window or need to reconstruct it
      newHandler = ~isequal(handler,obj.Handler);
      
      obj.show();
      
      if obj.isBound && ~newHandler && ~force
        return
      end
      % if a new handler was provided we need to destroy previous handler listeners
      % and then reassign our handler handle
      
      if newHandler || force
        obj.destroyListeners();
        obj.Handler = handler;
      end
      
      obj.clearView();
      
      obj.FileNodes = cell(handler.nFiles,1);
      obj.PropNodes = {};
      obj.NotifierLabel.Text = ...
        { ...
        'Loading...'; ...
        'Selected Datums will show when completed.' ...
        };
      drawnow('limitrate');
      pause(0.01);
      
      obj.recurseNodes();
      
      obj.NotifierLabel.Text = 'Select File Subset';
      
      % set selected from handler
      obj.setSelectionFromHandler();
      
      if newHandler || force
        % set and enable listener
        obj.handlerListeners{end+1} = addlistener( ...
          handler, ...
          'onSelectionUpdated', @(s,e)obj.onHandlerUpdate(e) ...
          );
        obj.handlerListeners{end+1} = addlistener( ...
          handler, ...
          'onCompletedLoad', @(s,e)obj.onHandlerUpdate(e) ...
          );
      end
      if ~event.hasListener(obj,'Close')
        addlistener(obj, 'Close', @(s,e)obj.selfDestruct());
      end
      obj.isBound = true;
    end
    
    function recurseNodes(obj)
      hd = obj.Handler;
      % Create parent Node for each file
      for p = 1:hd.nFiles
        mbr = hd.membership{p};
        dataInds = mbr.data;
        inclStatus = hd.Tracker.getStatus.inclusions(dataInds);
        d = hd(dataInds);
        [~,fn,ex] = fileparts(hd.fileList{p});
        thisNode = uitreenode(obj.FileTree, ...
          'Text', [fn,ex] );
        thisNode.Icon = fullfile( ...
          iris.app.Info.getResourcePath,...
          'icn', ...
          'File_Icon.png' ...
          );
        
        thisNode.NodeData = [];
        % create childNode for each datum
        for i = 1:length(d)
          thisChildNode = uitreenode(thisNode, ...
            'Text', d(i).id );
          thisChildNode.NodeData = d(i).getPropsAsCell;
          if inclStatus(i)
            icn = obj.InclusionIcon;
          else
            icn = obj.ExclusionIcon;
          end
          thisChildNode.Icon = icn;
          if i == 1
            thisNode.expand;
          end
          
          if ~mod(i,10)
            drawnow('limitrate');
          end
          
          obj.PropNodes{end+1} = thisChildNode;
        end
        
        obj.FileNodes{p} = thisNode;
      end
    end
    
    function selfDestruct(obj)
      % required for integration with menuservices
      obj.shutdown();
    end
    
    function shutdown(obj)
      obj.clearView();
      obj.destroyListeners();
      obj.Handler = [];
      shutdown@iris.ui.UIContainer(obj);
    end
  end
  %% Startup Methods
  methods (Access = protected)
    
    % Startup
    function startupFcn(obj,handler)
      if nargin < 2, return; end
      obj.GridLayout.ColumnWidth{2} = 0;
      drawnow();
      obj.buildUI(handler);
    end
    
    %handler selection was updated
    function onHandlerUpdate(obj,event)
      % if the window is open, we need to update the view. Otherwise we will let the
      % buildUI() method handle the update.
      if ~obj.isVisible, return; end
      
      if endsWith(event.EventName,'Updated')
        % selection update triggered
        obj.setSelectionFromHandler();
      elseif endsWith(event.EventName,'Load')
        % new files were loaded, rebuild the ui
        obj.isBound = false;
        obj.buildUI();
      else
        % future.
      end
    end
    
    % Set Table Data
    function setData(obj,d)
      % flatten table to unique first column
      keyNames = unique(d(:,1),'stable');
      keyData = cellfun( ...
        @(x)d(ismember(d(:,1),x),2), ...
        keyNames, ...
        'UniformOutput', false ...
        );
      if length(keyNames) == size(d,1)
        tableDat = d;
      else
        tableDat = [ ...
          keyNames(:), ...
          keyData(:) ...
          ];
      end
      % set all values column to strings
      tableDat(:,2) = arrayfun(@utilities.unknownCell2Str,tableDat(:,2),'unif',0);
      %set
      obj.PropTable.Data = tableDat;
    end

    % Construct view
    function createUI(obj)
      
      import iris.app.*;
      import matlab.ui.layout.GridLayoutOptions;
      
      finalPos = obj.position;
      
      initW = 816;
      initH = 366;
      pos = utilities.centerFigPos(initW,initH);
      obj.position = pos; %sets container too
      
      % Create container
      obj.container.Name = 'Data Overview';
      obj.container.Resize = 'on';

      % Create the Grid Layout
      obj.GridLayout = uigridlayout(obj.container);
      obj.GridLayout.BackgroundColor = obj.container.Color;
      obj.GridLayout.Padding = [10 10 10 10];
      obj.GridLayout.RowSpacing = 3;
      obj.GridLayout.ColumnSpacing = 3;
      obj.GridLayout.RowHeight = {'1x',36};
      obj.GridLayout.ColumnWidth = {250,'1x','1x'};
      
      % Create FileTree
      obj.FileTree = uitree(obj.GridLayout,'Layout',GridLayoutOptions('Row',1,'Column',1));
      obj.FileTree.FontName = 'Times New Roman';
      obj.FileTree.FontSize = 16;
      obj.FileTree.Multiselect = 'on';
      obj.FileTree.SelectionChangedFcn = @obj.nodeChanged;
      
      % Create PropTable
      obj.PropTable = uitable(obj.GridLayout,'Layout',GridLayoutOptions('Row',[1,2],'Column',2));
      obj.PropTable.ColumnName = {'Property '; 'Value'};
      obj.PropTable.ColumnWidth = {'fit', '1x'};
      obj.PropTable.RowName = {};
      obj.PropTable.FontName = 'Times New Roman';
      obj.PropTable.Visible = 'off';
      obj.PropTable.CellSelectionCallback = @obj.doCopyUITableCell;
      
      % Create NotifierLabel
      obj.NotifierLabel = uilabel(obj.GridLayout,'Layout',GridLayoutOptions('Row',[1,2],'Column',3));
      obj.NotifierLabel.HorizontalAlignment = 'center';
      obj.NotifierLabel.FontName = iris.app.Aes.uiFontName;
      obj.NotifierLabel.FontSize = 20;
      obj.NotifierLabel.Text = 'Building...';
      
      % Create ActionsPanel
      obj.ActionsPanel = uipanel(obj.GridLayout,'Layout',GridLayoutOptions('Row',2,'Column',1));
      obj.ActionsPanel.BackgroundColor = obj.container.Color;
      obj.ActionsPanel.FontName = iris.app.Aes.uiFontName;
      
      % Create ActionsGrid
      obj.ActionsGrid = uigridlayout(obj.ActionsPanel);
      obj.ActionsGrid.BackgroundColor = obj.container.Color;
      obj.ActionsGrid.RowSpacing = 3;
      obj.ActionsGrid.ColumnSpacing = 3;
      obj.ActionsGrid.Padding = [2,5,2,5];
      obj.ActionsGrid.ColumnWidth = {'1x',63};
      obj.ActionsGrid.RowHeight = {'1x'};
      
      obj.show;
      % Create Actions
      obj.Actions = uidropdown(obj.ActionsGrid,'Layout',GridLayoutOptions('Row',1,'Column',1));
      obj.Actions.Items = { ...
        'Actions', ...
        'Exclude Selected', ...
        'Include Selected', ...
        'Delete Selected', ...
        'Delete Unselected', ...
        'Export Selected' ...
        };
      obj.Actions.FontName = 'Times New Roman';
      obj.Actions.FontSize = 14;
      obj.Actions.Value = 'Actions';
      obj.Actions.ValueChangedFcn = @obj.SelectActions;
      
      % Create Apply
      obj.Apply = uibutton(obj.ActionsGrid,'Layout',GridLayoutOptions('Row',1,'Column',2));
      obj.Apply.FontName = 'Times New Roman';
      obj.Apply.Text = 'Apply';
      obj.Apply.Enable = 'off';
      obj.Apply.ButtonPushedFcn = @obj.ApplyAction;
      
      
      % update position
      obj.position = finalPos;
      drawnow;
      pause(0.01);
    end
    
  end
  
  %% Callback
  methods (Access = private)
    % Selected Action changed
    function SelectActions(obj,~,evt)
      if strcmp(evt.Value, 'Actions')
        obj.Apply.Enable = 'off';
      else
        obj.Apply.Enable = 'on';
      end
    end

    % set Selection based on handler.currentSelection
    function setSelectionFromHandler(obj)
      if ~isequal( ...
          obj.FileTree.SelectedNodes, ...
          [obj.PropNodes{obj.Handler.currentSelection.selected}] ...
          )
        % changing the selection
        obj.FileTree.SelectedNodes = [obj.PropNodes{obj.Handler.currentSelection.selected}];
        obj.FileTree.scroll(obj.PropNodes{obj.Handler.currentSelection.selected(end)});
      end
      
      obj.getSelectedInfo();
      
      if strcmp(obj.PropTable.Visible,'off')
        obj.togglePropTable('on');
      end
      
      % update inclusion
      obj.updateDatumIcons()
      
    end
    
    function updateDatumIcons(obj)
      % updates the icons
      currentSelectedNode = {obj.FileTree.SelectedNodes.Text};
      % dont set icons for file entry
      iconableMember = ~ismember( ...
        currentSelectedNode, ...
        cellfun(@(x)x.Text,obj.FileNodes,'UniformOutput',false) ...
        );
      % handler and ui selections should be the same at this point
      incs = obj.Handler.currentSelection.inclusion;
      for i = 1:numel(incs)
        if ~iconableMember(i), continue; end
        if incs(i) 
          thisIcon = obj.InclusionIcon;
        else
          thisIcon = obj.ExclusionIcon;
        end
        % set the icon
        obj.FileTree.SelectedNodes(i).Icon = thisIcon;
      end
    end
    
    % Apply action button pressed
    function ApplyAction(obj,~,~)
      try
        [~,inds] = obj.getSelectedInfo();
      catch x
        %log
        iris.app.Info.throwError(sprintf('Cannot process selection for reason: "%s"',x.message));
      end
      switch obj.Actions.Value
        case 'Exclude Selected'
          obj.Handler.setInclusion(inds,false);
        case 'Include Selected'
          obj.Handler.setInclusion(inds,true);
        case {'Delete Selected','Delete Unselected'}
          deleteType = subsref( ...
            strsplit(obj.Actions.Value,' '), ...\
            struct('type', '{}', 'subs', {{2}}) ...
            );
          
          keepInds = ismember(1:obj.Handler.nDatum,inds);
          if strcmp(deleteType,'Selected')
            keepInds = ~keepInds;
          end
          h = obj.Handler.subset(keepInds);
          
          obj.clearView();
          obj.buildUI(h, true);
          
        case 'Export Selected'
          obj.exportSelectedData();
        otherwise
          return
      end
    end
    
    % Selection Node changed.
    function nodeChanged(obj,~,evt)
      if ~isempty(evt.SelectedNodes)
        if isequal(evt.SelectedNodes,evt.PreviousSelectedNodes), return; end
        selectedNames = {evt.SelectedNodes.Text};
        if any( ...
            ismember( ...
            selectedNames, ...
            cellfun(@(x)x.Text,obj.FileNodes,'unif',0) ...
            ) ...
            )
          obj.togglePropTable('off');
          return
        end
        obj.getSelectedInfo();
        obj.togglePropTable('on');
      else
        obj.togglePropTable('off');
      end
    end
    
    % get the info from the selected ID
    function [infos,selectedIndex] = getSelectedInfo(obj)
      % sort by Node Text?
      sNodes = obj.FileTree.SelectedNodes;
      if isempty(sNodes)
        error('No nodes selected');
      end
      nodeNames = arrayfun(@(x)x.Text,sNodes,'UniformOutput',false);
      [~,sortInd] = sort(nodeNames);
      
      infos = arrayfun( ...
        @(x)x.NodeData, ...
        obj.FileTree.SelectedNodes(sortInd), ....
        'UniformOutput', false ...
        );
      selectedIndex = cellfun( ...
        @(v) str2double(v{ismember(v(:,1),'index'),2}), ...
        infos, ...
        'UniformOutput', true ...
        );
      
      if ~nargout
        if ~isequal(obj.Handler.currentSelection.selected, selectedIndex)
          obj.Handler.currentSelection = selectedIndex;
        end
        obj.setData(cat(1,infos{:}));
        pause(0.05);
      end
    end
    
    function togglePropTable(obj,newStatus)
      if nargin < 2
        newStatus = ~strcmp(obj.PropTable.Visible, 'on');
      end
      newStatus = matlab.lang.OnOffSwitchState(newStatus);
      
      % disallow calling toggle ON when file node selected.
      [tf,~] = obj.isFileNodeSelected();
      if tf && newStatus, return; end
      obj.PropTable.Visible = newStatus;
      obj.NotifierLabel.Visible = ~newStatus;
      if ~~newStatus
        widths = {'1x',0};
      else
        widths = {0,'1x'};
      end
      obj.GridLayout.ColumnWidth(2:3) = widths;
    end
    
    function clearView(obj)
      obj.togglePropTable('off');
      obj.isBound = false;
      if isempty(obj.PropNodes), return; end
      
      
      cellfun(@delete,obj.PropNodes,'UniformOutput',false);
      cellfun(@delete,obj.FileNodes,'UniformOutput',false);
    end
    
    function destroyListeners(obj)
      hasALs = isprop(obj.Handler,'AutoListeners__');
      for i = 1:length(obj.handlerListeners)
        lsn = obj.handlerListeners{i};
        if hasALs
          idx = cellfun(@(AL) isequal(AL,lsn), obj.Handler.AutoListeners__,'unif',1);
          cellfun(@delete,obj.Handler.AutoListeners__(idx));
          obj.Handler.AutoListeners__(idx) = [];
        end
        delete(lsn);
      end
      obj.handlerListeners = {};
    end
    
    function doCopyUITableCell(obj,source,event) %#ok<INUSL>
      try
        ids = event.Indices;
        nSelections = size(ids,1);
        merged = cell(nSelections,1);
        for sel = 1:nSelections
          merged{sel} = source.Data{ids(sel,1),ids(sel,2)};
        end
        stringified = utilities.unknownCell2Str(merged,';',false);
        clipboard('copy',stringified);
      catch x
        fprintf('Copy failed for reason:\n "%s"\n',x.message);
      end
    end
    
  end
  %% Utilities
  methods (Access = protected)
    
    function setContainerPrefs(obj)
      setContainerPrefs@iris.ui.UIContainer(obj);
    end
    
    function getContainerPrefs(obj)
      getContainerPrefs@iris.ui.UIContainer(obj);

    end

    function [tf,vec] = isFileNodeSelected(obj)
      currentSelections = obj.FileTree.SelectedNodes;
      if isempty(currentSelections),tf = false; vec = false(0,1); return; end
      currentSelectedNode = {currentSelections.Text};
      vec = ismember( ...
        currentSelectedNode, ...
        cellfun(@(x)x.Text,obj.FileNodes,'UniformOutput',false) ...
        );
      tf = any(vec);
    end
    
  end
end
