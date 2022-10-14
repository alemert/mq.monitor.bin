#!/usr/bin/perl

use strict ;
BEGIN
{
  push @INC, '/home/mqmon/monitor/lib' ;
}

use xymon ;

importEnv ;

my $spool = "/var/data/systemd" ;

foreach my $dir (glob "$spool/*" )
{
  next unless -d $dir ;
  my $rcFile = $dir."/systemd.rc" ;
  my $outFile = $dir."/systemd.stdout" ;

  next unless -f "$rcFile"  ;
  next unless -f "$outFile" ;

  my $qmgr = $dir ;
  $qmgr =~ s/.+\/(.+)$/$1/;

  open  RC, "$rcFile" ;
  my $rc = <RC> ;
  close RC ;

  my $msg ;
  open  OUT, "$outFile";
  foreach my $line (<OUT> )
  {
    $msg .= $line ;
  }
  close OUT ;

  my $color = "red" ;
  $color = "green" if $rc == 0 ;

  writeMsg $msg, $color, $qmgr, "sysd" ;
}

