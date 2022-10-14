#!/usr/bin/perl

BEGIN
{
  push @INC, '/home/mqmon/monitor/lib' ;
}

use strict ;
use xymon ;

my $dfdir = "/var/data/df" ;


foreach my $dir ( glob "$dfdir/*" )
{
  next unless -d $dir ;
  next unless -f "$dir/df.stdout" ;

  (my $qmgr = $dir ) =~ s/^\/.+\/(\w+)$/$1/ ;

  my $msg = "<table>\n";
  my $war = 0;
  my $err = 0;
  open DF, "$dir/df.stdout" ;
  foreach my $line (<DF>)
  {
    chomp $line ;
    next unless $line =~ /^(\/dev\/\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)%\s+(\S+)/ ;
    my $dev  = $1 ;
    my $all  = $2 ;
    my $used = $3 ;
    my $avail = $4 ;
    my $ratio = $5 ;
    my $mount = $6 ;
    
    my $realRatio = $used/$all*100 ;
    my $color = "&green" ;
    if( $realRatio > 60 )
    {
      $war++;
      $color = "&yellow";
    }
    if( $realRatio > 85 )
    {
      $err++;
      $color = "&red";
    }
   
    $msg .= sprintf "<tr><td>$color</td><td>%s&nbsp;</td><td>&nbsp;%d/%d</td><td>=%.2f\%</td></tr>\n", $mount, $used, $all, $realRatio ;
  }
  close DF ;

  $msg .= "</table>" ;

  my $bbColor = 'green';
     $bbColor = 'yellow' if $war > 0 ;
     $bbColor = 'red'    if $err > 0 ;
  writeMsg $msg, $bbColor, $qmgr, 'fs' ;

}

