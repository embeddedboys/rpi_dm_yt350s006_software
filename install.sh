#!/bin/bash

valid_disp_models=("YT350S006" "HP35006" "CL35BC219-40A")
valid_touch_models=("GT911" "FT6336" "NS2009")
valid_code_servers=("gitee" "github")

DISP_MODEL="YT350S006"
TOUCH_MODEL="GT911"
CODE_SERVER="github"
ORGNAZATION="embeddedboys"
REPO_NAME="rpi_dm_yt350s006_software"

WORK_DIR="${HOME}/${REPO_NAME}"

C_BLACK="\e[30;1m"
C_RED="\e[31;1m"
C_GREEN="\e[32;1m"
C_YELLOW="\e[33;1m"
C_BLUE="\e[34;1m"
C_PURPLE="\e[35;1m"
C_CYAN="\e[36;1m"
C_WHITE="\e[37;1m"
C_NORMAL="\033[0m"

function msg_tip()
{
	echo -e "${C_PURPLE}[ $(date | awk '{ print $4 }') ] $1${C_NORMAL}"
}

function msg_info()
{
	echo -e "${C_GREEN}[ $(date | awk '{ print $4 }') ] $1${C_NORMAL}"
}

function msg_warn()
{
	echo -e "${C_YELLOW}[ $(date | awk '{ print $4 }') ] $1${C_NORMAL}"
}

function msg_error()
{
	echo -e "${C_RED}[ $(date | awk '{ print $4 }') ] $1${C_NORMAL}"
}

function msg_normal()
{
    echo -e "[ $(date | awk '{ print $4 }') ] $1"
}

function check_choice_if_vaild()
{
    if [ $1 -ge $2 ]; then
        return 1
    fi
    return 0
}

