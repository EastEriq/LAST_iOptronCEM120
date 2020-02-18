function flag=isTracking(I)
% check if the mount is tracking
    flag=strcmp(I.Status,'tracking');
end
