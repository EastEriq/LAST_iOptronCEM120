function reportError(I,msg)
% report on stdout and set lastError, with the same argument
    I.lastError=msg;
    I.report([msg,'\n'])
end