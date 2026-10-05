# Zephyr Ethos-U55 Integration Test

This repository demonstrates how to build and run a Zephyr application that
uses TensorFlow Lite Micro on an Ethos-U55 NPU. It targets the Corstone-300
Fixed Virtual Platform (FVP), configured with an Ethos-U55 containing 128 MACs
and using the Shared SRAM memory mode.

Two equivalent CMSIS solutions are provided:

| Solution | Toolchain | FVP image |
|---|---|---|
| `GCC-Test-Ethos-U55.csolution.yml` | GCC | `zephyr.hex` |
| `AC6-Test-Ethos-U55.csolution.yml` | Arm Compiler 6 | `zephyr.hex` |

This is the Zephyr counterpart of the
[`Test-Ethos-U` example](https://github.com/arm-software/CMSIS-Ethos-U/tree/main/examples/Test-Ethos-U)
in CMSIS-Ethos-U. It runs two ML models and compares their results with reference data. Both examples use the same model-conversion workflow as the `script/model-converter.py` is  unchanged from [`Test-Ethos-U` example](https://github.com/arm-software/CMSIS-Ethos-U/tree/main/examples/Test-Ethos-U).

## Usage with Keil Studio

- [vcpkg-configuration.json](vcpkg-configuration.json) lists the tool dependencies that can be installed with
  [Arm Tools Environment Manager](https://marketplace.visualstudio.com/items?itemName=Arm.environment-manager).
- [Keil Studio for VS Code](https://marketplace.visualstudio.com/items?itemName=Arm.keil-studio-pack)
  can open the example. In the CMSIS view, use the
  [Action buttons](https://github.com/Open-CMSIS-Pack/vscode-cmsis-solution?tab=readme#action-buttons)
  to configure and build the example. Run the FVP from the command line as described below.

> [!WARNING]
> On Windows, use Python 3.13 to create the Zephyr virtual environment. Python
> 3.14 is not supported because the required `windows-curses` package is not
> available for it.

## Set Up Zephyr

The CI workflows build against Zephyr's `main` branch. The commands below
create a Zephyr workspace, enable the optional TensorFlow Lite Micro and
Ethos-U modules, and install the required Python packages.

### Create the workspace

Open a terminal as a regular user. On Windows, use `cmd.exe` for these
commands.

```console
mkdir zephyrproject
cd zephyrproject
python -m venv .venv
```

Activate the virtual environment.

Linux and macOS:

```sh
source .venv/bin/activate
```

Windows:

```bat
.venv\Scripts\activate.bat
```

Install `west`, initialize the workspace, and fetch Zephyr:

```console
python -m pip install west
west init -m https://github.com/zephyrproject-rtos/zephyr.git --mr main
west update
```

Enable Zephyr's optional module group and fetch the two modules used by this
example:

```console
west config manifest.group-filter -- +optional
west update tflite-micro hal_ethos_u
```

The first command stores the optional group selection in `.west/config`. The
second downloads the module revisions selected by the active Zephyr manifest.
The same commands can be used to add these modules to an existing workspace.

Install Zephyr's Python dependencies:

```console
python -m pip install -r zephyr/scripts/requirements.txt
```

Activate this virtual environment whenever you open a new terminal. Run
`deactivate` to leave it.

### Configure VS Code

Skip this section if you only use the command-line workflow.

The CMSIS Solution extension needs the Zephyr workspace and virtual environment
paths when it invokes `west`:

1. Open VS Code **Settings** and search for **Cmsis-Csolution: Environment
   Variables**.
2. Select the **User** or **Workspace** setting and add the variables below.
   Replace `<work-dir>` with the directory containing `zephyrproject`.

   | Variable | Linux and macOS | Windows |
   |---|---|---|
   | `ZEPHYR_BASE` | `/<work-dir>/zephyrproject/zephyr` | `C:\<work-dir>\zephyrproject\zephyr` |
   | `PATH` | `/<work-dir>/zephyrproject/.venv/bin` | `C:\<work-dir>\zephyrproject\.venv\Scripts` |
   | `VIRTUAL_ENV` | `/<work-dir>/zephyrproject/.venv` | `C:\<work-dir>\zephyrproject\.venv` |

3. Fully restart VS Code so that the extension uses the new environment.

For more information, see
[Work with Zephyr applications](https://mdk-packs.github.io/vscode-cmsis-solution-docs/zephyr.html#set-environment-variables).

## Build and Run

Clone or download this repository. In a terminal, activate the Zephyr virtual
environment, set `ZEPHYR_BASE`, change to the repository root, and install Vela
and the model converter's dependencies:

```console
python -m pip install ethos-u-vela -r script/requirements.txt
```

### Using VS Code

1. Open the repository folder in VS Code.
2. In the CMSIS view, select **Open Solution in Workspace** and open
   `GCC-Test-Ethos-U55.csolution.yml`.
3. Select the `Test-Ethos-U.Debug+SSE-300-U55` context.
4. Generate the model sources from a terminal in the repository root:

   ```console
   cbuild setup GCC-Test-Ethos-U55.csolution.yml --active SSE-300-U55 --packs
   python script/model-converter.py GCC-Test-Ethos-U55.cbuild-mlops.yml --out-dir app/model
   ```

5. Use the CMSIS view action buttons to build the application and start the
   FVP debugger.

To use Arm Compiler 6 instead, open `AC6-Test-Ethos-U55.csolution.yml` and
replace `GCC` with `AC6` in both commands.

> [!TIP]
> If configuration or build errors occur, use **Clean All 'out' and 'tmp'
> directories** from the CMSIS view menu to remove stale CMake cache files
> before rebuilding.

### Using the command line

The following commands generate the model sources and build the GCC solution:

```console
cbuild setup GCC-Test-Ethos-U55.csolution.yml --active SSE-300-U55 --packs
python script/model-converter.py GCC-Test-Ethos-U55.cbuild-mlops.yml --out-dir app/model
cbuild GCC-Test-Ethos-U55.csolution.yml --active SSE-300-U55 --packs
```

Run the resulting image on the FVP:

```console
FVP_Corstone_SSE-300_Ethos-U55 -f fvp_config_u55.txt -a out/Test-Ethos-U/SSE-300-U55/Debug/zephyr/zephyr.hex --simlimit 120
```

To build with Arm Compiler 6, replace `GCC` with `AC6` in all three build
commands. Both solutions and their CI workflows load `zephyr.hex` into the FVP.

### Expected output

Both workflows should produce:

```text
[PASS] hello_world (max delta 0 LSB)
[PASS] tiny_cnn (max delta 0 LSB)
2 of 2 checks passed
TEST RESULT: PASS
```

The FVP exits after the application writes EOT to UART0.

## How Model Generation Works

The model build follows the CMSIS-Toolbox
[MLOps integration workflow](https://open-cmsis-pack.github.io/cmsis-toolbox/build-overview/#mlops-integration):

1. `cbuild setup` reads the solution's `mlops` node and creates
   `GCC-Test-Ethos-U55.cbuild-mlops.yml` or
   `AC6-Test-Ethos-U55.cbuild-mlops.yml`.
2. `script/model-converter.py` reads that generated file, runs Vela with the
   selected model and accelerator parameters, and writes C sources to
   `app/model`.
3. The final `cbuild` invokes `west build` for `mps3/corstone300/fvp`.

The converter leaves optimized `.tflite` files and Vela reports below `Model`.
The generated `*.cbuild-mlops.yml`, `*_vela.tflite`, `VELA_SUMMARY.md`, and
`app/model/*_model.c` files are intentionally ignored by Git.

Regenerate these files after cloning and whenever a source model or the
solution's MLOps configuration changes.

Both solutions place their build output below
`out/Test-Ethos-U/SSE-300-U55/Debug/zephyr` and generate `zephyr.elf` and,
through `CONFIG_BUILD_OUTPUT_HEX`, `zephyr.hex`.

## Ethos-U Configuration

The build, model conversion, and simulation settings must all describe the
same accelerator and memory topology. This example uses the **Ethos-U55, 128
MACs, Shared SRAM** configuration described in
[Configure Ethos-U for FVP Simulation Models](https://arm-software.github.io/CMSIS-Ethos-U/main/integration/fvp-ethos-setup.html).

| Configuration | File | Value and purpose |
|---|---|---|
| Target and FVP | `*-Test-Ethos-U55.csolution.yml` | Selects `SSE-300-U55`, `FVP_Corstone_SSE-300_Ethos-U55`, and `fvp_config_u55.txt`. |
| Model conversion | `*-Test-Ethos-U55.csolution.yml` (`mlops`) | Selects `Ethos-U55`, `macs: 128`, Vela system `Ethos_U55_High_End_Embedded`, and memory mode `Shared_Sram`. `cbuild setup` transfers these values to `*.cbuild-mlops.yml`. |
| Zephyr driver | `app/prj.conf` | Enables the driver and hardware variant with `CONFIG_ETHOS_U=y` and `CONFIG_ETHOS_U55_128=y`. |
| Simulated hardware | `fvp_config_u55.txt` | Sets `ethosu.num_macs=128`. The remaining settings expose UART0 to CI and stop the FVP on EOT. |
| NPU address routing | `app/CMakeLists.txt` | Defines `NPU_REGIONCFG_0=3`, `NPU_REGIONCFG_1=0`, `NPU_REGIONCFG_2=0`, and `NPU_QCONFIG=3` for the Zephyr Ethos-U HAL. |
| Buffer placement | `app/linker.ld` | Places the Vela command streams (`ethos_model`) and TFLM arena (`ethos_arena`) in the NPU-visible `DDR4` region with 16-byte alignment. |

This repository provides the HAL overrides and linker placement shown above. After
changing any row, repeat all three command-line build steps so that model
conversion, firmware, and the simulated hardware remain consistent.

## Repository Structure

```text
.
|-- GCC-Test-Ethos-U55.csolution.yml  GCC solution and MLOps configuration
|-- AC6-Test-Ethos-U55.csolution.yml  Arm Compiler 6 equivalent
|-- app/                              Zephyr application and linker placement
|-- Model/                            Original quantized TFLite models
|-- script/model-converter.py         CMSIS MLOps model converter
`-- fvp_config_u55.txt                Corstone-300 Ethos-U55 FVP settings
```

The Vela command streams and TensorFlow Lite Micro arena are linked into the
FVP's NPU-visible DDR4 memory.
