function success=connect(I,Port)
% connect to an iOptron mount on the specified Port (serial or tcp address),
%  try all serial ports if Port omitted
   success = 0;
    if ~exist('Port','var') || isempty(Port)
        for Port=seriallist
            try
                % look for one iOptron mount on every
                %  possible serial port. Pity we cannot
                %  look for a named (i.e. SN) unit
                I.connect(Port);
                if isempty(I.LastError)
                    success = 1;
                    return
                else
                    delete(instrfind('Port',Port))
                end
            catch
                I.report("no iOptron CEM120 found on "+Port+'\n')
            end
        end
    end

    try
        if isIPnum(Port)
            delete(instrfind('RemoteHost',Port))
        else
            delete(instrfind('Port',Port))
        end
    catch
        I.LastError=['cannot delete Port object ' Port ' for iOptron mount - maybe OS disconnected it?'];
    end

    try
        if isIPnum(Port)
            I.SerialResource=tcpip(Port,8080);
        else
            I.SerialResource=serial(Port);
            % serial has been deprecated in 2019b in favour of
            %  serialport... all communication code should be
            %  transitioned...
        end
    catch
        I.LastError=['cannot create Port object ' Port ' for iOptron mount'];
    end

    try
        if strcmp(I.SerialResource.status,'closed')
            fopen(I.SerialResource);
            if ~isIPnum(Port)
                set(I.SerialResource,'BaudRate',115200,'Timeout',1);
            end
        end
        I.Port=Port; % I.SerialResource.Port; % but only for serial; RemoteHost for tcp
        success = check_for_mount(I);
    catch
        I.LastError=['Port ' Port ' for iOptron mount cannot be opened'];
        delete(instrfind('Port',Port)) % (catch also error here?)
    end
end
