#!/usr/bin/perl -wT
#-wT
#-d:ptkdb
#-d:DProf  

# author: Thomas Baum
# 09.04.2005
# erfasste Rechnungsposten ausgeben

use strict;
use CGI;
use Date::Calc qw(Today Add_Delta_DHMS);

use lib "../";
use Heb_stammdaten;
use Heb_datum;
use Heb_leistung;

my $q = new CGI;
my $s = new Heb_stammdaten;
my $d = new Heb_datum;
my $l = new Heb_leistung;

my $debug=1;

my $TODAY = sprintf "%4.4u-%2.2u-%2.2u",Today();

my $frau_id = $q->param('frau_id') || 0;

print $q->header ( -type => "text/html", -expires => "-1d");


print '<head>';
print '<title>list_posnr</title>';
print '<script language="javascript" src="../Heb.js"></script>';
print '<script language="javascript" src="leistungen.js"></script>';
print '</head>';

# style-sheet ausgeben
print <<STYLE;
  <style type="text/css">
  .disabled { color:black; background-color:gainsboro}
  .invisible { color:white; background-color:white;border-style:none}
  </style>
STYLE



# Alle Felder zur Eingabe ausgeben 
print '<table rules=rows style="margin-left:0" border="2" width="100%" align="left">';

# jetzt Rechnungsposten ausgeben
my $i=0;
$l->leistungsdaten_such($frau_id);
while (my @erg=$l->leistungsdaten_such_next()) {
  $i++;
  print '<tr>';
  print "<td style='width:1cm;margin-left:0em'>";
  print "<input style='font-size:8pt' type='button' name='aendern$i' value='�ndern' onclick='aend($frau_id,$erg[0]);'></td>\n";

  print "<td style='width:1cm'><input style='padding:0;margin:0;font-size:8pt' type='button' name='loeschen1' value='L�schen' onclick='loe_leistdat($frau_id,$erg[0]);'></td>";
  print "<td style='width:1.3cm;text-align:left'>$erg[4]</td>"; # datum
  print "<td style='width:0.4cm;text-align:center'>$erg[1]</td>"; # posnr
  # Aus DB Geb�hrentext und E. Preis holen
  my($l_bezeichnung,$l_preis)=$l->leistungsart_such_posnr('KBEZ,EINZELPREIS',$erg[1],$d->convert($erg[4]));
  print "<td style='width:5.0cm;text-align:left'>$l_bezeichnung</td>";
  $l_preis =~ s/\./,/g;
  print "<td style='width:1.0cm;text-align:right'>$l_preis</td>"; # e preis
  my $g_preis = sprintf "%.2f",$erg[10];$g_preis =~ s/\./,/g;
  print "<td style='width:1.0cm;text-align:right'>$g_preis</td>"; # g preis
  my ($h1,$m1)= unpack('A2xA2',$erg[5]);
  $erg[5] =~ s/00:00//g;
  print "<td style='width:1cm;text-align:right'>$erg[5]</td>"; # zeit von
  my ($h2,$m2)= unpack('A2xA2',$erg[6]);
  $erg[6] =~ s/00:00//g;
  print "<td style='width:0.8cm;text-align:right'>$erg[6]</td>"; # zeit bis
  # Dauer berechnen
  $h1 *=-1;
  $m1 *=-1;
  my ($y,$m,$d,$H,$M,$S) = Add_Delta_DHMS(1900,1,1,$h2,$m2,0,0,$h1,$m1,0);
  my $dauer=sprintf "%2.2u:%2.2u",$H,$M;
  $dauer =~ s/00:00//g;
  print "<td style='width:0.8cm;text-align:right'>$dauer</td>\n"; # Dauer
  my $beg='';
  $beg='ja' if (defined($erg[3]) && $erg[3] ne '');
  print "<td style='width:0.7cm;text-align:center'>$beg</td>"; # Begr�ndung
  my $tag = sprintf "%.2f",$erg[7];$tag =~ s/\./,/g;$tag =~ s/0,00//g;
  print "<td style='width:0.8cm;text-align:right'>$tag</td>"; # Entfernung Tag
  my $nacht = sprintf "%.2f",$erg[8];$nacht =~ s/\./,/g;$nacht =~ s/0,00//g;
  print "<td style='width:0.8cm;text-align:right'>$nacht</td>"; # Entfernung Nacht
  $erg[9]='' if ($tag eq '' && $nacht eq '');
  print "<td style='width:0.5cm;text-align:right'>$erg[9]</td>"; # Anzahl Frauen

  my $status ='';
  $status = 'in bearb.' if ($erg[11]==10);
  $status = 'Rechnung' if ($erg[11]==20);
  $status = 'abgeschl.' if ($erg[11]==30);
  print "<td style='width:1.5cm;text-align:right'>$status</td>"; # Status der Position
  print '</tr>';
  print "\n";
}
  print '</table>';
print "\n";
print "<script>window.scrollByLines(1000);</script>";
print "</body>";
print "</html>";

