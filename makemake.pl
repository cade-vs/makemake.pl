#!/usr/bin/perl
#############################################################################
=pod
$Id: makemake.pl,v 1.5 2002/12/15 16:48:12 cade Exp $
-----------------------------------------------------------------------------

MakeMake.pl -- makefiles creating utility

(c) Vladi Belperchinov-Shabanski 1998-2002 <cade@biscom.net> <cade@datamax.bg>
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

oct2002: jambo@datamax.bg
         $DEPFLAGS added for optional args for dependency checks.
         gcc -MM $DEPFLAGS file...

nov2002: cade@datamax.bg
         fixed modules build order (modules first)

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
use strict;

my %C = ( '_' =>  { 
                  'CC'    => 'gcc',
                  'LD'    => 'gcc',
                  'AR'    => 'ar rv',
                  'RANLIB'=> 'ranlib',
                  'SRC'   => '*.c *.cpp *.cc *.cxx',
                
                  'MKDIR' => 'mkdir -p',
                  'RMDIR' => 'rm -rf',
                  'RMFILE'=> 'rm -f',
                   } );

my $C = find_config( $ARGV[0],
                     "mm.conf",
                     "make.make",
                   );

my ( $argv0 ) = $0 =~ /([^\/]+)$/g;

read_config( $C, \%C ) or exit(1);

#############################################################################

print "### MAKEMAKE STARTS HERE #########################################\n" .
      "#\n" .
      "# Created by makemake.pl on " . localtime(time()) . "\n" .
      "#\n" .
      "##################################################################\n";

# put default values
my $CC     = $C{ '_' }{ 'CC' };
my $LD     = $C{ '_' }{ 'LD' };
my $AR     = $C{ '_' }{ 'AR' };
my $RANLIB = $C{ '_' }{ 'RANLIB' };
my $SRC    = $C{ '_' }{ 'SRC' };

my $MKDIR  = $C{ '_' }{ 'MKDIR' };
my $RMDIR  = $C{ '_' }{ 'RMDIR' };
my $RMFILE = $C{ '_' }{ 'RMFILE' };

my @MODULES = split /\s+/, $C{ '_' }{ 'MODULES' };

my @TARGETS = grep !/^_$/, keys %C;

print "\n### GLOBAL TARGETS ###############################################\n\n";

print "default: all\n\n";
print "re: rebuild\n\n";
print "li: link\n\n";

my $_all = "all: ";
my $_clean = "clean: ";
my $_rebuild = "rebuild: ";
my $_link = "link: ";

if ( @MODULES )
  {
  $_all .= "modules ";
  $_clean .= "clean-modules ";
  $_rebuild .= "rebuild-modules ";
  $_link .= "link-modules ";
  }
for( @TARGETS )
  {
  $_all .= "$_ ";
  $_clean .= "clean-$_ ";
  $_rebuild .= "rebuild-$_ ";
  $_link .= "link-$_ ";
  }

print "$_all\n\n$_clean\n\n$_rebuild\n\n$_link\n";

print "\n### GLOBAL (AND USER) DEFS ##########################################\n";

print "\n";
print "$_ = $C{ _ }{ $_ }\n" for ( sort keys %{ $C{ '_' } } );
print "\n";

my $n = 1;
make_target( $n++, $_, $C{ $_ } ) for ( @TARGETS );

