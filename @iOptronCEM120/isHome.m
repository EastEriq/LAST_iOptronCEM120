function flag=isHome(I)
% check if the mount is at home position
    flag=strcmp(I.fullStatus.motion,'at home');
end
