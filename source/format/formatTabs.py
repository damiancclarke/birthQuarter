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
ftype = 'over30'
dloc  = './../'

singleIPUM       = RES + 'ipums/sumStats/FullSample.txt'
singleNVSS       = RES + ftype + '/sumStats/FullSample.txt'
singleEducIPUM   = RES + 'ipums/sumStats/EducSample.txt'
singleEducNVSS   = RES + ftype + '/sumStats/EducSample.txt'
allEducIPUM      = RES + 'ipums/sumStats/JustEduc.txt'
allEducNVSS      = RES + ftype + '/sumStats/JustEduc.txt'


twinIPUM       = RES + 'ipums/sumStats/FullSampletwins.txt'
twinNVSS       = RES + ftype + '/sumStats/FullSampletwins.txt'
twinEducIPUM   = RES + 'ipums/sumStats/EducSampletwins.txt'
twinEducNVSS   = RES + ftype + '/sumStats/EducSampletwins.txt'
TallEducIPUM   = RES + 'ipums/sumStats/JustEductwins.txt'
TallEducNVSS   = RES + ftype + '/sumStats/JustEductwins.txt'

sumIPUM = RES + 'ipums/sumStats/ipumsSum.tex' 
sumNVSS = RES + ftype + '/sumStats/nvssSum.tex'
MumNVSS = RES + ftype + '/sumStats/nvssMum.tex'
MumPNVSS= RES + ftype + '/sumStats/nvssMumPart.tex'
KidNVSS = RES + ftype + '/sumStats/nvssKid.tex'

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
twid = ['5','5']
tcm  = ['}{p{9.8cm}}','}{p{12.0cm}}']
mc3  = '{\\begin{footnotesize}\\textsc{Notes:} '
lname = "Fertility$\\times$desire"
tname = "Twin$\\times$desire"
tsc  = '\\textsc{' 
ebr  = '}'
R2   = 'R$^2$'



#==============================================================================
#== (2) Write sum stat tables
#==============================================================================
for parity in ['single', 'twin']:
    sumT = open(TAB + 'sum'+parity+ftype+'.tex', 'w')

    if parity=='twin':
        NV  = open(twinNVSS, 'r').readlines()
        NVe = open(twinEducNVSS, 'r').readlines()
        NVj = open(TallEducNVSS, 'r').readlines()
        headline = 'Twins'
    elif parity=='single':
        NV  = open(singleNVSS, 'r').readlines()
        NVe = open(singleEducNVSS, 'r').readlines()
        NVj = open(allEducNVSS, 'r').readlines()
        headline = 'Singletons'

    sumT.write("\\begin{landscape}\\begin{table}[htpb!]"
               "\\caption{Percent of Births, "+headline+"} \n"
               "\\label{bqTab:"+parity+"Sum}\\begin{center}"
               "\\begin{tabular}{lcccc}\n\\toprule \\toprule \n"
               "& Bad    & Good   & Diff. & Ratio \\\\\n"
               "& Season & Season &       &       \\\\\\midrule"
               "\multicolumn{5}{l}{\\textsc{Panel A: By Age Groups}}\\\\"
               "\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*4+
               "\\begin{footnotesize}\\end{footnotesize}\\\\ \n")
    
    sumT.write(NV[1]+'\\\\ \n'
               +NV[2]+'\\\\ \n &&&& \\\\'
               "\multicolumn{5}{l}{\\textsc{Panel B: By Education}}\\\\"
               "\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*4+
               "\\begin{footnotesize}\\end{footnotesize}\\\\ \n"+
               NVj[1]+'\\\\ \n'+
               NVj[2]+'\\\\ \n &&&& \\\\'
               "\multicolumn{5}{l}{\\textsc{Panel C: By Age and Education}}\\\\"
               "\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*4+
               "\\begin{footnotesize}\\end{footnotesize}\\\\ \n"+
               NVe[1]+'\\\\ \n'+
               NVe[2]+'\\\\ \n'+
               NVe[3]+'\\\\ \n'+
               NVe[4]+'\\\\ \n &&&& \\\\'
               )
    
    
    sumT.write('\n'+mr+mc1+twid[0]+tcm[0]+mc3+
               "Good season refers to birth quarters 2 and 3 (Apr-Jun and "
               "Jul-Sept).  Bad season refers to quarters 1 and 4 (Jan-Mar "
               "and Oct-Dec).  Values reflect the percent of yearly births "
               "each season from 2005-2013. `Young' refers to 25-39 year olds,"
               " `Old' refers to 40-45 year olds. \n"
               "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}"
               "\\end{center}\\end{table}\\end{landscape}")
    
    sumT.close()


