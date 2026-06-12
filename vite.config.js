import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  base: './',   // required for Capacitor — makes all asset paths relative
  build: {
    outDir: 'dist',
  },
})
