# Generate my favorite planner.
# To generate planner entries between April 1st, 2015 and March 31, 2016:

#     perl make_entries.pl 2015-4-1 2016-3-31

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
use Date::Calendar;
use Calendar;
use Calendar::Japanese::Holiday;
use Date::Easter;
use Path::Tiny;

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

# Specify holidays to Date::Calendar, along with some other
# processing info. Provide date, lang (if Japanese),
# and emoji to display next to holiday name.
# TODO: For now, Unicode doesn't support country flags
# (and neither does Symbola).
my %holiday_info = (
    # New Years is handled by Japanese holidays
    'MLK Day' => {
        date => '3/Mon/Jan'
        # TODO: an MLK emoji would be nice...
    },

    'Groundhog Day' => {
        date => 'Feb2'
        # TODO: no groundhog emoji...
    },
    'Valentine\'s Day' => {
        date    => 'Feb14',
        emoji   => "\x{2665}" # heart
    },
    'President\'s Day' => {
        date    => '3/Mon/Feb',
        # emoji   => "\x{1F1FA}\x{1F1F8}" # US flag
    },

    "雛祭り" => {
        date    => 'Mar3', # but it differs by a bit by area
        emoji   => "\x{1F38E}", # Japanese dolls
        lang    => "JA"
    },
    'White Day' => {
        date    => 'Mar14',
        emoji   => "\x{2661}" # white heart
    },
    'St. Patrick\'s Day' => {
        date    => 'Mar17',
        emoji   => "\x{2618}" #shamrock. four-leaf clover (1F340) also available
    },

    'April Fool\'s Day' => {date => 'Apr1'},
    # Easter is handled separately

    'Mother\'s Day' => {
        date    => '2/Sun/May',
        # emoji   => "\x{1F395}" # TODO: boquet not availabe until Unicode 7 (and Symbola is ugly)
    },
    'Memorial Day' => {
        date    => '5/Mon/May', # means LAST Monday
        # emoji   => "\x{1F1FA}\x{1F1F8}" # US flag
    },
    'Wedding Anniversary' => {
        date    => 'May25',
        emoji   => "\x{1F48D}" # ring
    },

    'Flag Day' => {
        date    => 'Jun14',
        # emoji   => "\x{1F1FA}\x{1F1F8}" # US flag
    },
    'Father\'s Day' => {date => '3/Sun/Jun'},

    'Independence Day' => {
        date    => 'Jul4',
        # emoji   => "\x{1F1FA}\x{1F1F8}" # US flag
    },
    '七夕' => {
        date    => 'Jul7',
        emoji   => "\x{1F38B}", # tanabata bamboo decoration
        lang    => 'JA'
    },
    'Pioneer Day' => {
        date    => 'Jul24',
        # emoji => "\x{1f402}" # ox TODO: I want a covered wagon.
    },
    # the main Summer festival in Osaka
    '天神祭' => {
        date    => 'Jul25',
        emoji   => "\x{1F387}", # sparkler; sky firework also available (1F386)
        lang    => 'JA'
    },

    'お盆' => {
        date    => 'Aug15',
        emoji   => "\x{1F3EE}", #Izakaya lantern
        lang    => "JA"
    },

    '十五夜' => {
        date    => get_tsukimi(),
        emoji   => "\x{1F391}", # moon viewing ceremony
        lang    => "JA"
    },
    'Labor Day' => {
        date    => '1/Mon/Sep',
        # emoji   => "\x{1F1FA}\x{1F1F8}" # US flag
    },
    '9/11' => {
        date    => 'Sep11',
        # emoji   => "\x{1F1FA}\x{1F1F8}" # US flag
    },
    'Birthday' => {
        date    => 'Sep28',
        emoji   => "\x{1F382}" # birthday cake
    },

    'Columbus Day' => {
        date => '2/Mon/Oct',
        # emoji  TODO: I want an old ship. Palm (1F334) doesn't cut it.
    },
    'Halloween' => {
        date    => 'Oct31',
        emoji   => "\x{1F383}", # jack-o-lantern
    },

    'Veterans Day' => {
        date => 'Nov11',
        # emoji   => "\x{1F1FA}\x{1F1F8}" # US flag
    },
    'Thanksgiving' => {
        date    => '4/Thu/Nov',
        emoji   => "\x{1F357}" # foul leg. TODO: Turkey in future Unicode (x704)
    },

    'Pearl Harbor Day' => {
        date    => 'Dec7',
        # emoji   => "\x{1F1FA}\x{1F1F8}" # US flag
    },
    'Christmas Eve' => {
        date    => 'Dec24',
        emoji   => "\x{1F385}" # Santa
    },
    'Christmas' => {
        date    => 'Dec25',
        emoji   => "\x{1F384}" # Christmas tree
    },
    'New Years Eve' => {
        date    => 'Dec31',
        emoji   => "\x{1F38A}", # party popper
    },
    '大晦日' => {
        date    => 'Dec31',
        lang    => 'JA'
    }
);
# Add birthdays, which have common characteristics
{
    my %birthdays = (
        'Mom' =>    'Mar16',
        'Dad' =>    'Sep13',
        "Erika" =>  'Feb21',
        'Karen' =>  'Oct29',
        'Chelan' => 'Jul8',
        'Marlon' => 'Mar22',
        'Josh' =>   'Dec8',
    );
    for(keys %birthdays){
        $holiday_info{"$_\'s Birthday"} =
            {date => $birthdays{$_}, emoji => "\x{1F382}"}; # birthday cake emoji
    }
}

