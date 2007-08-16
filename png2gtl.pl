#!/usr/bin/perl -w
#
# png2gtl.pl - converts PNGs to Cyberboard GTL files
# Copyright (C) 2006 Joel Uckelman (uckelman@nomic.net)
#  
# Usage: png2gtl.pl 00bbggrr full.png half.png... tiles.gtl
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

# set values for GTL header
$sig = 'GTLB';
$vmajor = 0x02;
$vminor = 0x01;
$numtiles = ((scalar @ARGV) - 1) / 3;

open OUT, ">$ARGV[$#ARGV]" or die;

# vminor before vmajor because we're little-endian
print OUT pack('A4CCL', $sig, $vminor, $vmajor, $numtiles);

for ($i = 0; $i < $numtiles; ++$i) {
   # small tile color
   print OUT pack('L', hex($ARGV[3*$i]));
   # COLORREF is 00bbggrr
   
   # full-size tile Packed_DIB
   $fdib = `convert $ARGV[3*$i+1] dib:-`;
   print OUT pack('La*', length $fdib, $fdib);

   # half-size tile Packed_DIB
   $hdib = `convert $ARGV[3*$i+2] dib:-`;
   print OUT pack('La*', length $hdib, $hdib);
}

close OUT;
