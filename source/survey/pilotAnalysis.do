/* pilotAnalysis.do v0.00        damiancclarke             yyyy-mm-dd:2016-04-15
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

Analyse pilot data


*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) globals and locals    
********************************************************************************
global DAT "~/investigacion/2015/birthQuarter/data/survey/pilot"
global LOG "~/investigacion/2015/birthQuarter/log"
global OUT "~/investigacion/2015/birthQuarter/results/MTurk/pilot"
global GEO "~/investigacion/2015/birthQuarter/data/maps/states_simplified"

log using "$LOG/pilotAnalysis.txt", text replace

cap mkdir "$OUT"

********************************************************************************
*** (2) Open 
********************************************************************************
use "$DAT/pilotData"
decode state, gen(statename)
rename state statePilot



********************************************************************************
*** (3) Test geographic var
********************************************************************************
use "$GEO/US_db", clear

#delimit ;
spmap if NAME!="Alaska"&NAME!="Hawaii"&NAME!="Puerto Rico" using "$GEO/US_coord",
point(data("$DAT/pilotData.dta") xcoord(longitude) ycoord(latitude)
      select(keep if latitude>20) size(*1) fcolor(orange) ocolor(white)
      osize(vvthin))  id(_ID) fcolor(eggshell) ocolor(dkgreen) osize(thin)
label(data("$DAT/pilotData.dta") xcoord(longitude) ycoord(latitude) label(state)
      select(keep if latitude>20)) title("Coverage of the Pilot Survey")
note("Yellow dots are where the IP address says people are. Names are where people
say they are.");
graph export "$OUT/pilotCoverage.eps", as(eps) replace;

#delimit cr