# fill in default holiday language
$holiday_info{$_}->{lang} //= 'EN' for keys %holiday_info;

# finally create the calendar object, which provides
# parsing and querying of dates
my $holidays_calendar = Date::Calendar->new({
    map { $_ => $holiday_info{$_}->{date} } keys %holiday_info
});

# Japanese holiday dates are provided by Calendar::Japanese::Holiday,
# but they still need emoji!
%holiday_info = (
    %holiday_info,
    "元日"  => {
        emoji => "\x{1F38D}" # kadomatsu TODO: want torii (26E9), when it's available
    },
    # not provided by Calendar::Japanese::Holiday, but it's three days so
    # we can't specify the date here
    "三が日"  => {
        emoji => "\x{1F38D}" # kadomatsu
    },
    'こどもの日' => {
        # emoji   => "\x{1F38F}" # koinobori (it's ugly in current font)
    },
    "海の日" => {
        emoji => "\x{1F30A}" # wave; spiral shell (1F41A) also available
    },
    "山の日" => {
        emoji => "\x{1F304}" # mountain sunrise; Mt. Fuji (1F5FB) also available
    },
    "みどりの日" => {
        emoji => "\x{1F33F}" # herb; deciduous tree (1F333) also available
    },
    "建国記念の日" => {
        emoji => "\x{1F3EF}" # Japanese castle
    },
    "憲法記念日" => {
        # emoji => "\x{1F1EF}\x{1F1F5}" # JP flag
    },
    "秋分の日" => {
        emoji => "\x{1F341}" # maple leaf; some font might be better with fallen leaf (1F342)
    },
    "春分の日" => {
        emoji => "\x{1F331}" # seedling
    },
    "体育の日" => {
        emoji => "\x{1F3BD}" # running shirt with sash
    },
    "成人の日" => {
        emoji => "\x{1F458}" # kimono
    }
);

