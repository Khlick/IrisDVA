classdef IntensityResponseFamily
  % INTENSITYRESPONSEFAMILY A data object for storing/using intensity response
  % data.
  
  properties (SetAccess = private)
    % Data- The original IrisData object passed in on construction.
    Data
  end
  
  properties (Access = private)
    % dataStruct- private storage of the data struct generated at construction.
    dataStruct
  end
  
  properties (Dependent = true)
    % Specs- A table of para
    Specs
    % nDatums- The number of available data.
    nDatums
    % InclusionList- The list of inclusions as set during object construction.
    InclusionList
  end
  
  methods
    
    function obj = IntensityResponseFamily( ...
        Data ...
        )
      % INTENSITYRESPONSEFAMILY Construct instance of the IR Family class.
      
      arguments
        Data (1,1) IrisData
      end
      obj.Data = Data;
      
    end %IntensityResponseFamily
    
  end %methods
  
  
  methods (Static = true, Hidden = true)
    
    function devMap = getStimParams(par,stimAmpProp,stimDurProp)
      % this method assumes that there is only 1 stimulating led with the property
      % name, led1.
      import utilities.findParamCell
      import utilities.arrayContains
      import matlab.lang.makeValidName

      % we assume that the stimulus duration is in ms so we will convert to sec
      stimParams = findParamCell(par,[stimAmpProp,stimDurProp],1,2,false,true,false);
      stimParams.(stimDurProp) = stimParams.(stimDurProp)*1e-3;

      % note: led1 should always be stim and all other LEDs should be backgrounds
      nLeds = sum(~cellfun(@isempty,regexp(par(:,1),'^led\d+$'),'UniformOutput',true));
      ledProps = string(sprintfc("led%d",1:nLeds));

      % map the device to the background value
      lambdas = findParamCell(par,"wavelength",1,2,false,false,false);
      leds = findParamCell( ...
        par, ...
        ledProps, ...
        1, ... % search column
        2, ... % return column
        false, ... % find anywhere in string, e.g. match led1 and led1Background
        true,  ... % return as struct
        false  ... % find all matches
        );

      bgProperties = findParamCell( ...
        par, ...
        ["background","value","mean"], ...
        1, ... % search column
        2, ... % return column
        false, ... % not exact, i.e. use regex
        true,  ... % return as cell
        false  ... % don't return only the first match
        );
      bgFields = fieldnames(bgProperties);

      devMap(1:nLeds) = struct( ...
        'name', '', ...
        'shortName', '', ...
        'lambda', 0, ...
        'voltage', 0, ...
        'duration', 0, ...
        'isStim', false, ...
        'backgroundVoltage', 0, ...
        'nd', 0 ...
        );
      for b = 1:nLeds
        bs = devMap(b);
        bs.name = string(leds.(ledProps(b)));
        bs.shortName = makeValidName(bs.name);
        bs.lambda = lambdas{contains(lambdas(:,1),bs.shortName),2};
        % check which background to use.
        % if ignoreBackgroundInput is true, then use the mean or value entry
        % otherwise, the mean or value entry should be the same as the backgrround
        % entry
        bgval = leds.(strcat(ledProps(b),"Background"));
        theseBgProps = bgFields( ...
          arrayContains( ...
          bgFields, ... % search array
          [bs.shortName,"value"], ... % has all of these
          [bs.shortName,"mean"], ... % OR all of these
          "Units" ... % but not any of these
          ) ...
          );
        propVals = cellfun(@(p)bgProperties.(p),theseBgProps,'UniformOutput',0);
        propVals(~cellfun(@isnumeric,propVals,'UniformOutput',true)) = [];
        isIgnored = isfield(bgProperties,"ignoreBackgroundInput") && ...
          bgProperties.ignoreBackgroundInput;
        if isIgnored
          bs.backgroundVoltage = max([propVals{:}]);
        else
          bs.backgroundVoltage = max([bgval,propVals{:}]);
        end
        if strcmp(bs.name,leds.led1)
          bs.voltage = stimParams.(stimAmpProp);
          bs.duration = stimParams.(stimDurProp);
          bs.isStim = true;
        end
        devMap(b) = bs;
      end
    end
    
  end
  
  
end %class