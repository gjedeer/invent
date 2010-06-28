#! /usr/bin/perl
# Autorzy: Piotr Kłosowski <pklosows@press.umcs.lublin.pl> Wersja
# pierwsza działająca (0.1a): 1. lutego 1998 r.  
#		Mirosław „Minio” Zalewski <miniopl@gmail.com> http://minio.xt.pl -
#		Wydanie drugie poprawione (0.2): 15 stycznia 2010 r.
#		UWAGA! Od teraz skrypt domyślnie modyfikuje plik podany jako
#		argument (ale wcześniej tworzy kopię zapasową). Stare zachowanie
#		(wypisanie na STDOUT) można wymusić poprzez podanie - (myślnika)
#		jako pierwszego argumentu.

# Skrypt "porzadki" jest napisanym od nowa następcą awkowego skryptu
# "normtext.awk" z lata 96 r., który z kolei był rozwinięciem pomysłów
# Tomasza Przechlewskiego.

# Filtr do robienia porządków w duchu TeX-a w plikach tekstowych
# (przede wszystkim znaki przestankowe i wstawianie niełamliwych spacji) 
# Podstawowe zastosowanie to pomoc w konwersji tekstów napisanych w
# różnych edytorach. 

# Główne założenia i ograniczenia:
# - tekst jest podzielony na akapity pustymi wierszami,
# - tekst jest w języku polskim (kodowanie iso-latin2),
# - wnętrze akapitów z wyjątkiem linijek zakończonych przez "\\" może ulegać 
#   przeformatowaniu (próba usunięcia przeniesień wyrazów) (uwaga na ew. 
#   znaki komentarza - "%"!)

use strict;
#--------------------------------------------------
# use warnings;
# use utf8;
#-------------------------------------------------- 

use Cwd 'abs_path';
use Time::localtime;
use File::Copy;
use File::Basename;
use File::Compare;

# ========================================================================
# Stałe wykorzystywane w skrypcie

my $Odstep = "[\ \t~]";
my $NieOdstep = "[^\ \t~]";
my $Spojnik = "[aAiIoOuUwWzZ]";
my $Litera = "[a-zA-ZąĄćĆęĘłŁńŃóÓśŚżŻźŹ]";
my $NieLitera = "[^a-zA-ZąĄćĆęĘłŁńŃóÓśŚżŻźŹ]";
my $DuzaLitera = "[A-ZĄĆĘŁŃÓŚŻŹ]";
my $MalaLitera = "[a-ząćęłńóśżź]";
my $Cyfra = "[0-9]";
my $CyfraRzymska = "[IVXL]";
 
my $PominSrodowisko ="(tabular|array|tabbing|figure|equation|eqenarray|verbatim)";

my $FILE;
my $BACKUP;
my @file_content;

