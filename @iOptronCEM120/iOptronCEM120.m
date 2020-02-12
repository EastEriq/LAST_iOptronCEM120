classdef iOptronCEM120 <handle

    properties
        RA=NaN;
        Dec=NaN;
        HA=NaN;
        Az=NaN;
        Alt=NaN;
        EastOfPier
        TrackingSpeed=NaN;
    end
    
    properties(GetAccess=public, SetAccess=private)
        Status='unknown';
    end  
    
    properties(Hidden)
        Port='';
        MountPos=struct('ObsLon',NaN,'ObsLat',NaN,'ObsHeight',NaN);
        TimeFromGPS
        ParkPos=[0,-30]; % park pos in [Az,Alt] (negative Alt is probably impossible)
        MinAlt=15;
    end
    
        % non-API-demanded properties, Enrico's judgement
    properties (Hidden=true) 
        verbose=true; % for stdin debugging
        serial_resource % the serial object corresponding to Port
    end
    
    properties (Hidden=true, GetAccess=public, SetAccess=private, Transient)
        lastError='';
    end

    methods
        % constructor and destructor
        function I=iOptronCEM120()
            % does nothing, connecting to port in a separate method
        end
        
        function delete(I)
            delete(I.serial_resource)
            % shall we try-catch and report success/failure?
        end
        
    end
    
end