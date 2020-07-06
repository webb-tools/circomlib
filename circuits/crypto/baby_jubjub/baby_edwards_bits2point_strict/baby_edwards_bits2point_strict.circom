/*
    Copyright 2018 0KIMS association.

    This file is part of circom (Zero Knowledge Circuit Compiler).

    circom is a free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    circom is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with circom. If not, see <https://www.gnu.org/licenses/>.
*/

include "../../../basics/bitify/bits2num/bits2num.circom";
include "../../../basics/bitify/num2bits/num2bits.circom";
include "../../../basics/comparators/alias_check/alias_check.circom";
include "../../../basics/comparators/comp_constant/comp_constant.circom";
include "../baby_edwards_check/baby_edwards_check.circom"

function sqrt(n) {

    if (n == 0) {
        return 0;
    }

    // Test that the sqrt exists
    var res = n ** ((-1) >> 1);
//        if (res!=1) assert(false, "SQRT does not exists");
    if (res!=1) return 0;

    var m = 28;
    var c = 19103219067921713944291392827692070036145651957329286315305642004821462161904;
    var t = n ** 81540058820840996586704275553141814055101440848469862132140264610111;
    var r = n ** ((81540058820840996586704275553141814055101440848469862132140264610111+1)>>1);
    var sq;
    var i;
    var b;
    var j;

    while ((r != 0)&&(t != 1)) {
        sq = t*t;
        i = 1;
        while (sq!=1) {
            i++;
            sq = sq*sq;
        }

        // b = c ^ m-i-1
        b = c;
        for (j=0; j< m-i-1; j ++) b = b*b;

        m = i;
        c = b*b;
        t = t*c;
        r = r*b;
    }

    if (r < 0 ) {
        r = -r;
    }

    return r;
}

template BabyEdwardsBits2Point_strict() {
    signal input in[256];
    signal output out[2];

    var i;

    // Check aliasing
    component aliasCheckY = AliasCheck();
    for (i=0; i<254; i++) {
        aliasCheckY.in[i] <== in[i];
    }
    in[254] === 0;

    component b2nY = Bits2Num(254);
    for (i=0; i<254; i++) {
        b2nY.in[i] <== in[i];
    }

    out[1] <== b2nY.out;

    var a = 168700;
    var d = 168696;

    var y2 = out[1] * out[1];

    var x = sqrt(   (1-y2)/(a - d*y2)  );

    if (in[255] == 1) x = -x;

    out[0] <-- x;

    component babyCheck = BabyEdwardsCheck();
    babyCheck.x <== out[0];
    babyCheck.y <== out[1];

    component n2bX = Num2Bits(254);
    n2bX.in <== out[0];
    component aliasCheckX = AliasCheck();
    for (i=0; i<254; i++) {
        aliasCheckX.in[i] <== n2bX.out[i];
    }

    component signCalc = CompConstant(10944121435919637611123202872628637544274182200208017171849102093287904247808);
    for (i=0; i<254; i++) {
        signCalc.in[i] <== n2bX.out[i];
    }

    signCalc.out === in[255];
}