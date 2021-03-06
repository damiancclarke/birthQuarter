# birthQformat.py v0.00           damiancclarke             yyyy-mm-dd:2015-05-07
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
#    python birthQformat.py

import re
import os
#import locale
#locale.setlocale(locale.LC_ALL, 'en_US')

print('\n\n Producing tex files for output tables.\n\n')

#==============================================================================
#== (1a) File names (comes from Stata do files)
#==============================================================================
RES   = "/home/damian/investigacion/2015/birthQuarter/results/"
TAB   = "/home/damian/investigacion/2015/birthQuarter/tables/"

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
twid = ['10','6','7','7','7','6','5','6','6','6']
tcm  = ['}{p{16.6cm}}','}{p{15.6cm}}','}{p{15.6cm}}','}{p{17.6cm}}',
        '}{p{11.8cm}}','}{p{11.4cm}}','}{p{9.0cm}}','}{p{14.2cm}}' ,
        '}{p{16.2cm}}','}{p{9.9cm}}']
mc3  = '{\\begin{footnotesize}\\textsc{Notes:} '
lname = "Fertility$\\times$desire"
tname = "Twin$\\times$desire"
tsc  = '\\textsc{' 
ebr  = '}'
R2   = 'R$^2$'


#==============================================================================
#== (2) Basic Sum stats (NVSS)
#==============================================================================
for group in ['All','whiteMarried','whiteUnmarried','blackUnmarried',
              'whiteMarried-b2','whiteUnmarried-b2']:
    order = 'first'
    if group == 'All':
        mnote = 'all '
        mnum  = 20
        tnote = '(NVSS 2005-2013)'
    elif group=='whiteMarried':
        mnote = 'white, married '
        mnum  = 17
        tnote = '(White Married Mothers, 20--45)'
    elif group=='whiteMarried-b2':
        mnote = 'white, married '
        mnum  = 17
        tnote = '(White Married Mothers, 20--45, Second births)'
        order = 'second'
    elif group=='whiteUnmarried':
        mnote = 'white, unmarried '
        mnum  = 17
        tnote = '(White Unmarried Mothers, 20--45)'
    elif group=='whiteUnmarried-b2':
        mnote = 'white, unmarried '
        mnum  = 17
        tnote = '(White Unmarried Mothers, 20--45, Second births)'
        order = 'second'
    elif group=='blackUnmarried':
        mnote = 'black, unmarried '
        mnum  = 17
        tnote = '(Black Unmarried Mothers, 20--45)'
    
    sumT = open(TAB + 'sumStats_'+ group +'.tex', 'w')
    sumT.write('\\begin{table}[htpb!] \n \\begin{center} \n' 
               '\\caption{Descriptive Statistics ' + tnote +'}\n '
               '\\label{bqTab:SumStatsMain}'
               '\\scalebox{0.85}{'
               '\\begin{tabular}{lccccc} '
               '\n \\toprule\\toprule \\vspace{5mm} \n'
               '& N & Mean & Std. Dev. & Min. & Max. \\\\ \\midrule \n'
               '\multicolumn{6}{l}{\\textbf{Panel A: Mother}} \\\\ \n')

    Mu2  = open(RES + 'births/sumstats/sampMum_'+group+'.tex' , 'r').readlines()
    MP2  = open(RES + 'births/sumstats/sampMumP_'+group+'.tex', 'r').readlines()
    Ki2  = open(RES + 'births/sumstats/sampKid_'+group+'.tex' , 'r').readlines()

    for i,line in enumerate(Mu2):
        if i>8 and i< mnum:
            if "Aged 25-39" not in line:
                line = line.replace('\\hline','\\midrule')
                sumT.write(line)
    for i,line in enumerate(MP2):
        if i>8 and i<19:
            line = line.replace('\\hline','\\midrule')
            line = line.replace('college','Some College +')
            line = line.replace('ART','Used ART$^{a}$')
            line = line.replace('Received WIC food in Pregnancy',
                                'Received WIC food in Pregnancy$^{a}$')
            line = line.replace('Pre-pregnancy Underweight (BMI$ <18.5)$',
                                'Pre-pregnancy Underweight (BMI $<$ 18.5)$^{a}$')
            line = line.replace('Normal Weight (BMI 18.5-25)',
                                'Pre-pregnancy Normal Weight (18.5 $\leq$ BMI $<$ 25)$^{a}$')
            line = line.replace('Pre-pregnancy Overweight $(25\leq$ BMI$ <30)$',
                                'Pre-pregnancy Overweight (25 $\leq$ BMI $<$ 30)$^{a}$')
            line = line.replace('Pre-pregnancy Obese (BMI$ \geq 30)$',
                                'Pre-pregnancy Obese (BMI $\geq$ 30)$^{a}$')
            line = line.replace('BMI  ','Pre-pregnancy BMI$^{a}$')
            sumT.write(line)

    sumT.write(' \n \\multicolumn{6}{l}{\\textbf{Panel B: Child}}\\\\ \n ')
    for i,line in enumerate(Ki2):
        if i>8 and i<19 :
            line = line.replace('\\hline','\\midrule')
            line = line.replace('At least some college','Some College +')
            line = line.replace('female','Female')
            sumT.write(line)

    sumT.write('\n'+mr+mc1+twid[1]+tcm[1]+mc3+
               "Sample consists of all "+order+"-born, singleton children born to"
               " " + mnote + "mothers aged 20-45 for whom      "
               "education and smoking during pregnancy are available. Quarter 2  "
               "and quarter 3 births are determined by month (Apr-Jun and        "
               "Jul-Sept respectively). ART     "
               "refers to the proportion of women who undertook assisted         "
               "reproductive technologies that resulted in these births.         "
               "$^{a}$ Only available from 2009."
               "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}}        "
               "\\end{center}\\end{table}")
    sumT.close()

    sumT = open(TAB + 'sumStats_'+ group +'Mothers.tex', 'w')
    sumT.write('\\begin{table}[htpb!] \n \\begin{center} \n' 
               '\\caption{Descriptive Statistics for Mothers ' + tnote +'}\n '
               '\\label{bqTab:SumStatsM}'
               '\\scalebox{0.85}{'
               '\\begin{tabular}{lccccc} '
               '\n \\toprule\\toprule \\vspace{5mm} \n'
               '& N & Mean & Std. Dev. & Min. & Max. \\\\ \\midrule \n')

    Mu2  = open(RES + 'births/sumstats/sampMum_'+group+'.tex' , 'r').readlines()
    MP2  = open(RES + 'births/sumstats/sampMumP_'+group+'.tex', 'r').readlines()
    Ki2  = open(RES + 'births/sumstats/sampKid_'+group+'.tex' , 'r').readlines()

    for i,line in enumerate(Mu2):
        if i>8 and i< mnum:
            if "Aged 25-39" not in line:
                line = line.replace('\\hline','\\midrule')
                sumT.write(line)
    for i,line in enumerate(MP2):
        if i>8 and i<19:
            line = line.replace('\\hline','\\midrule')
            line = line.replace('college','Some College +')
            line = line.replace('ART','Used ART$^{a}$')
            line = line.replace('Received WIC food in Pregnancy',
                                'Received WIC food in Pregnancy$^{a}$')
            line = line.replace('Pre-pregnancy Underweight (BMI$ <18.5)$',
                                'Pre-pregnancy Underweight (BMI $<$ 18.5)$^{a}$')
            line = line.replace('Normal Weight (BMI 18.5-25)',
                                'Pre-pregnancy Normal Weight (18.5 $\leq$ BMI $<$ 25)$^{a}$')
            line = line.replace('Pre-pregnancy Overweight $(25\leq$ BMI$ <30)$',
                                'Pre-pregnancy Overweight (25 $\leq$ BMI $<$ 30)$^{a}$')
            line = line.replace('Pre-pregnancy Obese (BMI$ \geq 30)$',
                                'Pre-pregnancy Obese (BMI $\geq$ 30)$^{a}$')
            line = line.replace('BMI  ','Pre-pregnancy BMI$^{a}$')
            sumT.write(line)

    sumT.write('\n'+mr+mc1+twid[1]+tcm[1]+mc3+
               "Sample consists of all " + mnote + order+"-time mothers aged  "
               "20-45 who give birth to a singleton child and for whom        "
               "education, smoking status during pregnancy and gestational    "
               "length of (child's) birth are available. ART refers to the    "
               "proportion of women who undertook assisted reproductive       "
               "technologies that resulted in these births.                   "
               "$^{a}$ Only available from 2009."
               "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}}     "
               "\\end{center}\\end{table}")
    sumT.close()

    sumT = open(TAB + 'sumStats_'+ group +'Children.tex', 'w')
    sumT.write('\\begin{table}[htpb!] \n \\begin{center} \n' 
               '\\caption{Descriptive Statistics for Children ' + tnote +'}\n '
               '\\label{bqTab:SumStatsC}'
               '\\scalebox{0.85}{'
               '\\begin{tabular}{lccccc} '
               '\n \\toprule\\toprule \\vspace{5mm} \n'
               '& N & Mean & Std. Dev. & Min. & Max. \\\\ \\midrule \n')

    Mu2  = open(RES + 'births/sumstats/sampMum_'+group+'.tex' , 'r').readlines()
    MP2  = open(RES + 'births/sumstats/sampMumP_'+group+'.tex', 'r').readlines()
    Ki2  = open(RES + 'births/sumstats/sampKid_'+group+'.tex' , 'r').readlines()

    for i,line in enumerate(Ki2):
        if i>8 and i<19:
            line = line.replace('\\hline','\\midrule')
            line = line.replace('At least some college','Some College +')
            line = line.replace('female','Female')
            sumT.write(line)

    sumT.write('\n'+mr+mc1+twid[9]+tcm[9]+mc3+
               "Sample consists of all "+order+"-born, singleton children born"
               " to " + mnote + "mothers aged 20-45 for whom education, smoking"
               " status during pregnancy and gestational length of (child's)  "
               "birth are available.  Quarters of birth are determined by the "
               "month in which the baby is expected based on conception date. "
               "Quarter 1 refers to January to March, Quarter 2 refers to     "
               "April to June, Quarter 3 refers to July to September, and     "
               "Quarter 4 refers to October to December due dates.            "
               "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}}     "
               "\\end{center}\\end{table}")
    sumT.close()

