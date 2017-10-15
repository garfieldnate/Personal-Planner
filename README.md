# Personal Planner

This planner is a remake of my favorite planner purchased from the BYU bookstore as a student: a 7.5 x 5 inch weekly/daily academic planner from Roaring Spring Paper Products. I used to buy one every year and have the covers laminated. Features include:

* Daily planning entries with 1 week visible at a time
* Monthly planning pages
* Entries section can be regenerated for any time span
* American/Japanese holidays and family birthdays marked, sometimes with emoji!
* Lines for writing daily plans
* A star to fill in or put a sticker on for use with daily goals or habit building
* Blank, graph and line note sections in the back
* A year goals page in the back
* Shnazzy front and back covers (no barcodes or recycled signs)

I never used calendars, and I don't need to keep track of class schedules, so I didn't bother adding those pages.

## Prerequisites

To build the planner, you'll need the following:

* Perl
* [cpanm](http://cpanmin.us/)

You can then install the required Perl modules with the following command:

    cpanm --install-deps .

To render the planner properly, you'll need Google Chrome and the [Segoe UI Emoji](https://www.wfonts.com/font/segoe-ui-emoji) font. This is a black and white font for emoji (color emoji fonts do not render well when printed in black and white).

## Building

The planner is written in HTML/CSS with special print styles, intended to simply be printed via Google Chrome (supporting other browsers would be a lot of work!). The entries are generated using Perl and several calendar modules. 

To generate planner entries between April 1st, 2015 and March 31, 2016:

    perl -Ilib make_entries.pl 2015-4-1 2016-3-31

This will write the file `Entries.html`. You do not have to specify both of the dates; the default start date is January 1st of the current year, and the default end date is December 31st of the start year.

Next, you should edit the years listed in `Title.html` and `BackCover.html`. Finally, run `perl make_full_planner.pl` to combine all of the sections into one document, `FullPlannerContents.html`.

After that, you just need to print these files to PDF via Chrome and then take the files to a printer:

* FrontCover.html
* FullPlannerContents.html
* BackCover.html

Be sure to check the "Background Graphics" box in the print dialog; lined sections are implemented via a repeating background image of a line.

## License

Copyright Nathan Glenn, released under the [MIT license](http://choosealicense.com/licenses/apache-2.0/).

## TODO
* German Holidays
* ? Add entry footers
    - fire flower, Yoshi egg, mushroom, koopa, triforce, one true ring, types of knots or tesselations...
* Determine exactly how best to print (how many pages per paper in what orientation, etc.)
    - Actually print it!
    - Record estimated cost
    - find good way to make a cover; maybe just get blue/orange plastic and trace pictures on there.
* Calendar entries for general conference would be nice
* 2 month calendar in page corners (original has this; do I need it?)
* Investigate printing of small text and light gray text
    - Initial printing at FedEx Office and Office Max both stunk at these
* Report various bugs found during the making of this project
    - patch Japanese Holiday module to get rid of warnings;
    - file request for Calendar::China to allow gregorian year with Chinese month/day
    - Chrome doesn't change start page to left for Arabic/Hebrew
        + http://www.w3.org/TR/CSS21/page.html#page-selectors
    - Couldn't get @import CSS to work for page rules
    - Chrome's print emulation doesn't set page size, nor does it allow setting the rule to inches or points
    - FireFox totally ignores print styling?
    - Viewport sizes are set to nothing in paged media
    - page-break-after doesn't break after if there's a border
