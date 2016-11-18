/*
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
  Takes data from CDC of Influenza Like Illnesses from Flu View and makes weekly
averages for period 2009-2015.

*/
clear all
global DAT "~/investigacion/2015/birthQuarter/data/weather"

insheet using "$DAT/influenza.csv", comma names
drop if week==53
collapse weightedili, by(week)
rename weightedili influenza

lab dat "Influenza data from ILINet (CDC)"
save "$DAT/influenza", replace
