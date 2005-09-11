#!/usr/bin/perl -wT
#-w
#-d:ptkdb
#-d:DProf  

# author: Thomas Baum
# 29.02.2004
# Auswahl einer Frau aus den Stammdaten

use strict;
use CGI;

use lib "../";
use Heb_stammdaten;
use Heb_datum;
use Heb_krankenkassen;
use Heb_leistung;

my $q = new CGI;
my $s = new Heb_stammdaten;
my $d = new Heb_datum;
my $k = new Heb_krankenkassen;
my $l = new Heb_leistung;

my $debug=1;

my $vorname = $q->param('vorname') || '';
my $nachname = $q->param('nachname') || '';
my $geb_f = $q->param('geb_f') || '';
my $geb_k = $q->param('geb_k') || '';
my $ort = $q->param('ort') || '';
my $plz = $q->param('plz') || '';
my $strasse = $q->param('strasse') || '';

my $suchen = $q->param('suchen');
my $abschicken = $q->param('abschicken');

my $kk_ik = '';
my $kk_name = '';
my $kk_plz = '';
my $kk_ort = '';
my $kk_strasse = '';

print $q->header ( -type => "text/html", -expires => "-1d");

# Alle Felder zur Eingabe ausgeben
print '<head>';
print '<title>Frau suchen</title>';
print '<script language="javascript" src="../Heb.js"></script>';
print '<script language="javascript" src="stammdaten.js"></script>';
print '</head>';
print '<body bgcolor=white>';
print '<div align="center">';
print '<h1>Frau suchen</h1>';
print '<hr width="100%">';
print '</div><br>';
# Formular ausgeben
print '<form name="frau_suchen" action="frauenauswahl.pl" method="get" target=_self>';
print '<h3>Suchkriterien:</h3>';
print '<table border="0" width="500" align="left">';

# Name, Ort, PLZ, IK, als Suchkriterien vorgeben
# z1 s1
print '<tr>';
print '<td>';
print '<table border="0" align="left">';
print '<tr>';
print "<td><b>Vorame</b></td>\n";
print "<td><b>Nachname</b></td>\n";
print "<td><b>Geb. Frau</b></td>\n";
print "<td><b>Geb. Kind</b></td>\n";
print "<td><b>PLZ</b></td>\n";
print "<td><b>Ort</b></td>\n";
print "<td><b>Strasse</b></td>\n";
print '</tr>';
print "\n";

print '<tr>';
print "<td><input type='text' name='vorname' value='$vorname' size='15'></td>";
print "<td><input type='text' name='nachname' value='$nachname' size='15'></td>";
print "<td><input type='text' name='geb_f' value='$geb_f' size='12' onBlur='datum_check(this)'></td>";
print "<td><input type='text' name='geb_k' value='$geb_k' size='12' onBlur='datum_check(this)'></td>";
print "<td><input type='text' name='plz' value='$plz' size='7' onBlur='plz_check(this)'></td>";
print "<td><input type='text' name='ort' value='$ort' size='10'></td>";
print "<td><input type='text' name='strasse' value='$strasse' size='10'></td>";
print '</table>';
print "\n";

# Zeile mit Kn�pfen f�r unterschiedliche Funktionen
print '<tr>';
print '<td>';
print '<table border="0" align="left">';
print '<tr>';
print '<td><input type="submit" name="suchen" value="Suchen"></td>';
print '<td>';
print '<input type="button" name="zurueck" value="Zur�ck" onClick="self.close()"></td>';
print '</tr>';
print '</table>';

# Pr�fen, ob gesucht werden soll
if (defined($suchen)) {
  # alle Frauen ausgeben, die den Kriterien entsprechen
  print '<tr>';
  print '<td>';
  print '<table border="1" align="left">';
  print '<tr>';
  print "<td><b>Vorame</b></td>\n";
  print "<td><b>Nachname</b></td>\n";
  print "<td><b>Geb. Frau</b></td>\n";
  print "<td><b>Geb. Kind</b></td>\n";
  print "<td><b>PLZ</b></td>\n";
  print "<td><b>Ort</b></td>\n";
  print "<td><b>Strasse</b></td>\n";
  print "<td><b>Status Bearb.</b></td>\n";
  print '</tr>';
  # suchkriterien erweitern
  $vorname='%'.$vorname.'%';
  $nachname='%'.$nachname.'%';
  $geb_f = $d->convert($geb_f) if ($geb_f ne '');
  $geb_f='%'.$geb_f.'%';
  $geb_k = $d->convert($geb_k) if ($geb_k ne '');
  $geb_k='%'.$geb_k.'%';
  $plz='%'.$plz.'%';
  $ort='%'.$ort.'%';
  $strasse='%'.$strasse.'%';
  $s->stammdaten_suchfrau($vorname,$nachname,$geb_f,$geb_k,$plz,$ort,$strasse);
  while (my ($f_id,
	     $f_vorname,
	     $f_nachname,
	     $f_geb_f,
	     $f_geb_k,
	     $f_plz,
	     $f_ort,
	     $f_tel,
	     $f_strasse,
	     $f_bundesland,
	     $f_entfernung,
	     $f_krankennr,
	     $f_krankennrguelt,
	     $f_verstatus,
	     $f_fk_krankenkasse,
	     $f_nae_heb,
	     $f_begr_nicht_nae_heb) = $s->stammdaten_suchfrau_next) {
    $f_entfernung =~ s/\./,/g;
    # Krankenkassen Infos holen
    if ($f_fk_krankenkasse != 0) {
      ($kk_ik,$kk_name,$kk_plz,$kk_ort,$kk_strasse) =
	 $k->krankenkasse_ik('IK,NAME,PLZ_HAUS,ORT,STRASSE',$f_fk_krankenkasse);
      $kk_strasse = '' if (!defined($kk_strasse));
    } else {
      ($kk_ik,$kk_name,$kk_plz,$kk_ort,$kk_strasse) = ('','','','','');
    }
    # Status zu Erfassung ermitteln
    my $status=$l->status_text(10);
    if($l->leistungsdaten_werte($f_id,'distinct status','','status')) {
      ($status)=$l->leistungsdaten_werte_next();
      $status=$l->status_text($status);
    } 
    print '<tr>';
    $f_vorname=' ' if (!defined($f_vorname));print "<td>$f_vorname</td>";
    $f_nachname=' ' if (!defined($f_nachname));print "<td>$f_nachname</td>";
    print "<td>$f_geb_f</td>";
    print "<td>$f_geb_k</td>";
    print "<td>$f_plz</td>";
    $f_ort=' ' if (!defined($f_ort));print "<td>$f_ort</td>";
    $f_strasse=' ' if (!defined($f_strasse));print "<td>$f_strasse</td>";
    print "<td>$status</td>";
    print '<td><input type="button" name="waehlen" value="Ausw�hlen"';
    print "onclick=\"frau_eintrag('$f_id');self.close();\">";
    print "</td>";
    print "</tr>\n";
  }
}
print '</form>';
print '</tr>';
print '</table>';

print <<SCRIPTE;
<script>
window.focus();
</script>
SCRIPTE
print "</body>\n";
print "</html>";
