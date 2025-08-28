////////////////////////////////////////////////////////////
//
//        (C) Copyright 2021 Eximius Design
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
////////////////////////////////////////////////////////////

module axi_mm_slave_concat  (

// Data from Logic Links
  output logic [  48:   0]   rx_ar_data          ,
  output logic               rx_ar_push_ovrd     ,
  output logic               rx_ar_pushbit       ,
  input  logic               tx_ar_credit        ,

  output logic [  48:   0]   rx_aw_data          ,
  output logic               rx_aw_push_ovrd     ,
  output logic               rx_aw_pushbit       ,
  input  logic               tx_aw_credit        ,

  output logic [ 148:   0]   rx_w_data           ,
  output logic               rx_w_push_ovrd      ,
  output logic               rx_w_pushbit        ,
  input  logic               tx_w_credit         ,

  input  logic [ 134:   0]   tx_r_data           ,
  output logic               tx_r_pop_ovrd       ,
  input  logic               tx_r_pushbit        ,
  output logic               rx_r_credit         ,

  input  logic [   5:   0]   tx_b_data           ,
  output logic               tx_b_pop_ovrd       ,
  input  logic               tx_b_pushbit        ,
  output logic               rx_b_credit         ,

// PHY Interconnect
  output logic [ 319:   0]   tx_phy0             ,
  input  logic [ 319:   0]   rx_phy0             ,

  input  logic               clk_wr              ,
  input  logic               clk_rd              ,
  input  logic               rst_wr_n            ,
  input  logic               rst_rd_n            ,

  input  logic               m_gen2_mode         ,
  input  logic               tx_online           ,

  input  logic               tx_stb_userbit      ,
  input  logic [   3:   0]   tx_mrk_userbit      

);

// No TX Packetization, so tie off packetization signals
  assign tx_r_pop_ovrd                      = 1'b0                               ;
  assign tx_b_pop_ovrd                      = 1'b0                               ;

// No RX Packetization, so tie off packetization signals
  assign rx_ar_push_ovrd                    = 1'b0                               ;
  assign rx_aw_push_ovrd                    = 1'b0                               ;
  assign rx_w_push_ovrd                     = 1'b0                               ;

//////////////////////////////////////////////////////////////////
// TX Section

