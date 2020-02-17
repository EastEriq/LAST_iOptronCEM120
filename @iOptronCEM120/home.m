function home(I)
% send the mount to its home position (Az=0, Alt=Lat, Dec=90, RA=any)
% (north pole if aligned), searching the right index positions.
% Non-blocking.
% This is a failsafe procedure, slower than just slewing the mount
%  to what it is thought to be the home based on the encoders (which
%  may have changed if the clutches have been released)
    I.query('MSH');
end
