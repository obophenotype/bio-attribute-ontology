#!/usr/bin/perl
while(<>) {
    s@ VT:(\d+)@ OBA:VT$1@g;
    s@ TO:(\d+)@ OBA:TO$1@g;
    print;
}
