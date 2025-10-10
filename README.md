# FYP MrSteam Web 應用

這是一個使用 Flutter 開發的 Web 應用，專為 FYP MrSteam 項目設計。

## 功能特色

- 響應式 Web 設計
- 使用 Flutter Web 技術
- 整合 Firebase 服務
- 支援多種 UI 組件和功能

## 技術棧

- **前端框架**: Flutter Web
- **狀態管理**: Flutter Bloc
- **網路請求**: Dio
- **UI 組件**: Material Design
- **路由**: Go Router
- **國際化**: Intl
- **快取**: Cached Network Image

## 開發環境設置

### 前置需求

- Flutter SDK (>=3.35.0)
- Dart SDK (>=3.9.2)
- Web 瀏覽器（Chrome 推薦）

### 安裝步驟

1. 克隆專案
```bash
git clone <repository-url>
cd fyp_mrsteam_web
```

2. 安裝依賴
```bash
flutter pub get
```

3. 運行開發服務器
```bash
flutter run -d chrome
```

## 部署到 Google Cloud Platform

### 前置需求

- Google Cloud SDK
- Docker
- 已啟用的 GCP 專案

### 快速部署

使用提供的部署腳本：

```bash
# 部署到 GCP
./deploy.sh deploy

# 本地測試
./deploy.sh test

# 清理本地資源
./deploy.sh cleanup
```

### 手動部署步驟

1. **設置 GCP 專案**
```bash
# 設置專案 ID
export PROJECT_ID=your-project-id
gcloud config set project $PROJECT_ID

# 啟用必要的 API
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

2. **使用 Cloud Build 部署**
```bash
gcloud builds submit --config=cloudbuild.yaml .
```

3. **或手動構建和部署**
```bash
# 構建 Docker 映像
docker build -t gcr.io/$PROJECT_ID/fyp-mrsteam-web .

# 推送到 Container Registry
docker push gcr.io/$PROJECT_ID/fyp-mrsteam-web

# 部署到 Cloud Run
gcloud run deploy fyp-mrsteam-web \
  --image gcr.io/$PROJECT_ID/fyp-mrsteam-web \
  --region asia-east1 \
  --platform managed \
  --allow-unauthenticated \
  --port 8080
```

### 部署配置

- **地區**: asia-east1（香港）
- **平台**: Cloud Run（完全託管）
- **記憶體**: 512Mi
- **CPU**: 1 vCPU
- **最大實例數**: 10
- **最小實例數**: 0（自動縮放到零）

## 專案結構

```
fyp_mrsteam_web/
├── lib/                    # Dart 源代碼
│   └── main.dart          # 應用入口點
├── web/                   # Web 資源
│   ├── index.html         # HTML 模板
│   ├── manifest.json      # PWA 清單
│   └── icons/             # 應用圖標
├── test/                  # 測試文件
├── Dockerfile             # Docker 配置
├── nginx.conf             # Nginx 配置
├── cloudbuild.yaml        # Cloud Build 配置
├── deploy.sh              # 部署腳本
└── pubspec.yaml           # Flutter 依賴配置
```

## 開發指南

### 構建生產版本

```bash
flutter build web --release --web-renderer canvaskit
```

### 本地 Docker 測試

```bash
# 構建映像
docker build -t fyp-mrsteam-web .

# 運行容器
docker run -p 8080:8080 fyp-mrsteam-web
```

### 代碼品質

- 使用 `flutter analyze` 進行靜態分析
- 使用 `flutter test` 運行測試
- 遵循 Flutter 編碼規範

## 環境變數

部署時可以設置以下環境變數：

- `PROJECT_ID`: GCP 專案 ID
- `REGION`: 部署地區（預設：asia-east1）

## 故障排除

### 常見問題

1. **構建失敗**
   - 檢查 Flutter 版本是否符合要求
   - 確認所有依賴都已正確安裝

2. **部署失敗**
   - 檢查 GCP 權限設置
   - 確認已啟用必要的 API

3. **運行時錯誤**
   - 檢查瀏覽器控制台錯誤
   - 確認網路連接正常

### 日誌查看

```bash
# 查看 Cloud Run 日誌
gcloud logs read --service=fyp-mrsteam-web --region=asia-east1

# 查看 Cloud Build 日誌
gcloud builds log <BUILD_ID>
```

## 貢獻指南

1. Fork 專案
2. 創建功能分支
3. 提交更改
4. 推送到分支
5. 創建 Pull Request

## 授權

此專案為 FYP 學術用途。

## 聯絡方式

如有問題或建議，請聯絡開發團隊。
