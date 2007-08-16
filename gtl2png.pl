#!/usr/bin/perl -w
#
# gtl2png - converts Cyberboard GTL files to PNGs
# Copyright (C) 2006 Joel Uckelman (uckelman@nomic.net)
#  
# Usage: gtl2png gtlfile...
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

# parse options
$verbose = 0;

use Getopt::Long;
Getopt::Long::Configure('bundling');
GetOptions('f|full'     => \$full,
           'h|half'     => \$half,
           'v|verbose+' => \$verbose,
           'version'    => \$vers,
           'help'       => \$help);

if ($help) {
   print <<HELP;
Usage: gtl2png [OPTION]... gtlfile...
Convert Cyberboard GTL files to PNGs.

Options:
   -f, --full           extract full-size tiles only
   -h, --half           extract half-size tiles only
   -v, --verbose        print additional information on image extraction
       --help           display this help and exit
       --version        print version information and exit

Please visit http:://www.nomic.net/~uckelman/cbutils for updates and bug
reports.
HELP
   exit;
}
elsif ($vers) {
   print 'gtl2png version 0.9.0';
   exit;
}

# if no output option specified, output both full- and half-size tiles
if (!$full && !$half) { $full = $half = 1; }

die "$0: no input file specified\n" unless scalar @ARGV;

# set up our image object as a DIB
use Image::Magick;
$img = Image::Magick->new;

# unbuffer STDOUT so we get error messages in the correct order
$| = 1;

# loop over the GTL files given on the command line
foreach $ifile (@ARGV) {
   open IN, $ifile or die "$0: cannot open $ifile: $!\n";
   print $ifile if $verbose;

   $odir = $ifile;
   $odir =~ s/.*\///;    # chop off path
   $odir =~ s/\.gtl$//;  # chop off .gtl
   -d $odir or mkdir $odir or die "$0: cannot create directory $odir: $!\n";

   # get the header information
   read IN, $chars, 10 or die "$0: $ifile is not a GTL file\n";

   # vminor before vmajor because we're packed little-endian
   ($sig, $vminor, $vmajor, $numtiles) = unpack('A4CCL', $chars);
   $digits = length $numtiles;

   # check for the identifying string
   die "$0: $ifile is not a GTL file\n" if $sig ne 'GTLB';
   printf "\nversion %x.%02x,", $vmajor, $vminor if $verbose > 1;
   if ($verbose) {
      print " $numtiles tile";
      print 's' if $numtiles > 1;
   }
   print "\n" if $verbose > 1;

   for ($i = 0; $i < $numtiles; ++$i) {
      if ($verbose > 1) { print "\ntile $i\n"; }
      elsif ($verbose) { print '.'; }

      read IN, $chars, 4 or die "\n$0: $ifile is not a GTL file\n";
      if ($verbose > 1) {
         # COLORREF is 00bbggrr
         ($scolor) = unpack("L", $chars);
         printf "small tile color: %.8x\n", $scolor;
      }

      $ofbase = sprintf(">%s/%0${digits}u", $odir, $i);

      my $dib;

      # process the full-size tile
      $dib = &read_dib;
      &write_png("$ofbase.f.png", $dib) if ($full);

      # process the half-size tile
      $dib = &read_dib;
      &write_png("$ofbase.h.png", $dib) if ($half);
   }

   print "\n" if $verbose;
}


sub read_dib {
   # read the tile as DIB data
   read IN, $chars, 4 or die "\n$0: $ifile is not a GTL file\n";
   my ($dlen) = unpack('L', $chars);
   print "DIB size: $dlen\n" if $verbose > 1;
   my $blob;
   read IN, $blob, $dlen or die "\n$0: $ifile is not a GTL file\n";
   return $blob;
}


sub write_png {
   my ($ofile, $blob) = @_;

   if ($vmajor >= 3) {
      # Cyberboard 3 uses 16-bit 5-6-5 DIBs
      # build BMP header because ImageMagick chokes
      # on 16-bit 5-6-5 DIBs:
      #     14 bytes for the BITMAPFILEHEADER   
      #     40 bytes for the BITMAPINFOHEADER
      #     12 bytes for the color masks
      # so the data is offset by 66 bytes
      # NB: this should be unnecessary with ImageMagick >= 6.2.7-7
      $header = pack('A2Lx4L', ('BM', 14 + length $blob, 66));
      $blob = $header . $blob;
      $img->Set(magick => 'bmp');
   }
   else {
      $img->Set(magick => 'dib');
   }

   # write the tile as a PNG
   my $err = $img->BlobToImage(($blob));
   die "\n$0: ImageMagick error: $err\n" if "$err";
   
   open OUT, $ofile or die "\n$0: cannot write $ofile: $!\n";
   $err = $img->Write(file => \*OUT, filename => $ofile);
   die "\n$0: ImageMagick error: $err\n" if "$err";
   close OUT;
   
   @$img = ();
}
