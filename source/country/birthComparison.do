/* birthComparison.do v0.00      damiancclarke             yyyy-mm-dd:2015-06-18 
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file compares birth season figures for four countries: USA, Spain (our main
analysis countries) plus Chile and Mexico (different longitudes).  Each graph g-
ives the fraction of births, the fraction of births below/above expected, as we-
ll as a graph comparing all.  These are done for both month and quarter.

contact: damian.clarke@economics.ox.ac.uk

*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) Globals and locals
********************************************************************************
global CHI "~/investigacion/2015/birthQuarter/data/chile"
global ESP "~/investigacion/2015/birthQuarter/data/spain"
global MEX "~/investigacion/2015/birthQuarter/data/mexico"
global USA "~/investigacion/2015/birthQuarter/data/nvss"
global OUT "~/investigacion/2015/birthQuarter/results/countries"
global LOG "~/investigacion/2015/birthQuarter/log"

log using "$LOG/nvssTrends.txt", text replace


local legd     legend(label(1 "Q1") label(2 "Q2") label(3 "Q3") label(4 "Q4"))

local datESP births2013
local datUSA nvss2005_2013
local datCHI Nacimientos_Chile_20002012
local datMEX MexNacimientos_2000-2005

********************************************************************************
*** (2) Chile
********************************************************************************
use "$CHI/`datCHI'"
keep if ano_nac>2004
keep if edad_m>24&edad_m<46 & tipo_parto==1
gen young = edad_m<40
gen birthMonth   = mes_nac
gen birthQuarter = ceil(birthMonth/3)
gen birth = 1
tempfile Chile
save `Chile'

********************************************************************************
*** (3) Mexico
********************************************************************************
use "$MEX/`datMEX'"
keep if edad_madn>24&edad_madn<46 & tipo_nac==1 & mes_nac!=99
gen young = edad_madn<40
gen birthMonth   = mes_nac
gen birthQuarter = ceil(birthMonth/3)
gen birth = 1
tempfile Mexico
save `Mexico'


********************************************************************************
*** (4) Spain
********************************************************************************
use "$ESP/`datESP'"
keep if parity == 1 & motherSpanish == 1 & ageMother>=25 & ageMother<= 45 
rename monthBirth birthMonth
gen birth = 1
gen young = ageMother<40

tempfile Spain
save `Spain'

********************************************************************************
*** (5) USA
********************************************************************************
use "$USA/`datUSA'"
keep if birthOrder==1&twin==1&motherAge>24&motherAge<=45

gen birth=1
gen young=motherAge<40
tempfile USA
save `USA'


********************************************************************************
*** (7) Make individual graphs
********************************************************************************
foreach cc in Spain USA Chile Mexico {
    use ``cc''

    foreach period in Month Quarter {
        if `"`period'"'=="Month"   local Nn 12
        if `"`period'"'=="Quarter" local Nn 4
    
        preserve
        collapse (sum) birth, by(birth`period' young)


        bys young: egen totalBirths = sum(birth)
        replace birth = birth/totalBirths

        if `"`period'"'=="Month" {
            gen days = 31 if birthM==1 |birthM==3|birthM==5|birthM==7|birthM==8|/*
                           */birthM==10|birthM==12
            replace days = 30 if birthM==4|birthM==6|birthM==9|birthM==11 
            replace days = 28.25 if birthMonth==2
        }
        if `"`period'"'=="Quarter" {
            gen days = 90.25  if birthQuarter == 1
            replace days = 91 if birthQuarter == 2
            replace days = 92 if birthQuarter == 3
            replace days = 92 if birthQuarter == 4
        }


        gen expectedProp = days / 365.25
        gen excessBirths = birth - expectedProp

        cap label drop Month
        cap label drop Quarter        
        lab var birth        "Proportion of Births"
        lab var expectedProp "Expected Births (days/365.25)"
        lab var excessBirths "Proportion of Excess Births (Actual-Expected)"
        lab def Month   1 "Jan" 2 "Feb" 3 "Mar" 4 "Apr" 5 "May" 6 "Jun"  /*
                     */ 7 "Jul" 8 "Aug" 9 "Sep" 10 "Oct" 11 "Nov" 12 "Dec"
        lab def Quarter 1 "Quarter 1" 2 "Quarter 2" 3 "Quarter 3" 4 "Quarter 4"

        lab val birth`period' `period'
        
        sum excessBirths

        if `"`period'"'=="Quarter" local sc1   0.23(0.1)0.27
        if `"`period'"'=="Month"   local sc1   0.075(0.005)0.09
        local sc2 -0.01 -0.005 0 0.005
    
        sort young birth`period'
        foreach num of numlist 0 1 {

            local name Old
            if `num'==1 local name Young
            #delimit ;
            twoway bar birth birth`period' if young==`num', bcolor(ltblue) ||
                line expectedProp birth`period' if young==`num', scheme(s1mono) 
            lcolor(black) xlabel(1(1)`Nn', valuelabels) ytitle("Proportion")
            xtitle("`period' of Birth") lpattern(dash) ylabel(`sc1');
            graph export "$OUT/births`period'`cc'`name'.eps", as(eps) replace;

            twoway bar excessBirths birth`period' if young==`num', bcolor(ltblue)
            xlabel(1(1)`Nn', valuelabels) ytitle("Proportion") scheme(s1mono)
            xtitle("`period' of Birth") yline(0, lpattern(dash) lcolor(black)) 
            ytitle("Proportion Excess Births (Actual-Expected)") ylabel(`sc2');
            graph export "$OUT/excess`period'`cc'`name'.eps", as(eps) replace;
            #delimit cr
        }
        gen country = "`cc'"
        tempfile `period'`cc'
        save ``period'`cc''
        restore
    }
}
exit

    

*gen birthQuarter = ceil(birthMonth/3)
********************************************************************************
*** (X) Clean up
********************************************************************************
log close
