# 🌐 Gtbabel WP 🌐

Official WordPress plugin repository that can be used to build the free and pro version of the plugin.

## Development

### Setup

-   Clone [gtbabel-core](https://github.com/gtbabel/gtbabel-core) in /gtbabel/gtbabel-core
-   Clone [gtbabel-wp](https://github.com/gtbabel/gtbabel-wp) in /gtbabel/gtbabel-wp
-   Create relative symlink from /gtbabel/gtbabel-wp/vendor to /gtbabel/gtbabel-core/vendor with `ln -s ./../gtbabel-core/vendor ./vendor`

### Test deployment

-   Copy `/deploy/gtbabel-dev.sh` to your themes folder
-   `./gtbabel-dev.sh start` / `./gtbabel-dev.sh stop`

### Release

-   `cd deploy`
-   `./deploy.sh`
