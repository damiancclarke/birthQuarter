/* occupationPrep.do v0.00       damiancclarke             yyyy-mm-dd:2016-06-30
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

Import 2003/2004 May and November employment numbers from the BLS to examine se-
asonality of job types.  Raw data is from: http://www.bls.gov/oes/tables.htm

*/

vers 11
clear all
set more off
cap log close

*-------------------------------------------------------------------------------
*--- (1) globals, locals
*--------------------------------------------------------------------------------
global DAT "~/investigacion/2015/birthQuarter/data/employ"
global LOG "~/investigacion/2015/birthQuarter/log"
global USG "~/investigacion/2015/birthQuarter/data/weather"
global OUT "~/investigacion/2015/birthQuarter/results/occupation"
global MAP "~/investigacion/2015/birthQuarter/data/maps"
global GEO "~/investigacion/2015/birthQuarter/data/maps/states_simplified"

log using "$LOG/occupationPrep.txt", replace text

/*
*-------------------------------------------------------------------------------
*--- (2) Data
*--------------------------------------------------------------------------------
foreach yr in 03 04 {
    insheet using "$DAT/oesm`yr'st/state_may20`yr'_dl.csv", delim(";") clear
    keep if occ_title=="All Occupations"|group=="major"

    #delimit ;
    gen seasonal=occ_code=="35-0000"|occ_code=="29-0000"|occ_code=="11-0000"|
        occ_code=="43-0000"|occ_code=="39-0000" if occ_code!="00-0000";
    replace seasonal = 2 if occ_code=="25-0000";
    #delimit cr
    keep area st state occ_code occ_title tot_emp h_mean a_mean seasonal
    gen month = "May"
    gen year  = 20`yr'
    foreach var of varlist tot_emp h_mean a_mean {
        replace `var'="" if `var'=="**"
        destring `var', replace
        *rename `var' `var'_May`yr'
    }
    drop if state=="Guam"|state=="Puerto Rico"|state=="Virgin Islands"
    
    tempfile May`yr'
    save `May`yr''

    insheet using "$DAT/oesn`yr'st/state_november20`yr'_dl.csv", delim(";") clear
    keep if occ_title=="All Occupations"|group=="major"

    #delimit ;
    gen seasonal=occ_code=="35-0000"|occ_code=="29-0000"|occ_code=="11-0000"|
        occ_code=="43-0000"|occ_code=="39-0000" if occ_code!="00-0000";
    replace seasonal = 2 if occ_code=="25-0000";
    #delimit cr
    keep area st state occ_code occ_title tot_emp h_mean a_mean seasonal
    gen month = "Nov"
    gen year  = 20`yr'
    drop if state=="Guam"|state=="Puerto Rico"|state=="Virgin Islands"
    foreach var of varlist tot_emp h_mean a_mean {
        replace `var'="" if `var'=="**"
        destring `var', replace
        *rename `var' `var'_Nov`yr'
    }

    tempfile Nov`yr'
    save `Nov`yr''

}

insheet using $USG/usaWeather.txt, names delim(";") clear
keep if year==2013
collapse temp (min) minTemp=temp (max) maxTemp=temp, by(state)
tempfile temperature
save `temperature'



clear
append using `May03' `Nov03' `May04' `Nov04'
merge m:1 state using `temperature'
drop if _merge==2
drop _merge
gen cold = minTemp <23


collapse a_mean h_mean (sum) tot_emp, by(month seasonal cold)
replace tot_emp = tot_emp/1000000


*-------------------------------------------------------------------------------
*--- (3) Graph
*--------------------------------------------------------------------------------
reshape wide a_mean h_mean tot_emp, i(seasonal cold) j(month) string
lab def jtype 0 "No Seasonality" 1 "Seasonality" 2 "Education"
lab val seasonal jtype

graph bar tot_empMay tot_empNov, over(seasonal, label(labsize(small))) /*
*/ over(cold, relabel(1 ">= -5 Celsius" 2 "< -5 Celsius")) /*
*/ legend(lab(1 "May") lab(2 "November")) ytitle("Jobs (Millions)")
graph export "$OUT/seasonalEmployment.eps", replace

egen meanEmp = rowmean(tot_empMay tot_empNov)
gen devMay = tot_empMay - meanEmp
gen devNov = tot_empNov - meanEmp

