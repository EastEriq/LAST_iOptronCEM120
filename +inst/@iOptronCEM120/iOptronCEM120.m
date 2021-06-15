classdef iOptronCEM120 < obs.LAST_Handle

    properties
        RA=NaN;
        Dec=NaN;
        Az=NaN;
        Alt=NaN;
        TrackingSpeed=NaN; % in degrees/sec, limited to 0.1÷1.9*sidereal, or 0=no tracking
    end
    
    properties(Hidden,GetAccess=public, SetAccess=immutable)
        % readonly, never changed
        CoordType='J2000'; % mount coordinates are referenced as J2000
    end

    properties(GetAccess=public, SetAccess=private)
        Status='unknown';
        IsEastOfPier
        IsCounterWeightDown
    end  
    
    properties(Hidden)
        MountType = NaN;
        MountModel = NaN;
        Port=''; % either the serial port device, or the tcpip address (port 8080 assumed)
        MountPos=[NaN,NaN,NaN];
        MountUTC
        Time
        TimeFromGPS
        ParkPos=[180,-30]; % park pos in [Az,Alt] (negative Alt is probably impossible)
        MinAlt=15;
        CounterWeightDown=true; % Test that this works as expected
        MeridianFlip=true; % if false, stop at the meridian limit
        MeridianLimit=92; % Test that this works as expected, no idea what happens
        SlewSpeed % 7 = 256 x Sidereal; 8 = 512 x Sidereal; 9 = max (about 4°/sec)
    end
    
        % non-API-demanded properties, Enrico's judgement
    properties (Hidden) 
        SerialResource % the serial or the tcpip object corresponding to Port
    end
    
    properties (Hidden, GetAccess=public, SetAccess=private, Transient)
        FullStatus % complete status as returned by the mount, including time, track, etc.
    end
    
    properties(Hidden,Constant)
        SiderealRate=360/86164.0905; % Sidereal tracking rate constant, degrees/sec
    end

    methods
        % constructor and destructor
        function I=iOptronCEM120(id)
            % does nothing, connecting to port in a separate method
        end
        
        function delete(I)
            delete(I.SerialResource)
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
                I.reportError('target Az beyond limits');
            else
                I.LastError='';
            end
        end
        
        function eop=get.IsEastOfPier(I)
            % true if east, false if west.
            %  Assuming that the mount is polar aligned
            resp=I.query('GEP');
            eop=(resp(19)=='0');
        end
        
        function cwd=get.IsCounterWeightDown(I)
            resp=I.query('GEP');
            cwd=(resp(20)=='1');
        end
        
        function ALT=get.Alt(I)
            resp=I.query('GAC');
            ALT=str2double(resp(1:9))/360000;
        end
        
        function set.Alt(I,ALT)
            I.query(sprintf('Sa%+09d',int32(ALT*360000)));
            resp=I.query('MSS');
            if resp~='1'
                I.reportError('target Alt beyond limits');
            else
                I.LastError='';
            end
        end
        
        function DEC=get.Dec(I)
            resp=I.query('GEP');
            DEC=str2double(resp(1:9))/360000;
        end
        
        function set.Dec(I,DEC)
            I.query(sprintf('Sd%+08d',int32(DEC*360000)));
            if I.CounterWeightDown
                resp=I.query('MS1');
            else
                resp=I.query('MS2');
            end
            if resp~='1'
                I.reportError('target Dec beyond limits');
            else
                I.LastError='';
            end
        end
        
        function RA=get.RA(I)
            resp=I.query('GEP');
            RA=str2double(resp(10:18))/360000;
        end
        
        function set.RA(I,RA)
            I.query(sprintf('SRA%09d',int32(RA*360000)));
            if I.CounterWeightDown
                resp=I.query('MS1');
            else
                resp=I.query('MS2');
            end
            if resp~='1'
                I.reportError('target RA beyond limits');
            else
                I.LastError='';
            end
        end

        function S=get.FullStatus(I)
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
                I.LastError='incorrect status string returned by the mount';
            end
        end
        
        function flag=get.TimeFromGPS(I)
            flag=strcmp(I.FullStatus.GPS,'valid') &&...
                 strcmp(I.FullStatus.timesource,'GPS');
        end
        
        function s=get.Status(I)
            % motion state only, generic API form
            switch I.FullStatus.motion
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
                s=str2double(resp(1:end-1))*I.SiderealRate/10000;
            else
                s=0;
            end
        end

        function set.TrackingSpeed(I,s)
            % set tracking speed in deg/sec, and start tracking immediately
            %  at that speed. Use the iOprtonCEM120 custom
            %  tracking rates, limited to 0.1-:-1.9*sidereal, or 0, meaning
            %  stop tracking
            rate=s/I.SiderealRate;
            I.LastError='';
            if s==0
                I.query('ST0');
            elseif rate>=0.1 && rate<=1.9
                I.query('RT4');
                I.query(sprintf('RR%05d',int32(rate*10000)));
                I.query('ST1');
            elseif rate>0 && rate <0.1
                I.reportError('demanded tracking rate too small')
            elseif rate>1.9
                I.reportError('demanded tracking rate too large')
            end
        end

