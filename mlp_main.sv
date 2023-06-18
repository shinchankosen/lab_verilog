module mlp_main(
  input  logic CK,
  input  logic RB,
  input  logic EN_I,
  input logic signed [7:0] RAM_IF_READ_2, ///
  input  logic signed [7:0]  RAM_IF_READ_I,
  output logic [9:0] RAM_IF_ADDR_2, //
  output logic [9:0]  RAM_IF_ADDR_O,
  input logic signed [7:0] ROM_L1_READ_2, // 追加
  input  logic signed [7:0]  ROM_L1_READ_I,
  output logic [13:0] ROM_L1_ADDR_2, // 追加
  output logic [13:0] ROM_L1_ADDR_O,
  input  logic signed [7:0]  ROM_L2_READ_I,
  output logic [7:0]  ROM_L2_ADDR_O,
  output logic [7:0] LED
);

  // ステートマシン
  logic [1:0] state_r;

  // L1層の計算を制御するカウンタ
  logic [9:0] cnt1_l1_r;
  logic [9:0] cnt1_l12_r; // 追加
  logic [4:0] cnt2_l1_r;

  // L2層の計算を制御するカウンタ
  logic [4:0] cnt1_l2_r;
  logic [4:0] cnt1_delay_l2_r; // 1クロック遅らせる
  logic [3:0] cnt2_l2_r;
  logic [3:0] cnt2_delay_l2_r; // 1クロック遅らせる
  
  logic [3:0] cnt_ans;
  // L1層の結果を記憶
  //logic signed [25:0] l1_r[15:0];
  logic signed [17:0] l1_r[15:0];
  logic signed [17:0] l1_delay_r[15:0]; // 1クロック遅らせる
  // l1_r への書き込み信号（ROMからの読み出しに1クロックかかるため、1クロック遅らせる）
  logic l1_we_r;

  // MLPの出力を記憶
  //logic signed [38:0] l2_r[9:0];
  logic signed [22:0] l2_r[15:0];
  // l2_r への書き込み信号（ROMからの読み出しに1クロックかかるため、1クロック遅らせる）
  logic l2_we_r;

  
  logic signed [22:0] l2_r_MAX = -200;
  logic signed [22:0] l2_r_ANS = 0;

  // ステートマシンの状態
  localparam STATE_INIT = 2'b00;
  localparam STATE_L1   = 2'b01;
  localparam STATE_L2   = 2'b10;
  localparam STATE_Lans = 2'b11;

  // 各層のノード数
  localparam NUM_IF     = 10'd783; // IF-1
  localparam NUM_L1     = 5'd15  ; // L1-1
  localparam NUM_L2     = 4'd9   ; // 出力層のノード数 (0からカウント)

  // このモジュールの出力
  assign RAM_IF_ADDR_O  = cnt1_l1_r;
  assign RAM_IF_ADDR_2  = cnt1_l12_r;///
  assign ROM_L1_ADDR_2  = (NUM_L1+1) * cnt1_l12_r + cnt2_l1_r;//
  assign ROM_L1_ADDR_O  = (NUM_L1+1) * cnt1_l1_r + cnt2_l1_r;
  assign ROM_L2_ADDR_O  = (NUM_L2+1) * cnt1_l2_r + cnt2_l2_r;

  // ステートマシン
  always_ff @(posedge CK or negedge RB) begin
    if(!RB) begin
      state_r <= STATE_INIT;
    end else case(state_r)
      STATE_INIT: begin
        if(EN_I) begin
          state_r <= STATE_L1;
        end
      end

      STATE_L1: begin
      // NUM_IF/2にする 追加箇所
        if((cnt1_l1_r == NUM_IF / 2) && (cnt2_l1_r == NUM_L1)) begin
          state_r <= STATE_L2;
        end
      end

      STATE_L2: begin
        if((cnt1_l2_r == NUM_L1) && (cnt2_l2_r == NUM_L2)) begin
          state_r <= STATE_Lans;
        end
      end
		
		STATE_Lans: begin
        if(cnt_ans == NUM_L2) begin
          state_r <= STATE_INIT;
        end
      end

    endcase
  end

  // L1 内側のループ
  always_ff @(posedge CK or negedge RB) begin
    if(!RB) begin
      cnt1_l1_r <= 10'd0;
      cnt1_l12_r <= 10'd392;
    end else case(state_r)

      STATE_L1: begin // いろいろ追加
        if(cnt1_l1_r == NUM_IF / 2) begin
          cnt1_l1_r <= 10'd000;
          cnt1_l12_r <= 10'd392;
        end else begin
          cnt1_l1_r <= cnt1_l1_r + 10'd1;
          cnt1_l12_r <= cnt1_l12_r + 10'd1;
        end
      end

      default: begin
        cnt1_l1_r <= 10'd0;
        cnt1_l12_r <= 10'd392;
      end

    endcase
  end

  // L1 外側のループ
  always_ff @(posedge CK or negedge RB) begin
    if(!RB) begin
      cnt2_l1_r <= 5'd0;
    end else case(state_r)

      STATE_L1: begin
        if(cnt1_l1_r == NUM_IF / 2) begin // NUM_IF/2にしておく 追加箇所
          cnt2_l1_r <= cnt2_l1_r + 5'd1;
        end
      end

      default: begin
        cnt2_l1_r <= 5'd0;
      end

    endcase
  end

  // L2 内側のループ
  always_ff @(posedge CK or negedge RB) begin
    if(!RB) begin
      cnt1_l2_r <= 4'd0;
    end else case(state_r)

      STATE_L2: begin
        if(cnt1_l2_r == NUM_L1) begin
          cnt1_l2_r <= 5'd0;
        end else begin
          cnt1_l2_r <= cnt1_l2_r + 5'd1;
        end
      end

      default: begin
        cnt1_l2_r <= 5'd0;
      end

    endcase
  end

  // L2 外側のループ
  always_ff @(posedge CK or negedge RB) begin
    if(!RB) begin
      cnt2_l2_r <= 4'd0;
    end else case(state_r)

      STATE_L2: begin
        if(cnt1_l2_r == NUM_L1) begin
          cnt2_l2_r <= cnt2_l2_r + 4'd1;
        end
      end

      default: begin
        cnt2_l2_r <= 4'd0;
      end

    endcase
  end
  
  // 追加 loop
  always_ff @(posedge CK or negedge RB) begin
    if(!RB) begin
      cnt_ans <= 4'd0;
    end else case(state_r)
	   STATE_Lans: begin
        if(cnt_ans == NUM_L2) begin
          cnt_ans <= 4'd0;
        end else begin
          cnt_ans <= cnt_ans + 4'd1;
        end
      end
		
      default: begin
        cnt_ans <= 4'd0;
      end

    endcase
  end

  // L1の結果を計算
  // logic [25:0] l1_r[16:0];
  always_ff @(posedge CK) begin
    if(state_r==STATE_INIT) begin
      l1_r[0]  <= $signed(8'd186) ;
      l1_r[1]  <= $signed(8'd47 ) ;
      l1_r[2]  <= $signed(8'd210) ;
      l1_r[3]  <= $signed(8'd32 ) ;
      l1_r[4]  <= $signed(8'd41 ) ;
      l1_r[5]  <= $signed(8'd221) ;
      l1_r[6]  <= $signed(8'd254) ;
      l1_r[7]  <= $signed(8'd207) ;
      l1_r[8]  <= $signed(8'd65 ) ;
      l1_r[9]  <= $signed(8'd44 ) ;
      l1_r[10] <= $signed(8'd236) ;
      l1_r[11] <= $signed(8'd34 ) ;
      l1_r[12] <= $signed(8'd19 ) ;
      l1_r[13] <= $signed(8'd127) ;
      l1_r[14] <= $signed(8'd86 ) ;
      l1_r[15] <= $signed(8'd63 ) ;
    end else if(l1_we_r == 1'b1) begin
     // 追加
      l1_r[cnt2_l1_r] <= ((($signed({1'b0,RAM_IF_READ_I}) * $signed(ROM_L1_READ_I))) >>> 8) + ((($signed({1'b0,RAM_IF_READ_2}) * $signed(ROM_L1_READ_2))) >>> 8) + $signed(l1_r[cnt2_l1_r]);
    end
  end

  always_ff @(posedge CK or negedge RB) begin
    if(!RB) begin
       l1_we_r <= 1'b0;
    end else if(state_r==STATE_L1) begin
       l1_we_r <= 1'b1;
    end else begin
       l1_we_r <= 1'b1;
    end
  end


  // L2の結果を計算
  // logic [25:0] l1_r[16:0];
  always_ff @(posedge CK) begin
    if(state_r==STATE_INIT) begin
      l2_r[0]  <= $signed(8'd129);
      l2_r[1]  <= $signed(8'd39 );
      l2_r[2]  <= $signed(8'd233);
      l2_r[3]  <= $signed(8'd248);
      l2_r[4]  <= $signed(8'd94 );
      l2_r[5]  <= $signed(8'd27 );
      l2_r[6]  <= $signed(8'd241);
      l2_r[7]  <= $signed(8'd11 );
      l2_r[8]  <= $signed(8'd230);
      l2_r[9]  <= $signed(8'd9  );
    end else if(l2_we_r == 1'b1) begin
      l2_r[cnt2_delay_l2_r] <= ((ROM_L2_READ_I * $signed(l1_delay_r[cnt1_delay_l2_r])) >>> 8) + $signed(l2_r[cnt2_delay_l2_r]);
    end
  end
  
  // LEDと最大値(追加箇所)
  always_ff @(posedge CK) begin
    if(state_r == STATE_Lans && l2_r_MAX < l2_r[cnt_ans]) begin 
	   l2_r_MAX <= l2_r[cnt_ans];
		l2_r_ANS <= cnt_ans;
		LED <= cnt_ans;
    end
  end

  // 1クロック遅らせる（RAMやROMが同期読み出しのため）
  // cnt1_delay_l2_r; // 1クロック遅らせる
  // cnt2_delay_l2_r; // 1クロック遅らせる
  always_ff @(posedge CK or negedge RB) begin
    l1_delay_r[0]  <= $signed(l1_r[0]);
    l1_delay_r[1]  <= $signed(l1_r[1]);
    l1_delay_r[2]  <= $signed(l1_r[2]);
    l1_delay_r[3]  <= $signed(l1_r[3]);
    l1_delay_r[4]  <= $signed(l1_r[4]);
    l1_delay_r[5]  <= $signed(l1_r[5]);
    l1_delay_r[6]  <= $signed(l1_r[6]);
    l1_delay_r[7]  <= $signed(l1_r[7]);
    l1_delay_r[8]  <= $signed(l1_r[8]);
    l1_delay_r[9]  <= $signed(l1_r[9]);
    l1_delay_r[10] <= $signed(l1_r[10]);
    l1_delay_r[11] <= $signed(l1_r[11]);
    l1_delay_r[12] <= $signed(l1_r[12]);
    l1_delay_r[13] <= $signed(l1_r[13]);
    l1_delay_r[14] <= $signed(l1_r[14]);
    l1_delay_r[15] <= $signed(l1_r[15]);
    cnt1_delay_l2_r <= cnt1_l2_r;
    cnt2_delay_l2_r <= cnt2_l2_r;
  end

  // l2_r
  always_ff @(posedge CK or negedge RB) begin
    if(!RB) begin
       l2_we_r <= 1'b0;
    end else if(state_r==STATE_L2 &&  ($signed(l1_r[cnt1_l2_r] > $signed(0)))) begin
       l2_we_r <= 1'b1;
    end else begin
       l2_we_r <= 1'b0;
    end
  end
  

endmodule

