# NAME

MakeMake.pl -- Perl-based C/C++ makefile generator

# SYNOPSIS

    makemake.pl > makefile
    makemake.pl make.conf > makefile

# DESCRIPTION

input file is 'mm.conf', 'make.make' or name given as 1st arg.

output is printed to the stdout.

mm.conf/make.make format is:



    ---begin---
    # comments begin with # or ;
    ; this is also comment

    # defaults for all targets
    CC      = gcc
    LD      = gcc
    AR      = ar rv
    RANLIB  = ranlib
    SRC     = *.c *.cpp *.cc *.cxx

    # default commands
    MKDIR   = mkdir -p
    RMDIR   = rm -rf
    RMFILE  = rm -f

    # if labels above doesn't exist in the input file the values shown
    # are considered defaults

    # optional modules, subdirectories
    MODULES = module1 module2 module3

    # tells what actual makefile filename is. if this is defined
    # makefile will be recreated if mm.conf is changed
    # (optional)
    MM_REBUILD=Makefile

    # tells what makefile filename is. if this is defined
    # makefile will be recreated and make process will be restarted
    # if mm.conf is changed. this will override MM_BUILD if both used.
    # (optional)
    MM_RESTART=makefile

    # any other labels here are preserved but not used
    # this could be usefull to use make(1) vars, see next example
    DEBUG   = -g -pg

    [target-name-1]

    # this labels are required only if they should be different from
    # the defaults above
    CC      = gcc
    LD      = gcc
    CFLAGS  = $(DEBUG)
    CCFLAGS = -I../vslib -I/usr/include/ncurses -O2
    LDFLAGS = -L../vslib -lvslib -lncurses
    SRC     = *.cpp            # set source files
    # if 'TARGET' is skipped then the output file name is taken from the
    # target name (i.e. 'target-name-1' in this example)
    TARGET  = vfu

    [target-name-2]

    ...

    ---end-----

label 'CFLAGS' is optional and is appended to 'CCFLAGS' value

also each label's value can be appended to previous (or to defaults) with
'+=' operator:

    ---cut---
    SRC     = vstring.cpp
    SRC    += vstrlib.cpp
    SRC    += regexp3.cpp
    ---cut---

every target can inherit another one:

    ---cut---

    [vstring.a]

    CC      = g++
    LD      = g++
    CCFLAGS = -I. -O2
    TARGET  = libvstring.a
    SRC     = vstring.cpp vstrlib.cpp regexp3.cpp

    [debug-vstring.a: vstring.a]

    CCFLAGS += -g
    TARGET  = libvstring_dbg.a

    ---cut---

i.e. target 'debug-vstring.a' inherits 'vstring.a' but appends '-g' to the
compile options and changes output file name to 'libvstring\_dbg.a'

if you set target name to something that ends with '.a' -- makemake.pl will
produce library file target (i.e. will invoke AR instead of LD).

the minimum mm.conf is:

    ---cut---
    [hi]
    ---cut---

which will produce executable named 'hi' out from all sources in the current
directory...

Only one of MM\_REBUILD or MM\_RESTART should be used. If both used, MM\_RESTART
will override MM\_REBUILD. Makemake will not set default values for those two.
When either of the two is added or removed from mm.conf, makefile must be
manually recreated: 'makemake.pl > makefile' (or Makefile).

# CREDITS ANS MODIFICATIONS (HISTORY)

    dec1998: cade@biscom.net, ivo@datamax.bg
             * first version *
             though there are several utilities like this I still haven't
             found what I'm looking for... :)
             the closest approach is 'tmake' ( 'qmake' recently, 2002 ) made 
             by Troll Tech for their 'Qt' toolkit, but is far too complex...

           also I wanted it in Perl :)

    oct1999: cade@biscom.net
             added multi-target feature

    aug2000: cade@biscom.net
             general cleanup, target clean uses 'rm -rf' instead of 'rmdir'
             added targets 'rebuild' and 'link' (does 'relink' actually)
             globbing replaced with the use of 'ls'

    dec2000: cade@biscom.net
             added modules (subdir targets) support:
             $MODULES = "module1 module2 ...";
             now target name is required and not set to 'a.out' by default

    mar2001: cade@biscom.net
             added $MKDIR,$RMDIR,$RMFILE vars to support non-unix or
             non-standard commands for directory and file create/delete
             $REF[n] thing and target 're' are back :) see examples below

    jun2002: cade@biscom.net
             ranlib support (for versions of ar which don't have 's')

    oct2002: jambo@datamax.bg
             $DEPFLAGS added for optional args for dependency checks.
             gcc -MM $DEPFLAGS file...

    nov2002: cade@datamax.bg
             fixed modules build order (modules first)

    dec2002: cade@datamax.bg
             input file (mm.conf) format has changed. it is no more perl source
             but is simpler. near complete rewrite done.

    jan2003: cade@biscom.net
             DEPS added which could be used as extra dependencies to other
             target in the same makefile (f.e. test apps for a library)

    aug2006: cade@datamax.bg
             MM_REBUILD and MM_RESTART added. both used to handle the case in
             which mm.conf is changed and makefile needs to be recreated.
             thanks to Eduard Bloch <edi@gmx.de>

# AUTHORS

    (c) Vladi Belperchinov-Shabanski 1998-2015
          <cade@biscom.net> <cade@datamax.bg>
    (c) Ivaylo Baylov 1998
          <ivo@datamax.bg>

# LICENSE

DISTRIBUTED UNDER GNU GPLv2. FOR FULL TEXT SEE ENCLOSED 'COPYING' FILE.

# FEEDBACK

For any questions, problems, notes, contact me at:

    <cade@bis.bg> 
    <cade@biscom.net> 
    <cade@datamax.bg>

# VERSION

    Latest is 20150819
