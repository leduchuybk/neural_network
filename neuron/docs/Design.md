# Design

## Overview

Design implements operation of a sigmoid/relu neuron. Each input values will be multiplied with its predefined weighted value which is stored in Block RAM. Sum of those multiplication will be added with a predefined bias. This result will be passed to a sigmoid function or relu function to obtain the final result of neuron: $$S(x) = \frac{1}{1 + e^{-x}}$$
or $$f(x) = \max(0, x)$$

![image!](sigmoid_neuron.png)

## Inputs/Outputs

|Signal name|Direction|Bit width|Description|
|---|---|---|---|
|`clk`|Input|1 Bit|Input clock|
|`rstn`|Input|1 Bit|Asynchronous active low reset|
|`mInput`|Input|DataWidth|Input for sigmoid neuron. Each value of input is represetend in a format of sign magnitude.|
|`mInputValid`|Input|1 Bit|Signal notifies the avaibility of minput|
|`mWeight`|Input|32 Bits|Weighted value of input. Value of weight could be initially stored in Block RAM or be written from outside. Each value of weight is represetend in a format of sign magnitude.|
|`mWeightValid`|Input|1 Bit|Signal notifies the avaibility of mweight|
|`mBias`|Input|32 Bits|Bias value of neuron. Value of bias could be initially stored in Block RAM or be written from outside. Value of bias is represetend in a format of sign magnitude.|
|`mBiasValid`|Input|1 Bit|Signal notifies the avaibility of mBias|
|`config_layer_num`|Input|32 Bits|-|
|`config_neuron_num`|Input|32 Bits|-|
|`mOutput`|Output|DataWidth|Result of signmoid neuron|
|`mOutputValid`|Output|1 Bit|Signal notifies the avaibility of mOutput|

## Parameters

|Name|Default value|Description|
|---|---|---|
|`layerNo`|0|The neuron belongs to which layer.|
|`neuronNo`|0|The neuron number in layer.|
|`numWeight`|784|Size of Weight memory|
|`dataWidth`|16|Bit width of input and output of this neurons|
|`sigmoidSize`|5|Bit width of result of sigmoid function|
|`weightIntWidth`|1|The number of bits used for integer part of weight including the sign bit. For example, when defining 4 for weightIntWidth, 1 bit out of 16 bits used for input and output of this neurons is used for sign and the other 3 bits are used for magnitude.|
|`actType`|relu|Activation function for layer 3. It could be relu or sigmoid|
|`biasFile`|-|Initialized bias value|
|`weightFile`|-|Initialized weight value|

## Detail design

