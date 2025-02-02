#!/usr/bin/perl

################################################################################
#
#  xymon remote mq monitoring
#
#  -----------------------------------------------------------------------------
#  Description:
#
#  -----------------------------------------------------------------------------
#  Notes:
#    following HTML Style is needed in xymonmq.css
#      table.top { width:100%; } 
#      td.top {
#        width:100px;       text-align:center; 
#        padding-left:5px;  padding-right:5px;}
#      th.head {
#        text-align:left;}
#      td.left { 
#        text-align:left;  
#        padding-left:5px;  padding-right:5px; }
#      td.right {
#         text-align:right;
#         padding-left:5px; padding-right:5px; }
#      td.center { 
#        text-align:right; 
#        padding-left:5px;  padding-right:5px; }
#      td.na { 
#        background-color:DimGray; color:white; 
#        padding-left:5px;         padding-right:5px; }
#      td.ok {
#        background-color:green;   color:black; 
#        padding-left:5px;         padding-right:5px; }
#      td.war     { 
#       background-color:yellow;   color:black; 
#        padding-left:5px;         padding-right:5px; }
#      td.err     {
#        background-color:Crimson; color:white; 
#        padding-left:5px;         padding-right:5px; }
#      td.ign     {
#        background-color:blue;    color:white; 
#        padding-left:5px;         padding-right:5px; }
#      td.tig     {
#        background-color:WhiteSmoke; color:black; 
#        padding-left:5px;            padding-right:5px; }
#      td.org-ok  {
#        border:4px solid green;  
#        padding-left:5px;         padding-right:5px; }
#      td.org-war {
#        border:4px solid yellow; 
#        padding-left:5px;         padding-right:5px; }
#      td.org-err {
#        border:4px solid red;    
#        padding-left:5px;     padding-right:5px; }
#  hostsvc_header needs a link to xymonmq.css
#
#  -----------------------------------------------------------------------------
#  Functions:
#    - logger          2.05.00   
#    - logfdc          2.05.00  
#    - newHash         2.00.00
#    - sendSigHup      2.03.00
#    - sigInt()        2.03.00
#    - sigHup()        2.03.00
#    - usage           2.00.02
#    - cleanUp         2.10.08
#    - listCfg         2.00.02
#    - setTmpIgn       2.00.02
#    - setTmpEnable    2.10.07
#    - getTmpIgn       2.00.03
#    - getTmpEnb       2.10.07
#    - printHash       2.00.00   (for dbg only)    
#    - getCfg          2.00.00
#    - xml2hash        2.00.00
#    - expandHash      2.05.00
#    - mergeHash       2.00.00
#    - connQmgr        2.00.00
#    - checkCfg        2.17.00
#    - getPlatform     2.00.00
#    - cfg2conn        2.00.00 
#    - getObjState     2.00.00
#    - shrinkAttr      2.00.00
#    - execMqsc        2.00.00 
#    - joinQlstat      2.04.00
#    - joinChStat      2.04.00
#    - joinLsStat      2.10.00
#    - parseMqsc       2.00.00 2.09.00
#    - disQl           2.00.00 
#    - disXq           2.04.00
#    - disQs           2.00.00 
#    - disQmgrAlias    2.03.00
#    - disChl          2.03.00
#    - disChs          2.01.00 
#    - pingChl         2.12.00
#    - disQmStat       2.10.00
#    - disList         2.10.00
#    - disLisStat      2.10.00
#    - disServ         2.10.00
#    - disServStat     2.10.00
#    - stateFromFile   2.12.04 
#    - stateToFile     2.12.04
#    - evalStat        2.00.03 
#    - evalAttr        2.00.00
#    - lev2id          2.03.00
#    - cmpTH           2.00.00 2.10.00
#    - calcRatio       2.04.00
#    - getMonHash      2.00.00 
#    - checkMonTime    2.00.00
#    - enbIgn          2.10.07
#    - tree2format     2.00.00
#    - printMsg        2.00.04 
#    - xymonMsg        2.00.03 
#    - mailMsg         2.06.00
#    - sendMail        2.06.00
#
#  -----------------------------------------------------------------------------
#  History
#  28.10.2016 2.00.00 am Initial Version
#  15.11.2016 2.00.01 am getMonHash bugs solved
#  25.11.2016 2.00.02 am setTmpIgn, 
#                        printMsg, 
#                        xymonMsg
#                        command line handling
#                        return 2 rc from getMonHash + getting them in 
#                        getMonHash getTmpMsg
#  29.11.2016 2.00.03 am evalStat, xymonMsg _stat->...{ignore} introduced
#  15.12.2016 2.00.04 am show phone nr in header
#  27.12.2016 2.01.00 am disChs for showing SVRCONN 
#  13.11.2017 2.03.00 am Unix / direct connection: cfg2conn
#                        dis{Obj} ping qmgr added for Unix
#                        monitor trashold for appl->{type}{$type} 
#                        showing queue manager state at the top of xymon
#  27.08.2018 2.04.00 am first productive version
#                        monitor tag key value swaped to trashhold = level
#                        handling runmqsc zombies improved
#                        reconnect counter introduced
# 20.09.2018 2.05.00 am monitoring times as a hash, new format of ini files
# 05.10.2018 2.05.01 am expandHash expands whole tree
# 24.10.2018 2.05.02 am getMonHash obj definition found, checkMonTime 
#                       elsif condition check _defined $_mon added
#                       calcRatio added for XMITQ
# 06.11.2018 2.05.03 am @import in ini file improved, possible to import stanza 
#                       from any level of the tree
# 08.12.2018 2.05.04 am persistent ingore for combined attributes implemanted
#                       reset command displayed
# 23.01.2019 2.05.05 am rename $msg / %msg in printMsg to $xymMsg / %xymMsg
# 31.01.2019 2.06.00 am send mail activated
# 31.01.2019 2.06.01 am send mail debugging text to stdout deleted
# 01.02.2019 2.06.02 am imaginary type QLOUT added, can be used to re-route 
#                       xymon messages for QL to SYS-MQ view
#                       keep tag added to ini file to provide QLOUT
# 05.02.2019 2.07.00 am no execMqsc if send tag is missing (why to calculate 
#                       if nothing to send)
#                       handling CSQM297I message
# 05.02.2019 2.07.01 am code cleanup dis obj
#                       new obj type mqSVRCONN equals SVRCONN 
#                       used for duplicating the service
# 20.02.2019 2.07.02 am rename QLOUT to mqQLOCAL
# 19.03.2019 2.07.03 am temporary ignore for comb state bug in evalStat solved
# 12.04.2019 2.08.00 am send to patrol started
#                       bbrmq.pl with no attributes -> show usage and die
# 10.05.2019 2.08.01 am send to patrol, 1st working version
# 15.05.2019 2.09.00 am Ver. 9.1 AMQ\d{4} Messages replaced by AMQ\d{4}\w 
# 22.05.2019 2.09.01 am monitoring time for obj->{attr}{$attr} key/value swaped
#                       in function getMonHash. 
#                       this error 2.04.00 was produced in Ver 2.04.00
# 07.06.2019 2.09.02 am monitoring time for mail bug solved
# 28.06.2019 2.09.03 am patrol Warnings disabled. bug: OK->WAR->ERR ERR not sent
# 19.07.2019 2.09.04 am getMonHash {obj}{$obj}{attr}{$attr}{monitor}{time} 
# 22.07.2019 2.09.05 am evalStat $th not initialized for combine, solved
# 22.07.2019 2.09.06 am getMonHash empty monitor hash on attr level not wokring
# 23.07.2019 2.09.07 am evalStat display empty monitor hash on attr level gray
# 31.07.2019 2.09.08 am qmgr->obj->attr->monitor inherit ->time bug solved
# 02.08.2019 2.09.09 am $_stObj->{attr}{$cmb}{monitor} in evalStat was set to 
#                       SCALAR, the code was comment out.
# 09.08.2019 2.09.10 am bug evaluating levAttr to levObj in evalStat solved
# 12.08.2019 2.10.00 am types QMGR, LISTENER added 
#                       functions( disQmStat, disList, disLisStat, joinLsStat,
#                       disServ, disServStat )
#                       cmpTH operator ! introduced
# 19.08.2019 2.10.01 am call logger() from main, logger $par undefined bug
#                       info column in xymon introduced
#                       info key in xymon send stanza
# 26.08.2019 2.10.02 am check time, return ON only at the end of the function
#                         check time only worked by random, depending 
#                         on keys sequnece
# 27.08.2019 2.10.03 am disQmgrAlias rmoved from bbrmq.pl, sub from lib should
#                         be used
# 10.09.2019 2.10.04 am only allowed cmd attributes possible
#                       code cleanup
# 15.09.2019 2.10.05 am cmdln bbrmq.pl -ignore ... bug solved 
# 18.09.2019 2.10.06 am css moved to xymonmq.css;output in IE & Chrome improved 
# 20.09.2019 2.10.07 am enable monitoring
# 28.10.2019 2.10.08 am cleanup old mail files (func clenUp added)
# 12.12.2019 2.10.09 am "))" in conname causes emtpy DESCR 
# 12.12.2019 2.10.10 am INITQ type added
# 20.02.2019 2.11.00 am introducing level: "early" for early warning, e.g. used 
#                       for longrty / shorty in channel monitoring to avoid 
#                       yellow alerts on discint=0 after channel has been 
#                       started
# 24.02.2019 2.11.01 am bug solved: temporary ignore for mails not taken 
#                       into account 
# 27.02.2019 2.12.00 am ping channel introduced
#                       default treshold in evalAttr introduced
# 28.02.2019 2.12.01 am ping chl on zos
#                       dont ping running chl
# 02.03.2019 2.12.02 am OK as ping status not working, solved
# 05.03.2019 2.12.03 am cmpTH undefine / format err
#                       FORMAT match to ERR level introduced
#                       print FORMAT err to STDOUT
#                       pingChl MVS bugs solved
# 12.03.2019 2.12.04 am QTIME1, QTIME2 & co. monitoring introduced
#            2.12.05 am appl name added to the e-mail subject 
# 02.04.2019 2.12.06 am PING channel only during office times
# 20.04.2019 2.12.07 am dis qmgr if PING CHL on time out
#                       TIMEOUT variable introduced
# 21.04.2019 2.12.08 am 2.13.06 functionality removed
#                       mailMsg bug with undefined $th in report variable 
#                         solved for combined status
# 06.05.2019 2.12.09 am removing debug pinc chl information
#                       CSQ9006E message handling on ZoS MQSC output
# 06.05.2019 2.12.10 am mailMsg th not defined for combined attribute (SDR/SVR)
#                         solved
# 27.08.2020 2.13.00 am $key=$val in mailMsg bug solved
#                       set ignore until green 
#                       don't delete ignore file for files created 
#                       on 1st Jan 197 + max 10 sec
#                       delete ignore until green file if green.
# 24.09.2020 2.13.01 am set combined attribute on ignore
# 19.11.2020 2.13.02 am mqSDR type added
# 05.05.2021 2.13.03 am keep only first element working solved
# 10.06.2021 2.13.04 am BOQ for Back Out Queues introduced
# 10.08.2021 2.13.05 ef runmqsc path moved to 923
# 20.10.2021 2.13.06 am no object found on zos handling adjusted
#                       allow '.' (dot) in the application name / needed in ign
#                       show application in the header of xymon output
# 26.11.2021 2.14.00 am - issues with strict hash-key handling in new 
#                         perl version solved
#                       - ini-dir and flag-dir changed 
#                       - log-dir introduce
#                       - type mqQLOCAL removed
# 07.12.2021 2.14.01 am - sort types before sending to xymon (e.g. SDR always at
#                         top of SVR)
#                       - check if $_conn exists for $_cfg qmgr == is qmgr 
#                         configured for connect
# 31.03.2022 2.14.02 am - calcRation 4th attribute RATIO-KEY introduced
# 14.10.2022 2.15.00 am - merge with syspmq3 / automatic enable combSTATUS 
#                         on until green
# 19.10.2022 2.15.01 am - ignore empty keep and exclude object array
# 08.02.2022 2.16.00 am - type mqSDR  removed
#                         sendMail CC & BCC added
# 27.02.2022 2.17.00 am - checkCfg introduced
# 01.03.2022 2.17.01 am - printHash level introduced
#                       - ps command for stop comm replaced by args
# 07.03.2022 2.17.02 am - evalStat fix ignore on object level. tig and ign have
#                         a higher level as early
#                       - TIMEOUT vara removed and replaced by $timeA & timeD
#                       - ps command catches only bbrmq and perl
# 13.03.2022 2.17.03 am - joinChStat, mqSVRCONN regex replaced by eq SVRCONN
#                       - increase runmqsc timeout from 10 to 20
#                       - call setMaxFS with 2088960 (2TGB)
# 22.12.2023 2.17.04 am - who is functionality in setTmpIgn()
#
#  to be done:
# redesiegn PING
#
#
# BUGS:
#   sub cmpTH: check eq and nq first, > and < after it.
#              in > < val is checked on digit, th not. th should be checked 
#
################################################################################

use strict ;
use warnings ;

BEGIN
{
  push @INC, $ENV{HOME}.'/monitor/lib' ;
}

use FileHandle ;           # for file handel as object
use IPC::Open2 ;           # for runmqsc starting in the background
use POSIX ":sys_wait_h" ;  # for no hang on runmqsc in the background

use Sys::Hostname;

use Time::Local ;
use Time::HiRes qw(usleep nanosleep gettimeofday);

use Data::Dumper ;

use xymon ;

use qmgr ;

my $VERSION = "2.17.04" ;

################################################################################
#
#   L I B R A R I E S
#
################################################################################
use FileHandle ;           # for file handel as object
use IPC::Open2 ;           # for runmqsc starting in the background

################################################################################
#
#   E N V I R O N M E N T   
#
################################################################################
delete $ENV{MQPROMPT} if exists $ENV{MQPROMPT}; 

my $sysUrl = "https://".hostname().".deutsche-boerse.de/mqmon" ;

################################################################################
#
#   C O N S T A N T S  
#
################################################################################
my $ON  = 1 ;
my $OFF = 0 ;

my $NA     = -2;
my $SHW    = -1;
my $OK     =  0;
my $IGN    =  1;
my $TIG    =  2; # temporary ignore
my $EARLY  =  3; # early warning
my $WAR    =  4;
my $ERR    =  5;
my $FORMAT =  6; 

my %LEV = ( $NA     => 'NA'   , 
            $SHW    => 'SHW'  ,
            $OK     => 'OK'   ,
            $IGN    => 'IGN'  ,
            $TIG    => 'TIG'  ,
            $EARLY  => 'EARLY',
            $WAR    => 'WAR'  ,
            $ERR    => 'ERR'  , 
            $FORMAT => 'ERR' );


my $TMP = "/home/mqmon/monitor/flag/mqmon" ;
my $PCHTMP = $TMP.'/pingchl' ;
my $LOG = "/home/mqmon/monitor/log/mqmon" ;
my $MAIL_MAX_AGE =  2600000 ;  # app 1 Month

my $DOWN    = -99 ;
my $START   = 0;
my $STOP    = 1;
my $RESTART = 2;
my $IGNORE  = 3;
my $ENABLE  = 4;
my $DISABLE = 5;
my $CHECK   = 6;
my $DBG     = 99;

my $levelFormat  = "|@>|";

################################################################################
#
#   G L O B A L S  
#
################################################################################
my $cfg = "/home/mqmon/monitor/ini/mqmon/mqmon.ini" ;
my $runmqsc = "/usr/bin/runmqsc -e " ;
my $patrol  = "/opt/Patrol/MSEND/PatrolEvent" ;

my $_conn ;  # $_conn has to be global so it can be used in the signal handler

# ----------------------------------------------------------
# logger
# ----------------------------------------------------------
my $LF ;     # logger file name

################################################################################
#
#   S I G N A L S  
#
################################################################################

$SIG{HUP} = \&sigHup ;
$SIG{INT} = \&sigInt ;

################################################################################
#
#   C O M M A N D   L I N E   
#
################################################################################
my $mainAttr ;

my $gList   = 0 ;
my $gRun     ;
my $gDbg     = $DOWN ;

my $gIgnAppl ;
my $gIgnQmgr ;
my $gIgnType ;
my $gIgnObj ;
my $gIgnShow ;
my $gIgnAttr ;
my $gIgnTime ;

my $gEnbAppl = 'all' ;    # Enable all per default
my $gEnbQmgr = 'all' ;    # Enable all per default
my $gEnbType = 'all' ;    # Enable all per default
my $gEnbTime = 3600  ;    # Default Enable is one hour

my $gDsbQmgr ;
my $gDsbTime ;

my $gChkIni ;

my $argc = scalar @ARGV ;

# ------------------------------------------------------------------------------
# no arguments is not allowed
# ------------------------------------------------------------------------------
&usage() unless scalar @ARGV > 0 ;

