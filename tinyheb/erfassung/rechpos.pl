#!/usr/bin/perl -wT
#-wT
#-d:ptkdb
#-d:DProf  

# author: Thomas Baum
# 09.04.2005
# Rechnungspositionen erfassen f�r einzelne Rechnungsposition

use strict;
use CGI;
use Date::Calc qw(Today Day_of_Week Delta_Days);

use lib "../";
use Heb_stammdaten;
use Heb_datum;
use Heb_leistung;
use Heb;

my $q = new CGI;
my $s = new Heb_stammdaten;
my $d = new Heb_datum;
my $l = new Heb_leistung;
my $h = new Heb;

my $debug=1;
my $script='';
my $hint='';

my $TODAY = $d->convert_tmj(sprintf "%4.4u-%2.2u-%2.2u",Today());
my $TODAY_jmt = sprintf "%4.4u%2.2u%2.2u",Today();
my @aus = ('Neu','�ndern');

my $frau_id = $q->param('frau_id') || 0;
my $posnr = $q->param('posnr') || '';
my $begruendung = $q->param('begruendung') || '';
my $datum = $q->param('datum') || $TODAY;
$datum = $d->convert_tmj($datum);
my $zeit_von = $q->param('zeit_von') || '';
my $zeit_bis = $q->param('zeit_bis') || '';
my $entfernung_tag = $q->param('entfernung_tag') || 0;
my $entfernung_nacht = $q->param('entfernung_nacht') || 0;
my $leist_id = $q->param('leist_id') || 0;
my $anzahl_frauen = $q->param('anzahl_frauen') || '';
my $strecke = $q->param('strecke') || 'gesamt';
my $abschicken = $q->param('abschicken');
my $auswahl = $q->param('auswahl') || 'Anzeigen';
my $func = $q->param('func') || 0;

print $q->header ( -type => "text/html", -expires => "-1d");

if ($auswahl eq 'Neu' && defined($abschicken)) {
  speichern();
  $entfernung_tag=0;
  $entfernung_nacht=0;
}

if ($auswahl eq '�ndern' && defined($abschicken)) {
  aendern();
  $entfernung_tag=0;
  $entfernung_nacht=0; 
  $auswahl='Neu';
}

if ($func == 3) {
  loeschen();
}

if ($func == 2) {
  hole_daten();
  $auswahl='�ndern';
}

print '<head>';
print '<title>Rechnungen</title>';
print '<script language="javascript" src="../Heb.js"></script>';
print '<script language="javascript" src="leistungen.js"></script>';
print '</head>';

# style-sheet ausgeben
print <<STYLE;
  <style type="text/css">
  .disabled { color:black; background-color:gainsboro}
  .invisible { color:white; background-color:white;border-style:none}
  .enabled { color:black; background-color:white}
  </style>
STYLE

# Alle Felder zur Eingabe ausgeben
print '<body id="rechpos_window" bgcolor=white>';

# Formular f�r eigentliche Erfassung ausgeben
print '<form name="rechpos" action="rechpos.pl" method="get" target=rechpos bgcolor=white>';
print '<table border="0" width="100%" align="left">';

# Leistungspositionen 
# z1 s1
print '<h3>Leistungspositionen</h3>';
print '<table border="0" align="left">';
print '<tr>';
print '<td><table border="0" align="left">';
print '<tr>';
print '<td><b>Datum:</b></td>';
print '<td><b>Posnr:</b></td>';
print '<td><b>E. Preis:</b></td>';
print '<td><b>Wochentag:</b></td>';
print '</tr>';
print "\n";

print '<tr>';
print "<td><input type='text' name='datum' value='$datum' size='10' onblur='datum_check(this);wo_tag(document.rechpos.datum.value,document.rechpos.zeit_von.value,document.rechpos);'></td>";
# Auswahlbox f�r Positionsnummern
printauswahlboxposnr();

print "<td><input type='text' class='disabled' disabled name='preis' value='' size='6'></td>";
print "<td><input type='text' class='disabled' disabled name='wotag' value='' size='17'></td>";

print '</tr>';
print '</table>';


print '<tr><td><table border="0" align="left">';
print '<td><b>Uhrzeit von</b></td>';
print '<td><b>Uhrzeit bis</b></td>';
print '<td><b>Dauer</b></td>';
print '<td><b>Begr�ndung</b></td>';
#print '<td><b>ID Leistung</b></td>';
#print '<td><b>ID Frau</b></td>';
print '<tr>';

