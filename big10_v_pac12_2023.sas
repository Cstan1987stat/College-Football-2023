/* The first thing to do is load in the csv file into sas. */
proc import
 datafile = '/home/u63545593/personal/data/23cfootball.csv'/* this is the file path for me
                                                           it may be differnt for other people */
 out = CFB_23
 dbms = 'CSV'
 replace;
 getnames = YES;
run;

/*
proc print data=CFB_23 (obs=10);                 'This is simply a test done to check 
                                                  that the data was loaded in correctly.'
 run; 
 */

/* Creating a new dataset based on the loaded in one, and creating new columns. */
data CFB;
 set CFB_23;
 if Home_Points > Away_Points then Home_W = 1;
  else Home_W = 0;                             /* 1 if home team won in column */
 if Home_W = 1 then Away_W = 0;
  else Away_W = 1;                             /* 1 if away team won in column */   
 Home_Points_1h = Home_1_Q_P + Home_2_Q_P;
 Home_Points_2h = Home_3_Q_P + Home_4_Q_P;
 Away_Points_1h = Away_2_Q_P + Away_2_Q_P;
 Away_Points_2h = Away_3_Q_P + Away_4_Q_P;
 Total_Points = Home_Points + Away_Points;
 Total_Points_2 = Total_Points * Total_Points;
 Total_Points_sq = sqrt(Total_Points);         /* This is the new column used for the 
                                                  model  */
run;

/* Creating a new dataset that includes the new columns where all games are
   conference games */
data conf_games;
 set CFB;
 where Conference_Game = 'TRUE';
run;
 
/* Creating new dataset based on all conferences games where the teams are either Big 10
   or Pac 12. */ 
data rosebowl_conf_games;
 set conf_games; 
 where Home_Conference = 'Big Ten' or Home_Conference = 'Pac-12';
run;

/* Used to determine number of games to include for each conference */
proc freq data=rosebowl_conf_games;        
 table Home_Conference;
 run;

 
/* Getting dataset with just Big 10 games */ 
data bigten;
 set rosebowl_conf_games;
 where Home_Conference = 'Big Ten';
run;

/* Getting dataset with just Pac 12 games */
data pac12;
 set rosebowl_conf_games;
 where Home_Conference = 'Pac-12';
run; 

/* Randomly selecting 54 Big 10 games and outputing as new data set */
proc surveyselect data=bigten out=bigten_s seed = 20      
 /* seed was specififed in order for reproducibility of test */
 sampsize = 54    
 method=srs;
run;
 
/* Randomly selecting 46 Pac 12 games and outputing as new dataset */ 
proc surveyselect data=pac12 out=pac12_s seed = 10
 /* seed was specififed in order for reproducibility of test */
 sampsize = 46 
 method = srs;
run;

/* Combinging two datasets into one */
data pac_big_s_combin;
 set pac12_s bigten_s;
run;

/* Making sure the number of games for each conference is satisifactory */
proc freq data=pac_big_s_combin;
 table Home_Conference;
run;

/* Includes output for assumption work along with p-value to determine 
   potential difference */
proc glm data=pac_big_s_combin plots=diagnostics;
 class Home_Conference;
 model Total_Points = Home_Conference;
 lsmeans Home_Conference / pdiff;
 means Home_Conference / hovtest = bf;
run;




