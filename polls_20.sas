proc import file = "C:\Users\dryan\OneDrive\Documents\Sts499\president_polls_2020_generalElection.csv" out = polls2020
dbms = csv replace;
datarow = 2;
getNames = Yes;
run;

data polls2020;
set polls2020;
if answer = 'Biden' then porp_biden = pct;
if answer = 'Trump' then porp_trump = pct;
run;

proc freq data = polls2020;
tables answer;
run;


data biden;
set polls2020;
where answer in('Biden');
*if cmiss(state) > 0 then delete;
run;

data biden;
set biden;
diff_time = election_date - end_date;
run;

proc means data = biden;
class state;
var porp_biden;
run;

data biden;
set biden;
rename fte_grade = grade;
run;

proc sort data = biden;
by grade;
run;

data biden;
set biden;
if cmiss(grade) > 0 then delete;
run;

data biden;
set biden;
if (grade = 'A+' | grade = 'A' | grade = 'A-' | grade = 'A/' | grade = 'B+') then new_grade = 'A/B';
if(grade = 'B' | grade = 'B-' | grade = 'B/' | grade = 'C+' | grade = 'C' | grade = 'C-' | grade = 'C/' | grade = 'D-') then new_grade = 'B/C';
run;

proc sort data = biden;
by state;
run;


ods pdf file = 'C:\Users\dryan\OneDrive\Documents\Sts499\statePlots20_biden.pdf';
proc sgplot data = biden ;
where new_grade in("A/B","B/C");
scatter x = diff_time y = porp_biden/group = new_grade;
*band x = diff_time upper = upper_two_week lower = lower_two_week / transparency = 0.5;
*lineparm x= state_p y = state_p slope = 0;
xaxis reverse;
title 'all states loess 2020';
loess x = diff_time y = porp_biden/ nomarkers group = new_grade;
by state;
run;
ods pdf close;


proc sort data = biden;
by state;
run;


proc mixed data = biden; 
class new_grade pollster_id;
model porp_biden = new_grade / solution;
random int / subject = pollster_id vcorr;
by state;
run;

proc sort data = biden;
by state;
run;


ods pdf file = 'C:\Users\dryan\OneDrive\Documents\Sts499\spaghetti20_biden.pdf';
proc sgplot data = biden ;
where new_grade in("A/B","B/C") /*& diff_time <101*/;
series x = diff_time y = porp_biden/group = pollster groupLC = new_grade markers groupLP = new_grade groupMC = pollster groupMS = new_grade;
*band x = diff_time upper = upper_two_week lower = lower_two_week / transparency = 0.5;
*lineparm x= state_p y = state_p slope = 0;
xaxis reverse;
title 'spaghetti plot 2020';
*loess x = diff_time y = porp_trump/ nomarkers group = new_grade;
by state;
run;
ods pdf close;


data trump;
set polls2020;
where answer in('Trump');
run;

data trump;
set trump;
diff_time = election_date - end_date;
run;

data trump;
set trump;
rename fte_grade = grade;
run;


data trump;
set trump;
if (grade = 'A+' | grade = 'A' | grade = 'A-' | grade = 'A/' | grade = 'B+') then new_grade = 'A/B';
if(grade = 'B' | grade = 'B-' | grade = 'B/' | grade = 'C+' | grade = 'C' | grade = 'C-' | grade = 'C/' | grade = 'D-') then new_grade = 'B/C';
run;

data trump1;
set trump;
run;

data trump1;
set trump1;
where new_grade in('A/B') | new_grade in('B/C');
run;

proc sort data = trump1;
by state;
run;

data trump1;
set trump1;
diff_time = election_date - end_date;
run;


ods pdf file = 'C:\Users\dryan\OneDrive\Documents\Sts499\statePlots20_trump.pdf';
proc sgplot data = trump1 ;
scatter x = diff_time y = porp_trump/group = new_grade;
*lineparm x= state_p y = state_p slope = 0;
xaxis reverse;
title 'all states loess 2020';
loess x = diff_time y = porp_trump/ nomarkers group = new_grade;
by state;
run;
ods pdf close;

proc means data = trump1;
class state;
var porp_trump;
run;

proc sort data = trump1;
by state pollster_id diff_time;
run;

data polls2;
length fte_grade $4;
set polls2020;

daysbefore = election_date - end_date;
  if daysbefore <= 100 and state ne " " and population="lv";  *keep only those within 100 days, in a state, with likely voters;
run;

proc sort data=polls2;
  by state poll_id question_id; *pollster daysbefore;
run;

data both;
  merge polls2(where=(answer="Biden") rename=(pct=Bidenpct)) 
        polls2(where=(answer="Trump") rename=(pct=Trumppct));   *merge the Biden and Trump results onto one record, but note must rename the variable PCT;
  by state poll_id question_id; *pollster daysbefore;
  if fte_grade in ("A+", "A", "A-", "A/", "B+") then newgrade="A/B";
  else if fte_grade in ("B/", "B", "B-", "C+") then newgrade="B/C";
  else if fte_grade in ("C/", "C", "C-", "D-") then newgrade="C/D";   * New grade group, to include SurveyMonkey mostly;


  pBiden = Bidenpct/(Bidenpct + Trumppct);
  pTrump = Trumppct / (Bidenpct + Trumppct);

  keep state pollster daysbefore Bidenpct Trumppct fte_grade population--office_type end_date election_date 
       newgrade pbiden ptrump question_id;
run;

