        function resp=query(M,cmd)
            % Basic serial query function for iOptronCEM120
            
            % check the availability of the port
            if ~isPortAvailable(M)
                % ask David which kind of error reporting we expect at
                %  abstraction level: error, F.lastError, stdout, what?
                error(['Port ' M.Port ' disappeared'])
            else          
                % Dispose of previous traffic potentially having
                % filled the inbuffer, for an immediate response
                flushinput(M.serial_resource)
                fprintf(M.serial_resource,':%s#',cmd);
                if strcmp(cmd,'Q')
                    pause(0.5); % abort requires a longer delay
                elseif strcmp(cmd(1:2),'ST')
                    pause(0.7); % start and stop tracking even longer
                else
                    pause(0.1);
                end
                
                try
                    % the following must be char(fread(....)) and not the
                    %  recommended fread(....,'*char')
                    resp=char(fread(M.serial_resource,...
                        [1,M.serial_resource.BytesAvailable],'char'));
                    % possible replies are long strings terminated by #
                    %  for get commands, or 0/1 for boolean gets, or setters
                    if isempty(resp)
                        M.lastError='Mount did not respond. Maybe wrong command?';
                    end
                    if ~strcmp(resp(end),'#') && ...
                            (numel(resp)==1 && ~(resp=='0' || resp=='1'))
                        M.lastError='Response from mount incomplete';
                    else
                        M.lastError='';
                    end
                catch
                    M.lastError='cannot read from serial resource';
                end
            end
        end