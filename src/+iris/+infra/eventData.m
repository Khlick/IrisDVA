classdef (ConstructOnLoad) eventData < event.EventData

  properties
    Data
    EventInfo
  end

  methods

    function obj = eventData(data,evt)
      if nargin < 2, evt = []; end
      obj.Data = data;
      obj.EventInfo = evt;
    end

  end

end
