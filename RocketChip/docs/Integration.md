# Integrating a Hardware Accelerator into Rocket SoC (Chipyard)

A step-by-step beginner's guide using MNIST-CNN as a complete working example.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Prerequisites](#2-prerequisites)
3. [Architecture](#3-architecture)
4. [File Structure](#4-file-structure)
5. [Step 1: MNISTAccelerator.scala — The Accelerator Module](#step-1-mnistacceleratorscala--the-accelerator-module)
   - [5.1 Imports](#51-imports)
   - [5.2 IO Bundle](#52-io-bundle)
   - [5.3 BlackBox Wrapper](#53-blackbox-wrapper)
   - [5.4 Parameter Case Class](#54-parameter-case-class)
   - [5.5 LazyModule Device (MNISTCNNDevice)](#55-lazymodule-device-mnistcnndevice)
   - [5.6 Module Implementation (Inner Class)](#56-module-implementation-inner-class)
6. [Step 2: MnistFragments.scala — System Integration](#step-2-mnistfragmentsscala--system-integration)
   - [6.1 Configuration Key](#61-configuration-key)
   - [6.2 Configuration Fragment](#62-configuration-fragment)
   - [6.3 Integration Trait (CanHavePeriphery...)](#63-integration-trait-canhaveperiphery)
7. [Step 3: DigitalTop.scala — Mix In the Trait](#step-3-digitaltopscala--mix-in-the-trait)
8. [Step 4: RocketConfigs.scala — Create a Config Class](#step-4-rocketconfigsscala--create-a-config-class)
9. [Step 5: Add Verilog Source Files](#step-5-add-verilog-source-files)
10. [Step 6: Build and Test](#step-6-build-and-test)
11. [Common Errors and Solutions](#common-errors-and-solutions)
12. [Key Concepts Reference](#key-concepts-reference)

---

## 1. Overview

Chipyard uses a **Diplomacy**-based approach to connect hardware modules. Integrating a hardware accelerator involves four Scala files:

| File | Purpose |
|------|---------|
| `MNISTAccelerator.scala` | BlackBox wrapper, diplomatic nodes, hardware logic |
| `MnistFragments.scala` | Config key, config fragment, system integration trait |
| `DigitalTop.scala` | One-line mixin for the integration trait |
| `RocketConfigs.scala` | Top-level config class that users select at build time |

The data flow from writing code to running simulation:

```
RocketConfigs.scala          (selects which accelerator to include)
  └─> MnistFragments.scala   (wires the accelerator to buses)
        └─> MNISTAccelerator.scala  (the actual hardware)
              └─> BlackBox (your Verilog/SystemVerilog RTL)
```

---

## 2. Prerequisites

Before starting, you should understand:

- **Chisel3**: Scala-based hardware description language
- **TileLink**: RocketChip's on-chip interconnect protocol
- **AXI4/AXI Lite**: ARM's standard bus protocol (used by many IP cores)
- **Diplomacy**: RocketChip's parameter negotiation framework (LazyModule, Nodes)
- **Chipyard Config System**: How `Config` fragments compose together

Key Chipyard documentation:

- [MMIO Peripherals](https://chipyard.readthedocs.io/en/latest/Customization/MMIO-Peripherals.html)
- [DMA Devices](https://chipyard.readthedocs.io/en/latest/Customization/DMA-Devices.html)
- [Incorporating Verilog](https://chipyard.readthedocs.io/en/latest/Customization/Incorporating-Verilog-Blocks.html)

---

## 3. Architecture

The MNIST-CNN accelerator connects to the Rocket SoC through four independent paths:

```
                          ┌──────────────────────────────────┐
                          │         Rocket Core (CPU)         │
                          └───────┬──────────┬───────────────┘
                                  │          │
                          ┌───────▼──┐  ┌────▼────┐
                          │   PBUS   │  │  PLIC   │
                          │(Periph.) │  │(Interr.)│
                          └──┬────┬──┘  └────▲────┘
                   PATH 1   │    │ PATH 2    │ PATH 4
                   (AXI Lite)│    │ (MMIO)    │ (Interrupts)
                          ┌──▼────▼──────────┤────────┐
                          │    MNISTCNNDevice          │
                          │  ┌─────────────────────┐   │
                          │  │  MNISTCNNBlackBox   │   │
                          │  │  (dnn.sv)           │   │
                          │  └─────────────────────┘   │
                          │  ┌─────────────────────┐   │
                          │  │  DMA Controller     │   │
                          │  │  (FSM in Chisel)    │   │
                          │  └──────────┬──────────┘   │
                          └─────────────┼──────────────┘
                                        │ PATH 3 (DMA Master)
                                  ┌─────▼─────┐
                                  │   FBUS    │
                                  │ (Memory)  │
                                  └───────────┘
```

| Path | Direction | Protocol | Purpose |
|------|-----------|----------|---------|
| PATH 1 | CPU → Accel | TileLink → AXI4 → AXI Lite | Configure BlackBox registers |
| PATH 2 | CPU → Accel | TileLink (MMIO) | DMA control registers |
| PATH 3 | Accel → Memory | TileLink Master | DMA reads from DRAM |
| PATH 4 | Accel → CPU | Interrupt | Completion notification |

---

## 4. File Structure

```
generators/chipyard/src/main/scala/
├── accelerators/
│   └── MNISTAccelerator.scala     ← Step 1 (you create this)
├── config/
│   ├── fragments/
│   │   └── MnistFragments.scala   ← Step 2 (you create this)
│   └── RocketConfigs.scala        ← Step 4 (you add one class)
├── DigitalTop.scala               ← Step 3 (you add one line)
└── ...

generators/chipyard/src/main/resources/
└── vsrc/
    └── mnist_cnn/                 ← Step 5 (your Verilog files)
        ├── MNISTCNNBlackBox.sv
        └── layer_parameter.sv
```

---

## Step 1: MNISTAccelerator.scala — The Accelerator Module

**Location**: `generators/chipyard/src/main/scala/accelerators/MNISTAccelerator.scala`

This is the core file. It contains the BlackBox wrapper, diplomatic nodes, and all hardware logic.

### 5.1 Imports

```scala
package chipyard.accelerators

import chisel3._
import chisel3.util._
import chisel3.experimental.{IntParam, BaseModule}
import freechips.rocketchip.amba.axi4._          // AXI4 node types
import freechips.rocketchip.prci._                // ClockSinkDomain
import org.chipsalliance.cde.config.{Parameters, Field, Config}
import freechips.rocketchip.tilelink._            // TileLink nodes
import freechips.rocketchip.diplomacy._           // LazyModule, AddressSet
import freechips.rocketchip.regmapper.{HasRegMap, RegField}  // MMIO registers
import freechips.rocketchip.util._
import freechips.rocketchip.interrupts._          // IntSourceNode
```

**Key imports explained**:

- `freechips.rocketchip.prci._` — Needed for `ClockSinkDomain`, which gives your module a proper clock
- `freechips.rocketchip.interrupts._` — Needed for `IntSourceNode` to send interrupts to the PLIC
- `freechips.rocketchip.regmapper.RegField` — Needed for `tlNode.regmap(...)` to expose MMIO registers

### 5.2 IO Bundle

Define a Chisel `Bundle` that **exactly matches** your Verilog module's port list:

```scala
class MNISTCNNIO(val addrWidth: Int, val dataWidth: Int) extends Bundle {
  // Clock and reset (active-low)
  val clk   = Input(Clock())
  val rst_n = Input(Bool())

  // AXI Lite interface (matches Verilog port names exactly)
  val s_axi_awaddr  = Input(UInt(addrWidth.W))
  val s_axi_awprot  = Input(UInt(3.W))
  val s_axi_awvalid = Input(Bool())
  val s_axi_awready = Output(Bool())
  val s_axi_wdata   = Input(UInt(dataWidth.W))
  val s_axi_wstrb   = Input(UInt((dataWidth / 8).W))
  val s_axi_wvalid  = Input(Bool())
  val s_axi_wready  = Output(Bool())
  val s_axi_bresp   = Output(UInt(2.W))
  val s_axi_bvalid  = Output(Bool())
  val s_axi_bready  = Input(Bool())
  val s_axi_araddr  = Input(UInt(addrWidth.W))
  val s_axi_arprot  = Input(UInt(3.W))
  val s_axi_arvalid = Input(Bool())
  val s_axi_arready = Output(Bool())
  val s_axi_rdata   = Output(UInt(dataWidth.W))
  val s_axi_rresp   = Output(UInt(2.W))
  val s_axi_rvalid  = Output(Bool())
  val s_axi_rready  = Input(Bool())

  // AXI Stream input (for DMA data)
  val axis_in_tdata  = Input(UInt(dataWidth.W))
  val axis_in_tvalid = Input(Bool())
  val axis_in_tready = Output(Bool())

  // Interrupt output
  val intr = Output(Bool())
}
```

> ⚠️ **Critical**: Port names in the Bundle must exactly match the Verilog port names (with `io_` prefix added automatically by Chisel for BlackBox).

### 5.3 BlackBox Wrapper

Wrap your Verilog/SystemVerilog module:

```scala
class MNISTCNNBlackBox(val addrWidth: Int, val dataWidth: Int) extends BlackBox(
  Map(
    "C_S_AXI_DATA_WIDTH" -> IntParam(dataWidth),
    "C_S_AXI_ADDR_WIDTH" -> IntParam(addrWidth)
  )
) with HasBlackBoxResource with HasBlackBoxPath {

  val io = IO(new MNISTCNNIO(addrWidth, dataWidth))

  // Files from src/main/resources/ (packaged into JAR)
  addResource("/vsrc/mnist_cnn/MNISTCNNBlackBox.sv")   // Top-level wrapper
  addResource("/vsrc/mnist_cnn/layer_parameter.sv")     // Parameters include file

  // Files from filesystem (absolute paths)
  addPath(s"${System.getProperty("user.dir")}/generators/mnist-cnn/mnist/src/dnn.sv")
  addPath(s"${System.getProperty("user.dir")}/generators/mnist-cnn/mnist/src/Layer1.sv")
  // ... more files ...
}
```

**Key points**:

- `BlackBox(Map(...))` passes Verilog parameters (becomes `#(.C_S_AXI_DATA_WIDTH(32))`)
- `HasBlackBoxResource` — looks for files in `src/main/resources/` (classpath)
- `HasBlackBoxPath` — looks for files at absolute filesystem paths
- You can mix both traits to reference files from different locations
- The BlackBox class name must match the Verilog module name (e.g., `MNISTCNNBlackBox` ↔ `module MNISTCNNBlackBox`)

### 5.4 Parameter Case Class

Define parameters that can be configured from the Config system:

```scala
case class MNISTCNNParams(
  address: BigInt = 0x4000,     // Base MMIO address
  dataWidth: Int = 32,          // AXI data width
  addrWidth: Int = 32           // AXI address width
)
```

> ⚠️ **Critical**: Use `BigInt` for addresses. If the address exceeds `0x7FFFFFFF`, you must use `Long` literal suffix: `0x80004000L`. Otherwise Scala interprets it as a negative `Int`.

### 5.5 LazyModule Device (MNISTCNNDevice)

This is the Diplomacy wrapper that declares all bus connections:

```scala
class MNISTCNNDevice(params: MNISTCNNParams, beatBytes: Int)(implicit p: Parameters)
    extends ClockSinkDomain(ClockSinkParameters())(p) {

  // Device tree entry (for Linux drivers, if needed)
  val device = new SimpleDevice("mnist-cnn", Seq("chipyard,mnist-cnn"))
```

**Why `ClockSinkDomain`?** It provides a proper clock domain. The `clockNode` receives clock from PBUS, and the inner `Impl` class gets `clock`/`reset` automatically.

#### Declaring Diplomatic Nodes

Each bus connection is a **node**:

```scala
  // PATH 1: AXI4 Slave — receives configuration from CPU
  val axilNode = AXI4SlaveNode(
    Seq(AXI4SlavePortParameters(
      slaves = Seq(AXI4SlaveParameters(
        address = Seq(AddressSet(params.address, 0xFFF)),  // 4KB region
        regionType = RegionType.GET_EFFECTS,
        supportsWrite = TransferSizes(1, beatBytes),
        supportsRead = TransferSizes(1, beatBytes)
      )),
      beatBytes = beatBytes    // Must match PBUS width
    ))
  )

  // PATH 2: TileLink Register Node — exposes DMA control registers
  val tlNode = TLRegisterNode(
    address = Seq(AddressSet(params.address + 0x1000, 0xFFF)),  // 4KB at base+0x1000
    device = device,
    "dnn/control",             // Device tree path
    beatBytes = beatBytes
  )

  // PATH 3: TileLink Client (Master) — DMA reads from memory
  val dmaNode = TLClientNode(
    Seq(TLMasterPortParameters.v1(
      Seq(TLMasterParameters.v1(
        name = "mnist-cnn-dma",
        sourceId = IdRange(0, 1)  // Single outstanding request
      ))
    ))
  )

  // PATH 4: Interrupt Source — signals CPU via PLIC
  val intNode = IntSourceNode(IntSourcePortSimple(num = 2, resources = device.int))
```

**Node types summary**:

| Node | Type | Direction | Purpose |
|------|------|-----------|---------|
| `AXI4SlaveNode` | Slave | CPU → Accel | Receives AXI4 transactions |
| `TLRegisterNode` | Slave | CPU → Accel | Exposes MMIO registers |
| `TLClientNode` | Master | Accel → Memory | Issues TileLink reads |
| `IntSourceNode` | Source | Accel → CPU | Sends interrupts |

### 5.6 Module Implementation (Inner Class)

The actual hardware logic is an **inner class** extending `Impl`:

```scala
  override lazy val module = new MNISTCNNImpl
  class MNISTCNNImpl extends Impl {
    withClockAndReset(clock, reset) {
```

⚠️ **Critical Pattern**: When using `ClockSinkDomain`, you MUST:

1. Use `override lazy val module` (not `lazy val module`)
2. Extend `Impl` (not `LazyModuleImp`)
3. Wrap all hardware in `withClockAndReset(clock, reset) { ... }`

This is the same pattern used in `GCD.scala` (Chipyard's reference example).

#### Accessing Diplomatic Ports

Inside the inner class, access node ports directly (no `outer.` prefix needed):

```scala
      val (axi4, _)       = axilNode.in(0)     // AXI4 slave port
      val (mem, edge)      = dmaNode.out(0)     // TileLink master port
      val (interrupts, _)  = intNode.out(0)     // Interrupt output vector
```

**Direction rules**:

- Slave nodes → use `.in(0)` (data flows **in** to the slave)
- Master/Client nodes → use `.out(0)` (data flows **out** from the master)
- Source nodes (interrupts) → use `.out(0)` (interrupt signal flows **out**)

#### DMA FSM

A simple 4-state FSM that reads data from memory and streams it to the BlackBox:

```scala
      val s_idle :: s_request :: s_response :: s_done :: Nil = Enum(4)
      val dmaState = RegInit(s_idle)

      // TileLink GET request
      mem.a.valid := dmaState === s_request
      mem.a.bits := edge.Get(fromSource = 0.U, toAddress = dmaAddr, lgSize = 2.U)._2
      mem.d.ready := dmaState === s_response

      // State transitions
      when(dmaState === s_idle && ctrlReg(0)) {
        dmaState := s_request
        // ... setup address, count
      }
      when(dmaState === s_request && mem.a.ready) {
        dmaState := s_response
      }
      when(dmaState === s_response && mem.d.valid) {
        dmaData := mem.d.bits.data
        when(dmaCount === 1.U) { dmaState := s_done }
        .otherwise             { dmaState := s_request }
      }
```

#### MMIO Register Map

Use `tlNode.regmap(...)` to expose registers to the CPU:

```scala
      tlNode.regmap(
        0x00 -> Seq(RegField(32, ctrlReg)),            // R/W register
        0x04 -> Seq(RegField.r(32, statusReg)),        // Read-only register
        0x08 -> Seq(RegField(32, dmaAddrLowReg)),      // R/W register
        0x0C -> Seq(RegField(32, dmaAddrHighReg)),
        0x10 -> Seq(RegField(32, dmaSizeReg)),
        0x14 -> Seq(RegField.r(32, 0.U(32.W))),       // Read-only zero (reserved)
      )
```

**RegField types**:

- `RegField(width, reg)` — Read/Write register
- `RegField.r(width, signal)` — Read-only (from hardware signal or literal)
- `RegField.w(width, reg)` — Write-only

> ⚠️ **Common Error**: `RegField(32, 0.U(32.W))` creates a R/W register connected to a literal → compile error "Cannot reassign to read-only". Use `RegField.r(32, 0.U(32.W))` instead.

#### AXI4 → BlackBox Signal Mapping

Manually wire AXI4 diplomatic port signals to BlackBox IO:

```scala
      // Write Address Channel
      mnistcnn.io.s_axi_awaddr  := axi4.aw.bits.addr
      mnistcnn.io.s_axi_awvalid := axi4.aw.valid
      axi4.aw.ready             := mnistcnn.io.s_axi_awready

      // Write Data Channel
      mnistcnn.io.s_axi_wdata   := axi4.w.bits.data
      mnistcnn.io.s_axi_wstrb   := axi4.w.bits.strb
      mnistcnn.io.s_axi_wvalid  := axi4.w.valid
      axi4.w.ready              := mnistcnn.io.s_axi_wready

      // Write Response Channel
      axi4.b.valid              := mnistcnn.io.s_axi_bvalid
      axi4.b.bits.resp          := mnistcnn.io.s_axi_bresp
      axi4.b.bits.id            := 0.U        // Required: set AXI ID
      mnistcnn.io.s_axi_bready  := axi4.b.ready

      // Read Address Channel
      mnistcnn.io.s_axi_araddr  := axi4.ar.bits.addr
      mnistcnn.io.s_axi_arvalid := axi4.ar.valid
      axi4.ar.ready             := mnistcnn.io.s_axi_arready

      // Read Data Channel
      axi4.r.valid              := mnistcnn.io.s_axi_rvalid
      axi4.r.bits.data          := mnistcnn.io.s_axi_rdata
      axi4.r.bits.resp          := mnistcnn.io.s_axi_rresp
      axi4.r.bits.id            := 0.U        // Required: set AXI ID
      mnistcnn.io.s_axi_rready  := axi4.r.ready
```

> ⚠️ **Critical**: You must set `axi4.b.bits.id := 0.U` and `axi4.r.bits.id := 0.U`. AXI4 requires an ID field; AXI Lite does not have one. Forgetting this causes "sink not fully initialized" errors.

#### Interrupt Wiring

```scala
      interrupts(0) := mnistcnn.io.intr     // BlackBox hardware interrupt
      interrupts(1) := inferenceComplete     // DMA completion flag
```

Close all the braces:

```scala
    }  // end withClockAndReset
  }    // end MNISTCNNImpl
}      // end MNISTCNNDevice
```

---

## Step 2: MnistFragments.scala — System Integration

**Location**: `generators/chipyard/src/main/scala/config/fragments/MnistFragments.scala`

This file has three components: Config Key, Config Fragment, and Integration Trait.

### 6.1 Configuration Key

```scala
package chipyard.config

import org.chipsalliance.cde.config.{Field, Parameters, Config}
import freechips.rocketchip.subsystem.{PBUS, FBUS, BaseSubsystem}
import freechips.rocketchip.devices.tilelink.CanHavePeripheryPLIC
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.tilelink._
import freechips.rocketchip.amba.axi4.{AXI4Deinterleaver}
import freechips.rocketchip.prci._
import chipyard.accelerators._

// A Field that carries optional parameters
case object MNISTCNNKey extends Field[Option[MNISTCNNParams]](None)
```

**Pattern**: `Field[Option[YourParams]](None)` means "disabled by default". When a Config sets it to `Some(params)`, the peripheral is instantiated.

### 6.2 Configuration Fragment

```scala
class WithMNISTCNN(
    address: BigInt = 0x4000,
    dataWidth: Int = 32,
    addrWidth: Int = 32)
  extends Config((site, here, up) => {
  case MNISTCNNKey => Some(MNISTCNNParams(
    address = address, dataWidth = dataWidth, addrWidth = addrWidth))
})
```

This is the config fragment users compose into their configuration.

### 6.3 Integration Trait (CanHavePeriphery...)

This is where the module gets wired into the SoC bus architecture:

```scala
trait CanHavePeripheryMNISTCNN {
  this: BaseSubsystem with CanHavePeripheryPLIC =>

  private val portName = "mnist-cnn"
  private val pbus = locateTLBusWrapper(PBUS)

  val mnistcnn = p(MNISTCNNKey) match {
    case Some(params) =>
      val mnistcnnDevice = LazyModule(new MNISTCNNDevice(params, pbus.beatBytes)(p))

      // Give the module the PBUS clock
      mnistcnnDevice.clockNode := pbus.fixedClockNode
```

#### PATH 1: Configuration (TileLink → AXI4)

```scala
      pbus.coupleTo(portName + "-axil") {
        mnistcnnDevice.axilNode :=
          AXI4Deinterleaver(pbus.beatBytes) :=    // Serialize AXI4 responses
          TLToAXI4() :=                            // Convert TileLink → AXI4
          TLFragmenter(pbus.beatBytes, pbus.blockBytes, holdFirstDeny = true) :=
          TLWidthWidget(pbus.beatBytes) :=         // Match crossbar width
          _                                        // ← PBUS connection point
      }
```

**Converter chain explained** (right to left, following data flow):

```
PBUS (8 bytes, 64-bit)
  ↓ TLWidthWidget(pbus.beatBytes)     Satisfies Xbar width matching requirement
  ↓ TLFragmenter(8, 64, holdFirstDeny=true)  Breaks large TL transactions into beats
  ↓ TLToAXI4()                        Converts TileLink protocol → AXI4 protocol
  ↓ AXI4Deinterleaver(pbus.beatBytes) Ensures responses come back in order
  ↓ axilNode                          Your AXI4 slave node
```

**Why `holdFirstDeny = true`?** Required when `TLToAXI4` is downstream. AXI4 can produce denial responses that TileLink must handle correctly across fragmented beats.

**Why `TLWidthWidget`?** The PBUS crossbar requires all attached nodes to match its data width. This widget satisfies that requirement.

#### PATH 2: DMA Control (TileLink MMIO)

```scala
      pbus.coupleTo(portName + "-ctrl") {
        mnistcnnDevice.tlNode :=
          TLFragmenter(pbus.beatBytes, pbus.blockBytes) := _
      }
```

Simpler chain — no protocol conversion needed since `TLRegisterNode` speaks native TileLink.

#### PATH 3: DMA Execution (TileLink Master → Memory)

```scala
      val memBus = locateTLBusWrapper(FBUS)
      memBus.coupleFrom(portName + "-dma") { _ := mnistcnnDevice.dmaNode }
```

> Note: `coupleFrom` (not `coupleTo`) because DMA is a **master** that initiates transactions.

#### PATH 4: Interrupts → PLIC

```scala
      plicOpt.foreach { plic =>
        plic.intnode :=* mnistcnnDevice.intNode
      }
```

> Note: `:=*` (star connection) allows connecting a multi-interrupt source to the PLIC's interrupt aggregator.

Complete the match:

```scala
      Some(mnistcnnDevice)

    case None =>
      None
  }
}
```

---

## Step 3: DigitalTop.scala — Mix In the Trait

**Location**: `generators/chipyard/src/main/scala/DigitalTop.scala`

Add **one line** to the `DigitalTop` class:

```scala
class DigitalTop(implicit p: Parameters) extends ChipyardSystem
  with testchipip.tsi.CanHavePeripheryUARTTSI
  // ... existing traits ...
  with chipyard.example.CanHavePeripheryGCD
  with chipyard.config.CanHavePeripheryMNISTCNN   // ← ADD THIS LINE
  with chipyard.clocking.HasChipyardPRCI
  // ... rest of traits ...
```

> ⚠️ The trait ordering doesn't strictly matter, but by convention put your peripheral traits near other peripheral traits (before the clocking/NoC traits).

---

## Step 4: RocketConfigs.scala — Create a Config Class

**Location**: `generators/chipyard/src/main/scala/config/RocketConfigs.scala`

Add a new configuration class:

```scala
// MNIST-CNN accelerator configuration
class WithMNISTCNN extends Config(
  new chipyard.config.WithMNISTCNN(0x60004000L, 32, 32) ++   // Enable MNIST-CNN at address
  new freechips.rocketchip.rocket.WithNSmallCores(1) ++       // 1 Rocket core
  new chipyard.config.AbstractConfig)                          // Base config
```

**Key points**:

- `0x60004000L` — the `L` suffix makes it a `Long` literal (avoids signed overflow for addresses ≥ 0x80000000)
- Config fragments compose with `++` (left has highest priority)
- `AbstractConfig` must always be the rightmost (base) config

**Address selection**: Avoid conflicts with existing devices:

| Address Range | Device |
|---|---|
| `0x00000000 - 0x0FFFFFFF` | Debug, CLINT, PLIC, Boot ROM |
| `0x10000000 - 0x1FFFFFFF` | Standard peripherals (UART, GPIO, SPI) |
| `0x20000000 - 0x5FFFFFFF` | Available for custom peripherals ✅ |
| `0x60000000 - 0x7FFFFFFF` | Available for custom peripherals ✅ |
| `0x80000000+` | DRAM — **DO NOT overlap** |

---

## Step 5: Add Verilog Source Files

### Option A: Resources (recommended for portability)

Place files in `generators/chipyard/src/main/resources/vsrc/mnist_cnn/`:

```
src/main/resources/vsrc/mnist_cnn/
├── MNISTCNNBlackBox.sv    ← Top-level wrapper (must match BlackBox class name)
└── layer_parameter.sv     ← Include files
```

Reference with `addResource("/vsrc/mnist_cnn/MNISTCNNBlackBox.sv")`

### Option B: Paths (for files outside the project)

Reference with `addPath(s"${System.getProperty("user.dir")}/generators/mnist-cnn/mnist/src/dnn.sv")`

### The top-level wrapper

If your Verilog module name doesn't match your Chisel BlackBox class name, create a wrapper:

```systemverilog
// MNISTCNNBlackBox.sv — wraps dnn.sv to match Chisel BlackBox name
module MNISTCNNBlackBox #(
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 32
)(
    input  wire clk,
    input  wire rst_n,
    // ... all ports matching MNISTCNNIO Bundle ...
);

    dnn #(
        .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
    ) u_dnn (
        .clk(clk),
        .rst_n(rst_n),
        // ... port connections ...
    );

endmodule
```

---

## Step 6: Build and Test

### Build Verilog

```bash
cd sims/verilator
make CONFIG=WithMNISTCNN verilog
```

### Build Simulator

```bash
make CONFIG=WithMNISTCNN
```

### Run Test

```bash
./simulator-chipyard.harness-WithMNISTCNN ../../tests/build/hello.riscv
```

### Verify in Build Log

Check `generated-src/chipyard.harness.TestHarness.WithMNISTCNN/*.chisel.log` for:

```
[MNIST-CNN] Initializing with parameters:
  - Base Address: 0x60004000
  - Data Width: 32 bits
  - PBUS Beat Bytes: 8
```

---

## Common Errors and Solutions

### 1. "Xbar data widths don't match"

```
requirement failed: Xbar data widths don't match: 
mnistcnnDevice has 4B vs pbus has 8B
```

**Cause**: Your node's `beatBytes` doesn't match PBUS width.
**Fix**: Set `beatBytes = beatBytes` (pass through from constructor, matching PBUS).

### 2. "TLFragmenter can't support fragmenting (4) to sub-beat (8)"

**Cause**: `TLFragmenter(4, ...)` with an 8-byte bus.
**Fix**: Use `TLFragmenter(pbus.beatBytes, pbus.blockBytes, holdFirstDeny = true)` — the first parameter must be ≥ the bus beat size.

### 3. "Cannot reassign to read-only"

**Cause**: `RegField(32, 0.U(32.W))` — trying to make a R/W register from a literal.
**Fix**: Use `RegField.r(32, 0.U(32.W))` for read-only.

### 4. "sink not fully initialized"

**Cause**: An output port in your `Impl` class is never driven.
**Fix**: Either remove unused IO bundles from `Impl`, or drive all output signals.

### 5. "No implicit clock"

**Cause**: Using `LazyModuleImp` directly in a subsystem context (which has no implicit clock).
**Fix**: Use `ClockSinkDomain` + inner class `extends Impl` + `withClockAndReset(clock, reset)`.

### 6. "type mismatch; found: YourModule, required: YourDevice.this.Impl"

**Cause**: Using a standalone module class with `ClockSinkDomain`.
**Fix**: Must use inner class pattern: `class YourImpl extends Impl { ... }`.

### 7. Negative address in log output

```
Base Address: 0x-7fffc000
```

**Cause**: Address literal `0x80004000` overflows Scala `Int` (max `0x7FFFFFFF`).
**Fix**: Use `Long` suffix: `0x80004000L`.

### 8. "InterruptSinkNode (PLIC) can not be connected"

**Cause**: Diplomatic graph already finalized when connecting interrupts.
**Fix**: Use `plicOpt.foreach { plic => plic.intnode :=* device.intNode }` inside the trait, or use the interrupt bus pattern.

---

## Key Concepts Reference

### Diplomacy Connection Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `:=` | Connect (1-to-1) | `slave := master` |
| `:=*` | Connect (fan-in, many-to-one) | `plic.intnode :=* device.intNode` |
| `:*=` | Connect (fan-out, one-to-many) | `devices :*= broadcaster` |

### Bus Coupling Methods

| Method | Direction | Use Case |
|--------|-----------|----------|
| `pbus.coupleTo(name) { slave := ... := _ }` | CPU → Device | MMIO slave |
| `fbus.coupleFrom(name) { _ := master }` | Device → Memory | DMA master |

### TileLink Widgets

| Widget | Purpose |
|--------|---------|
| `TLWidthWidget(w)` | Match upstream bus width for crossbar |
| `TLFragmenter(minSize, maxSize)` | Break large transactions into smaller beats |
| `TLBuffer()` | Pipeline stage for timing |
| `TLToAXI4()` | Protocol converter: TileLink → AXI4 |
| `AXI4Deinterleaver(maxBytes)` | Serialize interleaved AXI4 responses |

### RegField Types

| Type | Access | Example |
|------|--------|---------|
| `RegField(w, reg)` | Read/Write | `RegField(32, ctrlReg)` |
| `RegField.r(w, sig)` | Read-Only | `RegField.r(32, statusReg)` |
| `RegField.w(w, reg)` | Write-Only | `RegField.w(32, cmdReg)` |

---

## Summary Checklist

- [ ] **MNISTAccelerator.scala**: IO Bundle + BlackBox + Params + Device (nodes) + Impl (logic)
- [ ] **MnistFragments.scala**: Key + Fragment + Trait (4 paths)
- [ ] **DigitalTop.scala**: Add `with CanHavePeripheryMNISTCNN`
- [ ] **RocketConfigs.scala**: Add `class WithMNISTCNN extends Config(...)`
- [ ] **Verilog files**: Placed in `resources/vsrc/` or referenced via `addPath`
- [ ] **Address**: In peripheral range (`0x10000000-0x7FFFFFFF`), not overlapping DRAM
- [ ] **Build**: `make CONFIG=WithMNISTCNN verilog` succeeds
- [ ] **Simulate**: `./simulator-... tests/build/hello.riscv` exits cleanly
