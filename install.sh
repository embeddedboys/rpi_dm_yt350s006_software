#!/bin/bash

valid_disp_models=("YT350S006" "HP35006" "CL35BC219-40A")
valid_touch_models=("GT911" "FT6336" "NS2009" "TSC2007")
valid_code_servers=("gitee" "github")

# 如果是测试环境
if [ "${RPI_DM_TEST}" = "1" ]; then
    echo "当前正处于测试环境"
    TARGET_CONFIG="/tmp/config.txt"
    DTBO_INSTALL_DIR="/tmp"
    FIRMWARE_INSTALL_DIR="/tmp"
    REBOOT_CMD="echo 测试环境不需要重启"
else
    TARGET_CONFIG="/boot/firmware/config.txt"
    DTBO_INSTALL_DIR="/boot/firmware/overlays"
    FIRMWARE_INSTALL_DIR="/lib/firmware"
    REBOOT_CMD="sudo reboot"
fi

# 一些默认值
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
	echo -e "${C_PURPLE}[ $(date +"%H:%M:%S" | awk '{ print $1 }') ] $1${C_NORMAL}"
}

function msg_info()
{
	echo -e "${C_GREEN}[ $(date +"%H:%M:%S" | awk '{ print $1 }') ] $1${C_NORMAL}"
}

function msg_warn()
{
	echo -e "${C_YELLOW}[ $(date +"%H:%M:%S" | awk '{ print $1 }') ] $1${C_NORMAL}"
}

function msg_error()
{
	echo -e "${C_RED}[ $(date +"%H:%M:%S" | awk '{ print $1 }') ] $1${C_NORMAL}"
}

function msg_normal()
{
    echo -e "[ $(date +"%H:%M:%S" | awk '{ print $1 }') ] $1"
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
    msg_info "请选择您的触摸屏驱动IC型号："
    msg_normal "\t 0. GT911"
    msg_normal "\t 1. FT6336"
    msg_normal "\t 2. NS2009"
    msg_normal "\t 3. TSC2007"
    msg_tip "检查您购买的屏幕，如果是电容触摸，检查商品详情中的触摸IC型号。如果是电阻触摸，检查电路板上焊接的电阻屏驱动IC的型号"
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
        msg_tip "备份用户的config.txt文件, 需要root权限"
        if [ -f "/boot/firmware/config.txt" ]; then
            TARGET_CONFIG="/boot/firmware/config.txt"
        fi

        # FIXME: 在一些老的型号上，还在使用/boot/config.txt文件
        # if [ -f "/boot/config.txt" ]; then
        #     TARGET_CONFIG="/boot/config.txt"
        # fi

        sudo cp ${TARGET_CONFIG} ${TARGET_CONFIG}.bak
        if [ $? -eq "0" ]; then
        	msg_info "您设备的config.txt已备份到：${TARGET_CONFIG}.bak"
        else
            msg_error "备份config.txt文件失败，已终止安装"
            exit 1
        fi
    fi

    # 将备份的config.txt文件覆盖回来，因为用户可能反复运行此脚本
    # 这里需要一个额外判断，如果用户在运行完此脚本之后，自己修改了
    # config.txt，那就应该先询问用户是否要覆盖当前的config.txt文件
    if [ -f "${TARGET_CONFIG}.bak" ]; then
        sudo cp ${TARGET_CONFIG}.bak ${TARGET_CONFIG}
    fi

    # 编译设备树和固件
    make clean >> /dev/null
    make >> /dev/null

    # 安装显示相关
    # original_string="dtparam=compatible=rpi-dm-yt350s006\0panel-mipi-dbi-spi"
    case ${DISP_MODEL} in
    "YT350S006")
        # modified_string=$(echo "$original_string" | sed 's/\(compatible=\)[^\\]*\\0/\1rpi-dm-yt350s006\\0/')
        sed -i 's/\(compatible=\)[^\\]*\\0/\1rpi-dm-yt350s006\\0/' config_disp.txt
        sudo cp rpi-dm-yt350s006.bin ${FIRMWARE_INSTALL_DIR}
        ;;
    "HP35006")
        # modified_string=$(echo "$original_string" | sed 's/\(compatible=\)[^\\]*\\0/\1rpi-dm-hp35006\\0/')
        sed -i 's/\(compatible=\)[^\\]*\\0/\1rpi-dm-hp35006\\0/' config_disp.txt
        sudo cp rpi-dm-hp35006.bin ${FIRMWARE_INSTALL_DIR}
        ;;
    "CL35BC219-40A")
        # modified_string=$(echo "$original_string" | sed 's/\(compatible=\)[^\\]*\\0/\1rpi-dm-cl35bc219-40a\\0/')
        sed -i 's/\(compatible=\)[^\\]*\\0/\1rpi-dm-cl35bc219-40a\\0/' config_disp.txt
        sudo cp rpi-dm-cl35bc219-40a.bin ${FIRMWARE_INSTALL_DIR}
        ;;
    esac
    # echo "$modified_string"
    # cat config_disp.txt
    sudo sh -c "cat config_disp.txt >> ${TARGET_CONFIG}"

    # 处理触摸屏驱动
    case ${TOUCH_MODEL} in
    "GT911")
        sed -i 's/dtoverlay=[^ ]*/dtoverlay=goodix-gt911/' config_touch.txt
        sudo install -m 0755 goodix-gt911.dtbo ${DTBO_INSTALL_DIR}
        ;;
    "FT6336")
        sed -i 's/dtoverlay=[^ ]*/dtoverlay=focaltech-ft6236/' config_touch.txt
        sudo install -m 0755 focaltech-ft6236.dtbo ${DTBO_INSTALL_DIR}
        ;;
    "NS2009")
        sed -i 's/\(dtoverlay=\).*/\1nsiway-ns2009/' config_touch.txt
        sudo install -m 0755 nsiway-ns2009.dtbo ${DTBO_INSTALL_DIR}
        ;;
    "TSC2007")
        sed -i 's/\(dtoverlay=\).*/\1ti-tsc2007/' config_touch.txt
        sudo install -m 0755 ti-tsc2007.dtbo ${DTBO_INSTALL_DIR}
        ;;
    esac
    # cat config_touch.txt
    sudo sh -c "cat config_touch.txt >> ${TARGET_CONFIG}"

    cat ${TARGET_CONFIG}

    # 询问用户是否重启设备使改动生效
    read -p "是否重启设备使改动生效？[Y/n] " answer
    case $answer in
    Y|y|"")
        msg_info "正在重启设备使改动生效"
        sync
        sleep 1
        ${REBOOT_CMD}
        ;;
    *|n|N)
        msg_warn "用户取消重启"
        sync
        exit 1
        ;;
    esac
}

function default_install()
{
    msg_info "执行默认安装流程中。。。"
    ask_disp_model
    ask_touch_model
    ask_code_server

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

# echo "参数个数：$num"

# 如果没有提供参数，则执行默认安装流程
if [ $num -eq 0 ]; then
    default_install
    exit 0
fi
