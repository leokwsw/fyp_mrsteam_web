#!/bin/bash

# FYP MrSteam Web 部署腳本
# 此腳本用於將 Flutter Web 應用部署到 Google Cloud Platform

set -e  # 遇到錯誤時立即退出

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函數：打印彩色訊息
print_message() {
    echo -e "${2}${1}${NC}"
}

# 檢查必要的工具
check_requirements() {
    print_message "檢查必要工具..." $BLUE
    
    if ! command -v gcloud &> /dev/null; then
        print_message "錯誤：未找到 gcloud CLI。請安裝 Google Cloud SDK。" $RED
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_message "錯誤：未找到 Docker。請安裝 Docker。" $RED
        exit 1
    fi
    
    if ! command -v flutter &> /dev/null; then
        print_message "錯誤：未找到 Flutter。請安裝 Flutter SDK。" $RED
        exit 1
    fi
    
    print_message "✓ 所有必要工具已安裝" $GREEN
}

# 設置 GCP 項目
setup_project() {
    # 首先嘗試從 gcloud 配置獲取當前項目
    if [ -z "$PROJECT_ID" ]; then
        PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    fi
    
    # 如果仍然沒有項目 ID，則提示用戶輸入
    if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
        print_message "請輸入您的 GCP 項目 ID：" $YELLOW
        read -r PROJECT_ID
        
        if [ -z "$PROJECT_ID" ]; then
            print_message "錯誤：必須提供項目 ID" $RED
            exit 1
        fi
    fi
    
    print_message "設置 GCP 項目：$PROJECT_ID" $BLUE
    gcloud config set project "$PROJECT_ID"
    
    # 啟用必要的 API
    print_message "啟用必要的 GCP API..." $BLUE
    gcloud services enable cloudbuild.googleapis.com
    gcloud services enable run.googleapis.com
    gcloud services enable containerregistry.googleapis.com
}

# 構建和部署
build_and_deploy() {
    print_message "開始構建和部署..." $BLUE
    
    # 使用 Cloud Build 進行構建和部署
    gcloud builds submit --config=cloudbuild.yaml .
    
    print_message "✓ 部署完成！" $GREEN
    
    # 獲取服務 URL
    SERVICE_URL=$(gcloud run services describe fyp-mrsteam-web --region=asia-east1 --format="value(status.url)")
    print_message "您的應用已部署到：$SERVICE_URL" $GREEN
}

# 本地測試
local_test() {
    print_message "進行本地測試..." $BLUE
    
    # 構建 Docker 映像
    docker build -t fyp-mrsteam-web-local .
    
    print_message "啟動本地容器（端口 8080）..." $BLUE
    docker run -p 8080:8080 fyp-mrsteam-web-local &
    
    print_message "本地測試服務器已啟動：http://localhost:8080" $GREEN
    print_message "按 Ctrl+C 停止服務器" $YELLOW
}

# 清理資源
cleanup() {
    print_message "清理本地 Docker 映像..." $BLUE
    docker rmi fyp-mrsteam-web-local 2>/dev/null || true
    print_message "✓ 清理完成" $GREEN
}

# 主函數
main() {
    print_message "=== FYP MrSteam Web 部署工具 ===" $BLUE
    
    case "${1:-deploy}" in
        "test")
            check_requirements
            local_test
            ;;
        "deploy")
            check_requirements
            setup_project
            build_and_deploy
            ;;
        "cleanup")
            cleanup
            ;;
        "help"|"-h"|"--help")
            echo "使用方法："
            echo "  $0 deploy   - 部署到 GCP（預設）"
            echo "  $0 test     - 本地測試"
            echo "  $0 cleanup  - 清理本地資源"
            echo "  $0 help     - 顯示此幫助訊息"
            ;;
        *)
            print_message "未知命令：$1" $RED
            print_message "使用 '$0 help' 查看可用命令" $YELLOW
            exit 1
            ;;
    esac
}

# 執行主函數
main "$@"
