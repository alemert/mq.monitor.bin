#!/usr/bin/perl

BEGIN
{
  push @INC, '/home/mqmon/monitor/lib' ;
}

use strict ;
use xymon ;

use Time::Local ;

my %MONTH ;
   $MONTH{January}   = 0 ;
   $MONTH{February}  = 1 ;
   $MONTH{March}     = 2 ;
   $MONTH{April}     = 3 ;
   $MONTH{May}       = 4 ;
   $MONTH{June}      = 5 ;
   $MONTH{July}      = 6 ;
   $MONTH{August}    = 7 ;
   $MONTH{September} = 8 ;
   $MONTH{October}   = 9 ;
   $MONTH{November}  = 10 ;
   $MONTH{December}  = 11 ;

my $WAR = 42 ;
my $ERR = 21 ;

my $ssldir = "/var//data/ssl" ;

foreach my $dir ( glob "$ssldir/*" )
{
  next unless -d $dir ;
  (my $qmgr = $dir ) =~ s/^\/.+\/(\w+)$/$1/ ;
  my $msg = "" ;
  my $war = 0;
  my $err = 0;
  foreach my $file ( glob "$dir/*" )
  {
    my $label ;
    my $subject  ;
    my $notAfter ;
    my $xpTime ;

    open SSL, $file ;
    foreach my $line (<SSL>)
    {
      chomp $line ;
      if( $line =~ /^\s*Label\s*:\s*(\S.+)$/ )
      {
        $label = $1 ;
        next ;
      }
      if( $line =~ /^\s*Subject\s*:\s*(\S.+)$/ )
      {
        $subject = $1 ;
        next ;
      }
      if( $line =~ s/^\s*Not After\s*:\s*(\S.+)$/$1/ )
      {
        $notAfter = $line ;
        $line =~ /^(\w+)\s+(\d+),\s+(\d+)\s+/ ;
        my $month = $1 ;
        my $dd    = $2 ;
        my $yyyy  = $3 ;
           $yyyy = 2037 if $yyyy > 2037 ;
        warn "unknown month $month" unless exists $MONTH{$month} ;
        my $mm=$MONTH{$month} ;
        my $epochTime = timelocal(0, 0, 12, $dd, $mm, $yyyy );
        $xpTime = $epochTime - time() ;
        next ;
      }
    }
    close SSL ;

    $xpTime /= (3600*24) ;  
    my $color = "&green" ;
    if( $xpTime < $WAR )
    {
      $color = "&yellow" ;
      $war++;
    }
    if( $xpTime < $ERR )
    {
      $color = "&red" ;
      $err++;
    }
    
    $msg .= "$color $notAfter $subject\n" ;
  }

  my $bbColor = 'green';
     $bbColor = 'yellow' if $war > 0 ;
     $bbColor = 'red'    if $err > 0 ;
  writeMsg $msg, $bbColor, $qmgr, 'ssl' ;
}
