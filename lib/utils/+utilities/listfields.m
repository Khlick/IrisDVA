function [varargout] = listfields( varargin )
%listfield listfields(Struct,...) produces a table of field names recurs.
%   Recursively searches for fieldnames outputs full structurepaths and/or 
%   split fields dropping parent levels. [fields, splits] = listfields(...)
%   Optional inputs: 'depth'['both'], 'fill'[false], 'return'['normal'];
%   Setting 'return': 'normal', 'invert', behaves the same with inverted
%   fill levels (rows that are fullwidth).
%   Setting 'return': 'both' causes special behavior depending on outputs

tpar = inputParser;
tpar.StructExpand = false;
validdepth = {'full', 'short', 'both'};
dpt = 'both';
validreturn = {'normal', 'invert', 'both'};
dret = 'both';

addRequired(tpar,'S',@isstruct);
addOptional(tpar,'depth',dpt, @(x) any(strcmpi(validatestring(x, validdepth),validdepth)));
addParameter(tpar, 'fill', false, @islogical);
addParameter(tpar, 'return', dret, @ischar);
parse(tpar,varargin{:})
%Handle depth type
dep = vret(tpar.Results.depth, validdepth);
if isempty(dep)
    dep = dpt;
end
%Handle returns
if ~tpar.Results.fill
    tret = vret(tpar.Results.return, validreturn);
    if isempty(tret)
        tret = dret;
    end
    
end

%Get array
switch dep
    case 'both'
        fullFFlds = lfs(tpar.Results.S, inputname(1),'full');
        shortFFlds = lfs(tpar.Results.S, inputname(1),'short');
        %Create Table
        [fullFTs,~,~] = maketab(fullFFlds, 0);
        [shortFTs,~,~] = maketab(shortFFlds, 1);
        nout = 4;
        %Drop and return inverse or not
        if exist('tret', 'var') && strcmpi(tret,'both')
            [fFoundTabs, xf, ifFoundTabs]= dropper(fullFTs,tret);
            [sFoundTabs, xs, isFoundTabs]= dropper(shortFTs,tret);
        
            [fFoundFields,~,ifFoundFields] = dropper(fullFFlds, tret, xf);
            [sFoundFields,~,isFoundFields] = dropper(shortFFlds, tret, xs);
            nout = 8;
        elseif exist('tret','var') && ~strcmpi(tret,'both')
            [FoundTabs, xf]= dropper(fullFTs,tret);
            [iFoundTabs, xs]= dropper(shortFTs,tret);
        
            [FoundFields,~] = dropper(fullFFlds, tret, xf);
            [iFoundFields,~] = dropper(shortFFlds, tret, xs);
            nout = 4;
        end
    otherwise
        FoundFields = lfs(tpar.Results.S, inputname(1),dep);
        %Create Table
        if strcmpi(dep,'full')
            lvl=0;
        else
            lvl=1;
        end
        [FoundTabs,~,~] = maketab(FoundFields, lvl);
        nout = 1;
        if exist('tret','var')
            switch tret
                case 'both'
                    [FoundTabs, xr, iFoundTabs] = dropper(FoundTabs, tret);
                    [FoundFields,~, iFoundFields] = dropper(FoundFields,...
                        tret, xr);
                    nout = 4;
                otherwise
                    [FoundTabs, xr] = dropper(FoundTabs, tret);
                    [FoundFields, ~] = dropper(FoundFields, tret, xr);
                    nout = 2;
            end
        end
end

if ~nargout
    nout = 0;
end

