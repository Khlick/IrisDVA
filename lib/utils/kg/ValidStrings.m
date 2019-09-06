function varargout = ValidStrings(testString,varargin)
      % VALIDSTRINGS A modified version of matlab's validstring. VALIDSTRINGS accepts
      % a cellstr and returns up to 2 outputs, a boolean indicated if all strings in
      % testString passed validation (by best partial matching) in allowedStrings and
      % a cellstr containing the validated strings.
      
      allowedStrings = "";
      nVargs = length(varargin);
      for v = 1:nVargs
        thisInput = varargin{v};
        switch class(thisInput)
          case 'char'
            allowedStrings = union(allowedStrings,string(thisInput));
          case 'string'
            allowedStrings = union(allowedStrings,thisInput);
          case 'cell'
            cStr = cellfun(@string,thisInput,'UniformOutput',false);
            allowedStrings = union(allowedStrings,[cStr{:}]);
          otherwise
            error('VALIDSTRINGS:UNSUPPORTEDTYPE','Unsuported input type, "%s".',class(thisInput));
        end
      end
      
      % clear the empty
      allowedStrings(allowedStrings=="") = [];
      
      if ~isstring(testString), testString = string(testString); end
      
      % MATLAB validatestrings will find uppercase from lowercase but not vice versa
      testString = lower(testString);
      % loop and check each input string
      tf = false(length(testString),1);
      for i = 1:length(testString)
        try
          testString(i) = validatestring(testString(i), allowedStrings);
          tf(i) = true;
        catch
          tf(i) = false;
        end
      end
      tf = all(tf);
      varargout{1} = tf;
      varargout{2} = testString;
    end