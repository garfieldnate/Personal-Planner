# Personal Planner

This planner is a remake of my favorite planner purchased from the BYU bookstore as a student: an academic year planner by 7.5 x 5 inch weekly/daily planner from Roaring Spring Paper Products. Features include:

* Daily planning entries with 1 week visible at a time
* Lines for writing daily plans
* A star to fill in or put a sticker on for use with daily goals or habit building
* Graph and line note sections in the back
* American/Japanese holidays and family birthdays marked, sometimes with cute emoji!
* The entries section can be regenerated for any time span.

I never used calendars, so I didn't bother adding any.

##Building

The planner is written in HTML/CSS with special print styles, intended to simply be printed via Google Chrome (I believe it's the only browser that works). The entries are generated using Perl and several calendar modules. To generate planner entries between April 1st, 2015 and March 31, 2016:

    perl make_entries.pl 2015-4-1 2016-3-31

This will write the file `Entries.html`. You do not have to specify both of the dates; the default start date is January 1st of the current year, and the default end date is December 31st of the start year.

After that, you just need to print the sections of the planner using Chrome:

* Cover.html
* Title.html
* Entries.html
* GraphNotes.html
* LineNotes.html
* Numbers.html

This all needs some adjusting, so stay tuned for future improvements.

## License

Copyright Nathan Glenn, released under the [MIT license](http://choosealicense.com/licenses/apache-2.0/).

## TODO

* Change from using @page settings in separate documents to having one document with stylable page divs (@page does not work if you want one document with several different margins, etc.).
    - Then make sure left/right is all correct in new document
* Move holidays to a separate module to make them easier to change
* Use JavaScript to reduce size of Numbers.html
* Use that Pet Force logo somewhere!
* ? Add entry footers
* ? Back page:
    - ? Goals
    - ? Calendar
    - ? Blank for doodling?
* ? Blank note pages (no lines or graphs)
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