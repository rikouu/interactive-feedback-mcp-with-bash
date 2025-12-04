#!/usr/bin/env bash
set -e

# ---------- 颜色定义 ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ---------- 辅助函数 ----------
print_header() {
  echo -e "\n${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${NC}"
  echo -e "${BOLD}${BLUE}  $1${NC}"
  echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"
}

print_step() {
  echo -e "${CYAN}>> $1${NC}"
}

print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
}

print_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

# ---------- 开始 ----------
print_header "Interactive Feedback MCP 安装脚本"

# ---------- 配置参数（可按需修改） ----------
REPO_URL="https://github.com/noopstudios/interactive-feedback-mcp.git"
INSTALL_DIR="${HOME}/Dev/interactive-feedback-mcp"
MCP_NAME="interactive-feedback-mcp"
CURSOR_MCP_JSON="${HOME}/.cursor/mcp.json"
UV_BIN_NAME="uv"

echo -e "${BOLD}配置信息：${NC}"
echo -e "  • 仓库地址: ${CYAN}${REPO_URL}${NC}"
echo -e "  • 安装目录: ${CYAN}${INSTALL_DIR}${NC}"
echo -e "  • MCP 名称: ${CYAN}${MCP_NAME}${NC}"
echo -e "  • Cursor 配置: ${CYAN}${CURSOR_MCP_JSON}${NC}"
echo ""

# ---------- 检查 Python 版本 ----------
print_step "检查 Python3..."
if ! command -v python3 >/dev/null 2>&1; then
  print_error "未找到 python3，请先安装 Python 3.11+ 再运行本脚本。"
  exit 1
fi

PY_VERSION_RAW=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
PY_MAJOR=$(echo "$PY_VERSION_RAW" | cut -d. -f1)
PY_MINOR=$(echo "$PY_VERSION_RAW" | cut -d. -f2)

if [ "$PY_MAJOR" -lt 3 ] || { [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 11 ]; }; then
  print_error "当前 Python 版本为 ${PY_VERSION_RAW}，需要 >= 3.11"
  exit 1
fi

print_success "Python3 版本满足要求：$PY_VERSION_RAW"

# ---------- 安装 uv ----------
print_step "检查 uv..."
if ! command -v ${UV_BIN_NAME} >/dev/null 2>&1; then
  print_warning "未检测到 uv，开始安装..."
  curl -LsSf https://astral.sh/uv/install.sh | sh

  # 确保 ~/.local/bin 在 PATH 中
  if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.bashrc"
    export PATH="$HOME/.local/bin:$PATH"
    print_info "已将 \$HOME/.local/bin 加入 PATH，并写入 ~/.bashrc"
  fi

  if ! command -v ${UV_BIN_NAME} >/dev/null 2>&1; then
    print_error "uv 安装后仍未找到，请检查安装脚本输出。"
    exit 1
  fi
  print_success "uv 安装完成"
else
  print_success "已检测到 uv：$(command -v ${UV_BIN_NAME})"
fi

# ---------- 克隆或更新仓库 ----------
print_step "准备安装目录：${INSTALL_DIR}"
mkdir -p "$(dirname "${INSTALL_DIR}")"

if [ ! -d "${INSTALL_DIR}/.git" ]; then
  print_step "仓库不存在，开始 clone..."
  git clone "${REPO_URL}" "${INSTALL_DIR}"
  print_success "仓库克隆完成"
else
  print_step "仓库已存在，执行 git pull..."
  git -C "${INSTALL_DIR}" pull --ff-only || {
    print_warning "git pull 失败，请手动检查仓库状态：${INSTALL_DIR}"
  }
  print_success "仓库更新完成"
fi

# ---------- 安装依赖（uv sync） ----------
print_step "使用 uv 安装依赖..."
cd "${INSTALL_DIR}"
${UV_BIN_NAME} sync

print_success "uv sync 完成"

# ---------- 确保 jq 存在，用来安全修改 JSON ----------
print_step "检查 jq..."
if ! command -v jq >/dev/null 2>&1; then
  print_warning "未检测到 jq，尝试安装..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if command -v brew >/dev/null 2>&1; then
      brew install jq
    else
      print_error "未找到 Homebrew，请先安装 jq: brew install jq"
      exit 1
    fi
  else
    # Linux
    sudo apt-get update
    sudo apt-get install -y jq
  fi