//   TX_CH_WIDTH           = 320; // Gen2Only running at Quarter Rate
//   TX_DATA_WIDTH         = 320; // Usable Data per Channel
//   TX_PERSISTENT_STROBE  = 1'b1;
//   TX_PERSISTENT_MARKER  = 1'b1;
//   TX_STROBE_GEN2_LOC    = 'd0;
//   TX_MARKER_GEN2_LOC    = 'd0;
//   TX_STROBE_GEN1_LOC    = 'd0;
//   TX_MARKER_GEN1_LOC    = 'd0;
//   TX_ENABLE_STROBE      = 1'b0;
//   TX_ENABLE_MARKER      = 1'b0;
//   TX_DBI_PRESENT        = 1'b0;
//   TX_REG_PHY            = 1'b0;

  localparam TX_REG_PHY    = 1'b0;  // If set, this enables boundary FF for timing reasons

  logic [ 319:   0]                              tx_phy_preflop_0              ;
  logic [ 319:   0]                              tx_phy_flop_0_reg             ;

  always_ff @(posedge clk_wr or negedge rst_wr_n)
  if (~rst_wr_n)
  begin
    tx_phy_flop_0_reg                       <= 320'b0                                  ;
  end
  else
  begin
    tx_phy_flop_0_reg                       <= tx_phy_preflop_0                        ;
  end

  assign tx_phy0                            = TX_REG_PHY ? tx_phy_flop_0_reg : tx_phy_preflop_0               ;

  assign tx_phy_preflop_0 [   0] = tx_ar_credit               ;
  assign tx_phy_preflop_0 [   1] = tx_aw_credit               ;
  assign tx_phy_preflop_0 [   2] = tx_w_credit                ;
  assign tx_phy_preflop_0 [   3] = tx_r_pushbit               ;
  assign tx_phy_preflop_0 [   4] = tx_r_data           [   0] ;
  assign tx_phy_preflop_0 [   5] = tx_r_data           [   1] ;
  assign tx_phy_preflop_0 [   6] = tx_r_data           [   2] ;
  assign tx_phy_preflop_0 [   7] = tx_r_data           [   3] ;
  assign tx_phy_preflop_0 [   8] = tx_r_data           [   4] ;
  assign tx_phy_preflop_0 [   9] = tx_r_data           [   5] ;
  assign tx_phy_preflop_0 [  10] = tx_r_data           [   6] ;
  assign tx_phy_preflop_0 [  11] = tx_r_data           [   7] ;
  assign tx_phy_preflop_0 [  12] = tx_r_data           [   8] ;
  assign tx_phy_preflop_0 [  13] = tx_r_data           [   9] ;
  assign tx_phy_preflop_0 [  14] = tx_r_data           [  10] ;
  assign tx_phy_preflop_0 [  15] = tx_r_data           [  11] ;
  assign tx_phy_preflop_0 [  16] = tx_r_data           [  12] ;
  assign tx_phy_preflop_0 [  17] = tx_r_data           [  13] ;
  assign tx_phy_preflop_0 [  18] = tx_r_data           [  14] ;
  assign tx_phy_preflop_0 [  19] = tx_r_data           [  15] ;
  assign tx_phy_preflop_0 [  20] = tx_r_data           [  16] ;
  assign tx_phy_preflop_0 [  21] = tx_r_data           [  17] ;
  assign tx_phy_preflop_0 [  22] = tx_r_data           [  18] ;
  assign tx_phy_preflop_0 [  23] = tx_r_data           [  19] ;
  assign tx_phy_preflop_0 [  24] = tx_r_data           [  20] ;
  assign tx_phy_preflop_0 [  25] = tx_r_data           [  21] ;
  assign tx_phy_preflop_0 [  26] = tx_r_data           [  22] ;
  assign tx_phy_preflop_0 [  27] = tx_r_data           [  23] ;
  assign tx_phy_preflop_0 [  28] = tx_r_data           [  24] ;
  assign tx_phy_preflop_0 [  29] = tx_r_data           [  25] ;
  assign tx_phy_preflop_0 [  30] = tx_r_data           [  26] ;
  assign tx_phy_preflop_0 [  31] = tx_r_data           [  27] ;
  assign tx_phy_preflop_0 [  32] = tx_r_data           [  28] ;
  assign tx_phy_preflop_0 [  33] = tx_r_data           [  29] ;
  assign tx_phy_preflop_0 [  34] = tx_r_data           [  30] ;
  assign tx_phy_preflop_0 [  35] = tx_r_data           [  31] ;
  assign tx_phy_preflop_0 [  36] = tx_r_data           [  32] ;
  assign tx_phy_preflop_0 [  37] = tx_r_data           [  33] ;
  assign tx_phy_preflop_0 [  38] = tx_r_data           [  34] ;
  assign tx_phy_preflop_0 [  39] = tx_r_data           [  35] ;
  assign tx_phy_preflop_0 [  40] = tx_r_data           [  36] ;
  assign tx_phy_preflop_0 [  41] = tx_r_data           [  37] ;
  assign tx_phy_preflop_0 [  42] = tx_r_data           [  38] ;
  assign tx_phy_preflop_0 [  43] = tx_r_data           [  39] ;
  assign tx_phy_preflop_0 [  44] = tx_r_data           [  40] ;
  assign tx_phy_preflop_0 [  45] = tx_r_data           [  41] ;
  assign tx_phy_preflop_0 [  46] = tx_r_data           [  42] ;
  assign tx_phy_preflop_0 [  47] = tx_r_data           [  43] ;
  assign tx_phy_preflop_0 [  48] = tx_r_data           [  44] ;
  assign tx_phy_preflop_0 [  49] = tx_r_data           [  45] ;
  assign tx_phy_preflop_0 [  50] = tx_r_data           [  46] ;
  assign tx_phy_preflop_0 [  51] = tx_r_data           [  47] ;
  assign tx_phy_preflop_0 [  52] = tx_r_data           [  48] ;
  assign tx_phy_preflop_0 [  53] = tx_r_data           [  49] ;
  assign tx_phy_preflop_0 [  54] = tx_r_data           [  50] ;
  assign tx_phy_preflop_0 [  55] = tx_r_data           [  51] ;
  assign tx_phy_preflop_0 [  56] = tx_r_data           [  52] ;
  assign tx_phy_preflop_0 [  57] = tx_r_data           [  53] ;
  assign tx_phy_preflop_0 [  58] = tx_r_data           [  54] ;
  assign tx_phy_preflop_0 [  59] = tx_r_data           [  55] ;
  assign tx_phy_preflop_0 [  60] = tx_r_data           [  56] ;
  assign tx_phy_preflop_0 [  61] = tx_r_data           [  57] ;
  assign tx_phy_preflop_0 [  62] = tx_r_data           [  58] ;
  assign tx_phy_preflop_0 [  63] = tx_r_data           [  59] ;
  assign tx_phy_preflop_0 [  64] = tx_r_data           [  60] ;
  assign tx_phy_preflop_0 [  65] = tx_r_data           [  61] ;
  assign tx_phy_preflop_0 [  66] = tx_r_data           [  62] ;
  assign tx_phy_preflop_0 [  67] = tx_r_data           [  63] ;
  assign tx_phy_preflop_0 [  68] = tx_r_data           [  64] ;
  assign tx_phy_preflop_0 [  69] = tx_r_data           [  65] ;
  assign tx_phy_preflop_0 [  70] = tx_r_data           [  66] ;
  assign tx_phy_preflop_0 [  71] = tx_r_data           [  67] ;
  assign tx_phy_preflop_0 [  72] = tx_r_data           [  68] ;
  assign tx_phy_preflop_0 [  73] = tx_r_data           [  69] ;
  assign tx_phy_preflop_0 [  74] = tx_r_data           [  70] ;
  assign tx_phy_preflop_0 [  75] = tx_r_data           [  71] ;
  assign tx_phy_preflop_0 [  76] = tx_r_data           [  72] ;
  assign tx_phy_preflop_0 [  77] = tx_r_data           [  73] ;
  assign tx_phy_preflop_0 [  78] = tx_r_data           [  74] ;
  assign tx_phy_preflop_0 [  79] = tx_r_data           [  75] ;
  assign tx_phy_preflop_0 [  80] = tx_r_data           [  76] ;
  assign tx_phy_preflop_0 [  81] = tx_r_data           [  77] ;
  assign tx_phy_preflop_0 [  82] = tx_r_data           [  78] ;
  assign tx_phy_preflop_0 [  83] = tx_r_data           [  79] ;
  assign tx_phy_preflop_0 [  84] = tx_r_data           [  80] ;
  assign tx_phy_preflop_0 [  85] = tx_r_data           [  81] ;
  assign tx_phy_preflop_0 [  86] = tx_r_data           [  82] ;
  assign tx_phy_preflop_0 [  87] = tx_r_data           [  83] ;
  assign tx_phy_preflop_0 [  88] = tx_r_data           [  84] ;
  assign tx_phy_preflop_0 [  89] = tx_r_data           [  85] ;
  assign tx_phy_preflop_0 [  90] = tx_r_data           [  86] ;
  assign tx_phy_preflop_0 [  91] = tx_r_data           [  87] ;
  assign tx_phy_preflop_0 [  92] = tx_r_data           [  88] ;
  assign tx_phy_preflop_0 [  93] = tx_r_data           [  89] ;
  assign tx_phy_preflop_0 [  94] = tx_r_data           [  90] ;
  assign tx_phy_preflop_0 [  95] = tx_r_data           [  91] ;
  assign tx_phy_preflop_0 [  96] = tx_r_data           [  92] ;
  assign tx_phy_preflop_0 [  97] = tx_r_data           [  93] ;
  assign tx_phy_preflop_0 [  98] = tx_r_data           [  94] ;
  assign tx_phy_preflop_0 [  99] = tx_r_data           [  95] ;
  assign tx_phy_preflop_0 [ 100] = tx_r_data           [  96] ;
  assign tx_phy_preflop_0 [ 101] = tx_r_data           [  97] ;
  assign tx_phy_preflop_0 [ 102] = tx_r_data           [  98] ;
  assign tx_phy_preflop_0 [ 103] = tx_r_data           [  99] ;
  assign tx_phy_preflop_0 [ 104] = tx_r_data           [ 100] ;
  assign tx_phy_preflop_0 [ 105] = tx_r_data           [ 101] ;
  assign tx_phy_preflop_0 [ 106] = tx_r_data           [ 102] ;
  assign tx_phy_preflop_0 [ 107] = tx_r_data           [ 103] ;
  assign tx_phy_preflop_0 [ 108] = tx_r_data           [ 104] ;
  assign tx_phy_preflop_0 [ 109] = tx_r_data           [ 105] ;
  assign tx_phy_preflop_0 [ 110] = tx_r_data           [ 106] ;
  assign tx_phy_preflop_0 [ 111] = tx_r_data           [ 107] ;
  assign tx_phy_preflop_0 [ 112] = tx_r_data           [ 108] ;
  assign tx_phy_preflop_0 [ 113] = tx_r_data           [ 109] ;
  assign tx_phy_preflop_0 [ 114] = tx_r_data           [ 110] ;
  assign tx_phy_preflop_0 [ 115] = tx_r_data           [ 111] ;
  assign tx_phy_preflop_0 [ 116] = tx_r_data           [ 112] ;
  assign tx_phy_preflop_0 [ 117] = tx_r_data           [ 113] ;
  assign tx_phy_preflop_0 [ 118] = tx_r_data           [ 114] ;
  assign tx_phy_preflop_0 [ 119] = tx_r_data           [ 115] ;
  assign tx_phy_preflop_0 [ 120] = tx_r_data           [ 116] ;
  assign tx_phy_preflop_0 [ 121] = tx_r_data           [ 117] ;
  assign tx_phy_preflop_0 [ 122] = tx_r_data           [ 118] ;
  assign tx_phy_preflop_0 [ 123] = tx_r_data           [ 119] ;
  assign tx_phy_preflop_0 [ 124] = tx_r_data           [ 120] ;
  assign tx_phy_preflop_0 [ 125] = tx_r_data           [ 121] ;
  assign tx_phy_preflop_0 [ 126] = tx_r_data           [ 122] ;
  assign tx_phy_preflop_0 [ 127] = tx_r_data           [ 123] ;
  assign tx_phy_preflop_0 [ 128] = tx_r_data           [ 124] ;
  assign tx_phy_preflop_0 [ 129] = tx_r_data           [ 125] ;
  assign tx_phy_preflop_0 [ 130] = tx_r_data           [ 126] ;
  assign tx_phy_preflop_0 [ 131] = tx_r_data           [ 127] ;
  assign tx_phy_preflop_0 [ 132] = tx_r_data           [ 128] ;
  assign tx_phy_preflop_0 [ 133] = tx_r_data           [ 129] ;
  assign tx_phy_preflop_0 [ 134] = tx_r_data           [ 130] ;
  assign tx_phy_preflop_0 [ 135] = tx_r_data           [ 131] ;
  assign tx_phy_preflop_0 [ 136] = tx_r_data           [ 132] ;
  assign tx_phy_preflop_0 [ 137] = tx_r_data           [ 133] ;
  assign tx_phy_preflop_0 [ 138] = tx_r_data           [ 134] ;
  assign tx_phy_preflop_0 [ 139] = tx_b_pushbit               ;
  assign tx_phy_preflop_0 [ 140] = tx_b_data           [   0] ;
  assign tx_phy_preflop_0 [ 141] = tx_b_data           [   1] ;
  assign tx_phy_preflop_0 [ 142] = tx_b_data           [   2] ;
  assign tx_phy_preflop_0 [ 143] = tx_b_data           [   3] ;
  assign tx_phy_preflop_0 [ 144] = tx_b_data           [   4] ;
  assign tx_phy_preflop_0 [ 145] = tx_b_data           [   5] ;
  assign tx_phy_preflop_0 [ 146] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 147] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 148] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 149] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 150] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 151] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 152] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 153] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 154] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 155] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 156] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 157] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 158] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 159] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 160] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 161] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 162] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 163] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 164] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 165] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 166] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 167] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 168] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 169] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 170] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 171] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 172] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 173] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 174] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 175] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 176] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 177] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 178] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 179] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 180] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 181] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 182] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 183] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 184] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 185] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 186] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 187] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 188] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 189] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 190] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 191] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 192] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 193] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 194] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 195] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 196] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 197] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 198] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 199] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 200] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 201] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 202] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 203] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 204] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 205] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 206] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 207] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 208] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 209] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 210] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 211] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 212] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 213] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 214] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 215] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 216] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 217] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 218] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 219] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 220] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 221] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 222] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 223] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 224] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 225] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 226] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 227] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 228] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 229] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 230] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 231] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 232] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 233] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 234] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 235] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 236] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 237] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 238] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 239] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 240] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 241] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 242] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 243] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 244] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 245] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 246] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 247] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 248] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 249] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 250] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 251] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 252] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 253] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 254] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 255] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 256] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 257] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 258] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 259] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 260] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 261] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 262] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 263] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 264] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 265] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 266] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 267] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 268] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 269] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 270] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 271] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 272] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 273] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 274] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 275] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 276] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 277] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 278] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 279] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 280] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 281] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 282] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 283] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 284] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 285] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 286] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 287] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 288] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 289] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 290] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 291] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 292] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 293] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 294] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 295] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 296] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 297] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 298] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 299] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 300] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 301] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 302] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 303] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 304] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 305] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 306] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 307] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 308] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 309] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 310] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 311] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 312] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 313] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 314] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 315] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 316] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 317] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 318] = 1'b0                       ;
  assign tx_phy_preflop_0 [ 319] = 1'b0                       ;
