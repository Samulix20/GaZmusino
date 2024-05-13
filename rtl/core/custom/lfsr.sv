module lfsr_151_144 (
    input logic clk, advance, set,
    input logic[150:0] seed,
    output logic[150:0] current_state
);

always_ff @(posedge clk) begin
    if (set) begin
        current_state = seed;
    end
    else if (advance) begin
        current_state = next_state;
    end
end

logic[150:0] next_state;

always_comb begin
    // Automatic generated code
    next_state[150] = current_state[146] ^ current_state[143];
    next_state[149] = current_state[145] ^ current_state[142];
    next_state[148] = current_state[144] ^ current_state[141];
    next_state[147] = current_state[143] ^ current_state[140];
    next_state[146] = current_state[142] ^ current_state[139];
    next_state[145] = current_state[141] ^ current_state[138];
    next_state[144] = current_state[140] ^ current_state[137];
    next_state[143] = current_state[139] ^ current_state[136];
    next_state[142] = current_state[138] ^ current_state[135];
    next_state[141] = current_state[137] ^ current_state[134];
    next_state[140] = current_state[136] ^ current_state[133];
    next_state[139] = current_state[135] ^ current_state[132];
    next_state[138] = current_state[134] ^ current_state[131];
    next_state[137] = current_state[133] ^ current_state[130];
    next_state[136] = current_state[132] ^ current_state[129];
    next_state[135] = current_state[131] ^ current_state[128];
    next_state[134] = current_state[130] ^ current_state[127];
    next_state[133] = current_state[129] ^ current_state[126];
    next_state[132] = current_state[128] ^ current_state[125];
    next_state[131] = current_state[127] ^ current_state[124];
    next_state[130] = current_state[126] ^ current_state[123];
    next_state[129] = current_state[125] ^ current_state[122];
    next_state[128] = current_state[124] ^ current_state[121];
    next_state[127] = current_state[123] ^ current_state[120];
    next_state[126] = current_state[122] ^ current_state[119];
    next_state[125] = current_state[121] ^ current_state[118];
    next_state[124] = current_state[120] ^ current_state[117];
    next_state[123] = current_state[119] ^ current_state[116];
    next_state[122] = current_state[118] ^ current_state[115];
    next_state[121] = current_state[117] ^ current_state[114];
    next_state[120] = current_state[116] ^ current_state[113];
    next_state[119] = current_state[115] ^ current_state[112];
    next_state[118] = current_state[114] ^ current_state[111];
    next_state[117] = current_state[113] ^ current_state[110];
    next_state[116] = current_state[112] ^ current_state[109];
    next_state[115] = current_state[111] ^ current_state[108];
    next_state[114] = current_state[110] ^ current_state[107];
    next_state[113] = current_state[109] ^ current_state[106];
    next_state[112] = current_state[108] ^ current_state[105];
    next_state[111] = current_state[107] ^ current_state[104];
    next_state[110] = current_state[106] ^ current_state[103];
    next_state[109] = current_state[105] ^ current_state[102];
    next_state[108] = current_state[104] ^ current_state[101];
    next_state[107] = current_state[103] ^ current_state[100];
    next_state[106] = current_state[102] ^ current_state[99];
    next_state[105] = current_state[101] ^ current_state[98];
    next_state[104] = current_state[100] ^ current_state[97];
    next_state[103] = current_state[99] ^ current_state[96];
    next_state[102] = current_state[98] ^ current_state[95];
    next_state[101] = current_state[97] ^ current_state[94];
    next_state[100] = current_state[96] ^ current_state[93];
    next_state[99] = current_state[95] ^ current_state[92];
    next_state[98] = current_state[94] ^ current_state[91];
    next_state[97] = current_state[93] ^ current_state[90];
    next_state[96] = current_state[92] ^ current_state[89];
    next_state[95] = current_state[91] ^ current_state[88];
    next_state[94] = current_state[90] ^ current_state[87];
    next_state[93] = current_state[89] ^ current_state[86];
    next_state[92] = current_state[88] ^ current_state[85];
    next_state[91] = current_state[87] ^ current_state[84];
    next_state[90] = current_state[86] ^ current_state[83];
    next_state[89] = current_state[85] ^ current_state[82];
    next_state[88] = current_state[84] ^ current_state[81];
    next_state[87] = current_state[83] ^ current_state[80];
    next_state[86] = current_state[82] ^ current_state[79];
    next_state[85] = current_state[81] ^ current_state[78];
    next_state[84] = current_state[80] ^ current_state[77];
    next_state[83] = current_state[79] ^ current_state[76];
    next_state[82] = current_state[78] ^ current_state[75];
    next_state[81] = current_state[77] ^ current_state[74];
    next_state[80] = current_state[76] ^ current_state[73];
    next_state[79] = current_state[75] ^ current_state[72];
    next_state[78] = current_state[74] ^ current_state[71];
    next_state[77] = current_state[73] ^ current_state[70];
    next_state[76] = current_state[72] ^ current_state[69];
    next_state[75] = current_state[71] ^ current_state[68];
    next_state[74] = current_state[70] ^ current_state[67];
    next_state[73] = current_state[69] ^ current_state[66];
    next_state[72] = current_state[68] ^ current_state[65];
    next_state[71] = current_state[67] ^ current_state[64];
    next_state[70] = current_state[66] ^ current_state[63];
    next_state[69] = current_state[65] ^ current_state[62];
    next_state[68] = current_state[64] ^ current_state[61];
    next_state[67] = current_state[63] ^ current_state[60];
    next_state[66] = current_state[62] ^ current_state[59];
    next_state[65] = current_state[61] ^ current_state[58];
    next_state[64] = current_state[60] ^ current_state[57];
    next_state[63] = current_state[59] ^ current_state[56];
    next_state[62] = current_state[58] ^ current_state[55];
    next_state[61] = current_state[57] ^ current_state[54];
    next_state[60] = current_state[56] ^ current_state[53];
    next_state[59] = current_state[55] ^ current_state[52];
    next_state[58] = current_state[54] ^ current_state[51];
    next_state[57] = current_state[53] ^ current_state[50];
    next_state[56] = current_state[52] ^ current_state[49];
    next_state[55] = current_state[51] ^ current_state[48];
    next_state[54] = current_state[50] ^ current_state[47];
    next_state[53] = current_state[49] ^ current_state[46];
    next_state[52] = current_state[48] ^ current_state[45];
    next_state[51] = current_state[47] ^ current_state[44];
    next_state[50] = current_state[46] ^ current_state[43];
    next_state[49] = current_state[45] ^ current_state[42];
    next_state[48] = current_state[44] ^ current_state[41];
    next_state[47] = current_state[43] ^ current_state[40];
    next_state[46] = current_state[42] ^ current_state[39];
    next_state[45] = current_state[41] ^ current_state[38];
    next_state[44] = current_state[40] ^ current_state[37];
    next_state[43] = current_state[39] ^ current_state[36];
    next_state[42] = current_state[38] ^ current_state[35];
    next_state[41] = current_state[37] ^ current_state[34];
    next_state[40] = current_state[36] ^ current_state[33];
    next_state[39] = current_state[35] ^ current_state[32];
    next_state[38] = current_state[34] ^ current_state[31];
    next_state[37] = current_state[33] ^ current_state[30];
    next_state[36] = current_state[32] ^ current_state[29];
    next_state[35] = current_state[31] ^ current_state[28];
    next_state[34] = current_state[30] ^ current_state[27];
    next_state[33] = current_state[29] ^ current_state[26];
    next_state[32] = current_state[28] ^ current_state[25];
    next_state[31] = current_state[27] ^ current_state[24];
    next_state[30] = current_state[26] ^ current_state[23];
    next_state[29] = current_state[25] ^ current_state[22];
    next_state[28] = current_state[24] ^ current_state[21];
    next_state[27] = current_state[23] ^ current_state[20];
    next_state[26] = current_state[22] ^ current_state[19];
    next_state[25] = current_state[21] ^ current_state[18];
    next_state[24] = current_state[20] ^ current_state[17];
    next_state[23] = current_state[19] ^ current_state[16];
    next_state[22] = current_state[18] ^ current_state[15];
    next_state[21] = current_state[17] ^ current_state[14];
    next_state[20] = current_state[16] ^ current_state[13];
    next_state[19] = current_state[15] ^ current_state[12];
    next_state[18] = current_state[14] ^ current_state[11];
    next_state[17] = current_state[13] ^ current_state[10];
    next_state[16] = current_state[12] ^ current_state[9];
    next_state[15] = current_state[11] ^ current_state[8];
    next_state[14] = current_state[10] ^ current_state[7];
    next_state[13] = current_state[9] ^ current_state[6];
    next_state[12] = current_state[8] ^ current_state[5];
    next_state[11] = current_state[7] ^ current_state[4];
    next_state[10] = current_state[6] ^ current_state[3];
    next_state[9] = current_state[5] ^ current_state[2];
    next_state[8] = current_state[4] ^ current_state[1];
    next_state[7] = current_state[3] ^ current_state[0];
    next_state[6] = current_state[150];
    next_state[5] = current_state[149];
    next_state[4] = current_state[148];
    next_state[3] = current_state[147];
    next_state[2] = current_state[146];
    next_state[1] = current_state[145];
    next_state[0] = current_state[144];
end

endmodule
