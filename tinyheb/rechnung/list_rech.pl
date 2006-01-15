#!/usr/bin/perl -wT
#-wT
#-d:ptkdb
#-d:DProf  

# erfasste Rechnungen ausgeben

# Copyright (C) 2005,2006 Thomas Baum <thomas.baum@arcor.de>
# Thomas Baum, Rubensstr. 3, 42719 Solingen, Germany

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


use strict;
use CGI;
use Date::Calc qw(Today);

use lib "../";
use Heb_stammdaten;
use Heb_datum;
use Heb_leistung;
use Heb_krankenkassen;

my $q = new CGI;
my $s = new Heb_stammdaten;
my $d = new Heb_datum;
my $l = new Heb_leistung;
my $k = new Heb_krankenkassen;

my $debug=1;

my $TODAY = sprintf "%4.4u-%2.2u-%2.2u",Today();

my $frau_id = $q->param('frau_id') || 0;

print $q->header ( -type => "text/html", -expires => "-1d");


print '<head>';
print '<title>list_rech</title>';
print '<script language="javascript" src="../Heb.js"></script>';
print '<script language="javascript" src="rechnung.js"></script>';
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
$l->rechnung_such("RECHNUNGSNR,DATE_FORMAT(RECH_DATUM,'%d.%m.%Y'),DATE_FORMAT(MAHN_DATUM,'%d.%m.%Y'),DATE_FORMAT(ZAHL_DATUM,'%d.%m.%Y'),BETRAG,STATUS,BETRAGGEZ,FK_STAMMDATEN,IK");
while (my @erg=$l->rechnung_such_next()) {
  print '<tr>';
  print "<td style='width:1.5cm;margin-left:0em;margin-right:0em'>";
  print "<input style='font-size:8pt' type='button' name='bearb' value='Bearbeiten' onclick='bearb_rech($erg[0],$erg[5]);'></td>\n";
  print "<td style='width:1.5cm;margin-left:0em'><input style='font-size:8pt' type='button' name='anseh' value='Ansehen' onclick='anseh_rech($erg[0]);'></td>\n";

  print "<td style='width:0.7cm;text-align:right'>$erg[0]</td>"; # Rechnungsnr
  # Name Frau holen
  my @erg_frau=$s->stammdaten_frau_id($erg[7]);
  print "<td style='width:3.5cm;text-align:left'>$erg_frau[1], $erg_frau[0]</td>"; # Name Frau
  # Name Krankenkasse holen
  my ($name)=$k->krankenkasse_ik("NAME",$erg[8]);
  $name = 'unbekannt' unless(defined($name));
  print "<td style='width:3.0cm;text-align:left'>$name</td>"; # Name Krankenkasse
  print "<td style='width:1.6cm;text-align:left'>$erg[1]</td>"; # Datum Rech
  my $g_preis = sprintf "%.2f",$erg[4];$g_preis =~ s/\./,/g;
  print "<td style='width:1.0cm;text-align:right'>$g_preis</td>"; # Betrag
  $erg[2] =~ s/00.00.0000//g;
  print "<td style='width:1.6cm;text-align:right'>$erg[2]</td>"; # letzte Mahn
  $erg[3] =~ s/00.00.0000//g;
  print "<td style='width:1.6cm;text-align:right'>$erg[3]</td>"; # Eingang
  my $betraggez = sprintf "%.2f",$erg[6];$betraggez=~ s/\./,/g;
  print "<td style='width:1.6cm;text-align:right'>$betraggez</td>"; # Betrag

  my $status = $l->status_text($erg[5]);
  print "<td style='width:1.5cm;text-align:left'>$status</td>"; # Status der Position
  print '</tr>';
  print "\n";
}
print '</table>';
print "\n";
print "<script>window.scrollByLines(1000);</script>";
print "</body>";
print "</html>";


