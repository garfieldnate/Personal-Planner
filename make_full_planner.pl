use strict;
use warnings;
use 5.010;
use Path::Tiny;

my $out = path('FullPlanner.html')->openw_utf8();

say $out <<'END';
<!doctype html>
<link rel="stylesheet" href="Page.css">
<link rel="stylesheet" href="JPFont.css">
<link rel="stylesheet" href="Cover.css">
<link rel="stylesheet" href="Title.css">
<link rel="stylesheet" href="Entries.css">
<link rel="stylesheet" href="Notes.css">
<link rel="stylesheet" href="Numbers.css">
END

for my $file (qw(Cover Title Entries Notes Numbers Goals)){
    my $in = path("$file.html")->openr_utf8();
    my $line;
    # skip header stuff used for stand-alone dev for each file
    while(($line = <$in>) !~ /<div/){}
    print $out $line;
    while(defined ($line = <$in>)){
        print $out $line;
    }
}