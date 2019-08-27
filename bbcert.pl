#!/usr/bin/perl

BEGIN
{
  push @INC, '/home/mqm/monitor/lib' ;
}

use strict ;
use xymon ;

my $ssldir = "/var/www/data/ssl" ;

foreach my $dir ( glob "$ssldir/*/" )
{
  $dir =~ /^.+\/(.+)\/$/ ;
  my $qmgr = $1 ;
  my $msg ;
  my $err = 0 ;
  my $war = 0 ;
  my $lev = "&green" ;
  open DATA, "$dir/xymon" ;
  foreach my $line (<DATA>)
  {
    chomp $line ;
    if( $line =~ /^\s*OK\s*$/ )
    {
      $lev = '&green' ;
      $msg .= "\n$lev " ;
      next ;
    }
    if( $line =~ /^\s*WAR\s*$/ )
    {
      $war++;
      $lev = '&war' ;
      $msg .= "\n$lev " ;
      next ;
    }
    if( $line =~ /^\s*ERR\s*$/ )
    {
      $err++;
      $lev = '&err' ;
      $msg .= "\n$lev " ;
      next ;
    }
    $msg .= "$line\n" ;
  }

  my $color = "green" ;
  $color = "yellow" if $war > 0 ;
  $color = "red" if $err > 0 ;
 
  close DATA ;
  writeMsg $msg, $color, $qmgr, 'cert' ;
}