As mentioned in section [Inputs/Outputs](#L10), there are 3 main interfaces for input value, weight value and output value. Each interface has value signal and its valid signal.

When weight value is not initialized at the beginning, it could be written into Weight Memory through this interface. Size of this memory is defined by parameter `numWeight`. Weight Memory is implemented as a Block RAM due to its big size: 2^`dataWidth`*`numWeight`.

After that, every time there is an input going into module, its respective weight value `w_out` is read from Weight Memory. Controller will send a pulse `enb0` to enable multiplier between `w_out` and 1 clock cycle delay value of `mInput`. This is a signed multiplication.

In the next cycle, `enb1` will be HIGH to enable addition between `comboAdd` and `mul`. There is a chance of overflow computation. It happens when:

- `mul` and `comboAdd` are negative but the result between them is postive.
- `mul` and `comboAdd` are positive but the result between them is negative.

Multiplication between weight and input will be added to sum untill the last `numWeight`. At this last value of input, `enb2` will be HIGH in one clock cycle to enable addition between `bias` and `comboAdd` to obtain `sum`. Then, `sum` will be pass to LUT `sigmoid ROM` to get `mOutput` and at the same clock cycle, `mOutputValid` will be HIGH to notify valid of the Output signal.

<img src="design.drawio.png" alt="design"> <!-- markdownlint-disable-line MD033 -->

<img src="waveform.drawio.png" alt="waveform"> <!-- markdownlint-disable-line MD033 -->

## RTL Simulation

In this RTL simulation, we drive `mInput` signal with fixed point number representation of 16-bit data width (2 bits for integer part). We expect `mOutput` has the same representation. Range value of this representation is from `-2.0` (0x8000) to `1.999` (0x7FFF). Meanwhile, bias value has fixed point number represetation of 32-bit data width (4 bits for integer part). Range value of this representation is from `-8.0` (0x8000) to `7.999` (0x7FFF). This difference is due to the mismatch of data representation in sum between `comboAdd` and `bias`.

|Signal|Data Width|Integer Width|Denotion|
|---|---|---|---|
|`mInput`|16|2|Q2.14|
|`mWeight`|16|2|Q2.14|
|`mBias`|16|4|Q4.12|
|`mul`|32|4|Q4.28|
|`comboAdd`|32|4|Q4.28|
|`sum`|32|4|Q4.28|
|`mOutput`|16|2|Q4.12|

For simplicity, we create test for 2 cases:

- Activation function is relu function:

  There will be 10 values of `mInput`, which is equal to `+0.01`. Their weight value will be `+1.0` while bias value is equal to `+0.01`. Because of above setup, our expected `mOutput` will be `+0.11`.

- Activation function is sigmoid function:
  There will be 10 values of `mInput`, which is equal to `0.00`. Their weight value will be `+1.0` while bias value is equal to `+0.01`. Because of above setup, our expected `mOutput` will be `+0.5`.

Here are simulation result in two cases:

- Activation function is relu function:

```bash
[145000] mul = 0x00290000 (0.010010)
[155000] comboAdd = 0x00290000 (0.010010)
[165000] mul = 0x00290000 (0.010010)
[175000] comboAdd = 0x00520000 (0.020020)
[185000] mul = 0x00290000 (0.010010)
[195000] comboAdd = 0x007b0000 (0.030029)
[205000] mul = 0x00290000 (0.010010)
[215000] comboAdd = 0x00a40000 (0.040039)
[225000] mul = 0x00290000 (0.010010)
[235000] comboAdd = 0x00cd0000 (0.050049)
[245000] mul = 0x00290000 (0.010010)
[255000] comboAdd = 0x00f60000 (0.060059)
[265000] mul = 0x00290000 (0.010010)
[275000] comboAdd = 0x011f0000 (0.070068)
[285000] mul = 0x00290000 (0.010010)
[295000] comboAdd = 0x01480000 (0.080078)
[305000] mul = 0x00290000 (0.010010)
[315000] comboAdd = 0x01710000 (0.090088)
[325000] mul = 0x00290000 (0.010010)
[335000] comboAdd = 0x019a0000 (0.100098)
bias = 0x00290000 (0.010010)
[345000] Sum = 0x01c30000 (0.110107)
[355000] mOutput = 0x070c (0.110107)
```

- Activation function is sigmoid function:

```bash
[145000] mul = 0x00000000 (0.000000)
[155000] comboAdd = 0x00000000 (0.000000)
[165000] mul = 0x00000000 (0.000000)
[175000] comboAdd = 0x00000000 (0.000000)
[185000] mul = 0x00000000 (0.000000)
[195000] comboAdd = 0x00000000 (0.000000)
[205000] mul = 0x00000000 (0.000000)
[215000] comboAdd = 0x00000000 (0.000000)
[225000] mul = 0x00000000 (0.000000)
[235000] comboAdd = 0x00000000 (0.000000)
[245000] mul = 0x00000000 (0.000000)
[255000] comboAdd = 0x00000000 (0.000000)
[265000] mul = 0x00000000 (0.000000)
[275000] comboAdd = 0x00000000 (0.000000)
[285000] mul = 0x00000000 (0.000000)
[295000] comboAdd = 0x00000000 (0.000000)
[305000] mul = 0x00000000 (0.000000)
[315000] comboAdd = 0x00000000 (0.000000)
[325000] mul = 0x00000000 (0.000000)
[335000] comboAdd = 0x00000000 (0.000000)
bias = 0x00290000 (0.010010)
[345000] Sum = 0x00290000 (0.010010)
[355000] mOutput = 0x2000 (0.500000)
```
