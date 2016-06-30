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


log using "$LOG/occupationPrep.txt", replace text


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