fi
print_success "jq 已就绪"

# ---------- 配置 ~/.cursor/mcp.json ----------
print_step "配置 Cursor MCP：${CURSOR_MCP_JSON}"
mkdir -p "$(dirname "${CURSOR_MCP_JSON}")"

# 构造这个 MCP server 的配置 JSON
read -r -d '' MCP_SERVER_JSON <<EOF || true
{
  "command": "uv",
  "args": [
    "--directory",
    "${INSTALL_DIR}",
    "run",
    "server.py"
  ],
  "timeout": 600,
  "autoApprove": [
    "interactive_feedback"
  ]
}
EOF

# 如果 mcp.json 不存在，创建新的
if [ ! -f "${CURSOR_MCP_JSON}" ]; then
  print_step "~/.cursor/mcp.json 不存在，创建新文件..."
  cat > "${CURSOR_MCP_JSON}" <<EOF
{
  "mcpServers": {
    "${MCP_NAME}": ${MCP_SERVER_JSON}
  }
}
EOF
  print_success "已创建新的 mcp.json"
else
  print_step "~/.cursor/mcp.json 已存在，合并配置..."
  # 用 jq 合并/覆盖 interactive-feedback-mcp 配置
  tmp_file="$(mktemp)"
  jq --arg name "${MCP_NAME}" --argjson server "${MCP_SERVER_JSON}" '
    .mcpServers = (.mcpServers // {}) |
    .mcpServers[$name] = $server
  ' "${CURSOR_MCP_JSON}" > "${tmp_file}"
  mv "${tmp_file}" "${CURSOR_MCP_JSON}"
  print_success "已更新 mcp.json 中的 ${MCP_NAME} 配置"
fi

# ---------- 完成信息 ----------
print_header "🎉 安装完成！"

echo -e "${BOLD}${GREEN}所有步骤已成功执行！${NC}\n"

echo -e "${BOLD}📁 安装路径信息：${NC}"
echo -e "┌────────────────────────────────────────────────────────────────┐"
echo -e "│ 项目安装目录: ${CYAN}${INSTALL_DIR}${NC}"
echo -e "│ Cursor 配置:  ${CYAN}${CURSOR_MCP_JSON}${NC}"
echo -e "└────────────────────────────────────────────────────────────────┘"
echo ""

echo -e "${BOLD}📋 生成的 MCP 配置 (已写入 mcp.json)：${NC}"
echo -e "${YELLOW}────────────────────────────────────────────────────────────────${NC}"
cat <<EOF
{
  "mcpServers": {
    "${MCP_NAME}": {
      "command": "uv",
      "args": [
        "--directory",
        "${INSTALL_DIR}",   <-- 这是你的安装路径
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
EOF
echo -e "${YELLOW}────────────────────────────────────────────────────────────────${NC}"
echo ""

echo -e "${BOLD}📌 下一步操作：${NC}"
echo -e "  ${GREEN}1.${NC} 重启 Cursor，让它重新加载 mcp.json 配置"
echo -e "  ${GREEN}2.${NC} 在 Cursor 设置中确认 MCP server: ${CYAN}${MCP_NAME}${NC} 已启用"
echo -e "  ${GREEN}3.${NC} 在 Cursor 的自定义提示词中添加以下内容以获得最佳效果："
echo ""
echo -e "${YELLOW}────────────────────────────────────────────────────────────────${NC}"
echo -e "  Whenever you want to ask a question, always call the MCP"
echo -e "  \`interactive_feedback\`."
echo -e "  Whenever you're about to complete a user request, call the MCP"
echo -e "  \`interactive_feedback\` instead of simply ending the process."
echo -e "  Keep calling MCP until the user's feedback is empty, then end"
echo -e "  the request."
echo -e "${YELLOW}────────────────────────────────────────────────────────────────${NC}"
echo ""

echo -e "${BOLD}🔧 手动测试（可选）：${NC}"
echo -e "  ${CYAN}cd \"${INSTALL_DIR}\"${NC}"
echo -e "  ${CYAN}uv run server.py${NC}"
echo ""
print_info "MCP 进程启动后会通过 stdio 通信，正常情况下会挂起等待客户端请求。"
echo ""

echo -e "${BOLD}${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  感谢使用 Interactive Feedback MCP！${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════════════════════════════════════${NC}"
