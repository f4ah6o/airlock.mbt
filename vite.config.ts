import { defineConfig } from 'vite';
import { resolve } from 'path';
import { moonbit } from 'vite-plugin-moonbit';

export default defineConfig(({ command }) => {
  const isDev = command === 'serve';

  return {
    appType: 'mpa',
    plugins: [moonbit({})],
    resolve: {
      alias: {
        '/target': resolve(import.meta.dirname, 'target'),
      },
    },
    optimizeDeps: {
      exclude: [
        '@duckdb/node-api',
        '@duckdb/node-bindings',
        '@duckdb/node-bindings-linux-x64',
        '@duckdb/node-bindings-linux-arm64',
        '@duckdb/node-bindings-darwin-x64',
        '@duckdb/node-bindings-darwin-arm64',
        '@duckdb/node-bindings-win32-x64',
      ],
    },
    server: {
      port: 5173,
      fs: {
        allow: ['.'],
      },
    },
    build: {
      outDir: 'dist',
      emptyOutDir: true,
      rollupOptions: {
        input: {
          ui_demo: resolve(import.meta.dirname, 'cmd/ui_demo/index.html'),
        },
        external: [
          '@duckdb/node-api',
          '@duckdb/node-bindings',
          /^@duckdb\/node-bindings/,
        ],
      },
    },
  };
});
