function flag=isHome(I)
% check if the mount is at home position
    flag=strcmp(I.FullStatus.motion,'at home');
end
