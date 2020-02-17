function GoTo(I,x,y,coordtype)
% shorthand function equivalent to setting Az,Alt or Ra,dec in a single step
    if ~exist('coordtype','var')
        coordtype='eq';
    end
    I.lastError='';
    switch coordtype
        case 'eq'
            I.RA=x;
            I.Dec=y;
        case {'hor','AzAlt'}
            I.Az=x;
            I.Alt=y;
        otherwise
            msg='unknow coodinate system; use "eq" or "AzAlt" / "hor"';
            I.report([msg,'\n'])
            I.lastError=msg;
    end
end
            
