function [ varargout ] = search_recurse( filename, varargin  )
%SEARCH_RECURSE finds a full path to a given filename.
%   Accepts filename, and searches recursively through pwd() and returns full
%   filepath. Accepts an optional 'root' string to find path to a file not on matlab
%   path or ancestor of pwd. Filename can contain 
%
%   Usage:
%    [fullfile, path, name] = search_recurse(filename,'root',root,'ext',{'.ext'});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% Script created by: Khris Griffis                                        %
% Date: 8/18/2014
% Update : Added support for no extension given in varargin. 20140820
%          Updated to use parsehelper.
%          06/13/2016: fixed multiple extension inputs
%             Added automatic check for capitalized extension
%             Optimized recursive engine
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

[newfile, root, extcell,errcut] = parsehelper(filename, varargin{:});
filepath = cell(length(newfile),1);

% Check inputs as given
for y = 1:length(newfile)
    filepath{y} = searching(newfile{y}, root);
    if ~isempty(filepath{y})
        pathindex = y;
        break
    end
end

% Check for upper case possibility.
if ~exist('pathindex','var')
  newfile_UC = strrep(newfile, extcell, upper(extcell));
  for y = 1:length(newfile_UC)
    filepath{y} = searching(newfile_UC{y}, root);
    if ~isempty(filepath{y})
        pathindex = y;
        newfile = newfile_UC;
        break
    end
  end
end

% Ask for new folder
if ~exist('pathindex', 'var') && ~errcut
  errnum = 0;
  while errnum < 3
    uiwait(msgbox({['" ',filename,' " ', 'could not be found in ', '" ', ...
      root, ' "'],['Please select the parent directory for "', ...
      filename,'".']}, 'Root Error', 'modal'));
    root = uigetdir(root, 'Select new root directory');
    if root == 0, return; end
    for y = 1:length(newfile)
      filepath{y} = searching(newfile{y}, root);
      if ~isempty(filepath{y})
          pathindex = y;
          break
      end
    end
    if ~exist('pathindex', 'var')
      errnum = errnum+1;
    else
      break
    end
  end
end
%Finally, report error if not found
if ~exist('pathindex','var')
    varargout{1} = MException('SEARCHRECURSE:UNLOCATABLEFILE',...
      ['Exiting script because "',filename,'" ', ...
      'could not be found in ', '"', root, '"']);
    return
end

filepath = filepath{pathindex};
fin.name = newfile{pathindex};
filefull = fullfile(filepath,fin.name);

switch nargout
  case 1
    varargout{1} = filefull;
  case 2
    varargout{1} = filefull;
    varargout{2} = root;
  case 3
    varargout{1} = filefull;
    varargout{2} = root;
    varargout{3} = fin.name;
  otherwise
    filefull %#ok
end
end

function fpath = searching(filein, fileroot)
fpath = []; %#ok
tmp = dir(fileroot);
%check current
current_files = {tmp(~[tmp.isdir]).name};
current_dirs = {tmp([tmp.isdir]).name};
% fprintf('Current_dirs:\n');
% disp(current_dirs');
current_dirs = strcat([fileroot, '\'], ...
  current_dirs(cellfun(@isempty, regexp(current_dirs, '^\W'))));
% fprintf('\nCurrent_dirs trunc:\n');
% disp(current_dirs');
% fprintf('\n%s\n    In: %s\n', filein, fileroot)
% file_index = find(ismember(current_files, filein),1);
file_index = find(strcmp(filein, current_files), 1, 'first');
%Move onto internal folders
if isempty(file_index)
  if isempty(current_dirs)
    fpath = [];
    return
  end
  for d = 1:length(current_dirs)
    fpath = searching(filein, current_dirs{d});
    if ~isempty(fpath)
      return
    end
  end
  fpath = [];
  return
else
  fpath = fileroot;
  return
end

end

%{
function fpath = searching_old(filein, fileroot, dex)
        fpath = dex;
        search.pathstrings = genpath(fileroot);
        search.seps = strfind(search.pathstrings, pathsep);
        search.l1 = [1 search.seps(1:end-1)+1];
        search.l2 = search.seps(1:end)-1;
        search.pathfolders = arrayfun(@(a,b) search.pathstrings(a:b), ...
            search.l1, search.l2, 'UniformOutput',false);
        search.files = [];
        for ifile = 1:length(search.pathfolders)
            search.new = dir(fullfile(search.pathfolders{ifile}, filein));
            if ~isempty(search.new)
                search.full = cellfun(@(a) fullfile( ...
                    search.pathfolders{ifile}, a), {search.new.name}, ...
                    'UniformOutput', false);
                [search.new.name] = deal(search.full{:});
                search.files = [search.files; search.new];
                fpath = fullfile(search.pathfolders{ifile}, '\');
            end
        end
end


function [name, ex] = exlen(namein)
    e = strfind(namein, '.');
    validateattributes(e, {'numeric'}, {'nonempty'});
    name = namein(1:e(end)-1);
    ex = namein(e(end):end);
end
%}

function [newfile, root, extcell, errcut] = parsehelper(varargin)

ss = inputParser;

droot = cd();
dext = {[]};

addRequired(ss, 'file', @ischar);
addOptional(ss, 'root', droot);
addParameter(ss, 'ext', dext, @iscellstr);
addParameter(ss, 'errcut', false, @islogical);
parse(ss, varargin{:});

errcut = ss.Results.errcut;

[root filen ext] = fileparts(ss.Results.file); %#ok

if isempty(root)
  root = ss.Results.root;
end
if isempty(ext)
    ets = ss.Results.ext;
  etscheck = strcat('.', ...
    ets(cellfun(@isempty,strfind(ets,'.'))));
  if ~isempty(etscheck)
    ets(cellfun(@isempty,strfind(ets,'.'))) = etscheck;
  end
elseif ~any(cellfun(@isempty, ss.Results.ext, 'UniformOutput', true))
  ets = ss.Results.ext;
  etscheck = strcat('.', ...
    ets(cellfun(@isempty,strfind(ets,'.'))));
  if ~isempty(etscheck)
    ets(cellfun(@isempty,strfind(ets,'.'))) = etscheck;
  end
  ftmp = strcat([filen,ext],ets);
  ets = cell(length(ftmp),1);
  for ff = 1:length(ftmp)
      itmp = regexpi(ftmp{ff},'\.');
      ext = ftmp{ff}(itmp(end):end);
      filen = ftmp{ff}(1:(itmp(end)-1));
      ets{ff} = ext;
  end
else
  ets = ext;
end

newfile = cellstr(strcat(filen,ets));
extcell = cellstr(ets);

end
