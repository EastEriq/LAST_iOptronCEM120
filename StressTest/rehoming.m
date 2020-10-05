% point the mount somewhere and then rehome it, in attempt to
%  reproduce a bug which appeared onde at Neot Smadar on 20/8/2020:
%  homing almost completed, telescope stuck, bad noise from motors

ntest=20;
npos=3; % number of moves before homing

for i=1:ntest
    fprintf('sequence #%d:\n',i)
    for j=1:npos
        fprintf('  pointing #%d:\n',j)
        M.GoTo(rand*359.99,rand*75+15,'azalt')
        while strcmp(M.Status,'slewing')
            fprintf('     Az=%.2f, Alt=%.2f\n',M.Az,M.Alt)
            pause(0.5)
        end
        pause(10)
    end
    M.home
    fprintf(' homing')
    while ~M.isHome
        fprintf('.')
        pause(1)
    end
    fprintf(' homed\n')
end