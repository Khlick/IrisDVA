classdef dataOverview < iris.ui.UIContainer
  %DATAOVERVIEW Manage currently open data.
  % Properties that correspond to app components
  properties (Access = public)
    FileTree            matlab.ui.container.Tree
    FileNodes
    PropNodes
    PropTable           matlab.ui.control.Table
    SelectSubsetPanel   matlab.ui.container.Panel
    SelectSubsetLabel   matlab.ui.control.Label
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
      obj.SelectSubsetLabel.Text = ...
        { ...
        'Loading...'; ...
        'Selected Datums will show when completed.' ...
        };
      drawnow('limitrate');
      pause(0.01);
      
      obj.recurseNodes();
      
      obj.SelectSubsetLabel.Text = 'Select File Subset';
      
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
        
        %obj.drawnow('limitrate');
        
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
          
          %TODO: recurse structs in d.<type>Configurations
          
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
      % detect handler condition and then hide or shutdown
      
      if obj.Handler.isready
        % just hide rather than kill
        obj.update();
        obj.hide();
      else
        obj.shutdown();
      end
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
      obj.container.SizeChangedFcn = @obj.containerResized;
      if nargin < 2, return; end
      pause(0.05);
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
      firstColWidth = max([120,obj.PropTable.ColumnWidth{1}]);
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
      lens = cellfun(@length,tableDat(:,2),'UniformOutput',true);
      remainderWidth = obj.PropTable.Position(3) - firstColWidth-20;
      obj.PropTable.ColumnWidth = {firstColWidth, max([lens*6.55;remainderWidth])};
    end
    
    % Construct view
    function createUI(obj)
      % TODO: Update to uigridlayout
      
      import iris.app.*;
      
      finalPos = obj.position;
      
      initW = 816;
      initH = 366;
      pos = utilities.centerFigPos(initW,initH);
      obj.position = pos; %sets container too
      
      % Create container
      obj.container.Name = 'Data Overview';
      obj.container.Resize = 'on';
      
      
      % Create FileTree
      obj.FileTree = uitree(obj.container);
      obj.FileTree.FontName = 'Times New Roman';
      obj.FileTree.FontSize = 16;
      obj.FileTree.Position = [15 52 230 304];
      obj.FileTree.Multiselect = 'on';
      obj.FileTree.SelectionChangedFcn = @obj.nodeChanged;
      
      % Create PropTable
      obj.PropTable = uitable(obj.container);
      obj.PropTable.ColumnName = {'Property '; 'Value'};
      obj.PropTable.ColumnWidth = {125, 'auto'};
      obj.PropTable.RowName = {};
      obj.PropTable.FontName = 'Times New Roman';
      obj.PropTable.Position = [255 15 546 341];
      obj.PropTable.Visible = 'off';
      obj.PropTable.CellSelectionCallback = @obj.doCopyUITableCell;
      
      % Create SelectSubsetPanel
      obj.SelectSubsetPanel = uipanel(obj.container);
      obj.SelectSubsetPanel.AutoResizeChildren = 'off';
      obj.SelectSubsetPanel.BackgroundColor = [1 1 1];
      obj.SelectSubsetPanel.FontName = iris.app.Aes.uiFontName;
      obj.SelectSubsetPanel.Position = [255 15 546 341];
      
      % Create SelectSubsetLabel
      obj.SelectSubsetLabel = uilabel(obj.SelectSubsetPanel);
      obj.SelectSubsetLabel.HorizontalAlignment = 'center';
      obj.SelectSubsetLabel.FontName = iris.app.Aes.uiFontName;
      obj.SelectSubsetLabel.FontSize = 20;
      obj.SelectSubsetLabel.Position = [ ...
        546/2 - 546*0.8/2, ...
        341/2 - 341*0.9/2, ...
        546*0.8, ...
        341*0.9 ...
        ];
      %(546-174)/2 158 174 25];
      obj.SelectSubsetLabel.Text = 'Building...';
      
      % Create Actions
      obj.Actions = uidropdown(obj.container);
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
      obj.Actions.Position = [15 15 156 22];
      obj.Actions.Value = 'Actions';
      obj.Actions.ValueChangedFcn = @obj.SelectActions;
      
      % Create Apply
      obj.Apply = uibutton(obj.container, 'push');
      obj.Apply.FontName = 'Times New Roman';
      obj.Apply.Position = [182 15 63 23];
      obj.Apply.Text = 'Apply';
      obj.Apply.Enable = 'off';
      obj.Apply.ButtonPushedFcn = @obj.ApplyAction;
      
      
      % update position
      obj.position = finalPos;
      drawnow('nocallbacks');
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
        obj.PropTable.Visible = 'on';
        obj.SelectSubsetPanel.Visible = 'off';
      end
      
      % update inclusion
      obj.updateDatumIcons()
      
    end
    
    function updateDatumIcons(obj)
      % handler and ui selections should be the same at this point
      incs = obj.Handler.currentSelection.inclusion;
      
      for i = 1:numel(incs)
        if incs(i)
          thisIcon = obj.InclusionIcon;
        else
          thisIcon = obj.ExclusionIcon;
        end
        % set the icon
        obj.FileTree.SelectedNodes(i).Icon = thisIcon;
      end
      % draw?
    end
    
    % Apply action button pressed
    function ApplyAction(obj,~,~)
      try
        [~,inds] = obj.getSelectedInfo();
      catch x
        %log
        warndlg('Cannot process this selection.','Processing Failure');
        return;
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
          
          keepInds = ismember(1:numel(obj.PropNodes),inds);
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
        if strcmp(obj.PropTable.Visible, 'on')
          newStatus = 'off';
        else
          newStatus = 'on';
        end
      end
      obj.PropTable.Visible = newStatus;
      if strcmp(newStatus,'on')
        obj.SelectSubsetPanel.Visible = 'off';
      else
        obj.SelectSubsetPanel.Visible = 'on';
      end
    end
    
    function containerResized(obj,src,~)
      
      obj.position = src.Position;%set ui
      
      obj.FileTree.Position(4) = obj.position(4) - 62;
      pW = obj.position(3) - 265;
      pH = obj.position(4) - 25;
      obj.PropTable.Position(3:4) = [pW,pH];
      obj.SelectSubsetPanel.Position(3:4) = [pW,pH];
      obj.SelectSubsetLabel.Position = [...
        0.2*pW/2, ...
        0.1*pH/2, ...
        pW*0.8, ...
        pH*0.9 ...
        ];
      % set the table width
      firstColWidth = max([120,obj.PropTable.ColumnWidth{1}]);
      tableDat = obj.PropTable.Data;
      if size(tableDat,2) < 2
        % no data in table, simply return
        return
      end
      lens = cellfun(@length,tableDat(:,2),'UniformOutput',true);
      remainderWidth = obj.PropTable.Position(3) - firstColWidth-20;
      obj.PropTable.ColumnWidth = {firstColWidth, max([lens*6.55;remainderWidth])};
    end
    
    function clearView(obj)
      obj.togglePropTable('off');
      obj.isBound = false;
      if isempty(obj.PropNodes), return; end
      
      
      cellfun(@delete,obj.PropNodes,'UniformOutput',false);
      cellfun(@delete,obj.FileNodes,'UniformOutput',false);
    end
    
    function destroyListeners(obj)
      for i = 1:length(obj.handlerListeners)
        delete(obj.handlerListeners{i});
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
  %% Preferences
  methods (Access = protected)
    
    function setContainerPrefs(obj)
      setContainerPrefs@iris.ui.UIContainer(obj);
    end
    
    function getContainerPrefs(obj)
      getContainerPrefs@iris.ui.UIContainer(obj);
    end
    
  end
end