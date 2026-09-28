# FPGA Image Convolution (Edge Detection) — MATLAB + Verilog

A hardware image-processing pipeline that applies a 3×3 convolution kernel (horizontal edge / Sobel-type filter) to a grayscale image on FPGA, using MATLAB for image ⇄ text conversion and Verilog for the actual convolution hardware.

## Pipeline overview

```
 [Source2.jpg]
      │
      ▼
 MATLAB (image_to_text.m)
  - convert to grayscale
  - resize to 750×750
  - flatten to pixel stream
      │
      ▼
 image_Input.txt  (one pixel value 0–255 per line)
      │
      ▼
 Verilog Testbench (tb_Histogram_image.v)
  - feeds pixels into the DUT, synchronized with its handshake
      │
      ▼
 Histogram_image.v  (DUT — convolution core + dual BRAM line buffers)
      │
      ▼
 image_Output.txt  (filtered pixel stream)
      │
      ▼
 MATLAB (text_to_image.m)
  - reshape stream back into a 750×750 image
  - save as input_image.png
      │
      ▼
 [Output image]
```

## Convolution kernel

The applied filter is a horizontal-difference / vertical-edge detector:

```
        -1   0   1
1/3  ×  -1   0   1
        -1   0   1
```

For every interior pixel, the hardware sums the right column of the 3×3 neighborhood, sums the left column, takes the (absolute) difference, and divides by 3:

```
avg = |(right_sum) - (left_sum)| / 3
right_sum = w02 + w12 + w22
left_sum  = w00 + w10 + w20
```

This highlights vertical edges (strong horizontal intensity gradients) in the image.

## 1. MATLAB — image to pixel stream

**File:** `image_to_text.m` (reads `Source2.jpg`, writes `image_Input.txt`)

- Loads the source image; converts to grayscale if it's RGB.
- Resizes to **750×750**.
- Flattens the image row-major (`reshape(img.', [], 1)`) into a column vector.
- Writes one pixel value (0–255) per line to `image_Input.txt`.

## 2. Verilog — convolution hardware

**File:** `Histogram_image.v`

**Module:** `Histogram_image #(W = 750, H = 750)`

| Port | Direction | Width | Description |
|---|---|---|---|
| `clk` | in | 1 | Clock |
| `rst` | in | 1 | Synchronous reset |
| `in_valid` | in | 1 | Pixel input strobe |
| `data_in` | in | 8 | Incoming pixel value |
| `data_out` | out | 8 | Filtered pixel value |
| `out_rdy` | out | 1 | Output valid strobe |

### Architecture

- **Dual ping-pong line buffers** (`RAM1 MyRam1`, `RAM1 MyRam2`) — generated FPGA Block RAM IP cores (single-port, `W`-deep, 8-bit wide). While one buffer is being written with the current row, the other supplies the previous row's pixels for the convolution window, and the two swap roles (`ping` signal) at the end of every row.
- **3×3 sliding window** (`w00`…`w22`) shifted in every clock as new pixels arrive from `data_in` and from the two row buffers (`px_y1`, `px_y2`).
- **8-state FSM** (`S_IDLE → S_READ → S_SHIFT → S_CALC → S_PAUSE → S_PAUSE2 → S_WRITE → S_ADV`) sequences: reading the two reference rows, shifting the window, computing the kernel sum, producing the output pixel, writing the current pixel into the active line buffer, and advancing the `(x, y)` pixel counters.
- Border pixels (first/last row or column) are passed through without the interior-only convolution logic (`inner_valid` marks the valid interior region).

> **BRAM IP note:** `RAM1` is a vendor-generated Block RAM IP core (e.g. Xilinx Block Memory Generator / Vivado IP Catalog), not written from scratch — regenerate it from the IP catalog for your target device if porting this project.

## 3. Testbench

**File:** `tb_Histogram_image.v`

- Instantiates `Histogram_image` with `W = H = 750`.
- Opens `image_Input.txt` for reading and `image_Output.txt` for writing.
- Holds `rst` high for 5 clock cycles, then releases it.
- Feeds pixels one at a time from the input file, gated by the DUT's own `we1`/`we2` write-enable signals (i.e. the testbench waits for the DUT to signal it's ready for the next pixel rather than streaming on a fixed schedule).
- Captures every pixel where `out_rdy` is asserted and appends it to `image_Output.txt`.
- After all `W × H` pixels have been sent, waits an additional 500 cycles to let the pipeline flush, then closes both files and ends the simulation.

## 4. MATLAB — pixel stream back to image

**File:** `text_to_image.m`

- Reads all values from `image_Output.txt` via `dlmread`.
- Reshapes the first `W×H` values into a `750×750` matrix (transposed to restore row/column order).
- Casts to `uint8`, displays the result, and saves it as `input_image.png`.

## Before / After

| Input (`Source2.jpg`, grayscale, 750×750) | Output (`input_image.png`, after convolution) |
|---|---|
| _add image here_ | _add image here_ |

## Simulation

1. Run `image_to_text.m` in MATLAB to generate `image_Input.txt` from your source image.
2. Simulate `tb_Histogram_image.v` (instantiating `Histogram_image.v` and the `RAM1` BRAM IP) in your simulator/Vivado — this produces `image_Output.txt`.
3. Run `text_to_image.m` in MATLAB to reconstruct and view the filtered output image.

## Possible extensions

- Parameterize the kernel coefficients instead of hardcoding the `/3` divide and fixed weights.
- Add support for color images (run the pipeline per channel).
- Replace the fixed 8-state-per-pixel FSM with a fully pipelined datapath for higher throughput.

## License

Add a license of your choice (MIT/Apache-2.0/etc.) if you intend to make this repository public.
