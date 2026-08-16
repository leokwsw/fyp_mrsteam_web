const port = process.env.PORT || 8070;

module.exports = {
  apps: [
    {
      name: 'fyp-mrsteam-web',
      script: 'serve',
      cwd: __dirname,
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '256M',
      env: {
        NODE_ENV: 'production',
        PM2_SERVE_PATH: 'build/web',
        PM2_SERVE_PORT: port,
        PM2_SERVE_SPA: 'true',
        PM2_SERVE_HOMEPAGE: '/index.html',
      },
    },
  ],
};
