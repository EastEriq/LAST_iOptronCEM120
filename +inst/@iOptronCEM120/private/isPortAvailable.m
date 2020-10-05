function avail=isPortAvailable(M)
% Check if the serial or tcpip resource assigned to the mount object is
%  still known to the system, and delete if it disappeared.
% This is often necessary as virtual serial ports, assigned to
%  serial-USB devices frequently disconnect and reconnect under
%  another name, due to EMI, poor cables and whatnot.

    %tic   

    if isa(M.SerialResource,'tcpip')
        % hopefully 1 ping is enough - eventually fine tune. However, only
        %  su can ping more frequently than every 0.2sec, so more than one
        %  repetition would add multiples of 200ms + ping time.
        if unix(['ping -c 1 -i 0.2 -w 2 ' M.Port '>/dev/null'])
            portlist='';
        else
            portlist=M.Port;
        end
    else
        portlist=serialportlist; % use seriallist in rev<2019 instead
    end
    
    avail=any(contains(portlist,M.Port));
    if ~avail
        M.report("Serial "+M.Port+' disappeared from system, closing it\n')
        try
            if isa(M.SerialResource,'tcpip')
                delete(instrfind('RemoteHost',M.Port))
            else
                delete(instrfind('Port',Port))
            end
        catch
            M.LastError=['cannot delete Port object ' M.Port ' -maybe OS disconnected it?'];
        end
    end
    
    % fprintf('availability check: %.1fms\n',toc*1000);
