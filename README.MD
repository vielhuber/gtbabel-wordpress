# 🌐 Gtbabel for WordPress 🌐

Official WordPress plugin repository that can be used to build the free and pro version of the plugin.

## Development

### Setup

-   Clone [gtbabel-core](https://github.com/gtbabel/gtbabel-core) into `/gtbabel/gtbabel-core`
-   Clone [gtbabel-wp](https://github.com/gtbabel/gtbabel-wp) into `/gtbabel/gtbabel-wp`
-   Inside `/gtbabel/gtbabel-wp`, create a relative symlink: `ln -s ./../gtbabel-core/vendor ./vendor`

### Test

-   Copy `/deploy/gtbabel-dev.sh` to your themes folder
-   `./gtbabel-dev.sh start` / `./gtbabel-dev.sh stop`

### Release

-   `cd deploy`
-   `./deploy.sh`
