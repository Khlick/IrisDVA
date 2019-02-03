classdef fileInfo < iris.ui.UIContainer
  %FILEINFO Displays metadata information attached to each open file.
  % Properties that correspond to app components
  properties (Access = public)
    FileInfoLabel   matlab.ui.control.Label
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
      
      obj.clearView;
      
      obj.show;
      files = [varargin{:}];
      obj.PropNodes = {};
      obj.recurseInfo(files, 'File', obj.FileTree);
    end
    
    function tf = get.isclear(obj)
      tf = isempty(obj.PropTable.Data);
    end
    
    function tf = get.hasnodes(obj)
      tf = ~isempty(obj.PropNodes);
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
          nodeName = sprintf('%s %d', name, f);
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
        if ~any(~notNested), return; end
        isNested = find(~notNested);
        for n = 1:length(isNested)
          obj.recurseInfo(vals{isNested(n)},props{isNested(n)},thisNode);
        end
      end
    end
    
    % Set Table Data
    function setData(obj,d)
      d(:,2) = arrayfun(@unknownCell2Str,d(:,2),'unif',0);
      obj.PropTable.Data = d;
    end
    
    
    % Construct view
    function createUI(obj)
      import iris.app.*;
      
      pos = obj.position;
      if isempty(pos)
        initW = 616;
        initH = 366;
        pos = centerFigPos(initW,initH);
      end
      obj.position = pos; %sets container too
      w = pos(3);
      h = pos(4);
      
      treeW = min([floor(w*0.33),208]);
      
      
      % Create container
      obj.container.Name = 'File Info';
      obj.container.SizeChangedFcn = @obj.containerSizeChanged;
      obj.container.Resize = 'on';
      
      % Create FileTree
      obj.FileTree = uitree(obj.container);
      obj.FileTree.FontName = 'Times New Roman';
      obj.FileTree.FontSize = 16;
      obj.FileTree.Multiselect = 'off';
      obj.FileTree.SelectionChangedFcn = @obj.getSelectedInfo;

      % Create PropTable
      obj.PropTable = uitable(obj.container);
      obj.PropTable.ColumnName = {'Property'; 'Value'};
      obj.PropTable.ColumnWidth = {125, 'auto'};
      obj.PropTable.RowName = {};
      obj.PropTable.HandleVisibility = 'off';
      

      % Create FileInfoLabel
      obj.FileInfoLabel = uilabel(obj.container);
      obj.FileInfoLabel.HorizontalAlignment = 'Left';
      obj.FileInfoLabel.VerticalAlignment = 'bottom';
      obj.FileInfoLabel.FontName = Aes.uiFontName;
      obj.FileInfoLabel.FontSize = 22;
      obj.FileInfoLabel.FontWeight = 'bold';
      
      obj.FileInfoLabel.Text = '  File Info';
      
      obj.FileTree.Position = [10 10 treeW h-35-10-10];
      obj.PropTable.Position = [treeW+8+10, 10, w-treeW-7-10-10,h-10-10];
      obj.FileInfoLabel.Position = [10,h-35,treeW,35];
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
    % Size changed function: container
    function containerSizeChanged(obj,~,~)
      pos = obj.container.Position;
      w = pos(3);
      h = pos(4);
      treeW = min([floor(w*0.33),208]);
      obj.FileTree.Position = [10 10 treeW h-35-10-10];
      obj.PropTable.Position = [treeW+8+10, 10, w-treeW-7-10-10,h-10-10];
      obj.FileInfoLabel.Position = [10,h-35,treeW,35];
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