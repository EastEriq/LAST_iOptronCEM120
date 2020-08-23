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
                if isempty(I.lastError)
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
        I.lastError=['cannot delete Port object ' Port ' -maybe OS disconnected it?'];
    end

    try
        if isIPnum(Port)
            I.serial_resource=tcpip(Port,8080);
        else
            I.serial_resource=serial(Port);
            % serial has been deprecated in 2019b in favour of
            %  serialport... all communication code should be
            %  transitioned...
        end
    catch
        I.lastError=['cannot create Port object ' Port ];
    end

    try
        if strcmp(I.serial_resource.status,'closed')
            fopen(I.serial_resource);
            if ~isIPnum(Port)
                set(I.serial_resource,'BaudRate',115200,'Timeout',1);
            end
        end
        I.Port=Port; % I.serial_resource.Port; % but only for serial; RemoteHost for tcp
        success = check_for_mount(I);
    catch
        I.lastError=['Port ' Port ' cannot be opened'];
        delete(instrfind('Port',Port)) % (catch also error here?)
    end
end
