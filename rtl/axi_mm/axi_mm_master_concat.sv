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

module axi_mm_master_concat  (

// Data from Logic Links
  input  logic [  48:   0]   tx_ar_data          ,
  output logic               tx_ar_pop_ovrd      ,
  input  logic               tx_ar_pushbit       ,
  output logic               rx_ar_credit        ,

  input  logic [  48:   0]   tx_aw_data          ,
  output logic               tx_aw_pop_ovrd      ,
  input  logic               tx_aw_pushbit       ,
  output logic               rx_aw_credit        ,

  input  logic [  76:   0]   tx_w_data           ,
  output logic               tx_w_pop_ovrd       ,
  input  logic               tx_w_pushbit        ,
  output logic               rx_w_credit         ,

  output logic [  70:   0]   rx_r_data           ,
  output logic               rx_r_push_ovrd      ,
  output logic               rx_r_pushbit        ,
  input  logic               tx_r_credit         ,

  output logic [   5:   0]   rx_b_data           ,
  output logic               rx_b_push_ovrd      ,
  output logic               rx_b_pushbit        ,
  input  logic               tx_b_credit         ,

// PHY Interconnect
  output logic [ 159:   0]   tx_phy0             ,
  input  logic [ 159:   0]   rx_phy0             ,

  input  logic               clk_wr              ,
  input  logic               clk_rd              ,
  input  logic               rst_wr_n            ,
  input  logic               rst_rd_n            ,

  input  logic               m_gen2_mode         ,
  input  logic               tx_online           ,

  input  logic               tx_stb_userbit      ,
  input  logic [   1:   0]   tx_mrk_userbit      

);