print '<tr>';
print "<td><input type='text' disabled class='disabled' name='zeit_von' value='$zeit_von' size='5' onblur='uhrzeit_check(this);wo_tag(document.rechpos.datum.value,document.rechpos.zeit_von.value,document.rechpos);'></td>";
print "<td><input type='text' disabled class='disabled' name='zeit_bis' value='$zeit_bis' size='5' onblur='uhrzeit_check(this)'></td>";
print "<td><input type='text' class='disabled' disabled name='dauer' value='' size='5'></td>";
printauswahlboxbegr();
print "<td><input type='hidden' name='leist_id' value='$leist_id' size='5'></td>";
print "<td><input type='hidden' name='frau_id' value='$frau_id' size='5'></td>";
print '</tr>';

print '<tr>';
print '<td><b>Kilometer Tag</b></td>';
print '<td><b>Kilometer Nacht</b></td>';
print '<td><b>Anzahl Frauen</b></td>';
print '<td><b>Strecke</b></td>';
print '</tr>';

print '<tr>';
print "<td><input type='text' name='entfernung_tag' value='$entfernung_tag' size='6'></td>";
print "<td><input type='text' name='entfernung_nacht' value='$entfernung_nacht' size='6'></td>";
print "<td><input type='text' name='anzahl_frauen' value='$anzahl_frauen' size='2'></td>";
print "<td><input type='radio' name='strecke' value='gesamt' checked>gesamt";
print "<input type='radio' name='strecke' value='anteilig'>anteilig";
print "</td>";
print "</tr>";
print '</table>';
print "\n";




# Zeile mit Kn�pfen f�r unterschiedliche Funktionen
print '<tr>';
print '<td colspan 3>';
print '<table border="0" align="left">';
print '<tr>';
print '<td>';
print "<select name='auswahl' size=1 onChange='auswahl_wechsel(document.rechpos)'>";
my $i=0;
while ($i <= $#aus) {
  print '<option';
  print ' selected' if ($aus[$i] eq $auswahl);
  print '>';
  print $aus[$i];
  print '</option>';
  $i++;
}
print '</select>';
print '</td>';

print '<td><input type="submit" name="abschicken" value="Speichern"></td>';
print '<td><input type="button" name="hauptmenue" value="Hauptmenue" onClick="haupt();"></td>';
print '<td><input type="button" name="stammdaten" value="Stammdaten" onClick="stamm(frau_id.value,document.rechpos);"></td>';
print '<td><input type="button" name="Drucken" value="Drucken" onClick="druck(document.rechpos);"></td>';
print '</tr>';
print '</table>';
print '</form>';
print '</tr>';
print '</table>';
# //  auswahl_wechsel(document.rechpos);
print <<SCRIPTE;
<script>
//  set_focus(document.krankenkassen);
  open("list_posnr.pl?frau_id=$frau_id","list_posnr");
  posnr_wechsel(document.rechpos); // funktion wurde dynamisch generiert.
  wo_tag(document.rechpos.datum.value,document.rechpos.zeit_von.value,document.rechpos);
  document.rechpos.datum.select();
  document.rechpos.datum.focus();
</script>
SCRIPTE
if ($hint ne '') {
  print "<script>alert('$hint');</script>";
}
print "</body>";
print "</html>";



#---------------------------------------------------------------------

sub printauswahlboxbegr {
   print "<td><select name='begruendung' size=1>";
   $h->parm_such('BEGRUENDUNG');
   print "<option value=''> </option>";
   while(my $text=$h->parm_such_next()) {
     $text = substr($text,0,40);
     print "<option value='$text' ";
     print ' selected' if($text eq $begruendung);
     print ' >';
     print "$text";
     print '</option>';
   }
   print "</select>";
}


sub printauswahlboxposnr {
  $script='<script>function posnr_wechsel(formular) {';
  print "<td><select name='posnr' onchange='posnr_wechsel(document.rechpos)' size=1>";
  print "<option value=''> </option>";
  $script .= "if(formular.posnr.value == '') {formular.preis.value='';}\n";
  printbox('A');
  printbox('B');
  printbox('C');
  printbox('D');
  printbox('M');
  $script .= "}\n</script>";
  print "</select>";
  print $script;

}

