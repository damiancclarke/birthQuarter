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
ftype = 'nvss'
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

NVSSGoodE =  RES + ftype + '/regressions/NVSSBinaryExpectGood.tex'
NVSSBadE  =  RES + ftype + '/regressions/NVSSBinaryExpectBad.tex'

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
twid = ['10','6','7','7']
tcm  = ['}{p{16.6cm}}','}{p{14.0cm}}','}{p{14.7cm}}','}{p{15.2cm}}']
mc3  = '{\\begin{footnotesize}\\textsc{Notes:} '
lname = "Fertility$\\times$desire"
tname = "Twin$\\times$desire"
tsc  = '\\textsc{' 
ebr  = '}'
R2   = 'R$^2$'



#==============================================================================
#== (2) Write sum stat tables
#==============================================================================
sumT = open(TAB + 'sumBQ'+ftype+'.tex', 'w')

tNV  = open(twinNVSS, 'r').readlines()
tNVe = open(twinEducNVSS, 'r').readlines()
tNVj = open(TallEducNVSS, 'r').readlines()
sNV  = open(singleNVSS, 'r').readlines()
sNVe = open(singleEducNVSS, 'r').readlines()
sNVj = open(allEducNVSS, 'r').readlines()


sumT.write("\\begin{landscape}\\begin{table}[htpb!]"
           "\\caption{Percent of Births by Season} \n"
           "\\label{bqTab:seasonSum}\\begin{center}"
           "\\begin{tabular}{lccccp{1cm}cccc}\n\\toprule \\toprule \n"
           "& \multicolumn{4}{c}{Singletons} && \multicolumn{4}{c}{Twins}"
           "\\\\ \cmidrule(r){2-5} \cmidrule(r){7-10} \n"
           "& Bad & Good & Diff.&Ratio&&Bad&Good & Diff. & Ratio \\\\\n"
           "& Season & Season&&&&Season&Season& &      \\\\\\midrule \n"
           "\multicolumn{10}{l}{\\textsc{Panel A: By Age Groups}}\\\\"
           "\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*9+
           "\\begin{footnotesize}\\end{footnotesize}\\\\ \n")
    
sumT.write( sNV[1]+'&&'+tNV[1].split('&',1)[-1]+'\\\\ \n'
           +sNV[2]+'&&'+tNV[2].split('&',1)[-1]+'\\\\ \n &&&&&&&& \\\\'
            "\multicolumn{10}{l}{\\textsc{Panel B: By Education}}\\\\"
            "\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*9+
            "\\begin{footnotesize}\\end{footnotesize}\\\\ \n"+
            sNVj[1]+'&&'+tNVj[1].split('&',1)[-1]+'\\\\ \n'+
            sNVj[2]+'&&'+tNVj[2].split('&',1)[-1]+'\\\\ \n &&&&&&&& \\\\'
            "\multicolumn{10}{l}{\\textsc{Panel C: By Age and Education}}\\\\"
            "\n"+"\\begin{footnotesize}\\end{footnotesize}& \n"*9+
            "\\begin{footnotesize}\\end{footnotesize}\\\\ \n"+
            sNVe[1]+'&&'+tNVe[1].split('&',1)[-1]+'\\\\ \n'+
            sNVe[2]+'&&'+tNVe[2].split('&',1)[-1]+'\\\\ \n'+
            sNVe[3]+'&&'+tNVe[3].split('&',1)[-1]+'\\\\ \n'+
            sNVe[4]+'&&'+tNVe[4].split('&',1)[-1]+'\\\\ \n &&&&&&&& \\\\'
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
'\\caption{Descriptive Statistics (NVSS 2005-2013)}\n \\begin{tabular}{lccccc} '
'\n \\toprule\\toprule \\vspace{5mm} \n'
'& N & Mean & Std. Dev. & Min. & Max. \\\\ \\midrule \n'
'\multicolumn{6}{l}{\\textbf{Panel A: Mother}} \\\\ \n')

Mu  = open(MumNVSS,  'r').readlines()
MP  = open(MumPNVSS, 'r').readlines()
Ki  = open(KidNVSS,  'r').readlines()

