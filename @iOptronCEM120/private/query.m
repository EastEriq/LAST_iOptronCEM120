        function resp=query(I,cmd)
            % Basic serial query function for iOptronCEM120
            
            % Dispose of previous traffic potentially having
            % filled the inbuffer, for an immediate response
            flushinput(I.Port)
            fprintf(I.Port,':%s#',cmd);
            if strcmp(cmd,'Q')
                pause(0.5); % abort requires a longer delay
            elseif strcmp(cmd(1:2),'ST')
                pause(0.7); % start and stop tracking even longer
            else
                pause(0.1);
            end
            resp=char(fread(I.Port,[1,I.Port.BytesAvailable],'char'));
            % possible replies are long strings terminated by #
            %  for get commands, or 0/1 for boolean gets, or setters
            if isempty(resp)
                error('Mount did not respond. Maybe wrong command?')
            end
            if ~strcmp(resp(end),'#') && ...
                   (numel(resp)==1 && ~(resp=='0' || resp=='1'))
                error('Response from mount incomplete')
            end
        end