#==============================================================================
#== (3) Basic Sum stats (IPUMS)
#==============================================================================
for g in ['All','whiteMarried','whiteUnmarried','blackUnmarried']:
    order = 'first'
    if g == 'All':
        mnote = 'all '
        tnote = '(All Mothers)'
        mnum  = 27
    elif g=='whiteMarried':
        mnote = 'white, married '
        tnote = '(White Married Mothers, 20--45)'
        mnum  = 24
    elif g=='whiteUnmarried':
        mnote = 'white, unmarried '
        tnote = '(White Unmarried Mothers, 20--45)'
        mnum  = 24
    elif g=='blackUnmarried':
        mnote = 'black, unmarried '
        tnote = '(Black Unmarried Mothers, 20--45)'
        mnum  = 24
        
    sumIPUMSh = RES + '/census/sumStats/IPUMSstats_'+g+'.tex'
    sumT = open(TAB + 'sumStatsIPUMS_'+g+'.tex', 'w')
    SI = open(sumIPUMSh, 'r').readlines()

    sumT.write('\\begin{table}[htpb!] \n \\begin{center} \n' 
               '\\caption{ACS Descriptive Statistics '+ tnote +'}\n '
               '\\label{bqTab:SumStatsIPUM}'
               '\\begin{tabular}{lccccc} '
               '\n \\toprule\\toprule \\vspace{5mm} \n'
               '& N & Mean & Std. Dev. & Min. & Max. \\\\ \\midrule \n')

    for i,line in enumerate(SI):
        if i>8 and i<mnum:
            if "Young" not in line:
                line = line.replace('\\hline','\\midrule')
                line = line.replace('Good Season of Birth','Born in Quarter 2 or Quarter 3')
                sumT.write(line)

    sumT.write('\n'+mr+mc1+twid[7]+tcm[7]+mc3+
               "Summary statistics are for "+mnote+"  mothers aged 20-45 who are "
               "either head of the household or spouse of the head of the        "
               "household, and have a " + order + " singleton child who is       "
               "\emph{at most} one year old. We exclude women who are in the     "
               "military, in a farm household, or currently in school. We retain "
               "only women who had worked within the previous five years where   "
               "each occupation must have at least 500 women over the entire     "
               "range of survey years. Birth quarter is based on \emph{actual}   "
               "birth quarter.            "
               "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}\\end{center}"
               "\\end{table}")
    sumT.close()


