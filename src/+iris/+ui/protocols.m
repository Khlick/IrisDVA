classdef protocols < iris.ui.UIContainer
  %PROTOCOLS Display the protocol/experiment parameters for the selected data.
  properties (Access = public)
    GridLayout matlab.ui.container.GridLayout
    ProtocolsTable  matlab.ui.control.Table
  end
  %% Public methods
  methods (Access = public)
    
    function buildUI(obj,protocolCell)
      if nargin<2, return; end
      if obj.isClosed, obj.rebuild; end
      obj.setProtocols(protocolCell);
    end
    
    function append(obj, protocolCell)
      validateattributes(protocolCell,...
        {'cell'}, {'ncols',2},...
        'IRIS:Protocols:append', 'protocolCell');
      obj.ProtocolsTable.Data = cat(1,obj.ProtocolsTable.Data,protocolCell);
    end
    
    function clear(obj)
      obj.ProtocolsTable.Data = cell(1,2);
    end
    
    function setProtocols(obj,protocolCell)
      validateattributes(protocolCell,...
        {'cell'}, {'ncols',2},...
        'IRIS:Protocols:setProtocols', 'protocolCell');
      obj.ProtocolsTable.Data = protocolCell;
      lens = cellfun(@length,protocolCell(:,2),'UniformOutput',false);
      lens(~cellfun(@isnumeric,lens,'UniformOutput',true)) = [];
      lens = [lens{:}];
      tabWidth = obj.ProtocolsTable.Position(3) - 220; %20 px for scrollbar?
      obj.ProtocolsTable.ColumnWidth = {200, max([tabWidth,max(lens)*6.55])};
      obj.ProtocolsTable.ColumnSortable = [true,true];
    end
    
    function selfDestruct(obj)
      % required for integration with menuservices
      obj.shutdown;
    end
    
  end
  %% Startup and Callback Methods
  methods (Access = protected)
    % Startup
    function startupFcn(obj,varargin)%#ok
    end
    % Construct view
    function createUI(obj)
      import iris.app.*;
      
      pos = obj.position;
      if isempty(pos)
        initW = 800;
        initH = 350;
        pos = utilities.centerFigPos(initW,initH);
      end
      obj.position = pos; %sets container too
      
      % Create container
      obj.container.Name = 'Data Properties';
      obj.container.Resize = 'on';
      
      % Grid Layout
      obj.GridLayout = uigridlayout(obj.container);
      obj.GridLayout.Padding = [5,10,5,0];
      obj.GridLayout.RowSpacing = 0;
      obj.GridLayout.ColumnSpacing = 0;
      obj.GridLayout.RowHeight = {'1x'};
      obj.GridLayout.ColumnWidth = {'1x'};
      obj.GridLayout.BackgroundColor = obj.container.Color;
      
      % Create ProtocolsTable
      obj.ProtocolsTable = uitable(obj.GridLayout);
      obj.ProtocolsTable.ColumnName = {'Property'; 'Value'};
      obj.ProtocolsTable.ColumnWidth = {'fit', '1x'};
      obj.ProtocolsTable.RowName = {};
      obj.ProtocolsTable.CellSelectionCallback = @obj.doCopyUITableCell;

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