#==============================================================================
#== (3) Basic Sum stats (NVSS and IPUMS)
#==============================================================================
sumT = open(TAB + 'sumStats'+ftype+'.tex', 'w')
sumT.write('\\begin{table}[htpb!] \n \\begin{center} \n' 
'\\caption{Descriptive Statistics (NVSS 2005-2013)}\n \\begin{tabular}{lcccc} '
'\n \\toprule\\toprule \\vspace{5mm} \n'
'& Mean & Std. Dev. & Min. & Max. \\\\ \\midrule \n'
'\multicolumn{5}{l}{\\textbf{Panel A: Mother}} \\\\ \n')

Mu  = open(MumNVSS,  'r').readlines()
MP  = open(MumPNVSS, 'r').readlines()
Ki  = open(KidNVSS,  'r').readlines()

for i,line in enumerate(Mu):
    if i>8 and i<13:
        line = line.replace('\\hline','\\midrule')
        line = line.replace('At least some college','Some College +')
        sumT.write(line)

sumT.write(' \n \\multicolumn{5}{l}{'
'\\textbf{Panel B: Mother (2003 standard only)}}\\\\ \n ')
for i,line in enumerate(MP):
    if i>8 and i<12:
        line = line.replace('\\hline','\\midrule')
        sumT.write(line)
    if i==12:
        obs2 = line

sumT.write(' \n \\multicolumn{5}{l}{\\textbf{Panel C: Child}}\\\\ \n ')
for i,line in enumerate(Ki):
    if i>8 and i<19:
        line = line.replace('\\hline','\\midrule')
        line = line.replace('At least some college','Some College +')
        line = line.replace('Quarter','season of birth')
        sumT.write(line)
sumT.write(obs2.replace('Observations', 'Observations (Panel B)'))

sumT.write('\n'+mr+mc1+twid[1]+tcm[1]+mc3+
           "Each sample consists of all first-born children born to white, "
           "non-hispanic, US-born mothers. Good season refers to birth quarters"
           " 2 and 3 (Apr-Jun and Jul-Sept). Educational attainment (mother)\n"
           " is unrecorded for 34.25\\% of the population."
           "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}\\end{center}"
           "\\end{table}")
sumT.close()

#==============================================================================
#== (X) write tables.tex file
#==============================================================================
final = open(TAB + "tables"+ ftype +".tex", 'w')

final.write("\\input{./../tables/sumStats"+ftype+".tex} \n")
final.write("\\input{./../tables/sumsingle"+ftype+".tex} \n")
final.write("\\input{./../tables/sumtwin"+ftype+".tex} \n")

final.write("\\begin{landscape}\n"
"\\input{./../results/"+ ftype +"/regressions/NVSSBinary.tex} \n"
"\\end{landscape}\n"
"\\input{./../results/"+ ftype +"/regressions/NVSSBinarymarried.tex} \n"
"\\input{./../results/"+ ftype +"/regressions/NVSSBinaryunmarried.tex} \n"
"\\input{./../results/"+ ftype +"/regressions/NVSSBinarySingle.tex} \n"
"\\input{./../results/"+ ftype +"/regressions/NVSSBinarysmoking.tex} \n"
"\\input{./../results/"+ ftype +"/regressions/NVSSBinarynon-smoking.tex} \n"
"\\begin{landscape}\\input{./..//results/"+ ftype +"/regressions/NVSSQuality.tex} \n"
"\\end{landscape}\\begin{landscape}\n"
"\\input{./../results/"+ ftype +"/regressions/NVSSQualityEducAll.tex} \n"
"\\end{landscape}\\begin{landscape}"
"\\input{./../results/"+ ftype +"/regressions/NVSSQualitySmoke0.tex} \n"
"\\end{landscape}\\begin{landscape}\n"
"\\input{./../results/"+ ftype +"/regressions/NVSSQualitySmoke1.tex} \n"
"\\end{landscape}"
)



final.close()
