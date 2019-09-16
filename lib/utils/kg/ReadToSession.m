function saveName = ReadToSession(verbose)
%READTOSESSION Read a supported data file into an Iris Session file.
%   This method will use a local parallel pool to convert multiple files to iris
%   session files. The purpose of this function is to decrease read times for
%   multiple files imported into Iris. A small GUI is created to prompt for
%   options and file selection.

% Initialize some environment variables
if ~nargin, verbose = false; end
grobs = gobjects(5,1);
% acceptable files
vf = iris.data.validFiles;
openDir = iris.pref.Iris.getDefault().UserDirectory;
if isempty(openDir)
  openDir = cd;
end
files = cell(1,2);
hasFiles = false;
mergeFiles = false;
abort = true;


% Create the GUI and wait for the user to complete the process.
makeGui();

if abort || ~hasFiles 
  saveName = {};
  return
end

fullFiles = fullfile(files(:,2),files(:,1));


[totalDataSize,eachFileSize] = iris.app.Info.getBytes(fullFiles);
accDataRead = 0;

LS = iris.ui.loadShow();
LS.updatePercent('Parsing files...');
pause(1);

nf = size(files,1);

if nf > 1
  POOL = gcp();
  cleanUpFx = @() cleanupWithPool(POOL,LS);
else
  cleanUpFx = @() cleanupNoPool(LS);
end

reader = cell(nf,1);
skipped = cell(nf,2);
S = cell(1,nf);

if nf == 1
  
  reader{1} = vf.getReadFxnFromFile(files{1,1});
  try
    S{1} = feval(reader{1},fullFiles{1});
  catch er
    skipped(1,:) = [files(1,1),{er.message}];
  end
  
else
  % using parallel pool
  % build future calls
  for I = 1:nf
    reader = str2func(vf.getReadFxnFromFile(files{I,1}));
    futures(I) = parfeval(POOL,reader,1,fullFiles{I}); %#ok<AGROW>
  end
  % collect from futures
  for I = 1:nf
    try
      [cIdx,S_par] = futures.fetchNext();
      S{cIdx} = S_par;
      if verbose
        fprintf('Successful parsing of "%s".\n', files{cIdx,1});
      end
    catch er
      skipped(I,:) = [files(I,1),{er.message}];
    end
    accDataRead = accDataRead + eachFileSize(cIdx);
    if accDataRead/totalDataSize < 1
      LS.updatePercent(accDataRead/totalDataSize);
    else
      LS.updatePercent('Loaded!');
    end
  end

end
pause(1.3);

LS.updatePercent('Saving sessions...');
pause(1.3);

%%%

skippedSlots = cellfun(@isempty, S, 'UniformOutput', true);
skipped = skipped(skippedSlots,:);

if ~isempty(skipped)
  fprintf('\nThe Following files were skipped:\n');
  for ss = 1:size(skipped,1)
    fprintf('  File: "%s"\n    For reason: "%s".\n', skipped{ss,:});
  end
end

S = S(~skippedSlots);
files = files(~skippedSlots,:);

fInfo = vf.getIDFromLabel('Session');

saveName = fullfile( ...
  files(:,2), ...
  regexprep( ...
    files(:,1), ...
    '(?<=\.)\w+$', ...
    fInfo.exts{1} ...
    ) ...
  )';

% files to be saved will have the same name as input file but with the .isf
% extension.

if mergeFiles && length(S) > 1
  % files were not saved on parallel thread, so merge to single 
  % make single session from output Structs.
  S = [S{:}];
  session = struct();
  session.Meta = [S.Meta];
  session.Notes = [S.Notes];
  session.Data = [S.Data];
  session.Files = saveName;
  filterText = { ...
    strjoin(strcat('*.',fInfo.exts),';'), ...
    fInfo.label ...
    };
  % create a generic save name with filter
  fn = fullfile( ...
    app.options.UserDirectory, ...
    [datestr(app.sessionInfo.sessionStart,'YYYY-mmm-DD'),'.',fInfo.exts{1}] ...
    );
  % prompt user for final save location
  userFile = [];
  while isempty(userFile)
    userFile = iris.app.Info.putFile('Save Iris Session', filterText, fn);
    if isempty(userFile)
      iris.app.Info.showWarning('Provide a valid file name.');
    end
  end
  saveName = {userFile};
  save(userFile,'session','-mat','-v7.3');
