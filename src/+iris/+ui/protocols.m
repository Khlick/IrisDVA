classdef protocols < iris.ui.UIContainer
  %PROTOCOLS Display the protocol/experiment parameters for the selected data.
  properties (Access = public)
    ProtocolsTable  matlab.ui.control.Table
    ProtocolsLabel  matlab.ui.control.Label
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
      obj.container.Name = 'Protocols';
      obj.container.SizeChangedFcn = @obj.containerSizeChanged;
      obj.container.Resize = 'on';
      
      % Create ProtocolsTable
      obj.ProtocolsTable = uitable(obj.container);
      obj.ProtocolsTable.ColumnName = {'Property'; 'Value'};
      obj.ProtocolsTable.ColumnWidth = {200, 'auto'};
      obj.ProtocolsTable.ColumnSortable = [true,true];
      obj.ProtocolsTable.RowName = {};
      obj.ProtocolsTable.HandleVisibility = 'off';
      obj.ProtocolsTable.Position = [10, 6, pos(3)-20,pos(4)-50-6];
      obj.ProtocolsTable.CellSelectionCallback = @obj.doCopyUITableCell;
      
      % Create ProtocolsLabel
      obj.ProtocolsLabel = uilabel(obj.container);
      obj.ProtocolsLabel.HorizontalAlignment = 'center';
      obj.ProtocolsLabel.VerticalAlignment = 'bottom';
      obj.ProtocolsLabel.FontName = Aes.uiFontName;
      obj.ProtocolsLabel.FontSize = 28;
      obj.ProtocolsLabel.FontWeight = 'bold';
      obj.ProtocolsLabel.Position = [10,pos(4)-45,pos(3)-20,pos(4)-5];
      obj.ProtocolsLabel.Text = 'Protocols';
    end
  end
  
  %% Callback
  methods (Access = private)
    % Size changed function: container
    function containerSizeChanged(obj,~,~)
      position = obj.container.Position;
      obj.ProtocolsTable.Position = [10,6,position(3)-20,position(4)-50-6];
      obj.ProtocolsLabel.Position = [10,position(4)-45,position(3)-20,position(4)-5];
    end
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