#!/usr/bin/perl -w
#
# gtl2png.pl - converts Cyberboard GTL files to PNGs
# Copyright (C) 2006 Joel Uckelman (uckelman@nomic.net)
#  
# Usage: gtl2png.pl gtlfile...
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

foreach (@ARGV) {
   print $_;
   open IN, $_;

   s/\.gtl$//;
   $odir = $_;

   mkdir $odir;

   read IN, $chars, 10;
   # vminor before vmajor because we're little-endian
   ($sig, $vminor, $vmajor, $numtiles) = unpack('A4CCL', $chars);
   $digits = length($numtiles);

   die if $sig ne 'GTLB';
   printf " %x.%x %u ", $vmajor, $vminor, $numtiles;

   for ($i = 0; $i < $numtiles; ++$i) {
      #print "\n\ntile $i\n";
      print '.';

      read IN, $chars, 4;
      #($scolor) = unpack("L", $chars);
      #printf "small tile color: %.8x\n", $scolor;
      # COLORREF is 00bbggrr

      read IN, $chars, 4;
      ($dlen) = unpack('L', $chars);
      #print "full DIB size: $dlen\n";

      open OUT, sprintf(">%s/%0${digits}u.f.dib", $odir, $i);
      read IN, $chars, $dlen;
      print OUT $chars;
      close OUT;

      read IN, $chars, 4;
      ($dlen) = unpack('L', $chars);
      #print "half DIB size: $dlen\n";

      open OUT, sprintf(">%s/%0${digits}u.h.dib", $odir, $i);
      read IN, $chars, $dlen;
      print OUT $chars;
      close OUT;
   }

   `mogrify -format png $odir/*.dib`;
   unlink <$odir/*.dib>;

   print "\n";
}