graph bar devMay devNov, over(seasonal, label(labsize(small))) /*
*/ over(cold, relabel(1 ">= -5 Celsius" 2 "< -5 Celsius")) /*
*/ legend(lab(1 "May") lab(2 "November")) ytitle("Jobs (Millions)")
graph export "$OUT/seasonalEmploymentDeviation.eps", replace

graph bar h_meanMay h_meanNov, over(seasonal, label(labsize(small))) /*
*/ over(cold, relabel(1 ">= -5 Celsius" 2 "< -5 Celsius")) /*
*/ legend(lab(1 "May") lab(2 "November")) exclude0 ylabel(17(0.5)19.5) /*
*/ ytitle("Hourly Salary")
graph export "$OUT/seasonalWages.eps", replace

*/

*-------------------------------------------------------------------------------
*--- (2) Data
*--------------------------------------------------------------------------------
insheet using "$DAT/2013/state_M2013_dl.csv", delim(";") clear
keep if occ_group=="major"

#delimit ;
gen seasonal=occ_code=="13-0000"|occ_code=="21-0000"|occ_code=="15-0000"|
    occ_code=="35-0000" if occ_code!="00-0000";
replace seasonal = 2 if occ_code=="25-0000";
gen seasonal2=occ_code=="35-0000"|occ_code=="29-0000"|occ_code=="11-0000"|
    occ_code=="43-0000"|occ_code=="39-0000" if occ_code!="00-0000";
replace seasonal2 = 2 if occ_code=="25-0000";
#delimit cr

replace jobs_1000="" if jobs_1000=="**"
destring jobs_1000, replace

preserve
collapse (sum) jobs_1000, by(state seasonal)

rename state NAME

merge m:1 NAME using "$GEO/US_db"
drop if _merge==1
drop if NAME=="Alaska"|NAME=="Hawaii"|NAME=="Puerto Rico"

format jobs_1000 %5.2f
#delimit ;
spmap jobs_1000 if seasonal==1 using "$GEO/US_coord_mercator", id(_ID)
osize(thin) legtitle("Jobs per 1,000") legstyle(2) fcolor(Heat)
legend(symy(*1.2) symx(*1.2) size(*1.5) rowgap(1)) title("Seasonal Jobs");
graph export "$OUT/seasonalJobs_t10.eps", replace;

spmap jobs_1000 if seasonal==0 using "$GEO/US_coord_mercator", id(_ID)
osize(thin) legtitle("Jobs per 1,000") legstyle(2) fcolor(Heat)
legend(symy(*1.2) symx(*1.2) size(*1.5) rowgap(1)) title("Non-Seasonal Jobs");
graph export "$OUT/nonseasonalJobs_t10.eps", replace;
#delimit cr

restore

collapse (sum) jobs_1000, by(state seasonal2)

rename state NAME

merge m:1 NAME using "$GEO/US_db"
drop if _merge==1
drop if NAME=="Alaska"|NAME=="Hawaii"|NAME=="Puerto Rico"

format jobs_1000 %5.2f
#delimit ;
spmap jobs_1000 if seasonal2==1 using "$GEO/US_coord_mercator", id(_ID)
osize(thin) legtitle("Jobs per 1,000") legstyle(2) fcolor(Heat)
legend(symy(*1.2) symx(*1.2) size(*1.5) rowgap(1)) title("Seasonal Jobs");
graph export "$OUT/seasonalJobs.eps", replace;

spmap jobs_1000 if seasonal2==0 using "$GEO/US_coord_mercator", id(_ID)
osize(thin) legtitle("Jobs per 1,000") legstyle(2) fcolor(Heat)
legend(symy(*1.2) symx(*1.2) size(*1.5) rowgap(1)) title("Non-Seasonal Jobs");
graph export "$OUT/nonseasonalJobs.eps", replace;
spmap jobs_1000 if seasonal2==2 using "$GEO/US_coord_mercator", id(_ID)
osize(thin) legtitle("Jobs per 1,000") legstyle(2) fcolor(Heat)
legend(symy(*1.2) symx(*1.2) size(*1.5) rowgap(1)) title("Education Jobs");
graph export "$OUT/teacherJobs.eps", replace;
#delimit cr
