classdef iOptronCEM120 <handle

    properties
        RA=NaN;
        Dec=NaN;
        Az=NaN;
        Alt=NaN;
        TrackingSpeed=NaN;
    end
    
    properties(GetAccess=public, SetAccess=private)
        Status='unknown';
        isEastOfPier
    end  
    
    properties(Hidden)
        Port='';
        MountPos=struct('ObsLon',NaN,'ObsLat',NaN,'ObsHeight',NaN);
        TimeFromGPS
        ParkPos=[180,-30]; % park pos in [Az,Alt] (negative Alt is probably impossible)
        MinAlt=15;
        preferEastOfPier=true; % TO IMPLEMENT
    end
    
        % non-API-demanded properties, Enrico's judgement
    properties (Hidden) 
        verbose=true; % for stdin debugging
        serial_resource % the serial object corresponding to Port
    end
    
    properties (Hidden, GetAccess=public, SetAccess=private, Transient)
        fullStatus % complete status as returned by the mount, including time, track, etc.
        lastError='';
    end
    
    properties(Hidden,Constant)
        sidereal=360/86164.0905; %sidereal tracking rate, degrees/sec
         % empirical slewing rate (fixed?), degrees/sec, excluding accelerations
         % if it could be varied (see ':GSR#'/':MSRn#'), this won't be a 
         % Constant property
        slewRate=2.5;
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
                I.lastError='target Az beyond limits';
            else
                I.lastError='';
            end
        end
        
        function eop=get.isEastOfPier(I)
            % true if east, false if west. Just based on the azimut angle,
            %  assuming that the mount is polar aligned
            eop=I.Az<90;
        end
        
        function ALT=get.Alt(I)
            resp=I.query('GAC');
            ALT=str2double(resp(1:9))/360000;
        end
        
        function set.Alt(I,ALT)
            I.query(sprintf('Sa%+09d',int32(ALT*360000)));
            resp=I.query('MSS');
            if resp~='1'
                I.lastError='target Alt beyond limits';
            else
                I.lastError='';
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
                I.lastError='target Dec beyond limits';
            else
                I.lastError='';
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
                I.lastError='target RA beyond limits';
            else
                I.lastError='';
            end
        end

        function S=get.fullStatus(I)
            % read the full status information as given by iOptron
            % state enumerations - let the function error if an out-of
            %  -range value is returned
            gpsstate=["No GPS","no data","valid"];
            motionstate=["stopped","track without PEC","slew","auto-guiding",...
                         "meridian flipping","track with PEC","parked",...
                         "at home"];
            trackingrate=["sidereal","lunar","solar","King","custom"];
            keyspeed=["1x","2x","4x","8x","16x","32x","64x","128x",...
                      "256x","512x","max"];
            timesource=["communicated","hand controller","GPS"];
            hemisphere=["South","North"];
            resp=I.query('GLS');
            try
                S=struct('Lon',str2double(resp(1:9))/360000,...
                         'Lat',str2double(resp(10:17))/360000-90,...
                         'GPS',gpsstate(str2double(resp(18))+1),...
                         'motion',motionstate(str2double(resp(19))+1),...
                         'tracking',trackingrate(str2double(resp(20))+1),...
                         'keyspeed',keyspeed(str2double(resp(21))+1),...
                         'timesource',timesource(str2double(resp(22))+1),...
                         'hempisphere',hemisphere(str2double(resp(23))+1) );
            catch
                S=[];
                I.lastError='incorrect status string returned by the mount';
            end
        end
        
        function flag=get.TimeFromGPS(I)
            flag=strcmp(I.fullStatus.GPS,'valid') &&...
                 strcmp(I.fullStatus.timesource,'GPS');
        end
        
        function s=get.Status(I)
            % motion state only, generic API form
            switch I.fullStatus.motion
                case "stopped"
                    s='idle';
                case "slew"
                    s='slewing';
                case "parked"
                    s='park';
                case "at home"
                    s='home';
                case {"track without PEC","track with PEC"}
                    s='tracking';
                case {"meridian flipping","auto-guiding"}
                    s='unknown'; % what else we could say...
                otherwise
                    s='unknown';
            end
        end
        
        % tracking implemented by setting the property TrackingSpeed.
        %  using custom tracking mode, which allows the broadest range
        
        function s=get.TrackingSpeed(I)
            % tracking speed returned in degrees/sec
            if I.isTracking
                resp=I.query('GTR');
                s=str2double(resp(1:end-1))*I.sidereal/10000;
            else
                s=0;
            end
        end

        function set.TrackingSpeed(I,s)
            % set tracking speed in deg/sec, and start tracking immediately
            %  at that speed. Use the iOprtonCEM120 custom
            %  tracking rates, limited to 0.1-:-1.9*sidereal, or 0, meaning
            %  stop tracking
            rate=s/I.sidereal;
            I.lastError='';
            if s==0
                I.query('ST0');
            elseif rate>=0.1 && rate<=1.9
                I.query('RT4');
                I.query(sprintf('RR%05d',int32(rate*10000)));
                I.query('ST1');
            elseif rate>0 && rate <0.1
                msg='demanded tracking rate too small';
                I.lastError=msg;
                I.report([msg,'\n'])
            elseif rate>1.9
                msg='demanded tracking rate too large';
                I.lastError=msg;
                I.report([msg,'\n'])
            end
        end

% functioning parameters getters/setters & misc
        
        function alt=get.MinAlt(I)
            resp=I.query('GAL');
            alt=str2double(resp(1:3));
        end
        
        function set.MinAlt(I,alt)
            if alt<-89 || alt>89
                error('altitude limit illegal')
            else
                I.query(sprintf('SAL%+03d',round(alt)));
            end
        end
       
        function p=get.ParkPos(I)
            resp=I.query('GPC');
            p=[str2double(resp(9:17))/360000,...
               str2double(resp(1:8))/360000];
        end

        function set.ParkPos(I,pos)
            % set park position (Az,Alt) in degrees
            if (pos(1)>=0 && pos(1)<=360) && ...
                (pos(2)>=0 && pos(2)<=90)
                I.lastError='';
                I.query(sprintf('SPA%08d',int32(pos(1)*360000)));
                I.query(sprintf('SPH%08d',int32(pos(2)*360000)));
            else
                msg='invalid parking position';
                I.lastError=msg;
                I.report([msg,'\n'])
            end
        end
        
    end

end