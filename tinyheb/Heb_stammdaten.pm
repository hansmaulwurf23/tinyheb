#!/usr/bin/perl -wT

# 28.02.2004
# Package um Stammdaten zu verarbeiten

# author: Thomas Baum

package Heb_stammdaten;

use strict;
use DBI;

use Heb;

my $debug = 1;
our $dbh; # Verbindung zur Datenbank
our $frau_such; # suchen von Frauen
our $max_frau=0; # maximal vergebene id

sub new {
  my($class) = @_;
  my $self = {};
  $dbh = Heb->connect;
  $frau_such = $dbh->prepare("select ID,VORNAME,NACHNAME,".
			     "DATE_FORMAT(GEBURTSDATUM_FRAU,'%d.%m.%Y'),".
			     "DATE_FORMAT(GEBURTSDATUM_KIND,'%d.%m.%Y'),".
			     "PLZ,ORT,TEL,STRASSE,BUNDESLAND,ENTFERNUNG, ".
			     "KRANKENVERSICHERUNGSNUMMER,".
			     "DATE_FORMAT(KRANKENVERSICHERUNGSNUMMER_GUELTIG,'%d.%m.%Y'),".
			     "VERSICHERTENSTATUS,".
			     "FK_KRANKENKASSE,".
			     "NAECHSTE_HEBAMME,".
			     "BEGRUENDUNG_NICHT_NAECHSTE_HEBAMME ".
			     "from Stammdaten where ".
			     "VORNAME like ? and ".
			     "NACHNAME like ? and ".
			     "GEBURTSDATUM_FRAU like ? and ".
			     "GEBURTSDATUM_KIND like ? and ".
			     "PLZ like ? and ".
			     "ORT like ? and ".
			     "STRASSE like ?;");

  bless $self, ref $class || $class;
  my $max_id = $dbh->prepare("select max(id) from Stammdaten;") or die $dbh->errstr();
  $max_id->execute() or die $dbh->errstr();
  $max_frau = $max_id->fetchrow_array();
  return $self;
}

sub stammdaten_suchfrau {
  # Sucht nach Frauen in der Datenbank

  shift; # package Namen vom stack nehmen

  $frau_such->execute(@_) or die $dbh->errstr();

}


sub stammdaten_suchfrau_next {
  my @erg = $frau_such->fetchrow_array();
  for (my $i=0;$i < $#erg;$i++) {
    if (!defined($erg[$i])) {
      $erg[$i]='';
    }
  }
  return @erg;
}


sub stammdaten_ins {
  # f�gt neue Person in Datenbank ein

  shift; # package Namen vom stack nehmen

  my($vorname,
     $nachname,
     $geburtsdatum_frau,
     $strasse,
     $plz,
     $ort,
     $tel,
     $entfernung,
     $krankenversicherungsnummer,
     $krankenversicherungsnummer_gueltig,
     $versichertenstatus,
     $fk_krankenkasse,
     $bundesland,
     $geburtsdatum_kind,
     $naechste_hebamme,
     $begruendung_nicht_naechste_hebamme,
     $datum) = @_;

  # insert an Datenbank vorbereiten
  my $stammdaten_ins = $dbh->prepare("insert into Stammdaten ".
				     "(ID,VORNAME,NACHNAME,GEBURTSDATUM_FRAU,".
				     "STRASSE,PLZ,ORT,TEL,ENTFERNUNG,".
				     "KRANKENVERSICHERUNGSNUMMER,".
				     "KRANKENVERSICHERUNGSNUMMER_GUELTIG,".
				     "VERSICHERTENSTATUS,FK_KRANKENKASSE,".
				     "BUNDESLAND,GEBURTSDATUM_KIND,".
				     "NAECHSTE_HEBAMME,".
				     "BEGRUENDUNG_NICHT_NAECHSTE_HEBAMME,".
				     "DATUM)".
				     "values (?,?,?,?,".
				     "?,?,?,?,?,".
				     "?,".
				     "?,".
				     "?,?,".
				     "?,?,".
				     "?,".
				     "?,".
				     "?);")
    or die $dbh->errstr();
  my $erg = $stammdaten_ins->execute('NULL',$vorname,$nachname,$geburtsdatum_frau,
				     $strasse,$plz,$ort,$tel,$entfernung,
				     $krankenversicherungsnummer,
				     $krankenversicherungsnummer_gueltig,
				     $versichertenstatus,$fk_krankenkasse,
				     $bundesland,$geburtsdatum_kind,
				     $naechste_hebamme,
				     $begruendung_nicht_naechste_hebamme,
				     $datum)
    or die $dbh->errstr();

    
  my $ins_id = $stammdaten_ins->{'mysql_insertid'};
  print "ergebnis $erg ins_id $ins_id<br>\n" if $debug;
  return $ins_id;
}

