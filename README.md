# FYP MrSteam Web

A Flutter Web application built for the FYP MrSteam project.

## Live app

~~**Web:** [https://fyp-mrsteam-web-zknqk6dfca-de.a.run.app](https://fyp-mrsteam-web-zknqk6dfca-de.a.run.app)~~

**Web services are migrating**

Open the link in a modern desktop or mobile browser (Chrome recommended).

## Features

- Responsive web layout
- Flutter Web
- Firebase integration
- Material Design UI

## Tech stack

Direct dependencies and tooling from [`pubspec.yaml`](pubspec.yaml). Runtime targets **Flutter Web** with Dart `>=3.9.2 <4.0.0` and Flutter `>=3.35.0 <4.0.0`.

### Core & UI

- **flutter** (SDK) — **Material** (`uses-material-design`) — **cupertino_icons**
- **google_fonts** — **cached_network_image** — **image_network**
- **flutter_html** — **flutter_form_builder** — **table_calendar**

### State & architecture

- **bloc** — **flutter_bloc** — **bloc_concurrency** — **bloc_test**
- **get_it**

### Networking & serialization

- **dio** — **retry** — **talker** — **talker_dio_logger**
- **json_annotation** (codegen via **json_serializable** / **build_runner** in `dev_dependencies`)

### Firebase

- **firebase_core** — **firebase_messaging** — **firebase_crashlytics**

### Maps & location

- **flutter_map** — **latlong2** — **flutter_map_cancellable_tile_provider**
- **google_maps_flutter** — **geolocator**

### Navigation & deep links

- **go_router** — **app_links**

### Storage, files & device

- **path** — **path_provider** — **shared_preferences**
- **image_picker** — **file_picker** — **excel**
- **permission_handler** — **device_info_plus** — **package_info_plus** — **connectivity_plus**

### Internationalization

- **intl**

### Development (`dev_dependencies`)

- **flutter_test** — **build_runner** — **json_serializable** — **flutter_lints**

## Local development

### Requirements

- Flutter SDK (>= 3.35.0)
- Dart SDK (>= 3.9.2)
- Chrome (or another supported browser)

### Setup

From the project root:

```bash
flutter pub get
flutter run -d chrome
```

### Production build

```bash
flutter build web --release --web-renderer canvaskit
```

### Code quality

- `flutter analyze` — static analysis
- `flutter test` — tests

## Deploying to Google Cloud (Cloud Run)

### Requirements

- Google Cloud SDK
- Docker
- A GCP project with billing and APIs enabled

### Using the deploy script

```bash
./deploy.sh deploy   # deploy
./deploy.sh test     # local test
./deploy.sh cleanup  # clean local resources
```

### Manual GCP setup (summary)

1. Set project and enable APIs: `cloudbuild.googleapis.com`, `run.googleapis.com`, `containerregistry.googleapis.com`.
2. Build and deploy, for example:

```bash
gcloud builds submit --config=cloudbuild.yaml .
```

Or build/push the image and run:

```bash
docker build -t gcr.io/$PROJECT_ID/fyp-mrsteam-web .
docker push gcr.io/$PROJECT_ID/fyp-mrsteam-web
gcloud run deploy fyp-mrsteam-web \
  --image gcr.io/$PROJECT_ID/fyp-mrsteam-web \
  --region asia-east1 \
  --platform managed \
  --allow-unauthenticated \
  --port 8080
```

### Typical Cloud Run settings

- **Region:** `asia-east1`
- **Platform:** Cloud Run (fully managed)
- **Memory:** 512Mi
- **CPU:** 1 vCPU
- **Scaling:** min 0, max 10 instances

### Local Docker

```bash
docker build -t fyp-mrsteam-web .
docker run -p 8080:8080 fyp-mrsteam-web
```

## Environment variables (deploy)

- `PROJECT_ID` — GCP project ID
- `REGION` — deploy region (default: `asia-east1`)

## Project layout

```
fyp_mrsteam_web/
├── lib/                 # Dart sources
│   └── main.dart        # Entry point
├── web/                 # Web assets (index.html, manifest, icons)
├── test/
├── Dockerfile
├── nginx.conf
├── cloudbuild.yaml
├── deploy.sh
└── pubspec.yaml
```

## Troubleshooting

- **Build fails:** Match Flutter/Dart versions to `pubspec.yaml`; run `flutter pub get`.
- **Deploy fails:** Check IAM, APIs, and `gcloud` project configuration.
- **Runtime issues:** Use the browser devtools console; confirm network access.

**Cloud Run logs:**

```bash
gcloud logs read --service=fyp-mrsteam-web --region=asia-east1
```

**Cloud Build logs:**

```bash
gcloud builds log <BUILD_ID>
```

## License

This project is for FYP (academic) use.

## Contact

For questions or feedback, contact the project team.
