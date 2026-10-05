# Zephyr Ethos-U55 Integration Test

This example runs two Vela-compiled TensorFlow Lite Micro models on the
Ethos-U55 NPU in the Corstone-300 Fixed Virtual Platform (FVP). The application
uses Zephyr's native TensorFlow Lite Micro and Ethos-U modules and is built with
CMSIS-Toolbox and Zephyr's `west` build system.

This repository is the Zephyr version of the
[`Test-Ethos-U` example](https://github.com/arm-software/CMSIS-Ethos-U/tree/main/examples/Test-Ethos-U)
in `arm-software/CMSIS-Ethos-U`. Its `script/model-converter.py` is copied
unchanged from that example so both versions use the same MLOps conversion
workflow.

The test executes a `hello_world` model and a small convolutional neural
network. Both results are compared with reference output embedded in the
application.

## Quick Start

1. Install [Keil Studio for VS Code](https://marketplace.visualstudio.com/items?itemName=Arm.keil-studio-pack).
2. [Install Zephyr and its Ethos-U dependencies](#zephyr-installation).
3. Clone or download this repository and open its folder in VS Code.
4. [Configure the Zephyr environment](#configure-vs-code) and restart VS Code.
5. In the CMSIS view, select **Open Solution in Workspace** and open
   `GCC-Test-Ethos-U55.csolution.yml`.
6. [Generate the model C sources](#mlops-integration).
7. Select `Test-Ethos-U.Debug+SSE-300-U55`, then use the CMSIS view action
   buttons to build and start the FVP debugger.

The expected result is:

```text
[PASS] hello_world (max delta 0 LSB)
[PASS] tiny_cnn (max delta 0 LSB)
2 of 2 checks passed
TEST RESULT: PASS
```

> [!TIP]
> If configuration or build errors occur, use **Clean All 'out' and 'tmp'
> directories** from the CMSIS view menu to remove stale CMake cache files
> before rebuilding.

## Zephyr Installation

The CI workflows build against Zephyr's current `main` branch. Install a supported Python 3 version
and Git before continuing.

> [!WARNING]
> On Windows, use Python 3.13 or earlier because the `windows-curses` package
> is not available for Python 3.14.

### Create the workspace

Open a terminal as a regular user. On Windows, use `cmd.exe` for these
commands.

Create a Zephyr workspace and a Python virtual environment:

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

Install `west` and initialize the workspace with the tested Zephyr release:

```console
python -m pip install west
west init -m https://github.com/zephyrproject-rtos/zephyr.git --mr main
west update
```

TensorFlow Lite Micro is an optional Zephyr module. For a new or existing
Zephyr workspace, run the following commands from the workspace root to enable
the optional module group and fetch the two dependencies used by this example:

```console
west config manifest.group-filter -- +optional
west update tflite-micro hal_ethos_u
```

These modules can also be added later to an existing Zephyr installation. The
first command saves the optional group selection in `.west/config`; the second
command downloads or updates only the named modules to the revisions selected
by the active Zephyr manifest.

Install Zephyr's Python dependencies:

```console
python -m pip install -r zephyr/scripts/requirements.txt
```

Activate the virtual environment again whenever you open a new terminal. Run
`deactivate` to leave it.

### Configure VS Code

The CMSIS Solution extension needs the Zephyr workspace and virtual environment
paths when it invokes `west`.

1. Open VS Code **Settings** and search for **Cmsis-Csolution: Environment
   Variables**.
2. Select the **User** or **Workspace** setting and add the following variables.
   Replace `<work-dir>` with the directory in which you created your
   `zephyrproject` workspace.

   | Variable | Linux and macOS | Windows |
   |---|---|---|
   | `ZEPHYR_BASE` | `/<work-dir>/zephyrproject/zephyr` | `C:\<work-dir>\zephyrproject\zephyr` |
   | `PATH` | `/<work-dir>/zephyrproject/.venv/bin` | `C:\<work-dir>\zephyrproject\.venv\Scripts` |
   | `VIRTUAL_ENV` | `/<work-dir>/zephyrproject/.venv` | `C:\<work-dir>\zephyrproject\.venv` |

3. Fully restart VS Code so the extension uses the new environment.

For more information, see
[Work with Zephyr applications](https://mdk-packs.github.io/vscode-cmsis-solution-docs/zephyr.html#set-environment-variables).

## Build and MLOps Integration

The repository provides two CMSIS solution projects for the same application,
target, FVP, and MLOps configuration:

| Solution | Toolchain | Notes |
|---|---|---|
| `GCC-Test-Ethos-U55.csolution.yml` | GCC | Use this solution for the GNU toolchain. The FVP can load the generated `zephyr.elf`. |
| `AC6-Test-Ethos-U55.csolution.yml` | Arm Compiler 6 | Use this solution for Arm Compiler; a valid Arm tool license is required. The CI workflow loads the generated `zephyr.hex`. |

Install [CMSIS-Toolbox](https://open-cmsis-pack.github.io/cmsis-toolbox/installation/)
and ensure that the selected compiler and the Corstone-300 Ethos-U55 FVP from
`vcpkg-configuration.json` are active. Activate the Zephyr virtual environment,
set `ZEPHYR_BASE`, and install Vela and the converter requirements:

```console
python -m pip install ethos-u-vela -r script/requirements.txt
```

Then run the setup, model-conversion, and build steps from the repository root.
This example uses the GCC solution; substitute `AC6` for `GCC` in all three
commands to build with Arm Compiler 6.

```console
cbuild setup GCC-Test-Ethos-U55.csolution.yml --active SSE-300-U55 --packs
python script/model-converter.py GCC-Test-Ethos-U55.cbuild-mlops.yml --out-dir app/model
cbuild GCC-Test-Ethos-U55.csolution.yml --active SSE-300-U55 --packs
```

This follows the CMSIS-Toolbox
[MLOps integration workflow](https://open-cmsis-pack.github.io/cmsis-toolbox/build-overview/#mlops-integration).
`cbuild setup` generates `GCC-Test-Ethos-U55.cbuild-mlops.yml` from the
solution's `mlops` node. The converter uses its model selection and Vela
parameters, writes generated C sources to `app/model`, and leaves the optimized
`.tflite` files and Vela reports below `Model`. The final `cbuild` invokes
`west build` for `mps3/corstone300/fvp`.

The generated `*.cbuild-mlops.yml`, `*_vela.tflite`, `VELA_SUMMARY.md`, and
`app/model/*_model.c` files are intentionally ignored by Git. Regenerate them
after cloning or whenever the models or MLOps configuration changes.

Both solutions generate `zephyr.elf` and, through `CONFIG_BUILD_OUTPUT_HEX`,
`zephyr.hex` below `out/Test-Ethos-U/SSE-300-U55/Debug/zephyr`. Run the GCC
image on the FVP with:

```console
FVP_Corstone_SSE-300_Ethos-U55 -f fvp_config_u55.txt -a out/Test-Ethos-U/SSE-300-U55/Debug/zephyr/zephyr.elf --simlimit 120
```

## Ethos-U Configuration

The Ethos-U parameters are distributed across the build and simulation files;
they must describe the same accelerator and memory topology. This example uses
the **Ethos-U55, 128 MACs, Shared SRAM** combination described in
[Configure Ethos-U for FVP Simulation Models](https://arm-software.github.io/CMSIS-Ethos-U/main/integration/fvp-ethos-setup.html).

| Configuration | File | Value and purpose |
|---|---|---|
| Target and FVP | `*-Test-Ethos-U55.csolution.yml` | Selects `SSE-300-U55`, the `FVP_Corstone_SSE-300_Ethos-U55` model, and `fvp_config_u55.txt`. |
| Model conversion | `*-Test-Ethos-U55.csolution.yml` (`mlops`) | Selects `Ethos-U55`, `macs: 128`, Vela system `Ethos_U55_High_End_Embedded`, and memory mode `Shared_Sram`. `cbuild setup` copies these values into `*.cbuild-mlops.yml` for `model-converter.py`. |
| Zephyr driver | `app/prj.conf` | Enables the Ethos-U driver and its matching hardware variant with `CONFIG_ETHOS_U=y` and `CONFIG_ETHOS_U55_128=y`. |
| Simulated hardware | `fvp_config_u55.txt` | Sets `ethosu.num_macs=128`; this must agree with the solution and Zephyr Kconfig. The remaining parameters make UART0 visible to CI and stop the FVP on EOT. |
| NPU address routing | `app/CMakeLists.txt` | Defines `NPU_REGIONCFG_0=3`, `NPU_REGIONCFG_1=0`, `NPU_REGIONCFG_2=0`, and `NPU_QCONFIG=3` for the Zephyr Ethos-U HAL. These are repository-specific overrides for its memory map. |
| Buffer placement | `app/linker.ld` | Places the generated Vela command streams (`ethos_model`) and the application-owned TFLM arena (`ethos_arena`) in the FVP's NPU-visible `DDR4` region with 16-byte alignment. |

The linked reference page supplies the U55 Shared SRAM values used here. This
Zephyr integration provides its own HAL overrides and linker placement as shown
in the table. After changing any configuration row, repeat the setup,
model-conversion, and build steps in [Build and MLOps Integration](#build-and-mlops-integration).

## Application Structure

- `GCC-Test-Ethos-U55.csolution.yml` and `AC6-Test-Ethos-U55.csolution.yml`
  describe the GCC and Arm Compiler 6 variants of the same target, FVP, and
  MLOps configuration.
- `app` contains the Zephyr application, linker placement and generated model
  sources.
- `Model` contains the original quantized `.tflite` models.
- `script/model-converter.py` converts models using the generated MLOps build
  information and is identical to the script in `CMSIS-Ethos-U`.
- `fvp_config_u55.txt` configures the Corstone-300 Ethos-U55 FVP.

The Vela command streams and TensorFlow Lite Micro arena are linked into the
FVP's NPU-visible DDR4 memory. The FVP exits when the application writes EOT to
UART0.
