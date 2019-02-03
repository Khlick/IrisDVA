classdef (ConstructOnLoad) eventData < event.EventData

    properties
        Data
    end

    methods

        function obj = eventData(data)
            obj.Data = data;
        end

    end

end