module top(
  input  logic CK,      //システムクロック
  input  logic RB,      //リセット信号
  input  logic PSW,      //プッシュスイッチ
  output logic [7:0]LED,      //LED
  output logic [7:0]SEG_0,  //７セグA出力パターン
  output logic [7:0]SEG_1,    //７セグB出力パターン
  output logic BZ
);

  logic [7:0]  ram_if_data_read ; // Input feature RAM 用の読み出しデータ配線
  logic [9:0]  ram_if_addr      ; // Input feature RAM 用のアドレス配線

  logic [7:0]  rom_l1_data_read ; // L1層重み係数 ROM 用の読み出しデータ配線
  logic [13:0] rom_l1_addr      ; // L1層重み係数 ROM 用のアドレス配線

  logic [7:0]  rom_l1_data_read2 ; // 追加
  logic [13:0] rom_l1_addr2; // 追加
  logic [7:0]  ram_if_data_read2;
  logic [9:0]  ram_if_addr2;

  logic [7:0]  ram_l1_data_read ; // L1層 結果記憶 RAM 用の読み出しデータ配線
  logic [4:0]  ram_l1_addr      ; // L1層 結果記憶 RAM 用のアドレス配線

  logic [7:0]  rom_l2_data_read ; // L2層重み係数 ROM 用の読み出しデータ配線
  logic [7:0]  rom_l2_addr      ; // L2層重み係数 ROM 用のアドレス配線

  assign BZ = (&ram_if_data_read) | (&rom_l1_data_read) | (&ram_l1_data_read) | (&rom_l2_data_read);
  // for debug

  // 3層パーセプトロン
  mlp_main mlp_main(
    .CK(CK),
    .RB(RB),
    .EN_I(~PSW),
    .RAM_IF_READ_2 (ram_if_data_read2), //
    .RAM_IF_READ_I (ram_if_data_read),
    .RAM_IF_ADDR_2 (ram_if_addr2), // 
    .RAM_IF_ADDR_O (ram_if_addr     ),
        .ROM_L1_READ_2(rom_l1_data_read2), // 追加
    .ROM_L1_READ_I (rom_l1_data_read),
        .ROM_L1_ADDR_2(rom_l1_addr2), // 追加
    .ROM_L1_ADDR_O (rom_l1_addr     ),
    .ROM_L2_READ_I (rom_l2_data_read),
    .ROM_L2_ADDR_O (rom_l2_addr     ),
	 .LED (LED)
  );

  // Input feature メモリ
  ram_if  ram_if_inst (
    .address_a ( ram_if_addr      ),
    .address_b ( ram_if_addr2     ), // not used add
    .clock     ( CK               ),
    .data_a    ( 8'h0             ), // only readout in this sample
    .data_b    ( 8'h0             ), // not used
    .wren_a    ( 1'b0             ), // only readout in this sample
    .wren_b    ( 1'b0             ), // not used
    .q_a       ( ram_if_data_read ),
    .q_b       ( ram_if_data_read2) // not used add
  );

  // L1層の重み係数
  rom_l1  rom_l1_inst (
    .address_a ( rom_l1_addr      ),
    .address_b ( rom_l1_addr2     ), // 追加
    .clock     ( CK               ),
    .q_a       ( rom_l1_data_read ),
    .q_b       ( rom_l1_data_read2)  // 追加
  );

  // L2層の重み係数
  rom_l2  rom_l2_inst (
    .address_a ( rom_l2_addr      ),
    .address_b ( 0                ), // not used
    .clock     ( CK               ),
    .q_a       ( rom_l2_data_read ),
    .q_b       (                  )  // not used
  );


endmodule