for i,line in enumerate(Mu):
    if i>8 and i<11:
        line = line.replace('\\hline','\\midrule')
        sumT.write(line)
for i,line in enumerate(MP):
    if i>8 and i<13:
        line = line.replace('\\hline','\\midrule')
        line = line.replace('At least some college','Some College +')
        sumT.write(line)

sumT.write(' \n \\multicolumn{6}{l}{\\textbf{Panel B: Child}}\\\\ \n ')
for i,line in enumerate(Ki):
    if i>8 and i<17:
        line = line.replace('\\hline','\\midrule')
        line = line.replace('At least some college','Some College +')
        line = line.replace('Quarter','season of birth')
        sumT.write(line)

sumT.write('\n'+mr+mc1+twid[1]+tcm[1]+mc3+
           "Each sample consists of all first-born children born to white, "
           "non-hispanic, US-born mothers. Good season refers to birth quarters"
           " 2 and 3 (Apr-Jun and Jul-Sept)."
           "\\end{footnotesize}} \\\\ \\bottomrule \n \\end{tabular}\\end{center}"
           "\\end{table}")
sumT.close()


#==============================================================================
#== (4a) Heterogeneity table (birth quarter)
#==============================================================================
hetT = open(TAB + 'quarterHeterogeneity.tex', 'w')
loc  = './../../results/'
rt3  = '/regressions/NVSSBinary.tex'

table = [
'Aged 25-39'    ,'',
'Some College +','',
'Married'       ,'',
'Smoked in Preg','',
'Constant'      ,'',
'Observations'
]
samples = [loc+'nvss'+rt3,loc+'nvss/regressions/NVSSBinarynon-smoking.tex'  ,
loc+'nvss/regressions/NVSSBinarysmoking.tex',loc+'fullT'+rt3,loc+'pre4w'+rt3,
loc+'2012'+rt3,loc+'2012/regressions/NVSSBinaryInfert0.tex',
loc+'2012/regressions/NVSSBinaryInfert1.tex',
loc+'nvss/regressions/NVSSBinaryfullT_IFT1.tex',
loc+'nvss/regressions/NVSSBinarypreT_IFT0.tex']

samples = [loc+'nvss'+rt3,loc+'nvss/regressions/NVSSBinarynon-smoking.tex'  ,
loc+'nvss/regressions/NVSSBinarysmoking.tex',loc+'2012'+rt3,
loc+'2012/regressions/NVSSBinaryInfert0.tex',
loc+'2012/regressions/NVSSBinaryInfert1.tex']

ii = 0
for sample in samples:
    if ii ==1 or ii==2:
        jj = 0
        work  = open(sample,  'r').readlines()
        for i,line in enumerate(work):
            if i>=8 and i<=13 or i==15:
                while jj >= 4 and jj <=7:
                    table[jj]+= '&'
                    jj = jj+1

                line = line.split('&')[-1]
                line = line[:-3]
                table[jj] += '&'+line
                jj = jj+1
    else:
        jj = 0
        work  = open(sample,  'r').readlines()
        for i,line in enumerate(work):
            if i>=8 and i<=17 or i==19:
                line = line.split('&')[-1]
                line = line[:-3]
                table[jj] += '&'+line
                jj = jj+1
    ii = ii+1
hetT.write('\\begin{table}[htpb!] \n ' 
'\\caption{Birth Season and Age: Alternative Samples and Definitions}\n '
'\\begin{center} \n'
'\\begin{tabular}{lcccccc} \\toprule\\toprule \n'
'\\textsc{Dep Var:}&(1)&(2)&(3)&(4)&(5)&(6)\\\\'
'Good Season&&\multicolumn{2}{c}{Smoked During Preg}&'
'&\multicolumn{2}{c}{Assisted Reproductive Tech.}'
'\\\\\cmidrule(r){3-4}\cmidrule(r){6-7}\n'
'&All&Non-  &Smoker&2012- &No&Yes \\\\'
'&   &Smoker&       &2013\ &  &  \\\\ '
'\\midrule\n')
hetT.write(table[0]+'\\\\ \n'
+table[1]+'\\\\ \n'
+table[2]+'\\\\ \n'
+table[3]+'\\\\ \n'
+table[4]+'\\\\ \n'
+table[5]+'\\\\ \n'
+table[6]+'\\\\ \n'
+table[7]+'\\\\ \n'
+table[8]+'\\\\ \n'
+table[9]+'\\\\ \\midrule \n'
+table[10]+'\\\\ \n'
)


