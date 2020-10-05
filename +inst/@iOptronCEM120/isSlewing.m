function flag=isSlewing(I)
% check if the mount is slewing
    flag=strcmp(I.FullStatus.motion,'slew');
end
