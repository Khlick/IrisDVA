classdef notes < iris.ui.UIContainer
  %NOTES Display notes accumulated for the current open files.
  properties (Access = public)
    NotesTable  matlab.ui.control.Table
    NotesLabel  matlab.ui.control.Label
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
      obj.container.SizeChangedFcn = @obj.containerSizeChanged;
      obj.container.Resize = 'on';

      % Create NotesTable
      obj.NotesTable = uitable(obj.container);
      obj.NotesTable.ColumnName = {'Timestamp'; 'Note'};
      obj.NotesTable.ColumnWidth = {150, 'auto'};
      obj.NotesTable.RowName = {};
      obj.NotesTable.HandleVisibility = 'off';
      obj.NotesTable.Position = [10, 6, pos(3)-20,pos(4)-50-6];

      % Create NotesLabel
      obj.NotesLabel = uilabel(obj.container);
      obj.NotesLabel.HorizontalAlignment = 'center';
      obj.NotesLabel.VerticalAlignment = 'bottom';
      obj.NotesLabel.FontName = Aes.uiFontName;
      obj.NotesLabel.FontSize = 28;
      obj.NotesLabel.FontWeight = 'bold';
      obj.NotesLabel.Position = [10,pos(4)-45,pos(3)-20,pos(4)-5];
      obj.NotesLabel.Text = 'Notes';
    end
  end
  
  %% Callback
  methods (Access = private)
    % Size changed function: container
    function containerSizeChanged(obj,~,~)
      position = obj.container.Position;
      obj.NotesTable.Position = [10,6,position(3)-20,position(4)-50-6];
      obj.NotesLabel.Position = [10,position(4)-45,position(3)-20,position(4)-5];
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