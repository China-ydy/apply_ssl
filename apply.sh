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
main_menu() {
    while true; do
        echo -e "${GREEN}欢迎使用服务器开荒一键脚本${NC}"
        echo "请选择功能："
        echo "1. 更新系统软件包"
        echo "2. 设置时区为中国标准时间"
        echo "3. 自动申请 SSL 证书"
        echo "4. 退出脚本"
        echo

        # 等待用户输入选择
        read -p "请输入数字选择对应功能: " choice

        # 调试输出：查看输入的内容
        echo "用户输入了：$choice"

        case $choice in
            1)
                update_system
                break
                ;;
            2)
                set_timezone
                break
                ;;
            3)
                apply_ssl
                break
                ;;
            4)
                echo "退出脚本..."
                exit 0
                ;;
            *)
                echo -e "${RED}无效选择，请重新输入！${NC}"
        esac
    done
}

# 功能 1：更新系统软件包
update_system() {
    echo "正在更新系统软件包..."
    sudo apt-get update && sudo apt-get upgrade -y
    echo -e "${GREEN}系统软件包已更新完成！${NC}"
    read -p "按任意键返回主菜单..." temp
    main_menu
}

# 功能 2：设置时区为中国标准时间
set_timezone() {
    echo "正在设置时区为中国标准时间..."
    timedatectl set-timezone Asia/Shanghai
    echo -e "${GREEN}时区已设置为中国标准时间！${NC}"
    read -p "按任意键返回主菜单..." temp
    main_menu
}

# 功能 3：自动申请 SSL 证书
apply_ssl() {
    # 检查是否安装了 certbot 和 dig
    if ! command -v certbot &>/dev/null; then
        echo -e "${RED}未安装 certbot，正在为你安装...${NC}"
        sudo apt-get install -y certbot
    fi
    if ! command -v dig &>/dev/null; then
        echo -e "${RED}未安装 dig 工具，正在为你安装...${NC}"
        sudo apt-get install -y dnsutils
    fi

    # 获取域名
    read -p "请输入已经解析到本服务器IP的域名: " domain

    # 获取本机IP
    local_ip=$(hostname -I | awk '{print $1}')
    echo "本机IP为: $local_ip"

    # 检查域名是否解析到本机 IP
    resolved_ip=$(dig +short "$domain")
    
    if [ "$resolved_ip" != "$local_ip" ]; then
        echo -e "${RED}警告：域名 $domain 并未解析到本机 IP ($local_ip)，当前解析结果为：$resolved_ip${NC}"
        
        # 提示用户是否继续
        while true; do
            read -p "是否继续执行 SSL 证书申请？（y = 继续，n = 重新输入域名，q = 返回主页）： " user_choice
            
            # 调试输出：查看用户输入的选择
            echo "用户选择了：$user_choice"
            
            if [[ "$user_choice" == "y" || "$user_choice" == "Y" ]]; then
                echo "继续执行 SSL 证书申请..."
                break  # 跳出循环，继续执行申请
            elif [[ "$user_choice" == "n" || "$user_choice" == "N" ]]; then
                echo "请重新输入一个已正确解析的域名。"
                return  # 退出当前 apply_ssl 函数，让用户重新执行
            elif [[ "$user_choice" == "q" || "$user_choice" == "Q" ]]; then
                echo "返回主页..."
                main_menu  # 返回主菜单
                return
            else
                echo -e "${RED}无效选择，返回主页...${NC}"
                main_menu  # 返回主菜单
                return
            fi
        done
    fi

    # 执行 certbot 自动申请 SSL 证书
    echo "正在申请 SSL 证书..."
    sudo certbot certonly --standalone -d "$domain" --agree-tos --non-interactive --email your-email@example.com

    if [ $? -eq 0 ]; then
        # 生成证书路径
        cert_path="/etc/letsencrypt/live/$domain/fullchain.pem"
        key_path="/etc/letsencrypt/live/$domain/privkey.pem"

        # 创建以域名命名的目录
        ssl_dir="/root/$domain"
        mkdir -p "$ssl_dir"

        # 复制证书和私钥到新目录
        cp "$cert_path" "$ssl_dir/$domain.cert"
        cp "$key_path" "$ssl_dir/$domain.key"

        # 提示用户证书存储路径
        echo -e "${GREEN}SSL 证书申请成功！证书文件已存储在：$ssl_dir/$domain.cert，私钥文件已存储在：$ssl_dir/$domain.key${NC}"
    else
        echo -e "${RED}SSL 证书申请失败，请检查域名解析是否正确。${NC}"
    fi

    read -p "按任意键返回主菜单..." temp
    main_menu
}

# 运行主菜单
main_menu