sub printbox {
  my ($wahl) = @_;
  #  print "WAHL $wahl\n";
  $l->leistungsart_such($TODAY_jmt,$wahl);
  while (my @werte = $l->leistungsart_such_next() ) {  
    my ($l_posnr,$l_bez,$l_preis,$l_fuerzeit)=($werte[1],$werte[21],$werte[4],$werte[9]);
    print "<option value='$l_posnr' ";
    print ' selected' if ($posnr eq $l_posnr);
    print " >";
    $script .= "if(formular.posnr.value == '$l_posnr') {formular.preis.value=$l_preis;\n";
    if ($l_fuerzeit > 0) {
      $script .= "formular.zeit_von.disabled=false;\n";
      $script .= "formular.zeit_bis.disabled=false;\n";
      $script .= "var zl_tag = document.getElementsByName('zeit_von');\n";
      $script .= "zl_tag[0].className='enabled';\n";
      $script .= "var zl_tag = document.getElementsByName('zeit_bis');\n";
      $script .= "zl_tag[0].className='enabled';\n";
      $script .= "formular.zeit_von.focus();\n";
    } else {
      $script .= "formular.zeit_von.disabled=true;\n";
      $script .= "formular.zeit_bis.disabled=true;\n";
      $script .= "var zl_tag = document.getElementsByName('zeit_von');\n";
      $script .= "zl_tag[0].className='disabled';\n";
      $script .= "var zl_tag = document.getElementsByName('zeit_bis');\n";
      $script .= "zl_tag[0].className='disabled';\n";
      $script .= "formular.begruendung.focus();\n";
    }
    $script.="}\n";
    print "$l_posnr&nbsp;$l_bez";
    print '</option>';
  }
}



