function track(I,rate)
% method form for causing the mount to track. I.track() does sidereal,
% I.track(0) stops, and I.track(rate) does an arbitrary custom rate
% in degrees/sec between 4.1781e-04°/sec and 7.9383e-3°/sec
    if ~exist('rate','var')
        rate=I.siderealRate;
    end
    I.TrackingSpeed=rate;
end