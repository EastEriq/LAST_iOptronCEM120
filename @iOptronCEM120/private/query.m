        function resp=query(I,cmd)
            % Basic serial query function for iOptronCEM120
            
            % Dispose of previous traffic potentially having
            % filled the inbuffer, for an immediate response
            flushinput(I.serial_resource)
            fprintf(I.serial_resource,':%s#',cmd);
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
                resp=char(fread(I.serial_resource,...
                          [1,I.serial_resource.BytesAvailable],'char'));
                % possible replies are long strings terminated by #
                %  for get commands, or 0/1 for boolean gets, or setters
                if isempty(resp)
                    I.lastError='Mount did not respond. Maybe wrong command?';
                end
                if ~strcmp(resp(end),'#') && ...
                        (numel(resp)==1 && ~(resp=='0' || resp=='1'))
                    I.lastError='Response from mount incomplete';
                else
                    I.lastError='';
                end
            catch
                I.lastError='cannot read from serial resource';
            end
        end
