function park(I,parking)
% parks the mount if parking=true, unparks it if false
    if ~exist('parking','var')
        parking=true;
    end
    I.LastError='';
    if parking
        resp=I.query('MP1');
        if resp~='1'
            I.LastError='parking mount failed';
        end
    else
        resp=I.query('MP0');
        if resp~='1'
            I.LastError='unparking mount failed';
        end
    end
end
