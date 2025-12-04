# Interactive Feedback MCP

[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

由 Fábio Ferreira ([@fabiomlferreira](https://x.com/fabiomlferreira)) 开发。  
更多 AI 开发增强工具请访问 [dotcursorrules.com](https://dotcursorrules.com/)。

一个简单的 [MCP 服务器](https://modelcontextprotocol.io/)，为 [Cursor](https://www.cursor.com)、[Cline](https://cline.bot) 和 [Windsurf](https://windsurf.com) 等 AI 辅助开发工具提供**人机协作 (Human-in-the-loop)** 工作流程。

![Interactive Feedback UI - 主界面](https://github.com/noopstudios/interactive-feedback-mcp/blob/main/.github/interactive_feedback_1.jpg?raw=true)
![Interactive Feedback UI - 命令面板展开](https://github.com/noopstudios/interactive-feedback-mcp/blob/main/.github/interactive_feedback_2.jpg?raw=true)

---

## ✨ 功能特性

- 🔄 **交互式反馈循环** - AI 在完成任务前请求用户确认
- 🖥️ **运行命令** - 直接在反馈界面中执行命令并查看输出
- 💾 **项目级配置** - 为每个项目保存独立的命令设置
- 🎨 **深色模式界面** - 现代化 Qt 界面，支持深色主题
- 🔌 **多平台支持** - 兼容 Cursor、Cline 和 Windsurf

---

## 💡 为什么使用它？

通过引导 AI 助手在执行操作前先与用户确认，而不是盲目进行推测性的高成本工具调用，这个模块可以**大幅减少高级 API 请求次数**。在某些情况下，它可以将多达 **25 次工具调用合并为 1 次反馈感知请求** —— 节省资源并提高准确性。

---

## 🚀 快速安装（推荐）

### 一键安装（macOS/Linux）

```bash
curl -fsSL https://raw.githubusercontent.com/noopstudios/interactive-feedback-mcp/main/mcp1.sh | bash
```

或者手动下载并运行脚本：

```bash
git clone https://github.com/noopstudios/interactive-feedback-mcp.git
cd interactive-feedback-mcp
bash mcp1.sh
```

脚本会自动完成以下操作：
- ✅ 检查 Python 版本（需要 3.11+）
- ✅ 如需要，自动安装 `uv` 包管理器
- ✅ 克隆/更新仓库到 `~/Dev/interactive-feedback-mcp`
- ✅ 安装所有依赖
- ✅ **自动配置 `~/.cursor/mcp.json`**（包含正确的路径）
- ✅ 保留现有的其他 MCP 配置（不会覆盖）

安装完成后，**重启 Cursor** 即可加载新的 MCP 服务器。

---

## 📦 手动安装

### 前置要求

- Python 3.11 或更高版本
- [uv](https://github.com/astral-sh/uv)（Python 包管理器）
  - **macOS/Linux:** `curl -LsSf https://astral.sh/uv/install.sh | sh`
  - **Windows:** `pip install uv`

### 安装步骤

1. **克隆仓库：**
   ```bash
   git clone https://github.com/noopstudios/interactive-feedback-mcp.git
   cd interactive-feedback-mcp
   ```

2. **安装依赖：**
   ```bash
   uv sync
   ```

3. **配置 Cursor**（编辑 `~/.cursor/mcp.json`）：

   > ⚠️ **重要：** 请将下面的路径替换为你的实际安装路径！

   ```json
   {
     "mcpServers": {
       "interactive-feedback-mcp": {
         "command": "uv",
         "args": [
           "--directory",
           "/你的/实际/路径/interactive-feedback-mcp",
           "run",
           "server.py"
         ],
         "timeout": 600,
         "autoApprove": [
           "interactive_feedback"
         ]
       }
     }
   }
   ```

4. **重启 Cursor** 以加载配置。

---

## ⚙️ 提示词配置

为获得最佳效果，请将以下内容添加到你的 **Cursor Rules** 或系统提示词中：

```
Whenever you want to ask a question, always call the MCP `interactive_feedback`.
Whenever you're about to complete a user request, call the MCP `interactive_feedback` instead of simply ending the process.
Keep calling MCP until the user's feedback is empty, then end the request.
```

中文版：

```
每当你想要提问时，始终调用 MCP `interactive_feedback`。
每当你即将完成用户请求时，调用 MCP `interactive_feedback` 而不是直接结束流程。
持续调用 MCP 直到用户的反馈为空，然后结束请求。
```

这将确保 AI 助手在标记任务完成之前请求你的反馈。

---

## 🛠️ 配置说明

MCP 服务器使用 Qt 的 `QSettings` 存储项目级配置：

| 配置项 | 说明 |
|--------|------|
| **命令** | 要运行的 Shell 命令 |
| **自动执行** | 是否在启动时自动运行命令 |
| **命令面板可见性** | 显示/隐藏命令面板 |
| **窗口几何** | 窗口大小和位置 |

配置存储在平台特定位置：
- **macOS:** `~/Library/Preferences/`
- **Linux:** `~/.config/` 或 `~/.local/share/`
- **Windows:** 注册表

---

## 🧪 开发调试

使用 Web 界面运行开发模式进行测试：

```bash
uv run fastmcp dev server.py
```

这将打开一个 Web 界面，用于与 MCP 工具进行交互测试。

---

## 📖 API 参考

### 工具：`interactive_feedback`

向用户请求交互式反馈。

**参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `project_directory` | `string` | 项目目录的完整路径 |
| `summary` | `string` | 变更的简短摘要（一行） |

**调用示例：**

```xml
<use_mcp_tool>
  <server_name>interactive-feedback-mcp</server_name>
  <tool_name>interactive_feedback</tool_name>
  <arguments>
    {
      "project_directory": "/path/to/your/project",
      "summary": "我已经完成了你请求的更改。"
    }
  </arguments>
</use_mcp_tool>
```

**返回值：**

```json
{
  "logs": "命令输出日志（如有）",
  "interactive_feedback": "用户的反馈文本"
}
```

---

## 🤝 贡献

欢迎贡献！你可以：

- 提交 Issue 报告 Bug 或请求新功能
- 提交 Pull Request
- 在 [X @fabiomlferreira](https://x.com/fabiomlferreira) 上分享你的反馈

---

## 📄 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

---

## 🙏 致谢

如果你觉得 Interactive Feedback MCP 有用，请关注 Fábio Ferreira 的 [X @fabiomlferreira](https://x.com/fabiomlferreira)。

更多 AI 辅助开发资源，请访问 [dotcursorrules.com](https://dotcursorrules.com/)。