# ========================================================================
sub PolaczWiersze {
# usunięcie przeniesień	
	s/($Litera)-$Odstep*\n$Odstep*($MalaLitera)/$1$2/g;
	s/($Litera)-$Odstep*\n$Odstep*-($Litera)/$1\\dywiz $2/g;
	s/\n$Odstep+\n/\\\\\ \\\\\ /g;
	tr/\n/\ /;
};
# ========================================================================
sub PoprawAkapit {
	&PoprawNielamliwe;
	&PoprawPrzestankowe;
};
# ------------------------------------------------------------------------
# Niełamliwe spacje
sub PoprawNielamliwe {
	&NielamliweSpojniki;
	&NielamliweInicjaly;
	&NielamliweDaty;
#	&NielamliweBibliograf;
	&NielamliweJednostki;
	&NielamliweTytuly;
#	&NielamliweInne;
#	&NielamliweWyliczenia;
};
#  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  
# niełamliwe spacje przy słowach jednoliterowych (uwaga na cyfrę rzymską "I")
sub NielamliweSpojniki {
	s/([\(,]|$Odstep+)($Spojnik)$Odstep+($Spojnik)$Odstep+/$1$2~$3~/g;
	s/([\(,]|$Odstep+)($Spojnik)$Odstep+/$1$2~/g;
};
#  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  
# niełamliwe spacje przy inicjałach
sub NielamliweInicjaly {
	s/($DuzaLitera)\.$Odstep*($DuzaLitera)\.$Odstep*($DuzaLitera$MalaLitera)/$1\.~$2\.~$3/g;
	s/($DuzaLitera)\.$Odstep*($DuzaLitera$MalaLitera)/$1\.~$2/g;
};
#  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  
# niełamliwe spacje przy skrótach związanych z pisownią daty
sub NielamliweDaty {
	s/($Cyfra)$Odstep*(r|w)\./$1~$2\./g;
	s/($NieLitera)(r|w)\.$Odstep*($Cyfra)/$1$2\.~$3/g;
	s/($CyfraRzymska)$Odstep+w\./$1~w\./g;
};
#  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  
# niełamliwe spacje przy skrótach występujących w zapisie bibliograficznym
sub NielamliweBibliograf {
	s/($NieLitera)([sStTzZ]|ss|SS|[vV]ol|[aA]rt)\.$Odstep*($Cyfra|$CyfraRzymska)/$1$2\.~$3/g;
};
#  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  
# niełamliwe spacje między liczbą a skrótem jednostki miary
my $DuzoZer = "tys\\.|mln|mld";
sub NielamliweJednostki {
	s/($Cyfra)$Odstep*($DuzoZer)/$1~$2/g;
	s/($Cyfra|$DuzoZer)$Odstep*([kdcm]?[glmsVAW])($NieLitera)/$1~$2$3/g;
	s/($Cyfra|$DuzoZer)$Odstep*(zł|gr|ha|t|mies|godz|min|sek)($NieLitera)/$1~$2$3$4/g;
};
#  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  
# niełamliwe spacje po tytułach
sub NielamliweTytuly {
	s/($NieLitera)(mgr|dr|prof\.|hab\.|bp|ks\.|o+\.|św\.|prez\.|przew\.|red\.|min\.|gen\.|płk|mjr|kpt\.)$Odstep+/$1$2~/g;
}
#  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  
# niełamliwe spacje przy innych skrótach
sub NielamliweInne {
	s/($NieLitera)([Tt]ab\.|[Tt]abl\.|[Rr]y[cs]\.|[Rr]ozdz\.|[Nn]r)$Odstep*($Cyfra)/$1$2~$3/g;
};
#  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  
# niełamliwe półfirety przy wyliczeniach
sub NielamliweWyliczenia {
	s/^-+$Odstep*/---\\enspace\ /;
	s/^($Cyfra+[\.\)\/])$Odstep+/$1\\enspace\ /;
	s/^($Litera[\.\)\/])[\ \t]+/$1\\enspace\ /;
};
# ------------------------------------------------------------------------
# Znaki przestankowe
sub PoprawPrzestankowe {
#	&PrzestankowePolpauzy;
#	&PrzestankowePauzy;
#	&PrzestankoweDywizy;
	&PrzestankoweCudzyslowy;
	&PrzestankoweWielokropki;
#	&PrzestankoweOdstepy;
#	&PrzestankoweSymbole;
};
#  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  
# półpauzy
sub PrzestankowePolpauzy {
	s/($Cyfra)$Odstep*-$Odstep*($Cyfra)/$1--$2/g;
};
#  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  
# pauzy
sub PrzestankowePauzy {
	s/$Odstep+-$Odstep+/\ ---\ /g;
	s/$Odstep+---/~---/g;
};
#  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  
# dywizy
sub PrzestankoweDywizy {
	s/($Litera)-($Litera)/$1\\dywiz $2/g;
};
#  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  
# cudzysłowy
sub PrzestankoweCudzyslowy {
	s/^\"/,,/;
	s/($NieLitera)\"($Litera)/$1,,$2/g;
	s/($Odstep)\"($NieOdstep)/$1,,$2/g;
	s/\"$/''/;
	s/($Litera)\"($NieLitera)/$1''$2/g;
	s/($NieOdstep)\"($Odstep)/$1''$2/g;
	s/\\,,/\\\"/g;
};
#  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  
# wielokropki
sub PrzestankoweWielokropki {
	s/\.{5,}/\\dotfill\{\}/g;
	s/\.{3,4}/\\ldots{}/g;
};
#  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  
# odstępy przy znakach przestankowych (uwaga: ryzykowne - dużo wyjątków)
sub PrzestankoweOdstepy {
	s/$Odstep*([\.;:!?\)\]])/$1/g;
	s/$Odstep*,([^,])/,$1/g;
	s/([\.!?;:\)\]])($Litera)/$1 $2/g;
	s/([^,]),($Litera)/$1, $2/g;
	s/([\(\[])$Odstep*/$1/g;
# skróty - wyjątki
	s/m\.\ +in\./m\.in\./g;
	s/p\.\ +n\.\ +e\./p\.n\.e\./g;
	s/l\.\ +c\./l\.c\./g;
	s/w\.\ +c\./w\.c\./g;
# duże liczby
	1 while (s/(.*\d\d)(\d\d\d)/$1\\,$2/ or s/(.*\d)(\d\d\d)\\,/$1\\,$2\\,/);
};
#  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  
# uporządkowanie kolejności nawias klamrowy - znak przestankowy (!!!sprawa 
# związana z grupowaniem texem - nie do załatwienia w tym prostym programie)
#  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .  
# symbole niematematyczne 
sub PrzestankoweSymbole {
#	s/([^\\])([\$\%])/$1\\$2/g;
	s/([^\$\<])\<([^\$\<])/$1\$\<\$$2/g;
	s/([^\$\>])\>([^\$\>])/$1\$\>\$$2/g;
}
# ========================================================================
# Zmiany w kształcie akapitu - usunięcie przeniesień i wcięć od marginesu 
# i przeformatowanie na szerokość <=70 zn (domyślna w AUCTeX-u)
sub PrzeformatujAkapit {
	s/$Odstep*\\\\/\ \\\\/g;
	my $IloscSlow = split;
	my $DlugoscWiersza = length($_[0]);
	for (my $i=1; $i<$IloscSlow; $i++) {
		$DlugoscWiersza += length($_[$i]) + 1;
		if (($DlugoscWiersza>70) || ($_[$i-1]=~/\\\\/)) {
			$_[$i-1] .= "\n";
			$DlugoscWiersza = length($_[$i]);
		};
	};
	$_ = join (" ", @_, "\n");
	s/$Odstep\\\\/\\\\/g;
	s/\n*\\\\\n\\\\\n/\n\n/g;
	s/\n$Odstep+/\n/g;
};
# ========================================================================
# Główny program

#--------------------------------------------------
# $/ = "";
# $\ = "\n";
#-------------------------------------------------- 

if ($ARGV[0] =~ m/^-$/) {
	# zakładamy że zawartość ma być wypisana na STDOUT
	shift @ARGV;
} else {
	if ($ARGV[0] =~ m/^-(b|-backup)$/i) {
		$BACKUP = 1;
		shift @ARGV;
	}
	$FILE = 1;
}

my $filepath = abs_path(shift @ARGV);

if ($FILE) {
	if ($BACKUP) {
		my $control_number;
		my $backup_copy = dirname($filepath) . "/." . basename($filepath);

		my $year = localtime()->year+1900;
		my $month = localtime()->mon+1;
		my $day = localtime()->mday;

		for ($month, $day) {
			$_ = '0' . $_ if length == 1;
		}

		if ($backup_copy =~ m:^.*\/.+(\.[0-9]+?)?$:) {
			$control_number = '0000' unless $1;
			$backup_copy =~ s:^(.*/.+)(\.[0-9]+)?$:$1$year$month$day:;
		}

		$control_number++;
		while (-e $backup_copy . '.' .$control_number . ".bak") {
			$control_number++;
		}

		# Sprawdza czy aktualna wersja jest różna od ostatniej
		# kopii zapasowej — jeśli tak, tworzy kopię zapasową.
		my $prev_control_num = $control_number - 1;
		$prev_control_num = '0' . $prev_control_num while length($prev_control_num) != 4;
		my $compare = compare($filepath, $backup_copy . '.'. $prev_control_num .'.bak');

		if ($compare == '-1') {
			die "Z jakiegoś powodu nie udało się porównać plików:\n
$filepath oraz $backup_copy . $prev_control_num .bak\n";
		} elsif ($compare == '1') {
			copy($filepath, $backup_copy . '.' . $control_number . ".bak") or die "Nie udało się skopiować pliku: $!\n";
			print STDERR "Utworzono kopię zapasową: $backup_copy.$control_number.bak\n";
		}
	}

	open (OUT, '+<', $filepath) or die "Nie udało się otworzyć pliku: ". $_ . "\n";

		@file_content = <OUT>;

		truncate(OUT, 0);
		seek(OUT, 0, 0);
} else {
	open (OUT, '<', $filepath) or die "Nie udało się otworzyć pliku: ". $_ . "\n";
		@file_content = <OUT>;
	close OUT;
}

open(OUT, '>-') unless $FILE;

foreach (@file_content) {
	next if /^%/;
	if (/\\begin{$PominSrodowisko}/../\\end{$PominSrodowisko}/) {
		next;
	};
#	&PolaczWiersze;
	&PoprawAkapit;
#	&PrzeformatujAkapit;
} continue { 
	print OUT;
}

close OUT;

print "Pomyślnie uporządkowano plik: $filepath\n" if $FILE;

# Koniec skryptu "porzadki".
