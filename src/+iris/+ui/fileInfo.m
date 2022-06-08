classdef fileInfo < iris.ui.UIContainer
  %FILEINFO Displays metadata information attached to each open file.
  % Properties that correspond to app components
  properties (Access = public)
    GridLayout matlab.ui.container.GridLayout
    FileTree        matlab.ui.container.Tree
    PropNodes    
    PropTable       matlab.ui.control.Table
  end
  properties (Dependent)
    isclear
    hasnodes
  end
  %% Public methods
  methods
    
    function buildUI(obj,varargin)
      if nargin < 2, return; end
      if obj.isClosed, obj.rebuild(); end
      
      obj.clearView();
      
      obj.show;
      files = [varargin{:}];
      obj.PropNodes = {};
      obj.recurseInfo(files, 'File', obj.FileTree);
      obj.FileTree.expand();
      obj.FileTree.SelectedNodes = obj.PropNodes{1};
      obj.setData(obj.PropNodes{1}.NodeData);
    end
    
    function tf = get.isclear(obj)
      tf = isempty(obj.PropTable.Data);
    end
    
    function tf = get.hasnodes(obj)
      tf = ~isempty(obj.PropNodes);
    end
    
    function selfDestruct(obj)
      obj.shutdown;
    end
    
  end
  %% Startup and Callback Methods
  methods (Access = protected)
    % Startup
    function startupFcn(obj,varargin)
      if nargin < 2, return; end
      obj.buildUI(varargin{:});
    end
    %recursion
    function recurseInfo(obj, S, name, parentNode)
      for f = 1:length(S)
        if iscell(S)
          this = S{f};
        else
          this = S(f);
        end
        props = fieldnames(this);
        vals = struct2cell(this);
        %find nests
        notNested = cellfun(@(v) ~isstruct(v),vals,'unif',1);
        if ~isfield(this,'File')
          hasName = contains(lower(props),'name');
          if any(hasName)
            nodeName = sprintf('%s (%s)',vals{hasName},name);
          else
            nodeName = sprintf('%s %d', name, f);
          end
        else
          nodeName = this.File;
        end
        thisNode = uitreenode(parentNode, ...
          'Text', nodeName );
        if any(notNested)
          thisNode.NodeData = [props(notNested),vals(notNested)];
        else
          thisNode.NodeData = [{},{}];
        end
        obj.PropNodes{end+1} = thisNode;
        %gen nodes
        if ~any(~notNested), continue; end
        isNested = find(~notNested);
        for n = 1:length(isNested)
          nestedVals = vals{isNested(n)};
          % if the nested values is an empty struct, don't create a node.
          areAllEmpty = all( ...
            arrayfun( ...
              @(sss)all( ...
                cellfun( ...
                  @isempty, ...
                  struct2cell(sss), ...
                  'UniformOutput', 1 ...
                  ) ...
                ), ...
              nestedVals, ...
              'UniformOutput', true ...
              ) ...
            );
          if areAllEmpty, continue; end
          obj.recurseInfo(nestedVals,props{isNested(n)},thisNode);
        end
      end
    end
    
    % Set Table Data
    function setData(obj,d)
      d(:,2) = arrayfun(@utilities.unknownCell2Str,d(:,2),'unif',0);
      obj.PropTable.Data = d;
      lens = cellfun(@length,d(:,2),'UniformOutput',true);
      tWidth = obj.PropTable.Position(3)-127;
      obj.PropTable.ColumnWidth = {125, max([tWidth,max(lens)*6.55])};
    end
    
    
    % Construct view
    function createUI(obj)
      import iris.app.*;
      
      pos = obj.position;
      if isempty(pos)
        initW = 616;
        initH = 366;
        pos = utilities.centerFigPos(initW,initH);
      end
      obj.position = pos; %sets container too
      
      % Create container
      obj.container.Name = 'File Info';
      obj.container.Resize = 'on';
      
      % Grid Layout
      obj.GridLayout = uigridlayout(obj.container);
      obj.GridLayout.Padding = [5,10,5,0];
      obj.GridLayout.RowSpacing = 0;
      obj.GridLayout.ColumnSpacing = 0;
      obj.GridLayout.RowHeight = {'1x'};
      obj.GridLayout.ColumnWidth = {'fit','1x'};
      obj.GridLayout.BackgroundColor = obj.container.Color;

      % Create FileTree
      obj.FileTree = uitree(obj.GridLayout);
      obj.FileTree.FontName = 'Times New Roman';
      obj.FileTree.FontSize = 16;
      obj.FileTree.Multiselect = 'off';
      obj.FileTree.SelectionChangedFcn = @obj.getSelectedInfo;

      % Create PropTable
      obj.PropTable = uitable(obj.GridLayout);
      obj.PropTable.ColumnName = {'Property'; 'Value'};
      obj.PropTable.ColumnWidth = {'fit', '1x'};
      obj.PropTable.RowName = {};
      obj.PropTable.CellSelectionCallback = @obj.doCopyUITableCell;
      
    end
    
    %Destruct View
    function clearView(obj)
      if obj.hasnodes
        cellfun(@delete,obj.PropNodes,'UniformOutput',false);
      end
      if ~obj.isclear
        obj.PropTable.Data = {[],[]};
      end
    end
  end
  
  %% Callback
  methods (Access = private)
    % copy cell contents callback
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
    % Selection Node changed.
    function getSelectedInfo(obj,~,evt)
      if ~isempty(evt.SelectedNodes)
        obj.setData(evt.SelectedNodes.NodeData);
      else
        obj.setData({[],[]});
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