// TX Section
//////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////
// RX Section

//   RX_CH_WIDTH           = 320; // Gen2Only running at Quarter Rate
//   RX_DATA_WIDTH         = 320; // Usable Data per Channel
//   RX_PERSISTENT_STROBE  = 1'b1;
//   RX_PERSISTENT_MARKER  = 1'b1;
//   RX_STROBE_GEN2_LOC    = 'd0;
//   RX_MARKER_GEN2_LOC    = 'd0;
//   RX_STROBE_GEN1_LOC    = 'd0;
//   RX_MARKER_GEN1_LOC    = 'd0;
//   RX_ENABLE_STROBE      = 1'b0;
//   RX_ENABLE_MARKER      = 1'b0;
//   RX_DBI_PRESENT        = 1'b0;
//   RX_REG_PHY            = 1'b0;

  localparam RX_REG_PHY    = 1'b0;  // If set, this enables boundary FF for timing reasons

  logic [ 319:   0]                              rx_phy_postflop_0             ;
  logic [ 319:   0]                              rx_phy_flop_0_reg             ;

  always_ff @(posedge clk_rd or negedge rst_rd_n)
  if (~rst_rd_n)
  begin
    rx_phy_flop_0_reg                       <= 320'b0                                  ;
  end
  else
  begin
    rx_phy_flop_0_reg                       <= rx_phy0                                 ;
  end


  assign rx_phy_postflop_0                  = RX_REG_PHY ? rx_phy_flop_0_reg : rx_phy0               ;

  assign rx_ar_pushbit              = rx_phy_postflop_0 [   0];
  assign rx_ar_data          [   0] = rx_phy_postflop_0 [   1];
  assign rx_ar_data          [   1] = rx_phy_postflop_0 [   2];
  assign rx_ar_data          [   2] = rx_phy_postflop_0 [   3];
  assign rx_ar_data          [   3] = rx_phy_postflop_0 [   4];
  assign rx_ar_data          [   4] = rx_phy_postflop_0 [   5];
  assign rx_ar_data          [   5] = rx_phy_postflop_0 [   6];
  assign rx_ar_data          [   6] = rx_phy_postflop_0 [   7];
  assign rx_ar_data          [   7] = rx_phy_postflop_0 [   8];
  assign rx_ar_data          [   8] = rx_phy_postflop_0 [   9];
  assign rx_ar_data          [   9] = rx_phy_postflop_0 [  10];
  assign rx_ar_data          [  10] = rx_phy_postflop_0 [  11];
  assign rx_ar_data          [  11] = rx_phy_postflop_0 [  12];
  assign rx_ar_data          [  12] = rx_phy_postflop_0 [  13];
  assign rx_ar_data          [  13] = rx_phy_postflop_0 [  14];
  assign rx_ar_data          [  14] = rx_phy_postflop_0 [  15];
  assign rx_ar_data          [  15] = rx_phy_postflop_0 [  16];
  assign rx_ar_data          [  16] = rx_phy_postflop_0 [  17];
  assign rx_ar_data          [  17] = rx_phy_postflop_0 [  18];
  assign rx_ar_data          [  18] = rx_phy_postflop_0 [  19];
  assign rx_ar_data          [  19] = rx_phy_postflop_0 [  20];
  assign rx_ar_data          [  20] = rx_phy_postflop_0 [  21];
  assign rx_ar_data          [  21] = rx_phy_postflop_0 [  22];
  assign rx_ar_data          [  22] = rx_phy_postflop_0 [  23];
  assign rx_ar_data          [  23] = rx_phy_postflop_0 [  24];
  assign rx_ar_data          [  24] = rx_phy_postflop_0 [  25];
  assign rx_ar_data          [  25] = rx_phy_postflop_0 [  26];
  assign rx_ar_data          [  26] = rx_phy_postflop_0 [  27];
  assign rx_ar_data          [  27] = rx_phy_postflop_0 [  28];
  assign rx_ar_data          [  28] = rx_phy_postflop_0 [  29];
  assign rx_ar_data          [  29] = rx_phy_postflop_0 [  30];
  assign rx_ar_data          [  30] = rx_phy_postflop_0 [  31];
  assign rx_ar_data          [  31] = rx_phy_postflop_0 [  32];
  assign rx_ar_data          [  32] = rx_phy_postflop_0 [  33];
  assign rx_ar_data          [  33] = rx_phy_postflop_0 [  34];
  assign rx_ar_data          [  34] = rx_phy_postflop_0 [  35];
  assign rx_ar_data          [  35] = rx_phy_postflop_0 [  36];
  assign rx_ar_data          [  36] = rx_phy_postflop_0 [  37];
  assign rx_ar_data          [  37] = rx_phy_postflop_0 [  38];
  assign rx_ar_data          [  38] = rx_phy_postflop_0 [  39];
  assign rx_ar_data          [  39] = rx_phy_postflop_0 [  40];
  assign rx_ar_data          [  40] = rx_phy_postflop_0 [  41];
  assign rx_ar_data          [  41] = rx_phy_postflop_0 [  42];
  assign rx_ar_data          [  42] = rx_phy_postflop_0 [  43];
  assign rx_ar_data          [  43] = rx_phy_postflop_0 [  44];
  assign rx_ar_data          [  44] = rx_phy_postflop_0 [  45];
  assign rx_ar_data          [  45] = rx_phy_postflop_0 [  46];
  assign rx_ar_data          [  46] = rx_phy_postflop_0 [  47];
  assign rx_ar_data          [  47] = rx_phy_postflop_0 [  48];
  assign rx_ar_data          [  48] = rx_phy_postflop_0 [  49];
  assign rx_aw_pushbit              = rx_phy_postflop_0 [  50];
  assign rx_aw_data          [   0] = rx_phy_postflop_0 [  51];
  assign rx_aw_data          [   1] = rx_phy_postflop_0 [  52];
  assign rx_aw_data          [   2] = rx_phy_postflop_0 [  53];
  assign rx_aw_data          [   3] = rx_phy_postflop_0 [  54];
  assign rx_aw_data          [   4] = rx_phy_postflop_0 [  55];
  assign rx_aw_data          [   5] = rx_phy_postflop_0 [  56];
  assign rx_aw_data          [   6] = rx_phy_postflop_0 [  57];
  assign rx_aw_data          [   7] = rx_phy_postflop_0 [  58];
  assign rx_aw_data          [   8] = rx_phy_postflop_0 [  59];
  assign rx_aw_data          [   9] = rx_phy_postflop_0 [  60];
  assign rx_aw_data          [  10] = rx_phy_postflop_0 [  61];
  assign rx_aw_data          [  11] = rx_phy_postflop_0 [  62];
  assign rx_aw_data          [  12] = rx_phy_postflop_0 [  63];
  assign rx_aw_data          [  13] = rx_phy_postflop_0 [  64];
  assign rx_aw_data          [  14] = rx_phy_postflop_0 [  65];
  assign rx_aw_data          [  15] = rx_phy_postflop_0 [  66];
  assign rx_aw_data          [  16] = rx_phy_postflop_0 [  67];
  assign rx_aw_data          [  17] = rx_phy_postflop_0 [  68];
  assign rx_aw_data          [  18] = rx_phy_postflop_0 [  69];
  assign rx_aw_data          [  19] = rx_phy_postflop_0 [  70];
  assign rx_aw_data          [  20] = rx_phy_postflop_0 [  71];
  assign rx_aw_data          [  21] = rx_phy_postflop_0 [  72];
  assign rx_aw_data          [  22] = rx_phy_postflop_0 [  73];
  assign rx_aw_data          [  23] = rx_phy_postflop_0 [  74];
  assign rx_aw_data          [  24] = rx_phy_postflop_0 [  75];
  assign rx_aw_data          [  25] = rx_phy_postflop_0 [  76];
  assign rx_aw_data          [  26] = rx_phy_postflop_0 [  77];
  assign rx_aw_data          [  27] = rx_phy_postflop_0 [  78];
  assign rx_aw_data          [  28] = rx_phy_postflop_0 [  79];
  assign rx_aw_data          [  29] = rx_phy_postflop_0 [  80];
  assign rx_aw_data          [  30] = rx_phy_postflop_0 [  81];
  assign rx_aw_data          [  31] = rx_phy_postflop_0 [  82];
  assign rx_aw_data          [  32] = rx_phy_postflop_0 [  83];
  assign rx_aw_data          [  33] = rx_phy_postflop_0 [  84];
  assign rx_aw_data          [  34] = rx_phy_postflop_0 [  85];
  assign rx_aw_data          [  35] = rx_phy_postflop_0 [  86];
  assign rx_aw_data          [  36] = rx_phy_postflop_0 [  87];
  assign rx_aw_data          [  37] = rx_phy_postflop_0 [  88];
  assign rx_aw_data          [  38] = rx_phy_postflop_0 [  89];
  assign rx_aw_data          [  39] = rx_phy_postflop_0 [  90];
  assign rx_aw_data          [  40] = rx_phy_postflop_0 [  91];
  assign rx_aw_data          [  41] = rx_phy_postflop_0 [  92];
  assign rx_aw_data          [  42] = rx_phy_postflop_0 [  93];
  assign rx_aw_data          [  43] = rx_phy_postflop_0 [  94];
  assign rx_aw_data          [  44] = rx_phy_postflop_0 [  95];
  assign rx_aw_data          [  45] = rx_phy_postflop_0 [  96];
  assign rx_aw_data          [  46] = rx_phy_postflop_0 [  97];
  assign rx_aw_data          [  47] = rx_phy_postflop_0 [  98];
  assign rx_aw_data          [  48] = rx_phy_postflop_0 [  99];
  assign rx_w_pushbit               = rx_phy_postflop_0 [ 100];
  assign rx_w_data           [   0] = rx_phy_postflop_0 [ 101];
  assign rx_w_data           [   1] = rx_phy_postflop_0 [ 102];
  assign rx_w_data           [   2] = rx_phy_postflop_0 [ 103];
  assign rx_w_data           [   3] = rx_phy_postflop_0 [ 104];
  assign rx_w_data           [   4] = rx_phy_postflop_0 [ 105];
  assign rx_w_data           [   5] = rx_phy_postflop_0 [ 106];
  assign rx_w_data           [   6] = rx_phy_postflop_0 [ 107];
  assign rx_w_data           [   7] = rx_phy_postflop_0 [ 108];
  assign rx_w_data           [   8] = rx_phy_postflop_0 [ 109];
  assign rx_w_data           [   9] = rx_phy_postflop_0 [ 110];
  assign rx_w_data           [  10] = rx_phy_postflop_0 [ 111];
  assign rx_w_data           [  11] = rx_phy_postflop_0 [ 112];
  assign rx_w_data           [  12] = rx_phy_postflop_0 [ 113];
  assign rx_w_data           [  13] = rx_phy_postflop_0 [ 114];
  assign rx_w_data           [  14] = rx_phy_postflop_0 [ 115];
  assign rx_w_data           [  15] = rx_phy_postflop_0 [ 116];
  assign rx_w_data           [  16] = rx_phy_postflop_0 [ 117];
  assign rx_w_data           [  17] = rx_phy_postflop_0 [ 118];
  assign rx_w_data           [  18] = rx_phy_postflop_0 [ 119];
  assign rx_w_data           [  19] = rx_phy_postflop_0 [ 120];
  assign rx_w_data           [  20] = rx_phy_postflop_0 [ 121];
  assign rx_w_data           [  21] = rx_phy_postflop_0 [ 122];
  assign rx_w_data           [  22] = rx_phy_postflop_0 [ 123];
  assign rx_w_data           [  23] = rx_phy_postflop_0 [ 124];
  assign rx_w_data           [  24] = rx_phy_postflop_0 [ 125];
  assign rx_w_data           [  25] = rx_phy_postflop_0 [ 126];
  assign rx_w_data           [  26] = rx_phy_postflop_0 [ 127];
  assign rx_w_data           [  27] = rx_phy_postflop_0 [ 128];
  assign rx_w_data           [  28] = rx_phy_postflop_0 [ 129];
  assign rx_w_data           [  29] = rx_phy_postflop_0 [ 130];
  assign rx_w_data           [  30] = rx_phy_postflop_0 [ 131];
  assign rx_w_data           [  31] = rx_phy_postflop_0 [ 132];
  assign rx_w_data           [  32] = rx_phy_postflop_0 [ 133];
  assign rx_w_data           [  33] = rx_phy_postflop_0 [ 134];
  assign rx_w_data           [  34] = rx_phy_postflop_0 [ 135];
  assign rx_w_data           [  35] = rx_phy_postflop_0 [ 136];
  assign rx_w_data           [  36] = rx_phy_postflop_0 [ 137];
  assign rx_w_data           [  37] = rx_phy_postflop_0 [ 138];
  assign rx_w_data           [  38] = rx_phy_postflop_0 [ 139];
  assign rx_w_data           [  39] = rx_phy_postflop_0 [ 140];
  assign rx_w_data           [  40] = rx_phy_postflop_0 [ 141];
  assign rx_w_data           [  41] = rx_phy_postflop_0 [ 142];
  assign rx_w_data           [  42] = rx_phy_postflop_0 [ 143];
  assign rx_w_data           [  43] = rx_phy_postflop_0 [ 144];
  assign rx_w_data           [  44] = rx_phy_postflop_0 [ 145];
  assign rx_w_data           [  45] = rx_phy_postflop_0 [ 146];
  assign rx_w_data           [  46] = rx_phy_postflop_0 [ 147];
  assign rx_w_data           [  47] = rx_phy_postflop_0 [ 148];
  assign rx_w_data           [  48] = rx_phy_postflop_0 [ 149];
  assign rx_w_data           [  49] = rx_phy_postflop_0 [ 150];
  assign rx_w_data           [  50] = rx_phy_postflop_0 [ 151];
  assign rx_w_data           [  51] = rx_phy_postflop_0 [ 152];
  assign rx_w_data           [  52] = rx_phy_postflop_0 [ 153];
  assign rx_w_data           [  53] = rx_phy_postflop_0 [ 154];
  assign rx_w_data           [  54] = rx_phy_postflop_0 [ 155];
  assign rx_w_data           [  55] = rx_phy_postflop_0 [ 156];
  assign rx_w_data           [  56] = rx_phy_postflop_0 [ 157];
  assign rx_w_data           [  57] = rx_phy_postflop_0 [ 158];
  assign rx_w_data           [  58] = rx_phy_postflop_0 [ 159];
  assign rx_w_data           [  59] = rx_phy_postflop_0 [ 160];
  assign rx_w_data           [  60] = rx_phy_postflop_0 [ 161];
  assign rx_w_data           [  61] = rx_phy_postflop_0 [ 162];
  assign rx_w_data           [  62] = rx_phy_postflop_0 [ 163];
  assign rx_w_data           [  63] = rx_phy_postflop_0 [ 164];
  assign rx_w_data           [  64] = rx_phy_postflop_0 [ 165];
  assign rx_w_data           [  65] = rx_phy_postflop_0 [ 166];
  assign rx_w_data           [  66] = rx_phy_postflop_0 [ 167];
  assign rx_w_data           [  67] = rx_phy_postflop_0 [ 168];
  assign rx_w_data           [  68] = rx_phy_postflop_0 [ 169];
  assign rx_w_data           [  69] = rx_phy_postflop_0 [ 170];
  assign rx_w_data           [  70] = rx_phy_postflop_0 [ 171];
  assign rx_w_data           [  71] = rx_phy_postflop_0 [ 172];
  assign rx_w_data           [  72] = rx_phy_postflop_0 [ 173];
  assign rx_w_data           [  73] = rx_phy_postflop_0 [ 174];
  assign rx_w_data           [  74] = rx_phy_postflop_0 [ 175];
  assign rx_w_data           [  75] = rx_phy_postflop_0 [ 176];
  assign rx_w_data           [  76] = rx_phy_postflop_0 [ 177];
  assign rx_w_data           [  77] = rx_phy_postflop_0 [ 178];
  assign rx_w_data           [  78] = rx_phy_postflop_0 [ 179];
  assign rx_w_data           [  79] = rx_phy_postflop_0 [ 180];
  assign rx_w_data           [  80] = rx_phy_postflop_0 [ 181];
  assign rx_w_data           [  81] = rx_phy_postflop_0 [ 182];
  assign rx_w_data           [  82] = rx_phy_postflop_0 [ 183];
  assign rx_w_data           [  83] = rx_phy_postflop_0 [ 184];
  assign rx_w_data           [  84] = rx_phy_postflop_0 [ 185];
  assign rx_w_data           [  85] = rx_phy_postflop_0 [ 186];
  assign rx_w_data           [  86] = rx_phy_postflop_0 [ 187];
  assign rx_w_data           [  87] = rx_phy_postflop_0 [ 188];
  assign rx_w_data           [  88] = rx_phy_postflop_0 [ 189];
  assign rx_w_data           [  89] = rx_phy_postflop_0 [ 190];
  assign rx_w_data           [  90] = rx_phy_postflop_0 [ 191];
  assign rx_w_data           [  91] = rx_phy_postflop_0 [ 192];
  assign rx_w_data           [  92] = rx_phy_postflop_0 [ 193];
  assign rx_w_data           [  93] = rx_phy_postflop_0 [ 194];
  assign rx_w_data           [  94] = rx_phy_postflop_0 [ 195];
  assign rx_w_data           [  95] = rx_phy_postflop_0 [ 196];
  assign rx_w_data           [  96] = rx_phy_postflop_0 [ 197];
  assign rx_w_data           [  97] = rx_phy_postflop_0 [ 198];
  assign rx_w_data           [  98] = rx_phy_postflop_0 [ 199];
  assign rx_w_data           [  99] = rx_phy_postflop_0 [ 200];
  assign rx_w_data           [ 100] = rx_phy_postflop_0 [ 201];
  assign rx_w_data           [ 101] = rx_phy_postflop_0 [ 202];
  assign rx_w_data           [ 102] = rx_phy_postflop_0 [ 203];
  assign rx_w_data           [ 103] = rx_phy_postflop_0 [ 204];
  assign rx_w_data           [ 104] = rx_phy_postflop_0 [ 205];
  assign rx_w_data           [ 105] = rx_phy_postflop_0 [ 206];
  assign rx_w_data           [ 106] = rx_phy_postflop_0 [ 207];
  assign rx_w_data           [ 107] = rx_phy_postflop_0 [ 208];
  assign rx_w_data           [ 108] = rx_phy_postflop_0 [ 209];
  assign rx_w_data           [ 109] = rx_phy_postflop_0 [ 210];
  assign rx_w_data           [ 110] = rx_phy_postflop_0 [ 211];
  assign rx_w_data           [ 111] = rx_phy_postflop_0 [ 212];
  assign rx_w_data           [ 112] = rx_phy_postflop_0 [ 213];
  assign rx_w_data           [ 113] = rx_phy_postflop_0 [ 214];
  assign rx_w_data           [ 114] = rx_phy_postflop_0 [ 215];
  assign rx_w_data           [ 115] = rx_phy_postflop_0 [ 216];
  assign rx_w_data           [ 116] = rx_phy_postflop_0 [ 217];
  assign rx_w_data           [ 117] = rx_phy_postflop_0 [ 218];
  assign rx_w_data           [ 118] = rx_phy_postflop_0 [ 219];
  assign rx_w_data           [ 119] = rx_phy_postflop_0 [ 220];
  assign rx_w_data           [ 120] = rx_phy_postflop_0 [ 221];
  assign rx_w_data           [ 121] = rx_phy_postflop_0 [ 222];
  assign rx_w_data           [ 122] = rx_phy_postflop_0 [ 223];
  assign rx_w_data           [ 123] = rx_phy_postflop_0 [ 224];
  assign rx_w_data           [ 124] = rx_phy_postflop_0 [ 225];
  assign rx_w_data           [ 125] = rx_phy_postflop_0 [ 226];
  assign rx_w_data           [ 126] = rx_phy_postflop_0 [ 227];
  assign rx_w_data           [ 127] = rx_phy_postflop_0 [ 228];
  assign rx_w_data           [ 128] = rx_phy_postflop_0 [ 229];
  assign rx_w_data           [ 129] = rx_phy_postflop_0 [ 230];
  assign rx_w_data           [ 130] = rx_phy_postflop_0 [ 231];
  assign rx_w_data           [ 131] = rx_phy_postflop_0 [ 232];
  assign rx_w_data           [ 132] = rx_phy_postflop_0 [ 233];
  assign rx_w_data           [ 133] = rx_phy_postflop_0 [ 234];
  assign rx_w_data           [ 134] = rx_phy_postflop_0 [ 235];
  assign rx_w_data           [ 135] = rx_phy_postflop_0 [ 236];
  assign rx_w_data           [ 136] = rx_phy_postflop_0 [ 237];
  assign rx_w_data           [ 137] = rx_phy_postflop_0 [ 238];
  assign rx_w_data           [ 138] = rx_phy_postflop_0 [ 239];
  assign rx_w_data           [ 139] = rx_phy_postflop_0 [ 240];
  assign rx_w_data           [ 140] = rx_phy_postflop_0 [ 241];
  assign rx_w_data           [ 141] = rx_phy_postflop_0 [ 242];
  assign rx_w_data           [ 142] = rx_phy_postflop_0 [ 243];
  assign rx_w_data           [ 143] = rx_phy_postflop_0 [ 244];
  assign rx_w_data           [ 144] = rx_phy_postflop_0 [ 245];
  assign rx_w_data           [ 145] = rx_phy_postflop_0 [ 246];
  assign rx_w_data           [ 146] = rx_phy_postflop_0 [ 247];
  assign rx_w_data           [ 147] = rx_phy_postflop_0 [ 248];
  assign rx_w_data           [ 148] = rx_phy_postflop_0 [ 249];
  assign rx_r_credit                = rx_phy_postflop_0 [ 250];
  assign rx_b_credit                = rx_phy_postflop_0 [ 251];
