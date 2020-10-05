function ismount=check_for_mount(I)
    try
        % Mount's model
        model = I.query('MountInfo');
        ismount = strcmp(model(1:3),'012');
        I.LastError = '';
    catch
        ismount=false;
        I.LastError=['not able to check for iOptron mount on ' I.Port];
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
        
        I.MountType = 'iOptron';
        I.MountModel = name;

        I.report(['mount iOptron ' name ' found on ',I.Port,'\n'])
    else
        I.report(['no iOptron CEM120 mount found on ',I.Port,'\n'])
        I.LastError=['no iOptron CEM120 mount found on ',I.Port];
    end
end