sub stammdaten_update {
  # speichert ge�nderte Daten ab
  shift;
  # update an Datenbank vorbereiten
  my $stammdaten_up = $dbh->prepare("update Stammdaten set ".
				    "VORNAME=?,NACHNAME=?,GEBURTSDATUM_FRAU=?,".
				    "STRASSE=?,PLZ=?,ORT=?,TEL=?,ENTFERNUNG=?,".
				    "KRANKENVERSICHERUNGSNUMMER=?,".
				    "KRANKENVERSICHERUNGSNUMMER_GUELTIG=?,".
				    "VERSICHERTENSTATUS=?,FK_KRANKENKASSE=?,".
				    "BUNDESLAND=?,GEBURTSDATUM_KIND=?,".
				    "NAECHSTE_HEBAMME=?,".
				     "BEGRUENDUNG_NICHT_NAECHSTE_HEBAMME=?,".
				    "DATUM=? ".
				    "where ID=?;")
    or die $dbh->errstr();
  my $erg = $stammdaten_up->execute(@_)
    or die $dbh->errstr();

  print "ergebnis $erg<br>\n" if $debug;
  return $erg;
}


sub stammdaten_delete {
  # l�scht Datensatz aus der Datenbank
  shift;
  # delete an Datenbank vorbereiten
  my $stammdaten_del = $dbh->prepare("delete from Stammdaten ".
				     "where ID=?;")
    or die $dbh->errstr();
  my $erg = $stammdaten_del->execute(@_)
    or die $dbh->errstr();
   
  print "ergebnis $erg<br>\n" if $debug;
  return $erg;
}  


sub stammdaten_frau_id {
  # holt alle Daten zu einer Frau
  shift;

  my ($id) = @_;

  my $frau_id = $dbh->prepare("select VORNAME,NACHNAME,".
			      "DATE_FORMAT(GEBURTSDATUM_FRAU,'%d.%m.%Y'),".
			      "DATE_FORMAT(GEBURTSDATUM_KIND,'%d.%m.%Y'),".
			      "PLZ,ORT,TEL,STRASSE,BUNDESLAND,ENTFERNUNG, ".
			      "KRANKENVERSICHERUNGSNUMMER,".
			      "DATE_FORMAT(KRANKENVERSICHERUNGSNUMMER_GUELTIG,'%d.%m.%Y'),".
			      "VERSICHERTENSTATUS,".
			      "FK_KRANKENKASSE,".
			      "NAECHSTE_HEBAMME,".
			      "BEGRUENDUNG_NICHT_NAECHSTE_HEBAMME ".
			      "from Stammdaten where ".
			      "ID = $id;")
    or die $dbh->errstr();
  $frau_id->execute() or die $dbh->errstr();
  my @erg = $frau_id->fetchrow_array();
  for (my $i=0;$i < $#erg;$i++) {
    if (!defined($erg[$i])) {
      $erg[$i]='';
    }
  }
  return @erg;
}


sub max {
  # gibt die h�chste ID zur�ck
  return $max_frau;
}
1;