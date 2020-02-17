function park(I,parking)
% parks the mount, idf parking=true, unparks it if false
    if ~exist('parking','var')
        parking=true;
    end
    I.lastError='';
    if parking
        resp=I.query('MP1');
        if resp~='1'
            I.lastError='parking mount failed';
        end
    else
        resp=I.query('MP0');
        if resp~='1'
            I.lastError='unparking mount failed';
        end
    end
end
