function disconnect(I)
% close the serial stream, but don't delete it from workspace
   fclose(I.SerialResource);
end
