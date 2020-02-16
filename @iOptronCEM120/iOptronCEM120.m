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
    
    methods
        % setters and getters
                function AZ=get.Az(I)
            resp=I.query('GAC');
            AZ=str2double(resp(10:18))/360000;
        end
        
        function set.Az(I,AZ)
            I.query(sprintf('Sz%09d',int32(AZ*360000)));
            resp=I.query('MSS');
            if resp~='1'
                error('target position beyond limits')
            end
        end
        
        function ALT=get.Alt(I)
            resp=I.query('GAC');
            ALT=str2double(resp(1:9))/360000;
        end
        
        function set.Alt(I,ALT)
            I.query(sprintf('Sa%+09d',int32(ALT*360000)));
            resp=I.query('MSS');
            if resp~='1'
                error('target position beyond limits')
            end
        end
        
        function DEC=get.Dec(I)
            resp=I.query('GEP');
            DEC=str2double(resp(1:9))/360000;
        end
        
        function set.Dec(I,DEC)
            I.query(sprintf('Sd%+08d',int32(DEC*360000)));
            resp=I.query('MS1');
            if resp~='1'
                error('target position beyond limits')
            end
        end
        
        function RA=get.RA(I)
            resp=I.query('GEP');
            RA=str2double(resp(10:18))/360000;
        end
        
        % East or West of pier, and counterweight positions could
        %  be read from the last two digits of the answer to GEP.
        %  However, they should also be understandable from Az and Alt (?)
 
        function set.RA(I,RA)
            I.query(sprintf('SRA%09d',int32(RA*360000)));
            resp=I.query('MS1'); % choose counterweight down for now
            if resp~='1'
                error('target position beyond limits')
            end
        end

    end
    
end