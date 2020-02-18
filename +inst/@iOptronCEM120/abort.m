        function abort(I)
            % emergency stop
            I.query('Q');
            I.query('ST0');
        end
