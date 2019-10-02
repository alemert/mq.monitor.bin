#!/usr/bin/perl

use strict ;

use IPC::Open2 ;  
use Time::Local ;

my $ssl ='/usr/bin/openssl s_client -showcerts -connect ' ;
my $x509='/usr/bin/openssl x509 -noout -enddate -startdate -issuer -subject -in ' ;

my %MONTH;
   $MONTH{Jan} = 0 ;
   $MONTH{Feb} = 1 ;
   $MONTH{Mar} = 2 ;
   $MONTH{Apr} = 3 ;
   $MONTH{May} = 4 ;
   $MONTH{Jun} = 5 ;
   $MONTH{Aug} = 7 ;
   $MONTH{Nov} = 10 ;
   $MONTH{Dec} = 11 ;

my $ssldir = "/var/www/data/ssl" ;

my %CFG ;

delete $ENV{MQPROMPT} if exists $ENV{MQPROMPT} ;

my ($rd, $wr );
my $pid = open2( $rd, $wr, "runmqsc -e" );

<$rd> ; 
<$rd> ; 

foreach my $qmgr (glob "$ssldir/*/" )
{
  $qmgr =~ s/^.+\/(.+)\//$1/ ;
  my $xmitq ;
  my $conname ;
  print $wr "dis qr($qmgr) xmitq\n" ;
  print $wr "ping qmgr\n" ;
  while (my $line = <$rd>)
  {
    chomp $line ;
    last if $line =~ /^AMQ8415I?:/ ;
    next unless $line =~ /^.+\sXMITQ\((.+)\)/ ;
    $xmitq = $1 ;
  }

  print $wr "dis chl(*) conname where ( xmitq eq $xmitq )\n" ; 
  print $wr "ping qmgr\n" ;
  while (my $line = <$rd>)
  {
    chomp $line ;
    last if $line =~ /^AMQ8415I?:/ ;
    next unless $line =~ /^.+\sCONNAME\((.+?)\((\d+)\)\)/ ;
    $conname = "$1:$2" ;
  }
  $CFG{$qmgr}{CONN} = $conname ;
}

foreach my $qmgr ( keys %CFG )
{
  my $dir = $ssldir.'/'.$qmgr ;
  open CHAIN, ">$dir/chain" ;
  my $conn = $CFG{$qmgr}{CONN} ;
  my $id ;
  my $write = 0 ;
  
  foreach my $line ( `echo | $ssl $conn` )
  {
    print CHAIN "$line" ;
    chomp $line ;
    if( $line =~ /^\s+(\d+)\s+s:\/(.+)$/ )
    {
      $id = $1;
      my $label = $2 ;
      $CFG{$qmgr}{SUBJECT}{$id} = $label ;
      open CRT, ">$dir/$id.cert" ;
      next ;
    }
    if( $line =~ /^\s+i:\/(.+)$/ )
    {
      my $label = $1;
      $CFG{$qmgr}{ISSUER}{$id} = $label ;
      next ;
    }
    $write = 1 if $line =~ /\-+BEGIN CERTIFICATE\-+/ ;
    print CRT "$line\n" if $write == 1 ;
    if( $line =~ /\-+END CERTIFICATE\-+/ )
    {
      close CRT; 
      $write = 0 ;
    }
  }
  close CHAIN ;
}


foreach my $qmgr ( keys %CFG )
{
  open XYMON, ">$ssldir/$qmgr/xymon" ;
  foreach my $file (glob "$ssldir/$qmgr/*.cert" )
  {
    foreach my $line (`$x509 $file`)
    {
      if( $line =~ /notAfter=(\w+)\s+(\d+)\s+\d+:\d+:\d+\s+(\d+)\s+/ )
      {
        my $month = $1 ;
        my $dd    = $2 ;
        my $yyyy  = $3 ;
        warn "unknown month $month" unless exists $MONTH{$month} ;
        my $mm = 0;
        $mm = $MONTH{$month} if exists $MONTH{$month} ;
        my $epochTime = timelocal(0, 0, 12, $dd, $mm, $yyyy );
        my $timeDiff = $epochTime - time() ;
        my $day = $timeDiff/3600/24 ;
        my $lev = 'OK' ;
        $lev = 'WAR' if $day < 120 ;
        $lev = 'ERR' if $day < 60 ;
        print XYMON "$lev\n";
      }
      print XYMON $line ;
    }
  }
  close XYMON ;
}
