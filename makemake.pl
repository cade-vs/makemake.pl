#!/usr/bin/perl
#############################################################################
=pod
$Id: makemake.pl,v 1.1 2002/08/17 11:54:32 cade Exp $
-----------------------------------------------------------------------------

MakeMake.pl -- makefiles creating utility

(c) Vladi Belperchinov-Shabanski 1998-2001 <cade@biscom.net> <cade@datamax.bg>
(c) Ivaylo Baylov 1998 <ivo@datamax.bg>

DISTRIBUTED `AS IS' WITHOUT ANY KIND OF WARRANTY OR ELSE.
YOU MAY USE, MODIFY AND DISTRIBUTE THIS UTILITY AS LONG AS
THE ORIGINAL CREDITS ARE KEPT INTACT!
(AND YOU CREDIT YOURSELF FOR THE APROPRIATE MODIFICATIONS)

-----------------------------------------------------------------------------

CREDITS ANS MODIFICATIONS:

dec1998: cade@biscom.net, ivo@datamax.bg
         * first version *
         though there were a number of utilities like this I still haven't
         found what I'm looking for... :)
         the closest approach is `tmake' of Troll Tech used for `Qt', but
         is far too complex...

oct1999: cade@biscom.net
         added multi-target feature

aug2000: cade@biscom.net
         general cleanup, target clean uses `rm -rf' instead of `rmdir'
         added targets `rebuild' and `link' (does `relink' actually)
         globbing replaced with the use of `ls'

dec2000: cade@biscom.net
         added modules (subdir targets) support:
         $MODULES = "module1 module2 ...";
         now target name is required and not set to `a.out' by default

mar2001: cade@biscom.net
         added $MKDIR,$RMDIR,$RMFILE vars to support non-unix or
         non-standard commands for directory and file create/delete
         $REF[n] thing and target `re' are back :) see examples below

jun2002: cade@biscom.net
         ranlib support (for versions of ar which don't have `s')

-----------------------------------------------------------------------------

GENERAL USAGE AND TIPS:
input file is `mm.conf' or/and `make.make' or given file as 1st arg
output is printed to the stdout

usage: makemake.pl > makefile
usage: makemake.pl mm.dos.conf > makefile
...

mm.conf/make.make files are actually real perl programs so you can do
whatever you want in there as long as you provide at the end variables
used by makemake.pl:

---cut---
$CC      = "gcc";              # set compiler executable
$LD      = "gcc";              # set linker executable
$CFLAGS  = "-g";               # this is concatenated to $CCFLAGS
$CCFLAGS = "-I../vslib -I/usr/include/ncurses -O2"; # set compiler flags
$LDFLAGS = "-L../vslib -lvslib -lncurses"; # set linker flags executable
$TARGET  = "vfu";              # set target name
$SRC     = "*.cpp";            # set source files
$MODULES = "vslib vfu ftparc"; # set modules (subdirectory targets)
---cut---

