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
        ParkPos=[0,-30]; % park pos in [Az,Alt]
        MinAlt=15;
    end
    
end