//////////////////////////////////////////////////////////////////
// TX Packet Section
  logic [   2:   0]                              tx_requestor                  ;
  logic [   2:   0]                              tx_grant_onehotish            ;
  logic [   1:   0]                              tx_grant_enc_data             ;
  logic [ 153:   0]                              tx_packet_data                ;
  logic [ 153:   0]                              tx_packet_data0               ;
  logic [ 153:   0]                              tx_packet_data1               ;
  logic [ 153:   0]                              tx_packet_data2               ;

  rrarb #(.REQUESTORS(3)) rrarb_itx
          (// Outputs
           .grant                     (tx_grant_onehotish),
           // Inputs
           .clk_core                  (clk_wr),
           .rst_core_n                (rst_wr_n),
           .requestor                 (tx_requestor),
           .advance                   (1'b1));

  // This converts from one-hot-ish rrarb output to encoded value
  always_comb
  begin
    case(tx_grant_onehotish)
       3'b001 : tx_grant_enc_data =  2'd0   ;
       3'b010 : tx_grant_enc_data =  2'd1   ;
       3'b100 : tx_grant_enc_data =  2'd2   ;
      default : tx_grant_enc_data =  2'd0   ;
    endcase
  end

  // This assigns the data portion of packetizing
  always_comb
  begin
    case(tx_grant_enc_data)
       2'd0    : tx_packet_data = tx_packet_data0;
       2'd1    : tx_packet_data = tx_packet_data1;
       2'd2    : tx_packet_data = tx_packet_data2;
      default  : tx_packet_data = tx_packet_data2;
    endcase
  end

  // This controls if we can pop the TX FIFO
  assign tx_ar_pop_ovrd = (tx_grant_enc_data == 2'd0) ? 1'b0 : 1'b1;
  assign tx_aw_pop_ovrd = (tx_grant_enc_data == 2'd1) ? 1'b0 : 1'b1;
  assign tx_w_pop_ovrd = (tx_grant_enc_data == 2'd2) ? 1'b0 : 1'b1;

  // Request to Arbitrate
  assign tx_requestor [0] = tx_ar_pushbit ; 
  assign tx_requestor [1] = tx_aw_pushbit ; 
  assign tx_requestor [2] = tx_w_pushbit ; 

  // Data to Transmit
  assign tx_packet_data0      [   0 +:  49] = tx_ar_data           [   0 +:  49] ; // Llink Data
  assign tx_packet_data0      [  49 +:   1] = tx_ar_pushbit                      ; // Push Bit
  assign tx_packet_data0      [  50 +: 104] = 104'b0                             ; // Spare

  assign tx_packet_data1      [   0 +:  49] = tx_aw_data           [   0 +:  49] ; // Llink Data
  assign tx_packet_data1      [  49 +:   1] = tx_aw_pushbit                      ; // Push Bit
  assign tx_packet_data1      [  50 +: 104] = 104'b0                             ; // Spare

  assign tx_packet_data2      [   0 +:  77] = tx_w_data            [   0 +:  77] ; // Llink Data
  assign tx_packet_data2      [  77 +:   1] = tx_w_pushbit                       ; // Push Bit
  assign tx_packet_data2      [  78 +:  76] = 76'b0                              ; // Spare

// TX Packet Section
//////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////
// RX Packet Section

  logic [   0:   0]                              rx_grant_enc_data             ;
  logic [ 153:   0]                              rx_packet_data                ;

  // This controls if we override the RX Push Bit (if the signal is 0, that is only time Push Bit could be valid)
  assign rx_r_push_ovrd       = (rx_grant_enc_data == 1'd1) ? 1'b0 : 1'b1;
  assign rx_b_push_ovrd       = (rx_grant_enc_data == 1'd0) ? 1'b0 : 1'b1;

  // This is RX Push Bit
  assign rx_b_pushbit         = ((rx_grant_enc_data == 1'd0) && (rx_packet_data [6] == 1'b1));
  assign rx_r_pushbit         = ((rx_grant_enc_data == 1'd1) && (rx_packet_data [71] == 1'b1));

  // This is RX Data
  assign rx_b_data            [   0 +:   6] = rx_packet_data       [   0 +:   6];
  assign rx_r_data            [   0 +:  71] = rx_packet_data       [   0 +:  71];

// RX Packet Section
//////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////
// TX Section

//   TX_CH_WIDTH           = 160; // Gen2Only running at Half Rate
//   TX_DATA_WIDTH         = 158; // Usable Data per Channel
//   TX_PERSISTENT_STROBE  = 1'b1;
//   TX_PERSISTENT_MARKER  = 1'b1;
//   TX_STROBE_GEN2_LOC    = 'd0;
//   TX_MARKER_GEN2_LOC    = 'd78;
//   TX_STROBE_GEN1_LOC    = 'd0;
//   TX_MARKER_GEN1_LOC    = 'd39;
//   TX_ENABLE_STROBE      = 1'b0;
//   TX_ENABLE_MARKER      = 1'b1;
//   TX_DBI_PRESENT        = 1'b0;
//   TX_REG_PHY            = 1'b0;

  localparam TX_REG_PHY    = 1'b0;  // If set, this enables boundary FF for timing reasons

  logic [ 159:   0]                              tx_phy_preflop_0              ;
  logic [ 159:   0]                              tx_phy_flop_0_reg             ;

  always_ff @(posedge clk_wr or negedge rst_wr_n)
  if (~rst_wr_n)
  begin
    tx_phy_flop_0_reg                       <= 160'b0                                  ;
  end
  else
  begin
    tx_phy_flop_0_reg                       <= tx_phy_preflop_0                        ;
  end

  assign tx_phy0                            = TX_REG_PHY ? tx_phy_flop_0_reg : tx_phy_preflop_0               ;

  assign tx_phy_preflop_0 [   0] = tx_grant_enc_data   [   0] ;
  assign tx_phy_preflop_0 [   1] = tx_grant_enc_data   [   1] ;
  assign tx_phy_preflop_0 [   2] = tx_packet_data      [   0] ;
  assign tx_phy_preflop_0 [   3] = tx_packet_data      [   1] ;
  assign tx_phy_preflop_0 [   4] = tx_packet_data      [   2] ;
  assign tx_phy_preflop_0 [   5] = tx_packet_data      [   3] ;
  assign tx_phy_preflop_0 [   6] = tx_packet_data      [   4] ;
  assign tx_phy_preflop_0 [   7] = tx_packet_data      [   5] ;
  assign tx_phy_preflop_0 [   8] = tx_packet_data      [   6] ;
  assign tx_phy_preflop_0 [   9] = tx_packet_data      [   7] ;
  assign tx_phy_preflop_0 [  10] = tx_packet_data      [   8] ;
  assign tx_phy_preflop_0 [  11] = tx_packet_data      [   9] ;
  assign tx_phy_preflop_0 [  12] = tx_packet_data      [  10] ;
  assign tx_phy_preflop_0 [  13] = tx_packet_data      [  11] ;
  assign tx_phy_preflop_0 [  14] = tx_packet_data      [  12] ;
  assign tx_phy_preflop_0 [  15] = tx_packet_data      [  13] ;
  assign tx_phy_preflop_0 [  16] = tx_packet_data      [  14] ;
  assign tx_phy_preflop_0 [  17] = tx_packet_data      [  15] ;
  assign tx_phy_preflop_0 [  18] = tx_packet_data      [  16] ;
  assign tx_phy_preflop_0 [  19] = tx_packet_data      [  17] ;
  assign tx_phy_preflop_0 [  20] = tx_packet_data      [  18] ;
  assign tx_phy_preflop_0 [  21] = tx_packet_data      [  19] ;
  assign tx_phy_preflop_0 [  22] = tx_packet_data      [  20] ;
  assign tx_phy_preflop_0 [  23] = tx_packet_data      [  21] ;
  assign tx_phy_preflop_0 [  24] = tx_packet_data      [  22] ;
  assign tx_phy_preflop_0 [  25] = tx_packet_data      [  23] ;
  assign tx_phy_preflop_0 [  26] = tx_packet_data      [  24] ;
  assign tx_phy_preflop_0 [  27] = tx_packet_data      [  25] ;
  assign tx_phy_preflop_0 [  28] = tx_packet_data      [  26] ;
  assign tx_phy_preflop_0 [  29] = tx_packet_data      [  27] ;
  assign tx_phy_preflop_0 [  30] = tx_packet_data      [  28] ;
  assign tx_phy_preflop_0 [  31] = tx_packet_data      [  29] ;
  assign tx_phy_preflop_0 [  32] = tx_packet_data      [  30] ;
  assign tx_phy_preflop_0 [  33] = tx_packet_data      [  31] ;
  assign tx_phy_preflop_0 [  34] = tx_packet_data      [  32] ;
  assign tx_phy_preflop_0 [  35] = tx_packet_data      [  33] ;
  assign tx_phy_preflop_0 [  36] = tx_packet_data      [  34] ;
  assign tx_phy_preflop_0 [  37] = tx_packet_data      [  35] ;
  assign tx_phy_preflop_0 [  38] = tx_packet_data      [  36] ;
  assign tx_phy_preflop_0 [  39] = tx_packet_data      [  37] ;
  assign tx_phy_preflop_0 [  40] = tx_packet_data      [  38] ;
  assign tx_phy_preflop_0 [  41] = tx_packet_data      [  39] ;
  assign tx_phy_preflop_0 [  42] = tx_packet_data      [  40] ;
  assign tx_phy_preflop_0 [  43] = tx_packet_data      [  41] ;
  assign tx_phy_preflop_0 [  44] = tx_packet_data      [  42] ;
  assign tx_phy_preflop_0 [  45] = tx_packet_data      [  43] ;
  assign tx_phy_preflop_0 [  46] = tx_packet_data      [  44] ;
  assign tx_phy_preflop_0 [  47] = tx_packet_data      [  45] ;
  assign tx_phy_preflop_0 [  48] = tx_packet_data      [  46] ;
  assign tx_phy_preflop_0 [  49] = tx_packet_data      [  47] ;
  assign tx_phy_preflop_0 [  50] = tx_packet_data      [  48] ;
  assign tx_phy_preflop_0 [  51] = tx_packet_data      [  49] ;
  assign tx_phy_preflop_0 [  52] = tx_packet_data      [  50] ;
  assign tx_phy_preflop_0 [  53] = tx_packet_data      [  51] ;
  assign tx_phy_preflop_0 [  54] = tx_packet_data      [  52] ;
  assign tx_phy_preflop_0 [  55] = tx_packet_data      [  53] ;
  assign tx_phy_preflop_0 [  56] = tx_packet_data      [  54] ;
  assign tx_phy_preflop_0 [  57] = tx_packet_data      [  55] ;
  assign tx_phy_preflop_0 [  58] = tx_packet_data      [  56] ;
  assign tx_phy_preflop_0 [  59] = tx_packet_data      [  57] ;
  assign tx_phy_preflop_0 [  60] = tx_packet_data      [  58] ;
  assign tx_phy_preflop_0 [  61] = tx_packet_data      [  59] ;
  assign tx_phy_preflop_0 [  62] = tx_packet_data      [  60] ;
  assign tx_phy_preflop_0 [  63] = tx_packet_data      [  61] ;
  assign tx_phy_preflop_0 [  64] = tx_packet_data      [  62] ;
  assign tx_phy_preflop_0 [  65] = tx_packet_data      [  63] ;
  assign tx_phy_preflop_0 [  66] = tx_packet_data      [  64] ;
  assign tx_phy_preflop_0 [  67] = tx_packet_data      [  65] ;
  assign tx_phy_preflop_0 [  68] = tx_packet_data      [  66] ;
  assign tx_phy_preflop_0 [  69] = tx_packet_data      [  67] ;
  assign tx_phy_preflop_0 [  70] = tx_packet_data      [  68] ;
  assign tx_phy_preflop_0 [  71] = tx_packet_data      [  69] ;
  assign tx_phy_preflop_0 [  72] = tx_packet_data      [  70] ;
  assign tx_phy_preflop_0 [  73] = tx_packet_data      [  71] ;
  assign tx_phy_preflop_0 [  74] = tx_packet_data      [  72] ;
  assign tx_phy_preflop_0 [  75] = tx_packet_data      [  73] ;
  assign tx_phy_preflop_0 [  76] = tx_packet_data      [  74] ;
  assign tx_phy_preflop_0 [  77] = tx_packet_data      [  75] ;
  assign tx_phy_preflop_0 [  78] = tx_mrk_userbit[0]          ; // MARKER
  assign tx_phy_preflop_0 [  79] = tx_packet_data      [  76] ;
  assign tx_phy_preflop_0 [  80] = tx_packet_data      [  77] ;
  assign tx_phy_preflop_0 [  81] = tx_packet_data      [  78] ;
  assign tx_phy_preflop_0 [  82] = tx_packet_data      [  79] ;
  assign tx_phy_preflop_0 [  83] = tx_packet_data      [  80] ;
  assign tx_phy_preflop_0 [  84] = tx_packet_data      [  81] ;
  assign tx_phy_preflop_0 [  85] = tx_packet_data      [  82] ;
  assign tx_phy_preflop_0 [  86] = tx_packet_data      [  83] ;
  assign tx_phy_preflop_0 [  87] = tx_packet_data      [  84] ;
  assign tx_phy_preflop_0 [  88] = tx_packet_data      [  85] ;
  assign tx_phy_preflop_0 [  89] = tx_packet_data      [  86] ;
  assign tx_phy_preflop_0 [  90] = tx_packet_data      [  87] ;
  assign tx_phy_preflop_0 [  91] = tx_packet_data      [  88] ;
  assign tx_phy_preflop_0 [  92] = tx_packet_data      [  89] ;
  assign tx_phy_preflop_0 [  93] = tx_packet_data      [  90] ;
  assign tx_phy_preflop_0 [  94] = tx_packet_data      [  91] ;
  assign tx_phy_preflop_0 [  95] = tx_packet_data      [  92] ;
  assign tx_phy_preflop_0 [  96] = tx_packet_data      [  93] ;
  assign tx_phy_preflop_0 [  97] = tx_packet_data      [  94] ;
  assign tx_phy_preflop_0 [  98] = tx_packet_data      [  95] ;
  assign tx_phy_preflop_0 [  99] = tx_packet_data      [  96] ;
  assign tx_phy_preflop_0 [ 100] = tx_packet_data      [  97] ;
  assign tx_phy_preflop_0 [ 101] = tx_packet_data      [  98] ;
  assign tx_phy_preflop_0 [ 102] = tx_packet_data      [  99] ;
  assign tx_phy_preflop_0 [ 103] = tx_packet_data      [ 100] ;
  assign tx_phy_preflop_0 [ 104] = tx_packet_data      [ 101] ;
  assign tx_phy_preflop_0 [ 105] = tx_packet_data      [ 102] ;
  assign tx_phy_preflop_0 [ 106] = tx_packet_data      [ 103] ;
  assign tx_phy_preflop_0 [ 107] = tx_packet_data      [ 104] ;
  assign tx_phy_preflop_0 [ 108] = tx_packet_data      [ 105] ;
  assign tx_phy_preflop_0 [ 109] = tx_packet_data      [ 106] ;
  assign tx_phy_preflop_0 [ 110] = tx_packet_data      [ 107] ;
  assign tx_phy_preflop_0 [ 111] = tx_packet_data      [ 108] ;
  assign tx_phy_preflop_0 [ 112] = tx_packet_data      [ 109] ;
  assign tx_phy_preflop_0 [ 113] = tx_packet_data      [ 110] ;
  assign tx_phy_preflop_0 [ 114] = tx_packet_data      [ 111] ;
  assign tx_phy_preflop_0 [ 115] = tx_packet_data      [ 112] ;
  assign tx_phy_preflop_0 [ 116] = tx_packet_data      [ 113] ;
  assign tx_phy_preflop_0 [ 117] = tx_packet_data      [ 114] ;
  assign tx_phy_preflop_0 [ 118] = tx_packet_data      [ 115] ;
  assign tx_phy_preflop_0 [ 119] = tx_packet_data      [ 116] ;
  assign tx_phy_preflop_0 [ 120] = tx_packet_data      [ 117] ;
  assign tx_phy_preflop_0 [ 121] = tx_packet_data      [ 118] ;
  assign tx_phy_preflop_0 [ 122] = tx_packet_data      [ 119] ;
  assign tx_phy_preflop_0 [ 123] = tx_packet_data      [ 120] ;
  assign tx_phy_preflop_0 [ 124] = tx_packet_data      [ 121] ;
  assign tx_phy_preflop_0 [ 125] = tx_packet_data      [ 122] ;
  assign tx_phy_preflop_0 [ 126] = tx_packet_data      [ 123] ;
  assign tx_phy_preflop_0 [ 127] = tx_packet_data      [ 124] ;
  assign tx_phy_preflop_0 [ 128] = tx_packet_data      [ 125] ;
  assign tx_phy_preflop_0 [ 129] = tx_packet_data      [ 126] ;
  assign tx_phy_preflop_0 [ 130] = tx_packet_data      [ 127] ;
  assign tx_phy_preflop_0 [ 131] = tx_packet_data      [ 128] ;
  assign tx_phy_preflop_0 [ 132] = tx_packet_data      [ 129] ;
  assign tx_phy_preflop_0 [ 133] = tx_packet_data      [ 130] ;
  assign tx_phy_preflop_0 [ 134] = tx_packet_data      [ 131] ;
  assign tx_phy_preflop_0 [ 135] = tx_packet_data      [ 132] ;
  assign tx_phy_preflop_0 [ 136] = tx_packet_data      [ 133] ;
  assign tx_phy_preflop_0 [ 137] = tx_packet_data      [ 134] ;
  assign tx_phy_preflop_0 [ 138] = tx_packet_data      [ 135] ;
  assign tx_phy_preflop_0 [ 139] = tx_packet_data      [ 136] ;
  assign tx_phy_preflop_0 [ 140] = tx_packet_data      [ 137] ;
  assign tx_phy_preflop_0 [ 141] = tx_packet_data      [ 138] ;
  assign tx_phy_preflop_0 [ 142] = tx_packet_data      [ 139] ;
  assign tx_phy_preflop_0 [ 143] = tx_packet_data      [ 140] ;
  assign tx_phy_preflop_0 [ 144] = tx_packet_data      [ 141] ;
  assign tx_phy_preflop_0 [ 145] = tx_packet_data      [ 142] ;
  assign tx_phy_preflop_0 [ 146] = tx_packet_data      [ 143] ;
  assign tx_phy_preflop_0 [ 147] = tx_packet_data      [ 144] ;
  assign tx_phy_preflop_0 [ 148] = tx_packet_data      [ 145] ;
  assign tx_phy_preflop_0 [ 149] = tx_packet_data      [ 146] ;
  assign tx_phy_preflop_0 [ 150] = tx_packet_data      [ 147] ;
  assign tx_phy_preflop_0 [ 151] = tx_packet_data      [ 148] ;
  assign tx_phy_preflop_0 [ 152] = tx_packet_data      [ 149] ;
  assign tx_phy_preflop_0 [ 153] = tx_packet_data      [ 150] ;
  assign tx_phy_preflop_0 [ 154] = tx_packet_data      [ 151] ;
  assign tx_phy_preflop_0 [ 155] = tx_packet_data      [ 152] ;
  assign tx_phy_preflop_0 [ 156] = tx_packet_data      [ 153] ;
  assign tx_phy_preflop_0 [ 157] = tx_r_credit                ;
  assign tx_phy_preflop_0 [ 158] = tx_mrk_userbit[1]          ; // MARKER
  assign tx_phy_preflop_0 [ 159] = tx_b_credit                ;
// TX Section
//////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////
// RX Section

//   RX_CH_WIDTH           = 160; // Gen2Only running at Half Rate
//   RX_DATA_WIDTH         = 158; // Usable Data per Channel
//   RX_PERSISTENT_STROBE  = 1'b1;
//   RX_PERSISTENT_MARKER  = 1'b1;
//   RX_STROBE_GEN2_LOC    = 'd0;
//   RX_MARKER_GEN2_LOC    = 'd79;
//   RX_STROBE_GEN1_LOC    = 'd0;
//   RX_MARKER_GEN1_LOC    = 'd39;
//   RX_ENABLE_STROBE      = 1'b0;
//   RX_ENABLE_MARKER      = 1'b1;
//   RX_DBI_PRESENT        = 1'b0;
//   RX_REG_PHY            = 1'b0;

  localparam RX_REG_PHY    = 1'b0;  // If set, this enables boundary FF for timing reasons

  logic [ 159:   0]                              rx_phy_postflop_0             ;
  logic [ 159:   0]                              rx_phy_flop_0_reg             ;

  always_ff @(posedge clk_rd or negedge rst_rd_n)
  if (~rst_rd_n)
  begin
    rx_phy_flop_0_reg                       <= 160'b0                                  ;
  end
  else
  begin
    rx_phy_flop_0_reg                       <= rx_phy0                                 ;
  end


  assign rx_phy_postflop_0                  = RX_REG_PHY ? rx_phy_flop_0_reg : rx_phy0               ;

  assign rx_grant_enc_data   [   0] = rx_phy_postflop_0 [   0];
  assign rx_packet_data      [   0] = rx_phy_postflop_0 [   1];
  assign rx_packet_data      [   1] = rx_phy_postflop_0 [   2];
  assign rx_packet_data      [   2] = rx_phy_postflop_0 [   3];
  assign rx_packet_data      [   3] = rx_phy_postflop_0 [   4];
  assign rx_packet_data      [   4] = rx_phy_postflop_0 [   5];
  assign rx_packet_data      [   5] = rx_phy_postflop_0 [   6];
  assign rx_packet_data      [   6] = rx_phy_postflop_0 [   7];
  assign rx_packet_data      [   7] = rx_phy_postflop_0 [   8];
  assign rx_packet_data      [   8] = rx_phy_postflop_0 [   9];
  assign rx_packet_data      [   9] = rx_phy_postflop_0 [  10];
  assign rx_packet_data      [  10] = rx_phy_postflop_0 [  11];
  assign rx_packet_data      [  11] = rx_phy_postflop_0 [  12];
  assign rx_packet_data      [  12] = rx_phy_postflop_0 [  13];
  assign rx_packet_data      [  13] = rx_phy_postflop_0 [  14];
  assign rx_packet_data      [  14] = rx_phy_postflop_0 [  15];
  assign rx_packet_data      [  15] = rx_phy_postflop_0 [  16];
  assign rx_packet_data      [  16] = rx_phy_postflop_0 [  17];
  assign rx_packet_data      [  17] = rx_phy_postflop_0 [  18];
  assign rx_packet_data      [  18] = rx_phy_postflop_0 [  19];
  assign rx_packet_data      [  19] = rx_phy_postflop_0 [  20];
  assign rx_packet_data      [  20] = rx_phy_postflop_0 [  21];
  assign rx_packet_data      [  21] = rx_phy_postflop_0 [  22];
  assign rx_packet_data      [  22] = rx_phy_postflop_0 [  23];
  assign rx_packet_data      [  23] = rx_phy_postflop_0 [  24];
  assign rx_packet_data      [  24] = rx_phy_postflop_0 [  25];
  assign rx_packet_data      [  25] = rx_phy_postflop_0 [  26];
  assign rx_packet_data      [  26] = rx_phy_postflop_0 [  27];
  assign rx_packet_data      [  27] = rx_phy_postflop_0 [  28];
  assign rx_packet_data      [  28] = rx_phy_postflop_0 [  29];
  assign rx_packet_data      [  29] = rx_phy_postflop_0 [  30];
  assign rx_packet_data      [  30] = rx_phy_postflop_0 [  31];
  assign rx_packet_data      [  31] = rx_phy_postflop_0 [  32];
  assign rx_packet_data      [  32] = rx_phy_postflop_0 [  33];
  assign rx_packet_data      [  33] = rx_phy_postflop_0 [  34];
  assign rx_packet_data      [  34] = rx_phy_postflop_0 [  35];
  assign rx_packet_data      [  35] = rx_phy_postflop_0 [  36];
  assign rx_packet_data      [  36] = rx_phy_postflop_0 [  37];
  assign rx_packet_data      [  37] = rx_phy_postflop_0 [  38];
  assign rx_packet_data      [  38] = rx_phy_postflop_0 [  39];
  assign rx_packet_data      [  39] = rx_phy_postflop_0 [  40];
  assign rx_packet_data      [  40] = rx_phy_postflop_0 [  41];
  assign rx_packet_data      [  41] = rx_phy_postflop_0 [  42];
  assign rx_packet_data      [  42] = rx_phy_postflop_0 [  43];
  assign rx_packet_data      [  43] = rx_phy_postflop_0 [  44];
  assign rx_packet_data      [  44] = rx_phy_postflop_0 [  45];
  assign rx_packet_data      [  45] = rx_phy_postflop_0 [  46];
  assign rx_packet_data      [  46] = rx_phy_postflop_0 [  47];
  assign rx_packet_data      [  47] = rx_phy_postflop_0 [  48];
  assign rx_packet_data      [  48] = rx_phy_postflop_0 [  49];
  assign rx_packet_data      [  49] = rx_phy_postflop_0 [  50];
  assign rx_packet_data      [  50] = rx_phy_postflop_0 [  51];
  assign rx_packet_data      [  51] = rx_phy_postflop_0 [  52];
  assign rx_packet_data      [  52] = rx_phy_postflop_0 [  53];
  assign rx_packet_data      [  53] = rx_phy_postflop_0 [  54];
  assign rx_packet_data      [  54] = rx_phy_postflop_0 [  55];
  assign rx_packet_data      [  55] = rx_phy_postflop_0 [  56];
  assign rx_packet_data      [  56] = rx_phy_postflop_0 [  57];
  assign rx_packet_data      [  57] = rx_phy_postflop_0 [  58];
  assign rx_packet_data      [  58] = rx_phy_postflop_0 [  59];
  assign rx_packet_data      [  59] = rx_phy_postflop_0 [  60];
  assign rx_packet_data      [  60] = rx_phy_postflop_0 [  61];
  assign rx_packet_data      [  61] = rx_phy_postflop_0 [  62];
  assign rx_packet_data      [  62] = rx_phy_postflop_0 [  63];
  assign rx_packet_data      [  63] = rx_phy_postflop_0 [  64];
  assign rx_packet_data      [  64] = rx_phy_postflop_0 [  65];
  assign rx_packet_data      [  65] = rx_phy_postflop_0 [  66];
  assign rx_packet_data      [  66] = rx_phy_postflop_0 [  67];
  assign rx_packet_data      [  67] = rx_phy_postflop_0 [  68];
  assign rx_packet_data      [  68] = rx_phy_postflop_0 [  69];
  assign rx_packet_data      [  69] = rx_phy_postflop_0 [  70];
  assign rx_packet_data      [  70] = rx_phy_postflop_0 [  71];
  assign rx_packet_data      [  71] = rx_phy_postflop_0 [  72];
  assign rx_packet_data      [  72] = rx_phy_postflop_0 [  73];
  assign rx_packet_data      [  73] = rx_phy_postflop_0 [  74];
  assign rx_packet_data      [  74] = rx_phy_postflop_0 [  75];
  assign rx_packet_data      [  75] = rx_phy_postflop_0 [  76];
  assign rx_packet_data      [  76] = rx_phy_postflop_0 [  77];
  assign rx_packet_data      [  77] = rx_phy_postflop_0 [  78];
//       MARKER                     = rx_phy_postflop_0 [  79]
  assign rx_packet_data      [  78] = rx_phy_postflop_0 [  80];
  assign rx_packet_data      [  79] = rx_phy_postflop_0 [  81];
  assign rx_packet_data      [  80] = rx_phy_postflop_0 [  82];
  assign rx_packet_data      [  81] = rx_phy_postflop_0 [  83];
  assign rx_packet_data      [  82] = rx_phy_postflop_0 [  84];
  assign rx_packet_data      [  83] = rx_phy_postflop_0 [  85];
  assign rx_packet_data      [  84] = rx_phy_postflop_0 [  86];
  assign rx_packet_data      [  85] = rx_phy_postflop_0 [  87];
  assign rx_packet_data      [  86] = rx_phy_postflop_0 [  88];
  assign rx_packet_data      [  87] = rx_phy_postflop_0 [  89];
  assign rx_packet_data      [  88] = rx_phy_postflop_0 [  90];
  assign rx_packet_data      [  89] = rx_phy_postflop_0 [  91];
  assign rx_packet_data      [  90] = rx_phy_postflop_0 [  92];
  assign rx_packet_data      [  91] = rx_phy_postflop_0 [  93];
  assign rx_packet_data      [  92] = rx_phy_postflop_0 [  94];
  assign rx_packet_data      [  93] = rx_phy_postflop_0 [  95];
  assign rx_packet_data      [  94] = rx_phy_postflop_0 [  96];
  assign rx_packet_data      [  95] = rx_phy_postflop_0 [  97];
  assign rx_packet_data      [  96] = rx_phy_postflop_0 [  98];
  assign rx_packet_data      [  97] = rx_phy_postflop_0 [  99];
  assign rx_packet_data      [  98] = rx_phy_postflop_0 [ 100];
  assign rx_packet_data      [  99] = rx_phy_postflop_0 [ 101];
  assign rx_packet_data      [ 100] = rx_phy_postflop_0 [ 102];
  assign rx_packet_data      [ 101] = rx_phy_postflop_0 [ 103];
  assign rx_packet_data      [ 102] = rx_phy_postflop_0 [ 104];
  assign rx_packet_data      [ 103] = rx_phy_postflop_0 [ 105];
  assign rx_packet_data      [ 104] = rx_phy_postflop_0 [ 106];
  assign rx_packet_data      [ 105] = rx_phy_postflop_0 [ 107];
  assign rx_packet_data      [ 106] = rx_phy_postflop_0 [ 108];
  assign rx_packet_data      [ 107] = rx_phy_postflop_0 [ 109];
  assign rx_packet_data      [ 108] = rx_phy_postflop_0 [ 110];
  assign rx_packet_data      [ 109] = rx_phy_postflop_0 [ 111];
  assign rx_packet_data      [ 110] = rx_phy_postflop_0 [ 112];
  assign rx_packet_data      [ 111] = rx_phy_postflop_0 [ 113];
  assign rx_packet_data      [ 112] = rx_phy_postflop_0 [ 114];
  assign rx_packet_data      [ 113] = rx_phy_postflop_0 [ 115];
  assign rx_packet_data      [ 114] = rx_phy_postflop_0 [ 116];
  assign rx_packet_data      [ 115] = rx_phy_postflop_0 [ 117];
  assign rx_packet_data      [ 116] = rx_phy_postflop_0 [ 118];
  assign rx_packet_data      [ 117] = rx_phy_postflop_0 [ 119];
  assign rx_packet_data      [ 118] = rx_phy_postflop_0 [ 120];
  assign rx_packet_data      [ 119] = rx_phy_postflop_0 [ 121];
  assign rx_packet_data      [ 120] = rx_phy_postflop_0 [ 122];
  assign rx_packet_data      [ 121] = rx_phy_postflop_0 [ 123];
  assign rx_packet_data      [ 122] = rx_phy_postflop_0 [ 124];
  assign rx_packet_data      [ 123] = rx_phy_postflop_0 [ 125];
  assign rx_packet_data      [ 124] = rx_phy_postflop_0 [ 126];
  assign rx_packet_data      [ 125] = rx_phy_postflop_0 [ 127];
  assign rx_packet_data      [ 126] = rx_phy_postflop_0 [ 128];
  assign rx_packet_data      [ 127] = rx_phy_postflop_0 [ 129];
  assign rx_packet_data      [ 128] = rx_phy_postflop_0 [ 130];
  assign rx_packet_data      [ 129] = rx_phy_postflop_0 [ 131];
  assign rx_packet_data      [ 130] = rx_phy_postflop_0 [ 132];
  assign rx_packet_data      [ 131] = rx_phy_postflop_0 [ 133];
  assign rx_packet_data      [ 132] = rx_phy_postflop_0 [ 134];
  assign rx_packet_data      [ 133] = rx_phy_postflop_0 [ 135];
  assign rx_packet_data      [ 134] = rx_phy_postflop_0 [ 136];
  assign rx_packet_data      [ 135] = rx_phy_postflop_0 [ 137];
  assign rx_packet_data      [ 136] = rx_phy_postflop_0 [ 138];
  assign rx_packet_data      [ 137] = rx_phy_postflop_0 [ 139];
  assign rx_packet_data      [ 138] = rx_phy_postflop_0 [ 140];
  assign rx_packet_data      [ 139] = rx_phy_postflop_0 [ 141];
  assign rx_packet_data      [ 140] = rx_phy_postflop_0 [ 142];
  assign rx_packet_data      [ 141] = rx_phy_postflop_0 [ 143];
  assign rx_packet_data      [ 142] = rx_phy_postflop_0 [ 144];
  assign rx_packet_data      [ 143] = rx_phy_postflop_0 [ 145];
  assign rx_packet_data      [ 144] = rx_phy_postflop_0 [ 146];
  assign rx_packet_data      [ 145] = rx_phy_postflop_0 [ 147];
  assign rx_packet_data      [ 146] = rx_phy_postflop_0 [ 148];
  assign rx_packet_data      [ 147] = rx_phy_postflop_0 [ 149];
  assign rx_packet_data      [ 148] = rx_phy_postflop_0 [ 150];
  assign rx_packet_data      [ 149] = rx_phy_postflop_0 [ 151];
  assign rx_packet_data      [ 150] = rx_phy_postflop_0 [ 152];
  assign rx_packet_data      [ 151] = rx_phy_postflop_0 [ 153];
  assign rx_packet_data      [ 152] = rx_phy_postflop_0 [ 154];
  assign rx_packet_data      [ 153] = rx_phy_postflop_0 [ 155];
  assign rx_ar_credit               = rx_phy_postflop_0 [ 156];
  assign rx_aw_credit               = rx_phy_postflop_0 [ 157];
  assign rx_w_credit                = rx_phy_postflop_0 [ 158];
//       MARKER                     = rx_phy_postflop_0 [ 159]

// RX Section
//////////////////////////////////////////////////////////////////


endmodule