If you set target name to something that ends with `.a' -- makemake.pl will
produce library file target!




Multiple targets are defined in this way:

---cut---
# this is target 0 (first one!)
$CC[0]      = "gcc";              # set compiler executable
$LD[0]      = "gcc";              # set linker executable
$CFLAGS[0]  = "-g";               # this is concatenated to $CCFLAGS
$CCFLAGS[0] = "-I../vslib -I/usr/include/ncurses -O2"; # set compiler flags
$LDFLAGS[0] = "-L../vslib -lvslib -lncurses"; # set linker flags executable
$TARGET[0]  = "vfu";              # set target name
$SRC[0]     = "*.cpp";            # set source files

# this is target 1 (second one!)
$CC[1]      = "gcc";              # set compiler executable
$LD[1]      = "gcc";              # set linker executable
$CFLAGS[1]  = "-g";               # this is concatenated to $CCFLAGS
$CCFLAGS[1] = "-I../vslib -I/usr/include/ncurses -O2"; # set compiler flags
$LDFLAGS[1] = "-L../vslib -lvslib -lncurses"; # set linker flags executable
$TARGET[1]  = "vfu";              # set target name
$SRC[1]     = "*.cpp";            # set source files

# modules are global! you cannot have $MODULES[0] for example.
$MODULES    = "vslib vfu ftparc"; # set modules (subdirectory targets)
---cut---





Fields/vars without numbers ( [0]... ) are considered target 0 as well as
globals so you can miss everything except $TARGET[n] and all the rest will
be filled auto:

---cut---
# this is target 0 and also globals!
$CC      = "gcc";              # set compiler executable
$LD      = "gcc";              # set linker executable
$CCFLAGS = "-I../vslib -I/usr/include/ncurses -O2"; # set compiler flags
$LDFLAGS = "-L../vslib -lvslib -lncurses"; # set linker flags executable
$SRC     = "*.cpp";            # set source files

# this is target 0 (first one!)
$CFLAGS[0]  = "-g";       # we want debug info!
$TARGET[0]  = "test-vfu"; # set target name for debug binary

# this is target 1 (second one!)
$CFLAGS[1]  = "-O2";      # now we prefer to optimize!
$TARGET[1]  = "vfu";      # set target name for non-debug binary

# modules are global! you cannot have $MODULES[0] for example.
$MODULES    = "vslib vfu ftparc"; # set modules (subdirectory targets)
---cut---





NOTE: You cannot skip target numbers! If you do this:

---cut---
# this is target 0 (first one!)
$CFLAGS[0]  = "-g";       # we want debug info!
$TARGET[0]  = "test-vfu"; # set target name for debug binary

# this is target 2 (we want third here but this is wrong!)
$CFLAGS[2]  = "-O2";      # now we prefer to optimize!
$TARGET[2]  = "vfu";      # set target name for non-debug binary
---cut---

You will end up with just one target!



The following fields/variables have default values and so you may skip
them if you want:

---cut---
$CC     = "gcc";                  # default compiler
$LD     = "gcc";                  # default linker
$AR     = "ar rvs";               # default archiver (librarian)
$SRC    = "*.c *.cpp *.cc *.cxx"; # default sources set

# usually under unix you don't need to change these
$MKDIR  = "mkdir -p";  # command to create directory
$RMDIR  = "rm -rf";    # command to remove directory
$RMFILE = "rm -f";     # command to remove file(s)
---cut---

i.e. the minimum mm.conf is:

---cut---
$TARGET = "hi";
---cut---



-----------------------------------------------------------------------------

FOR ANY PROBLEMS, REMARKS, NOTES -- CONTACT AUTHORS FREELY!
Note that since Ivo Baylov does not work actively on makemake.pl you
should try first to contact Vladi <cade@biscom.net> or <cade@datamax.bg>

-----------------------------------------------------------------------------
=cut
#############################################################################

if ( $ARGV[0] )
  {
  do $ARGV[0];
  }
else
  {
  if ( !(( -e "mm.conf" ) || ( -e "make.make" )) )
    { die "makemake.pl: cannot find neither mm.conf nor make.make files\n" };

  do 'mm.conf';
  do 'make.make';
  }

  print "### MAKEMAKE STARTS HERE #########################################\n" .
        "#\n" .
        "# Created by makemake.pl on " . localtime(time()) . "\n" .
        "#\n" .
        "##################################################################\n";

  # put default values
  $CC     = "gcc"                  unless $CC;
  $LD     = "gcc"                  unless $LD;
  $AR     = "ar rv"                unless $AR;
  $RANLIB = "ranlib"               unless $RANLIB;
  $SRC    = "*.c *.cpp *.cc *.cxx" unless $SRC;

  $MKDIR  = "mkdir -p"             unless $MKDIR;
  $RMDIR  = "rm -rf"               unless $RMDIR;
  $RMFILE = "rm -f"                unless $RMFILE;

  # $TARGET = "a.out"             unless $TARGET;

  # if no target defined in the TARGET array take defaults

  $TARGET[0] = $TARGET if $TARGET && $#TARGET == -1;

  print "\n### GLOBAL TARGETS ###############################################\n";

  print "\ndefault: all\n";
  print "\nre: rebuild\n\n";
  print "\nli: link\n\n";

  $_all = "all: ";
  $_clean = "clean: ";
  $_rebuild = "rebuild: ";
  $_link = "link: ";

  for( @TARGET )
    {
    $_all .= "$_ ";
    $_clean .= "clean-$_ ";
    $_rebuild .= "rebuild-$_ ";
    $_link .= "link-$_ ";
    }
  if ( $MODULES )
    {
    $_all .= "modules";
    $_clean .= "clean-modules ";
    $_rebuild .= "rebuild-modules ";
    $_link .= "link-modules ";
    }

  print "$_all\n\n$_clean\n\n$_rebuild\n\n$_link\n";

  print "\n### GLOBAL DEFS ##################################################\n";

  print "\n";
  print "MKDIR      = $MKDIR\n";
  print "RMDIR      = $RMDIR\n";
  print "RMFILE     = $RMFILE\n\n";

  $z = 0;
  while( $z <= $#TARGET )
    { make_target( $z++ ); } # output all targets...


  if ( $MODULES )
    {
    print "### MODULES #####################################################\n\n";
    make_module( "" );
    make_module( "clean" );
    make_module( "rebuild" );
    make_module( "link" );
    }

print "\n### MAKEMAKE ENDS HERE ###########################################\n";


###############################################################################

sub make_target
{
  my $n = shift;

  print "### TARGET $n: $TARGET[$n] #########################################\n\n";

  #=======================================================================
  # target init and setups

  if ( $REF[$n] )
    {
    # this tells us this target data is refering another one
    # so we should copy referred data and then proceed normally
    $_CC      = $CC[$REF[$n]];
    $_LD      = $LD[$REF[$n]];
    $_AR      = $AR[$REF[$n]];
    $_RANLIB  = $RANLIB[$REF[$n]];
    $_CFLAGS  = $CFLAGS[$REF[$n]] ;
    $_CCFLAGS = $CCFLAGS[$REF[$n]];
    $_LDFLAGS = $LDFLAGS[$REF[$n]];
    $_ARFLAGS = $ARFLAGS[$REF[$n]];
    $_TARGET  = $TARGET[$REF[$n]];
    $_SRC     = $SRC[$REF[$n]];
    }

  # take local values just to be handy
  $_CC      = $CC[$n]      if $CC[$n];
  $_LD      = $LD[$n]      if $LD[$n];
  $_AR      = $AR[$n]      if $AR[$n];
  $_RANLIB  = $RANLIB[$n]  if $RANLIB[$n];
  $_CFLAGS  = $CFLAGS[$n]  if $CFLAGS[$n];
  $_CCFLAGS = $CCFLAGS[$n] if $CCFLAGS[$n];
  $_LDFLAGS = $LDFLAGS[$n] if $LDFLAGS[$n];
  $_ARFLAGS = $ARFLAGS[$n] if $ARFLAGS[$n];
  $_TARGET  = $TARGET[$n]  if $TARGET[$n];
  $_SRC     = $SRC[$n]     if $SRC[$n];

  $_OBJDIR = ".OBJ.$n.$_TARGET";

  # for all undefined values -- take default ones
  $_CC      = $CC      unless $_CC;
  $_LD      = $LD      unless $_LD;
  $_AR      = $AR      unless $_AR;
  $_RANLIB  = $RANLIB  unless $_RANLIB;
  $_CFLAGS  = $CFLAGS  unless $_CFLAGS;
  $_CCFLAGS = $CCFLAGS unless $_CCFLAGS;
  $_LDFLAGS = $LDFLAGS unless $_LDFLAGS;
  $_ARFLAGS = $ARFLAGS unless $_ARFLAGS;
  $_TARGET  = $TARGET  unless $_TARGET;
  $_SRC     = $SRC     unless $_SRC;

  #=======================================================================

  # now print main target variables
  print "CC_$n      = $_CC\n";
  print "LD_$n      = $_LD\n";
  print "AR_$n      = $_AR\n";
  print "RANLIB_$n  = $_RANLIB\n";
  print "CFLAGS_$n  = $_CFLAGS\n";
  print "CCFLAGS_$n = $_CCFLAGS\n";
  print "LDFLAGS_$n = $_LDFLAGS\n";
  print "ARFLAGS_$n = $_ARFLAGS\n";
  print "TARGET_$n  = $_TARGET\n";

  my @_OBJ;
  my @_SRC;

  # for( glob($_SRC) )
  # or
  for( split( /[\s\n]+/, `ls -1 $_SRC 2> /dev/null` ) )
    {
    push @_SRC,$_;
    /(.*)\.[^\.]+/;
    push @_OBJ,"$_OBJDIR/$1.o";
    }

  print "\n### SOURCES FOR TARGET $n: $_TARGET #################################\n\n";
  print "SRC_$n= \\\n";
  for( @_SRC )
    { print "     $_ \\\n"; }



  print "\n#### OBJECTS FOR TARGET $n: $_TARGET ################################\n\n";
  print "OBJ_$n= \\\n";
  for( @_OBJ )
    { print "     $_ \\\n"; }



  print "\n### TARGET DEFINITION FOR TARGET $n: $_TARGET #######################\n\n";

  print "$_OBJDIR: \n" .
        "\t\$(MKDIR) $_OBJDIR\n\n";

  print "$_TARGET: $_OBJDIR \$(OBJ_$n)\n";
  if ($_TARGET =~ /\.a[ \t]*$/)
    {
    $target_link  = "\t\$(AR_$n) \$(ARFLAGS_$n) \$(TARGET_$n) \$(OBJ_$n)\n";
    $target_link .= "\t\$(RANLIB_$n) \$(TARGET_$n)\n";
    $target_link .= "\n";
    }
  else
    {
    $target_link = "\t\$(LD_$n) \$(OBJ_$n) \$(LDFLAGS_$n) -o \$(TARGET_$n)\n\n";
    }
  print $target_link;

  print "clean-$_TARGET: \n" .
        "\t\$(RMFILE) \$(TARGET_$n)\n" .
        "\t\$(RMDIR) $_OBJDIR\n\n";

  print "rebuild-$_TARGET: clean-$_TARGET $_TARGET\n\n";

  print "link-$_TARGET: $_OBJDIR \$(OBJ_$n)\n" .
        "\t\$(RMFILE) $_TARGET\n" .
        $target_link;

  print "### TARGET OBJECTS FOR TARGET $n: $_TARGET ##########################\n\n";

  $c = 0;
  while( $c <= $#_OBJ )
    {
    $deps = file_deps( $_SRC[$c] );
    print "$_OBJ[$c]: $deps\n" .
          "\t\$(CC_$n) \$(CFLAGS_$n) \$(CCFLAGS_$n) -c $_SRC[$c] -o $_OBJ[$c]\n";
    $c++;
    }

  print "\n";
}

###############################################################################

sub make_module
{
  my $target = shift;

  my @MODULES = split( /\s+/, $MODULES );
  my $modules_list = "";
  for( @MODULES )
    {
    $modules_list .= "\tmake -C $_ $target\n";
    }
  $target .= "-" if $target;
  print $target . "modules:\n$modules_list\n";
}

###############################################################################

sub file_deps
{
  my $fname = shift;
  $_ = `$CC -MM $fname 2> /dev/null`;
  s/^[^:]+://;
  s/[\n\r]$//;
  $_;
}

### EOF #######################################################################

