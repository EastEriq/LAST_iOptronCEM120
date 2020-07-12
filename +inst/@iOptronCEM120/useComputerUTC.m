function useComputerUTC(I)
   % Set the mount UTC clock from the computer clock. Units: Julian Date - use with care
   J2000 = 2451545.0;
   MiliSecPerDay = 86400000;
   I.query(sprintf('SUT%013d',round((celestial.time.julday-J2000).*MiliSecPerDay)));
end