#---------------------------------------------------
# Routinen zum Speichern und �ndern
sub speichern {

  my $zuschlag='';

  if ($frau_id == 0) {
    $hint .= "Bitte Frau ausw�hlen";
    return;
  }
  if ($posnr eq '') {
    $hint .= "Keine PosNr. gew�hlt, nichts gespeichert";
    return;
  }
  # Datum konvertieren
  my $datum_l = $d->convert($datum);
  # Entfernung konvertieren
  $entfernung_tag =~ s/,/\./g;
  $entfernung_nacht =~ s/,/\./g;
  # entfernung berechnen
  $anzahl_frauen++ if($anzahl_frauen eq '' || $anzahl_frauen == 0);
  if ($strecke eq 'gesamt') {
    $entfernung_tag /= $anzahl_frauen;
    $entfernung_nacht /= $anzahl_frauen;
  }

  # Wenn Sonntag angegeben ist, pr�fen ob Sonntag und richtige PosNr
  my $dow=Day_of_Week($d->jmt($datum));
  # 1 == Montag 2 == Dienstag, ..., 7 == Sonntag
  my ($l_samstag,$l_sonntag) = $l->leistungsart_such_posnr('SAMSTAG,SONNTAG',$posnr,$datum_l);
  if ($dow == 6 && $l_samstag =~ /(\+{0,1})(\d{1,3})/ && $2 > 0 && $d->zeit_h($zeit_von) >= 12) {
    # print "Samstag erkannt\n";
    # pr�fen ob es sich um andere Positionsnummer handelt
    if ($1 ne '+')  {
      $hint .= "Positionsnummer $posnr w/ Samstag ersetzt durch $2";
      $posnr = $2;
    } else {
      $zuschlag = $2;
    }
  }

  # pr�fen auf Sonntag oder Feiertag
  if (($dow == 7 || ($d->feiertag_datum($datum)>0)) && $l_sonntag =~ /(\+{0,1})(\d{1,3})/ && $2 > 0) {
    # print "Sonntag erkannt\n";
    # pr�fen ob es sich um andere Positionsnummer handelt
    if ($1 ne '+')  {
      $hint .= "Positionsnummer $posnr w/ Sonntag oder Feiertag ersetzt durch $2";
      $posnr = $2;
    } else {
      $zuschlag = $2;
    }
  }    
  
  my ($material) = $l->leistungsart_such_posnr('LEISTUNGSTYP',$posnr,$datum_l);

  if ($material ne 'M') {
    # nur pr�fen, wenn kein Material abgerechnet wird.
    if ($l->leistungsart_pruef_zus($posnr,'SONNTAG') && ($dow==7 || ($d->feiertag_datum($datum)))) {
      # alles ok
    } elsif ($l->leistungsart_pruef_zus($posnr,'SAMSTAG') && $dow==6 && $d->zeit_h($zeit_von) >= 12) {
      # alles ok
    } elsif ($l->leistungsart_pruef_zus($posnr,'NACHT') && ($d->zeit_h($zeit_von) <= 8 || $d->zeit_h($zeit_von) >= 20)) {
      # alles ok
    } elsif (($l->leistungsart_pruef_zus($posnr,'SONNTAG') || $l->leistungsart_pruef_zus($posnr,'SAMSTAG') || $l->leistungsart_pruef_zus($posnr,'NACHT')) && ($dow < 6 || $dow==6 && $d->zeit_h($zeit_von) < 12) || $d->zeit_h($zeit_von)>8 && $d->zeit_h($zeit_von) > 20) {
      $hint .= "Positionsnummer nur an bestimmten Tagen, es wurde nichts gespeichert";
      return;
    }
  }



  # Preis berechnen in Abh�ngigkeit der Dauer
  my $preis=0;
  my ($l_epreis,$l_fuerzeit) = $l->leistungsart_such_posnr('EINZELPREIS,FUERZEIT',$posnr,$datum_l);
  if ($l_fuerzeit > 0) {
    my $dauer = $d->dauer_m($zeit_bis,$zeit_von);
    $preis = sprintf "%3.3u",($dauer / $l_fuerzeit);
    $preis++ if ($preis*$l_fuerzeit < $dauer);
    $preis = $preis*$l_epreis;
  } else {
    $preis = $l_epreis;
  }
  


  # einf�gen in Datenbank
  $leist_id=$l->leistungsdaten_ins($posnr,$frau_id,$begruendung,$datum_l,$zeit_von.':00',$zeit_bis.':00',$entfernung_tag,$entfernung_nacht,$anzahl_frauen,$preis,'',10);

  # pr�fen ob einmaliger Zuschlag gerechnet werden muss
  # wird genau dann gemacht, wenn die Positionsnummer 
  # noch nicht erfasst ist
  my ($einmal_zus) = $l->leistungsart_such_posnr('EINMALIG',$posnr,$datum_l);
  if ($einmal_zus =~ /(\+{0,1})(\d{1,3})/ && $2 > 0) {
    $zuschlag=$2;
    $zuschlag=0 if ($l->leistungsdaten_werte($frau_id,"POSNR","POSNR=$zuschlag"));
  }

  # pr�fen ob Zuschlag gespeichert werden muss
  if ($zuschlag ne '' && $zuschlag > 0) {
    my ($prozent,$ze_preis) = $l->leistungsart_such_posnr('PROZENT,EINZELPREIS',$zuschlag,$datum_l);
    my $preis_neu = 0;
    $preis_neu = $preis * $prozent if ($prozent > 0);
    $preis_neu = $ze_preis if ($ze_preis > 0);
    # Entfernung darf nicht 2mal gerechnet werden
    $entfernung_nacht=0;
    $entfernung_tag=0;
    $leist_id=$l->leistungsdaten_ins($zuschlag,$frau_id,$begruendung,$datum_l,$zeit_von.':00',$zeit_bis.':00',$entfernung_tag,$entfernung_nacht,$anzahl_frauen,$preis_neu,'',10);
    $hint .= " Zuschlag prozentual wurde zus�tzlich gespeichert" if ($prozent > 0);
    $hint .= " Zuschlag wurde zus�tzlich gespeichert" if ($ze_preis > 0);
  }

  # pr�fen, ob Materialpauschale gerechnet werden muss
  # wird genau dann gemacht, wenn Zusatzgeb�hr1 auf Material verweisst.
  # und keine Abh�ngigkeit zur Zeit besteht
  my ($mat_zus,$mat_zus2) = $l->leistungsart_such_posnr('ZUSATZGEBUEHREN1,ZUSATZGEBUEHREN2',$posnr,$datum_l);
  if ($mat_zus2 eq '' && $mat_zus =~ /(\+M)(\d{1,3})/ && $2 > 0) {
    my $m_zus='M'.$2;
    # Entfernung nicht 2mal rechnen
    $entfernung_nacht=0;
    $entfernung_tag=0;
    my ($ze_preis) = $l->leistungsart_such_posnr('EINZELPREIS',$m_zus,$datum_l);
    $leist_id=$l->leistungsdaten_ins($m_zus,$frau_id,$begruendung,$datum_l,$zeit_von.':00',$zeit_bis.':00',$entfernung_tag,$entfernung_nacht,$anzahl_frauen,$ze_preis,'',10);
    $hint .= " Materialpauschale wurde zus�tzlich gespeichert";
  }


  # pr�fen, ob Materialpauschale f�r Zuschlag gerechnet werden muss
  # hier mit Vergleichswerten
  ($mat_zus,$mat_zus2) = $l->leistungsart_such_posnr('ZUSATZGEBUEHREN1,ZUSATZGEBUEHREN2',$zuschlag,$datum_l);
  matpausch($mat_zus,$mat_zus2,$datum_l);
  ($mat_zus,$mat_zus2) = $l->leistungsart_such_posnr('ZUSATZGEBUEHREN3,ZUSATZGEBUEHREN4',$zuschlag,$datum_l);
  matpausch($mat_zus,$mat_zus2,$datum_l);
  

  $entfernung_tag*=$anzahl_frauen;
  $entfernung_nacht*=$anzahl_frauen;
  $strecke='gesamt';

}


