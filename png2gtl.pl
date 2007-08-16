#!/usr/bin/perl -w
#
# png2gtl - converts PNGs to Cyberboard GTL files
# Copyright (C) 2006 Joel Uckelman (uckelman@nomic.net)
#  
# Usage: png2gtl 00bbggrr full.png half.png... tiles.gtl
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

# parase options
use Getopt::Long;
Getopt::Long::Configure('bundling');
GetOptions('version'   => \$vers,
           'help'      => \$help);

if ($help) {
   print <<HELP;
Usage: png2gtl [OPTION]... [version] (smcolor fullpng halfpng)...
Convert PNGs to Cyberboard GTL files.

Options:
   --help               display this help and exit
   --version            print version information and exit

Specifying the GTL version is optional; default is 3.0. The GTL version,
if given, must be formatted X.Y.

Please visit http:://www.nomic.net/~uckelman/cbutils for updates and bug
reports.   
HELP
   exit;
}
elsif ($vers) {
   print 'png2gtl version 0.9.0';
   exit;
}

# set values for GTL header
$sig = 'GTLB';

# set the major and minor GTL version
if ($ARGV[0] =~ /^[0-9A-Fa-f]{1,8}$/) {
   # first arg is a hex string, so use default version
   $vmajor = 0x03;
   $vminor = 0x00;
}
else {
   # user has specified a version
   ($vmajor, $vminor) = $ARGV[0] =~ /^(\d+)\.(\d+)$/
    or die "$0: malformed GTL version\n";
   shift @ARGV;
}

# check that we were given a full set of arguments
die "$0: too few arguments\n" if (scalar @ARGV - 1) % 3;
$numtiles = ((scalar @ARGV) - 1) / 3;

$ofile = $ARGV[$#ARGV];
open OUT, ">$ofile" or die "$0: cannot write $ofile: $!\n";

# vminor before vmajor because we're packed little-endian
print OUT pack('A4CCL', $sig, $vminor, $vmajor, $numtiles);

# set up our image object as a PNG
use Image::Magick;
$img = Image::Magick->new(magick => 'png');

# unbuffer STDOUT so we get error messages in the correct order
$| = 1;

for ($i = 0; $i < $numtiles; ++$i) {
   # small tile color
   print OUT pack('L', hex($ARGV[3*$i]));
   # COLORREF is 00bbggrr

   # process the full-size tile
#   &png2dib($ARGV[3*$i+1]);
   read_png($ARGV[3*$i+1]);
   write_dib($ARGV[3*$i+1]);

   # process the half-size tile
#   &png2dib($ARGV[3*$i+2]);
   read_png($ARGV[3*$i+2]);
   write_dib($ARGV[3*$i+2]);
}

close OUT;


sub read_png {
   # read the PNG
   my ($ifile) = @_;
   open IN, $ifile or die "$0: cannot open $ifile: $!\n";
   my $err = $img->Read(file => \*IN);
   die "$0: ImageMagick error: $err\n" if "$err";
   close IN;
}


sub write_dib {
   my ($ifile) = @_;   

   if ($vmajor >= 3) {
      # make a 16-bit 5-6-5 DIB
   } 
   else {
      # make an 8-bit DIB
      $img->Set(type => 'palette');
   }

   open FOO, '>test.dib' or die "$0: cannot open test.dib: $!\n";
   $err = $img->Write(file => \*FOO, filename => 'test.dib', depth => 8);
   close FOO;
   
   # write the tile as Packed_DIB
   my ($dib) = $img->ImageToBlob(magick => 'dib');
   die "$0: failed to convert PNG $ifile to DIB\n" unless defined $dib;
   print OUT pack('La*', length $dib, $dib);
   @$img = ();
}



sub png2dib {
   # read the PNG
   my ($ifile) = @_;
   open IN, $ifile or die "$0: cannot open $ifile: $!\n";
   my $err = $img->Read(file => \*IN);
   die "$0: ImageMagick error: $err\n" if "$err";
   close IN;

   # write the tile as Packed_DIB
   my ($dib) = $img->ImageToBlob(magick => 'dib');
   die "$0: failed to convert PNG $ifile to DIB\n" unless defined $dib;
   print OUT pack('La*', length $dib, $dib);
   @$img = ();   
}