# ------------------------------------------------------------------------------
# go through all arguments
# ------------------------------------------------------------------------------
while( defined $ARGV[0] )
{
  my $opt = '' ;

  # --------------------------------------------------------  
  #  opt starts with -  
  # --------------------------------------------------------  
  if( $ARGV[0] =~ s/^-// )
  {
    $opt = $ARGV[0] ;
  } 

  # --------------------------------------------------------  
  # ignore ( main attribute)
  # --------------------------------------------------------  
  if( $opt eq 'ignore' )
  {
    &usage() if defined $mainAttr ;
    $mainAttr = $opt;
    $gRun = $IGNORE ;
    if( defined $ARGV[1] && $ARGV[1] !~ /^-/ )
    {
      shift @ARGV ;
      $gIgnShow = $ARGV[0] ;
      if( $gIgnShow eq 'err' )
      {
        $gIgnShow = $ERR ;
      }
      elsif( $gIgnShow eq 'war' )
      {
        $gIgnShow = $WAR ;
      }
      else
      {
        &usage() ;
      }
    }
    shift @ARGV;
    next ;
  }

  # --------------------------------------------------------  
  # enable monitoring ( main attribute )
  #   ignore temporary and persistent disabeling
  # --------------------------------------------------------  
  if( $opt eq 'enable' )
  {
    &usage() if defined  $mainAttr ;
    $mainAttr = $opt ;
    $gRun = $ENABLE ;
    shift @ARGV;
    next ;
  }

  # --------------------------------------------------------  
  # disable monitoring ( main attribute )
  #   disable monitoring for only one queue manager 
  #   avoiding timeouts if queue not accessable
  # --------------------------------------------------------  
  if( $opt eq 'disable' )
  {
    &usage() if defined $mainAttr ;
    $mainAttr = $opt ;
    $gRun = $DISABLE ;
    shift @ARGV;
    next ;
  }

  # --------------------------------------------------------  
  # list configuration ( main attribute )
  # --------------------------------------------------------  
  if( $opt eq 'list' )
  {
    &usage() if defined $mainAttr ;
    $mainAttr = $opt;
    $gList = 1 ;
    shift @ARGV;
    next ;
  }

  # --------------------------------------------------------  
  # stop monitoring ( main attribute )
  # --------------------------------------------------------  
  if( $opt eq 'stop' )
  {
    $gRun = $STOP ;
    &usage() if defined $mainAttr ;
    $mainAttr = $opt;
    shift @ARGV;
    next ;
  }

  # --------------------------------------------------------  
  # start monitoring ( main attribute )
  # --------------------------------------------------------  
  if( $opt eq 'start' )
  {
    &usage() if defined $mainAttr ;
    $mainAttr = $opt;
    $gRun = $START ;
    shift @ARGV;
    next ;
  }

  # --------------------------------------------------------  
  # restart monitoring ( main attribute )
  # --------------------------------------------------------  
  if( $opt eq 'restart' )
  {
    &usage() if defined $mainAttr ;
    $mainAttr = $opt;
    $gRun = $RESTART ;
    shift @ARGV;
    next ;
  }

  # --------------------------------------------------------  
  # debug monitoring 
  #  main attributes, other main attributes are allowed 
  # --------------------------------------------------------  
  if( $opt eq 'dbg' )
  {
    &usage() if defined $mainAttr ;
    $mainAttr = $opt;
    $gDbg = $DBG ;
    shift @ARGV;
    next ;
  }

  if( $opt eq 'check' )
  {
    &usage() if defined $mainAttr ;
    $mainAttr = $opt;
    $gRun = $CHECK ;
    shift @ARGV;
    next ;
  }

  # --------------------------------------------------------  
  # optional attributes with 
  #   main attribute: ignore
  # --------------------------------------------------------  
  if( $mainAttr eq 'ignore' )
  {
    shift @ARGV ;
    # ----------------------------------
    # applicaiton name
    # ----------------------------------
    if( $opt eq 'appl' )
    {
      &usage() unless defined $ARGV[0] ;
      $gIgnAppl = $ARGV[0] ;
      shift @ARGV ;
      next;
    }

    # ----------------------------------
    # qmgr name
    # ----------------------------------
    if( $opt eq 'qmgr' )
    {
      &usage() unless defined $ARGV[0] ;
      $gIgnQmgr = $ARGV[0];
      shift @ARGV ;
      next;
    }

    # ----------------------------------
    # mq object type name
    # ----------------------------------
    if( $opt eq 'type' )
    {
      &usage() unless defined $ARGV[0] ;
      $gIgnType = $ARGV[0];
      shift @ARGV; 
      next;
    }

    # ----------------------------------
    # mq object name or object parse
    # ----------------------------------
    if( $opt eq 'obj' )
    {
      &usage() unless defined $ARGV[0] ;
      $gIgnObj = $ARGV[0];
      shift @ARGV; 
      next;
    }

    # ----------------------------------
    # mq object attribute name
    # ----------------------------------
    if( $opt eq 'attr' )
    {
      &usage() unless defined $ARGV[0] ;
      $gIgnAttr = $ARGV[0] ;
      shift @ARGV;
      next;
    }

    # ----------------------------------
    # time to ignore
    # ----------------------------------
    if( $opt eq 'time' )
    {
      &usage() unless defined $ARGV[0] ;
      $gIgnTime = $ARGV[0] ;
      shift @ARGV;
      next;
    }

    # ----------------------------------
    # all other -> print usage & quit
    # ----------------------------------
    &usage();
  }

  # --------------------------------------------------------  
  # optional attributes with 
  #   main attribute: enable
  # --------------------------------------------------------  
  if( $mainAttr eq 'enable' )
  {
    shift @ARGV ;

    # ----------------------------------
    # applicaiton name
    # ----------------------------------
    if( $opt eq 'appl' )
    {
      &usage() unless defined $ARGV[0] ;
      $gEnbAppl = $ARGV[0] ;
      shift @ARGV ;
      next;
    }

    # ----------------------------------
    # queue manager name
    # ----------------------------------
    if( $opt eq 'qmgr' )
    {
      &usage() unless defined $ARGV[0] ;
      $gEnbQmgr = $ARGV[0] ;
      shift @ARGV ;
      next;
    }

    # ----------------------------------
    # object type name
    # ----------------------------------
    if( $opt eq 'type' )
    {
      &usage() unless defined $ARGV[0] ;
      $gEnbType = $ARGV[0] ;
      shift @ARGV ;
      next;
    }

    # ----------------------------------
    # object type name
    # ----------------------------------
    if( $opt eq 'time' )
    {
      &usage() unless defined $ARGV[0] ;
      $gEnbTime = $ARGV[0] ;
      shift @ARGV ;
      next;
    }

    # ----------------------------------
    # all other -> print usage & quit
    # ----------------------------------
    &usage();
  }

  # --------------------------------------------------------  
  # optional attributes with 
  #   main attribute: disable
  # --------------------------------------------------------  
  if( $mainAttr eq 'disable' )
  {
    shift @ARGV ;

    # ----------------------------------
    # queue manager name
    # ----------------------------------
    if( $opt eq 'qmgr' )
    {
      &usage() unless defined $ARGV[0] ;
      $gDsbQmgr = $ARGV[0] ;
      shift @ARGV ;
      next;
    }

    # ----------------------------------
    # queue manager name
    # ----------------------------------
    if( $opt eq 'time' )
    {
      &usage() unless defined $ARGV[0] ;
      $gDsbTime = $ARGV[0] ;
      shift @ARGV ;
      next;
    }

    # ----------------------------------
    # all other -> print usage & quit
    # ----------------------------------
    &usage();
  }

  # --------------------------------------------------------  
  # optional attributes with 
  #   main attribute: disable
  # --------------------------------------------------------  
  if( $mainAttr eq 'check' )
  {
    shift @ARGV ;

    # ----------------------------------
    # ini file path
    # ----------------------------------
    if( $opt eq 'ini' )
    {
      &usage() unless defined $ARGV[0] ;
      $gChkIni = $ARGV[0] ;
      shift @ARGV ;
      next ;
    }
    &usage();
  }     

  &usage() ;
}



################################################################################
#
#   F U N C T I O N S  
#
################################################################################

################################################################################
# logger
################################################################################
sub logger
{
  my $SYSdate =  time()            ;
  my @SYSdate =  localtime $SYSdate;

  my $ss   =  $SYSdate[0] ;
  my $mm   =  $SYSdate[1] ;
  my $hh   =  $SYSdate[2] ;
  my $dd   =  $SYSdate[3] ;
  my $MM   =  $SYSdate[4] + 1 ;
  my $YYYY =  $SYSdate[5] + 1900 ;
  my $wd   =  $SYSdate[6] ;

  my $day = sprintf("%4d-%2d-%2d", $YYYY, $MM, $dd );
  my $time = sprintf("%2d:%2d", $hh, $mm)  ;
     $day =~ s/ /0/g;
     $time =~ s/ /0/g;

  my $src  =  [caller(0)]->[1] ; 
  my $par  =  [caller(1)]->[3] ;   #parent
  if( defined $par )
  {
    $par  =~ s/^\w+?::// ;
  }
  else
  {
    $par = 'main' ;
  }
  my $line =  [caller(0)]->[2] ; 

  $LF = $LOG.'/bbrmq.'.$day.'.'.$$.'.log' ;

  open FD, ">>$LF" ;

  print FD $day  ." ".
           $time ." ".
           $src  .":". 
           $par  ."(".
           $line .")".
           "\n" ;
  close FD ;
}

################################################################################
# stack
################################################################################
sub logfdc
{
  my $SYSdate =  time()            ;
  my @SYSdate =  localtime $SYSdate;

  my $ss   =  $SYSdate[0] ;
  my $mm   =  $SYSdate[1] ;
  my $hh   =  $SYSdate[2] ;
  my $dd   =  $SYSdate[3] ;
  my $MM   =  $SYSdate[4] + 1 ;
  my $YYYY =  $SYSdate[5] + 1900 ;
  my $wd   =  $SYSdate[6] ;

  my $day = sprintf("%4d-%2d-%2d", $YYYY, $MM, $dd );
  my $time = sprintf("%2d:%2d", $hh, $mm)  ;
     $day =~ s/ /0/g;
     $time =~ s/ /0/g;

  my $FDC = $LOG.'/bbrmq.'.$day.'.'.$$.'.fdc' ;

  open FDC, ">>$FDC" ;

  print FDC "----------------------------------------";
  print FDC "----------------------------------------\n";
  print FDC "Program\t\t:".$0."\n";
  print FDC "Time Stamp\t: $day $time\n" ;

  
  print FDC "\n----------------------------------------\n";
  print FDC "Last Function call: ";

  print FDC "  sub ". [caller(1)]->[3]."( )\n"; 
  if( [caller(1)]->[4] == 1 )
  {
    my $i = 1 ;
    foreach my $attr (@_)
    {
      print FDC "--------------------\n" ;
      print FDC "  attr ".$i." ". ref($attr) ."\n";
      print FDC Dumper \$attr ;
      $i++;
    }
  }

  print FDC "\nStack:\n";

  my @stack ;

  my $func = "" ;
  for( my $i=0; $func ne "main" ;$i++ )
  {
    $func = [caller($i)]->[3] ;
    $func = "main" unless defined $func ;
    $func =~ s/^.+?::// ;
    my $line = [caller($i)]->[2] ;
       $line = '?' unless defined $line ;
    push @stack, $func.":".$line ;
  }

  my $offset = '' ;
  foreach my $item (reverse @stack)
  {
    print FDC $offset."- ".$item."\n" ;
    $offset .= " ";
  }

  close FDC ;
}

################################################################################
# create a hash as a reference
################################################################################
sub newHash 
{
  my %h ;
  return \%h ;
}

################################################################################
# send signal HUP
################################################################################
sub sendSigHup
{
  logger();
  foreach my $line (`ps --no-headers -e -o pid,fuid,args`)
  {
    chomp $line ;
    $line =~ /^\s*(\d+)\s+(\d+)\s+(.+)$/;
    my $pid = $1;
    my $uid = $2;
    my $cmd = $3;
    next unless $cmd =~ /bbrmq.pl/ ;
    next unless $cmd =~ /perl/ ;
    next if $pid == $$ ;
    print "$pid\t$uid\t$cmd\n";
    kill 'HUP', $pid ;
  }
}

################################################################################
# signal handler interrupt
################################################################################
sub sigInt()
{
  logger();
  &sigHup() ;
}

################################################################################
# signal handler hang up
################################################################################
sub sigHup()
{
  logger();
  foreach my $qmgr ( keys %$_conn)
  {
    next if $_conn->{$qmgr}{PID} == 0 ;
    my $wr = $_conn->{$qmgr}{WR} ;
    print $wr "end\n" ;
  }
  usleep 100000 ;

  foreach my $qmgr ( keys %$_conn)
  {
    my $wr = $_conn->{$qmgr}{WR} ;
    my $rd = $_conn->{$qmgr}{RD} ;
    close $wr || warn "error closing write pipe to $qmgr" ;
    close $rd || warn "error closing read pipe from $qmgr" ;
    waitpid $_conn->{$qmgr}{PID}, &WNOHANG;
    $_conn->{$qmgr}{PID} = 0;
  }
  exit 0 ;
}

################################################################################
# program usage
################################################################################
sub usage
{
  print "
usage via 
bbmq.pl -ignore [err] -appl {APPL} -qmgr {QMGR} -type {TYPE} -obj {OBJECT} \
                      -attr {ATTR|all|err} -time {TIME}
  -ignore          set the object to ignore temporary list
  -ignore err      show only non-green objects 
    -appl {APPL}   ignore only objects for application {APPL}
    -qmgr {QMGR}   ignore only object on queue manager {QMGR}
    -type {TYPE}   ignore only objects of type {TYPE}
    -obj  {OBJECT} ignore only objects matching {OBJECT}
    -attr {ATTR}   set only attribute {ATTR} to ignore
    -attr err      set only non-green attributes to ignore
    -attr all      set all attributes to ignore
    -time {TIME}   time to ignore: time can have following formats
          n[dhm]   ignore for next n [d]ays [h]ours [m]minutes
          hh:mm    ignore until time (today)
          MM-DD hh:mm ignore until Date-Time (this year)
          YYYY-MM-DD hh:mm ignore until Date-Time
 
bbmq.pl -enable -appl {APPL|all} -qmgr {QMGR|all} -type {TYPE|all} 
 
bbmq.pl -list
  -list list the configuration
 
If there is only one application, queue manager, object type, object or attribute
than it will be taken automaticly.
 
" ;
  die "\n" ;
}

################################################################################
# cleanup / hause keeping
# 
# remove mail files older thean one month
################################################################################
sub cleanUp
{
  opendir TMP, $TMP ;
  foreach my $file (readdir TMP)
  {
    next unless -f "$TMP/$file" ;
    next if $file =~ /^mqLog\.\w+\.log$/ ;
    my $age = time() - (stat "$TMP/$file")[9] ;
    if( $file =~ /^mail-/ )
    {
      next if $age < $MAIL_MAX_AGE ;
      print "removing $TMP/$file $age\n" ;
      unlink "$TMP/$file" ;
    }
  }
}

################################################################################
# list configuration (>stdout)
################################################################################
sub listCfg 
{
  my $_conn = $_[0]->{connect} ;
  my $_app  = $_[0]->{app} ;

  if( defined $gIgnAppl )
  {
    print "List all queue manager for application:\t$gIgnAppl\n" ;
    unless( defined $gIgnQmgr )
    {
      foreach my $qmgr ( keys %{$_app->{$gIgnAppl}{qmgr}} ) 
      {
        print "\t$qmgr \n" ;
      }
    }
    return ;
  }

  if( defined $gIgnQmgr )
  {
    unless( exists $_conn->{qmgr}{$gIgnQmgr} )
    {
      print "No connection to queue manager:\t$gIgnQmgr\tconfigured\n";
      return ;
    }
    print "List all applications for queue manager:\t$gIgnQmgr\n" ;
    foreach my $app (sort keys %$_app)
    {
      next unless exists $_app->{$app}{qmgr}{$gIgnQmgr} ;
      print "\t$app\n" ;
    }
    return ;
  }

  foreach my $app (sort keys %$_app)
  {
    print "\t$app\n" ;
    foreach my $qmgr (sort keys %{$_app->{$app}{qmgr}})
    {
      print "\t\t$qmgr\n"
    }
  }
}

################################################################################
# set temporary ignore
################################################################################
sub setTmpIgn
{
  my $_app = $_[0]->{app} ;
  my $_stat = $_[1] ;

  # --------------------------------------------------------
  # get the application to ignore
  # --------------------------------------------------------
  unless( defined $gIgnAppl )             # no application on command line
  {                                       #
    while(1)                              #
    {                                     #
      my @appl =  sort keys %$_app;       #
      if( scalar @appl == 1 )             # take the only application found
      {                                   #
        $gIgnAppl = $appl[0] ;            #
        last ;                            #
      }                                   #
      print "APPL:\n" ;                   # list all appliacations available
      foreach my $appl ( @appl )          #
      {                                   #
        print "  $appl\n" ;               #
      }                                   #
      print "> " ;                        #
      $gIgnAppl = <STDIN> ;               #
      chomp $gIgnAppl ;                   #
      last if exists $_app->{$gIgnAppl};  #
    }                                     #
  }                                       #
  unless( exists $_app->{$gIgnAppl} )     # ignore application comes from 
  {                                       #  command line; check if it exists
    die "$gIgnAppl not configured for monitoring\n";
  }                                       #
                                          #
  # --------------------------------------------------------
  # get the queue manager to ignore
  # --------------------------------------------------------
  my $_qmgr = $_app->{$gIgnAppl}{qmgr} ;  #
  unless( defined $gIgnQmgr )             # no queue manager set on command line
  {                                       #
    while(1)                              #
    {                                     #
      my @qmgr = sort keys %$_qmgr;       #
      if( scalar @qmgr == 1 )             # take the queue manager if there is 
      {                                   #  only one configured
        $gIgnQmgr = $qmgr[0];             #
        last;                             #
      }                                   #
      print "QMGR:\n";                    # list all queue manager 
      foreach my $qmgr ( @qmgr )          #
      {                                   #
        print "  $qmgr\n" ;               #
      }                                   #
      print "> ";                         #
      $gIgnQmgr = <STDIN> ;               # choose a queue manager
      chomp $gIgnQmgr ;                   #
      last if exists $_qmgr->{$gIgnQmgr}; # break the loop if one queue manager
    }                                     #  choosen
  }                                       #
  unless( exists $_qmgr->{$gIgnQmgr} )    #
  {                                       #
    die "$gIgnQmgr not configured for monitoring\n";
  }                                       #
                                          #
  # --------------------------------------------------------
  # get the object type to ignore 
  # --------------------------------------------------------
  my $_type = $_qmgr->{$gIgnQmgr}{type};  #
  unless( defined $gIgnType )             # no type set on command line
  {                                       #
    while(1)                              #
    {                                     #
      my @type = sort keys %$_type;       # take the only object type if there 
      if( scalar @type == 1)              #  is only one configured
      {                                   #
        $gIgnType = $type[0];             #
        last;                             #
      }                                   #
      print "TYPE:\n";                    # list all object types
      foreach my $type (@type)            #
      {                                   #
        print "  $type\n";                #
      }                                   #
      print "> ";                         #
      $gIgnType = <STDIN>;                # type in object type
      chomp $gIgnType;                    # 
      last if exists $_type->{$gIgnType}; # break loop if chosen type exitsts
    }                                     #
  }                                       #
  unless( exists $_type->{$gIgnType} )    # break script if type received over
  {                                       # command line doesn't exist
    die "$gIgnType not configured for monitoring\n" ;
  }                                       #
                                          #
  # --------------------------------------------------------
  # get the object to ignore 
  # --------------------------------------------------------
  my $_obj = $_stat->{$gIgnAppl}          #
                     {$gIgnQmgr}          #
                     {$gIgnType};         #
  $gIgnObj = '' unless defined $gIgnObj;  # no object / object parse on 
  unless( exists $_obj->{$gIgnObj} )      #  command line
  {                                       #
    my @obj = sort keys %$_obj;           # 
    if( defined $gIgnShow )               # list only non-green objects
    {                                     #
      my @subObj ;
      foreach my $obj (@obj)
      {
        next unless ref $_obj->{$obj} eq 'ARRAY' ;
        foreach my $_instance (@{$_obj->{$obj}} )
        {
          next unless exists $_instance->{attr} ;
          foreach my $attr ( keys %{$_instance->{attr}} )
          {
            next unless exists $_instance->{attr}{$attr}{level} ;
            if( defined $gIgnAttr && $gIgnAttr ne $attr ) 
            {
              next ;
            } 
            next if $_instance->{attr}{$attr}{level} < $WAR ;
            next if $_instance->{attr}{$attr}{level} > $ERR ;
            next if $_instance->{attr}{$attr}{level} < $gIgnShow ;
            push @subObj, $obj;
          }
        }
      }
      @obj = @subObj ;
    }                                     #
                                          #
    while(1)                              # check if object name from command
    {                                     #  line or from stdin can be found as
      my @subObj=grep{$_=~/$gIgnObj/}@obj;#  a part of the existing one
      if( scalar @subObj == 0 )           # object not found
      {                                   #
        die "no such object, (grep $gIgnObj) exit...\n " ;
      }                                   #
      if( scalar @subObj == 1 )           # there is only one object that fits 
      {                                   # parsing -> take it
        $gIgnObj = $subObj[0];            #
        last;                             #
      }                                   #
      @obj = @subObj;                     #
                                          #
      print "OBJECT:\n";                  # print all (remaining) objects
      foreach my $obj (@obj)              #
      {                                   #
        print "  $obj\n";                 #
      }                                   #
      print "> ";                         #
      $gIgnObj = <STDIN>;                 # get the new object name (part) 
      chomp $gIgnObj;                     #  from stding
    }                                     #
  }                                       #
                                          #
  # --------------------------------------------------------
  # get the attribute(s) to ignore
  # --------------------------------------------------------
  my $_attr = @{$_obj->{$gIgnObj}}[0]->{attr}; 
  my @attr;                              #
  unless( defined $gIgnAttr )            # no mq object attribute on 
  {                                      #  command line -> get one from stdin
    print "ATTR:\n";                     #
    foreach my $attr (sort keys %$_attr) #
    {                                    #
      next unless exists $_attr->{$attr}{monitor};
      print "  $attr\n";                 #
    }                                    #
    print "> ";                          #
    my @buff = split " ", <STDIN> ;      #
    foreach my $attr (@buff)
    {
      next unless exists $_attr->{$attr} ;
      next unless exists $_attr->{$attr}{monitor} ;
      push @attr, $attr ;
    }
  }                                      #
  elsif( $gIgnAttr eq 'all' )            # ignore all monitored attributes 
  {                                      #
    @attr=grep{exists $_attr->{$_}{level}} keys %{$_attr};
  }                                      #
  elsif( $gIgnAttr eq 'err' )            # ignore only error attributes
  {                                      #
    @attr = grep {exists $_attr->{$_}{level} && 
                  $_attr->{$_}{level}==$ERR} keys %$_attr ;
  }                                      #
  elsif( $gIgnAttr eq 'war' )            # ignore only warning attributes
  {                                      #
    @attr=grep{exists $_attr->{$_}{level} && 
               $_attr->{$_}{level}==$WAR} keys %$_attr ;
  }                                      #
  else                                   # one mq object attribute 
  {                                      #  passed on command line
    unless( exists $_attr->{$gIgnAttr}   || 
            ( exists $_type->{$gIgnType} &&
              exists $_type->{$gIgnType}{combine} &&
              exists $_type->{$gIgnType}{combine}{$gIgnAttr} 
            )
          )
    {                                    # mq object attribute invalid -> break
      die "$gIgnAttr does not exists\n"; #
    }                                    #
    push @attr, $gIgnAttr ;              #
  }                                      #
                                         #
  # --------------------------------------------------------
  # get ignoring time 
  # --------------------------------------------------------
  unless( defined $gIgnTime )            # no ignore time passed over 
  {                                      #   command line
    print "time to disable:\n> ";        # read it from stdin
    $gIgnTime = <STDIN>;                 #
    chomp $gIgnTime ;                    #
  }                                      #
                                         #
  my $epochIgnTime;                      #
  # -------------------------------------- 
  # time in form min / hour / day offset
  # -------------------------------------- 
  if($gIgnTime=~/^\s*(\d+)([m|h|d])\s*$/)#
  {                                      #
    my $offset = $1;                     #
    my $unit   = $2;                     #
    $offset *= 60    if $unit eq 'm';    #
    $offset *= 3600  if $unit eq 'h';    #
    $offset *= 86400 if $unit eq 'd';    #
                                         # 
    $epochIgnTime = time() + $offset;    #
  }                                      #
  # -------------------------------------- 
  # time in form until yyyy-mm-dd hh:mm or in form mm-dd hh:mm or in form hh:mm
  # -------------------------------------- 
  elsif($gIgnTime=~/^\s*(                # open date 
                         ((20\d{2})-)?   # year 20?? -> can occure 
                         (\d{2})-        # month
                         (\d{2})\s+      # day
                        )?               # close date -> can occure
                        (\d{2}):         # hour
                        (\d{2})/x )      # minute
  {                                      #
    my $timeForm = 'time';               # only time defined 
       $timeForm = 'date' if defined $1; # date and time defined
                                         #
    my $YYY;                             #
    my $MM ;                             #
    my $DD ;                             #
    if( $timeForm eq 'date' )            # date & time defined
    {                                    #
      if( defined $3 )                   # date with year
      {                                  #
        $YYY = $3 - 1900;                #
      }                                  #
      else                               # date without a year (current year)
      {                                  #
        $YYY=(localtime(time()))[5];     # get the current year
      }                                  #
      $MM  = $4 -1;                      #
      $DD  = $5   ;                      #
    }                                    #
    my $hh = $6;                         #
    my $mm = $7;                         #
                                         #
    $YYY=~/^\d{3}$/||die "invalid year\n";
    $MM=~/^\d{2}$/||die "invalid month\n";
    $DD=~/^\d{2}$/||die "invalid day\n"; #
    $hh=~/^\d{2}$/||die "invalid hour\n";#
    $mm=~/^\d{2}$/||die "invalid minute\n";
    $MM < 12 || die "invalid month\n";   # check if date has expected format
    $DD < 32 || die "invalid day\n";     #
    $hh < 62 || die "invalid hour\n";    #
    $mm < 62 || die "invalid minute\n";  #
    $epochIgnTime = timelocal( 0, $mm,   #
                              $hh,$DD,   #
                              $MM,$YYY); #
    if( $epochIgnTime < time() )         #
    {                                    #
      die "time in the past\n"           #
    }                                    #
  }                                      #
  elsif( lc( $gIgnTime ) eq 'ug' )       #
  {                                      #
    $epochIgnTime =0 ;                   #
  }                                      #
                                         #
  my $tty = `tty`; chomp $tty ;          #
  my $whoIs = `who is $tty`;             #
  foreach my $attr (@attr)               #
  {                                      # setup a temporary file name
    my $file = $TMP."/$gIgnAppl-$gIgnQmgr-$gIgnType-$attr-$gIgnObj"; 
    open FD, ">$file";                   #
    print FD $whoIs ;                    #
    close FD;                            #
    utime time(), $epochIgnTime, $file;  # set the time stamp in the future
  }                                      #
}

################################################################################
# set temporary enable
################################################################################
sub setTmpEnable
{
  my $_app = $_[0]->{app} ;
  my $_stat = $_[1] ;

  my $file = $TMP ;

  if( $gEnbAppl eq 'all' )                  # enable all application
  {                                         #
    $gEnbQmgr = 'all' ;                     #
  }                                         #
  else                                      # enable only one application
  {                                         #
    unless( exists $_app->{$gEnbAppl} )     # handle non-existing application
    {                                       #
      print "$gEnbAppl doesn't exists\n" ;  #
      print "  use one of: \n";             #
      foreach my $app ( sort keys %$_app )  #
      {                                     #
        print "    $app\n";                 #
      }                                     #
      die ;                                 #
    }                                       #
  }                                         #
                                            #
  if( $gEnbQmgr eq 'all' )                  # enable all queue manager for 
  {                                         #  application $gEnbAppl
    $gEnbType = 'all' ;                     #
  }                                         #
  else                                      # enable only one qmgr
  {                                         #
    unless( exists $_stat->{$gEnbAppl}{$gEnbQmgr} )
    {                                       # handle non-existing qmgr
      print "$gEnbQmgr doesn't exists\n" ;  #
      print "  use one of: \n";             #
      foreach my $qmgr ( sort keys %{$_stat->{$gEnbAppl}} ) 
      {                                     #
        print "    $qmgr\n";                #
      }                                     #
      die ;                                 #
    }                                       #
  }                                         #
                                            #
  if( $gEnbType eq 'all' )                  #
  {                                         #
  }                                         #
  else                                      #
  {                                         #
    unless( exists $_stat->{$gEnbAppl}{$gEnbQmgr}{$gEnbType} )
    {                                       #
      print "$gEnbType doesn't exists\n" ;  #
      print "  use one of: \n";             #
      foreach my $type ( sort keys %{$_stat->{$gEnbAppl}{$gEnbQmgr}} )
      {                                     #
        print "    $type \n" ;              #
      }                                     #
      die ;                                 #
    }                                       #
  }                                         #
                                            #
  $file .= '/enable-'.$gEnbAppl.'-'.$gEnbQmgr.'-'.$gEnbType ; 
                                            # 
  print "
Enabling monitoring for: 
  Application\t$gEnbAppl
  Queue Manager\t$gEnbQmgr
  Object Type\t$gEnbType

  for next $gEnbTime seconds

  is this ok [Y/N] : ";                     #
                                            #
  my $anwser = <STDIN> ; chomp $anwser ;    #
  die unless uc($anwser) eq 'Y' ;           #
                                            #
  print $file ;                             #
                                            #
  open FD, ">$file" ;                       #
  close FD;                                 #
  utime time(), time() + $gEnbTime, $file;  # set the time stamp in the future
}

################################################################################
# set temporary enable
################################################################################
sub setTmpDisable
{
  my $file = $TMP.'/disable-'.$gDsbQmgr  ;
  open FD, ">$file" ;                      #
  close FD;                                #
  $gDsbTime = 130100 if $gDsbTime > 130100 ;
  utime time(), time() + $gDsbTime, $file; # set the time stamp in the future
}

################################################################################
# get temporary ignore 
################################################################################
sub getTmpIgn
{
  my $_ign ;

# logger();

  opendir TMP, $TMP ;

  foreach my $file (readdir TMP)
  {
    next unless $file =~ /^([\w\.]+)-    # application
                           (\w+)-    # queue manager
                           (\w+)-    # type
                           (\w+)-    # attribute 
                           (.+)$/x;  # object

    my $appl = $1 ;
    my $qmgr = $2 ;
    my $type = $3 ;
    my $attr = $4 ;
    my $obj  = $5 ;
    my $time = (stat $TMP.'/'.$file)[9] ;

    if( time() > $time && $time > 10 ) 
    {
      unlink $TMP.'/'.$file ;
      next ;
    }
    $_ign->{$appl}{$qmgr}{$type}{$obj}{$attr} = $time ;
  }

  closedir TMP ;

  return $_ign ;
}

################################################################################
# get temporary enable
################################################################################
sub getTmpEnb
{
  my $_enb ;

# logger() ;

  opendir TMP, $TMP ;
  
  foreach my $file (readdir TMP)
  {
    next unless $file =~ /^enable-
                           (\w+)-    # application
                           (\w+)-    # queue manager
                           (\w+)$/x; # type
    my $appl = $1 ;
    my $qmgr = $2 ;
    my $type = $3 ;
    my $time = (stat $TMP.'/'.$file)[9] ;

    if( time() > $time )
    {
      unlink $TMP.'/'.$file ;
      next ;
    }
    $_enb->{$appl}{$qmgr}{$type} = $time ;
  }

  closedir TMP ;

  return $_enb ;
}

################################################################################
# get temporary disable 
#
# rc:
#   0 -> enabled 
#   1 -> disabled
################################################################################
sub getTmpDsb
{
  my $qmgr = $_[0] ;
  my $file = $TMP.'/disable-'.$qmgr ;

  return 0 unless -f $file ;
  
  my $fileTime = (stat $file)[9] ;
  return 1 if $fileTime < time() ;

  unlink $file ;
  return 0 ;
}

################################################################################
# merge ignore & enable hash
################################################################################
sub mergeIgnEnb
{
  my $_ign = $_[0] ;
  my $_enb = $_[1] ;

  if( exists $_enb->{all} )
  {
    foreach my $app ( keys %$_ign )
    {
      delete $_ign->{$app} ;
    }  
    return ;
  }

  foreach my $app (keys %$_enb)
  {
    if( exists $_enb->{$app}{all} )
    {
      delete $_ign->{$app} if exists $_ign->{$app} ;
      return ;
    }
    foreach my $qmgr ( keys %{$_enb->{$app}} )
    {
      if( exists $_enb->{$app}{$qmgr}{all} )
      {
        delete $_ign->{$app}{$qmgr} ;
        return ;
      }
      foreach my $type ( keys %{$_enb->{$app}{$qmgr}} )
      {
        delete $_ign->{$app}{$qmgr}{$type} ;
      }
    }
  }
}

################################################################################
# print hash 
#   (for dbg only)
################################################################################
sub printHash
{
  my $_h     = $_[0] ;
  my $offset = $_[1] ;
     $offset = 0 unless defined $offset ;
  my $level  = $_[2] ;
     $level  = 99 unless defined $level ;

  return if $level == 0 ;

  unless( defined $_h )
  {
    print "undef\n" ;
    return ;
  }
  if( ref $_h eq '' )
  {
    print ">$_h<\n" ;
    return ;
  }

  my $tab = '' ;
  for( my $i=0;$i<$offset;$i++) { $tab .= "  "; }

  print "-----------------------------------------------------\n" if $tab eq '';
  foreach my $key (sort keys %$_h )
  {
    if( ref $_h->{$key} eq 'ARRAY' )
    {
      print "$tab$key => qw< \n" ;
      foreach my $val (@{$_h->{$key}}) 
      { 
        if( ref $val eq 'SCALAR' )
        {
          print "$val\n"; 
          next ;
        }
        if( ref $val eq 'HASH' )
        {
          &printHash( $val, $offset+1, $level-1 );
        }

      }
      print "$tab$tab>qw\n" ; 
      next;
    }

    if( ref $_h->{$key} eq 'HASH' )
    {
      print "$tab$key => \n" ;
      &printHash( $_h->{$key}, $offset+1, $level -1 );
      next;
    }

    print "$tab$key => ";
    unless( defined $_h->{$key} )
    {
      print "undef\n" ;
      next ;
    }
    print "$_h->{$key}\n" ;
  }
}

################################################################################
# get config
#  read configuration
################################################################################
sub getCfg
{
  my $cfg = $_[0] ;
  my $cfgFd ;

  my $_cfg = {} ;

  die "can not open $cfg \n" unless open $cfgFd, $cfg ;

  my $i=1;
  my $txt = '';
  foreach my $line (<$cfgFd>)
  {
    chomp $line ;
    next if $line =~ /^\s*#/ ;
    next if $line =~ /^\s*$/ ;
    if( $line =~ /^\s*@(\w+)\s*=\s*(\S+)\s*$/ )
    {
      my $key = $1 ;
      my $val = $2 ;
      if( $key eq 'import' )
      {
# aendern -> 
#    if nur $txt leer mergeHash
#    if nur $_cfg leer nur merge txt
# dafuer ->
#     getCfg return ($_cfg, $txt)
# getCfg wird nur hier und im main() aufgerufen
        my ($_myCfg, $myTxt) = &getCfg($val) ;
        if( $txt=~ /^\s*$/ )
        {
          $_cfg = &mergeHash($_cfg, $_myCfg ) ;
        }
        else
        {
          $txt .= $myTxt;
        }
        next ;
      }
    }
    $txt .= $line ;
  }

  close $cfgFd ;

  return $_cfg if $txt =~ /^\s*$/ ;
  $_cfg = &xml2hash( $txt ) ;
  return ($_cfg,$txt) ;
}

################################################################################
# xml to hash
#  convert configuration xml to hash
################################################################################
sub xml2hash
{
  my $txt = $_[0] ;

  my $_rc ;
  my $item ; 
  my $prop ;
  my $key  ;
  my $val  ;


  return {} if $txt =~ /^\s*$/ ; # Version 2.03.00, allow empty tags
  
  # --------------------------------------------------------
  # key = value
  # --------------------------------------------------------
  if( $txt =~ s/^\s*(\S\w+)\s*=\s*(\S+)\s*// )  # 
  {                                             #
    $key = $1;                                  #
    $val = $2;                                  #
    $_rc->{$key} = $val ;                       #
                                                # return hash
    return $_rc if $txt =~ /^\s*$/ ;            # if no further data available
    $_rc = mergeHash( $_rc, &xml2hash( $txt )); # analyse rest-data 
    return $_rc ;                               #  and return merged hash
  }                                             #
                                                # 
  # --------------------------------------------------------
  # list of strings has to be quoted
  # --------------------------------------------------------
  if( $txt =~ s/^\s*\"(.+?)\"\s*// )
  {
    my @arr ;
    my $word = $1 ;     
    push @arr, $word ; 
    return \@arr if $txt =~ /^\s*$/ ;
    $_rc = &xml2hash( $txt );
    die "mixture of array and hash not allowed" unless ref $_rc eq 'ARRAY';
    push @arr, @$_rc ;
    return \@arr ;
  }

  # --------------------------------------------------------
  # get <item key=value> (open tag)
  # cut off <item key=value>, after this regex txt has form:
  #  sub-xml </item> rest-xml
  # --------------------------------------------------------
  if( $txt =~ s/^\s*\<                          # <
                 \s*(\w+)\s*                    # item  -> group 1
                 ((\w+)                         # key   -> group 3 \
                 \s*=\s*                        # =                | -> group 2
                 (\S+?))?                       # value -> group 4\/ 
                 \s*\>//x )                     #
  {                                             #
    $item = $1 ;                                # item
    $prop = $2 ;                                # prop -> (key=value) 
    $key  = $3 ;                                # 
    $val  = $4 ;                                #
  }                                             #
                                                #
  # --------------------------------------------------------
  # check </item> (close tag)
  # get sub xml  -> <item> sub-xml </item>
  # get rest xml -> <item> sub-xml </item> rest-xml
  # --------------------------------------------------------
  unless( $txt =~ s/^\s*(.*?)\s*                # sub-xml 
                     \<\s*\/$item\s*\>          # <\/item> 
                     (.*)$//x )                 # rest-xml
  {                                             #
    die "error handling <$item> near $txt\n" ;  #
  }                                             #
  my $subXml  = $1 ;                            #
  my $restXml = $2 ;                            #
                                                #
  # --------------------------------------------------------
  # analyze sub xml 
  # --------------------------------------------------------
  unless( defined $key )                        # sub xml with tag $item 
  {                                             # has no proparties
    $_rc->{$item} = &xml2hash( $subXml );       # 
  }                                             #
  else                                          #
  {                                             #
    $key eq 'name' ||                           #
    $key eq 'type' ||                           #
    die "error unknown item attribute $key" ;   #
    $_rc->{$item}{$val}=&xml2hash( $subXml );   #
  }                                             #
                                                #
  return $_rc if $restXml =~ /^\s*$/ ;          #
                                                #
  # --------------------------------------------------------
  # analyze rest xml 
  # --------------------------------------------------------
  $_rc = &mergeHash( $_rc, &xml2hash($restXml));#

  return $_rc ;
}

################################################################################
# expand hash
################################################################################
sub expandHash 
{
  my $_cfg = $_[0] ;

  # --------------------------------------------------------
  # expand missing type
  # --------------------------------------------------------

  # --------------------------------------------------------
  # expand global type to appl type
  # --------------------------------------------------------
  foreach my $type (keys %{$_cfg->{global}{type}})
  {
    foreach my $app (keys %{$_cfg->{app}})
    {
      unless( exists $_cfg->{app}{$app}{type}{$type} )
      {
        $_cfg->{app}{$app}{type}{$type} = $_cfg->{global}{type}{$type} ;
        next;
      }
    
      foreach my $item (keys %{$_cfg->{global}{type}{$type}})
      {
        if( exists $_cfg->{app}{$app}{type}{$type}{$item} )
        {
          if( $item eq 'attr' )
          {
            foreach my $attr (keys %{$_cfg->{global}{type}{$type}{$item}})
            {
              next if exists $_cfg->{app}{$app}{type}{$type}{$item}{$attr} ; 
              $_cfg->{app}{$app}{type}{$type}{$item}{$attr} = 
                $_cfg->{app}{$app}{type}{$type}{$item}{$attr};
            } 
          }
          next;
        }
        $_cfg->{$app}{$app}{type}{$type}{$item} = 
                                         $_cfg->{global}{type}{$type}{$item};
      }
    }
  }

  foreach my $app (keys %{$_cfg->{app}} )
  {
    # ------------------------------------------------------
    # expend application type to qmgr type
    # ------------------------------------------------------
    my $_typeApp = $_cfg->{app}{$app}{type} ;
    foreach my $qmgr (keys %{$_cfg->{app}{$app}{qmgr}} )
    {
      unless( exists $_cfg->{app}{$app}{qmgr}{$qmgr}{type} )
      {
        $_cfg->{app}{$app}{qmgr}{$qmgr}{type} = $_typeApp ;
        next;
      }
      else
      {
        foreach my $type ( keys %$_typeApp )
        {
          unless( exists $_cfg->{app}{$app}{qmgr}{$qmgr}{type}{$type} )
          {
            $_cfg->{app}{$app}{qmgr}{$qmgr}{type}{$type} = $_typeApp->{$type};
          }
          foreach my $item (keys %{$_typeApp->{$type}})
          {
            if( exists $_cfg->{app}{$app}{qmgr}{$qmgr}{type}{$type}{$item} )
            {
              if( $item eq 'attr' )
              {
                foreach my $attr (keys %{$_typeApp->{$type}{$item}} )
                {
                  next if exists $_cfg->{app}{$app}
                                        {qmgr}{$qmgr}
                                        {type}{$type}
                                          {$item}{$attr} ; 
                  $_cfg->{app}{$app}
                         {qmgr}{$qmgr}
                         {type}{$type}
                           {$item}{$attr} = $_typeApp->{$type}{$item}{$attr} ;
                }
              }
              next;
            }
            $_cfg->{app}{$app}
                   {qmgr}{$qmgr}
                   {type}{$type}{$item} = $_typeApp->{$type}{$item} ;
          }
        }
      }
    }
  }
}

################################################################################
# merge hash
#  merge to hashes (references) to a new one (reference)
#
# BUG: Can't use an undefined value as a HASH reference 
#        at ./bbrmq.pl line 1046, <GEN28> line 21559.
#
################################################################################
sub mergeHash
{
  my $_p = $_[0] ;
  my $_q = $_[1] ;

  unless( defined $_p )
  {
    logger();
    logfdc( @_ ) ;
  }

  unless( ref $_p eq 'HASH')
  {
    logger();
    logfdc( @_ ) ;
    print "_p: ";
    print keys %$_p ;
    print "\n" ;
  }

  unless( ref $_q eq 'HASH')
  {
    logger();
    logfdc( @_ ) ;
    print "_q: ";
    print keys %$_q ;
    print "\n" ;
  }

  my $_r = {} ; 
  $_r = {%$_p,%$_q};
  foreach my $key (keys %$_p)
  {
    next unless ref $_q->{$key} eq 'HASH' ;
    $_r->{$key} = &mergeHash($_p->{$key}, $_q->{$key}) if exists $_q->{$key} ;
  }

  return $_r ;
}

################################################################################
# chack the configuration on logical errors
################################################################################
sub checkCfg
{
  my $_cfg = $_[0] ; shift @_ ;
  my @gen  =  @_ ;

  if( ref $_cfg eq 'HASH' )
  {
    foreach my $key (keys %$_cfg)
    {
      unshift @gen, $key ;
      &checkCfg( $_cfg->{$key}, @gen );
    }
  }
  elsif( ref $_cfg eq 'ARRAY' )
  {
    
  } 
  else
  {
    if( $gen[1] eq 'mail' )
    {
      if( $gen[0] eq 'address' ||
          $gen[0] eq 'cc'      ||
          $gen[0] eq 'bcc'     )
      {
        my @email = split ",", $_cfg ;
        foreach my $email ( @email )
        {
          die "unvalid email $email" unless $email =~ /^\w[\w,\.-]+@[\w-]+\.\w+$/ ;
        }
      }
    }
  }
  
}

################################################################################
# connenct to all queue manager
################################################################################
sub connQmgr
{
  my $_cfg  = $_[0]->{app} ;
  my $_conn = $_[1] ;
  my $_alias = $_[2] ;

  logger() ;

  foreach my $app (keys %$_cfg)
  {
    warn "tag app->$app->qmgr not found\n" unless exists $_cfg->{$app}{qmgr};

    # ------------------------------------------------------
    # convert RegEx qmgr to an existing qmgr alias name
    # ------------------------------------------------------
    foreach my $qmgr (keys %{$_cfg->{$app}{qmgr}})  # 
    {                                               # 
#     next if getTmpDsb $qmgr  ;
      next if exists $_conn->{$qmgr};               # RegEx is not in conn Hash
      foreach my $alias ( @$_alias )                # check for every existing
      {                                             #  alias it fits RegEx
        next if exists $_cfg->{$app}{qmgr}{$alias}; #
        next unless $alias =~ /$qmgr/;              # didn't fit
        $_cfg->{$app}{qmgr}{$alias} = \%{$_cfg->{$app}{qmgr}{$qmgr}};
      }                                             #
      delete $_cfg->{$app}{qmgr}{$qmgr} ;           #
    }                                               #
                                                    #
    foreach my $qmgr (keys %{$_cfg->{$app}{qmgr}})  #
    {                                               #
#     next if getTmpDsb $qmgr  ;
      die "$qmgr not configured for connect\n" unless exists $_conn->{$qmgr} ;
      next unless $_conn->{$qmgr}{PID} == 0 ;       #
      if( exists $_conn->{$qmgr}{MQSERVER} )        #
      {                                             #
        $ENV{MQSERVER}=$_conn->{$qmgr}{MQSERVER} ;  #
      }                                             #
                                                    #
      unless( exists $_conn->{$qmgr}{RETRY} )       # set the connect counter
      {                                             #
        $_conn->{$qmgr}{RETRY} = 0;                 #
      }                                             #
                                                    #
      my $pid = 0 ;                                 #
      if( $_conn->{$qmgr}{RETRY} == 0 )             #
      {                                             #
        $pid = open2 $_conn->{$qmgr}{RD} ,          # try to connect
                     $_conn->{$qmgr}{WR} ,          #
                     $_conn->{$qmgr}{RUN};          #
        usleep 100000 ;                             #
        $_conn->{$qmgr}{RETRY} = 0 ;                #
      }                                             #
      if( $_conn->{$qmgr}{RETRY} == 5 )             # reset reconn counter
      {                                             #
        $_conn->{$qmgr}{RETRY} =0;                  #
        next;                                       #
      }                                             #
                                                    #
      if( $pid == waitpid $pid, &WNOHANG )          # check if runmqsc is still
      {                                             # -> runmqsc stopped
        my $exitCode = $? >> 8 ;                    # get exit code from runmqsc
        $_conn->{$qmgr}{PID} = 0;                   #
        $_conn->{$qmgr}{RETRY}++ ;                  #
        close $_conn->{$qmgr}{RD};                  # close read and write file
        close $_conn->{$qmgr}{WR};                  #  handle for runmqsc 
                                                    # queue manager alias was
        if( $exitCode == 20 )                       #  deleted (not by 
        {                                           #  monitoring)
          warn "queue manager alias $qmgr doesn't exist any more\n";
          warn "removing $qmgr from monitoring hash\n";
          kill 'KILL', $pid ;                       #
          waitpid $pid, &WNOHANG ;                  #
          delete $_conn->{$qmgr};                   # remove qmgr from $_conn 
          foreach my $app ( keys %$_cfg )           #  hash
          {                                         #
            next unless exists $_cfg->{$app}{qmgr}; # remove qmgr from all 
            if( exists $_cfg->{$app}{qmgr}{$qmgr} ) #  application hashes
            {                                       #
              delete $_cfg->{$app}{qmgr}{$qmgr} ;   #
            }                                       #
          }                                         #
        }                                           #
        next ;                                      #
      }                                             #
                                                    #
      $_conn->{$qmgr}{PID} = $pid;                  #
      if( $pid == 0 )                               #
      {                                             #
        $_conn->{$qmgr}{RETRY}++ ;                  #
        next ;                                      #
      }                                             #
      my $rd = $_conn->{$qmgr}{RD} ;                #
      my $wr = $_conn->{$qmgr}{WR} ;                #
      my $platform = &getPlatform($_conn->{$qmgr}); #
      unless( defined $platform )                   #
      {                                             #
        warn "no connection to $qmgr \n" ;          #
        close $rd;                                  #
        close $wr;                                  #
        waitpid $pid, &WNOHANG ;                    #
        $_conn->{$qmgr}{PID} = 0;                   #
        $_conn->{$qmgr}{RETRY}++ ;                  #
        usleep 100000 ;                             #
      }                                             #
      $_conn->{$qmgr}{OS} = $platform;              #
    }
  }
}

################################################################################
# get platform
#  get queue manager platform
################################################################################
sub getPlatform
{
  my $_conn = $_[0] ;

  my $rd = $_conn->{RD} ;
  my $wr = $_conn->{WR} ;
  my $platform ;

  print $wr "display qmgr platform\n" ;

  while(my $line=<$rd>)
  {
    last if $line =~ /^\s*$/;
  }
  while(my $line=<$rd>)
  {
    chomp $line ;
    if( $line =~ /^\s*(AMQ\d{4})\w?:\s+/ )
    {
      my $amq = $1;
      if( $amq eq 'AMQ8416' )  # MQSC timed out waiting for a response 
      {                        # from the command server.
        print $wr "end\n";
        close $wr ;
        close $rd ;
        waitpid $_conn->{PID}, &WNOHANG;
        $_conn->{PID} = 0;
        return ;
      }
# missing send error
    }
    next unless $line =~ /QMNAME\(\S+\)\s+PLATFORM\((\w+)\)\s*$/ ;
    $platform = $1 ; 
    last ;
  }
  
  if( $platform eq 'MVS' )
  {
    while(my $line=<$rd>)
    {
      chomp $line ;
      last if $line =~ /^CSQ/ ;
    }
  }
  return $platform ;
}

################################################################################
# connfiguration to conn
#   at conn structure to the configuration hash
################################################################################
sub cfg2conn
{
  my $_cfg  = $_[0]->{qmgr} ;
  my $_alias = $_[1] ;

  my $_conn ;

  # --------------------------------------------------------
  # transform regex queue manager name to a real one
  # --------------------------------------------------------
  foreach my $qmgr (keys %$_cfg)
  {
    next if $qmgr =~ /^[\w\.]+$/ ;
    if( $_cfg->{$qmgr}{type} eq 'proxy' )
    {
      foreach my $myQmgr (@$_alias)
      {
        next unless $myQmgr =~ /$qmgr/ ;
        next if exists $_cfg->{$myQmgr} ;
        $_cfg->{$myQmgr}{type}  = $_cfg->{$qmgr}{type} ;
        $_cfg->{$myQmgr}{proxy} = $_cfg->{$qmgr}{proxy} ;
      }
      delete $_cfg->{$qmgr} ;
    }
  }

  foreach my $qmgr (keys %$_cfg)
  {
    unless( exists $_cfg->{$qmgr}{type} )
    {
      warn "connect->$qmgr->type does not exist\n";
      next;
    }
    $_conn->{$qmgr}{PID} = 0 ;
    $_conn->{$qmgr}{WR}  = FileHandle->new() ;
    $_conn->{$qmgr}{RD}  = FileHandle->new() ;
    if( $_cfg->{$qmgr}{type} eq 'mqserver' ) 
    {
      $_conn->{$qmgr}{RUN} = $runmqsc.' -c '.$qmgr ;
      $_conn->{$qmgr}{MQSERVER}  = $_cfg->{$qmgr}{channel}.'/' ;
      $_conn->{$qmgr}{MQSERVER} .= $_cfg->{$qmgr}{trptype}.'/' ;
      $_conn->{$qmgr}{MQSERVER} .= $_cfg->{$qmgr}{conname}     ;
    }
    elsif( $_cfg->{$qmgr}{type} eq 'proxy' ) 
    {
      $_conn->{$qmgr}{RUN} = $runmqsc.' -w 20 -m '.
                                      $_cfg->{$qmgr}{proxy}.
                                      ' '.$qmgr ;
    }
    elsif( $_cfg->{$qmgr}{type} eq 'zos' ) 
    {
      $_conn->{$qmgr}{RUN} = $runmqsc.' -w 20 -x -m '.
                                      $_cfg->{$qmgr}{proxy}.
                                      ' '.$qmgr ;
    }
    elsif( $_cfg->{$qmgr}{type} eq 'direct' ) 
    {
      $_conn->{$qmgr}{RUN} = $runmqsc.' '.$qmgr ;
    }
  }
  return $_conn ;
}

################################################################################
# get object status 
################################################################################
sub getObjState
{
  my $_cfg  = $_[0]->{app} ;
  my $_glb  = $_[0]->{global} ;
  my $_conn = $_[1] ; 
  my $_state = {} ;

  logger();

  # --------------------------------------------------------
  # get status of all objects and all attributes
  # --------------------------------------------------------
  foreach my $app (keys %$_cfg)
  {
    next unless exists $_cfg->{$app}{qmgr} ;
    foreach my $qmgr (keys %{$_cfg->{$app}{qmgr}})
    {
#     next if getTmpDsb $qmgr  ;
      next unless exists $_cfg->{$app}{qmgr}{$qmgr}{type} ;
      my $_type = $_cfg->{$app}{qmgr}{$qmgr}{type} ;
      next unless ref $_type eq 'HASH';

      my $_qmgrConn->{CONNECT} = 'CONNECTED' ;
      if( exists $_type->{CONNECTION} )
      {
        ${$_state->{$app}{$qmgr}{CONNECTION}{$qmgr}}[0] = $_qmgrConn ;
      }
      if( $_conn->{$qmgr}{PID} == 0 )
      {
        $_qmgrConn->{CONNECT} = 'DISCONNECTED' ;
        next ;
      }

      foreach my $type (keys %{$_type})    #
      {                                    #
        next if $type eq 'CONNECTION' ;    #
        next if $type eq 'PING'       ;    #
                                           #
        next unless exists $_type->{$type}{send} ;
        next unless exists $_type->{$type}{parse} ;
        next unless ref $_type->{$type}{parse} eq 'ARRAY';
        foreach my $parse (@{$_type->{$type}{parse}} )
        {
          my $_myState = &execMqsc( $_conn->{$qmgr}{RD}, 
                                    $_conn->{$qmgr}{WR}, 
                                    $_conn->{$qmgr}{OS}, 
                                    $type, 
                                    $parse );

          unless( defined $_myState )
          {
            warn "no object found for:\n\t$app\n\t$qmgr\n\t$type\n\t$parse\n" ;
            my $wr = $_conn->{$qmgr}{WR} ;
            my $rd = $_conn->{$qmgr}{RD} ;
            print $wr "end\n"  ;
            usleep 100000 ;
            close $wr;
            close $rd;
            waitpid $_conn->{$qmgr}{PID}, &WNOHANG;
            $_conn->{$qmgr}{PID} = 0;
            last ;
          }
          unless( exists $_state->{$app}{$qmgr}{$type} )
          {
            $_state->{$app}{$qmgr}{$type} = $_myState ;
            next ;
          }
          $_state->{$app}{$qmgr}{$type}={%{$_state->{$app}{$qmgr}{$type}} , 
                                         %$_myState                      };
        }

        last if $_conn->{$qmgr}{PID} == 0 ;

        if( exists $_type->{$type}{exclude} && 
            ref $_type->{$type}{exclude} eq 'ARRAY'  )
        {
          foreach my $exclude (@{$_type->{$type}{exclude}} )
          {
            foreach my $obj (keys %{$_state->{$app}{$qmgr}{$type}} )
            {
              delete $_state->{$app}{$qmgr}{$type}{$obj} if $obj =~ /$exclude/ ;
            }
          }
        }
        if( exists $_type->{$type}{keep} &&
            ref $_type->{$type}{keep} eq 'ARRAY'  )
        {
          foreach my $obj (keys %{$_state->{$app}{$qmgr}{$type}})
          {
            my $found = 0 ;
            foreach my $keep (@{$_type->{$type}{keep}} )
            {
              if( $obj =~ /$keep/ )
              {
                $found = 1;
                last ;
              }
            } 
            next if $found == 1 ; 
            delete $_state->{$app}{$qmgr}{$type}{$obj} ;
          } 
        # foreach my $keep (@{$_type->{$type}{keep}} )
        # {
        #   foreach my $obj (keys $_state->{$app}{$qmgr}{$type})
        #   {
        #     delete $_state->{$app}{$qmgr}{$type}{$obj} unless $obj=~/$keep/;
        #   }
        # }
        }
      }
      # ----------------------------------------------------
      # handle type PING
      # ----------------------------------------------------
      next unless exists $_type->{PING};
      next unless exists $_type->{PING}{send};


      my $SYSdate =  time()            ;
      my @SYSdate =  localtime $SYSdate;

      my $ss   =  $SYSdate[0] ;
      my $mm   =  $SYSdate[1] ;
      my $hh   =  $SYSdate[2] ;
      my $dd   =  $SYSdate[3] ;
      my $MM   =  $SYSdate[4] + 1 ;
      my $YYYY =  $SYSdate[5] + 1900 ;
      my $wd   =  $SYSdate[6] ;

      my $day = sprintf("%4d-%2d-%2d", $YYYY, $MM, $dd );
      my $time = sprintf("%2d%2d", $hh, $mm)  ;
      $day =~ s/ /0/g;
      $time =~ s/ /0/g;

   #  if( $time > 2000 ||
   #      $time < 630  ||
   #      $wd == 6     ||
   #      $wd == 0      )
   #  {
   #    my $goalInst;
   #    $goalInst->{CHLTYPE} ='ANY' ;
   #    $goalInst->{PING}    = 'OK' ;
   #    $goalInst->{STATUS}  = 'INACTIVE' ;
   #    $goalInst->{STATUS}  = 'No health check during night / weekend' ;
   #    push @{$_state->{$app}{$qmgr}{PING}{'ALL'}},$goalInst; ;
   #  }
   #  else
   #  {
        my $pingChlTimeOut = 0;

        foreach my $type ('SDR', 'SVR')
        {
          next unless $_type->{$type}{send};
          foreach my $obj ( keys %{$_state->{$app}{$qmgr}{$type}} )
          {
            foreach my $srcInst ( @{$_state->{$app}{$qmgr}{$type}{$obj}} )
            {
              my $goalInst ;
              $goalInst->{CHLTYPE} = $type ;
              unless( exists $srcInst->{STATUS} )
              {
                $goalInst->{STATUS} = 'INACTIVE' ;

                if( -f $PCHTMP."/$qmgr-$type-$obj" )
                {
                  $goalInst = &stateFromFile( $qmgr, $type, $obj );
                }
                else
                {
                  ( $goalInst->{PING},
                    $goalInst->{TEXT} ) = pingChl( $_conn->{$qmgr}{RD},
                                                   $_conn->{$qmgr}{WR},
                                                   $_conn->{$qmgr}{OS}, 
                                                   $obj );
                  $pingChlTimeOut++ if $goalInst->{PING} eq 'AMQ8416' ;
                  &stateToFile( $qmgr, $type, $obj, $goalInst ); 
                }
              }
              else
              {
                $goalInst->{STATUS} = $srcInst->{STATUS} ;
                $goalInst->{PING} = 'OK' ;
                $goalInst->{TEXT} = 'channel healt check done by status';
                &stateToFile( $qmgr, $type, $obj, $goalInst ); 
              }
  
              push @{$_state->{$app}{$qmgr}{PING}{$obj}},$goalInst; ;
            }
          }
        }
        if( $pingChlTimeOut > 0 )
        {
          if( $_conn->{$qmgr}{OS} eq 'UNIX' )
          {
            sleep 60;
          # $TIMEOUT+=60; timeout vara removed in V 2.17.02

            my $wr = $_conn->{$qmgr}{WR} ;
            my $rd = $_conn->{$qmgr}{RD} ;
            print $wr "dis qmgr qmname\n" ;
            while( my $line=<$rd> )
            {
              chomp $line;                         #
              next if $line =~ /^\s*$/ ;           #
                                                   #
              if( $line =~ /(AMQ\d{4})\w?:/ )      #
              {                                    #
                my $amq = $1;                      #
                last if $amq eq 'AMQ8145' ;        # Connection broken.
                last if $amq eq 'AMQ8156' ;        # queue manager quiescing
                last if $amq eq 'AMQ8416' ;        # Time Out
                next if $amq eq 'AMQ8408' ;        # Dis qmgr
              }  
              last if $line =~ /^\s*QMNAME\(/ ;
            }
          }
        }
 #    }   
    }
  }
  return $_state ;
}

################################################################################
# shrink attributes
################################################################################
sub shrinkAttr
{
  my $_app = $_[0]->{app};
  my $_glb = $_[0]->{global};
  my $_state = $_[1];

# logger();

  foreach my $app (keys %$_state)
  {
    foreach my $qmgr (keys %{$_state->{$app}})
    {
      foreach my $type (keys %{$_state->{$app}{$qmgr}})
      {
        my $_aAttr;
        if( exists $_app->{$app}{qmgr}{$qmgr}{type}{$type}{attr} )
        {
          $_aAttr =  $_app->{$app}{qmgr}{$qmgr}{type}{$type}{attr} ;
        }

        my $_gAttr;
        if( exists $_glb->{type}{$type}{attr} )
        {
          $_gAttr = $_glb->{type}{$type}{attr} ;
        }

        foreach my $obj (keys %{$_state->{$app}{$qmgr}{$type}})
        {
          foreach my $_objInst (@{$_state->{$app}{$qmgr}{$type}{$obj}})
          {
            foreach my $attr (keys %{$_objInst})
            {
              my $val = $_objInst->{$attr};
              delete $_objInst->{$attr};
              if( exists $_gAttr->{$attr} ||
                  exists $_aAttr->{$attr}  )
              {
                $_objInst->{attr}{$attr}{value} = $val ;
              }
            }
          }
        }
      }
    }
  }
}

################################################################################
# exec mqsc 
################################################################################
sub execMqsc
{
  my $rd = $_[0];
  my $wr = $_[1];
  my $os = $_[2];
  my $type = $_[3];
  my $obj  = $_[4];

  my $_obj ;
  # --------------------------------------------------------
  # QL & DLQ & QLOUT
  # --------------------------------------------------------
  if( $type eq 'QLOCAL'   ||
      $type eq 'INITQ'    ||
      $type eq 'BOQ'      ||
      $type eq 'DLQ'       )
  {
    my $_ql = disQl( $rd, $wr, $obj, $os );
    return $_ql unless defined $_ql;

    my $_qs = disQs( $rd, $wr, $obj, $os );
    return $_ql unless defined $_qs;

     $_obj = &joinQlstat($_ql, $_qs);

     &calcRatio( $_obj, "CURDEPTH", "MAXDEPTH", "CURDERATIO" );

     &setMaxFS( $_obj, 2088960 );  # 2TG
     &calcRatio( $_obj, "CURFSIZE", "CURMAXFS", "CURFSRATIO" );
  }
  # --------------------------------------------------------
  # XMIT
  # --------------------------------------------------------
  elsif( $type eq 'XMITQ' )
  {
    my $_ql = disXq( $rd, $wr, $obj, $os );
    return $_ql unless defined $_ql;

    my $_qs = disQs( $rd, $wr, $obj, $os );
    return $_ql unless defined $_qs;

     $_obj = &joinQlstat($_ql, $_qs);

     &calcRatio( $_obj, "CURDEPTH", "MAXDEPTH", "CURDERATIO" );

     &setMaxFS( $_obj, 2088960 ); # 2TG
     &calcRatio( $_obj, "CURFSIZE", "MAXFSIZE", "CURFSRATIO" );
  }
  # --------------------------------------------------------
  # SDR
  # --------------------------------------------------------
  elsif( $type eq 'SDR'   ||
         $type eq 'SVR'   ||
         $type eq 'RCVR'  ||
         $type eq 'RQSTR' )
  {
    my $myType = $type ;
       $myType =~ s/^mq//g;
    my $_chl = disChl( $rd, $wr, $myType, $obj, $os );
    return $_chl unless defined $_chl ;

    my $_chs = disChs(  $rd, $wr, $myType, $obj, $os );

     $_obj = &joinChStat($_chl, $_chs );
  }
  # --------------------------------------------------------
  # CLIENT
  # --------------------------------------------------------
  elsif( $type eq 'SVRCONN' )
  {
    my $_chl = disChl( $rd, $wr, 'SVRCONN', $obj, $os );
    return $_chl unless defined $_chl ;

    my $_chs = disChs(  $rd, $wr, 'SVRCONN', $obj, $os );

     $_obj = &joinChStat($_chl, $_chs );
  }
  # --------------------------------------------------------
  # QMGR
  # --------------------------------------------------------
  elsif( $type eq 'QMGR' )
  {
    $_obj = disQmStat( $rd, $wr, $os );
  }
  # --------------------------------------------------------
  # LISTENER
  # --------------------------------------------------------
  elsif( $type eq 'LISTENER' )
  {
    my $_lst = disList( $rd, $wr, $obj, $os) ;
    return $_lst unless defined $_lst ;

    my $_lss = disLisStat( $rd, $wr, $obj, $os) ;
    $_obj = &joinLsStat($_lst, $_lss );
  }
  # --------------------------------------------------------
  # SERVICE
  # --------------------------------------------------------
  elsif( $type eq 'SERVICE' )
  {
    my $_srv = disServ( $rd, $wr, $obj, $os) ;
    return $_srv unless defined $_srv ;

    my $_srs = disServStat( $rd, $wr, $obj, $os) ;
    $_obj = &joinLsStat($_srv, $_srs );
  }

  return $_obj ;    # other object types can be added
}

################################################################################
# join qlocal & status
#  this will add qstat attributes to qlocal only for the queues in ql hash
################################################################################
sub joinQlstat
{
  my $_ql = $_[0] ;
  my $_qs = $_[1] ;

  my $_q = {} ;

  foreach my $q (keys %$_ql)
  {
    my $_objRef = mergeHash( @{$_ql->{$q}}[0],
                             @{$_qs->{$q}}[0] );
    push @{$_q->{$q}}, $_objRef ;
  }
 
  return $_q; 
}

################################################################################
# join channel & channel status
################################################################################
sub joinChStat
{
  my $_chl = $_[0] ;
  my $_chs = $_[1] ;

  my $_c = {} ;

  my $_inactive->{STATUS}   = 'INACTIVE' ;
     $_inactive->{LONGRTS}  = 999999999 ;
     $_inactive->{SHORTRTS} = 10 ;

  foreach my $c (keys %$_chl)
  {
    warn "unexpected REF for $c" unless ref $_chl->{$c} eq 'ARRAY' ;
    warn "unexpected struct for $c" unless exists @{$_chl->{$c}}[0]->{CHLTYPE} ;

    $_inactive->{CURSHCNV} = 0  if @{$_chl->{$c}}[0]->{CHLTYPE} eq 'SVRCONN'; 
    unless( exists $_chs->{$c})
    {
      push @{$_chs->{$c}}, $_inactive ;
    }
    foreach my $_instC (@{$_chs->{$c}})
    {
      my $_objRef = mergeHash ( @{$_chl->{$c}}[0],
                                $_instC );
      #                         @{$_chs->{$c}}[0]);
      push @{$_c->{$c}}, $_objRef ;
    }
  }

  return $_c ;
}

################################################################################
# join listener information and status
################################################################################
sub joinLsStat
{
  my $_lst = $_[0] ;
  my $_lss = $_[1] ;

  my $_inactive->{STATUS}   = 'INACTIVE' ;

  my $_l = {};

  foreach my $l (keys %$_lst)
  {
    unless( exists $_lss->{$l} )
    {
      push @{$_lss->{$l}}, $_inactive ;
    }
    my $_objRef = mergeHash( @{$_lst->{$l}}[0],
                             @{$_lss->{$l}}[0] );
    push @{$_l->{$l}}, $_objRef ;
  }
  return $_l;
}

################################################################################
# parse mqsc 
################################################################################
sub parseMqsc 
{
  my $rd = $_[0] ;  # mqsc read pipe 
  my $os = $_[1] ;  # operating system of the queue manager

  my $_obj  ;       # hash ref for return
  my $obj   ;       # object name
  my $_objRef ;     # object array

# logger();

  while( my $line=<$rd> )
  {
    chomp $line;                         #
    next if $line =~ /^\s*$/ ;           #
                                         #
    if( $line =~ /(AMQ\d{4})\w?:/ )      #
    {                                    #
      my $amq = $1;                      #
      if( $amq eq 'AMQ8145' ||           # Connection broken.
          $amq eq 'AMQ8156' ||           # queue manager quiescing
          $amq eq 'AMQ8416'  )           # Time Out
      {                                  #
        return undef ;                   #
      }                                  #
      last         if $amq eq 'AMQ8415'; # Ping Queue Manager command complete.
      die $line    if $amq eq 'AMQ8569'; # Error in filter specification
      if( $amq eq 'AMQ8147')             # WebSphere MQ object %s not found.
      {                                  #
        warn "$line\n" ;                 #
        next;                            #
      }                                  #
      if( $amq eq 'AMQ8409' ||           # Display Queue details.   
          $amq eq 'AMQ8417' ||           # Display Channel Status details.
          $amq eq 'AMQ8450' ||           # Display queue status details.
          $amq eq 'AMQ8414' ||           # Display Channel details.
          $amq eq 'AMQ8420' ||           # Channel Status not found ???
          $amq eq 'AMQ8705' ||           # Display Queue Manager Status Details
          $amq eq 'AMQ8630' ||           # Display listener information details.
          $amq eq 'AMQ8631' ||           # Display listener status details.
          $amq eq 'AMQ8629' ||           # Display service information details.
          $amq eq 'AMQ8632'  )           # Display service status details.
      {                                  #
        $obj = undef;                    #
        next;                            #
      }                                  #
      warn "unknown MQ reason $amq: line";    #
    }                                    #
                                         #
    next if $line =~ /^\s*$/ ;           # ignore empty lines
                                         #
    # ------------------------------------------------------
    # new object found
    # ------------------------------------------------------
    if( $line =~ s/^CSQM4\d{2}I\s+       # object or status type message
                    (.+?)\s+//x    )     # queue manager name or plus
    #   $line =~ /(AMQ\d{4}):/         ) # AMQ message missing for Unix 
    {                                    #
      $obj = undef;                      #
    }                                    #
                                         #
    # ------------------------------------------------------
    # handle non mqsc output
    # ------------------------------------------------------
                                         #
    if( $os eq 'MVS' )                   #
    {                                    #
      next if $line =~ /^CSQN205I\s*/;   # command processor return code
                                         # first line for ZOS
      if( $line =~ /^CSQ.\d{3}\w\s+/ )   # error handling missing
      {                                  # for messages  beside CSQ9022I 
        last if $line =~ /^CSQ9022I\s+/; # NORMAL COMPLETION
        if( $line =~ /CSQM297I\s+/ )     # no items found matching request
        {                                #
          next if $line =~ / NO CHSTATUS /;
          next if $line =~ / NO QSTATUS /;
          warn "$line\n" ;               #
          next ;                         #
        }                                #
        if( $line =~ /CSQ9006E\s+/ )     # 'QLOCAL' parameter uses asterisk (*)
        {                                #
          warn "unexpected MQSC output\n";
          die "$line\n" ;                #
          next ;                         #
        }                                #
        last ;                           #
      }                                  #
    }                                    #
                                         #
    # ------------------------------------------------------
    # handle mqsc output
    # ------------------------------------------------------
    while( $line =~ s/^\s*(\w+)(\((.*?)\)?\))?\s*// )
    {                                    #
      my $key   = $1 ;                   #
      my $value = $3 ;                   #
      unless( defined $obj )             #
      {                                  #
        logfdc( @_ ) unless defined $value ;
        $obj = $value ;                  #
        $_objRef = newHash() ;           #
        push @{$_obj->{$obj}}, $_objRef; #
        next ;                           #
      }                                  #
      $_objRef = ${$_obj->{$obj}}[-1] if exists $_obj->{$obj} ;
      if( defined $value             &&  #
          $value=~/(\w)\s*,\s*(\w+)/  )  #
      {                                  #
        my $val1 = $1;                   #
        my $val2 = $2;                   #
        $_objRef->{$key.'1'} = $val1;    #
        $_objRef->{$key.'2'} = $val2;    #
      }                                  #
      $_objRef->{$key} = $value ;        #
    }                                    #
  }                                      #
  return $_obj ;
}

################################################################################
# display qlocal
################################################################################
sub disQl
{
  my $rd    = $_[0];
  my $wr    = $_[1];
  my $parse = $_[2];
  my $os    = $_[3];

  print $wr "display qlocal($parse) all where ( usage eq normal) \n" ;
  print $wr "ping qmgr\n" if $os eq 'UNIX' ;

  return parseMqsc $rd, $os ;
}

################################################################################
# display xmitq
################################################################################
sub disXq
{
  my $rd    = $_[0];
  my $wr    = $_[1];
  my $parse = $_[2];
  my $os    = $_[3];

  print $wr "display qlocal($parse) all where ( usage eq xmitq) \n" ;
  print $wr "ping qmgr\n" if $os eq 'UNIX' ;

  return parseMqsc $rd, $os ;
}

################################################################################
# display qstatus
################################################################################
sub disQs
{
  my $rd    = $_[0];
  my $wr    = $_[1];
  my $parse = $_[2];
  my $os    = $_[3];

  print $wr "display qstatus($parse) all \n" ;
  print $wr "ping qmgr\n" if $os eq 'UNIX' ;

  return parseMqsc $rd, $os ;
}

################################################################################
# display (list) sender 
################################################################################
sub disChl
{
  my $rd    = $_[0];
  my $wr    = $_[1];
  my $type  = $_[2];
  my $parse = $_[3];
  my $os    = $_[4];

  print $wr "display channel($parse) all where ( chltype eq $type )\n";
  print $wr "ping qmgr\n" if $os eq 'UNIX' ;

  return parseMqsc $rd, $os ;
}

################################################################################
# display chs
################################################################################
sub disChs
{
  my $rd    = $_[0];
  my $wr    = $_[1];
  my $type  = $_[2];
  my $parse = $_[3];
  my $os    = $_[4];


# next time you see next 3 lines->delete them
# my $chl ;
# my $conn ;
# my $_chl ;

  print $wr "display chs($parse) all where ( CHLTYPE eq $type)\n" ;
  print $wr "ping qmgr\n" if $os eq 'UNIX' ;

  return parseMqsc $rd, $os ;
}

################################################################################
# ping channel
################################################################################
sub pingChl
{
  my $rd  = $_[0];
  my $wr  = $_[1];
  my $os  = $_[2];   # UNIX / MVS
  my $chl = $_[3];

  my $pingRc ;
  my $txt    ;

  print $wr "ping channel($chl)\n" ;
  print $wr "ping qmgr \n" if $os eq 'UNIX' ;

  while( my $line=<$rd> )
  {
    chomp $line;                         #
    next if $line =~ /^\s*$/ ;           #
    if( $os eq 'UNIX' )
    {
      next unless $line =~ /^\s*(AMQ\d{4})\w?:(.+)/ ;
      my $mqscRc = $1 ;
      last if $mqscRc eq 'AMQ8415' ;  # ping qmgr
      $pingRc = $mqscRc ;
      $txt = $2;
      last if $mqscRc eq 'AMQ8416' ;  # time out
    }
    elsif( $os eq 'MVS' )
    {
      if( $line =~ /^\s*AMQ8416\w?:/ ) 
      {
        $pingRc = 'AMQ8416';
        $txt = 'MQSC timed out waiting for a response from the command server';
        last ;
      }
      next unless $line =~ /^\s*(CSQ\w{5})\s+(\S+)\s+(\w+)\s+(.+)$/ ;
      my $mqscRc   = $1;
      my $mqscQmgr = $2;
      my $mqscCmd  = $3;
      my $mqscTxt  = $4;
 #    if( $mqscCmd eq 'CSQMPCHL' )
 #    {
        $pingRc = $mqscRc ;
        $txt   .= $mqscRc." ".$mqscTxt."<br>" ; 
 #    }
      last if $mqscCmd eq 'CSQXCRPS' ;
      last if $mqscRc  eq 'CSQ9023E' ;
    }
  }

  $txt =~ s/<br>$// if defined $txt;
  return ($pingRc,$txt) ;
}

################################################################################
# dis qmstatus all
################################################################################
sub disQmStat
{ 
  my $rd = $_[0];
  my $wr = $_[1];
  my $os = $_[2];

  print $wr "display qmstatus all\n" ;
  print $wr "ping qmgr\n" if $os eq 'UNIX' ;

  return parseMqsc $rd, $os ;
}

################################################################################
# dis listener all
################################################################################
sub disList
{
  my $rd    = $_[0] ;
  my $wr    = $_[1] ;
  my $parse = $_[2] ;
  my $os    = $_[3] ;

  print $wr "display listener($parse) all\n" ;
  print $wr "ping qmgr\n" if $os eq 'UNIX' ;

  return parseMqsc $rd, $os ;
} 

################################################################################
# dis lsstatus all
################################################################################
sub disLisStat 
{
  my $rd    = $_[0] ;
  my $wr    = $_[1] ;
  my $parse = $_[2] ;
  my $os    = $_[3] ;

  print $wr "display lsstatus($parse) all\n" ;
  print $wr "ping qmgr\n" if $os eq 'UNIX' ;

  return parseMqsc $rd, $os ;
} 

################################################################################
# dis service all type server
################################################################################
sub disServ
{
  my $rd    = $_[0] ;
  my $wr    = $_[1] ;
  my $parse = $_[2] ;
  my $os    = $_[3] ;

  print $wr "display service($parse) where ( servtype eq server ) all\n" ;
  print $wr "ping qmgr\n" if $os eq 'UNIX' ;

  return parseMqsc $rd, $os ;
} 

################################################################################
# dis lsstatus all
################################################################################
sub disServStat
{
  my $rd    = $_[0] ;
  my $wr    = $_[1] ;
  my $parse = $_[2] ;
  my $os    = $_[3] ;

  print $wr "display svstatus($parse) all\n" ;
  print $wr "ping qmgr\n" if $os eq 'UNIX' ;

  return parseMqsc $rd, $os ;
} 

################################################################################
# get status from file
################################################################################
sub stateFromFile
{
  my $qmgr = $_[0] ;
  my $type = $_[1] ;
  my $obj  = $_[2] ;

  my %rc ;

  my $file = $PCHTMP."/$qmgr-$type-$obj";
 

  open STAT, $file;

  foreach my $line (<STAT>)
  {
    $line =~ /^(\w+)=(.+)$/ ;
    my $key = $1;
    my $val = $2;
    $rc{$key} = $val ; 
  }
  close STAT;

  my $fileAge = (stat $file)[9] ;
  my $sysTime = time();
  if( ( $sysTime - $fileAge ) > 3600 )
  {
    unlink $file ;
  }

  return \%rc ;
}

################################################################################
# state to file
################################################################################
sub stateToFile
{ 
  my $qmgr  = $_[0] ;
  my $type  = $_[1] ;
  my $obj   = $_[2] ;
  my $_hash = $_[3] ;

  my $file = "$PCHTMP/$qmgr-$type-$obj";

  open STAT, ">$file" ;
  foreach my $key (keys %$_hash)
  {
    print STAT "$key=$_hash->{$key}\n";
  }
  close STAT;
  my $sysTime = gettimeofday   ;   # time.\d{5}
     $sysTime =~ /(\d+)\.(\d+)/ ;
  my $a = $1 ;
  my $b = $2 ; 
  $b = 0 unless defined $b ;
  my $fileTime = $a + ($b%3600) + 3600 ;

  utime time(), $fileTime, $file;  # set the time stamp in the future

}

################################################################################
# evaluate state
################################################################################
sub evalStat
{
  my $_app = $_[0]->{app} ;
  my $_glb = $_[0]->{global} ;
  my $_stat = $_[1] ; 
  my $_ign  = $_[2] ;
  my $_enb  = $_[3] ;

# logger();

  foreach my $app (keys %$_stat)                     # go through all
  {                                                  #  applications
    my $_stApp = $_stat->{$app};                     #
    foreach my $qmgr (keys %$_stApp )                # go through all
    {                                                #  queue manager
#     next if getTmpDsb $qmgr  ;
      my $_stQmgr = $_stApp->{$qmgr};                #
      foreach my $type (keys %$_stQmgr )             # go through all
      {                                              #  object types
        my $_stType = $_stQmgr->{$type};             #
        foreach my $obj (keys %$_stType)             # go through all objects
        {                                            #
          foreach my $_stObj (@{$_stType->{$obj}})   #
          {                                          #
            my $_stAttr = $_stObj->{attr};           # 
            my $early = 0;                           #
            my $war = 0;                             #
            my $err = 0;                             #
            my $ign = 0;                             #
            my $tig = 0;                             #
            my $cnt = 0;                             #
                                                     #
            foreach my $attr (keys %$_stAttr )       # go through all attributes
            {                                        #
              my $_mon;                              # monitoring hash
              my $ignRc;                             # set if time - ignored 
              ($_mon,$ignRc)=&getMonHash($_glb->{type}{$type},
                                         $_app->{$app},
                                          $qmgr     ,# get monitoring hash and
                                          $type     ,#  ignore return code for  
                                          $obj      ,#  selected object 
                                          $attr    );#  attribute combination
                                                     #
              next unless defined $_mon;             # no monitoring hash found
                                                     # ->no monitoring for attr
                                                     #
              $ignRc = &enbIgn( $app    ,            #
                                $qmgr   ,            #
                                $type   ,            #
                                $ignRc  ,            #
                                $_enb   );           # dont use ignore field
                                                     #   if monitoring enabled
              if( defined $ignRc )                   #
              {                                      #
                next if $ignRc==$NA ;                #
                if( $ignRc == $IGN )                 #
                {                                    #
                  $_stAttr->{$attr}{ignore} = $IGN;  #
                }                                    #
              }                                      #
              my $levRc;                             # level (ok/war/err)
              $levRc=&evalAttr($_stAttr->{$attr}     #
                                         {value},    #
                               $_mon);               #
              if( $levRc == $FORMAT )                #
              {                                      #
                print "unexpected error for:\n";     #
                print "    app  = $app\n";           #
                print "    qmgr = $qmgr\n";          #
                print "    qmgr = $type\n";          #
                print "    obj  = $obj\n";           #
                print "    attr = $attr\n";          #
              }                                      #
              if( scalar keys %{$_mon} > 0 )         #
              {                                      #
                $_stAttr->{$attr}{monitor} = $_mon ; #
                $_stAttr->{$attr}{level} = $levRc;   #
              }                                      #
              if( exists $_ign->{$app}{$qmgr}{$type} #   full exists fehlt
                                {$obj}{$attr}      ) #
              {                                      #
                if( $_ign->{$app}{$qmgr}{$type}      #
                           {$obj}{$attr}  == 0   &&  #
                    $levRc                == $OK   ) #
                {                                    #
# achtung experiment
                  my $file = "$TMP/$app-$qmgr-$type-$attr-$obj" ;
                  unlink $file ;                     #
                }                                    #
                else                                 #
                {                                    #
                  $_stAttr->{$attr}{ignore} = $TIG ; #
                  $ignRc = $TIG;                     #
                }                                    #
              }                                      #
                                                     #
              $cnt++;                                #
              if( defined $ignRc )                   #
              {                                      #
                if( $ignRc == $TIG )                 #
                {                                    #
                  $tig++;                            #
                  next;                              #
                }                                    #
                if( $ignRc == $IGN )                 #
                {                                    #
                  $ign++;                            #
                  next;                              #
                }                                    #
              }                                      #
              $early++ if $levRc == $EARLY;          #
              $war++   if $levRc == $WAR;            #
              $err++   if $levRc == $ERR;            #
            }                                        #
                                                     #
            if( exists $_glb->{type}{$type} &&       # handle combined attribut
                exists $_glb->{type}{$type}{combine})#
            {                                        #
              my $_cmb=$_glb->{type}{$type}{combine};#
              foreach my $cmb ( keys %$_cmb)         #
              {                                      #
                next unless exists $_cmb->{$cmb}{match};
                $_stObj->{attr}{$cmb}{value} = '' ;  # set empty value
                $_stObj->{attr}{$cmb}{level} = $OK;  # assume level OK
             #  $_stObj->{attr}{$cmb}{monitor} = "combine ";
             #  foreach my $key (keys %{$_cmb->{$cmb}{match}})
             #  {
             #    $_stObj->{attr}{$cmb}{monitor} .= "$key +" ;
             #  }
                my $matchCnt = 0;                    #
                my $combIgn = 0;                     #
                my $ignRc ;
                                                     # go through all attributes
                foreach my $attr (keys %{$_cmb->{$cmb}{match}} )
                {                                    # 
                  if( exists $_stObj->{attr}{$attr}         &&
                      exists $_stObj->{attr}{$attr}{ignore} &&
                      $_stObj->{attr}{$attr}{ignore} == $IGN )
                  {                                  #
                    $combIgn++;                      #
                  }                                  #
                  if( exists $_stObj->{attr}{$attr}{level} &&
                      ( $_stObj->{attr}{$attr}{level} == 
                        lev2id( $_cmb->{$cmb}{match}{$attr}) ) 
                    )                                # push attributes with
                  {                                  #  matching level
                    $_stObj->{attr}{$cmb}{value} .= $attr . '+' ;
                    $matchCnt++;                     # count matching attributes
                  }                                  #
                }                                    #
                $_stObj->{attr}{$cmb}{value} =~ s/\+$//;
                $_stObj->{attr}{$cmb}{ignore} = $IGN if $combIgn > 0 ;
                                                     # 
                if( exists $_ign->{$app}            &&
                    exists $_ign->{$app}{$qmgr}     &&
                    exists $_ign->{$app}{$qmgr}{$type}       &&
                    exists $_ign->{$app}{$qmgr}{$type}{$obj} &&
                    exists $_ign->{$app}{$qmgr}{$type}{$obj}{$cmb} ) 
                {                                    #
                  $_stObj->{attr}{$cmb}{ignore} = $TIG ;
                  $ignRc = $TIG ;                    #
                }                                    #
                                                     #
                if( exists $_stObj->{attr}{$cmb}{ignore} )
                {                                    #
                  $ign++ if $_stObj->{attr}{$cmb}{ignore} == $IGN ;
                  $tig++ if $_stObj->{attr}{$cmb}{ignore} == $TIG ;
                }                                    #
                                                     #
                if( $matchCnt == scalar keys %{$_cmb->{$cmb}{match}} )
                {                                    #
                  my $lev = &lev2id( $_cmb->{$cmb}{result} );
                  $_stObj->{attr}{$cmb}{level}=$lev; #
                  unless( exists $_stObj->{attr}{$cmb}{ignore} )
                  {                                  #
                    $early++ if $lev == $early;      #
                    $war++   if $lev == $WAR;        #
                    $err++   if $lev == $ERR;        #
                  }                                  #
                }                                    #
                if( exists $_stObj->{attr}{$cmb}{level}   &&
                    $_stObj->{attr}{$cmb}{level} == $OK   &&
                    exists $_stObj->{attr}{$cmb}{ignore}  &&
                     $_stObj->{attr}{$cmb}{ignore} == $TIG )
                {
                  my $file = "$TMP/$app-$qmgr-$type-$cmb-$obj" ;
                  if( -f $file )
                  {
                    my $fileAge = (stat $file)[9] ;
                    unlink $file if $fileAge < 10 ;
                  }
                }
              }                                      #
            }                                        #
                                                     #
            $_stObj->{level}=$OK;                    #
            $_stObj->{level}=$OK if $early > 0 ;     # show early as OK
            $_stObj->{level}=$TIG if $tig > 0 ;      #
            $_stObj->{level}=$IGN if $ign > 0 ;      #
            $_stObj->{level}=$WAR if $war > 0 ;      #
            $_stObj->{level}=$ERR if $err > 0 ;      #
          }
        }
      }
    }
  }
}

################################################################################
# evaluate attribute
################################################################################
sub evalAttr
{
  my $_attr = $_[0] ;
  my $_mon  = $_[1] ;

  my $cntOk  = 0 ;
  my $cntEarly = 0 ;
  my $cntWar = 0 ;
  my $cntErr = 0 ;
  my $cntFormat = 0 ;

  my $rcCnt=0;
  foreach my $th (keys %{$_mon})
  {
    next if $th eq 'default' ;
    my $rc = &cmpTH( $_attr, $th ) ;
    if( $rc == 1 ) 
    {
      $rcCnt++;
      if( $_mon->{$th} eq 'ok'    ) { $cntOk++   ; next; }
      if( $_mon->{$th} eq 'early' ) { $cntEarly++; next; }
      if( $_mon->{$th} eq 'war'   ) { $cntWar++  ; next; }
      if( $_mon->{$th} eq 'err'   ) { $cntErr++  ; next; }
      print "unknown level in \"sub evalAttr\"" ; 
    }
    elsif( $rc == -1 )
    {
      warn "unexpected $_attr and _mon"; 
      printHash $_mon ;
      $cntFormat++;
    }
  }

  if( $rcCnt == 0 &&
      exists $_mon->{'default'} )
  {
    my $th = 'default' ;
    if( $_mon->{$th} eq 'ok'    ) { $cntOk++   ; }
    elsif( $_mon->{$th} eq 'early' ) { $cntEarly++; }
    elsif( $_mon->{$th} eq 'war'   ) { $cntWar++  ; }
    elsif( $_mon->{$th} eq 'err'   ) { $cntErr++  ; }
  }
  
  my $rc = $OK ;
  $rc = $WAR    if $cntWar    > 0;
  $rc = $EARLY  if $cntEarly  > 0;
  $rc = $ERR    if $cntErr    > 0;
  $rc = $OK     if $cntOk     > 0;
  $rc = $FORMAT if $cntFormat > 0;

  return $rc ;
}

################################################################################
# level name to level id
################################################################################
sub lev2id
{
  my $lev = $_[0];

  my $id = $NA ;

  while( exists $LEV{$id} )
  {
    return $id if $LEV{$id} eq uc $lev ;
    $id++ ;
  }

  return $LEV{$NA} ;
}

################################################################################
# compare trashhold
#  return 
#    1 if true
#    0 if false
#   -1 if no eval possible
################################################################################
sub cmpTH
{
  my $val = $_[0];  # value to compare
  my $mon  = $_[1];  # 

  $mon =~ /^(.)(.+)/ ; 
  my $op = $1 ;   # operator
  my $th = $2 ;   # trashhold
  
  if( $op eq '<' )
  {
    return -1 unless $val =~ /^\d*$/ ;
    return 1 if $val < $th;
    return 0;
  }
  if( $op eq '>' )
  {
    return -1 if $val =~ /^\s*$/ ;
    unless( $val =~ /^\d*$/ )
    {
      warn "$val not numeric" ;
      return 0 ;
    }
    return 1 if  $val > $th;
    return 0;
  }
  if( $op eq '=' )
  {
    return 1 if  $val eq $th;
    return 0;
  }
  if( $op eq '!' )
  {
    return 1 if  $val ne $th;
    return 0;
  }
}

################################################################################
# set max file size
################################################################################
sub setMaxFS
{
  my $_obj = $_[0] ;
  my $max  = $_[1] ;

  foreach my $obj (keys %$_obj)
  {
    foreach my $_inst (@{$_obj->{$obj}})
    {
      last unless $_inst->{MAXFSIZE}  ;
      next unless $_inst->{MAXFSIZE} eq 'DEFAULT' ;

      $_inst->{MAXFSIZE} = $max ;
    }
  }
}

################################################################################
# calculate ratio
################################################################################
sub calcRatio
{
  my $_obj     = $_[0] ;
  my $numKey   = $_[1] ;   # numerator
  my $denumKey = $_[2] ;   # denumerator
  my $ratioKey = $_[3] ;

  foreach my $obj (keys %$_obj) 
  {
    foreach my $_inst (@{$_obj->{$obj}})
    {
      # if MAXFS doesn't exists due to old version on the first queue
      # then any other queue won't have MAXFS 
      # then quite this function after first queue
      return unless exists $_inst->{$denumKey}; 

      my $num   = $_inst->{$numKey}  ; 
      my $denum = $_inst->{$denumKey}; 
      if( $denum == 0 )
      {
        $_inst->{$ratioKey} = 0;
        next;
      }
      if( $denum == $num )
      {
        $_inst->{$ratioKey} = 100;
        next;
      }
      $_inst->{$ratioKey} = int( $num*100/$denum);
    }
  }
}

################################################################################
#  get monitoring hash
#
#    attr:
#      1. $_cfg->{global}{type}{$type}
#      2. $_cfg->{app}{$app} {qmgr}{$qmgr}{type}{$type}
#      3. $qmgr
#      4. $type
#      5. $obj
#      6. $attr 
#
#   return code:
#      - 'na'     for attr that has not been found
#      - 'show'   for attr that is not monitored
#      - 'ignore' for out of monitoring gime
#      - monitoring hash 
#          monitoring hash has form
#          war = <ddd
#          err = >ddd
################################################################################
sub getMonHash
{
  my $_glb = $_[0]->{attr} ;
  my $_app = $_[1] ;

  my $qmgr = $_[2] ;
  my $type = $_[3] ;
  my $obj  = $_[4] ;
  my $attr = $_[5] ;

  my $rc = $NA ;
  my $_mon    ;
  my $_monOld ;

  my $rcAttrTime = $NA ;

  # --------------------------------------------------------
  # check the global configuration
  #   global configuration can be only set on type level
  #     $_cfg->{global}{type}{$type}
  # global configuration doesn't depend on time
  # --------------------------------------------------------
  if( exists $_glb->{$attr} )
  {
    $rc = $SHW ;
    if( exists $_glb->{$attr}{monitor} )
    {
      $_mon    = $_glb->{$attr}{monitor} ;
      $_monOld = $_mon ;
    }
  }

  # --------------------------------------------------------
  # top level application configuration
  #   level: $_cfg->{app}{$app}{monitor}{time}
  #   top level application configuration can only have ignore time
  #   monitoring trashhold can't be changed on this level
  # --------------------------------------------------------
  if( exists $_app->{monitor}      &&
      exists $_app->{monitor}{time} )
  {
    $rcAttrTime = $OK ;
    if( $OFF==&checkMonTime($_app->{monitor}{time}))
    { 
      $rc = $IGN if defined $_mon ;
      $rcAttrTime = $IGN ;
    }
  }

  # --------------------------------------------------------
  # application / type level configuration
  #   level $_cfg->{app}{$app}{type}
  # --------------------------------------------------------
  if( exists $_app->{type}                      && 
      exists $_app->{type}{$type}               && 
      exists $_app->{type}{$type}{monitor}      && 
      exists $_app->{type}{$type}{monitor}{time} )
  {
    $rcAttrTime = $OK ;
    if( $OFF == &checkMonTime( $_app->{type}{$type}{monitor}{time} ))
    {
      $rc = $IGN if defined $_mon;
      $rcAttrTime = $IGN ;
    }
    elsif( $rc == $IGN &&        # if  $_app->{}{} set on ignore
           defined $_monOld   )  # and $_app->{type{}{}{} set back to monitor, 
    {                            # than trashhold is missing and has to be 
      $_mon =$_monOld ;          # set to the global treshhold (if it exist)
      $rc = $SHW;                #
    }                            # 
  }

  # --------------------------------------------------------
  # application / type / attribute level configuration
  #   level $_cfg->{app}{$app}{type}{$type}{attr}
  # --------------------------------------------------------
  if( exists $_app->{type}                              && 
      exists $_app->{type}{$type}                       && 
      exists $_app->{type}{$type}{attr}                 && 
      exists $_app->{type}{$type}{attr}{$attr}          && 
      exists $_app->{type}{$type}{attr}{$attr}{monitor} )
  {
#
#  FEHLER fehler 
#  ERROR error 
#  BUG bug
#  ..{monitor}{err} kann nicht existieren.
#  es gibt nur ..{monitor}{>100}=err 
#
    if( exists $_app->{type}{$type}{attr}{$attr}{monitor}{time} )
    {
      if(  &checkMonTime( $_app->{type}{$type}
                                 {attr}{$attr}
                                 {monitor}{time} ) == $ON )
      {
        $rcAttrTime = $OK ;
        if(exists $_app->{type}{$type}{attr}{$attr}{monitor}{err}||
           exists $_app->{type}{$type}{attr}{$attr}{monitor}{war}||
           exists $_app->{type}{$type}{attr}{$attr}{monitor}{early}||
           exists $_app->{type}{$type}{attr}{$attr}{monitor}{ok}  )
        {
          $_mon = $_app->{type}{$type}{attr}{$attr}{monitor};
          $_monOld = $_mon ;
        }
        else
        {
          $_mon = $_monOld ;
        }
        $rc = $SHW;
      }
    }
    elsif( $rc ne $IGN )
    {
      $_mon = $_app->{type}{$type}{attr}{$attr}{monitor};
      $_monOld = $_mon ;
      $rc = $SHW unless $rc == $IGN ;
    }
    else
    {
      $rc = $IGN;
      $rcAttrTime = $IGN ;
    }
  }

  # --------------------------------------------------------
  # application / type / attribute / obj level configuration
  #   level $_cfg->{app}{$app}{type}{$type}{obj}{$obj}
  # --------------------------------------------------------
  if( exists $_app->{type}             && 
      exists $_app->{type}{$type}      && 
      exists $_app->{type}{$type}{obj} )
  {
    # ------------------------------------------------------
    # search for object configution (match exact of regex)
    # ------------------------------------------------------
    my $_obj ;                                       #
    if( exists $_app->{type}{$type}                  # check if object name
                      {obj}{$obj} )                  #  matches EXACT config
    {                                                #  entry
      $_obj = $_app->{type}{$type}                   #
                     {obj}{$obj} ;                   #
    }                                                #
    else                                             # check every object 
    {                                                # configuration: 
      foreach my $regex (keys %{$_app->{type}{$type} #  - is it a regex
                                       {obj}}      ) #  - does it match the
      {                                              #    actual object name
        next unless $regex =~ /^\^.+\$$/ ;           # ignore all but regex
        my @found ;                                  # 
        if( $obj =~ /$regex/ )                       # check for a match
        {                                            #
          $_obj =$_app->{type}{$type}                #
                        {obj}{$regex} ;              #
          push @found, $regex ;                      # count matches
        }                                            #
        if( scalar @found > 1 )                      # if more than one match
        {                                            # print an error
          warn  "$obj configured to many times:\n";  #
          foreach my $found (@found)                 #
          {                                          #
            warn "\t- $found\n" ;                    #
          }                                          #
          # die ""                                   # exit the script 
        }                                            #  might be a solution
      }                                              #
    }                                                #

    # ------------------------------------------------------
    # object definition has been found
    # ------------------------------------------------------
    if( defined $_obj       && 
        ref $_obj eq 'HASH'  )
    {                        
      # ----------------------------------------------------
      # object level configuration 
      #   level: $_cfg->{app}{$app}{type}{$type}{obj}{$obj}{monitor}{time}
      #   type level configuration can only have ignore time
      #   monitoring trashhold can't be changed on this level
      # ----------------------------------------------------
      if( exists $_obj->{monitor}  &&                #
          exists $_obj->{monitor}{time} )            #
      {                                              #
        $rcAttrTime = $OK ;                          #
        if( &checkMonTime($_obj->{monitor}{time})    # 
              == $OFF      )                         #
        {                                            #
          $rc = $IGN ;                               #
          $rcAttrTime = $IGN ;                       #
        }                                            #
        elsif( defined $_mon   &&                    #
               $_mon == $IGN   &&                    # if earlier set on ignore 
               defined $_monOld )                    #  and set back to monitor 
        {                                            #  here, than trashhold is 
          $_mon =$_monOld ;                          #  missing and has to be 
          $rc = $SHW;                                #  set to the old treshhold
        }                                            #  (if one exists) 
      }                                              # 
                                                     #
      # ----------------------------------------------------
      # object / attribute level configuration 
      #   level: $_cfg->{app}{$app}{type}{$type}{obj}{$obj}
      #                            {attr}{$attr}{monitor}{time}
      # ----------------------------------------------------
      if( exists $_obj->{attr}          &&           #
          exists $_obj->{attr}{$attr}   &&           # check if attr sub
          exists $_obj->{attr}{$attr}{monitor} )     #  tree exists
      {                                              #
        if( exists $_obj->{attr}{$attr}              # check for time
                          {monitor}{time} )          #  configuration
        {                                            #
          $rcAttrTime = $IGN ;                          #
          if(&checkMonTime($_obj->{attr}             #
                                  {$attr}            #
                                  {monitor}          #
                                  {time}  ) == $ON)  #
          {                                          #
            $rcAttrTime = $OK ;                          #
#
#  FEHLER fehler 
#  ERROR error 
#  BUG bug
#  ..{monitor}{err} kann nicht existieren.
#  es gibt nur ..{monitor}{>100}=err 
#
            if( exists $_obj->{attr}{$attr}          #
                              {monitor}{err}||       #
                exists $_obj->{attr}{$attr}          #
                              {monitor}{war}||       #
                exists $_obj->{attr}{$attr}          #
                              {monitor}{early}||     #
                exists $_obj->{attr}{$attr}          #
                              {monitor}{ok}  )       #
            {                                        #
              $_mon = $_obj->{attr}{$attr}           #
                             {monitor};              #
              $_monOld = $_mon;                      #
            }                                        #
            else                                     #
            {                                        #
              $_mon = $_monOld;                      #
            }                                        #
          }                                          #
          $rc = $SHW;                                #
        }                                            #
        elsif( $rc ne $IGN )                         #
        {                                            #
          $_mon = $_obj->{attr}{$attr}{monitor};     #
          $_monOld = $_mon;                          #
          $rc = $SHW;                                #
        }                                            #
        else                                         #
        {                                            #
          $_mon = $_obj->{attr}{$attr}{monitor};     #
          $rc = $IGN;                                #
        }                                            #
      }                                              #
    }                                                #
  }                                                  #

  # --------------------------------------------------------
  # queue manager level configuration 
  #   level: $_cfg->{app}{$app}{qmgr}{$qmgr}{monitor}{time}
  #   qmgr level configuration can only have ignore time
  #   monitoring trashhold can't be changed on this level
  # --------------------------------------------------------
  if( exists $_app->{qmgr}{$qmgr}{monitor}  &&          
      exists $_app->{qmgr}{$qmgr}{monitor}{time} )     
  {
    $rcAttrTime = $OK ;                         
    if( $OFF == &checkMonTime( $_app->{qmgr}{$qmgr}{monitor}{time} ))
    {
      $rc = $IGN if defined $_mon;
      $rcAttrTime = $IGN ;                         
    }
    elsif( $rc == $IGN &&        # if  $_app->{}{} set on ignore
           defined $_monOld   )  # and $_app->{qmgr{}{}{} set back to monitor, 
    {                            # than trashhold is missing and has to be 
      $_mon =$_monOld ;          # set to the global treshhold (if it exist)
      $rc = $SHW;                #
    }                            # 
  }                              #

  # --------------------------------------------------------
  # type level configuration
  #   level: $_cfg->{app}{$app}{qmgr}{$qmgr}{type}{$type}{monitor}{time}
  #   type level configuration can only have ignore time
  #   monitoring trashhold can't be changed on this level
  # --------------------------------------------------------
  if( exists $_app->{qmgr}{$qmgr}{type}{$type}{monitor}  &&
      exists $_app->{qmgr}{$qmgr}{type}{$type}{monitor}{time} )     
  {
    $rcAttrTime = $OK ;                         
    if( $OFF==&checkMonTime( $_app->{qmgr}{$qmgr}{type}{$type}{monitor}{time} ))
    {
      $rc = $IGN if defined $_mon;
      $rcAttrTime = $IGN ;                         
    }
    elsif( $rc == $IGN &&        # if  $_app->{}{} set on ignore
           defined $_monOld   )  # and $_app->{qmgr{}{}{} set back to monitor, 
    {                            # than trashhold is missing and has to be 
      $_mon =$_monOld ;          # set to the global treshhold (if they exist)
      $rc = $SHW;                #
    }                            # 
  }

  # --------------------------------------------------------
  # typle / attribute level configuration
  #   level: $_cfg->{app}{$app}{qmgr}{$qmgr}{type}{$type}{attr}{$attr}
  #                 {monitor}{time}
  # --------------------------------------------------------
  if( exists $_app->{qmgr}{$qmgr}{type}{$type}{attr}                &&
      exists $_app->{qmgr}{$qmgr}{type}{$type}{attr}{$attr}         &&
      exists $_app->{qmgr}{$qmgr}{type}{$type}{attr}{$attr}{monitor} )
  {
    if( exists $_app->{qmgr}{$qmgr}{type}{$type}{attr}{$attr}{monitor}{time} )
    {
      $rcAttrTime = $IGN ;                         
      if(  &checkMonTime( $_app->{qmgr}{$qmgr}
                                 {type}{$type}
                                 {attr}{$attr}{monitor}{time}) == $ON )
      {  
        $rcAttrTime = $OK ;                         
#
#  FEHLER fehler 
#  ERROR error 
#  BUG bug
#  ..{monitor}{err} kann nicht existieren.
#  es gibt nur ..{monitor}{>100}=err 
#
        if(exists $_app->{qmgr}{$qmgr}{type}{$type}{attr}{$attr}{monitor}{err}||
           exists $_app->{qmgr}{$qmgr}{type}{$type}{attr}{$attr}{monitor}{war}||
           exists $_app->{qmgr}{$qmgr}{type}{$type}{attr}{$attr}{monitor}{early}||
           exists $_app->{qmgr}{$qmgr}{type}{$type}{attr}{$attr}{monitor}{ok}  )
        {
          $_mon = $_app->{qmgr}{$qmgr}{type}{$type}{attr}{$attr}{monitor};
          $_monOld = $_mon ;
        }
        else
        {
          $_mon = $_monOld ;
        }
        $rc = $SHW;
      }
    }
    elsif( $rc ne $IGN )
    {
      $_mon = $_app->{qmgr}{$qmgr}{type}{$type}{attr}{$attr}{monitor};
      $_monOld = $_mon ;
      $rc = $SHW unless $rc == $IGN ;
    }
    else
    {
      $rc = $IGN;
    }
  }

  # --------------------------------------------------------
  # object / attribute level configuration
  #   level: $_cfg->{app}{$app}{qmgr}{$qmgr}{type}{$type}{obj}{$obj}
  #   there are two arts to determinate object:
  #    - match exact object name
  #    - match object name through perl regex
  #   a regex name can identified by ^ as first and $ as last letter
  # --------------------------------------------------------
  if( exists $_app->{qmgr}{$qmgr}{type}{$type}{obj}) # check if there is an 
  {                                                  # object subtree at all
    # ------------------------------------------------------
    # search for object configution (match exact of regex)
    # ------------------------------------------------------
    my $_obj ;                                       #
    if( exists $_app->{qmgr}{$qmgr}                  # check if object name
                      {type}{$type}                  #  matches EXACT config
                      {obj}{$obj} )                  #  entry
    {                                                #
      $_obj = $_app->{qmgr}{$qmgr}                   #
                     {type}{$type}                   #
                     {obj}{$obj} ;                   #
    }                                                #
    else                                             # check every object 
    {                                                # configuration 
      foreach my $regex (keys %{$_app->{qmgr}{$qmgr} # and check if it is a 
                                       {type}{$type} # regex and if it matches 
                                       {obj}}      ) # the actual object 
      {                                              #
        next unless $regex =~ /^\^.+\$$/ ;           # ignore all but regex
        my @found ;                                  # 
        if( $obj =~ /$regex/ )                       # check for match
        {                                            #
          $_obj =$_app->{qmgr}{$qmgr}                #
                        {type}{$type}                #
                        {obj}{$regex} ;              #
          push @found, $regex ;                      # count matches
        }                                            #
        if( scalar @found > 1 )                      # if more than one match
        {                                            # print an error
          warn  "$obj configured to many times:\n";  #
          foreach my $found (@found)                 #
          {                                          #
            warn "\t- $found\n" ;                    #
          }                                          #
          # die ""                                   # exit the script 
        }                                            #  might be a solution
      }                                              #
    }                                                #
                                                     #
    # ------------------------------------------------------
    # object definition has been found
    # ------------------------------------------------------
    if( defined $_obj       && 
        ref $_obj eq 'HASH'  )
    {                        
      # ----------------------------------------------------
      # object level configuration 
      #   level: $_cfg->{app}{$app}{qmgr}{$qmgr}{type}{$type}
      #                 {obj}{$obj}{monitor}{time}
      #   type level configuration can only have ignore time
      #   monitoring trashhold can't be changed on this level
      # ----------------------------------------------------
      if( exists $_obj->{monitor}  &&             #
          exists $_obj->{monitor}{time} )         #
      {                                           #
        $rcAttrTime = $OK ;                       #
        if( &checkMonTime($_obj->{monitor}{time}) # 
              == $OFF      )                      #
        {                                         #
          $rc = $IGN ;                            #
          $rcAttrTime = $IGN ;                    #    
        }                                         #
        elsif( defined $_mon   &&                 #
               $_mon == $IGN   &&                 # if earlier set on ignore 
               defined $_monOld )                 #  and set back to monitor 
        {                                         #  here, than trashhold is 
          $_mon =$_monOld ;                       #  missing and has to be set 
          $rc = $SHW;                             #
        }                                         #  to the old treshhold (if 
      }                                           #  one exists) 
                                                  #
      # ----------------------------------------------------
      # object / attribute level configuration 
      #   level: $_cfg->{app}{$app}{qmgr}{$qmgr}{type}{$type}
      #                 {obj}{$obj}{attr}{$attr}{monitor}{time}
      # ----------------------------------------------------
      if( exists $_obj->{attr}          &&        #
          exists $_obj->{attr}{$attr}   &&        # check if attr sub
          exists $_obj->{attr}{$attr}{monitor} )  #   tree exists
      {                                           #
        my $monSet = 0;                           #
        if( ( scalar keys %{ $_obj->{attr}{$attr}{monitor}}) == 0 )
        {                                         #
          $monSet = 1 ;                           #
          $_mon = $_obj->{attr}{$attr}{monitor} ; #
          $rc = $SHW ;                            #
        }                                         #
        else                                      #
        {                                         #
          foreach my $key ( keys %{$_obj->{attr}{$attr}{monitor}} )
          {                                       #
            next unless ref \$_obj->{attr}{$attr} #
                                    {monitor}{$key} eq 'SCALAR';
            $_mon = $_obj->{attr}{$attr}{monitor};#    
            $_monOld = $_mon;                     #
            $monSet = 1;                          #
            last ;                                #
          }                                       #
        }                                         #
        if( $monSet == 0 )                        #
        {                                         #
          $_mon = $_monOld;                       #
        }                                         #
        if( exists $_obj->{attr}{$attr}           # check for time configuration
                          {monitor}{time} )       #
        {                                         #
          if(&checkMonTime($_obj->{attr}          #
                                  {$attr}         #
                                  {monitor}       #
                                  {time} )==$OFF) #
          {                                       #
            $rc=$IGN;                             #
          }                                       #
        }                                         #
        elsif( $rcAttrTime == $IGN )              #
        {                                         #
          $rc=$IGN;                               #
        }                                         #
        if( $rc ne $IGN )                         #
        {                                         #
          $rc = $SHW;                             #
        }                                         #
      }                                           #
    }
  }
  
  unless( defined $_mon )
  {
    $_mon = $_monOld ;
  }
  else
  {
    $_mon = $_monOld unless ref $_mon eq 'HASH'; 
  }
  return( $_mon,$rc) ;
}

################################################################################
# check monitoring time
#   rc: ON
#       OFF
################################################################################
sub checkMonTime
{
  my $_time = $_[0];

     # -----------------------------------------------------
     # get time & date
     #   localtime :  0 - sec
     #                1 - min
     #                2 - hours
     #                3 - day of month
     #                4 - month of year (0-11)
     #                5 - year since 1900
     #                6 - day of week
     #                7 - day of year
     #                8 - summer (1) / winter (0)
     # -----------------------------------------------------
  my $SYSdate =  time()            ;
  my @SYSdate =  localtime $SYSdate;

  my $ss   =  $SYSdate[0] ;
  my $mm   =  $SYSdate[1] ;
  my $hh   =  $SYSdate[2] ;
  my $dd   =  $SYSdate[3] ;
  my $MM   =  $SYSdate[4] + 1 ;
  my $YYYY =  $SYSdate[5] + 1900 ;
  my $wd   =  $SYSdate[6] ;

  my $time = sprintf("%2d%2d", $hh, $mm)  ;
     $time =~ s/ /0/g;

  foreach my $id ( keys %$_time )
  {
    my $start =  $_time->{$id}{start} if exists $_time->{$id}{start};
    my $stop  =  $_time->{$id}{stop}  if exists $_time->{$id}{stop} ;
       $start =~ s/://g if defined $start;
       $stop  =~ s/://g if defined $stop;
  
    my $DAY = 1 ;
  
    if( exists $_time->{$id}{day} )
    {
      if( $_time->{$id}{day} =~ /^(\d+)-(\d+)$/ )
      {
        my $first = $1;
        my $last  = $2;
        $DAY = 0 if $wd < $first ; 
        $DAY = 0 if $wd > $last ; 
      }
  
      my @day ;
      if( $_time->{$id}{day} =~ /,/ )
      {
        @day = split ",", $_time->{$id}{day} ;
      }
      push @day, $_time->{$id}{day} if $_time->{$id}{day} =~ /^\d$/ ;
      if( scalar @day > 0 )
      {
        my $match = grep { $_ == $wd } @day ;
        $DAY = 0 if( $match == 0 ) ;
      }
    }
  
    next if $DAY == 0 ;
  
    if( defined $start &&              # start and stop are defined
        defined $stop   )              #
    {                                  #
      if( $stop < $start )             # do not monitor during an interval
      {                                #
        next       if $time < $stop  ; # monitor from 00:00 until stop time
        next       if $time > $start ; # monitor from start time until 23:59
      # return $ON if $time < $stop  ; # monitor from 00:00 until stop time
      # return $ON if $time > $start ; # monitor from start time until 23:59
        return $OFF ;                  # don't monitor during interval
      }                                #
      next if( $time > $start &&       # monitor during an interval
               $time < $stop  );       #
    # return $ON if( $time > $start && # monitor during an interval
    #                $time < $stop  ); #
      return $OFF;                     # don't monitor outside an interval
    }                                  #
                                       #
    return $OFF if( defined $start &&  # only start defined, don't monitor early
                    $time < $start );  #  in the morning
                                       #
    return $OFF if( defined $stop &&   # only stop defined, don't monitor late
                    $time > $stop );   #  in the evening
  }                                    #
  return $ON ;                         # 
 
}

################################################################################
#  enabel ignore
#   correct ignore flag depending on enable flag
#     $NA   = -2;
#     $SHW  = -1;
#     $OK   =  0;
#     $IGN  =  1;
#     $TIG  =  2; # temporary ignore
#     $WAR  =  3;
#     $ERR  =  4;
################################################################################
sub enbIgn
{
  my $app  = $_[0] ;
  my $qmgr = $_[1] ;
  my $type = $_[2] ;
  my $ign  = $_[3] ;
  my $_enb = $_[4] ;

  if( $ign == $NA  ||
      $ign == $SHW ||
      $ign == $OK   ) { return $ign ; }

  return $ign unless defined $_enb ;
  return $ign unless ref $_enb eq 'HASH' ;
  return $ign unless scalar $_enb > 0 ;

  return $SHW if exists $_enb->{all}  ;

  if( exists $_enb->{$app} )
  {
    return $SHW if exists $_enb->{$app}{all}  ;

    if( exists $_enb->{$app}{$qmgr} )
    {
      return $SHW if exists $_enb->{$app}{$qmgr}{all} ;
      return $SHW if exists $_enb->{$app}{$qmgr}{$type} ;
    }
  }
 
  return $ign ;
}

################################################################################
# tree to format
#  convert tree to perl format statemant
################################################################################
sub tree2format
{
  my $_type = $_[0]->{global}{type} ;
  my $_format ;

  foreach my $type (keys %$_type)
  {
    my $headerPrefix = $levelFormat ;
       $headerPrefix =~ s/./-/g;
    $_format->{$type}{format} = $levelFormat.$_type->{$type}{format} ;
    $_format->{$type}{top}    = $headerPrefix.$_type->{$type}{format} ;
    push @{$_format->{$type}{header}}, $type ;
    foreach my $attr (sort keys %{$_type->{$type}{attr}} )
    {
      $_format->{$type}{format} .= $levelFormat.
                                     $_type->{$type}{attr}{$attr}{format} ;
      $_format->{$type}{top}    .= $headerPrefix.
                                     $_type->{$type}{attr}{$attr}{format} ;
      push @{$_format->{$type}{header}}, $attr ;
    }
    $_format->{$type}{format} .= "\n" ;
    $_format->{$type}{top}    .= "\n" ;
  } 
  return $_format;
}

################################################################################
#  print message
################################################################################
sub printMsg 
{
  my $_stat = $_[0];
  my $_app  = $_[1]->{app} ;
  my $_glb  = $_[1]->{global} ;
  my $_format = $_[2] ;

# logger();

  my %xymMsg ;
  my %mailMsg ;
  my %patrolMsg ;

  my %anchor ;

  foreach my $app (keys %$_stat)                          # app level
  {                                                       #
    next unless exists $_app->{$app};                     #
    my $inf = '' ;                                        #
    if( exists $_app->{$app}{information} )               #
    {                                                     #
      $inf = "<table>" ;                                  #
      $inf .= "<tr><td>application</td><td>$app</td></tr>\n"; #
      $inf .= "<tr><td>version</td><td>$VERSION</td></tr>\n"; 
      foreach my $key (sort keys %{$_app->{$app}{information}})  
      {                                                   #
        my $val = $_app->{$app}{information}{$key};       #
        $inf .= "<tr><td>$key</td><td>$val</td></tr>\n";  #
      }                                                   #
      $inf .= "</table>\n";                               #
    }                                                     #
    foreach my $qmgr (sort keys %{$_stat->{$app}} )       # qmgr level
    {                                                     #
#     next if getTmpDsb $qmgr  ;
      next unless exists $_app->{$app}{qmgr}{$qmgr};      #
      foreach my $type (sort keys %{$_stat->{$app}{$qmgr}} ) # type level
      {                                                   #
        next unless exists $_app->{$app}                  # ignore application
                                  {qmgr}{$qmgr}           # whithout send/xymon
                                  {type}{$type}{send};    #  sub-tree
                                                          #
        # -------------------------------------------------
        # build message for xymon 
        # -------------------------------------------------
        if( exists $_app->{$app}{qmgr}{$qmgr}             #
                          {type}{$type}{send}{xymon} )    #
        {                                                 #
          my $host = $_app->{$app}{qmgr}{$qmgr}           #
                                  {type}{$type}           # get host & service
                                  {send}{xymon}{host};    #
          my $srv  = $_app->{$app}{qmgr}{$qmgr}           #
                                  {type}{$type}           #
                                  {send}{xymon}{service}; #
          my $info ;                                      #
          if( exists $_app->{$app}{qmgr}{$qmgr}           #
                                  {type}{$type}           #
                                  {send}{xymon}{info} )   #
          {                                               #
            $info = $_app->{$app}{qmgr}{$qmgr}            #
                                 {type}{$type}            #
                                 {send}{xymon}{info}      #
          }                                               #
          my ($xymMsg,$lev) = &xymonMsg( $app    ,        #
                                         $qmgr   ,        #
                                         $type   ,        #
                                         $_glb   ,        #
                                         $_stat->{$app},  #
                                         $info  )      ;  # 
                                                          #
          $xymMsg="<a name=\"$qmgr-$type\"></a>".$xymMsg; #
          $xymMsg{$host}{$srv}{msg}.= $xymMsg ;           #
          my $anchor = '&green' ;                         #
          $anchor = '&yellow' if $lev == $WAR ;           #
          $anchor = '&red'    if $lev == $ERR ;           #
          $anchor = '&blue'   if $lev == $IGN ;           #
          $anchor .= "<a href=\"#$qmgr-$type\"> $qmgr $type </a>\n" ;
          $xymMsg{$host}{$srv}{anchor} .= $anchor;        #
                                                          #
          unless( exists $xymMsg{$host}{$srv}{level} )    #
          {                                               #
            $xymMsg{$host}{$srv}{level} = $lev;           #
          }                                               #
          else                                            #
          {                                               # 
            if( $lev>$xymMsg{$host}{$srv}{level} )        #
            {                                             #
              $xymMsg{$host}{$srv}{level}=$lev ;          #
            }                                             #
          }                                               #
        }                                                 #
                                                          #
        # -------------------------------------------------
        # build message for e-mail
        # -------------------------------------------------
        if( exists $_app->{$app}{qmgr}{$qmgr}             #
                          {type}{$type}{send}{mail} )     #
        {                                                 #
          my ($mailErr,$mailBody,$mailSub)=&mailMsg($app,
                                                    $qmgr ,
                                                    $type ,        
                                                    $_glb ,       
                                                    $_stat->{$app}); 
          if( $mailErr > 0 )                              #
          {                                               #
            $mailMsg{$qmgr}{$type}{body} = $mailBody;     #
            $mailMsg{$qmgr}{$type}{subject} = $mailSub;   #
            $mailMsg{$qmgr}{$type}{app} = $app ;
       #    $mailMsg{$qmgr}{$type}{address}=$_app->{$app}{qmgr}{$qmgr}
       #                                                 {type}{$type}
       #                                                 {send}{mail}{address};
            $mailMsg{$qmgr}{$type}{appl} = $app ;         #
          }                                               #
        }                                                 #
        # -------------------------------------------------
        # build message for patrol
        # -------------------------------------------------
        if( exists $_app->{$app}{qmgr}{$qmgr}             #
                          {type}{$type}{send}{patrol} )   #
        {                                                 #
          foreach my $obj (keys %{$_stat->{$app}{$qmgr}{$type}})
          {                                               #
            foreach my $_objInst (@{$_stat->{$app}{$qmgr}{$type}{$obj}})
            {                                             #
              next unless exists $_objInst->{level};      #
              foreach my $attr (keys %{$_objInst->{attr}})#
              {                                           #
                next unless exists $_objInst->{attr}{$attr}{level} ;
                my $_attr = $_objInst->{attr}{$attr} ;    #
                if( $_attr->{level} == $NA  ||            # don't handle NA & 
                    $_attr->{level} == $SHW  )            # SHW for patrol
                {                                         #
                  next;                                   #
                }                                         #
                my $ignore = $OK;                         #
                $ignore = $_attr->{ignore} if exists $_attr->{ignore} ;
                $patrolMsg{$app}{$qmgr}                   #
                          {$type}{$obj}                   #
                          {$attr}{class}=$_app->{$app}{qmgr}
                                                {$qmgr}{type}
                                                {$type}{send}
                                                {patrol}{class};
                $patrolMsg{$app}{$qmgr}                   #
                          {$type}{$obj}                   #
                          {$attr}{resend}=$_app->{$app}{qmgr}
                                                {$qmgr}{type}
                                                {$type}{send}
                                                {patrol}{resend};
                if( $_attr->{level} == $OK  ||            # for Patrol 
                    $ignore         == $IGN ||            # OK, IGN and Temp IGN
                    $ignore         == $TIG  )            # is the same
                {                                         #
                  $patrolMsg{$app}{$qmgr}                 #
                            {$type}{$obj}                 #
                            {$attr}{value}=$_attr->{value};
                  $patrolMsg{$app}{$qmgr}                 #
                            {$type}{$obj}                 #
                            {$attr}{level} = $OK ;        #
                  next;                                   #
                }                                         #
                if( $_attr->{level} == $WAR ||            # Alerts to be send:
                    $_attr->{level} == $ERR  )            # ERR, WAR
                {                                         #
                  $patrolMsg{$app}{$qmgr}                 #
                            {$type}{$obj}                 #
                            {$attr}{value}=$_attr->{value};
                  $patrolMsg{$app}{$qmgr}                 #
                            {$type}{$obj}                 #
                            {$attr}{level}=$_attr->{level};
                }                                         #
              }                                           #
            }                                             #
          }                                               #
        }                                                 #
      }                                                   #
      # --- [end] all type of messages build 
    }                                                     #
                                                          #
    foreach my $host (keys %xymMsg)                       #
    {                                                     #
      foreach my $srv (keys %{$xymMsg{$host}})            #
      {                                                   #
        next if exists $xymMsg{$host}{$srv}{inf} ;        #
        $xymMsg{$host}{$srv}{inf} = $inf ;                #
      }                                                   #
    }                                                     #
  }                                                       #
                                                          #
  # -------------------------------------------------------
  # send xymon message 
  # -------------------------------------------------------
  foreach my $host ( keys %xymMsg )                       # send a message
  {                                                       #  to xymon
    foreach my $service ( keys %{$xymMsg{$host}} )        #
    {                                                     #
      my $msg = $xymMsg{$host}{$service}{msg};            #
      my $color = 'green' ;                               #
      $color = 'yellow' if $xymMsg{$host}{$service}{level} == $WAR;
      $color = 'red'    if $xymMsg{$host}{$service}{level} == $ERR;
      $msg = "restart on ".hostname()." as user mqmon\n".
             "~mqmon/monitor/bin/bbrmq.pl -restart\n\n".
             $xymMsg{$host}{$service}{inf}.
             $xymMsg{$host}{$service}{anchor}.$msg ;
      writeMsg $msg, $color, $host, $service ;            #
    }                                                     #
  }                                                       #
                                                          #
  # -------------------------------------------------------
  # send mail message
  # -------------------------------------------------------
  foreach my $qmgr ( keys %mailMsg )
  {
    foreach my $type ( keys %{$mailMsg{$qmgr}} )
    {
      my $app = $mailMsg{$qmgr}{$type}{app};

      &sendMail( $mailMsg{$qmgr}{$type}{body}                  ,
                 $_app->{$app}{qmgr}{$qmgr}{type}{$type}{send} ,
                 $app, $qmgr, $type                           );
    } 
  }
  # -------------------------------------------------------
  # send patrol message
  # -------------------------------------------------------
  foreach my $app ( keys %patrolMsg )
  {
    foreach my $qmgr ( keys %{$patrolMsg{$app}} )
    {
      foreach my $type ( keys %{$patrolMsg{$app}{$qmgr}} )
      {
        foreach my $obj ( keys %{$patrolMsg{$app}{$qmgr}{$type}} )
        {
          foreach my $attr ( keys %{$patrolMsg{$app}{$qmgr}{$type}{$obj}} )
          {
            next unless exists $patrolMsg{$app}{$qmgr}{$type}
                                         {$obj}{$attr}{level};
            &sendPatrol( $app, $qmgr, $type, $obj, $attr,
                         $patrolMsg{$app}{$qmgr}{$type}{$obj}{$attr} );
          }
        }
      }
    }
  }

}

################################################################################
# build a xymon message
################################################################################
sub xymonMsg 
{
  my $appl    = $_[0] ;
  my $qmgr    = $_[1] ;
  my $type    = $_[2] ;
  my $_glb    = $_[3] ;
  my $_stat   = $_[4] ;
  my $info    = $_[5] ;

  logger();

  my $rcLevel = $OK ;

#  my $disableIgnore = getDisableXymIgnore( $appl, $qmgr, $type) ;

  my $msg  = " <div>" ;                                            # table
  $msg.="<table class=\"top\"><tr>" ;                              #   header
  $msg.="<td class=\"top\"><hr></td><td class =\"top\">$qmgr</td>";# qmgr
  $msg.="<td class=\"top\"><hr></td><td class =\"top\">$type</td>";# type
  $msg.="<td class=\"top\"><hr></td></tr></table>\n";              #
                                                                   #
  $msg .= "<table><thead><tr>\n";                                  #
  $msg .= "  <th></th><th align=\"center\" class=\"head\">$type</th>\n";
  if( defined $info && $info eq 'yes' )
  {
    $msg .= "  <th class=\"head\"> </th>\n";   # (i) placeholder
  }
  foreach my $attr ( sort keys %{$_glb->{type}{$type}{attr}} )
  {
    next unless exists $_glb->{type}{$type}{attr}{$attr}{format} ;
    $msg .= "  <th class=\"head\">$attr</th>\n";
  }
  $msg .= "</tr></thead>\n";

  $msg .= "<tbody>\n";
  foreach my $obj ( sort keys %{$_stat->{$qmgr}{$type}} )
  {  
    my $color ;

    foreach my $_objInst (@{$_stat->{$qmgr}{$type}{$obj}})
    {
      $color = "&green"  if $_objInst->{level} eq $OK ;
      $color = "&yellow" if $_objInst->{level} eq $WAR ;
      $color = "&red"    if $_objInst->{level} eq $ERR ;
      $color = "&blue"   if $_objInst->{level} eq $IGN ;
      $color = "&clear"  if $_objInst->{level} eq $TIG ;
      $rcLevel =  $_objInst->{level} if  $_objInst->{level} > $rcLevel;
      $msg .= "<tr>\n";
      my $ignAttr ;
      foreach my $attr ( sort keys %{$_glb->{type}{$type}{attr}} )
      {
        next unless exists $_objInst->{attr}{$attr}{value} ;
        next unless  exists $_objInst->{attr}{$attr}{level} ;
        my $value = $_objInst->{attr}{$attr}{value} ;
        my $level = $_objInst->{attr}{$attr}{level} ;
        
        $ignAttr .= $attr.'('.$value.'/'.$LEV{$level}.'),';
      }

      my $ignLink = $sysUrl.'/ignore.cgi?appl='.$appl.
                                    '&qmgr='.$qmgr.
                                    '&type='.$type.
                                    '&obj='.$obj ;

      if( defined $ignAttr )
      { 
        $ignAttr =~ s/,$//;
        $ignLink .= '&attr='.$ignAttr ;
      }

      $msg .= "<td valign=\"bottom\">$color</td>\n";
      $msg .= "<td valign=\"baseline\">\n";
      $msg .= "  <a id=\"$obj\" onclick=\"javascript:location.href=\'$ignLink&url=\'";
      $msg .= ".concat(location.host).concat(location.pathname).concat('&').concat(location.search.substring(1));\" >$obj</a>\n";
      $msg .= "</td>\n";
 
      if( defined $info && $info eq 'yes' )
      {
        my $infoLink = $sysUrl."/info.cgi?qmgr=$qmgr&type=$type&obj=$obj" ; 
        $msg .= "  <td><a id=\"$obj\" onclick=\"javascript:location.href=\'$infoLink&url=\'";
        $msg .= ".concat(location.host).concat(location.pathname).concat('&').concat(location.search.substring(1));\" >(i)</a></td>\n";
      }
 
      foreach my $attr ( sort keys %{$_glb->{type}{$type}{attr}} )
      {
        next unless exists $_glb->{type}{$type}{attr}{$attr}{format} ;
        unless( exists $_objInst->{attr}{$attr}{value} )
        {
          $_objInst->{attr}{$attr}{value} = '' ;
        }
        my $format ;
        my $value  ;
        my $level  ;
        my $ignore ;
        $format="left"   if $_glb->{type}{$type}{attr}{$attr}{format} =~ /^@</ ;
        $format="right"  if $_glb->{type}{$type}{attr}{$attr}{format} =~ /^@>/ ;
        $format="center" if $_glb->{type}{$type}{attr}{$attr}{format} =~ /^@\|/;
  
      # next unless exists $_objInst->{attr}{$attr}{value} ;
        $value = $_objInst->{attr}{$attr}{value} ;
  
        if( exists $_objInst->{attr}{$attr}{level} )
        {
          $level = $_objInst->{attr}{$attr}{level} ;
        }
        if( exists $_objInst->{attr}{$attr}{ignore} )
        {
          $ignore = $_objInst->{attr}{$attr}{ignore} ;
        }
 
# ANPASSEN
#  welche werte kan $ignore haben, 
#  wenn monitoring ENABLED, ignoriere ignore
#  ignore kann folgende werte besitzen: TIG, IGN, undef
 
        my $color = "na" ;
        my $border = '';
        if( defined $level )
        {
          $color = "ok"  if $level == $OK  ;
          $color = "ok"  if $level == $EARLY ;
          $color = "war" if $level == $WAR ;
          $color = "err" if $level == $ERR ;
        }

        my $colorLevel = $color;
        if( defined $ignore )
        {
          if( $ignore == $IGN )
          {
            $color = "ign" ;
            $border = 'org-'.$colorLevel if defined $level;
          }
          if( $ignore == $TIG )
          {
            $color = "tig" ;
            $border = 'org-'.$colorLevel if defined $level;
          }
        }
        unless( defined $value )
        {
          warn "value not set for $appl / $qmgr / $type / $obj / $attr " ;
        }
        $msg .= "<td class=\"$color $format $border\">$value</td>";
      }
      $msg .= "</tr>\n" ;
    }
  }
  $msg .= "</tbody></table>\n";

  $msg .= "</div>\n";
  return ($msg,$rcLevel) ;
}

################################################################################
# build a mail message
################################################################################
sub mailMsg
{
  my $appl    = $_[0] ;
  my $qmgr    = $_[1] ;
  my $type    = $_[2] ;
  my $_glb    = $_[3] ;
  my $_stat   = $_[4] ;

  logger();
  my $report ;
  my $msg;
  my $globErr = 0 ;
  foreach my $obj ( sort keys %{$_stat->{$qmgr}{$type}} )
  {
    foreach my $_objInst (@{$_stat->{$qmgr}{$type}{$obj}})
    {
      next if $_objInst->{level} == $IGN ;
      next if $_objInst->{level} == $TIG ;
      my $objErr=0; 
      foreach my $attr ( sort keys %{$_glb->{type}{$type}{attr}} )
      {
        next unless exists $_objInst->{attr}{$attr}{level} ;
        if( $_objInst->{attr}{$attr}{level} == $ERR )
        {
          $globErr++;
          $objErr++;
          my $th;
          if( exists $_objInst->{attr}{$attr}{monitor} )
          {
            foreach my $key ( keys %{$_objInst->{attr}{$attr}{monitor}} )
            {
              if( $_objInst->{attr}{$attr}{monitor}{$key} eq 'err' )
              {
                $th = $key ;
                last;
              }
            }
          }

          if( exists $_glb->{type}{$type}{combine}               &&
              exists $_glb->{type}{$type}{combine}{$attr}        &&
              exists $_glb->{type}{$type}{combine}{$attr}{match} &&
              ref    $_glb->{type}{$type}{combine}{$attr}{match} eq 'HASH' )
          {
            foreach my $key (keys %{$_glb->{type}{$type}{combine}{$attr}{match}})
            {
              my $val=$_glb->{type}{$type}{combine}{$attr}{match}{$key};
              $th .= "$key"."="."$val;" ;
            }
          }
          warn "$appl / $qmgr / $type /$obj / $attr" unless defined $th ;
          $report .= "$obj $attr $_objInst->{attr}{$attr}{value} $th -> err\n";
        }
      }
  # future feature : formline
  #   if( $objErr > 0 )
  #   {
  #     
  #   }
    }
  }
  my $subject ;
  if( $globErr > 0 )
  {
    $subject = "Error $appl on $qmgr for $type"; 
  }
  return ($globErr,$report,$subject);
}

################################################################################
# send mail / mailx
################################################################################
sub sendMail
{
  logger() ;

  my $body    = $_[0] ;
  my $_send   = $_[1] ; 
  my $appl    = $_[2] ;
  my $qmgr    = $_[3];
  my $type    = $_[4];

  my $options  = "-s \"Error $appl on $qmgr for $type\" "; 
     $options .= "-c $_send->{mail}{cc} " if exists $_send->{mail}{cc} ;
     $options .= "-b $_send->{mail}{bcc} " if exists $_send->{mail}{bcc} ;
     $options .= "-r dont.reply\@deutsche-boerse.mq " ;
  my $address = " " ;
     $address = $_send->{mail}{address} if exists $_send->{mail}{address} ;
  my $xymURL  = "https://zxymon1.deutsche-boerse.de/xymon-cgi/svcstatus.sh?HOST=".$_send->{xymon}{host}."&SERVICE=".$_send->{xymon}{service};

  # tests to be done
  # 24 h test
  # mail & file diffrent in 2nd line
  # mail longer than file
  # mail shorter than file
  # mail empty but file exists

  my $file = "$TMP/mail-$appl-$qmgr-$type" ;
  my @body = split "\n", $body;

  if( scalar @body == 0 )
  {
    unlink $file ;
    return ;
  }
 
  if( open TMP, $file )
  {
    foreach my $bLine (@body)
    {
      $bLine =~ /^(\S+)\s+(\S+)\s+/ ;
      my $bObj = $1;
      my $bAttr = $2 ;
  
      my $fLine = <TMP> ;
      unless( defined $fLine )
      {
        unlink $file ;
        last ;
      }
      $fLine =~ /^(\S+)\s+(\S+)\s+/ ;
      my $fObj = $1;
      my $fAttr = $2 ;
  
      unless( $fObj eq $bObj &&
              $fAttr eq $bAttr )
      {
        unlink $file ;
        last ;
      }
  
      next ;
    }
    close TMP;
  }
 
  my $mTime = (stat $file)[9] ;
  my $sysTime = time();
  if( defined $mTime )
  {
    if( ($sysTime - $mTime )  > 3600*24 )
    {
      unlink $file ;
    }
    else
    {
      return ;
    }
  }
 
# open MAIL, "|mailx -s \"$subject\" $address" ; 
  open MAIL, "|mailx $options $address " ;
  open TMP, ">$file" ;
  foreach my $line (@body)
  {
    print MAIL "$line\n\n";
    print TMP  "$line\n";
  }
  print MAIL "\n$xymURL\n" ;
  close MAIL ;
  logfdc( $? ) ;
  close TMP ;
}

################################################################################
# send patrol
################################################################################
sub sendPatrol
{
  my $app   = $_[0];
  my $qmgr  = $_[1];
  my $type  = $_[2];
  my $obj   = $_[3];
  my $attr  = $_[4];
  my $_send = $_[5];

  my $class  = $_send->{class};
  my $resend = $_send->{resend};
  my $value  = $_send->{value};
  my $level  = $_send->{level};

  my $baseFile = $app.'-'.$qmgr.'-'.$attr.'-'.$obj ;
  my $patrolFile = $TMP.'/patrol@'.$baseFile ;

  my $fileTime = (stat $patrolFile)[9] ;  # check for flag file
  my $sysTime = time() ;

  if( defined $fileTime &&
      ( $resend > 0 ) && 
      ( $sysTime - $fileTime - $resend*3600 > 0 ) )
  {
    unlink $patrolFile ; 
    undef $fileTime ;
  }

  my $txtLev ;
  if( $level == $OK  )
  {
    $txtLev = 'OK' ; 
  }
  elsif( $level == $WAR )
  {
    $txtLev = 'WARNING' ; 
  }
  elsif( $level == $ERR )
  {
    $txtLev = 'CRITICAL' ;
  }

  my $patrolParam = "$type\@$obj:$attr" ;
  my $txtMsg    = "$txtLev for $attr = $value on $qmgr\@$obj";

  if( $level == $OK )    # if level OK (white, blue, green)
  {
    if( defined $fileTime )
    {
      system "$patrol -c $class -s $txtLev -o \"$qmgr\" -p \"$patrolParam\" -m \"$txtMsg \" ";
      my $rc =  $?>>8 ;
      unlink $patrolFile if $rc == 0 ; 
    }
    else
    {
    }
  }
  elsif( # $level == $WAR || 
         $level == $ERR  )
  {
    if( defined $fileTime )
    {
    }
    else
    {
      system "$patrol -c $class -s $txtLev -o \"$qmgr\" -p \"$patrolParam\" -m \"$txtMsg \" ";
      my $rc =  $?>>8 ;
      if( $rc == 0 )
      {
        open FLAG, ">$patrolFile";
        close FLAG;
      }
    }
  }
}

################################################################################
#
#   M A I N   
#
################################################################################
logger() ;

unless( defined $gRun )
{
  usage unless $gDbg == $DBG ;
  $gRun = $DBG ; 
}

if( $gRun == $STOP )
{
  sendSigHup() ;
  exit 0 ;
}

if( $gRun == $RESTART )
{
  sendSigHup() ;
}

if( $gRun == $CHECK )
{
  $cfg = $gChkIni if defined $gChkIni ;
}

# ----------------------------------------------------------
# start bbrmq.pl as a deamon / detach parent
# ----------------------------------------------------------
if( $gRun == $START || $gRun == $RESTART )
{
  my $pid = fork() ;
  exit 0 unless $pid == 0 ;
  if( -t STDIN && -t STDOUT )
  {
    print "bbrmq.pl started as a deamon\n\n";
  }
}

# ----------------------------------------------------------
# clean flag directory
# ----------------------------------------------------------
mkdir $TMP   , 0775 unless -d $TMP;    # mkdir if not exists
mkdir $PCHTMP, 0775 unless -d $PCHTMP; #
cleanUp();

# ----------------------------------------------------------
# read configuration
# ----------------------------------------------------------
my $_cfg  = getCfg $cfg ;
expandHash( $_cfg ); 

checkCfg( $_cfg );

# ----------------------------------------------------------
# get all queue manager aliases from the local queue manager
# ----------------------------------------------------------
my $wr = FileHandle->new() ;
my $rd = FileHandle->new() ;
my $pid = open2( $rd, $wr, $runmqsc );
usleep 100000 ;
if( $pid == waitpid $pid, &WNOHANG )      # check if runmqsc is still
{                                         #
  $pid = 0;
  close $wr;
  close $rd;
  die "can connect to default queue manager, aborting..." ;
}

print $wr "ping qmgr \n" ;
while( my $line=<$rd> )
{
  last if $line =~ /AMQ\d{4}\w?:/ ;
}

my @qmgrAlias = keys %{ (disQmgrAlias( $rd, $wr, '*', 'UNIX' )) }; 

print $wr "end\n";
usleep 100000 ;
close $wr ;
close $rd ;
unless( $pid == 0 )
{
  waitpid $pid, &WNOHANG ;
  $pid = 0 ;
}

# ----------------------------------------------------------
# disable single queue manager for monitoring
# ----------------------------------------------------------
if( $gRun == $DISABLE )
{
  my $match = grep { $_ eq $gDsbQmgr } @qmgrAlias ;
  setTmpDisable ;
  die "\n" ;
}

# ----------------------------------------------------------
# connect to all queue manager
# ----------------------------------------------------------

$_conn = cfg2conn $_cfg->{connect}, \@qmgrAlias ;
my $_format = tree2format $_cfg;

my $_stat ;

if( $gList == 1 )
{
  listCfg $_cfg ;
  exit ;
}

################################################################################
#   L O O P 
################################################################################
my $SLEEP = 300 ;
while( 1 )
{
  my $timeA = time() ;

  connQmgr $_cfg, $_conn, \@qmgrAlias ;
  $_stat = getObjState $_cfg, $_conn ;
  shrinkAttr $_cfg, $_stat ;

  if( $gRun == $IGNORE )
  {
    setTmpIgn $_cfg, $_stat ;
    my $_ign = getTmpIgn ;
    evalStat  $_cfg, $_stat, $_ign, undef  ;
    printMsg $_stat, $_cfg, $_format ;
    last ;
  }

  if( $gRun == $ENABLE )
  {
    setTmpEnable $_cfg, $_stat ; 
    my $_enb = getTmpEnb ;
    my $_ign = getTmpIgn ;
    mergeIgnEnb $_ign, $_enb ;
    evalStat  $_cfg, $_stat, $_ign, $_enb ;
    printMsg $_stat, $_cfg, $_format ;
    last ;
  }

  my $_ign = getTmpIgn ;
  my $_enb = getTmpEnb ;
  mergeIgnEnb $_ign, $_enb ;
  evalStat  $_cfg, $_stat, $_ign, $_enb ;
  printMsg $_stat, $_cfg, $_format ;
  
  my $timeD = time() - $timeA ;
  $timeD = 250 if( $timeD > 250 ) ;
  if( $gDbg == $DBG  )
  {
    sleep 5;
    next ;
  }
  sleep ($SLEEP - $timeD ) ;
}