#==============================================================================
#== (4) IPUMS Industry clean
#==============================================================================
#VARIOUS TABS
AllTabs = ['IPUMSIndustryQ2_All'            ,'IPUMSIndustryQ3_All'            ,
           'IPUMSIndustry_All'              ,'IPUMSIndustry_whiteMarried'     ,
           'IPUMSIndustry_blackUnmarried'   ,'IPUMSIndustry_whiteUnmarried'   ,
           'IPUMSIndustry_whiteMarried-emp','IPUMSIndustry_whiteMarried-unemp',
           'IPUMSIndustry_whiteMarried-work10p','IPUMSIndustry_whiteMarried-work10l',
           'IPUMSIndustry_whiteMarried-work20p','IPUMSIndustry_whiteMarried-work20l',
           'IPUMSIndustry_whiteMarried-work30p','IPUMSIndustry_whiteMarried-work30l',
           'IPUMSIndustry_whiteMarried-work40p','IPUMSIndustry_whiteMarried-work40l',
           'IPUMSIndustryLogit_All'         ,'IPUMSIndustryLogit_whiteMarried',
           'IPUMSIndustryNoWork_whiteMarried','IPUMSIndustryInc_whiteMarried' ,
           'IPUMSIndustryLogitNoWork_whiteMarried'                            ,
           'IPUMSIndustryQ2_whiteMarried'   ,'IPUMSIndustryQ3_whiteMarried'   ,
           'IPUMSIndustryQ2_blackUnmarried' ,'IPUMSIndustryQ3_blackUnmarried' ,
           'IPUMSIndustryQ2_whiteUnmarried' ,'IPUMSIndustryQ3_whiteUnmarried' ,
           'IPUMSIndustryIncQ2_whiteMarried','IPUMSIndustryIncQ3_whiteMarried']

for table in AllTabs:
    IPUMSind  = RES + 'census/regressions/'+table+'.tex'
    ipoT = open(TAB + table + '.tex', 'w')
    ipiT = open(IPUMSind, 'r').readlines()

    for i,line in enumerate(ipiT):
        line = line.replace('oneLevelOcc==','')
        line = line.replace('twoLevelOcc==','')
        line = line.replace('Occupations','')
        line = line.replace('Occpations==','')
        line = line.replace('\\end{footnotesize}}\\end{tabular}\\end{table}',
                            '\\end{footnotesize}}\\end{tabular}}\\end{table}')
        line = line.replace('\\begin{tabular}',
                            '\\scalebox{0.95}{\\begin{tabular}')
        ipoT.write(line)
    ipoT.close()