if ( @MODULES )
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
  my $n = shift; # name/number
  my $t = shift; # target id
  my $d = shift; # data

  my $CC       = $d->{ 'CC' };
  my $LD       = $d->{ 'LD' };
  my $AR       = $d->{ 'AR' };
  my $RANLIB   = $d->{ 'RANLIB' };
  my $CCFLAGS  = $d->{ 'CCFLAGS' } . ' ' . $d->{ 'CFLAGS' };
  my $LDFLAGS  = $d->{ 'LDFLAGS' };
  my $DEPFLAGS = $d->{ 'DEPFLAGS' };
  my $ARFLAGS  = $d->{ 'ARFLAGS' };
  my $TARGET   = $d->{ 'TARGET' };
  my $SRC      = $d->{ 'SRC' };
  my $OBJDIR   = ".OBJ.$n.$t";

  if ( ! $TARGET )
    {
    $TARGET = $t;
    logger( "warning: using target name as output ($t)" );
    }

  print "### TARGET $n: $TARGET #######################################\n\n";

  print "CC_$n       = $CC\n";
  print "LD_$n       = $LD\n";
  print "AR_$n       = $AR\n";
  print "RANLIB_$n   = $RANLIB\n";
  print "CCFLAGS_$n  = $CCFLAGS\n";
  print "LDFLAGS_$n  = $LDFLAGS\n";
  print "DEPFLAGS_$n = $DEPFLAGS\n";
  print "ARFLAGS_$n  = $ARFLAGS\n";
  print "TARGET_$n   = $TARGET\n";

  my @OBJ;
  my @SRC;

  for( glob( $SRC ) )
  # or
  # for( split( /[\s\n]+/, `ls -1 $_SRC 2> /dev/null` ) )
    {
    push @SRC, $_;
    /^(.*)\.[^\.]+$/;
    push @OBJ,"$OBJDIR/$1.o";
    }

  print "\n### SOURCES FOR TARGET $n: $TARGET #################################\n\n";
  print "SRC_$n= \\\n";
  for( @SRC )
    { print "     $_ \\\n"; }

  print "\n#### OBJECTS FOR TARGET $n: $TARGET ################################\n\n";
  print "OBJ_$n= \\\n";
  for( @OBJ )
    { print "     $_ \\\n"; }

  print "\n### TARGET DEFINITION FOR TARGET $n: $TARGET #######################\n\n";

  print "$OBJDIR: \n" .
        "\t\$(MKDIR) $OBJDIR\n\n";

  print "$t: $OBJDIR \$(OBJ_$n)\n";
  my $target_link;
  if ( $TARGET =~ /\.a$/ )
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

  print "clean-$t: \n" .
        "\t\$(RMFILE) \$(TARGET_$n)\n" .
        "\t\$(RMDIR) $OBJDIR\n\n";

  print "rebuild-$t: clean-$t $t\n\n";

  print "link-$t: $OBJDIR \$(OBJ_$n)\n" .
        "\t\$(RMFILE) $TARGET\n" .
        $target_link;

  print "### TARGET OBJECTS FOR TARGET $n: $TARGET ##########################\n\n";

  while( @SRC and @OBJ )
    {
    my $S = shift @SRC;
    my $O = shift @OBJ;
    my $DEPS = file_deps( $S, $DEPFLAGS  );
    print "$O: $S $DEPS\n" .
          "\t\$(CC_$n) \$(CFLAGS_$n) \$(CCFLAGS_$n) -c $S -o $O\n";
    }

  print "\n";
  
  logger( "info: target $t ($TARGET) ok" );
}

###############################################################################

sub make_module
{
  my $target = shift;

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
  my $depflags = shift;
  my $deps = `$CC -MM $depflags $fname 2> /dev/null`;
  $deps =~ s/^[^:]+://;
  $deps =~ s/[\n\r]$//;
  return $deps;
}

#############################################################################

sub read_config
{
  my $fn = shift;
  my $hr = shift;
  my $sec = '_';
  my $i;
  if(! open $i, $fn )
    {
    logger( "error: cannot read file $fn" );
    return 0;
    }
  while(<$i>)
    {
    chomp;
    next if /^\s*[#;]/;
    next unless /\S/;
    if ( /^\s*\[\s*(\S+?)\s*(:\s*(\S+?))?\s*\]/ )
      {
      $sec = lc $1;
      my $isa = ( lc $3 ) || '_';
      if ( $hr->{ $sec } )
        {
        logger( "error: duplicate target $sec" );
        return 0;
        }
      if ( $isa and $hr->{ $isa } )
        {
        my $ir = $hr->{ $isa }; # inherited hash reference
        while( my ( $k, $v ) = each %$ir )
          {
          $hr->{ $sec }{ $k } = $v;
          }
        }
      next;
      }
    if ( /^\s*(\S+)+\s*(\+)?=+\s*(.+)\s*$/ )
      {
      if ( $2 eq '+' )
        {
        $hr->{ $sec }{ uc $1 } .= ' ' . fixval( $3 );
        }
      else
        {
        $hr->{ $sec }{ uc $1 } = fixval( $3 );
        }
      next;
      }
    logger( "error: parse error in $fn, line $., ($_)" );
    return 0;  
    }
  close $i;  
  return 1;
}

sub fixval
{
  my $s = shift;
  $s =~ s/^["'](.+)['"]$/$1/;
  return $s;
}

###############################################################################

sub find_config
{
  for ( @_ )
    {
    return $_ if -e $_;
    };
  return undef;
}

###############################################################################

sub logger
{
  my $msg = shift;
  print STDERR "$argv0: $msg\n";
}

### EOF #######################################################################

