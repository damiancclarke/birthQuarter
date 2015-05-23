/*spainPrep.do v0.00             damiancclarke             yyyy-mm-dd:2015-05-23
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

Read in fixed width birth file from Spain using the dictionary file spainNac.dct
then attach labels as described in the online data description files from INE's
site: http://www.ine.es/en/prodyser/micro_mnp_nacim_en.htm

*/

vers 11
clear all
set more off
cap log close

*-------------------------------------------------------------------------------
*--- (1) Globals
*-------------------------------------------------------------------------------
global DAT "~/database/Spain/nacimientos"
global DIC "~/investigacion/2015/birthQuarter/source/dataPrep"

local data "Anonimizado Nacimientos sin causa A2013.txt"

*-------------------------------------------------------------------------------
*--- (2) Import
*-------------------------------------------------------------------------------
infile using "$DIC/spainNac.dct", using("$DAT/`data'")
