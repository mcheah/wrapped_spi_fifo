`timescale 1ns / 1ps
`default_nettype none
module wrapper_tb();
reg [120*8-1:0] func;
localparam MCLKp = 5;
localparam SCLKp = 83;

reg mclk;
reg sclk;
reg sclk_en;
wire sclk_masked;
reg CSb;
reg mosi;
reg rstb;
wire valid;
wire miso;
reg [15:0]reg_out;
reg [7:0] adr;
reg [15:0] dat;
assign sclk_masked = sclk && sclk_en;
integer i;
reg [15:0] reg_in;

always begin
    #MCLKp; mclk = ~mclk;
end

always begin
    #SCLKp; sclk = ~sclk;
end

initial begin
    $dumpfile("waveform.vcd");
    $dumpvars;
    force uut.mprj.wrapped_spi_fifo_6.spi_blk.pdat = 16'd5;
    func = "main";
    mclk = 1'b0;
    sclk = 1'b0;
    sclk_en = 1'b0;
    reg_in = 16'b0;
    CSb = 1'b1;
    mosi = 1'b0;
    rstb = 1'b0;
    adr = 8'd0;
    dat = 16'd0;
    reg_out = 16'b0;
    i = 0;
    #(SCLKp*8); rstb = 1'b1;
    //empty CS
    spi_raw_write(0,0);
    //CS with 1 bit
    spi_raw_write(0,1);
    //CS with 2 bits
    spi_raw_write(0,2);
    //CS with 3 bits
    spi_raw_write(0,3);
    //CS with 4 bits
    spi_raw_write(0,4);

    spi_raw_write(32'h2000000A,4);

    spi_raw_write(32'h60001234,24);

    spi_raw_write(32'h3AAD567F,873);
    rstb = 1'b0;
    #(SCLKp*8)
    CSb = 1'b1;
    #(SCLKp*8) rstb = 1'b1;
    //write random registers
    // repeat(40) begin

    for(i=0;i<40;i=i+1) begin
        // adr = $random();
        adr = i;
        dat = $random();
        // rstb = 1'b0;
        // #(SCLKp*8) rstb = 1'b1;
        spi_reg_write(adr,dat);
        #(SCLKp*8);
    end
    //read random registers
    // repeat(40) begin
    for(i=0;i<40;i=i+1) begin
        // adr = $random();
        adr = i;
        
        spi_reg_read(adr,reg_out);
        #(SCLKp*8);
    end
    force uut.mprj.wrapped_spi_fifo_6.spi_blk.pdat.spi_blk.pdat = 16'd480;
    for(i=0;i<40;i=i+1) begin
        // adr = $random();
        adr = i;
        dat = $random();
        // rstb = 1'b0;
        // #(SCLKp*8) rstb = 1'b1;
        spi_reg_write(adr,dat);
        #(SCLKp*8);
    end
    #5000;
    $finish;
end

task spi_raw_write(
    input [31:0] datin,
    input [31:0] num_clks
);
begin
    integer i;
    reg [120*8-1:0] oldfunc;
    oldfunc = func;
    func = "spi_raw_write";
    i=0;
    rstb = 1'b0;
    CSb = 1'b1;
    #(SCLKp*8) rstb = 1'b1;
    #(SCLKp*8); CSb = 1'b0;
    repeat(4) begin
        @(negedge sclk)
        #0;
    end
    sclk_en = 1'b1;
    for(i=0;i<num_clks;i=i+1) begin
        if(i>31)
            mosi = datin[0];
        else
            mosi = datin[31-i];
        @(negedge sclk)
        #0;
    end
    sclk_en = 1'b0;
    repeat(4)
        @(negedge sclk)
        #0;
    CSb = 1'b1;
    func = oldfunc;
    #(SCLKp*8);
end
endtask

task spi_write(
    input RWb, 
    input [7:0]adr, 
    input [15:0]datin,
    output reg [26:0]datout
);
begin
    reg [31:0] count;
    reg [120*8-1:0] oldfunc;
    datout = 27'b0;
    oldfunc = func;
    func = "spi_write";
    count = 0;
    CSb = 1'b0;
    repeat(4) begin
        @(negedge sclk)
        #0;
    end

    //RWb
    @(negedge sclk)
    mosi = RWb;
    sclk_en = 1'b1;
    @(posedge sclk)
    datout[23-count] = miso;
    count = 0;

    //ADR
    repeat(8) begin
        @(negedge sclk)
        mosi = adr[7-(count-0)];
        @(posedge sclk)
        datout[23-count] = miso;
        count = count + 1;
    end

    //DAT
    repeat(16) begin
        @(negedge sclk)
        mosi = datin[15-(count-8)];
        @(posedge sclk)
        datout[23-count] = miso;
        count = count + 1;
    end
    @(negedge sclk)
    sclk_en = 1'b0;
    repeat(4) begin
        @(negedge sclk)
        #0;
    end
    CSb = 1'b1;
    func = oldfunc;
    #(SCLKp*8);
end
endtask

task spi_reg_write(
    input [7:0]adr, 
    input [15:0]datin
);
begin
    reg [26:0]temp;
    reg [120*8-1:0] oldfunc;
    oldfunc = func;
    func = "spi_reg_write";
    // spi_write(
    //     .RWb(1'b0),
    //     .PC(1'b0),
    //     .PX(1'b0),
    //     .adr(adr),
    //     .dat(dat),
    //     .datout()
    // );
    // spi_write(.RWb(1'b0),.adr(adr), .dat(dat), .datout(reg_out) );
    spi_write((1'b0), (adr), (datin), (temp) );
    func = oldfunc;
    #(SCLKp*8);
end
endtask

task spi_reg_read(
    input [7:0] adr,
    output[15:0]datout
);
begin
    reg [10:0]temp;
    reg [120*8-1:0] oldfunc;
    temp = 11'b0;
    oldfunc = func;
    func = "spi_reg_read";
    // spi_write(
    //     .RWb(1'b1),
    //     .adr(adr),
    //     .dat(16'd0),
    //     .datout(datout)
    // );
    spi_write(
        (1'b1),
        (adr),
        (16'd0),
        ({temp,datout})
    );
    func = oldfunc;
    #(SCLKp*8);
end
endtask

caravel uut (
    .vddio    (VDD3V3),
    .vssio    (VSS),
    .vdda     (VDD3V3),
    .vssa     (VSS),
    .vccd     (VDD1V8),
    .vssd     (VSS),
    .vdda1    (USER_VDD3V3),
    .vdda2    (USER_VDD3V3),
    .vssa1    (VSS),
    .vssa2    (VSS),
    .vccd1    (USER_VDD1V8),
    .vccd2    (USER_VDD1V8),
    .vssd1    (VSS),
    .vssd2    (VSS),
    .clock    (clk),
    .gpio     (gpio),
    .mprj_io  ({22'b0,
    1'b0,sclk_en,1'b1,1'b1,
    rstb, mosi, sclk_masked, CSb,
    8'b0}),
    .flash_csb(flash_csb),
    .flash_clk(flash_clk),
    .flash_io0(flash_io0),
    .flash_io1(flash_io1),
    .resetb   (rstb)
);

spiflash #(
    // change the hex file to match your project
    .FILENAME("project.hex")
) spiflash (
    .csb(flash_csb),
    .clk(flash_clk),
    .io0(flash_io0),
    .io1(flash_io1),
    .io2(),         // not used
    .io3()          // not used
);



endmodule
`default_nettype wire