switch nout
    case 0
        if ~exist('FoundFields', 'var')
            [sFoundFields(1:end-1);...
              isFoundFields] %#ok
        else
          if istable(FoundTabs),FoundTabs = unique(FoundTabs, 'rows', 'stable'); end
          FoundTabs %#ok
        end
    case 1
        nargoutchk(1,1)
        if ~exist('FoundFields', 'var')
            tmp = [sFoundFields(1:end-1);
                isFoundFields];
            if istable(tmp), tmp = unique(tmp, 'rows','stable'); end
            varargout{1} = tmp;
        else
            tmp = FoundTabs;
            if istable(tmp), tmp = unique(tmp, 'rows', 'stable'); end
            varargout{1} = tmp;
        end
    case 2
        nargoutchk(1,2)
        tmp = FoundFields;
        if istable(tmp), tmp = unique(tmp, 'rows','stable'); end
        varargout{1} = tmp;
        if nargout >1
        tmp2 = FoundTabs;
        if istable(tmp2), tmp2 = unique(tmp2, 'rows','stable'); end
        varargout{2} = tmp2;
        end
    case 4
        nargoutchk(1,4)
        varargout{1} = FoundFields;
        if nargout >1
        varargout{2} = FoundTabs;
        if nargout >2
        varargout{3} = iFoundFields;
        if nargout >3
        varargout{4} = iFoundTabs;
        end
        end
        end
    case 8
        nargoutchk(1,8)
        if nargout == 1
            varargout{1} = unique([sFoundFields(1:end-1);...
                isFoundFields]);
        else
            varargout{1} = unique(fFoundTabs,'rows', 'stable');
        end
        if nargout >1
        varargout{2} = unique(ifFoundTabs,'rows', 'stable');
        if nargout >2
        varargout{3} = unique(fFoundFields,'rows', 'stable');
        if nargout >3
        varargout{4} = unique(ifFoundFields,'rows', 'stable');
        if nargout >4
        varargout{5} = unique(sFoundTabs,'rows', 'stable');
        if nargout >5
        varargout{6} = unique(isFoundTabs,'rows', 'stable');
        if nargout >6
        varargout{7} = unique(sFoundFields,'rows', 'stable');
        if nargout >7
        varargout{8} = unique(isFoundFields,'rows', 'stable');
        end
        end
        end 
        end 
        end 
        end
        end
end
end




%Recursive internal
function LFs = lfs( S, current, depth)

narginchk(1,3)

if ~exist('current', 'var') || isempty(current)
    current = inputname(1);
    if isempty(current)
        current = 'S';
    end
else
    validateattributes(current, {'cell','char'}, {'nonempty'})
    if iscell(current)
        current = char(current);
    end
end

CurrentFields = fieldnames(S);
ListedFields = cellfun(@(x) strcat(sprintf('%s.',current),x),...
    CurrentFields,'UniformOutput',false);
RunningFields = cellfun(@(x) strcat('S.',x),...
    CurrentFields,'UniformOutput',false);
if strcmpi(depth, 'short')
    ListedFields = CurrentFields;
end

for f = 1:numel(CurrentFields)
   if isstruct(eval(RunningFields{f}))
       switch depth
           case 'full'
               ListedFields=[ListedFields;...
                   lfs(eval(RunningFields{f}), ...
                   ListedFields{f}, 'full')];
           case 'short'
               ListedFields=[ListedFields;...
                   lfs(eval(RunningFields{f}), ...
                   CurrentFields{f}, 'full')];
       end
   end
end
 
LFs = ListedFields(ismember(unique(ListedFields(:,1)), ...
      ListedFields(:,1)),:);
end

function [ctab, tablewidth, tableheight] = maketab(ffds, lvl)
%Create Table
flen = length(ffds);
dots = NaN(flen,1);
for i = 1:flen
    ms = regexp(ffds{i},regexptranslate('escape', '.'),'match');
    dots(i) = length(ms);
end
dots = max(dots)+2;

%Create table
ctmp = cell(flen,dots);

for i = 1:flen
    ms = regexp(ffds{i},regexptranslate('escape', '.'),'split');
    bound = repmat({'.'}, 1, dots-length(ms));
    ctmp(i,:) = [ms,bound];
end
ctmp(:,dots) = [];
%output table
ctab = cell2table(ctmp, ...
    'VariableNames',sprintfc('Level_%d', linspace(lvl,lvl+(dots-2), ...
    (dots-1))));
ctab = unique(ctab, 'rows', 'stable');
tablewidth = width(ctab);
tableheight = height(ctab);
end

function val = vret(instr, validator)
instr = char(instr);
try
    val = validatestring(instr,validator);
catch
    if length(intrs) == 1
        val = [];
    else
        warning(['Problem with return type, ' '''' instr '''' '.'; ...
        'Trying: ' '''' instr(1:end-1) '''.'])
        val = vret(instr(1:end-1),validator);
    end
end

end

function [Fout, xrows, varargout] = dropper(Ftab, tret, varargin)
if isempty(varargin)
        
    drop = zeros(size(Ftab));
    ncol = size(Ftab,2);
    for d = 1:ncol
        drop(:,d) = strcmpi(Ftab.(d),'.');
    end
    [xrows,~] = find(drop);%%
    
else
    xrows = [varargin{:}]';
    
end
    switch tret
        case 'normal'
            Ftab(xrows,:) = [];
            Fout = Ftab;
        case 'invert'
            Fout = Ftab(xrows,:);
        case 'both'
            OUT1 = Ftab(xrows,:);
            Ftab(xrows,:) = [];
            OUT2 = Ftab;
            switch nargout
                case 2
                    Fout = OUT1;
                    assignin('caller', 'OUT2', OUT2);
                case 3
                    Fout = OUT1;
                    varargout{1} = OUT2;
            end
    end
end
