import { defineConfig } from 'vite';

export default defineConfig(({ mode }) => {
    if (mode === 'wpbackend') {
        return {
            build: {
                outDir: './assets/build/wpbackend',
                rollupOptions: {
                    input: './components/wpbackend/script.js',
                    output: {
                        format: 'iife',
                        inlineDynamicImports: true,
                        entryFileNames: 'bundle.js'
                    }
                },
                sourcemap: false,
                minify: false,
                emptyOutDir: false
            }
        };
    }
    if (mode === 'wpgutenberg') {
        return {
            build: {
                outDir: './assets/build/wpgutenberg',
                rollupOptions: {
                    input: './components/wpgutenberg/script.js',
                    output: {
                        format: 'iife',
                        inlineDynamicImports: true,
                        entryFileNames: 'bundle.js'
                    }
                },
                sourcemap: false,
                minify: false,
                emptyOutDir: false
            }
        };
    }
});
