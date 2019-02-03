classdef Aes < handle
  
  methods (Static)
    
    %% Colors
    function cMat = appColor(n,colorName,form)
      if nargin < 1, n = 1; end
      if nargin < 2, colorName = 'green'; end
      if nargin < 3, form = 'matrix'; end
      
      form = validatestring(form,{'matrix', 'cdata'});
      
      if length(n) < 2 && strcmp(form,'cdata')
        n = num2cell([rep(n,2,'dims', {1,2}), 3]);
      elseif strcmp(form,'cdata')
        n = num2cell([n(:)',3]);
      elseif strcmp(form,'matrix')
        n = {n(1),[]};
      end
      validColors = {'green','red','zaffre','pistachio','greys','colorful','contrast'};
      colorName = validatestring(colorName, validColors);
      switch colorName
        case 'green'
          cMat = rep([202,241,160]./256, ...
            prod([n{~cellfun(@isempty,n(1:2))}]), 1, ...
            'dims', n);
        case 'red'
          cMat = rep([162,20,47]./256, ...
            prod([n{~cellfun(@isempty,n(1:2))}]), 1, ...
            'dims', n);
        case 'greys'
          if strcmp(form,'cdata'), error('Cannot get cData from this color.'); end
          cMat = interp1(1:2,...
            [0.3913,0.3913,0.3913;...
             0.6957,0.6957,0.6957],...
             linspace(1,2,n{1}), 'linear');
        case 'colorful'
          if strcmp(form,'cdata'), error('Cannot get cData from this color.'); end
          cMat = interp1(1:5,    ...
            [156, 47,  56;       ...
             88,  123, 127;      ...
             22,  50,  79;       ...
             211, 97,  53;       ...
             152, 138, 42]./256, ...
             linspace(1,5,n{1}), ...
             'pchip');
           cMat(cMat > 1) = 1; %correct interp
           cMat(cMat < 0) = 0; %correct interp
        case 'zaffre'
          cMat = rep([0 20 168]./256, ...
            prod([n{~cellfun(@isempty,n(1:2))}]), 1, ...
            'dims', n);
        case 'pistachio'
          cMat = rep([147 197 114]./256, ...
            prod([n{~cellfun(@isempty,n(1:2))}]), 1, ...
            'dims', n);
        case 'contrast'
          cMat = interp1(1:12,    ...
            [21,62,86;       ...
             22,91,119;      ...
             24,119,152;       ...
             26,148,185;       ...
             92,166,146;       ...
             161,183,108;       ...
             234,199,70;       ...
             235,169,59;       ...
             239,138,48;       ...
             241,108,37;       ...
             216,79,36;       ...
             191,50,35       ...
             ]./256, ...
             linspace(1,12,n{1}), ...
             'pchip');
           cMat(cMat > 1) = 1; %correct interp
           cMat(cMat < 0) = 0; %correct interp
      end
    end
    
    %% UIControl aspects
    function fnt = uiFontName()
      fnt = 'Times New Roman';
    end
    
    function fsz = uiFontSize(controlType,varargin)
      if nargin < 1, controlType = 'default'; end
      fsz = 12;
      switch controlType
        case 'label'
          attn = 4;
        case 'shrink'
          attn = -1;
        case 'edit'
          attn = 5;
        case 'custom'
          if isempty(varargin)
            attn = 15; 
          else
            attn = varargin{1};
          end
        otherwise
          attn = 0;
      end
      fsz = fsz + attn;
    end
    
    function props = screenProp(propNames)
      if ischar(propNames)
        propNames = {propNames};
      end
      s0 = get(groot);
      s0fields = fieldnames(s0);
      rmProps = propNames(~contains(s0fields,propNames,'IgnoreCase',1));
      
      props = fastrmField(s0,rmProps);
      
      if length(fieldnames(props)) == 1
        props = props.(propNames{1});
      end
    end
    
    %% Utils
    str = strLib( stringID )
    
  end
  
end