hetT.write('\n'+mr+mc1+twid[2]+tcm[2]+mc3+
           'All specifications are linear probability models estimates by OLS w'
           'ith heteroscedasticity-robust standard errors. Full term in column '
           '(4) refers to any babies whose gestation was greater than or equal '
           'to 39 weeks. Infertility treatment regressions are only estimated f'
           'or years 2012-2013.  Column (9) is the union of columns (8) and (4)'
           ', column (10) is the union of (7) and (5).'
           '\\end{footnotesize}}\\\\ \\bottomrule \n\\end{tabular}\\end{center}'
           '\\end{table}'
)
hetT.close()

#==============================================================================
#== (4b) Heterogeneity table (quality)
#==============================================================================
hetT = open(TAB + 'qualityHeterogeneity.tex', 'w')
loc  = './../../results/'
rt3  = '/regressions/NVSSQualityEduc.tex'

table = [
'Aged 25-39'    ,'',
'Bad Season    ','',
'Some College +','',
'Married'       ,'',
'Smoked in Preg','',
'Constant'      ,'',
'Observations'
]
samples = [loc+'nvss'+rt3,loc+'nvss/regressions/NVSSQualitySmoke0.tex'      ,
loc+'nvss/regressions/NVSSQualitySmoke1.tex',loc+'fullT'+rt3,loc+'pre4w'+rt3,
loc+'2012'+rt3,loc+'2012/regressions/NVSSQualityInfert0.tex',
loc+'2012/regressions/NVSSQualityInfert1.tex']
samples = [loc+'nvss'+rt3,loc+'nvss/regressions/NVSSQualitySmoke0.tex'      ,
loc+'nvss/regressions/NVSSQualitySmoke1.tex',
loc+'2012'+rt3,loc+'2012/regressions/NVSSQualityInfert0.tex',
loc+'2012/regressions/NVSSQualityInfert1.tex']

ii = 0
for sample in samples:
    if ii ==1 or ii==2:
        jj = 0
        work  = open(sample,  'r').readlines()
        for i,line in enumerate(work):
            if i>=8 and i<=13 or i==15:
                while jj >= 4 and jj <=9:
                    print jj
                    table[jj]+= '&'
                    jj = jj+1

                line = line.split('&')[2]
                table[jj] += '&'+line
                jj = jj+1
    else:
        jj = 0
        work  = open(sample,  'r').readlines()
        for i,line in enumerate(work):
            if i>=8 and i<=19 or i==21:
                line = line.split('&')[2]
                table[jj] += '&'+line
                jj = jj+1
    ii = ii+1
hetT.write('\\begin{table}[htpb!] \n '
'\\caption{Birth Quality and Age: Alternative Samples and Definitions}\n '
'\\begin{center} \n'
'\\begin{tabular}{lcccccc} \\toprule\\toprule \n'
'\\textsc{Dep Var:}&(1)&(2)&(3)&(4)&(5)&(6)\\\\'
'Birthweight&&\multicolumn{2}{c}{Smoked During Pregnancy}&'
'&\multicolumn{2}{c}{Assisted Reproductive Tech.}\\\\ '
'\cmidrule(r){3-4}\cmidrule(r){6-7}\n'
'&All&Non-  &Smoker&2012- &No&Yes \\\\'
'&   &Smoker&      &2013\ &  &    \\\\ \\midrule\n')
hetT.write(table[0]+'\\\\ \n'
+table[1 ] + '\\\\ \n'
+table[2 ] + '\\\\ \n'
+table[3 ] + '\\\\ \n'
+table[4 ] + '\\\\ \n'
+table[5 ] + '\\\\ \n'
+table[6 ] + '\\\\ \n'
+table[7 ] + '\\\\ \n'
+table[8 ] + '\\\\ \n'
+table[9 ] + '\\\\ \n'
+table[10] + '\\\\ \n'
+table[11] + '\\\\ \\midrule \n'
+table[12] + '\\\\ \n'
)


