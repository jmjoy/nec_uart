# NEC UART（实验项目）

这是一个面向 FPGA 的 NEC 红外协议与 UART 相关逻辑的实验项目，用于学习与验证设计方法。代码与工程文件供参考，不保证适配所有环境或器件。

## 主要内容

- NEC 协议解析与显示（`nec.sv`, `nec_bcd.sv`, `bcd_display.sv` 等）
- UART 发送模块（`uart_tx.sv`）
- 顶层与约束（`top_nec_uart.sv`, `nec_uart.cst`, `nec_uart.sdc`）
- 仿真与测试（`tb_*.sv`, `waves.mxd`, `files.f`）
- 工程/实现产物（`impl/`, `pnr/`, `dsim_work/`）

## 快速开始

- 环境：Linux，bash，含可用的 SystemVerilog 仿真与综合工具（例如 DSim/Gowin 工具链）。
- 仿真（示例，仅供参考）：
- 使用 `files.f` 与测试平台 `tb_nec_uart.sv` 进行编译与仿真。
- 不同工具命令有所差异，请按本机工具链调整。

## 文件结构（简要）

- `src/`：源代码与约束
- `impl/`, `pnr/`：综合、布局布线与报告
- `dsim_work/`：仿真中间产物
- `waves.mxd`：波形视图配置
- `files.f`：仿真文件列表

## 免责声明

本仓库仅用于学习与实验，接口、时序、约束等可能需根据实际硬件平台调整。请在受控环境下验证后再用于任何实际项目。

## 许可

本项目遵循仓库根目录中的 `LICENSE` 文件所述条款。

