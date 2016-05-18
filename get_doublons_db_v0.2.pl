#!/usr/bin/env perl

# Prerequisites
# if required init img.db and Images::Schema :run ./rebuild_db.sh

# Usage : perl -w get_doublons_db.pl [ volumes_names ]


# Note : take into account all files with mimetype string begining by image

use strict;
use warnings;


#use Digest::MD5 qw(md5 md5_hex md5_base64);
use Digest::MD5 qw(md5);
#use File::Compare;
use File::Basename qw(fileparse);
#use File::Path;
#use File::Spec;
#use File::Copy;
use File::Find;
use File::MimeInfo::Magic;

use Images::Schema;

my $schema = Images::Schema->connect('dbi:SQLite:img.db', '', '',{ sqlite_unicode => 1});


my %REC_REPORT;
my %SIGNATURES;
my $report_id;

my $dirs_read;
my $files_read;


sub compute_md5_file {
    my $filename = shift;
    open (my $fh, '<', $filename) or die "Can't open '$filename': $!";
    binmode ($fh);
    return Digest::MD5->new->addfile($fh)->hexdigest;
}

sub compute_report_id {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
			$mon 	+= 1;
			$year 	+= 1900;
			$mday 	= substr("0".$mday,length("0".$mday)-2, 2);
			$mon 	= substr("0".$mon,length("0".$mon)-2, 2);
			$hour 	= substr("0".$hour,length("0".$hour)-2, 2);
			$min 	= substr("0".$min,length("0".$min)-2, 2);
	
			$report_id = join("_", $year, $mon, $mday, join("-", $hour,$min));
}


# report_id : date only
sub init_proc_report {

	my $rec_report = {};
	
	$rec_report->{report_id} 					= $report_id;
#	$rec_report->{proc}							= $proc;
#	$rec_report->{args}							= $dir;
	$rec_report->{report_nbdirsread} 			= 0;
	$rec_report->{report_nbfilesread}			= 0;
	$rec_report->{report_nbdup}					= 0;
	$REC_REPORT{ $rec_report->{report_id} } 	= $rec_report;
	
}		
		
sub ls_files {
	my $md5;
#	print $File::Find::name,"\n";
	if ( !($_ =~ /^\./) ) {
		if ( -l $_ ) {
		}
		elsif ( -d $_ ) { 
		# Input file is a directory
			$dirs_read++;
			$REC_REPORT{$report_id}{report_nbdirsread}++;					
    	}	
    	elsif ( mimetype($_) =~ /^image\// ) {  
 #	   		print $_,"\n";
    		$files_read++;
    		$REC_REPORT{$report_id}{report_nbfilesread}++;
    		my ($filename,$dir,$ext) = fileparse($File::Find::name, qr/\.[^.]*/);
			my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($File::Find::name);
	   		   		
	   		my $md5 = compute_md5_file($File::Find::name);
	   		# MD5 already exists
	   		if ( $SIGNATURES{$md5} ) {
	   			# Add occurence and location if location not in database
	   			my $rs_id = $schema->resultset('Image')->find( { img_id => $md5 } );
#				print "DEBUG | md5 : ",$md5;
	   			my $nb_occ = $rs_id->img_nbocc;
	   			my $rs_loc = $schema->resultset('Location')->find( { loc_fullname => $File::Find::name, loc_id => $md5 } ); 
	   			if ( defined($rs_loc) ) { 
	   				# location found do nothing
#	   				print "File : ",$rs_loc->{loc_fullname}, " already in db. NOTHING DONE !\n";
	   			} 
	   			else {
	   				# md5 exists but new location so img_nbocc 				
	   				# NO ERROR CHECK !!
	   				
#	   				print "File : ",$File::Find::name,"\t nbocc b4 : ",$nb_occ;

	   				# Add new location  	
	   				my $import = $schema->resultset('Location')->find_or_create({
						loc_id 			=> $md5,
						loc_fullname 	=> $File::Find::name,
						loc_filename 	=> $filename,
						loc_dir 		=> $dir,
						loc_ext 		=> $ext });	
					$nb_occ++;
					
					$rs_id->update( {img_nbocc => $nb_occ} ) ;
					$REC_REPORT{$report_id}{report_nbdup}++;	
	   			}
			}	
	   		else {
	   		# new md5
	   			$SIGNATURES{$md5}++;
	   			
	   			my $import_img = $schema->resultset('Image')->create({
					img_id 		=> $md5,
					img_size 	=> $size,
					img_mtime 	=> $mtime,
				});
	   			
	   			my $import_loc = $schema->resultset('Location')->create({
					loc_id 			=> $md5,
					loc_fullname 	=> $File::Find::name,
					loc_filename 	=> $filename,
					loc_dir 		=> $dir,
					loc_ext 		=> $ext,
				});	
			}		
		}		
	}
}

sub save_db_report { 
	my $import_rep = $schema->resultset('Report')->create({
					report_id			=> $report_id,
					report_nbdirsread 	=> $REC_REPORT{$report_id}{report_nbdirsread},
					report_nbfilesread 	=> $REC_REPORT{$report_id}{report_nbfilesread},
					report_nbdup		=> $REC_REPORT{$report_id}{report_nbdup},
					report_sizelost 	=> compute_lostspace(),
				});	
}

sub load_db_ids {

	my $rs_img = $schema->resultset('Image')->search( { } );  
	for my $img ( $rs_img->all ) {
#		print "DEBUG ! img_id : ",$img->img_id,"\n";
		$SIGNATURES{$img->img_id}++;
	}
}

sub print_SIGNATURES {

		foreach my $id (keys %SIGNATURES) {
			print "\t KEYS : ",$SIGNATURES{$id},"\n";
		}
}		

sub print_SIMPLE_REPORT {
	print "[ REPORT FOR : ",$report_id," ] \n";

	print 	"\t NB DIRS: \t", $REC_REPORT{$report_id}{report_nbdirsread},"\n",
			"\t NB FILES: \t", $REC_REPORT{$report_id}{report_nbfilesread},"\n",
			"\t NB DOUBLONS: \t", $REC_REPORT{$report_id}{report_nbdup},"\n",
			"\t SPACE LOST: \t", compute_lostspace(),"\n"
			
}


sub compute_lostspace {
	my $lostspace = 0;
	
	
		my $rs_id = $schema->resultset('Image')->search(
			{'img_nbocc' => { '>', 1 } },
			{ columns => [ 'img_id', 'img_nbocc', 'img_size' ]}
		);
		
		my @ids = $rs_id->all;
		foreach my $id ( @ids ) {
#			print "DEBUG | md5 : ",$id->img_id,"\t nbocc : ",$id->img_nbocc,"\t size : ",$id->img_size,"\n";
			$lostspace += $id->img_nbocc * $id->img_size;
		}
		
	return $lostspace;
}

##########################################################################################
# MAIN
##########################################################################################

my @inputs;
for my $arg (0 .. $#ARGV) {
#	print $ARGV[$arg],"\t | ";
	if (-d $ARGV[$arg]) {
		$inputs[$arg] = $ARGV[$arg];
#		print " dir_OK \t |";
	} else {
#		print " Not_dir \t |";
	}
#	print "\n";
}

	load_db_ids();
#	print "DEBUG | nb of images in db at start : ",scalar(keys %SIGNATURES),"\n";  
	compute_report_id();
	init_proc_report();
	find(\&ls_files, @inputs);
	save_db_report();		


