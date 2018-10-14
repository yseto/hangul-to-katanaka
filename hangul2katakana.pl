#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Encode;
use File::Slurp;
use Lingua::KO::Romanize::Hangul;
use Lingua::JA::Moji 'romaji2kana';

my $conv = Lingua::KO::Romanize::Hangul->new;
my @doc = read_file(shift);

my $patchim = "";

read_line($_) for @doc;

sub read_line {
    my $line = shift;
    print $line;

    my $roman;
    my @chars = $conv->string( decode_utf8($line) );
    while(my ($index,$word) = each @chars){
        my ($raw, $ruby) = @$word;
#       print ".$i.>";
        my $char = rewrite_japanese_pronuance($ruby ? $ruby : $raw, $index);
#       print $char;
        $roman .= $char;
    }
#   print "\n";

#   print convert_katakana_like($roman);
#   print "\n";
    my $katakana = romaji2kana(convert_katakana_like($roman));
    print encode_utf8(normalize_katakana($katakana));
    print "\n";
}

sub normalize_katakana {
    my $row = shift;
    $row =~ s/ ン/ン /g;
    $row =~ s/ ッ/ッ /g;
    $row =~ s/\bアハ(\s+?)/アナ$1/g;
    $row =~ s/ルイ/レ/g;
    $row =~ s/ウイ/エ/g;
    $row =~ s/r/ル/g;
    $row =~ s/t/ッ/g;

    $row =~ s/[a-z]//g;
    $row;
}

sub convert_katakana_like {
    my $row = shift;

    # カタカナにさらに寄せる
    $row =~ s/gh/g/g;
    $row =~ s/kh/k/g;

    $row =~ s/jw/j/g;
    $row =~ s/dw/d/g;
    $row =~ s/sw/s/g;

    # カタカナにすると音が無くなるので追加する
    $row =~ s/ks/kus/g;

    $row;
}

sub rewrite_japanese_pronuance {
    my ($roman, $index) = @_;

    # 行頭はパッチムをあえて引き継がない
    if ($index == 0) {
        $patchim = "";
    }

    # スペースの場合 パッチム の位置を明示的に入れ替え、前の音に引き継ぐ
    if ($roman =~ m/\s/) {
        $roman = $patchim . " ";
        $patchim = "";
    }

    # パッチムが存在していた場合、今の音の前につける
    if ($patchim ne "") {
        $roman = $patchim . $roman;
        $patchim = "";
    }

    # 正規化
    $roman =~ s/l/r/;

    # 発声が変わる
    if ($index == 0) {
        $roman =~ s/^g/k/;
        if ($roman =~ m/^n/) {
#           $roman =~ s/^n/t/;
        } else {
            $roman =~ s/^t/n/;
        }
        $roman =~ s/^d/t/;
        $roman =~ s/^b/p/;
    }

    # パッチムが存在するか調べる
    my (undef, $cur_patchim) = split(/a|i|u|e|o/, $roman);
    if ($cur_patchim) {
        $roman =~ s/$cur_patchim$//;
        $patchim = $cur_patchim;
    }

    # ある程度の音に対してカタカナでの処理がしやすいように書き換える

    # 子音
    $roman =~ s/^th/t/;
    $roman =~ s/^bw/b/;
    $roman =~ s/^phy/py/g;

    # 子音+母音
    $roman =~ s/der/de/;
    $roman =~ s/^nhi/ni/g;
    $roman =~ s/^nh/h/g;

    # 母音
    $roman =~ s/eo/o/;
    $roman =~ s/eu/u/;
    $roman =~ s/oe/e/;
    $roman =~ s/ae/e/;

    # 末尾
    $roman =~ s/m$/n/;

    $roman;
}

