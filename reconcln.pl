#!/usr/bin/perl

use strict ;
use warnings ;

BEGIN
{
  push @INC, $ENV{HOME}.'/monitor/lib' ;
}

delete $ENV{MQPROMPT} if exists $ENV{MQPROMPT};

use FileHandle ;           # for file handel as object
use IPC::Open2 ;           # for runmqsc starting in the background
use POSIX ":sys_wait_h" ;  # for no hang on runmqsc in the background
use Time::Local ;
use Time::HiRes qw(usleep nanosleep);

use Data::Dumper ;

use qmgr 5.0 ;
use mqsc 5.0 ;

my $runmqsc  = '/opt/mqm/90a/bin/runmqsc -e ' ;
my $dspmqrte = '/opt/mqm/90a/bin/dspmqrte -q XYMON.TEST.NOT.EXISTS -w 10 -v outline -qm ' ;

################################################################################
#
#   M A I N  
#
################################################################################

# ----------------------------------------------------------
# get all queue manager aliases from the local queue manager
# ----------------------------------------------------------
#my $wr = FileHandle->new() ;
#my $rd = FileHandle->new() ;
#my $pid = open2( $rd, $wr, $runmqsc );
#usleep 100000 ;
#if( $pid == waitpid $pid, &WNOHANG )      # check if runmqsc is still
#{                                         #
#  $pid = 0;
#  close $wr;
#  close $rd;
#  die "can connect to default queue manager, aborting..." ;
#}

#print $wr "ping qmgr \n" ;
#while( my $line=<$rd> )
#{
#  last if $line =~ /AMQ\d{4}:/ ;
#}

my ($pid, $rd, $wr, $platform) = connect $runmqsc ;

# ----------------------------------------------------------
# get all queue manager aliases from the local queue manager
# ----------------------------------------------------------
my @qmgrAlias = keys (disQmgrAlias( $rd, $wr, '*', 'UNIX' ));

my $_qmgrAlias ;


# ----------------------------------------------------------
# get xmitq to every queue manager alias
# ----------------------------------------------------------

foreach my $qmgr ( @qmgrAlias )
{
  print $wr "display qremote($qmgr) xmitq where ( rname eq '') \n" ;
  print $wr "ping qmgr\n" ;

  my $_qr = parseMqsc $rd, 'UNIX' ;

  unless( exists $_qr->{$qmgr}[0]->{XMITQ} )
  {
    next;
  }

  if( $_qr->{$qmgr}[0]->{XMITQ} eq ' ' )
  {
    delete $_qr->{$qmgr} ;
    next;
  }

  $_qmgrAlias->{$qmgr} = $_qr->{$qmgr}[0];
}

# ----------------------------------------------------------
# display the route to all queue manager
# ----------------------------------------------------------
my $_sdr;
foreach my $qmgr (@qmgrAlias)
{
  open my $read, "$dspmqrte $qmgr | " ;

  print "$qmgr\n";

  my $rqmgr ;
  my $sdr   ;

  while ( my $line = <$read> )
  {
    chomp $line ;
    next if $line =~ /^AMQ8653:/ ;
    next unless( $line =~ /^\s*(\w+):\s+'(.+?)\s*'\s*$/ );
    my $key = $1;
    my $val = $2;
    next if $key eq 'ApplName'      ;    # to be ignored
    next if $key eq 'QName'         ;    # to be ignored
    next if $key eq 'ResolvedQName' ;    # to be ignored
    next if $key eq 'RemoteQName'   ;    # to be ignored
    next if $key eq 'RemoteQMgrName';    # to be ignored
    next if $key eq 'XmitQName'     ;    # to be ignored

    $rqmgr = $val if $key eq 'QMgrName' ;
    $sdr   = $val if $key eq 'ChannelName' ;
    next unless defined $sdr ;
    next if exists $_sdr->{$sdr} ;
    $_sdr->{$sdr}{QMGR} = $rqmgr ;
    next;
  }

  close $read;
}

# ----------------------------------------------------------
# display the route to all queue manager
# ----------------------------------------------------------

my $_conn ;
foreach my $sdr (keys %$_sdr)
{
  my $qmgr = $_sdr->{$sdr}{QMGR} ;

  print "$sdr\n" ;
  my $status = $_sdr->{$sdr}{STATUS} if exists $_sdr->{$sdr}{STATUS} ;
 
  next if $status eq 'STOPPED' ;
  next if $status eq 'RUNNING' ;
 
  unless( exists  $_conn->{$qmgr}{WR}  )
  {
    $_conn->{$qmgr}{WR}  = FileHandle->new() ;
    $_conn->{$qmgr}{RD}  = FileHandle->new() ;
  }

  unless( exists $_conn->{$qmgr}{PID} &&  $_conn->{$qmgr}{PID} > 0 )
  { 
    my $pid  = open2 $_conn->{$qmgr}{RD} ,          # try to connect
                     $_conn->{$qmgr}{WR} ,          #
                     "$runmqsc -w 10 $qmgr";        #
   
    usleep 100000 ;
    
    if( $pid == waitpid $pid, &WNOHANG )  
    {
      $pid = 0;
      close $_conn->{$qmgr}{WR} ;
      close $_conn->{$qmgr}{RD} ;
    }
  }

  my $rd = $_conn->{$qmgr}{RD} ;
  my $wr = $_conn->{$qmgr}{WR} ;
  
  print $wr "dis chs($sdr) \n" ;
  print $wr "ping qmgr\n" ;

  my $_chs = parseMqsc $rd, 'UNIX' ;

  $status = $_chs->{$sdr}[0]->{STATUS} ;
  $_sdr->{$sdr}{STATUS} = $status ;
  next if $status eq 'STOPPED' ;
  next if $status eq 'RUNNING' ;

  print $wr "start chl(*)\n";
  print $wr "ping qmgr\n" ;
  parseMqsc $rd, 'UNIX' ;
}