sub matpausch {
  # pr�fen, ob Materialpauschale f�r Zuschlag gerechnet werden muss
  # wird genau dann gemacht, wenn Zusatzgeb�hr bei Zuschlag 
  # auf Material verweisst und Abh�ngigkeit zur Zeit besteht
  # der Vergleichswert wird aus Zusatzvermerk ermittelt
  my ($mat_zus,$mat_zus2,$datum_l) = @_;
  if ($mat_zus2 ne '' && $mat_zus =~ /(\+M)(\d{1,3})/ && $2 > 0) {
    my $m_zus='M'.$2;
    my $comp=0; # Flag ob gespeichert werden muss oder nicht
    # operator f�r Vergleich ermitteln
    my ($op,$op_wert,$op_vgltyp) = 
      $mat_zus2 =~ /([>,<,=]{1})(\d{1,3})(\D{1,2})/;
    if ($op_vgltyp eq 'GK') { # Geburtsdatum Kind
      # geburtsdatum kind ermitteln
      my @dat_frau = $s->stammdaten_frau_id($frau_id);
      my $geb_kind = $dat_frau[3];
      $geb_kind = $d->convert($geb_kind);
      # Wieviele Tage liegen zwischen $datum_l und Geburtsdatum Kind?
      my $days = Delta_Days(unpack('A4xA2xA2',$datum_l),unpack('A4xA2xA2',$geb_kind));
      $comp = 1 if (abs($days)<$op_wert && $op eq '<');
      $comp = 1 if (abs($days)==$op_wert && $op eq '=');
      $comp = 1 if (abs($days)>$op_wert && $op eq '>');
    }
    
    if ($comp) { # es muss gespeichert werden
      # Entfernung nicht 2mal rechnen
      $entfernung_nacht=0;
      $entfernung_tag=0;
      my ($ze_preis) = $l->leistungsart_such_posnr('EINZELPREIS',$m_zus,$datum_l);
      $leist_id=$l->leistungsdaten_ins($m_zus,$frau_id,$begruendung,$datum_l,$zeit_von.':00',$zeit_bis.':00',$entfernung_tag,$entfernung_nacht,$anzahl_frauen,$ze_preis,'',10);
      $hint .= " Abh�ngige Materialpauschale wurde zus�tzlich gespeichert";
    }
  }
}


sub loeschen {
#  print "loeschen\n";
  $l->leistungsdaten_delete($frau_id,$leist_id);
  $leist_id=0;
}

sub aendern {
  return if ($frau_id==0 || $leist_id ==0);
  loeschen();
  speichern();

}


sub hole_daten {
#  print "hole daten\n";
  my @erg=$l->leistungsdaten_such_id($leist_id);
  $frau_id = $erg[2] || 0;
  $posnr = $erg[1] || '';
  $begruendung = $erg[3] || '';
  $datum = $erg[4];
  $zeit_von = $erg[5] || '';
  $zeit_bis = $erg[6] || '';
  $anzahl_frauen = $erg[9] || '1';
  $entfernung_tag = $erg[7]*$anzahl_frauen || 0;
  $entfernung_tag = sprintf "%.2f",$entfernung_tag;
  $entfernung_tag =~ s/\./,/g;
  $entfernung_nacht = $erg[8]*$anzahl_frauen || 0;
  $entfernung_nacht = sprintf "%.2f",$entfernung_nacht;
  $entfernung_nacht =~ s/\./,/g;
  $strecke = 'gesamt';
}
