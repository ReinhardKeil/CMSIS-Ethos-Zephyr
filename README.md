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
   `Test-Ethos-U55.csolution.yml`.
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

The example is tested with Zephyr 4.4.0. Install a supported Python 3 version
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
west init -m https://github.com/zephyrproject-rtos/zephyr.git --mr v4.4.0
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

## MLOps Integration

The solution contains the model inputs and Vela parameters described by the
CMSIS-Toolbox
[MLOps integration workflow](https://open-cmsis-pack.github.io/cmsis-toolbox/build-overview/#mlops-integration).
Install Vela and the converter's Python requirements:

```console
python -m pip install ethos-u-vela -r script/requirements.txt
```

Generate the MLOps build information, then pass that generated file to the
converter:

```console
cbuild setup Test-Ethos-U55.csolution.yml --active SSE-300-U55 --packs
python script/model-converter.py Test-Ethos-U55.cbuild-mlops.yml --out-dir app/model
```

`cbuild setup` generates `Test-Ethos-U55.cbuild-mlops.yml` from the `mlops`
node in `Test-Ethos-U55.csolution.yml`. The converter reads its model selection
and Vela parameters. `--out-dir app/model` writes the generated C sources where
the Zephyr CMake project expects them; optimized `.tflite` files and Vela
reports remain below `Model`.

The generated `*.cbuild-mlops.yml`, `*_vela.tflite`, `VELA_SUMMARY.md`, and
`app/model/*_model.c` files are intentionally ignored by Git. Regenerate them
after cloning or whenever the models or MLOps configuration change. Commit
them only when a project deliberately chooses to version generated artifacts.

## Command-Line Build

Install [CMSIS-Toolbox](https://open-cmsis-pack.github.io/cmsis-toolbox/installation/)
and ensure that GCC and the Corstone-300 Ethos-U55 FVP from
`vcpkg-configuration.json` are active. Activate the Zephyr virtual environment,
set `ZEPHYR_BASE`, and run from the repository root:

```console
cbuild setup Test-Ethos-U55.csolution.yml --active SSE-300-U55 --packs
python script/model-converter.py Test-Ethos-U55.cbuild-mlops.yml --out-dir app/model
cbuild Test-Ethos-U55.csolution.yml --active SSE-300-U55 --packs
```

The solution invokes `west build` for `mps3/corstone300/fvp`. The resulting
image is:

```text
out/Test-Ethos-U/SSE-300-U55/Debug/zephyr/zephyr.elf
```

Run it on the FVP with:

```console
FVP_Corstone_SSE-300_Ethos-U55 -f fvp_config_u55.txt -a out/Test-Ethos-U/SSE-300-U55/Debug/zephyr/zephyr.elf --simlimit 120
```

## Application Structure

- `Test-Ethos-U55.csolution.yml` describes the CMSIS solution, target, FVP and
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
