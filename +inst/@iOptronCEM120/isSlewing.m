function flag=isSlewing(I)
% check if the mount is slewing
    flag=strcmp(I.fullStatus.motion,'slew');
end
