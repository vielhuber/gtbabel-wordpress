# 🌐 Gtbabel for WordPress 🌐

Official WordPress plugin repository that can be used to build a new version of the plugin.

-   Repository-URL: [https://wordpress.org/plugins/gtbabel](https://wordpress.org/plugins/gtbabel)

## Development

### Setup

-   Clone [gtbabel/core](https://github.com/gtbabel/core) into `/gtbabel/core`
-   Clone [gtbabel/wordpress](https://github.com/gtbabel/wordpress) into `/gtbabel/wordpress`
-   Inside `/gtbabel/wordpress`, create a relative symlink: `ln -s ./../core/vendor ./vendor`

### Build pipeline

-   `npm install`
-   `npm run dev` / `npm run prod`

### Test

-   Copy `/deploy/gtbabel-dev.sh` to your themes folder
-   Change `BASE_PLUGIN` and `BASE_WORDPRESS`
-   `./gtbabel-dev.sh start` / `./gtbabel-dev.sh stop`

### Release

-   `cd deploy`
-   `./deploy.sh --release`
