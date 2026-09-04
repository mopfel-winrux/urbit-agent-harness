import { createHash } from 'node:crypto'
import { resolve } from 'node:path'
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

const cacheBust = () => ({
  name: 'harness-cache-bust',
  enforce: 'post',
  generateBundle(_options, bundle) {
    const app = bundle['app.js']
    const css = bundle['app.css']
    const html = bundle['index.html']
    if (!app || !html || html.type !== 'asset') return
    const digest = createHash('sha256')
      .update(app.type === 'chunk' ? app.code : String(app.source))
      .update(css?.type === 'asset' ? String(css.source) : '')
      .digest('hex')
      .slice(0, 12)
    html.source = String(html.source)
      .replace('/apps/harness/app.js', `/apps/harness/app.js?v=${digest}`)
      .replace('/apps/harness/app.css', `/apps/harness/app.css?v=${digest}`)
  },
})

export default defineConfig({
  plugins: [react(), cacheBust()],
  base: '/apps/harness/',
  build: {
    outDir: resolve(import.meta.dirname, '../desk/web'),
    emptyOutDir: true,
    assetsDir: '',
    rollupOptions: {
      output: {
        codeSplitting: false,
        entryFileNames: 'app.js',
        assetFileNames: ({ names }) =>
          names?.some((name) => name.endsWith('.css')) ? 'app.css' : '[name][extname]',
      },
    },
  },
})