hetT.write('\n'+mr+mc1+twid[3]+tcm[3]+mc3+
           'All specifications are identical to column (2) of table 5 estimated'
           ' by OLS with heteroscedasticity-robust standard errors. Full term i'
           'n column (4) refers to any babies whose gestation was greater than '
           'or equal to 39 weeks. Infertility treatment regressions are only es'
           'timated for years 2012-2013.'
           '\\end{footnotesize}}\\\\ \\bottomrule \n\\end{tabular}\\end{center}'
           '\\end{table}'
)
hetT.close()

#==============================================================================
#== (5) Fix labelling of gestation correction table
#==============================================================================
goodT = open(NVSSGoodE, 'r').readlines()
badT  = open(NVSSBadE , 'r').readlines()

outG = open(TAB + 'NVSSBinaryExpectGood.tex', 'w')
outB = open(TAB + 'NVSSBinaryExpectBad.tex' , 'w')

for line in goodT:
    line = line.replace('(due in good)','')
    line = line.replace('\\midrule'    ,'')
    line = line.replace('Aged','&(due in good)'*4+'\\\\ \\midrule\n Aged')
    line = line.replace('Observations','\\midrule\n Observations')
    outG.write(line)
for line in badT:
    line = line.replace('(due in bad)','')
    line = line.replace('\\midrule'    ,'')
    line = line.replace('Aged','&(due in bad)'*4+'\\\\ \\midrule\n Aged')
    line = line.replace('Observations','\\midrule\n Observations')
    outB.write(line)

outG.close
outB.close

#==============================================================================
#== (X) write tables.tex file
#==============================================================================
#===== TABLE 1: Descriptive Statistics                                        X
#===== TABLE 2: Percent births by season [G]                                  X
#===== TABLE 3: Birth by season                                               X
#===== TABLE 3: Birth by season EB                                            X
#===== TABLE 3: Birth by season EG                                            X

#===== TABLE 4: Heterogeneity birth season [G,l]                              X
#===== TABLE 5: Quality full [l]                                              X
#===== TABLE 6: Quality heterogeneity bwt [G,l]                               X        
#===== TABLE 7: Qualilty gestation correction                                 X
#===== TABLE 8: Spain select  [l]                                             X
#===== TABLE 9: Spain quality [l]                                             X
#===== TABLE 10: Spain quality gestation correction                           X
#==============================================================================
loc1  = './../tables/'
loc2  = './../results/'+ftype+'/regressions/'
loc3  = './../results/spain/regressions/'
final = open(TAB + "tables"+ ftype +".tex", 'w')

TABLES = [loc1+'sumStats'+ftype+'.tex', loc1+'sumBQ'+ftype+'.tex'      ,
loc2+'NVSSBinary.tex'                 , loc1+'NVSSBinaryExpectBad.tex' ,
loc1+'NVSSBinaryExpectGood.tex'       , loc1+'quarterHeterogeneity.tex',
loc2+'NVSSQualityEduc.tex'            , loc1+'qualityHeterogeneity.tex', 
loc2+'NVSSQualityGestFix.tex'         , loc2+'NVSSQualityGFYoung1.tex' ,
loc2+'NVSSQualityGFYoung0.tex'        , loc3+'spainBinary.tex'         ,       
loc3+'spainQualityEduc.tex'           , loc3+'spainQualityGestFix.tex' ]

itera = 1

for table in TABLES:
    if itera<6 or itera==9 or itera==10 or itera==11 or itera==14:
        final.write('\\input{'
                    +table+'}\n')
    if itera==6 or itera==7 or itera==8 or itera==12 or itera==13:
        final.write('\\begin{landscape}\\input{'
                    +table+'}\\end{landscape}\n')
    itera = itera+1
final.close()
