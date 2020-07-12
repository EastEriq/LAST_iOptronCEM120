function success=connect(I,Port)
% connect to a focus motor on the specified Port, try all ports if
%  Port omitted
   success = 0;
    if ~exist('Port','var') || isempty(Port)
        for Port=seriallist
            try
                % look for one NexStar device on every
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
        delete(instrfind('Port',Port))
    catch
        I.lastError=['cannot delete Port object ' Port ' -maybe OS disconnected it?'];
    end

    try
        I.serial_resource=serial(Port);
        % serial has been deprecated in 2019b in favour of
        %  serialport... all communication code should be
        %  transitioned...
    catch
        I.lastError=['cannot create Port object ' Port ];
    end

    try
        if strcmp(I.serial_resource.status,'closed')
            fopen(I.serial_resource);
            set(I.serial_resource,'BaudRate',115200,'Timeout',1);
        end
        I.Port=I.serial_resource.Port;
        success = check_for_mount(I);
    catch
        I.lastError=['Port ' Port ' cannot be opened'];
        delete(instrfind('Port',Port)) % (catch also error here?)
    end
end
