function GoTo(I,x,y,coordtype)
% shorthand function equivalent to setting Az,Alt or Ra,dec in a single step
% Arguments: x:          RA or Az
%            y:          Dec or Alt
%            coordtype:  'eq' or 'hor' or 'azalt' (the latter two to the same effect)
% Examples: M.GoTo(10,20,'eq')
    if ~exist('coordtype','var')
        coordtype='eq';
    end
    I.LastError='';
    switch lower(coordtype)
        case 'eq'
            I.RA=x;
            I.Dec=y;
        case {'hor','azalt'}
            I.Az=x;
            I.Alt=y;
        otherwise
            msg='unknown coodinate system; use "eq" or "AzAlt" / "hor"';
            I.report([msg,'\n'])
            I.LastError=msg;
    end
end
            
