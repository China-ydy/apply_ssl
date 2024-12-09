#!/bin/bash

# 设置颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查是否安装了 sudo
if ! command -v sudo &>/dev/null; then
    echo -e "${RED}系统未安装 sudo，正在为你安装...${NC}"
    apt-get update && apt-get install -y sudo
    echo -e "${GREEN}sudo 安装成功！${NC}"
else
    echo -e "${GREEN}已检测到 sudo，继续执行...${NC}"
fi

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}建议以 root 用户运行该脚本！${NC}"
else
    echo -e "${GREEN}已检测到 root 用户，可以继续执行！${NC}"
fi

# 主菜单函数
main(){
    echo -e "${GREEN}欢迎使用服务器开荒一键脚本${NC}"
    echo "请选择功能："
    echo "1. 更新系统软件包"
    echo "2. 设置时区为中国标准时间"
    echo "3. 自动申请 SSL 证书"
    echo "4. 退出脚本"
    echo "请输入要选择的功能"
    read choice
    echo -e "${GREEN}您选择的功能是：  ${choice}  ${NC}"
}
main