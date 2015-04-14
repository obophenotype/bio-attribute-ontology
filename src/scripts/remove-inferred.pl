#!/usr/bin/perl
while(<>) {
    print unless m/is_inferred="true"/;
}