else
  for I = 1:length(S)
    session = S{I};
    save(saveName{I},'session', '-mat', '-v7.3');
    pause(1);
  end
end

% Finally
cleanUpFx();

%% Functions
  function makeGui()
  %{
  warnState = warning('query', ...
    'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame' ...
    );
  warning('off', 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
  %}
  w = 400;
  h = 480;
  
  % Create and hide the figure. Then prompt to select supported files
  grobs(1) = figure( ...
    'Visible', 'off', ...
    'NumberTitle', 'off', ...
    'MenuBar', 'none', ...
    'Toolbar', 'none', ...
    'DockControls', 'off', ...
    'Interruptible', 'on', ...
    'HitTest', 'off', ...
    'Color', [1,1,1], ...
    'CloseRequestFcn', @closeGui ...
    );
  figName = 'Iris Session Creator';
  set(grobs(1), ...
    'Position', centerFigPos(w,h), ...
    'Name', figName, ...
    'Units', 'Pixels', ...
    'Resize', 'off' ...
    );
  
  % listbox
  grobs(2) = uicontrol(grobs(1), ...
    'Style', 'Listbox', ...
    'Position', [15, 10, w-15-105, h-15], ...
    'FontName', 'Times New Roman', ...
    'FontSize', 14 ...
    );
  
  grobs(1).Units = 'normalized';
  
  % create buttons
  
  % Submit for reading
  grobs(4) = uicontrol(grobs(1), ...
    'Style', 'PushButton', ...
    'FontName', 'Times New Roman', ...
    'FontWeight', 'bold', ...
    'String', 'Convert', ...
    'Enable', 'off', ...
    'Position', [w-105+10, (h-30)/2 + 15 - 12.5, 85, 25], ...
    'Callback', @submit ...
    );
  
  % select files
  grobs(3) = uicontrol(grobs(1), ...
    'Style', 'PushButton', ...
    'String', 'Select', ...
    'FontName', 'Times New Roman', ...
    'Position', grobs(4).Position + [0,40,0,0], ...
    'Callback', @getFiles ...
    );
  
  % Cancel and bail out;
  grobs(5) = uicontrol(grobs(1), ...
    'Style', 'PushButton', ...
    'String', 'Clear', ...
    'FontName', 'Times New Roman', ...
    'Position', grobs(4).Position + [0,-40,0,0], ...
    'Callback', @doClear ...
    );
  
  % Cancel and bail out;
  grobs(6) = uicontrol(grobs(1), ...
    'Style', 'PushButton', ...
    'String', 'Cancel', ...
    'FontName', 'Times New Roman', ...
    'Position', grobs(4).Position + [0,-80,0,0], ...
    'Callback', @bail ...
    );
  
  grobs(7) = uicontrol(grobs(1), ...
    'Style', 'checkbox', ...
    'String', 'Merge', ...
    'BackgroundColor', [1 1 1], ...
    'Value', 0, ...
    'FontSize', 10, ...
    'Enable', 'off', ...
    'FontName', 'Times New Roman', ...
    'Position', grobs(4).Position + [15,40+25+15,-25,0] ...
    );
  
  grobs(1).Visible = 'on';
  
  pause(0.1);
  
  % Get the java component before adding buttons to decrease wait time
  %{
  warnState = warning('query', ...
    'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame' ...
    );
  warning('off', 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
  %}
  
  jPane = findjobj(grobs(2));
  jList = handle( ...
    jPane.getViewport.getComponent(0), ...
    'callbackproperties' ...
    );
  
  set( jList, ...
    'MousePressedCallback', @mouseDown, ...
    'MouseReleasedCallback', @mouseUp  ...
    );
  
  jDD = handle( java.awt.dnd.DropTarget(), 'CallbackProperties' );
  
  set( jDD, ...
    'DragOverCallback', @dragged, ...
    'DropCallback', @target ...
    );
  % Configure drag-and-drop on the listbox and attach the DND object
  set( jList, ...
    'DragSelectionEnabled', false, ....
    'DragEnabled', true, ...
    'DropMode', javax.swing.DropMode.INSERT ...
    );
  jList.setDropTarget( jDD );
  
  
  uiwait(grobs(1));
  
  %{
  warning(warnState.state, ...
    'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame' ...
    );
  
  %jScrollPane.setVerticalScrollBarPolicy( ...
  %  javax.swing.ScrollPaneConstants.VERTICAL_SCROLLBAR_AS_NEEDED ...
  %  );
  %}
  init = [];
  %% Callbacks for buttons
  function submit(~,~)
    abort = false;
    mergeFiles = grobs(7).Value;
    uiresume(grobs(1));
    delete(grobs(1));
  end

  function getFiles(~,~)
    ftext = vf.getFilterText();
    ftext(contains(ftext(:,1),'.isf'),:) = [];
    % prompt for files
    [f,idx,r] = iris.app.Info.getFile( ...
      'Load Data Files', ...
      ftext, ...
      openDir, ...
      'MultiSelect', 'on' ...
      );
    r = {r};
    if isempty(f), return; end
    exts = regexprep(regexprep(ftext{idx,1},'\*\.',''),';','|');
    
    f = regexprep(f, ['.+\\(?=[\w-]+\.[',exts,'])'], '');
    %concat
    files = [files;[f(:),r(ones(length(f),1))]];
    
    files(cellfun(@isempty,files(:,1),'unif',1),:) = [];
    
    [~,ia] = unique(strcat(files(:,2),files(:,1)),'stable');
    files = files(ia,:);
    
    grobs(2).String = files(:,1);
    grobs(4).Enable = 'on';
    grobs(7).Enable = 'on';
    hasFiles = true;
  end

  function closeGui(~,~)
    if ~isvalid(grobs(1)), return; end
    if hasFiles
      doQuit = iris.ui.questionBox( ...
        'Prompt', 'You have files in the queue, are you sure?', ...
        'Title', 'Quit Conversion', ...
        'Options', {'Yes','Cancel'}, ...
        'Default', 'Yes' ...
        );
      if strcmp(doQuit.response,'Cancel')
        return
      end
    end
    abort = true;
    uiresume(grobs(1));
    delete(grobs(1));
  end
  
  function doClear(~,~)
    files = cell(1,2);
    hasFiles = false;
    grobs(4).Enable = 'off';
    grobs(7).Enable = 'off';
    grobs(2).String = {};
  end
  
  function bail(~,~)
    abort = true;
    uiresume(grobs(1));
    delete(grobs(1));
  end


  %% Callbacks for changing file order
  function mouseDown( src, evt )
    init = src.locationToIndex( evt.getPoint ) + 1;

    % Make sure the listbox gains focus when it's clicked
    src.requestFocus();
  end
  function mouseUp  ( src, evt )
    init = [];
  end
  function target   ( src, evt )
    init = [];
  end
  function dragged  ( src, evt )
    mouseInd = jList.locationToIndex( evt.getLocation ) + 1;
    moveInd = mouseInd - init;

    % Only proceed if the mouse has moved at least one item
    if moveInd
      % Retrieve the list contents and selection
      str = get( grobs(2), 'String' );
      val = get( grobs(2), 'Value' );

      % Update the selection (the click isn't always registered)
      if ~ismember( init, val )
          val = init;
      end

      % Update the log of the mouse's position
      init = mouseInd;

      % Shift the selected items by moveInd, and update the listbox
      [ str val permOrder ] = doPerm( str, val, moveInd );
      set( grobs(2), 'String', str, 'Value', val );

      % Make sure the selected items are visible
      if moveInd > 0
        jList.ensureIndexIsVisible( val(end)-1 );
      else
        jList.ensureIndexIsVisible( val(1)-1 );
      end
    else
      % If list doesn't change, create default permOrder
      str = get( grobs(2), 'String' );
      permOrder = 1 : length( str );
    end
  end
  function [S,V,P] = doPerm( s,v,i )
    if ~i
      S = s;
      V = v;
      P = 1:length(s);
      return
    end
    nItems = length(s);
    nSel = length(v);
    if i > 0
      V = min( v+i, nItems - (nSel-1 :-1: 0) );
    else
      V = max( v+i, (1:nSel) );
    end
    
    allItems = 1:nItems;
    P([V, setdiff(allItems,V)]) = [v, setdiff(allItems,v)];
    S = s(P);
  end
end

end

% external Functions
function cleanupWithPool(p,lshow)
  delete(p);
  cleanupNoPool(lshow);
end

function cleanupNoPool(lshow)
  lshow.updatePercent('Done!');
  pause(2);
  lshow.shutdown();
end