my $out = path('Entries.html')->openw_utf8;
say $out '<!doctype html>';
say $out '<link rel="stylesheet" href="Entries.css">';
say $out '<link rel="stylesheet" href="Page.css">';
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
# print by the week until we have surpassed the end date
while ( $date < $end ) {
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
$writer->end();

sub start_week {
    my ($writer, $date) = @_;
    my $start = print_date($date);
    my $end = print_date($date + 6);
    $writer->startTag('div',
        class=> 'week',
        'data-start-date' => $start,
        'data-end-date' => $end
    );
    # $writer->startTag('div', class => 'page page-left');

    $writer->startTag('div', class => 'week-header-container');
    $writer->startTag('h3', class => 'week-header');
    $writer->raw($start . "  &mdash;  " . $end);
    $writer->endTag('h3');
    $writer->endTag('div');
    return;
}

sub write_day {
    my ($writer, $date, $day_of_week) = @_;

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

    $writer->startTag('div', class => 'lines');
    $writer->emptyTag('img',
        class => 'goal-star',
        src => "Star.svg"
    );
    $writer->endTag('div');

    $writer->endTag('div'); # day
}

sub write_holidays {
    my ($writer, $year, $month, $day) = @_;

    my @en_holidays = get_en_holidays($year, $month, $day);
    my @jp_holidays = get_jp_holidays($year, $month, $day);

    if(@en_holidays || @jp_holidays){
        $writer->startTag('span', class => 'holiday');
    }else{
        return;
    }

    if(@jp_holidays){
        $writer->startTag('span', lang => 'ja');
        while(my ($i, $holiday) = each @jp_holidays){
            $writer->characters($holiday);
            write_emoji($writer, $holiday);
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
        $writer->characters($holiday);
        write_emoji($writer, $holiday);
        if($i != $#en_holidays){
            $writer->characters(', '); # separator
        }
    }
    $writer->endTag('span');
    return;
}

sub write_emoji {
    my ($writer, $holiday) = @_;
    if(exists $holiday_info{$holiday}->{emoji}){
        $writer->startTag('span', class => 'emoji');
        $writer->characters("$holiday_info{$holiday}->{emoji} ");
        $writer->endTag('span');
    }
    return;
}

sub get_en_holidays {
    my ($year, $month, $day) = @_;
    my @holidays;
    # cache easter dates for each year if not done yet
    state %easter;
    if(!$easter{$year}){
        $easter{$year} = join ',', easter($year);
    }

    # check for Easter and then check the calendar for other holidays
    if($easter{$year} eq "$month,$day"){
        push @holidays, 'Easter';
    }
    # labels always returns day of the week, as well as holidays
    if ((my @temp = $holidays_calendar->labels($year, $month, $day)) > 1){
        shift @temp;
        for my $holiday(@temp){
            if(!exists $holiday_info{$holiday}->{lang}){
                print $holiday;
            }
            if(!($holiday_info{$holiday}->{lang} eq 'JA')){
                push @holidays, $holiday;
            }
        }
    }
    return @holidays;
}

sub get_jp_holidays {
    my ($year, $month, $day) = @_;

    # 0 means we don't get substitute business holidays when the actual one is on a weekend
    my @holidays = isHoliday($year, $month, $day, 0) || ();
    # can't specify this on calendar because it's two days
    if($month == 1 && ($day == 2 || $day == 3)){
        push @holidays, '三が日';
    }

    # labels always returns day of the week, as well as holidays
    if ((my @temp = $holidays_calendar->labels($year, $month, $day)) > 1){
        shift @temp;
        for my $holiday(@temp){
            if($holiday_info{$holiday}->{lang} eq 'JA'){
                push @holidays, $holiday;
            }
        }
    }
    return @holidays;
}

sub end_week {
    my ($writer) = @_;

    # $writer->endTag('div'); # page-right
    $writer->endTag('div'); # week
    return;
}

# Moon viewing is on 8/15 of the old calendar
sub get_tsukimi {
    my ($year) = @_;
    # start with any date near the middle of the year just to initialize
    # the Chinese cycle/year correctly
    my $temp_date = Calendar->new_from_Gregorian(7, 1, 2015);
    $temp_date->convert_to_China();
    #get tsukimi date from cycle and year found above, and date 8/15
    my $tsukimi = Calendar->new_from_China(-cycle => $temp_date->cycle, -year => $temp_date->year, -month => 8, -day => 15);
    $tsukimi->convert_to_Gregorian();
    return $tsukimi->month . '/' . $tsukimi->day;
}

sub print_date {
    my ($date) = @_;
    return sprintf('%s %d, %d',
        $months[$date->month - 1], $date->day, $date->year);
}
