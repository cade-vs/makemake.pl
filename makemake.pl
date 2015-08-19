#!/usr/bin/perl
#############################################################################
=pod

=head1 NAME

MakeMake.pl -- Perl-based C/C++ makefile generator

=head1 SYNOPSIS

  makemake.pl > makefile
  makemake.pl make.conf > makefile

=head1 DESCRIPTION

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
compile options and changes output file name to 'libvstring_dbg.a'

if you set target name to something that ends with '.a' -- makemake.pl will
produce library file target (i.e. will invoke AR instead of LD).

the minimum mm.conf is:

  ---cut---
  [hi]
  ---cut---

which will produce executable named 'hi' out from all sources in the current
directory...

Only one of MM_REBUILD or MM_RESTART should be used. If both used, MM_RESTART
will override MM_REBUILD. Makemake will not set default values for those two.
When either of the two is added or removed from mm.conf, makefile must be
manually recreated: 'makemake.pl > makefile' (or Makefile).

=head1 CREDITS ANS MODIFICATIONS (HISTORY)

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

=head1 AUTHORS

 (c) Vladi Belperchinov-Shabanski 1998-2015
       <cade@biscom.net> <cade@datamax.bg>
 (c) Ivaylo Baylov 1998
       <ivo@datamax.bg>

=head1 LICENSE

DISTRIBUTED UNDER GNU GPLv2. FOR FULL TEXT SEE ENCLOSED 'COPYING' FILE.

=head1 FEEDBACK

For any questions, problems, notes, contact me at:

  <cade@bis.bg> 
  <cade@biscom.net> 
  <cade@datamax.bg>

=head1 VERSION

  Latest is 20150819

=cut
#############################################################################
use File::Basename; # FIXME: avoid if possible, implement own
use strict;

our @SECTIONS; # filled by read_config()

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

print comment( "### MAKEMAKE STARTS HERE #" );
print comment( "### Created by makemake.pl on " . localtime(time()) . " #" );

# put default values
my $CC     = $C{ '_' }{ 'CC' };
my $LD     = $C{ '_' }{ 'LD' };
my $AR     = $C{ '_' }{ 'AR' };
my $RANLIB = $C{ '_' }{ 'RANLIB' };
my $SRC    = $C{ '_' }{ 'SRC' };

my $MKDIR  = $C{ '_' }{ 'MKDIR' };
my $RMDIR  = $C{ '_' }{ 'RMDIR' };
my $RMFILE = $C{ '_' }{ 'RMFILE' };

my $MM_REBUILD = $C{ '_' }{ 'MM_REBUILD' };
my $MM_RESTART = $C{ '_' }{ 'MM_RESTART' };

my @MODULES = split /\s+/, $C{ '_' }{ 'MODULES' };

my @TARGETS = @SECTIONS;

print comment( "### GLOBAL TARGETS #" );

print "default: mm_update all\n\n";
print "re: mm_update rebuild\n\n";
print "li: mm_update link\n\n";

my $_all = "all: mm_update ";
my $_clean = "clean: mm_update ";
my $_rebuild = "rebuild: mm_update ";
my $_link = "link: mm_update ";

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

print comment( "### GLOBAL (AND USER) DEFS #" );

print "\n";
print "$_ = $C{ _ }{ $_ }\n" for ( sort keys %{ $C{ '_' } } );
print "\n";

my $n = 1;
make_target( $n++, $_, $C{ $_ } ) for ( @TARGETS );

if ( @MODULES )
  {
  print comment( "### MODULES #" );
  make_module( "" );
  make_module( "clean" );
  make_module( "rebuild" );
  make_module( "link" );
  }

if( $MM_RESTART ne '' )
{
print <<END;

mm_update: $MM_RESTART

$MM_RESTART: mm.conf
\t\@echo "MAKEFILENAME: \$(MAKEFILES)"
\t\@#ifneq (\$(MAKEMAKERESTARTED),1)
\t\@echo "mm.conf changed, trying to recreate $MM_RESTART..."
\tmakemake.pl mm.conf > $MM_RESTART
\t\$(MAKE) MAKEMAKERESTARTED=1
\t@#endif

END
}
elsif( $MM_REBUILD ne '' )
{
print <<END;

mm_update: $MM_REBUILD

$MM_REBUILD: mm.conf
\tmakemake.pl mm.conf > $MM_REBUILD
\t\@echo "$MM_REBUILD recreated, please start make again..."
\t\@exit 1

END
}
else
{
print <<END;

mm_update:
\t

END
}

print comment( "### MAKEMAKE ENDS HERE #" );


###############################################################################

