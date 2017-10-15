# Generate my favorite planner.
# To generate planner entries between April 1st, 2015 and March 31, 2016:

#     perl -Ilib make_entries.pl 2015-4-1 2016-3-31

# This will write the file `Entries.html`. You do not have to
# specify both of the dates; the default start date is January
# 1st of the current year, and the default end date is December
# 31st of the start year.

# The entries are displayed as 1 week per 2-page spread, from Monday to
# Sunday. Therefore, the actual first entry date is the first Monday on
# or before the input start date, and the actual end date is the next
# Saturday on or after the input end date.
use strict;
use warnings;
use XML::Writer;
use 5.010;
use utf8;
use Date::Simple ('ymd');
use Path::Tiny;

use Lib '.';
use Planner::Holidays;

sub _date_from_arg {
    my ($date) = @_;
    if((my ($year, $month, $day) = split '\W', $date) == 3){
        return ymd($year, $month, $day);
    }else {
        usage();
        exit;
    }
}

sub _usage {
    say "Usage: perl make_planner.pl year-month-date [year-month-date]"
}

my ($input_start, $input_end) = @ARGV;

# default start date is January 1, this year
my $start = _date_from_arg($input_start || (localtime)[5]+1900 . '-1-1');
# if end date not specified, use December 31st of the same year.
my $end = do {
    if($input_end){
        _date_from_arg($input_end);
    } else{
        ymd($start->year, 12, 31);
    }
};

my $holidays = Planner::Holidays->new($start->year .. $end->year);

my $out = path('Entries.html')->openw_utf8;
say $out '<!doctype html>';
say $out '<link rel="stylesheet" href="CSS/Page.css">';
# Specify Japanese and then emoji fonts so emoji overrides Japanese
say $out '<link rel="stylesheet" href="CSS/JPFont.css">';
say $out '<link rel="stylesheet" href="CSS/Entries.css">';
say $out '<link rel="stylesheet" href="CSS/Notes.css">';
my $writer = XML::Writer->new(
    OUTPUT => $out,
    DATA_MODE => 1,
    UNSAFE => 1,
    DATA_INDENT => '    '
);

my @months = (
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
);

my @days_of_week = (
    'SUNDAY',
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY'
);

# we use Monday-Sunday weeks; find the Monday previous to our start date
my $date = $start;
while($date->day_of_week != 1){
    $date--;
}

$writer->startTag('div', class => 'entries');
my $week_counter = 0;
my $term_length = 5;
# print by the week until we have surpassed the end date;
# print a term planning page every 5 weeks
while ( $date < $end ) {
    term_planner($writer, $date) if $week_counter % $term_length == 0;
    $week_counter++;
    start_week($writer, $date);
    for(1..7){
        write_day($writer, $date, $_);
        $date++;
        # last;
    }
    end_week($writer);
    # last;
}
$writer->endTag('div'); # entries
$writer->end(); # end the entire document

# for now, this is just two blank pages with a header. Maybe
# next year I'll have some ideas on content or formatting.
sub term_planner {
    for(qw(left right)){
        $writer->startTag('div',
            class => 'page ' . $_ . '-page notes-page');
        $writer->startTag('div', class => 'corner');
        $writer->endTag('div');
        $writer->startTag('div', class => 'notes-header');
        $writer->characters('Term Goals');
        $writer->endTag('div');
        if($_ eq 'right') {
            $writer->startTag('div', class => 'notes line-notes');
            $writer->endTag('div');
        }
        $writer->endTag('div');
    }

    return;
}

sub start_week {
    my ($writer, $date) = @_;
    my $start = print_date($date);
    my $end = print_date($date + 6);
    $writer->startTag('div',
        class=> 'week',
        'data-start-date' => $start,
        'data-end-date' => $end
    );

    # first page contains Monday -- Wednesday
    $writer->startTag('div', class => 'page left-page');
    $writer->startTag('div', class => 'corner');
    $writer->endTag('div');

    $writer->startTag('div', class => 'week-header-container');
    $writer->startTag('h3', class => 'week-header');
    $writer->raw($start . "  &mdash;  " . $end);
    $writer->endTag('h3');
    $writer->endTag('div');
    return;
}

sub write_day {
    my ($writer, $date, $day_of_week) = @_;

    # second page contains Thursday -- Sunday
    if($day_of_week == 4){
        $writer->startTag('div', class => "page right-page");
        $writer->startTag('div', class => 'corner');
        $writer->endTag('div');
    }
    $writer->startTag('div',
        class => 'day ' . ($day_of_week < 6 ? 'weekday' : 'weekend'),
        'data-week-day' => $days_of_week[$date->day_of_week],
        'data-month-day' => $date->day,
        'data-month' => $months[$date->month - 1],
    );

    $writer->startTag('h4', class => 'day-header');
        $writer->startTag('span', class=> 'day-of-week');
            $writer->characters(
                $days_of_week[$date->day_of_week] . ', ');
        $writer->endTag('span');
        $writer->startTag('span', class => 'date');
            $writer->characters(print_date($date));
        $writer->endTag('span');

        write_holidays($writer, $date->year, $date->month, $date->day);
    $writer->endTag('h4');

    $writer->startTag('div', class => 'entry-lines');
    $writer->emptyTag('img',
        class => 'goal-star',
        src => "images/Star.svg"
    );
    $writer->endTag('div');

    $writer->endTag('div'); # day

    # end page div
    if($day_of_week == 3 || $day_of_week == 7){
        $writer->endTag('div');
    }
    return;
}

sub write_holidays {
    my ($writer, $year, $month, $day) = @_;

    my @en_holidays = $holidays->get_en_holidays($year, $month, $day);
    my @jp_holidays = $holidays->get_jp_holidays($year, $month, $day);

    if(@en_holidays || @jp_holidays){
        $writer->startTag('span', class => 'holiday');
    }else {
        return;
    }

    if(@jp_holidays){
        $writer->startTag('span', lang => 'ja');
        while(my ($i, $holiday) = each @jp_holidays){
            $writer->characters($holiday->{name});
            write_emoji($writer, $holiday->{emoji})
                if($holiday->{emoji});
            if($i != $#jp_holidays){
                $writer->characters('、'); # separator
            }
        }
        $writer->endTag('span');
    }

    if(@en_holidays && @jp_holidays){
        $writer->characters('　'); # separator
    }
    while(my ($i, $holiday) = each @en_holidays){
        $writer->characters($holiday->{name});
        write_emoji($writer, $holiday->{emoji})
            if($holiday->{emoji});
        if($i != $#en_holidays){
            $writer->characters(', '); # separator
        }
    }
    $writer->endTag('span');
    return;
}

sub write_emoji {
    my ($writer, $emoji) = @_;
        $writer->startTag('span', class => 'emoji');
        $writer->characters("$emoji ");
        $writer->endTag('span');
    return;
}

sub end_week {
    my ($writer) = @_;

    # $writer->endTag('div'); # right-page
    $writer->endTag('div'); # week
    return;
}

sub print_date {
    my ($date) = @_;
    return sprintf('%s %d, %d',
        $months[$date->month - 1], $date->day, $date->year);
}
