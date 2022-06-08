classdef notes < iris.ui.UIContainer
  %NOTES Display notes accumulated for the current open files.
  properties (Access = public)
    GridLayout matlab.ui.container.GridLayout
    NotesTable  matlab.ui.control.Table
  end
  %% Public methods
  methods (Access = public)
    
    function buildUI(obj,noteCell)
      if nargin < 2, return; end
      if obj.isClosed, obj.rebuild(); end
      obj.setNotes(noteCell);
    end
    
    function append(obj, noteCell)
      validateattributes(noteCell,...
        {'cell'}, {'ncols',2},...
        'IRIS:NOTES:append', 'noteCell');
      obj.NotesTable.Data = cat(1,obj.NotesTable.Data,noteCell);
    end
    
    function clear(obj)
      obj.NotesTable.Data = cell(1,2);
    end
    
    function setNotes(obj,noteCell)
      validateattributes(noteCell,...
        {'cell'}, {'ncols',2},...
        'IRIS:NOTES:setNotes', 'noteCell');
      obj.NotesTable.Data = noteCell;
      lens = cellfun(@length,noteCell(:,2),'UniformOutput',true);
      tWidth = obj.NotesTable.Position(3)-150;
      obj.NotesTable.ColumnWidth = {150, max([tWidth,max(lens)*6.56])};
    end
    
    function selfDestruct(obj)
      % required for integration with menuservices
      obj.shutdown;
    end
    
  end
  %% Startup and Callback Methods
  methods (Access = protected)
    % Startup
    function startupFcn(obj,varargin)
      if nargin > 1
        obj.buildUI(varargin{:});
      end
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
      obj.container.Name = 'Notes';
      obj.container.Resize = 'on';

      % Grid Layout
      obj.GridLayout = uigridlayout(obj.container);
      obj.GridLayout.Padding = [5,10,5,0];
      obj.GridLayout.RowSpacing = 0;
      obj.GridLayout.ColumnSpacing = 0;
      obj.GridLayout.RowHeight = {'1x'};
      obj.GridLayout.ColumnWidth = {'1x'};
      obj.GridLayout.BackgroundColor = obj.container.Color;

      % Create NotesTable
      obj.NotesTable = uitable(obj.GridLayout);
      obj.NotesTable.ColumnName = {'Timestamp'; 'Note'};
      obj.NotesTable.ColumnWidth = {'fit', '1x'};
      obj.NotesTable.RowName = {};
      obj.NotesTable.CellSelectionCallback = @obj.doCopyUITableCell;

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
