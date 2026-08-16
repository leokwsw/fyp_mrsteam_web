# FYP MrSteam Web

A Flutter Web application built for the FYP MrSteam project.

## Live app

**Web:** [https://web-mu2526-fyp.leonardpark.dev](https://web-mu2526-fyp.leonardpark.dev)

**API:** [https://api-mu2526-fyp.leonardpark.dev](https://api-mu2526-fyp.leonardpark.dev)

**API documentation:** [https://api-mu2526-fyp.leonardpark.dev/api/docs](https://api-mu2526-fyp.leonardpark.dev/api/docs)

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
- **geolocator**

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

## Deploying on Ubuntu with PM2

### Requirements

- Flutter SDK (>= 3.35.0)
- Node.js
- PM2 (`npm install --global pm2`)
- Nginx

### Using the deploy script

```bash
./deploy.sh deploy
```

The script installs Flutter dependencies, creates a release build, starts or
reloads the app from `ecosystem.config.js`, and saves the PM2 process list.

### Manual deployment

```bash
flutter pub get
flutter build web --release
pm2 startOrReload ecosystem.config.js --update-env
pm2 save
```

The app listens on port `8070` by default. Set `PORT` before starting PM2 to
override it:

```bash
PORT=3000 ./deploy.sh deploy
```

### Process management

```bash
./deploy.sh status
./deploy.sh logs
./deploy.sh restart
./deploy.sh stop
```

To restore the saved process list after a server reboot, configure PM2 startup
once by running `pm2 startup` and following the command it prints.

### Nginx reverse proxy

Proxy the public web domain to the PM2 static server:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name web.example.com;

    location / {
        proxy_pass http://127.0.0.1:8070;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Replace `web.example.com` with the production web domain, validate the Nginx
configuration with `sudo nginx -t`, and then reload Nginx.

## Project layout

```
fyp_mrsteam_web/
├── lib/                 # Dart sources
│   └── main.dart        # Entry point
├── web/                 # Web assets (index.html, manifest, icons)
├── test/
├── ecosystem.config.js  # PM2 process and static server configuration
├── deploy.sh
└── pubspec.yaml
```

## Troubleshooting

- **Build fails:** Match Flutter/Dart versions to `pubspec.yaml`; run `flutter pub get`.
- **Deploy fails:** Confirm that Flutter and PM2 are available in `PATH`.
- **Runtime issues:** Use the browser devtools console; confirm network access.

**PM2 logs:**

```bash
pm2 logs fyp-mrsteam-web
```

## License

This project is for FYP (academic) use.

## Contact

For questions or feedback, contact the project team.