% functioning parameters getters/setters & misc
        
        function flip=get.MeridianFlip(I)
            resp=I.query('GMT');
            flip=(resp(1)=='1');
        end
        
        function set.MeridianFlip(I,flip)
            I.query(sprintf('SMT%01d%02d',round(flip),I.MeridianLimit));
        end
        
        function lim=get.MeridianLimit(I)
            resp=I.query('GMT');
            lim=str2double(resp(2:3))+90;
        end
        
        function set.MeridianLimit(I,limit)
            % degrees past meridian where to perform the flip
            if limit<90 || limit>104
                I.reportError('meridian flip limit illegal')
            else
                I.query(sprintf('SMT%01d%02d',I.MeridianFlip,round(limit)+90));
            end
        end
        
        function alt=get.MinAlt(I)
            resp=I.query('GAL');
            alt=str2double(resp(1:3));
        end
        
        function set.MinAlt(I,alt)
            if alt<-89 || alt>89
                I.reportError('altitude limit illegal')
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
                I.LastError='';
                I.query(sprintf('SPA%08d',int32(pos(1)*360000)));
                I.query(sprintf('SPH%08d',int32(pos(2)*360000)));
            else
                I.reportError('invalid parking position');
            end
        end
        
        function pos=get.MountPos(I)
            pos=[I.FullStatus.Lon,I.FullStatus.Lat,I.MountPos(3)];
        end
            
        function set.MountPos(I,pos)
            % tell the mount longitude and latitude, only when
            % the GPS is not working. Height is not stored in the mount
            if ~strcmp(I.FullStatus.GPS,'valid')
                I.query(sprintf('SLO%+09d',int32(pos(1)*360000)));
                I.query(sprintf('SLA%+09d',int32(pos(2)*360000)));
                % I don't understand why the mount needs a separate entry for
                %   the hemisphere, since latitude is signed
                hem=(pos(2)>0);
                if hem
                    % 1 is north
                    I.query('SHE1');
                else
                    % 0 is south
                    I.query('SHE0');
                end
            end
            I.MountPos(3)=pos(3);
        end

        function MountUTC=get.MountUTC(I)
            % Returns mount UTC clock. Units: Julian Date
            J2000 = 2451545.0;
            MiliSecPerDay = 86400000;
            resp=I.query('GUT');
            MountUTC=str2double(resp(6:18))./MiliSecPerDay + J2000;
        end
            
        function set.MountUTC(I, dummy)
            % Set the mount UTC clock from the computer clock. Units: Julian Date - use with care           
            J2000 = 2451545.0;
            MiliSecPerDay = 86400000;
            I.query(sprintf('SUT%013d',round((celestial.time.julday-J2000).*MiliSecPerDay)));
        end

        function s=get.SlewSpeed(I)
            % Get the current slew speed (7,8 or 9)
            % Working ONLY with firmware 2009.20
            %  7 = 256 x Sidereal; 8 = 512 x Sidereal; 9 = max (about 4°/sec)
            resp=I.query('GSR');
            s=str2double(resp(1));
        end
        
        function set.SlewSpeed(I,s)
            % Set the current slew speed (7,8 or 9)
            % Working ONLY with firmware 2009.20
            %  7 = 256 x Sidereal; 8 = 512 x Sidereal; 9 = max (about 4°/sec)
            if s>=7 && s<=9
                I.query(sprintf('MSR%1d',s));
            elseif s<7
                I.reportError('demanded slew rate too small, should be >=7')
            elseif s>9
                I.reportError('demanded slew rate too large, should be <=9')
            end
        end

     
    end

end
