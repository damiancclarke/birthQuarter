# formatTabs.py v0.00             damiancclarke             yyyy-mm-dd:2015-05-07
#----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
#
# This file formats tables to produce output for the paper "Fertility Timing and
# Season of Birth..." (Clarke, Oreffice, Quintana-Domeque).  It produces indivi-
# dual tex files, and one final file called tables.tex which should be called by
# the main paper.tex file.  The only thing that needs to be changed is the defi-
# nition of RES and TAB in section (1).
# 
# At the command line:
#
#    python formatTabs.py

import re
import os
#import locale
#locale.setlocale(locale.LC_ALL, 'en_US')

print('\n\n Producing tex files for output tables.\n\n')

#==============================================================================
#== (1a) File names (comes from Stata do files)
#==============================================================================
RES   = "/home/damiancclarke/investigacion/2015/birthQuarter/results/"
TAB   = "/home/damiancclarke/investigacion/2015/birthQuarter/tables/"

singleIPUM = RES + 'ipums/sumStats/FullSample.txt'
singleNVSS = RES + 'nvss/sumStats/FullSample.txt'


#==============================================================================
#== (1b) shortcuts
#==============================================================================
foot = "$^{*}$p$<$0.1; $^{**}$p$<$0.05; $^{***}$p$<$0.01"
ls   = "\\\\"

mr   = '\\midrule'
tr   = '\\toprule'
br   = '\\bottomrule'
mc1  = '\\multicolumn{'
mc2  = '}}'
twid = ['10']
tcm  = ['}{p{14.0cm}}']
mc3  = '{\\begin{footnotesize}\\textsc{Notes:} '
lname = "Fertility$\\times$desire"
tname = "Twin$\\times$desire"
tsc  = '\\textsc{' 
ebr  = '}'
R2   = 'R$^2$'



#==============================================================================
#== (2) Write sum stat tables
#==============================================================================
sumT = open(TAB + "sumSingle.tex", 'w')

NV = open(singleNVSS, 'r').readlines()
IP = open(singleIPUM, 'r').readlines()

l1a = NV[1].replace("\"", "")
l2a = NV[2].replace("\"", "")



sumT.write("\\begin{landscape}\\begin{table}[htpb!]"
    "\\caption{Percent of Births, Singletons} \n"
    "\\label{bqTab:singleSum}\\begin{center}"
    "\\begin{tabular}{lccccp{6mm}cccc}\n\\toprule \\toprule \n"
    "&\\multicolumn{4}{c}{NVSS}&&\\multicolumn{4}{c}{ACS}"
    "\\\\ \\cmidrule(r){2-5} \\cmidrule(r){7-10} \n"
    "& Bad    & Good   & Diff. & Ratio && Bad    & Good   & Diff. & Ratio\\\\\n"
    "& Season & Season &       &       && Season & Season &     & \\\\\\midrule"
    "\multicolumn{10}{l}{\\textsc{Panel A: By Age Groups}}\\\\"
    "\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*9+
    "\\begin{footnotesize}\\end{footnotesize}\\\\ \n")

sumT.write(NV[1]+'&&'+IP[1]+'\\\\ \n'
          +NV[2]+'&&'+IP[2]+'\\\\ \n &&&&&&&&& \\\\'


"\multicolumn{10}{l}{\\textsc{Panel B: By Age and Education}}\\\\"
"\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*9+
"\\begin{footnotesize}\\end{footnotesize}\\\\ \n")




sumT.write('\n'+mr+mc1+twid[0]+tcm[0]+mc3+
"Good season refers to birth quarters 2 and 3 (Apr-Jun and Jul-Sept).  Bad "
"quarter refers to quarters 1 and 4 (Jan-Mar and Oct-Dec).  Values reflect "
"the percent of yearly births each season from 2005-2013. `Young' refers to"
" 20-39 year olds, `Old' refers to 40-45 year olds. \n"
"\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}\\end{center}"
"\\end{table}\\end{landscape}")

sumT.close()


#==============================================================================
#== (X) write tables.tex file
#==============================================================================
final = open(TAB + "tables.tex", 'w')

final.write("\\input{./../tables/sumSingle.tex} \n")

final.close()
