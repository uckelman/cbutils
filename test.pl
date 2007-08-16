#!/usr/bin/perl -w

open IN, $ARGV[0] or die;
#read IN, $foo, 14 or die;
read IN, $header, 40 or die;
close IN;

($size,
 $width,
 $height,
 $planes,
 $bitCount,
 $compression,
 $sizeImage,
 $XPelsPerMeter,
 $YPelsPerMeter,
 $clrUsed,
 $clrImportant) = unpack('LLLSSLLLLLL', $header);

print "$size $width $height $planes $bitCount $compression $sizeImage $XPelsPerMeter $YPelsPerMeter $clrUsed $clrImportant\n";
