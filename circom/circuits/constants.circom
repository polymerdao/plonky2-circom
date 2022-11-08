pragma circom 2.0.9;

// Order of Goldilocks field
function Order() { return 18446744069414584321; }
function W() { return 7; }
function DTH_ROOT() { return 18446744069414584320; }

function NUM_WIRES_CAP() { return 1; }
function NUM_PLONK_ZS_PARTIAL_PRODUCTS_CAP() { return 1; }
function NUM_QUOTIENT_POLYS_CAP() { return 1; }

function NUM_OPENINGS_CONSTANTS() { return 4; }
function NUM_OPENINGS_PLONK_SIGMAS() { return 65; }
function NUM_OPENINGS_WIRES() { return 135; }
function NUM_OPENINGS_PLONK_ZS() { return 2; }
function NUM_OPENINGS_PLONK_ZS_NEXT() { return 2; }
function NUM_OPENINGS_PARTIAL_PRODUCTS() { return 16; }
function NUM_OPENINGS_QUOTIENT_POLYS() { return 16; }

function NUM_FRI_COMMIT_ROUND() { return 2; }
function FRI_COMMIT_MERKLE_CAP_HEIGHT() { return 1; }
function NUM_FRI_QUERY_ROUND() { return 10; }
function NUM_FRI_QUERY_INIT_CONSTANTS_SIGMAS_V() { return 69; }
function NUM_FRI_QUERY_INIT_CONSTANTS_SIGMAS_P() { return 20; }
function NUM_FRI_QUERY_INIT_WIRES_V() { return 135; }
function NUM_FRI_QUERY_INIT_WIRES_P() { return 20; }
function NUM_FRI_QUERY_INIT_ZS_PARTIAL_V() { return 18; }
function NUM_FRI_QUERY_INIT_ZS_PARTIAL_P() { return 20; }
function NUM_FRI_QUERY_INIT_QUOTIENT_V() { return 16; }
function NUM_FRI_QUERY_INIT_QUOTIENT_P() { return 20; }
function NUM_FRI_QUERY_STEP0_V() { return 8; }
function NUM_FRI_QUERY_STEP0_P() { return 17; }
function NUM_FRI_QUERY_STEP1_V() { return 8; }
function NUM_FRI_QUERY_STEP1_P() { return 14; }
function NUM_FRI_FINAL_POLY_EXT_V() { return 64; }

function NUM_SIGMA_CAPS() { return 1; }
function GET_SIGMA_CAP(i) {
  var sc[1][4];
  sc[0][0] = 15640437949349398862;
  sc[0][1] = 17323488953357094675;
  sc[0][2] = 17182300319914659116;
  sc[0][3] = 6457795985382393768;
  return sc[i];
}

function NUM_REDUCTION_ARITY_BITS() { return 2; }
function REDUCTION_ARITY_BITS() {
  var bits[2];
  bits[0] = 3;
  bits[1] = 3;
  return bits;
}

function G_BY_ARITY_BITS(arity_bits) {
  var g_arity_bits[4];
  g_arity_bits[0] = 18446744069414584320;
  g_arity_bits[1] = 281474976710656;
  g_arity_bits[2] = 18446744069397807105;
  g_arity_bits[3] = 17293822564807737345;
  return g_arity_bits[arity_bits - 1];
}

function G_FROM_DEGREE_BITS() {
  var g[2];
  g[0] = 17492915097719143606;
  g[1] = 0;
  return g;
}

function MULTIPLICATIVE_GROUP_GENERATOR() { return 7; }
function PRIMITIVE_ROOT_OF_UNITY_LDE() { return 3511170319078647661; }
function LOG_SIZE_OF_LDE_DOMAIN() { return 20; }
function NUM_CHALLENGES() { return 2; }
function MIN_FRI_POW_RESPONSE() { return 20; }
function CIRCUIT_DIGEST() {
  var cd[4];
  cd[0] = 2891690267213478025;
  cd[1] = 17406386567256428725;
  cd[2] = 9723703874444410999;
  cd[3] = 4682235071878973622;
  return cd;
}
function SPONGE_RATE() { return 8; }
function SPONGE_CAPACITY() { return 4; }
function SPONGE_WIDTH() { return 12; }
function DEGREE_BITS() { return 12; }
function FRI_RATE_BITS() { return 8; }
function NUM_GATE_CONSTRAINTS() { return 123; }
function NUM_PARTIAL_PRODUCTS_TERMS() { return NUM_OPENINGS_PLONK_SIGMAS() \ QUOTIENT_DEGREE_FACTOR() + 1; }
function QUOTIENT_DEGREE_FACTOR() { return 8; }
function K_IS(i) {
  var k_is[65];
  k_is[0] = 1;
  k_is[1] = 7;
  k_is[2] = 49;
  k_is[3] = 343;
  k_is[4] = 2401;
  k_is[5] = 16807;
  k_is[6] = 117649;
  k_is[7] = 823543;
  k_is[8] = 5764801;
  k_is[9] = 40353607;
  k_is[10] = 282475249;
  k_is[11] = 1977326743;
  k_is[12] = 13841287201;
  k_is[13] = 96889010407;
  k_is[14] = 678223072849;
  k_is[15] = 4747561509943;
  k_is[16] = 33232930569601;
  k_is[17] = 232630513987207;
  k_is[18] = 1628413597910449;
  k_is[19] = 11398895185373143;
  k_is[20] = 79792266297612001;
  k_is[21] = 558545864083284007;
  k_is[22] = 3909821048582988049;
  k_is[23] = 8922003270666332022;
  k_is[24] = 7113790686420571191;
  k_is[25] = 12903046666114829695;
  k_is[26] = 16534350385145470581;
  k_is[27] = 5059988279530788141;
  k_is[28] = 16973173887300932666;
  k_is[29] = 8131752794619022736;
  k_is[30] = 1582037354089406189;
  k_is[31] = 11074261478625843323;
  k_is[32] = 3732854072722565977;
  k_is[33] = 7683234439643377518;
  k_is[34] = 16889152938674473984;
  k_is[35] = 7543606154233811962;
  k_is[36] = 15911754940807515092;
  k_is[37] = 701820169165099718;
  k_is[38] = 4912741184155698026;
  k_is[39] = 15942444219675301861;
  k_is[40] = 916645121239607101;
  k_is[41] = 6416515848677249707;
  k_is[42] = 8022122801911579307;
  k_is[43] = 814627405137302186;
  k_is[44] = 5702391835961115302;
  k_is[45] = 3023254712898638472;
  k_is[46] = 2716038920875884983;
  k_is[47] = 565528376716610560;
  k_is[48] = 3958698637016273920;
  k_is[49] = 9264146389699333119;
  k_is[50] = 9508792519651578870;
  k_is[51] = 11221315429317299127;
  k_is[52] = 4762231727562756605;
  k_is[53] = 14888878023524711914;
  k_is[54] = 11988425817600061793;
  k_is[55] = 10132004445542095267;
  k_is[56] = 15583798910550913906;
  k_is[57] = 16852872026783475737;
  k_is[58] = 7289639770996824233;
  k_is[59] = 14133990258148600989;
  k_is[60] = 6704211459967285318;
  k_is[61] = 10035992080941828584;
  k_is[62] = 14911712358349047125;
  k_is[63] = 12148266161370408270;
  k_is[64] = 11250886851934520606;
  return k_is[i];
}
function NUM_PUBLIC_INPUTS() { return 4; }
