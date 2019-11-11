#!/usr/bin/perl

use strict ;
use Sys::Hostname ;
BEGIN
{
  push @INC, '/home/mqm/monitor/lib' ;
}



################################################################################
#   L I B R A R I E S   
################################################################################
use Data::Dumper ;

use xymon ;

################################################################################
# IMPORT EXTERNAL HASHES
################################################################################
our %IGN ;
require "/home/mqm/monitor/ini/amq.global.ini" ;

################################################################################
# COMMAND LINE ARGUMENTS
################################################################################
my @qmgr ;
my $reset = 0 ;

my $opt ;

while( defined $ARGV[0] )
{
  if( $ARGV[0] =~ s/^-// )
  {
    $opt = $ARGV[0] ;
    shift ;
    $reset = 1 if $opt eq 'reset' ;
    next ;
  }
  if( $opt eq 'qmgr' )
  {
    push @qmgr, $ARGV[0] ;
    shift ;
    next ;
  }
}

################################################################################
# CONSTANTS
################################################################################
my $TIME_MIN = 0 ;
my $TIME_MAX = 99999999999999 ;
my $MAX_LINE = 300 ;

my %LEV = ( 'NA' => '&clear'  , 
            'MSG' => '&green' ,
            'WAR' => '&yellow',
            'ERR' => '&red' );

################################################################################
# FORMAT
################################################################################
my $formBB     = "@<<<<<<< @<<<<< @<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
" ;

################################################################################
# GLOBALS
################################################################################
my $errdir = "/var/www/data/log/";



################################################################################
# process a single amq log
################################################################################
sub processAmqLog
{
  my $_amq = $_[0] ;
  my $amq = $_[1] ;

   my $date;
   my $time;
   my $type;
   my $logId;
   my $logDscr;
   my $expl ;
   my $action;

  open AMQLOG, $amq ;

  my $cnt = scalar keys %$_amq ;

  foreach my $line (<AMQLOG>)
  {
    chomp $line ;

    if( $line =~ /^(\d\d).(\d\d).(\d{2,4})\s+(\d\d).(\d\d).(\d\d)\s+([AaPp][Mm])?.+/ )
    {
      my $am_pm = $7 ;
      my $YY = $3 ;
      my $MM = $1 ;
      my $DD = $2 ;
      my $hh = $4 ;
      my $mm = $5 ;
      my $ss = $6 ;
      $YY += 2000 if $YY < 2000 ;
      $hh  = 0    if( $am_pm =~ /[Aa][Mm]/ && $hh == 12 ) ;
      $hh += 12   if $am_pm =~ /[Pp][Mm]/ ;
      $hh -= 12   if $hh > 23 ;
      $date = $YY.$MM.$DD ;
      $time = $hh.$mm.$ss ;
      $type = 'TIME' ;
      next ;
    }

    if( $line =~ /^(AMQ\d{4})\w?:\s+(.*)$/ )
    {
      $logId = $1 ;
      $logDscr  = $2 ;
      $type  = 'ID' ;
      next ;
    }

    if( $line =~ /^EXPLANATION:\s*$/ )
    {
      $type = 'EXPL' ;
      next ;
    }

    if( $line =~ /^ACTION:\s*$/ )
    {
      $type = 'ACTION' ;
      next ;
    }

    if( $line =~ /^-{5}.+-{5}$/ )
    {
      $_amq->{$cnt}{DATE} = $date ;
      $_amq->{$cnt}{TIME} = $time ;
      $_amq->{$cnt}{ID}   = $logId ;
      $_amq->{$cnt}{DSCR} = $logDscr ;
      $_amq->{$cnt}{EXPL} = $expl ;
      $_amq->{$cnt}{ACT}  = $action ;

      my $timeStamp = $date.$time ;
      delete $_amq->{$cnt} if( $timeStamp < $TIME_MIN ||
                               $timeStamp > $TIME_MAX ) ;

      $cnt++ ;
      $time   = '' ;
      $logId  = '' ;
      $expl   = '' ;
      $action = '' ;
      next ;
    }

    if( $type eq 'TIME' )
    {
      next ;
    }

    if( $type eq 'ID' )
    {
      $logDscr .= ' '.$line ;
      next ;
    }
    if( $type eq 'EXPL' )
    {
      $expl .= ' '.$line ;
      next ;
    }

    if( $type eq 'ACTION' )
    {
      $action .= ' '.$line ;
      next ;
    }

  }
  close AMQLOG ;
}



################################################################################
sub processAmqDir
{
  my $qmgrDir = $_[0] ;
  my $filter = $qmgrDir.'/AMQERR??.LOG' ;
  my %amq ;

  my @amq = sort {$b cmp $a} glob $filter ;
  foreach my $amq (@amq)
  {
  # my $age = getFileAge($amq) ;
  # next if $age > $AMQ_AGE ;
    processAmqLog \%amq, $amq ;
  }
  return \%amq ;
}

################################################################################
#
################################################################################
sub getResetTime
{
  my $qmgr = $_[0] ;

  my $resetFile = '/home/mqm/monitor/flag/mqLog.'.$qmgr.'.log' ;
  open RESET, "$resetFile" ;
  my $time = <RESET> ;
  close RESET ;

  return $time ;
}


################################################################################
################################################################################
sub cutResetAmqMsg
{
  my $_amq = $_[0] ;
  my $qmgr = $_[1] ;

  my $resetTime = getResetTime $qmgr ;

  foreach my $cnt (sort {$a <=> $b} keys %$_amq )
  {
    my $amqTime =  $_amq->{$cnt}{DATE}.$_amq->{$cnt}{TIME} ;
    delete $_amq->{$cnt} if $amqTime < $resetTime ;
  }
}


################################################################################
# 
################################################################################
sub buildAmqMsg
{
  my $_amq = $_[0] ;
  my $msg = '' ;
  my $size = 0 ;

  my $war = 0 ;
  my $err = 0 ;

  foreach my $cnt (sort {$b <=> $a} keys %$_amq )
  {
    $^A = '' ;

    my $lev = $_amq->{$cnt}{LEV} ;
    my $color = $LEV{$lev} ;

    formline $formBB, $_amq->{$cnt}{DATE} ,
                      $_amq->{$cnt}{TIME} ,
                      $_amq->{$cnt}{ID}   ,
                      $_amq->{$cnt}{DSCR} ,
                      $_amq->{$cnt}{EXPL} ,
                      $_amq->{$cnt}{ACT}  ;
    $msg .= $color.$^A ;

    $war++ if $_amq->{$cnt}{LEV} eq 'WAR' ;
    $err++ if $_amq->{$cnt}{LEV} eq 'ERR' ;

    last if $size > $MAX_LINE ;
    $size++ ;
  }
  return ($msg,$war,$err) ;
}

################################################################################
#
################################################################################
sub setAmqLevel 
{
  my $_amq = $_[0]; 
  my $_ign = $_[1]; 
  my $_qmgrIgn = $_[2] ;

  foreach my $i ( keys %$_amq )
  {
    my $amq = $_amq->{$i}{ID} ;
    my $lev = 'NA' ;
    $lev = $_ign->{$amq}{LEV} if exists $_ign->{$amq} ;
    $lev = $_qmgrIgn->{$amq}{LEV} if (defined $_qmgrIgn && exists $_qmgrIgn->{$amq} && exists $_qmgrIgn->{$amq}{LEV} )  ;
    $_amq->{$i}{LEV} = $lev ;
  }
}

################################################################################
# reset xymon
################################################################################
sub resetXymon
{
  my $_amq = $_[0];
  my $qmgr   = $_[1];

  my $rc = &findFirstErr( $_amq, \%IGN );

  my $resetFile = '/home/mqm/monitor/flag/mqLog.'.$qmgr.'.log' ;
  open RESET, ">$resetFile" ;

   my $time = sprintf("%8d%6d",$_amq->{$rc}{DATE},$_amq->{$rc}{TIME});
      $time =~ s/\s/0/g ;

  print RESET  $time+1;
  close RESET ;

}

################################################################################
#
################################################################################
sub findFirstErr
{
  my $_amq = $_[0];
  my $_ign = $_[1];

  my $oldCnt = 0 ;
  foreach my $cnt (sort {$b <=> $a} keys %$_amq )
  {
    my $id = $_amq->{$cnt}{ID} ;
    next unless exists $IGN{$id} ;
    if( $_ign->{$id}{LEV} eq 'MSG'  ||
        $_ign->{$id}{LEV} eq 'IGN'  ||
        $_ign->{$id}{TYPE} eq 'NONE' )
    {
      $oldCnt = $cnt ;
      next ;
    }
    return $cnt ;
  }
  return -1 ;
}

################################################################################
# tailAmqMsg
################################################################################
sub tailAmqMsg
{
  my $_amq = $_[0] ;
  my $id   = $_[1] ;

  my $oldCnt = -1 ;

  foreach my $cnt (sort {$a <=> $b }keys %$_amq )
  {
    next unless $_amq->{$cnt}{ID} eq $id ;
    delete $_amq->{$oldCnt} if exists $_amq->{$oldCnt} ;
    $oldCnt = $cnt ;
  }
}

sub flushAmqMsg
{
  my $_amq = $_[0] ;
  my $id   = $_[1] ;

  foreach my $cnt (keys %$_amq )
  {
    next unless $_amq->{$cnt}{ID} eq $id ;
    delete $_amq->{$cnt} ;
  }
}

sub groupAmqMsg
{
  my $_amq = $_[0] ;
  my $id   = $_[1] ;

  my $firstCnt = -1 ;
  foreach my $cnt (sort {$a <=> $b}keys %$_amq )
  {
    unless( $_amq->{$cnt}{ID} eq $id )
    {
      $firstCnt = -1 ;
      next ;
    }
    if( $firstCnt == -1 )
    {
      $firstCnt = $cnt ;
      next ;
    }
    delete $_amq->{$cnt} ;
  }
}

sub checkFileAge
{
  my $file = $_[0] ;

  my $fileTime = (stat $file)[9] ;  
  my $sysTime  = time() ;

  return $sysTime-$fileTime;
}

sub getLocalIgn
{
  my $_ini ;
  foreach my $ini ( glob "/home/mqm/monitor/ini/amq.*.ini" )
  {
    my ($qmgr) = ($ini =~ /^.+\/amq\.(\w+)\.ini$/ ); 
    next if $qmgr eq 'global' ;
    print "$qmgr\t$ini\n" ;
    our %ign ;
    require $ini ;
    $_ini->{$qmgr} = \%ign ; 
    next ;
  }
  return $_ini ;
}

################################################################################
#
#   M A I N  
#
################################################################################

if( $qmgr[0] eq 'all' )
{
  @qmgr = qw <> ;
  foreach my $qmgr (glob "$errdir/*" )
  {
    $qmgr =~ s/^.+\///;
    push @qmgr, $qmgr ;
  }
}

 my $_locIgn = getLocalIgn ;

foreach my $qmgr (@qmgr)
{
  my $amqdir = $errdir.$qmgr ;
  my $_amq = processAmqDir $amqdir ;
  
  if( $reset == 1 )
  {
    resetXymon $_amq, $qmgr ;
    $_amq = processAmqDir $amqdir ;
  }
  
  cutResetAmqMsg $_amq, $qmgr ;
  my $_qmgrIgn = $_locIgn->{$qmgr} if exists $_locIgn->{$qmgr} ;
  setAmqLevel $_amq, \%IGN, $_qmgrIgn;

  foreach my $ignId (sort keys %IGN)
  {
    my $type = $IGN{$ignId}{TYPE} ;
    $type = $_locIgn->{$qmgr}{$ignId}{TYPE} if( defined $_locIgn && exists $_locIgn->{$qmgr}{$ignId} && exists $_locIgn->{$qmgr}{$ignId}{TYPE} );
    if( $type eq 'LAST_ONLY' )
    {
      tailAmqMsg $_amq, $ignId ;
      next;
    }
    next if( $type eq 'EVERY' ); 
    if( $type eq 'NONE' )
    {
      flushAmqMsg $_amq, $ignId ;
    }
    if( $type eq 'GRP_FIRST' )
    {
      groupAmqMsg $_amq, $ignId ;
    }
  }

  my $timeDiff = checkFileAge $amqdir.'/AMQERR01.LOG' ;

  my ( $msg, $war, $err ) = buildAmqMsg $_amq ;
  my $host = hostname ;
  $msg = "reset message on $host via: ~mqm/monitor/bin/ml.pl -reset -qmgr {QMGR}\n\n".$msg ;
  if( $timeDiff > 3600 )
  {
    $timeDiff/=60;
    $timeDiff=~s/\.\d+//;
    $err++;
    $msg="&red No file copied from $qmgr to syspmq3 for $timeDiff minutes, check file transfer on syspmq3 
    scp $qmgr:/mq/data/$qmgr/errors/AMQERR01.LOG $amqdir

   last message received:
".$msg ;
  }

  my $color = 'green' ;
     $color = 'yellow' if $war > 0 ;
     $color = 'red'    if $err > 0 ;

  writeMsg $msg, $color, $qmgr, 'log' ;
}

exit ;