function ask_disp_model()
{
    msg_info "请选择您的的显示面板型号："
    msg_normal "\t 0. YT350S006"
    msg_normal "\t 1. HP35006"
    msg_normal "\t 2. CL35BC219-40A"
    msg_tip "检查您购买的屏幕FPC丝印"
    read -p "请输入选择 [0]: " model
    model=${model:-0}
    check_choice_if_vaild ${model} ${#valid_disp_models[@]}
    if [ $? -eq 1 ]; then
        msg_warn "输入的参数不合法，请重新输入"
        ask_disp_model
    fi
    DISP_MODEL=${valid_disp_models[${model}]}
}

function ask_touch_model()
{
    msg_info "请选择您的触摸屏型号："
    msg_normal "\t 0. GT911"
    msg_normal "\t 1. FT6336"
    msg_normal "\t 2. NS2009"
    msg_tip "检查您购买的屏幕时选择的触摸类型"
    read -p "请输入选择 [0]: " model
    model=${model:-0}
    check_choice_if_vaild ${model} ${#valid_touch_models[@]}
    if [ $? -eq 1 ]; then
        msg_warn "输入的参数不合法，请重新输入"
        ask_touch_model
    fi
    TOUCH_MODEL=${valid_touch_models[${model}]}
}

function ask_code_server()
{
    msg_info "请选择代码服务器："
    msg_normal "\t 0. gitee"
    msg_normal "\t 1. github"
    read -p "请输入选择 [0]: " choice
    choice=${choice:-0}
    check_choice_if_vaild ${choice} ${#valid_code_servers[@]}
    if [ $? -eq 1 ]; then
        msg_warn "输入的参数不合法，请重新输入"
        ask_code_server
    fi
    CODE_SERVER=${valid_code_servers[${choice}]}
}

# 打印用户选择
function print_user_select()
{
    msg_info "您选择的显示面板型号为：${DISP_MODEL}"
    msg_info "您选择的触摸屏型号为：${TOUCH_MODEL}"
    msg_info "您选择的代码服务器为：${CODE_SERVER}"
}

function install()
{
    REPO_URL="https://${CODE_SERVER}.com/${ORGNAZATION}/${REPO_NAME}.git"
    FIRST_RUN=false

    msg_info "开始安装， 工作目录为：${WORK_DIR}"
    if [ ! -d ${WORK_DIR} ]; then
        git clone -v --progress ${REPO_URL} ${WORK_DIR}
        # echo ${REPO_URL}
    fi

    pushd ${WORK_DIR} >> /dev/null
    # ls -lh

    if [ ! -f .first_run ]; then
        FIRST_RUN=true
        touch .first_run
    fi

    # 如果是第一次运行，备份用户的config.txt文件
    if [ ${FIRST_RUN} = true ]; then
        if [ ! -f "/boot/firmware/config.txt" ]; then
            sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.bak
            msg_info "您的config.txt备份文件已保存为：/boot/firmware/config.txt.bak"
        fi

        if [ ! -f "/boot/config.txt" ]; then
            sudo cp /boot/config.txt /boot/config.txt.bak
            msg_info "您的config.txt备份文件已保存为：/boot/config.txt.bak"
        fi
    fi

    # 将备份的config.txt文件覆盖回来，因为用户可能反复运行此脚本
    # 这里需要一个额外判断，如果用户在运行完本脚本之后，自己修改了config.txt
    # 文件，那就应该先询问用户是否要覆盖当前的config.txt文件
    if [ -f "/boot/firmware/config.txt.bak" ]; then
        sudo cp /boot/firmware/config.txt.bak /boot/firmware/config.txt
    fi
    if [ -f "/boot/config.txt.bak" ]; then
        sudo cp /boot/config.txt.bak /boot/config.txt
    fi

    # 安装显示相关
    # original_string="dtparam=compatible=rpi-dm-yt350s006\0panel-mipi-dbi-spi"
    case ${DISP_MODEL} in
    "YT350S006")
        # modified_string=$(echo "$original_string" | sed 's/\(compatible=\)[^\\]*\\0/\1rpi-dm-yt350s006\\0/')
        sed -i 's/\(compatible=\)[^\\]*\\0/\1rpi-dm-yt350s006\\0/' config.txt
        ;;
    "HP35006")
        # modified_string=$(echo "$original_string" | sed 's/\(compatible=\)[^\\]*\\0/\1rpi-dm-hp35006\\0/')
        sed -i 's/\(compatible=\)[^\\]*\\0/\1rpi-dm-hp35006\\0/' config.txt
        ;;
    "CL35BC219-40A")
        # modified_string=$(echo "$original_string" | sed 's/\(compatible=\)[^\\]*\\0/\1rpi-dm-cl35bc219-40a\\0/')
        sed -i 's/\(compatible=\)[^\\]*\\0/\1rpi-dm-cl35bc219-40a\\0/' config.txt
        ;;
    esac
    # echo "$modified_string"
    cat config.txt

    # 安装触摸相关

    # 询问用户是否重启设备使改动生效
}

function default_install()
{
    msg_info "执行默认安装流程中。。。"
    ask_disp_model
    ask_touch_model
    # ask_code_server

    print_user_select

    read -p "是否继续安装？[Y/n] " answer
    case $answer in
    Y|y|"")
        install
        ;;
    *|n|N)
        msg_error "用户取消安装，退出安装"
        exit 1
        ;;
    esac
}

num=$#
while [[ $# -gt 0 ]]; do
    case $1 in
    --model)
        model=$2
        ;;
    -*|--*)
        msg_error "未知选项 $1"
        # exit 1
    esac
    if [ $((num)) -gt 0 ]; then
        shift
    fi
done

# 检查是否在树莓派上运行
# check_if_raspberry_pi()
# {
#     if [ ! -f /etc/rpi-issue ]; then
#         msg_error "当前不是树莓派系统，无法安装"
#         exit 1
#     fi
# }

echo "参数个数：$num"

# 如果没有提供参数，则执行默认安装流程
if [ $num -eq 0 ]; then
    default_install
    exit 0
fi

# 如果提供了参数，先判断参数是否是否在允许的范围内
echo ${{model}}