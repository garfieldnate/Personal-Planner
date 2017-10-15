package Planner::Holidays;
use strict;
use warnings;
use utf8;
use Calendar::Japanese::Holiday;
use Date::Calendar;
use Calendar;
use 5.010;

sub new {
    my ($class) = @_;
    my ($holiday_info, $calendar) = _init_holiday_info();

    my $self = bless {info => $holiday_info, calendar => $calendar}, $class;
    return $self;
}

sub _init_holiday_info {
    # Specify holidays to Date::Calendar, along with some other
    # processing info. Provide date, lang (if Japanese),
    # and emoji to display next to holiday name.
    # TODO: For now, Unicode doesn't support country flags
    # (and neither does Symbola).
    my %holiday_info = (
        # American holidays (New Years is handled by Japanese holidays)
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
        'St. Patrick\'s Day' => {
            date    => 'Mar17',
            emoji   => "\x{2618}" #shamrock. four-leaf clover (1F340) also available
        },
        'April Fool\'s Day' => {date => 'Apr1'},
        'Easter'            => {date => '+0'}, # TODO: emoji Church, chick...
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

        # Japanese Holidays
        "雛祭り" => {
            date    => 'Mar3', # but it differs by a bit by area
            emoji   => "\x{1F38E}", # Japanese dolls
            lang    => "JA"
        },
        'White Day' => {
            date    => 'Mar14',
            emoji   => "\x{2661}" # white heart
        },
        '七夕' => {
            date    => 'Jul7',
            emoji   => "\x{1F38B}", # tanabata bamboo decoration
            lang    => 'JA'
        },
        'お盆' => {
            date    => 'Aug15',
            emoji   => "\x{1F3EE}", #Izakaya lantern
            lang    => "JA"
        },
        '大晦日' => {
            date    => 'Dec31',
            lang    => 'JA'
        },

        # German holidays (for NRW)
        'Karfreitag' => {
            date    => '-2',
            lang    => 'DE'
        },
        'Ostermontag' => {
            date    => '+1',
            lang    => 'DE'
        },
        'Christi Himmelfahrt' => {
            date    => '+39',
            lang    => 'DE'
        },
        'Pfingstmontag' => {
            date    => '+50',
            lang    => 'DE'
        },
        'Fronleichnam' => {
            date    => '+60',
            lang    => 'DE'
        },
        'Tag der Arbeit' => {
            date    => 'May1',
            lang    => 'DE'
        },
        'Tag der Deutschen Einheit' => {
            date    => 'Oct3',
            lang    => 'DE',
        },
        'Allerheiligen' => {
            date    => 'Nov1',
            lang    => 'DE'
        },
        'Zweiter Weihnachtsfeiertag' => {
            date    => 'Dec26',
            lang    => 'DE'
        },

        # LDS events and holidays
        'Pioneer Day' => {
            date    => 'Jul24',
            # emoji => "\x{1f402}" # ox TODO: I want a covered wagon.
        },
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
        $holiday_info{q(Erika's Birthday)}->{emoji} = "\x{1f43b}\x{1F382}"; # bear and cake
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
        '十五夜' => {
            emoji   => "\x{1F391}", # moon viewing ceremony
            lang    => "JA"
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

    return (\%holiday_info, $holidays_calendar);
}

# Moon viewing is on 8/15 of the old calendar
sub _is_tsukimi {
    my ($self, $year, $month, $day) = @_;

    # cache the calculation
    if(!$self->{tsukimi}->{$year}){
        # start with any date near the middle of the year just to initialize
        # the Chinese cycle/year correctly
        my $temp_date = Calendar->new_from_Gregorian(7, 1, $year);
        $temp_date->convert_to_China();
        #get tsukimi date from cycle and year found above, and date 8/15
        my $tsukimi = Calendar->new_from_China(-cycle => $temp_date->cycle, -year => $temp_date->year, -month => 8, -day => 15);
        $tsukimi->convert_to_Gregorian();
        $self->{tsukimi}->{$year} =  $tsukimi->month . '/' . $tsukimi->day;
    }
    return "$month/$day" eq $self->{tsukimi}->{$year};
}

# return [{name => ..., emoji => ...}, ...]
sub get_en_holidays {
    my ($self, $year, $month, $day) = @_;
    my @holidays;
    # labels always returns day of the week, as well as holidays
    if ((my @temp = $self->{calendar}->labels($year, $month, $day)) > 1){
        shift @temp;
        for my $holiday(@temp){
            # all non-Japanese holidays are assumed English
            if($self->get_lang($holiday) ne 'JA'){
                push @holidays, { name => $holiday, emoji => $self->get_emoji($holiday) };
            }
        }
    }
    return @holidays;
}

# return [{name => ..., emoji => ...}, ...]
sub get_jp_holidays {
    my ($self, $year, $month, $day) = @_;

    # 0 means we don't get substitute business holidays when the actual one is on a weekend
    my @holidays = isHoliday($year, $month, $day, 0) || ();
    @holidays = map { {name => $_, emoji => $self->{info}->{$_}->{emoji}} } @holidays;
    if($self->_is_tsukimi($year, $month, $day)){
        push @holidays, {name => '十五夜', emoji => $self->get_emoji('十五夜')};
    }

    # can't specify this on calendar because it's two days
    if($month == 1 && ($day == 2 || $day == 3)){
        push @holidays, {name => '三が日', emoji => $self->{info}->{'三が日'}->{emoji}};
    }

    # labels always returns day of the week, as well as holidays
    if ((my @temp = $self->{calendar}->labels($year, $month, $day)) > 1){
        shift @temp;
        for my $holiday(@temp){
            if($self->get_lang($holiday) eq 'JA'){
                push @holidays, { name => $holiday, emoji => $self->get_emoji($holiday) };
            }
        }
    }
    return @holidays;
}

sub get_emoji {
    my ($self, $holiday) = @_;
    return $self->{info}->{$holiday}->{emoji};
}

sub get_lang {
    my ($self, $holiday) = @_;
    return $self->{info}->{$holiday}->{lang};
}

'パーティーやろう！';