sub make_target
{
  my $n = shift; # name/number
  my $t = shift; # target id
  my $d = shift; # data

  my $CC         = $d->{ 'CC' };
  my $LD         = $d->{ 'LD' };
  my $AR         = $d->{ 'AR' };
  my $RANLIB     = $d->{ 'RANLIB' };
  my $CCFLAGS    = $d->{ 'CCFLAGS' } . ' ' . $d->{ 'CFLAGS' };
  my $LDFLAGS    = $d->{ 'LDFLAGS' };
  my $DEPFLAGS   = $d->{ 'DEPFLAGS' };
  my $ARFLAGS    = $d->{ 'ARFLAGS' };
  my $TARGET     = $d->{ 'TARGET' };
  my $SRC        = $d->{ 'SRC' };
  my $EXTRA      = $d->{ 'EXTRA' };
  my $EXTRA_TEXT = $d->{ 'EXTRA_TEXT' };
  my $DEPS       = $d->{ 'DEPS' };
  my $MJ_DEPS    = $d->{ 'MJ_DEPS' };
  my $OBJDIR     = ".OBJ.$t";

  if ( ! $TARGET )
    {
    $TARGET = $t;
    logger( "warning: using target name as output ($t)" );
    }

  my $J_DEPS;
  my $J_INC;
  my $J_LIB;
  if( $MJ_DEPS )
    {
    my @J = split /[,\s]+/, $MJ_DEPS;
    for my $j ( @J )
      {
      if( $j =~ /^(.*?)\/lib([^\/\.]+)(\.a)$/ )
        {
        my $p = $1;
        my $f = $2;
        $J_DEPS .= "$j ";
        $J_INC  .= "-I$p ";
        $J_LIB  .= "-L$p -l$f ";
        }

      }
    }

  print comment( "### TARGET $n: $TARGET #" );

  print "CC_$n       = $CC\n";
  print "LD_$n       = $LD\n";
  print "AR_$n       = $AR\n";
  print "RANLIB_$n   = $RANLIB\n";
  print "CCFLAGS_$n  = $CCFLAGS $J_INC\n";
  print "LDFLAGS_$n  = $LDFLAGS $J_LIB\n";
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
    # push @OBJ,"$OBJDIR/$1.o";
    push @OBJ,"$OBJDIR/" . basename($1) . ".o";
    }

  print comment( "### SOURCES FOR TARGET $n: $TARGET #" );
  print "SRC_$n= \\\n";
  for( @SRC )
    { print "     $_ \\\n"; }

  print comment( "#### OBJECTS FOR TARGET $n: $TARGET #" );
  print "OBJ_$n= \\\n";
  for( @OBJ )
    {
    print "     $_ \\\n";
    }

  print comment( "### TARGET DEFINITION FOR TARGET $n: $TARGET #" );

  print "$OBJDIR: \n" .
        "\t\$(MKDIR) $OBJDIR\n\n";

  print "$t: $DEPS $J_DEPS $OBJDIR \$(OBJ_$n)\n";
  my $target_link;
  if ( $TARGET =~ /\.a$/ )
    {
    $target_link  = "\t\$(AR_$n) \$(ARFLAGS_$n) \$(TARGET_$n) \$(OBJ_$n)\n";
    $target_link .= "\t\$(RANLIB_$n) \$(TARGET_$n)\n";
    }
  else
    {
    $target_link = "\t\$(LD_$n) \$(OBJ_$n) \$(LDFLAGS_$n) -o \$(TARGET_$n)\n";
    }

  $target_link .= "\t$EXTRA\n" if $EXTRA ne '';
  $target_link .= "\n";
  print $target_link;

  print "clean-$t: \n" .
        "\t\$(RMFILE) \$(TARGET_$n)\n" .
        "\t\$(RMDIR) $OBJDIR\n\n";

  print "rebuild-$t: clean-$t $t\n\n";

  print "link-$t: $OBJDIR \$(OBJ_$n)\n" .
        "\t\$(RMFILE) $TARGET\n" .
        $target_link;

  print comment( "### TARGET OBJECTS FOR TARGET $n: $TARGET #" );

  while( @SRC and @OBJ )
    {
    my $S = shift @SRC;
    my $O = shift @OBJ;
    my $DEPS = file_deps( $S, $DEPFLAGS  );

    my $SS = sprintf "%-20s", $S; # pretty printing
    print "$O: $S $DEPS\n" .
          "\t\$(CC_$n) \$(CFLAGS_$n) \$(CCFLAGS_$n) -c $SS -o $O\n";
    }

  print "\n";

  print "\n$EXTRA_TEXT\n\n" if $EXTRA_TEXT ne '';

  logger( "info: target $t ($TARGET) ok" );
}

###############################################################################

sub make_module
{
  my $target = shift;

  my $modules_list = "";
  for( @MODULES )
    {
    $modules_list .= "\t\$(MAKE) -C $_ $target\n";
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

  @SECTIONS = ();

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
      $sec = $1;
      push @SECTIONS, $sec;
      my $isa = ( $3 ) || '_';
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
    if ( /^\s*(\S+)+\s*(\+)?=+(.*)$/ )
      {
      my $name = uc $1;
      my $add  = $2;
      my $v = fixval( $3 );
      $v =~ s/\$\((\S+)\)/ $hr->{ $sec }{ uc $1 } || $hr->{ '_' }{ uc $1 } || ''/ge;
      if ( $add eq '+' )
        {
        $hr->{ $sec }{ $name } .= ' ' . $v;
        }
      else
        {
        $hr->{ $sec }{ $name } = $v;
        }
      next;
      }
    if ( /^\s*BEGIN_EXTRA/i )
      {
      my $v;
      while(<$i>)
        {
        last if /^\s*END_EXTRA/i;
        $v .= $_;
        }
      $hr->{ $sec }{ 'EXTRA_TEXT' } = $v;
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
  $s =~ s/^\s+//;
  $s =~ s/\s+$//;
  $s =~ s/^["'](.+)['"]$/$1/;
  return $s;
}

###############################################################################

sub comment
{
  my $s = shift;
  $s .= '#' x 80;
  $s = substr( $s, 0, 80 );
  return "\n$s\n\n";
}

sub find_config
{
  for ( @_ )
    {
    return $_ if -e $_;
    };
  return undef;
}

sub logger
{
  my $msg = shift;
  print STDERR "$argv0: $msg\n";
}

### EOF #######################################################################

