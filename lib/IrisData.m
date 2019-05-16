classdef IrisData
  %IRISDATA Data class for Iris DVA export 
  %   Detailed explanation goes here
  
  properties (SetAccess=private)
    Meta
    Notes
    Data
    Membership
  end
  
  
  
  methods
    function obj = IrisData(varargin)
      %IRISDATA Construct instance of Iris DVA data class.
      ip = inputParser();
      ip.addParameter('Data', {}, @iscell);
      ip.addParameter('Meta', {}, @iscell);
      ip.addParameter('Notes',{}, @iscell);
      ip.addParameter('FileList', {}, @iscell);
      
      ip.parse(varargin{:});
      
      
      % parse data to allow contiguous selection
      % need a method to allow a lookup table for file memberships
    end
    
    
  end
end