//       nc                         = rx_phy_postflop_0 [ 252];
//       nc                         = rx_phy_postflop_0 [ 253];
//       nc                         = rx_phy_postflop_0 [ 254];
//       nc                         = rx_phy_postflop_0 [ 255];
//       nc                         = rx_phy_postflop_0 [ 256];
//       nc                         = rx_phy_postflop_0 [ 257];
//       nc                         = rx_phy_postflop_0 [ 258];
//       nc                         = rx_phy_postflop_0 [ 259];
//       nc                         = rx_phy_postflop_0 [ 260];
//       nc                         = rx_phy_postflop_0 [ 261];
//       nc                         = rx_phy_postflop_0 [ 262];
//       nc                         = rx_phy_postflop_0 [ 263];
//       nc                         = rx_phy_postflop_0 [ 264];
//       nc                         = rx_phy_postflop_0 [ 265];
//       nc                         = rx_phy_postflop_0 [ 266];
//       nc                         = rx_phy_postflop_0 [ 267];
//       nc                         = rx_phy_postflop_0 [ 268];
//       nc                         = rx_phy_postflop_0 [ 269];
//       nc                         = rx_phy_postflop_0 [ 270];
//       nc                         = rx_phy_postflop_0 [ 271];
//       nc                         = rx_phy_postflop_0 [ 272];
//       nc                         = rx_phy_postflop_0 [ 273];
//       nc                         = rx_phy_postflop_0 [ 274];
//       nc                         = rx_phy_postflop_0 [ 275];
//       nc                         = rx_phy_postflop_0 [ 276];
//       nc                         = rx_phy_postflop_0 [ 277];
//       nc                         = rx_phy_postflop_0 [ 278];
//       nc                         = rx_phy_postflop_0 [ 279];
//       nc                         = rx_phy_postflop_0 [ 280];
//       nc                         = rx_phy_postflop_0 [ 281];
//       nc                         = rx_phy_postflop_0 [ 282];
//       nc                         = rx_phy_postflop_0 [ 283];
//       nc                         = rx_phy_postflop_0 [ 284];
//       nc                         = rx_phy_postflop_0 [ 285];
//       nc                         = rx_phy_postflop_0 [ 286];
//       nc                         = rx_phy_postflop_0 [ 287];
//       nc                         = rx_phy_postflop_0 [ 288];
//       nc                         = rx_phy_postflop_0 [ 289];
//       nc                         = rx_phy_postflop_0 [ 290];
//       nc                         = rx_phy_postflop_0 [ 291];
//       nc                         = rx_phy_postflop_0 [ 292];
//       nc                         = rx_phy_postflop_0 [ 293];
//       nc                         = rx_phy_postflop_0 [ 294];
//       nc                         = rx_phy_postflop_0 [ 295];
//       nc                         = rx_phy_postflop_0 [ 296];
//       nc                         = rx_phy_postflop_0 [ 297];
//       nc                         = rx_phy_postflop_0 [ 298];
//       nc                         = rx_phy_postflop_0 [ 299];
//       nc                         = rx_phy_postflop_0 [ 300];
//       nc                         = rx_phy_postflop_0 [ 301];
//       nc                         = rx_phy_postflop_0 [ 302];
//       nc                         = rx_phy_postflop_0 [ 303];
//       nc                         = rx_phy_postflop_0 [ 304];
//       nc                         = rx_phy_postflop_0 [ 305];
//       nc                         = rx_phy_postflop_0 [ 306];
//       nc                         = rx_phy_postflop_0 [ 307];
//       nc                         = rx_phy_postflop_0 [ 308];
//       nc                         = rx_phy_postflop_0 [ 309];
//       nc                         = rx_phy_postflop_0 [ 310];
//       nc                         = rx_phy_postflop_0 [ 311];
//       nc                         = rx_phy_postflop_0 [ 312];
//       nc                         = rx_phy_postflop_0 [ 313];
//       nc                         = rx_phy_postflop_0 [ 314];
//       nc                         = rx_phy_postflop_0 [ 315];
//       nc                         = rx_phy_postflop_0 [ 316];
//       nc                         = rx_phy_postflop_0 [ 317];
//       nc                         = rx_phy_postflop_0 [ 318];
//       nc                         = rx_phy_postflop_0 [ 319];

// RX Section
//////////////////////////////////////////////////////////////////


endmodule
