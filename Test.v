`timescale 1ns/1ps

module tb_Histogram_image;

  localparam integer W = 750;
  localparam integer H = 750;

  reg         clk;
  reg         rst;
  reg         in_valid;
  reg  [7:0]  data_in;
  wire [7:0]  data_out;
  wire        out_rdy;

  integer in_fd;
  integer out_fd;

  integer pix;
  integer ok;

  integer sent_pixels;
  integer total_pixels;

  reg feed_next;

  Histogram_image #(.W(W), .H(H)) My_Module (
    .clk      (clk),
    .rst      (rst),
    .in_valid (in_valid),
    .data_in  (data_in),
    .data_out (data_out),
    .out_rdy  (out_rdy)
  );

  // clock
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // init + open files + reset
  initial begin
    rst        = 1'b1;
    in_valid   = 1'b0;
    data_in    = 8'd0;

    sent_pixels  = 0;
    total_pixels = W * H; 

    feed_next = 1'b0;

    in_fd = $fopen("image_Input.txt", "r");
    if (in_fd == 0) begin
      $display("ERROR: cannot open input file Ring_Source.txt");
      $finish;
    end

    out_fd = $fopen("image_Output.txt", "w");
    if (out_fd == 0) begin
      $display("ERROR: cannot open output file Ring_Output.txt");
      $finish;
    end

    repeat (5) @(posedge clk);
    rst = 1'b0;

    feed_next = 1'b1;
  end


  always @(posedge clk) begin
    if (rst) begin
      in_valid    <= 1'b0;
      data_in     <= 8'd0;
      sent_pixels <= 0;
      feed_next   <= 1'b0;
    end else begin

      in_valid <= 1'b0;

      if (My_Module.we1 || My_Module.we2) begin
        feed_next <= 1'b1;
      end

		if (feed_next && (sent_pixels < total_pixels)) begin
			if (!$feof(in_fd)) begin
				ok = $fscanf(in_fd, "%d\n", pix);
				if (ok == 1)
					data_in <= pix[7:0];
				else
					data_in <= 8'd0;
			end else begin
				data_in <= 8'd0;
			end

			in_valid    <= 1'b1;
			sent_pixels <= sent_pixels + 1;
			feed_next   <= 1'b0;
		end else begin
			in_valid <= 1'b0;
		end

      if (sent_pixels >= total_pixels) begin
        in_valid <= 1'b0;
      end
    end
	end

  // ------------------------------------------------------------
  // Capture output
  // ------------------------------------------------------------
  always @(posedge clk) begin
    if (!rst && out_rdy) begin
      $fwrite(out_fd, "%0d\n", data_out);
    end
  end

  // Finish
  initial begin
    wait(!rst);
    wait(sent_pixels == total_pixels);

    repeat (500) @(posedge clk);

    $fclose(in_fd);
    $fclose(out_fd);
    $display("DONE. Sent %0d pixels. Output written to Ring_Output.txt", total_pixels);
    $finish;
  end

endmodule