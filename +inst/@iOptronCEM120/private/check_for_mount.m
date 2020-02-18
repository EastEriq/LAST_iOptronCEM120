function ismount=check_for_mount(I)
    try
        model=I.query('MountInfo');
        ismount=strcmp(model(1:3),'012');
        I.lastError='';
    catch
        ismount=false;
        I.lastError=['not able to check for Focus Motor on ' I.Port];
    end

    if ismount
        switch model
            case '0120'
                name='CEM120';
            case '0121'
                name='CEM120-EC';
            case '0122'
                name='CEM120-EC2';
            otherwise
                name='CEM120-???';
        end
        I.report(['mount iOptron ' name ' found on ',I.Port,'\n'])
    else
        I.report(['no iOptron CEM120 mount found on ',I.Port,'\n'])
        I.lastError=['no iOptron CEM120 mount found on ',I.Port];
    end
end